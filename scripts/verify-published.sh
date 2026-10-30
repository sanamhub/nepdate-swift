#!/usr/bin/env bash
# Checks a released tag the way a user gets it: a fresh SwiftPM package outside this checkout depends
# on https://github.com/sanamhub/nepdate-swift with .exact(VERSION), builds the two Examples programs
# against it, and must print what the same programs print when built from this checkout. A tag that
# resolves to other code, or a package that does not build from its URL, fails here.
#
#   scripts/verify-published.sh 0.1.0-beta.1
#   scripts/verify-published.sh latest --standalone
#   scripts/verify-published.sh --revision <commit on GitHub>
#   scripts/verify-published.sh latest --resolve
#   scripts/verify-published.sh latest --metadata
#
# latest is the first non-draft release of the GitHub releases API, which is what a user finds on
# the Releases page; the tags carry no v. The resolved tag is printed before anything is installed.
# --resolve prints it alone and exits, so a workflow can pass it to the later jobs.
#
# A plain <version> call compares the published package with a checkout of that tag, so run it from
# the repository root of that checkout. --standalone is for a scheduled run, where there is no
# checkout of the tag: it installs the published package alone and compares one date conversion and
# the New Year event with the text below. The --revision form is what CI runs before any tag exists:
# same consumer, same comparison, pinned to a pushed commit instead.
#
# --metadata reads the releases API, confirms that the tag is released, and sends a HEAD request to
# its tarball; it downloads no package file. --manager names the package manager, and only SwiftPM
# publishes this package.
set -euo pipefail

registry="https://api.github.com/repos/sanamhub/nepdate-swift"
user_agent="nepdate-verify-published"

mode=install
version=""
revision=""
standalone=0
manager=swiftpm
while [ $# -gt 0 ]; do
  case "$1" in
    --resolve) mode=resolve; shift ;;
    --metadata) mode=metadata; shift ;;
    --standalone) standalone=1; shift ;;
    --manager)
      manager="${2:-}"
      if [ -z "$manager" ]; then
        echo "verify-published: --manager needs a name"
        exit 2
      fi
      shift 2
      ;;
    --revision)
      revision="${2:-}"
      shift 2
      ;;
    -*)
      echo "verify-published: unknown argument '$1'"
      exit 2
      ;;
    *)
      version="$1"
      shift
      ;;
  esac
done

case "$manager" in
  swiftpm) ;;
  *)
    echo "verify-published: '$manager' is not a package manager for nepdate-swift; use swiftpm"
    exit 2
    ;;
esac

if [ -n "$revision" ]; then
  if ! printf '%s' "$revision" | grep -Eq '^[0-9a-f]{40}$'; then
    echo "verify-published: --revision needs a full 40-character commit hash"
    exit 1
  fi
  if [ "$mode" != install ] || [ "$standalone" -ne 0 ]; then
    echo "verify-published: --revision cannot be combined with --resolve, --metadata or --standalone"
    exit 2
  fi
  version="$revision"
fi

registry_json() {
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl -fsS --retry 3 -H "Accept: application/vnd.github+json" \
      -H "User-Agent: ${user_agent}" -H "Authorization: Bearer ${GITHUB_TOKEN}" "${registry}/$1"
  else
    curl -fsS --retry 3 -H "Accept: application/vnd.github+json" \
      -H "User-Agent: ${user_agent}" "${registry}/$1"
  fi
}

# The first non-draft release, newest first as the API lists them. A pre-release counts: while the
# package has no stable release, the newest published tag is the version a user installs.
latest_version() {
  local json tags tag
  json="$(registry_json releases)"
  tags="$(printf '%s' "$json" | jq -r '.[] | select(.draft == false) | .tag_name')"
  tag="$(printf '%s\n' "$tags" | sed -n '1p')"
  if [ -z "$tag" ]; then
    echo "verify-published: ${registry}/releases lists no published release" >&2
    exit 1
  fi
  printf '%s' "$tag"
}

version="${version:-latest}"
if [ -z "$revision" ] && [ "$version" = latest ]; then
  version="$(latest_version)"
  if [ "$mode" != resolve ]; then
    echo "verify-published: nepdate-swift latest release is ${version}"
  fi
fi
if [ "$mode" = resolve ]; then
  printf '%s\n' "$version"
  exit 0
fi

if [ -z "$revision" ]; then
  if [ "$mode" = install ] && [ "$standalone" -eq 0 ]; then
    bash scripts/release-check.sh "$version" > /dev/null || {
      echo "verify-published: '$version' is not a release version with a changelog section here"
      exit 1
    }
  fi
  if ! printf '%s' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'; then
    echo "verify-published: '$version' is not a release tag like 0.1.0 or 0.1.0-beta.1"
    exit 2
  fi
fi

