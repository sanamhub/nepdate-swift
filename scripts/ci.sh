#!/usr/bin/env bash
# Runs the gates of ADR-0004 in order, stops at the first failure and ends with one summary line.
# scripts/ci.ps1 runs the same gates on Windows; change both together.
set -uo pipefail
cd "$(dirname "$0")/.."

run() {
  echo "+ $*"
  "$@"
}

gate_format() {
  run swift format lint --strict --recursive Sources Tests
}

gate_build() {
  run swift build -c release -Xswiftc -warnings-as-errors \
    --explicit-target-dependency-import-check error
}

gate_build_core() {
  run swift build --target NepDate
}

gate_test() {
  run swift test --enable-code-coverage || return 1
  # Coverage is enforced on Linux only (ADR-0004, CI jobs).
  if [[ "$(uname -s)" != Linux ]]; then
    echo "coverage threshold: skipped (Linux only)"
    return 0
  fi
  local report
  report="$(swift test --show-codecov-path)" || return 1
  run swift run --package-path Tools/Codegen coverage-check "$report"
}

gate_codegen() {
  run swift run --package-path Tools/Codegen codegen --check
}

gate_patro_free() {
  echo "skipped (the Examples package arrives in S4)"
}

gate_api() {
  echo "skipped (starts with 0.1.1)"
}

gates=(format build build_core test codegen patro_free api)
names=(format build build-core test codegen patro-free api)

for i in "${!gates[@]}"; do
  n=$((i + 1))
  echo "== gate $n/${#gates[@]}: ${names[$i]}"
  if ! "gate_${gates[$i]}"; then
    echo "ci: failed at gate $n: ${names[$i]}"
    exit 1
  fi
done
echo "ci: ${#gates[@]}/${#gates[@]} gates passed"
