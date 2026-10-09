# S5: Docs, benchmarks, release 0.1.0

Read first: ADR-0002 §7, `shared/spec/BENCHMARK.md`, ADR-0005, `docs/competitors.md`, `docs/runbooks/release.md`,
`shared/spec/PORT-PLAN.md` phase 5.

## Tasks

### S5-01 DocC and README quick start
- A DocC comment on every public symbol (summary, `- Parameters:`, `- Returns:`, `- Throws:`);
  gate 1 enforces it through `.swift-format`. `Sources/NepDate/NepDate.docc/NepDate.md` (landing
  page: what it is, range BS 1901-01-01 to 2199-12-30, the `Calendar.Identifier.vikram` warning
  from the README, and that tithi, holidays and events live in `NepDatePatro`).
- README `## Quick start`: two fenced `swift` blocks, byte for byte the contents of
  `Examples/Sources/core-only/main.swift` and `Examples/Sources/with-patro/main.swift` (S4-03).
- `readme-check`, a third executable target in `Tools/Codegen`, extracts the `swift` blocks under
  `## Quick start` and exits 1 if they differ from those two files. Add it to gate 5 in both CI
  scripts (after `codegen --check`).
- The macOS CI job also runs `xcodebuild docbuild -scheme NepDate -destination 'generic/platform=macOS'`
  and fails on any DocC warning. The maintainer has no Mac, so this job is how DocC is checked.
- AC1: CI green with gate 1 and the docbuild step.
- AC2: changing one character in a README quick start block makes `readme-check` exit 1.

### S5-02 Full benchmarks: B1 to B8, competitors, C# ratio (`Benchmarks/`)
The reference machine (Windows) can't run package-benchmark, which supports only Linux and macOS
(BENCHMARK §1). So the Swift numbers come from GitHub runners and are never put in the reference
machine's column; the comparison with C# is a ratio measured on the same runner.
- `Benchmarks/Package.swift` (from S1-07) adds the vendored MIT source of `NepaliDateConverter` in
  `Benchmarks/Vendor/NepaliDateConverter/` with its licence, and the shivathapaa XCFramework as a
  binary target at an exact version (macOS arm64 only, behind `#if os(macOS) && arch(arm64)`).
- Our benchmarks: B1 to B8 exactly as in BENCHMARK §2 and §3 (64 inputs computed in setup,
  `blackHole` on every result, scaling factor 64), plus B5a and `B7-sorted` from earlier phases.
  Metrics `.wallClock`, `.cpuTotal`, `.mallocCountTotal`, `.instructions`.
- Competitor benchmarks: B1 and B2 for each library in `docs/competitors.md` with a conversion
  API, over the same 64 dates, with mallocs. The 64 dates are inside BS 2000 to 2090, which both
  competitors cover. An "agrees" column: does each competitor give the `shared/data` answer for
  all 64 dates (a test in `Benchmarks/Tests`, not a timing)?
- C# column: workflow `.github/workflows/bench-full.yml` (`workflow_dispatch`) runs on
  `ubuntu-latest` and `macos-latest`. Each job runs our benchmarks, the competitors, and then the
  hub's `tools/dotnet-bench` (checked out at the commit in `shared/VERSION`, .NET 10, the NepDate
  version it pins) on the same runner. A small script divides Swift ns/op by C# ns/op per ID. The
  reference-machine C# numbers are copied from the hub's `docs/benchmarks/dotnet.md` into a
  separate column labelled "C#, reference machine".
- Publish `docs/benchmarks.md` in the BENCHMARK §5 layout: per runner, the CPU model, OS, Xcode or
  Swift version, .NET version, date and workflow run URL; then one table: ID, ours ns/op, mallocs,
  each competitor's ns/op and agrees, C# ns/op on the same runner, ratio ours/C#, C# on the
  reference machine.
- Targets are ADR-0002 §7: B1, B2, B7 ratio ≤ 1.5 on both runners; mallocs 0 for B1 to B4, B5a,
  B6 to B8, and 1 for B5. If one is missed, report it with the numbers; don't guess-optimise.
- AC1: `docs/benchmarks.md` has all eight IDs for both runners, with ratio and malloc columns
  filled, and a row for each competitor with a conversion API (B1, B2, agrees).
- AC2: the ratio for B1, B2 and B7 is ≤ 1.5 on both runners, or the miss is reported to the human
  with the numbers before S5-05.
- AC3: every malloc count equals its threshold; the `bench` job's thresholds check passes.

### S5-03 Size measurement
In the `macos-latest` job of `bench-full.yml`: build `Examples` with `-c release` for arm64, run `strip` on all three
executables and record `core-only` minus `baseline` and `with-patro` minus `baseline` in bytes in
`docs/benchmarks.md`.
- AC: both numbers are in `docs/benchmarks.md`; `with-patro` minus `baseline` < 200 KB
  (ADR-0002 §7), or the miss is reported.

### S5-04 Release workflow
`.github/workflows/release.yml` per ADR-0005 and `docs/runbooks/release.md`: on a tag push, a
preflight job (tag matches `^[0-9]+\.[0-9]+\.[0-9]+$` and `CHANGELOG.md` has `## [<tag>] - `),
the CI jobs, then a job in environment `production` that creates the GitHub Release with that
changelog section as notes (`gh release create`, `permissions: contents: write` on that job only).
- AC: a `workflow_dispatch` dry run on a test branch, with input `tag: 0.0.1` (no tag pushed) and a
  `## [0.0.1] - <date>` section in that branch's changelog, passes preflight and CI and skips the
  release job.

### S5-05 0.1.0
Move `[Unreleased]` to `## [0.1.0] - <date>`. **Agent stops here.** The human tags `0.1.0`,
approves the release and registers the package on the Swift Package Index (ADR-0005).

## Checkpoint
The agent stops at S5-05. The reviewer checks:
- [ ] DocC builds without warnings on macOS; `readme-check` fails on a one-character change.
- [ ] `docs/benchmarks.md` follows BENCHMARK §5, names the runners and says the reference machine
  couldn't run the Swift benchmarks.
- [ ] B1, B2, B7 ratios against C# on the same runner, every malloc count, and the size numbers
  are present; each miss is reported, not hidden.
- [ ] Every competitor row has an "agrees" value; a disagreeing library is not ranked first.
- [ ] The release workflow dry run passed preflight and skipped the release job.
- [ ] `CHANGELOG.md` has `## [0.1.0] - <date>`; no tag was pushed by the agent.
