#!/usr/bin/env python3
"""S7-03: fail unless each stripped Examples delta is under its ADR-0006 target.

ADR-0006 states the targets as strict bounds (<), so a delta equal to the limit fails.

The limits live in Benchmarks/size-targets.json, not in the workflow. Deltas are measured from the
baseline executable, which links neither product.

  python3 size-gate.py --targets Benchmarks/size-targets.json \
    --baseline B --core-only C --with-patro P
"""

import argparse
import json
import os
import sys


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--targets", required=True)
    parser.add_argument("--baseline", required=True)
    parser.add_argument("--core-only", required=True)
    parser.add_argument("--with-patro", required=True)
    arguments = parser.parse_args()

    with open(arguments.targets, encoding="utf-8") as stream:
        targets = json.load(stream)

    baseline = os.path.getsize(arguments.baseline)
    checks = [
        ("core-only", os.path.getsize(arguments.core_only) - baseline, "core_only_max_bytes"),
        ("with-patro", os.path.getsize(arguments.with_patro) - baseline, "with_patro_max_bytes"),
    ]
    failed = False
    for name, value, key in checks:
        limit = int(targets[key])
        status = "ok" if value < limit else "OVER"
        print(f"size-gate: {name} +{value:,} B {status} (limit {limit:,} B)")
        if value >= limit:
            failed = True
    if failed:
        print("size-gate: failed; see docs/adr/0006-binary-size-targets.md")
        return 1
    print("size-gate: all products inside the targets in Benchmarks/size-targets.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
