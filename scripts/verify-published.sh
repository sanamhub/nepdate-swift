#!/usr/bin/env bash
# Checks a released tag the way a user gets it: a fresh SwiftPM package outside this checkout depends
# on https://github.com/sanamhub/nepdate-swift with .exact(VERSION), builds the two Examples programs
# against it, and must print what the same programs print when built from this checkout. A tag that
# resolves to other code, or a package that does not build from its URL, fails here.
#
#   scripts/verify-published.sh 0.1.0-beta.1
#   scripts/verify-published.sh --revision <commit on GitHub>
#
# Run from the repository root of a checkout of that tag or commit. The --revision form is what CI
# runs before any tag exists: same consumer, same comparison, pinned to a pushed commit instead.
set -euo pipefail

if [ "${1:-}" = "--revision" ]; then
  revision="${2:-}"
  if ! printf '%s' "$revision" | grep -Eq '^[0-9a-f]{40}$'; then
    echo "verify-published: --revision needs a full 40-character commit hash"
    exit 1
  fi
  requirement="revision: \"$revision\""
  version="$revision"
else
  version="${1:-}"
  bash scripts/release-check.sh "$version" > /dev/null || {
    echo "verify-published: '$version' is not a release version with a changelog section here"
    exit 1
  }
  requirement="exact: \"$version\""
fi

url="https://github.com/sanamhub/nepdate-swift"
root="$(pwd)"
consumer="$(mktemp -d)"
trap 'rm -rf "$consumer"' EXIT
# On Windows this runs in Git Bash, whose /tmp paths swift.exe cannot open.
if command -v cygpath > /dev/null; then
  root="$(cygpath -m "$root")"
  consumer="$(cygpath -m "$consumer")"
fi

mkdir -p "$consumer/Sources/core-only" "$consumer/Sources/with-patro"
cp Examples/Sources/core-only/main.swift "$consumer/Sources/core-only/main.swift"
cp Examples/Sources/with-patro/main.swift "$consumer/Sources/with-patro/main.swift"
cat > "$consumer/Package.swift" <<EOF
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Consumer",
  platforms: [.macOS(.v12)],
  dependencies: [
    .package(url: "$url", $requirement)
  ],
  targets: [
    .executableTarget(
      name: "core-only",
      dependencies: [.product(name: "NepDate", package: "nepdate-swift")]),
    .executableTarget(
      name: "with-patro",
      dependencies: [
        .product(name: "NepDate", package: "nepdate-swift"),
        .product(name: "NepDatePatro", package: "nepdate-swift"),
      ]),
  ],
  swiftLanguageModes: [.v6]
)
EOF

echo "verify-published: resolving $url at $version"
swift package --package-path "$consumer" resolve
dependencies="$(swift package --package-path "$consumer" show-dependencies)"
printf '%s\n' "$dependencies"
# For a tag the text form prints the dependency as <URL@VERSION>. A revision has no version, so
# Package.resolved is where the pinned commit shows.
if [ -z "${revision:-}" ]; then
  if ! printf '%s' "$dependencies" | grep -Fq "@$version>"; then
    echo "verify-published: nepdate-swift did not resolve to $version"
    exit 1
  fi
elif ! grep -Fq "\"$revision\"" "$consumer/Package.resolved"; then
  echo "verify-published: Package.resolved does not pin $revision"
  exit 1
fi

swift build -c release --package-path "$consumer"
swift build -c release --package-path "$root/Examples"

# The programs run from the build directory, not with `swift run`: on Windows, swift run under Git
# Bash could not start a program built in a cygpath -m temp directory ("exec error: No such file or
# directory"), while the built .exe itself runs fine.
bin_path() {
  local bin
  bin="$(swift build -c release --package-path "$1" --show-bin-path)"
  if command -v cygpath > /dev/null; then bin="$(cygpath -u "$bin")"; fi
  printf '%s' "$bin"
}
consumer_bin="$(bin_path "$consumer")"
examples_bin="$(bin_path "$root/Examples")"
run_program() {
  if [ -f "$1/$2.exe" ]; then "$1/$2.exe"; else "$1/$2"; fi
}

failed=0
for program in core-only with-patro; do
  want="$(run_program "$examples_bin" "$program")"
  got="$(run_program "$consumer_bin" "$program")"
  echo "== $program (published $version)"
  printf '%s\n' "$got"
  if [ -z "$got" ] || [ "$got" != "$want" ]; then
    echo "verify-published: $program differs from the checkout build"
    printf 'want:\n%s\n' "$want"
    failed=1
  fi
done
# The patro program must really read the almanac: BS 2081-01-01 is New Year.
if ! run_program "$consumer_bin" with-patro | grep -q 'New Year'; then
  echo "verify-published: with-patro printed no New Year event for 2081-01-01"
  failed=1
fi
if [ "$failed" -ne 0 ]; then
  exit 1
fi
echo "verify-published: ok: nepdate-swift $version from $url"
