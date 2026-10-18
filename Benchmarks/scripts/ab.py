#!/usr/bin/env python3
"""Median over interleaved rounds for a base and a head checkout, with the C# number on that runner.

Directory layout produced by .github/workflows/perf-compare.yml:
  results/base/<round>/*.histogram.percentiles.tsv
  results/head/<round>/*.histogram.percentiles.tsv
  results/csharp/results/*-report.csv

Usage:
  python3 ab.py --base results/base --head results/head --csharp results/csharp/results/x.csv
"""

import argparse
import glob
import os
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from ratio import OPS_PER_ITERATION, csharp_results, format_number, swift_results


def rounds(directory):
    """One swift_results() per round directory, in name order."""
    paths = sorted(path for path in glob.glob(os.path.join(directory, "*")) if os.path.isdir(path))
    return [swift_results(path) for path in paths]


def median_of(results, name, metric, percentile_index):
    values = []
    for result in results:
        entry = result.get(name)
        if not entry or metric not in entry:
            continue
        values.append(entry[metric][percentile_index])
    return statistics.median(values) if values else None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", required=True)
    parser.add_argument("--head", required=True)
    parser.add_argument("--csharp", required=True)
    arguments = parser.parse_args()

    base = rounds(arguments.base)
    head = rounds(arguments.head)
    csharp = csharp_results(arguments.csharp)
    if len(base) != len(head) or not base:
        print("ab: the base and head round counts differ or are empty", file=sys.stderr)
        return 1

    names = sorted(
        name
        for name in head[0]
        if "wall" in head[0][name] and name != "Baseline"
    )
    print(f"Rounds per side: {len(base)}. p50 and p90 are medians over the rounds, ns per operation.")
    print()
    print(
        "| Benchmark | base p50 | head p50 | change | base p90 | head p90 | "
        "base mallocs | head mallocs | C# same runner | base/C# | head/C# |"
    )
    print("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|")

    for name in names:
        base_p50 = median_of(base, name, "wall", 0)
        head_p50 = median_of(head, name, "wall", 0)
        if base_p50 is None or head_p50 is None:
            continue
        base_p90 = median_of(base, name, "wall", 1)
        head_p90 = median_of(head, name, "wall", 1)
        base_malloc = median_of(base, name, "malloc", 0)
        head_malloc = median_of(head, name, "malloc", 0)
        baseline = median_of(base, "Baseline", "malloc", 0) or 0.0
        base_ops = base_p50 / OPS_PER_ITERATION
        head_ops = head_p50 / OPS_PER_ITERATION
        change = (head_ops - base_ops) / base_ops * 100 if base_ops else 0.0
        csharp_ns = csharp.get(name)
        base_ratio = f"{base_ops / csharp_ns:.2f}" if csharp_ns else "n/a"
        head_ratio = f"{head_ops / csharp_ns:.2f}" if csharp_ns else "n/a"
        print(
            f"| {name} | {format_number(base_ops)} | {format_number(head_ops)} | "
            f"{change:+.1f} % | {format_number(base_p90 / OPS_PER_ITERATION)} | "
            f"{format_number(head_p90 / OPS_PER_ITERATION)} | "
            f"{max(0.0, (base_malloc - baseline) / OPS_PER_ITERATION):.0f} | "
            f"{max(0.0, (head_malloc - baseline) / OPS_PER_ITERATION):.0f} | "
            f"{format_number(csharp_ns) if csharp_ns else 'n/a'} | {base_ratio} | {head_ratio} |"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