# The daily check: the releases API still lists the tag and its tarball still answers. A deleted
# release or a tarball that answers 404 fails here, a day before a user would find it.
if [ "$mode" = metadata ]; then
  json="$(registry_json releases)"
  tag="$(printf '%s' "$json" | jq -r --arg v "$version" \
    '.[] | select(.draft == false and .tag_name == $v) | .tag_name' | sed -n '1p')"
  if [ -z "$tag" ]; then
    echo "verify-published: GitHub lists no release tagged ${version} for nepdate-swift"
    exit 1
  fi
  tarball="$(printf '%s' "$json" | jq -r --arg v "$version" \
    '.[] | select(.draft == false and .tag_name == $v) | .tarball_url' | sed -n '1p')"
  if [ -z "$tarball" ]; then
    echo "verify-published: the release ${version} has no tarball_url"
    exit 1
  fi
  # -I sends HEAD and -L follows GitHub's redirect to the archive host; neither fetches the file.
  code="$(curl -sS -o /dev/null -w '%{http_code}' -I -L --retry 3 "$tarball")"
  if [ "$code" != 200 ]; then
    echo "verify-published: ${tarball} answered ${code}"
    exit 1
  fi
  echo "verify-published: nepdate-swift ${version} is released and its tarball answers 200"
  exit 0
fi

url="https://github.com/sanamhub/nepdate-swift"
if [ -n "$revision" ]; then
  requirement="revision: \"$revision\""
else
  requirement="exact: \"$version\""
fi
root="$(pwd)"
consumer="$(mktemp -d)"
trap 'rm -rf "$consumer"' EXIT
# On Windows this runs in Git Bash, whose /tmp paths swift.exe cannot open.
if command -v cygpath > /dev/null; then
  root="$(cygpath -m "$root")"
  consumer="$(cygpath -m "$consumer")"
fi

if [ "$standalone" -eq 1 ]; then
  mkdir -p "$consumer/Sources/published-check"
  cat > "$consumer/Sources/published-check/main.swift" <<'EOF'
// The one conversion and one patro lookup the scheduled check compares. The fallbacks turn a broken
// value into wrong output, which the caller reports, instead of a trap.
import NepDate
import NepDatePatro

let date = (try? NepaliDate(year: 2081, month: 4, day: 15)) ?? .min
let ad = date.gregorian
print("date: \(date) -> AD \(ad.year)-\(ad.month)-\(ad.day)")

let newYear = (try? NepaliDate(year: 2081, month: 1, day: 1)) ?? .min
let events = newYear.calendarInfo.events.map { $0.english }
if events.contains("New Year") {
  print("new year: New Year")
} else {
  print("new year: none")
}
EOF
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
      name: "published-check",
      dependencies: [
        .product(name: "NepDate", package: "nepdate-swift"),
        .product(name: "NepDatePatro", package: "nepdate-swift"),
      ]),
  ],
  swiftLanguageModes: [.v6]
)
EOF
else
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
fi

echo "verify-published: resolving $url at $version"
swift package --package-path "$consumer" resolve
dependencies="$(swift package --package-path "$consumer" show-dependencies)"
printf '%s\n' "$dependencies"
# For a tag the text form prints the dependency as <URL@VERSION>. A revision has no version, so
# Package.resolved is where the pinned commit shows.
if [ -n "$revision" ]; then
  if ! grep -Fq "\"$revision\"" "$consumer/Package.resolved"; then
    echo "verify-published: Package.resolved does not pin $revision"
    exit 1
  fi
elif ! printf '%s' "$dependencies" | grep -Fq "@$version>"; then
  echo "verify-published: nepdate-swift did not resolve to $version"
  exit 1
fi

swift build -c release --package-path "$consumer"

# The programs run from the build directory, not with `swift run`: on Windows, swift run under Git
# Bash could not start a program built in a cygpath -m temp directory ("exec error: No such file or
# directory"), while the built .exe itself runs fine.
bin_path() {
  local bin
  bin="$(swift build -c release --package-path "$1" --show-bin-path)"
  if command -v cygpath > /dev/null; then bin="$(cygpath -u "$bin")"; fi
  printf '%s' "$bin"
}
run_program() {
  if [ -f "$1/$2.exe" ]; then "$1/$2.exe"; else "$1/$2"; fi
}
consumer_bin="$(bin_path "$consumer")"

# A scheduled run has no checkout of the tag, so there is nothing to compare with: the published
# package alone must print the fixed text. The two lines are one conversion and the New Year event.
if [ "$standalone" -eq 1 ]; then
  got="$(run_program "$consumer_bin" published-check | tr -d '\r')"
  want="date: 2081/04/15 -> AD 2024-07-30
new year: New Year"
  echo "== published-check (published $version)"
  printf '%s\n' "$got"
  if [ "$got" != "$want" ]; then
    echo "verify-published: the published package printed other output; expected:"
    printf '%s\n' "$want"
    exit 1
  fi
  echo "verify-published: ok: nepdate-swift $version from $url, published package alone"
  exit 0
fi

swift build -c release --package-path "$root/Examples"
examples_bin="$(bin_path "$root/Examples")"

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
