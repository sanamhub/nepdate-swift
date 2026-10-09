# ADR-0004: Testing and quality gates

- Status: Accepted
- Date: 2026-10-06 (tests and CI jobs extended 2026-10-07)
- Deciders: Sanam Pakuwal

## Decision

`./scripts/ci.sh` runs, in order, printing each command, stopping at the first failure and ending
with one summary line (`ci: 7/7 gates passed`):

1. `swift format lint --strict --recursive Sources Tests`, with the repository's `.swift-format`
   (which turns on `AllPublicDeclarationsHaveDocumentation` and `ValidateDocumentationComments`).
2. `swift build -c release -Xswiftc -warnings-as-errors --explicit-target-dependency-import-check error`.
   The import check makes an `import NepDatePatro` inside `Sources/NepDate` a build error.
3. `swift build --target NepDate`: the core builds on its own.
4. `swift test --enable-code-coverage`: test targets `NepDateTests` (depends on `NepDate` only) and
   `NepDatePatroTests`; line coverage ≥ 90 % for the files under `Sources/NepDate/` and, from S4,
   `Sources/NepDatePatro/` (org target 80 %), read from the JSON at `swift test --show-codecov-path`.
5. `swift run --package-path Tools/Codegen codegen --check`; from S5, also `readme-check` (the
   README quick start equals the `Examples` sources).
6. From S4: patro-free core. `swift build -c release --package-path Examples`; the binary
   `Examples/.build/release/with-patro` must contain the bytes
   `World Day Against Human Trafficking` (proves the check can see the string) and
   `Examples/.build/release/core-only`, which links only `NepDate`, must not (hub PORT-PLAN
   phase 4). Checked with `grep -a -q`.
7. Public API check: `swift package diagnose-api-breaking-changes <last-tag>` (from 0.1.1 on).

Gates that don't apply yet (6 before S4, 7 before 0.1.0) print `skipped` and count as passed.

## Tests (swift-testing)

| Kind | Where | Rule |
|---|---|---|
| Shared vectors | `Tests/NepDateTests/Vectors*.swift` | files under `shared/spec/vectors/`, read with `#filePath`-relative paths. Files under 1,000 rows are `@Test(arguments:)` per row; larger files loop inside one test, assert the row count and report the first 10 failing rows with line numbers (one swift-testing case per row is slow at 10,000 rows) |
| C# catalogue | one test per row of `docs/plan/00-ROADMAP.md` "C# test catalogue", named after the row id; theory rows are one parameterised test with the `InlineData` rows as arguments in order | rows tagged with a deviation get a comment naming the D-ID instead |
| Exhaustive | `Exhaustive.swift` | all 109,212 serials round-trip through `init(serial:)`, `init(year:month:day:)` and `init(gregorianYear:month:day:)` |
| Property | `Properties.swift` | a seeded SplitMix64 generator (fixed seed in the file, 100,000 cases per property); properties listed in each phase file |
| Compile-time | `CompileTime.swift` | `requireSendable(T.self)` for every public type, `requireBitwiseCopyable(NepaliDate.self)`, `MemoryLayout<NepaliDate>.size == 8`; the file fails to compile if a type loses a conformance |
| Thread safety | `Concurrency.swift` | 8 tasks in a `TaskGroup` read every table and convert 10,000 dates each on first access; results equal a single-threaded run |
| Allocation | `Benchmarks/` (package-benchmark 1.36.4) | `mallocCountTotal` static thresholds per benchmark (ADR-0002 §7); `swift package --package-path Benchmarks benchmark thresholds check` fails the `bench` job on any extra malloc. Swift 6.3 and later count mallocs with the package's interposer, so the Linux image needs no jemalloc |
| Fuzzing | `Fuzz/` (Linux only), from S3 | libFuzzer targets for `parse`, `parseLenient` and `format`, built with `-sanitize=fuzzer,address`, 60 seconds each per CI run, corpus seeded from `parse.tsv`; a crash or sanitizer report fails the job |
| Interop | `NepDateTests/Foundation*.swift` | `Date` across `Asia/Kathmandu`, `America/New_York` (DST) and UTC; `Codable` round trips |

## CI jobs

- `macos` (latest stable Xcode), `linux` (`swift:6.4` image) and `windows` (swift.org 6.4 toolchain,
  `scripts/ci.ps1` running the same steps). Coverage (gate 4) and the
  `World Day Against Human Trafficking` check (gate 6) are enforced on Linux; `ci.ps1` runs the
  tests without the coverage threshold and prints `skipped` for gate 6.
- `bench` (Linux, every PR from S1): the malloc thresholds above. Times are printed, not gated,
  because shared runners are noisy.
- `fuzz` (Linux, every PR from S3).
- `bench-full` (`workflow_dispatch`, from S5): B1 to B8 on `ubuntu-latest` and `macos-latest`,
  competitors, and the hub's `tools/dotnet-bench` on the same runner for the C# ratio
  (S5-02).

Actions are pinned by SHA; `permissions: contents: read`.
