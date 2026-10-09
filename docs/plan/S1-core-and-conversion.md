# S1: Core types and BS ↔ AD conversion

Read first: ADR-0002, ADR-0003, `docs/API.md` (`NepaliDate`, `Month`, `Weekday`, `Lang`,
`NepDateError`), `shared/spec/ALGORITHM.md` §1–7 and §9, `shared/spec/PARITY.md` D-01, D-12,
`shared/spec/PORT-PLAN.md` phase 1, `shared/spec/BENCHMARK.md`.

## Tasks

### S1-01 Generated calendar tables
Extend `codegen` to write, inside `enum CalendarData` in `Calendar.generated.swift` (ADR-0002 §2),
both as `@usableFromInline static let` arrays of integer literals:
`monthStart: [Int32]` (3,589 serials, index `(year - 1901) * 12 + month - 1`, the last one 109212)
and `monthAtBucket: [UInt16]` (6,826 month indexes, entry `b` is the month containing serial
`b * 16`), plus `epochUnixDays: Int32 = -45920`. Write the explicit element type on every array (an
untyped 3,589-element literal is slow to type-check), and one `// 1901` comment per year row of
`monthStart`. No month-length or year-start table: both are differences of `monthStart` entries.
The generator exits 1 if any 16-day bucket would need two month steps (it can't: the shortest
month is 29 days, but check it).
- AC1: a test reads `monthStart[3588] == 109212`, `monthStart[12] == 365` and
  `monthAtBucket.count == 6826`.
- AC2: `codegen --check` passes after `codegen`.

### S1-02 `Lang`, `Month`, `Weekday`, `NepDateError`
Per `docs/API.md`. Names come in S3; here `Month` and `Weekday` are the bare enums with raw values.
`NepDateError` carries only `kind`.
- AC: `Month(rawValue: 13) == nil`; `Weekday.allCases.count == 7` with `.sunday.rawValue == 0`.

### S1-03 Serial conversion (internal)
`NepaliDate` stores `serial: Int32`, `y: Int16`, `m: UInt8`, `d: UInt8` (ADR-0002 §1); `serial` is
`@usableFromInline package let`. Internal `@inlinable init(serial:)`: `i = monthAtBucket[s >> 4]`,
`if s >= monthStart[i + 1] { i += 1 }`, then y/m/d from `i` (ADR-0002 §2). No loop, no binary
search. `init(year:month:day:)` validates in the ALGORITHM §3 order: year → `.outOfRange`, month →
`.invalidMonth`, day → `.invalidDay(monthLength:)`, and takes the serial as
`monthStart[i] + day - 1`. `min` and `max` are built from serials 0 and 109211 without `try!`.
`==`, `<` and `hash(into:)` are written by hand on `serial` only.
- AC1: `NepaliDate(year: 2081, month: 4, day: 32)` succeeds; `day: 33` throws
  `.invalidDay(monthLength: 32)`; `year: 1900` throws `.outOfRange`; `month: 13` throws
  `.invalidMonth`.
- AC2: `MemoryLayout<NepaliDate>.size == 8`, `.stride == 8`, `.alignment == 4` (in
  `CompileTime.swift`, S1-06).

### S1-04 Gregorian, weekday and month properties
`daysFromCivil` / `civilFromDays` per ALGORITHM §5, integers only, no `Calendar`.
`init(gregorianYear:month:day:)` checks the Gregorian date first (`.invalidGregorian`, ALGORITHM §5
validity) and then the range (`.outOfRange`). `gregorian`, `weekday` (§7), `dayOfYear`,
`monthLength`, `bsMonth`, `firstDayOfMonth`, `lastDayOfMonth`. `gregorian` and `weekday` start from
`serial` (`serial + epochUnixDays` is the Unix day); `&+`, `&-`, `&*` only below the range check
(ADR-0002 §6).
- AC1: AD 1844-04-10 and 2143-04-16 throw `.outOfRange`; AD 2023-02-29 throws `.invalidGregorian`.
- AC2: the ALGORITHM §9 table passes as a parameterised test.

### S1-05 Vector and exhaustive tests
- `Tests/NepDateTests/Vectors.swift`: a small TSV/CSV reader (split on `\n`, then on `,` or `\t`;
  skip the header) and a helper that finds `shared/spec/vectors/` from `#filePath`.
- `month-boundaries.csv`: 7176 rows; check `bs` → `ad`, `ad` → `bs`, `weekday`, `month_length`.
- C# golden `dates.tsv` (1018 rows): columns `ad`, `weekday`, `day_of_year`, `month_length`.
- Exhaustive: every serial 0...109211 gives a valid date whose `serial` is the same and whose
  Gregorian date converts back to it.
