#!/usr/bin/env bash
# Release preflight (ADR-0005): the version is a SwiftPM tag without a `v`, either X.Y.Z or a semver
# pre-release such as 0.1.0-beta.1, and CHANGELOG.md has its own dated section. A stable section does
# not satisfy a pre-release tag, nor the other way round, because the heading is matched exactly.
#
#   scripts/release-check.sh 0.1.0-beta.1 [CHANGELOG.md]
#   scripts/release-check.sh --print [CHANGELOG.md]
#
# --print reads the newest released heading from the changelog and validates it the same way, for
# the CI job that passes the port's version to the hub's version check.
set -euo pipefail

print_mode=0
if [ "${1:-}" = "--print" ]; then
  print_mode=1
  shift
fi

if [ "$print_mode" -eq 1 ]; then
  changelog="${1:-CHANGELOG.md}"
  version=""
else
  version="${1:-}"
  changelog="${2:-CHANGELOG.md}"
fi

if [ ! -f "$changelog" ]; then
  echo "release-check: $changelog not found"
  exit 1
fi
if [ "$print_mode" -eq 1 ]; then
  # Keep a Changelog lists the newest section first; only a dated release heading counts.
  version="$(awk '
    /^## \[[^]]+\] - [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][[:space:]]*$/ {
      line = $0
      sub(/^## \[/, "", line)
      sub(/\].*/, "", line)
      print line
      exit
    }
  ' "$changelog")"
  if [ -z "$version" ]; then
    echo "release-check: $changelog has no '## [VERSION] - YYYY-MM-DD' section"
    exit 1
  fi
fi

ident='(0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)'
pattern="^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-$ident(\.$ident)*)?$"

if ! printf '%s' "$version" | grep -Eq "$pattern"; then
  echo "release-check: '$version' is not X.Y.Z or X.Y.Z-PRERELEASE (no v, no build metadata)"
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
if [ "$print_mode" -eq 1 ]; then
  printf '%s\n' "$version"
else
  echo "release-check: $version ok"
fi
