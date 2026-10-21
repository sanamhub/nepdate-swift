#!/usr/bin/env bash
# Release preflight (ADR-0005): the version is a SwiftPM tag without a `v`, either X.Y.Z or a semver
# pre-release such as 0.1.0-beta.1, and CHANGELOG.md has its own dated section. A stable section does
# not satisfy a pre-release tag, nor the other way round, because the heading is matched exactly.
#
#   scripts/release-check.sh 0.1.0-beta.1 [CHANGELOG.md]
set -euo pipefail

version="${1:-}"
changelog="${2:-CHANGELOG.md}"

ident='(0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)'
pattern="^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-$ident(\.$ident)*)?$"

if ! printf '%s' "$version" | grep -Eq "$pattern"; then
  echo "release-check: '$version' is not X.Y.Z or X.Y.Z-PRERELEASE (no v, no build metadata)"
  exit 1
fi
if [ ! -f "$changelog" ]; then
  echo "release-check: $changelog not found"
  exit 1
fi
# index() compares literally, so the dots in the version are not regex wildcards.
if ! awk -v v="$version" '
  index($0, "## [" v "] - ") == 1 && substr($0, length("## [" v "] - ") + 1) ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ { found = 1 }
  END { exit found ? 0 : 1 }
' "$changelog"; then
  echo "release-check: $changelog has no '## [$version] - YYYY-MM-DD' section"
  exit 1
fi
echo "release-check: $version ok"
