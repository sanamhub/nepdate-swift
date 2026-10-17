#!/usr/bin/env python3
"""Attribute the with-patro size delta to Mach-O sections and to symbols (S6-04).

Runs on macOS, where `size` and `nm` understand Mach-O:

  python3 size-breakdown.py --baseline B --core-only C --with-patro P

The section table sums what changed in the file; the symbol table names the largest additions. A
stripped Swift binary keeps the string literals in __TEXT,__cstring and the Swift metadata in the
__swift5_* sections, neither of which is a symbol, so the symbol sum is smaller than the file delta
and the remainder is reported as literals and metadata.
"""

import argparse
import os
import re
import subprocess
import sys

SECTION = re.compile(r"^\s*Section (__\w+): (0x[0-9a-fA-F]+)")
SYMBOL = re.compile(r"^([0-9a-fA-F]+) ([0-9a-fA-F]+) (\w) (.+)$")
BUCKETS = [
    ("patro tables and names", ("PatroData", "Patro", "Named", "CalendarInfo", "PatroEvents")),
    ("core", ("NepaliDate", "NepDate")),
    ("Swift runtime and metadata", ("Swift", "swift", "_$s")),
]


def run(*arguments):
    return subprocess.run(arguments, check=True, capture_output=True, text=True).stdout


def sections(path):
    sizes = {}
    for line in run("size", "-m", path).splitlines():
        match = SECTION.match(line)
        if match:
            sizes[match.group(1)] = int(match.group(2), 16)
    return sizes


def symbols(path):
    sizes = {}
    for line in run("nm", "-S", "-n", "-U", path).splitlines():
        match = SYMBOL.match(line)
        if match:
            sizes[match.group(4)] = int(match.group(2), 16)
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
    arguments = parser.parse_args()

    baseline_size = os.path.getsize(arguments.baseline)
    core_size = os.path.getsize(arguments.core_only)
    patro_size = os.path.getsize(arguments.with_patro)
    core_delta = core_size - baseline_size
    patro_delta = patro_size - baseline_size

    print("## File sizes")
    print()
    print("| Binary | Stripped bytes | Delta from baseline |")
    print("|---|---:|---:|")
    print(f"| baseline | {baseline_size:,} | 0 |")
    print(f"| core-only | {core_size:,} | {core_delta:+,} |")
    print(f"| with-patro | {patro_size:,} | {patro_delta:+,} |")
    print()

    baseline_sections = sections(arguments.baseline)
    core_sections = sections(arguments.core_only)
    patro_sections = sections(arguments.with_patro)
    names = sorted(set(core_sections) | set(patro_sections))
    print("## Sections, core-only against with-patro")
    print()
    print("| Section | core-only bytes | with-patro bytes | delta |")
    print("|---|---:|---:|---:|")
    section_sum = 0
    for name in names:
        core = core_sections.get(name, 0)
        patro = patro_sections.get(name, 0)
        delta = patro - core
        section_sum += delta
        if delta:
            print(f"| {name} | {core:,} | {patro:,} | {delta:+,} |")
    print(f"| **section sum** | | | **{section_sum:+,}** |")
    print()

    core_symbols = symbols(arguments.core_only)
    patro_symbols = symbols(arguments.with_patro)
    deltas = []
    for name, size in patro_symbols.items():
        delta = size - core_symbols.get(name, 0)
        if delta > 0:
            deltas.append((delta, name))
    deltas.sort(reverse=True)
    symbol_sum = sum(delta for delta, _ in deltas)

    print("## Symbols")
    print()
    print("| Symbol | Delta bytes | Bucket |")
    print("|---|---:|---|")
    for delta, name in deltas[:20]:
        print(f"| `{name}` | {delta:+,} | {bucket(name)} |")
    print(f"| **symbol sum, {len(deltas)} symbols** | **{symbol_sum:+,}** | |")
    print()

    print("## Buckets")
    print()
    print("| Bucket | Symbol delta bytes |")
    print("|---|---:|")
    buckets = {}
    for delta, name in deltas:
        label = bucket(name)
        buckets[label] = buckets.get(label, 0) + delta
    for label, total in sorted(buckets.items(), key=lambda item: -item[1]):
        print(f"| {label} | {total:+,} |")
    print()

    print("## Remainder")
    print()
    print(f"- file delta: {patro_delta:+,} bytes")
    print(f"- section sum: {section_sum:+,} bytes")
    print(f"- symbol sum: {symbol_sum:+,} bytes")
    print(f"- not named by a symbol (literals, metadata, padding): {patro_delta - symbol_sum:+,} bytes")
    print(f"- baseline sections: {sum(baseline_sections.values()):,} bytes")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as error:
        print(f"size-breakdown: {error.cmd[0]} failed: {error.stderr}", file=sys.stderr)
        sys.exit(1)
