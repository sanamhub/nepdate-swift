#!/usr/bin/env python3
"""Turn package-benchmark percentile exports into the Markdown report tables.

The Swift benchmarks iterate all 64 inputs per iteration (package-benchmark's scaling factor is a
power of 1,000, so `.one` leaves the value per iteration), so every wall-clock value is divided by
64.

Usage:
  python3 report.py --swift-dir results/nepdate [--competitors-dir results/competitors]
"""

import argparse
import glob
import os
import re
import sys

IDS = [f"B{number}" for number in range(1, 9)]
OPS_PER_ITERATION = 64
TIME_TO_NS = {"ns": 1.0, "us": 1e3, "\u00b5s": 1e3, "\u03bcs": 1e3, "ms": 1e6, "s": 1e9}


def read_percentiles(path):
    """{percentile: value} and the unit from the header, from one histogramPercentiles TSV."""
    values = {}
    unit = "ns"
    with open(path, encoding="utf-8") as stream:
        header = stream.readline().rstrip("\n").split("\t")
        if len(header) == 2:
            # For example "Time (wall clock) (ns) *"; the unit is the last parenthesised group.
            groups = re.findall(r"\(([^()]*)\)", header[1])
            if groups:
                unit = groups[-1].strip()
        for line in stream:
            fields = line.rstrip("\n").split("\t")
            if len(fields) != 2:
                continue
            try:
                values[int(fields[0])] = float(fields[1])
            except ValueError:
                continue
    return values, unit


def to_ns(value, unit):
    return value * TIME_TO_NS.get(unit, 1.0)


def swift_results(directory):
    """{benchmark: {'wall': (p50, p90), 'malloc': (p50, p90)}}, wall in ns per iteration."""
    results = {}
    for path in sorted(glob.glob(os.path.join(directory, "*.histogram.percentiles.tsv"))):
        parts = os.path.basename(path).split(".")
        if len(parts) < 6:
            continue
        # <baseline>.<target>.<benchmark>.<metric>.histogram.percentiles.tsv
        metric, name = parts[-4], parts[-5]
        values, unit = read_percentiles(path)
        if not values:
            continue
        entry = results.setdefault(name, {})
        if metric == "wallClock":
            entry["wall"] = (to_ns(values.get(50, 0.0), unit), to_ns(values.get(90, 0.0), unit))
        elif metric == "mallocCountTotal":
            entry["malloc"] = (values.get(50, 0.0), values.get(90, 0.0))
    return results


def format_number(value, digits=1):
    return f"{value:,.{digits}f}"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--swift-dir", required=True)
    parser.add_argument("--competitors-dir")
    arguments = parser.parse_args()

    swift = swift_results(arguments.swift_dir)
    if not swift:
        print("ratio: no Swift results in", arguments.swift_dir, file=sys.stderr)
        return 1

    # The harness allocates 16 times per iteration on Linux (the Baseline benchmark, the same loop
    # with no NepDate call), so subtract it to get NepDate's own mallocs.
    baseline = swift.get("Baseline", {}).get("malloc", (16.0, 16.0))[0]

    print("| ID | Swift p50 ns/op | Swift p90 ns/op | NepDate mallocs/op |")
    print("|---|---:|---:|---:|")
    for identifier in IDS:
        result = swift.get(identifier)
        if not result or "wall" not in result:
            continue
        p50 = result["wall"][0] / OPS_PER_ITERATION
        p90 = result["wall"][1] / OPS_PER_ITERATION
        harness = result.get("malloc", (baseline, baseline))[0]
        mallocs = max(0.0, (harness - baseline) / OPS_PER_ITERATION)
        print(
            f"| {identifier} | {format_number(p50)} | {format_number(p90)} | {mallocs:.0f} |"
        )

    extras = [name for name in ("B5a", "B7-sorted", "MonthRange") if name in swift]
    if extras:
        print()
        print("| Extra benchmark | Swift p50 ns/op | Swift p90 ns/op | mallocs/op |")
        print("|---|---:|---:|---:|")
        for name in extras:
            result = swift[name]
            harness = result.get("malloc", (baseline, baseline))[0]
            mallocs = max(0.0, (harness - baseline) / OPS_PER_ITERATION)
            print(
                f"| {name} | {format_number(result['wall'][0] / OPS_PER_ITERATION)} | "
                f"{format_number(result['wall'][1] / OPS_PER_ITERATION)} | {mallocs:.0f} |"
            )
        print()
        print(f"Baseline (harness only): {format_number(baseline / OPS_PER_ITERATION, 2)} mallocs/op.")

    if arguments.competitors_dir:
        competitors = swift_results(arguments.competitors_dir)
        print()
        print("| Competitor benchmark | Swift p50 ns/op | Swift p90 ns/op | mallocs/op |")
        print("|---|---:|---:|---:|")
        for name in sorted(competitors):
            result = competitors[name]
            if "wall" not in result:
                continue
            harness = result.get("malloc", (0.0, 0.0))[0]
            print(
                f"| {name} | {format_number(result['wall'][0] / OPS_PER_ITERATION)} | "
                f"{format_number(result['wall'][1] / OPS_PER_ITERATION)} | "
                f"{harness / OPS_PER_ITERATION:.2f} |"
            )
    return 0


if __name__ == "__main__":
    sys.exit(main())
