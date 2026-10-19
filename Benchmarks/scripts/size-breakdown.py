#!/usr/bin/env python3
"""Attribute the with-patro size delta to Mach-O sections and to symbols.

Runs on macOS, where `size` and `nm` understand Mach-O:

  python3 size-breakdown.py --baseline B --core-only C --with-patro P \
    --unstripped-baseline UB --unstripped-core UC --unstripped-patro UP

Apple's `nm -S` reports zero sizes for Mach-O ("sizes with --print-size for Mach-O files are always
zero"), so symbol sizes come from the sorted addresses of the unstripped copies: a text symbol lasts
until the next symbol. Stripping removes the symbol table, not code, so the layout and the sizes are
the ones in the shipped binary.
"""

import argparse
import os
import re
import subprocess
import sys

SECTION = re.compile(r"^\s*Section (__\w+): (\d+)")
SEGMENT = re.compile(r"^Segment (__\w+):")
SYMBOL = re.compile(r"^([0-9a-fA-F]+) (\w) (.+)$")
BUCKETS = [
    ("patro tables and names", ("PatroData", "Patro", "Named", "CalendarInfo", "PatroEvents")),
    ("core", ("NepaliDate", "NepDate")),
    ("Swift runtime and metadata", ("Swift", "swift", "_$s")),
]


def run(*arguments):
    return subprocess.run(arguments, check=True, capture_output=True, text=True).stdout


def sections(path):
    """Section sizes in bytes, keyed by segment and section so the two __const entries differ."""
    sizes = {}
    segment = None
    for line in run("size", "-m", path).splitlines():
        match = SEGMENT.match(line)
        if match:
            segment = match.group(1)
            continue
        match = SECTION.match(line)
        if match and segment:
            sizes[f"{segment}.{match.group(1)}"] = int(match.group(2))
    return sizes


def symbol_sizes(path):
    """Text symbol sizes from consecutive text addresses in an unstripped binary."""
    text = []
    for line in run("nm", "-n", "-U", path).splitlines():
        match = SYMBOL.match(line)
        if match and match.group(2) in ("T", "t"):
            text.append((int(match.group(1), 16), match.group(3).strip()))
    text.sort()
    sizes = {}
    for (address, name), (following, _) in zip(text, text[1:]):
        if following > address:
            sizes[name] = following - address
    return sizes


def bucket(name):
    for label, needles in BUCKETS:
        if any(needle in name for needle in needles):
            return label
    return "other"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", required=True)
    parser.add_argument("--core-only", required=True)
    parser.add_argument("--with-patro", required=True)
    parser.add_argument("--unstripped-baseline")
    parser.add_argument("--unstripped-core")
    parser.add_argument("--unstripped-patro")
    arguments = parser.parse_args()

    baseline_size = os.path.getsize(arguments.baseline)
    core_size = os.path.getsize(arguments.core_only)
    patro_size = os.path.getsize(arguments.with_patro)
    core_delta = core_size - baseline_size
    patro_delta = patro_size - baseline_size
    patro_over_core = patro_size - core_size

    print("## File sizes")
    print()
    print("| Binary | Stripped bytes | Delta from baseline | Delta from core-only |")
    print("|---|---:|---:|---:|")
    print(f"| baseline | {baseline_size:,} | 0 | |")
    print(f"| core-only | {core_size:,} | {core_delta:+,} | 0 |")
    print(f"| with-patro | {patro_size:,} | {patro_delta:+,} | {patro_over_core:+,} |")
    print()

    baseline_sections = sections(arguments.baseline)
    core_sections = sections(arguments.core_only)
    patro_sections = sections(arguments.with_patro)
    names = sorted(set(baseline_sections) | set(core_sections) | set(patro_sections))
    print("## Sections")
    print()
    print("| Section | baseline | core-only | with-patro | delta from baseline | delta from core |")
    print("|---|---:|---:|---:|---:|---:|")
    section_sum = 0
    for name in names:
        baseline = baseline_sections.get(name, 0)
        core = core_sections.get(name, 0)
        patro = patro_sections.get(name, 0)
        delta = patro - baseline
        if not delta:
            continue
        section_sum += delta
        print(f"| {name} | {baseline:,} | {core:,} | {patro:,} | {delta:+,} | {patro - core:+,} |")
    print(f"| **section sum** | | | | **{section_sum:+,}** | |")
    print()

    if arguments.unstripped_core and arguments.unstripped_patro:
        core_symbols = symbol_sizes(arguments.unstripped_core)
        patro_symbols = symbol_sizes(arguments.unstripped_patro)
        deltas = []
        for name, size in patro_symbols.items():
            delta = size - core_symbols.get(name, 0)
            if delta > 0:
                deltas.append((delta, name))
        deltas.sort(reverse=True)
        symbol_sum = sum(delta for delta, _ in deltas)

        print("## Symbols, with-patro against core-only")
        print()
        print("| Symbol | Delta bytes | Bucket |")
        print("|---|---:|---|")
        for delta, name in deltas[:25]:
            print(f"| `{name}` | {delta:+,} | {bucket(name)} |")
        print(f"| **symbol sum, {len(deltas)} symbols** | **{symbol_sum:+,}** | |")
        print()

        print("## Buckets")
        print()
        print("| Bucket | Symbol delta bytes |")
        print("|---|---:|")
        buckets = {}
        for delta, name in deltas:
            buckets[bucket(name)] = buckets.get(bucket(name), 0) + delta
        for label, total in sorted(buckets.items(), key=lambda item: -item[1]):
            print(f"| {label} | {total:+,} |")
        print()

    print("## Remainder")
    print()
    print(f"- file delta from baseline: {patro_delta:+,} bytes")
    print(f"- section sum from baseline: {section_sum:+,} bytes")
    print(f"- difference (page rounding, load commands, symbol table): {patro_delta - section_sum:+,} bytes")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as error:
        print(f"size-breakdown: {error.cmd[0]} failed: {error.stderr}", file=sys.stderr)
        sys.exit(1)
