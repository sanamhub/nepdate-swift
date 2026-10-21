#!/usr/bin/env bash
# Positive and negative cases for scripts/release-check.sh. Each case writes its own changelog, so
# the test does not depend on what CHANGELOG.md says today.
set -euo pipefail

check="$(cd "$(dirname "$0")" && pwd)/release-check.sh"
dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT
failures=0

expect() { # expect ok|fail VERSION CHANGELOG-TEXT
  printf '%b' "$3" > "$dir/CHANGELOG.md"
  if bash "$check" "$2" "$dir/CHANGELOG.md" > "$dir/out" 2>&1; then got=ok; else got=fail; fi
  if [ "$got" != "$1" ]; then
    echo "FAIL: release-check '$2' gave $got, want $1 ($(cat "$dir/out"))"
    failures=$((failures + 1))
  fi
}

stable='## [Unreleased]\n\n## [0.1.0] - 2026-10-21\n'
beta='## [Unreleased]\n\n## [0.1.0-beta.1] - 2026-10-21\n'

expect ok   0.1.0         "$stable"
expect ok   0.1.0-beta.1  "$beta"
expect ok   1.2.3-rc.10   '## [1.2.3-rc.10] - 2026-01-02\n'
# A beta tag cannot use the stable section, nor a stable tag the beta one.
expect fail 0.1.0         "$beta"
expect fail 0.1.0-beta.1  "$stable"
# The dots are literal: 0x1x0 must not match a 0.1.0 heading.
expect fail 0.1.0         '## [0x1x0] - 2026-10-21\n'
# Malformed versions.
expect fail v0.1.0        '## [v0.1.0] - 2026-10-21\n'
expect fail 0.1           '## [0.1] - 2026-10-21\n'
expect fail 01.1.0        '## [01.1.0] - 2026-10-21\n'
expect fail 0.1.0-        '## [0.1.0-] - 2026-10-21\n'
expect fail 0.1.0-beta..1 '## [0.1.0-beta..1] - 2026-10-21\n'
expect fail 0.1.0-beta.01 '## [0.1.0-beta.01] - 2026-10-21\n'
expect fail 0.1.0+build.1 '## [0.1.0+build.1] - 2026-10-21\n'
expect fail ''            "$stable"
# The section needs a full date.
expect fail 0.1.0         '## [0.1.0]\n'
expect fail 0.1.0         '## [0.1.0] - 2026-10\n'
expect fail 0.1.0         '## [0.1.0] - soon\n'
expect fail 0.1.0         '### [0.1.0] - 2026-10-21\n'

if [ "$failures" -ne 0 ]; then
  echo "test-release-check: $failures case(s) failed"
  exit 1
fi
echo "test-release-check: 18 cases ok"
