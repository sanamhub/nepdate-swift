#!/usr/bin/env python3
"""Median over interleaved rounds for a base and a head checkout.

Directory layout produced by .github/workflows/perf-compare.yml:
  results/base/<round>/*.histogram.percentiles.tsv
  results/head/<round>/*.histogram.percentiles.tsv

Usage:
  python3 ab.py --base results/base --head results/head
"""

import argparse
import glob
import os
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from report import OPS_PER_ITERATION, format_number, swift_results


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
    arguments = parser.parse_args()

    base = rounds(arguments.base)
    head = rounds(arguments.head)
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
        "base mallocs | head mallocs |"
    )
    print("|---|---:|---:|---:|---:|---:|---:|---:|")

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
        print(
            f"| {name} | {format_number(base_ops)} | {format_number(head_ops)} | "
            f"{change:+.1f} % | {format_number(base_p90 / OPS_PER_ITERATION)} | "
            f"{format_number(head_p90 / OPS_PER_ITERATION)} | "
            f"{max(0.0, (base_malloc - baseline) / OPS_PER_ITERATION):.0f} | "
            f"{max(0.0, (head_malloc - baseline) / OPS_PER_ITERATION):.0f} |"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