- AC: the test reports 7176 boundary rows and 1018 golden rows checked (assert the counts, so an
  empty file can't pass).

### S1-06 C# catalogue rows and extra tests
- Every C# catalogue row tagged S1 (`docs/plan/00-ROADMAP.md` "C# test catalogue": 108 rows from
  `NepaliDateComparableTests`, `DictionaryIntegrityTests`, `NepaliDateConstructionTests`
  `Constructor_*`, `NepaliDatePropertiesTests`, `NepaliDateMonthNameTests` `MonthName_SameMonth*`,
  `NepaliDateManipulationTests` `MonthEndDate_*` and the S1 part of `OptimizationVerificationTests`)
  has a test named after the row id in `Tests/NepDateTests/CSharp/<C# class name>.swift`. A
  `[Theory]` is one `@Test(arguments:)` with its `InlineData` rows in order. Rows tagged D-01 get a
  `// D-01` comment, no test. Names that are only C# idioms (`Equals(object)`) stay n/a.
- `CompileTime.swift`: `requireSendable(_:)` for every public type so far,
  `requireBitwiseCopyable(NepaliDate.self)`, and the `MemoryLayout` checks of S1-03 AC2.
- `Properties.swift` (ADR-0004): seeded SplitMix64, 100,000 cases each. P1: for random
  `(year, month, day)` in `1850...2250 × 0...14 × 0...34`, the initialiser either throws the kind
  ALGORITHM §3 predicts or gives a date whose `year`, `month`, `day` equal the input. P2: for random
  serials `a < b`, `init(serial: a) < init(serial: b)`. P3: `init(gregorianYear:month:day:)` of
  `d.gregorian` is `d`.
- `Concurrency.swift`: 8 tasks in a `TaskGroup` start together on first table access and convert
  10,000 dates each; results equal a single-threaded run.
- AC: the test log lists 108 S1 catalogue rows run (or a D-ID comment for each skipped one).

### S1-07 `Benchmarks` package, B1 and B2, first-access cost
- `Benchmarks/Package.swift`: tools 6.0, `ordo-one/package-benchmark` at exact `1.36.4`, this
  package by path. Target `NepDateBenchmarks` with B1 and B2 per `shared/spec/BENCHMARK.md` §2 and
  §3: the 64 inputs are computed in setup, outside the measured region; each iteration runs all 64
  and passes every result to `blackHole`. Metrics `.wallClock`, `.mallocCountTotal`,
  `.instructions`; scaling factor 64 so the report is per operation.
- Thresholds: `.mallocCountTotal` absolute 0 for B1 and B2, checked by
  `swift package --package-path Benchmarks benchmark thresholds check`. Times are printed, not gated.
- CI job `bench` (Linux, `swift:6.4` image, every PR from now on) runs the thresholds check.
- First access (ADR-0002 §7): an executable target `first-access` in `Benchmarks` that, in a fresh
  process, times the first `NepaliDate(gregorianYear: 2024, month: 7, day: 30)` with
  `ContinuousClock` and prints microseconds. Also record whether the `monthStart` and
  `monthAtBucket` accessors call `swift_once` in a release build:
  `objdump -d --no-show-raw-insn` on the `NepDate` object file, `grep -c swift_once` inside the two
  `unsafeMutableAddressor` symbols. Write both results in the PR description.
- AC1: `bench` job green with 0 mallocs for B1 and B2.
- AC2: the PR states the first-access time on the Linux runner (target < 100 µs) and whether
  `swift_once` is present. Don't change the table design if it is; report it.

## Definition of Done
Roadmap DoD + milestone M1.

## Checkpoint
The agent stops here. The reviewer checks:
- [ ] `Calendar.generated.swift` has exactly `monthStart` (3,589) and `monthAtBucket` (6,826), with
  explicit element types; `codegen --check` passes.
- [ ] `init(serial:)` has no loop: one bucket load, at most one step, then arithmetic.
- [ ] `==`, `<`, `hash(into:)` use `serial` only; `MemoryLayout<NepaliDate>.size == 8`.
- [ ] Put ALGORITHM §5 next to the Gregorian file: do the lines match one to one? Every `&+`, `&-`,
  `&*` has a comment naming the range check above it.
- [ ] Exhaustive test covers all 109,212 serials; vector tests assert 7,176 and 1,018 rows.
- [ ] 108 S1 catalogue rows run or carry a D-ID comment; property, compile-time and concurrency
  files exist.
- [ ] `bench` job: B1 and B2 at 0 mallocs; ns/op and the first-access time are in the PR, marked
  "CI runner, not the reference machine".
- [ ] How long does the exhaustive test take on Windows (`swift test --filter Exhaustive`)?
