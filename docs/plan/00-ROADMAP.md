# Roadmap (Swift port)

Each phase is one PR (or a short series). Task IDs `S<phase>-<n>`; commit
`feat(nepdate): S1-03 serial conversion`. The phases are the ones in `shared/spec/PORT-PLAN.md`
(the same for every port); each phase file lists its tasks with the Swift names from
`docs/API.md` and an acceptance criterion (AC) per task. A PORT-PLAN AC that a phase file doesn't
repeat still applies.

```
S0 package + CI ─► S1 core + conversion ─► S2 arithmetic/fiscal/range ─┐
                            └────────────► S3 format + parse ──────────┴─► S4 patro + Foundation interop ─► S5 docs, bench, 0.1.0
```

Preconditions: hub H0 merged (first `shared/VERSION`); hub H3 before S0-04. S2 and S3 may run in
parallel. `nepdate-mobile` phase I1 needs S4 (it can use the package from a local path before
0.1.0).

| Phase | File | Output |
|---|---|---|
| S0 | [`S0-package-and-ci.md`](S0-package-and-ci.md) | `Package.swift`, `.swift-format`, `Tools/Codegen` skeleton, `scripts/ci.sh` and `scripts/ci.ps1`, CI (macOS, Linux, Windows), community files, `.spi.yml` |
| S1 | [`S1-core-and-conversion.md`](S1-core-and-conversion.md) | `NepaliDate` (8 bytes), `Month`, `Weekday`, `Lang`, `NepDateError`, generated `monthStart` and `monthAtBucket`, serial and Hinnant conversion; vectors + exhaustive tests; `Benchmarks` package with B1, B2 and the `bench` CI job |
| S2 | [`S2-arithmetic-fiscal-range.md`](S2-arithmetic-fiscal-range.md) | `adding(days/months/years)`, `days(until:)`, `diff`, `FiscalYear`, `Quarter`, `NepaliDateRange`; B3, B4 |
| S3 | [`S3-format-and-parse.md`](S3-format-and-parse.md) | `short`, `long`, `format`, the `append…(to:)` forms, `nepaliDigits`, strict and lenient parse, `LosslessStringConvertible`, `Codable`; B5, B6; `Fuzz` package |
| S4 | [`S4-patro-and-interop.md`](S4-patro-and-interop.md) | product `NepDatePatro` (dense per-day tables, ADR-0002 §3), `Examples` package and the `World Day Against Human Trafficking` check, `Date`/`TimeZone` interop, `today(in:)`; B7, B8 |
| S5 | [`S5-docs-bench-release.md`](S5-docs-bench-release.md) | DocC catalogue, README quick start checked in CI, full benchmarks (competitors, C# ratio on the same runner), size measurement, release workflow, 0.1.0 (agent stops at the version bump; human tags) |

Every phase file ends with a "Checkpoint" section. The agent stops there for review (AGENTS.md §3).

## Definition of Done (every task)

1. Every acceptance criterion has a test. 2. `./scripts/ci.sh` passes on macOS and Linux, `./scripts/ci.ps1` on Windows.
3. No public symbol beyond `docs/API.md`, no dependency in the library products, nothing from
   `NepDatePatro` in `NepDate`.
4. `CHANGELOG.md` `[Unreleased]` updated. 5. Prose follows the writing-style skill.

## Milestones

| Milestone | Exit |
|---|---|
| M1 converts | S0–S1: month-boundary vectors + exhaustive round-trip |
| M2 parity | S2–S3: all C# golden rows except `PARITY.md` deviations |
| M3 usable by the iOS app | S4 |
| M4 0.1.0 | S5: tagged, listed on the Swift Package Index |

## C# test catalogue

The hub's `shared/spec/vectors/csharp-tests/catalog.tsv` (hub task H5) lists one row per `[Fact]`
and per `[InlineData]` of C# NepDate's tests at `cb05cb65`. It is in `shared/` since 2026-10-09. This
table maps the same tests to phases; it was made on 2026-10-07 from the C# clone (395
`[Fact]` and 147 `[InlineData]` rows, 542 in all). Where the two differ, the catalogue's `phase` column wins
and any difference is reported to the human.

| C# test class (rows) | Phase |
|---|---|
| `NepaliDateComparableTests` (11) | S1 |
| `DictionaryIntegrityTests` (11) | S1 |
| `NepaliDateConstructionTests` (29): `Constructor_*` | S1 |
| `NepaliDateConstructionTests`: `TryParse_*` | S3 |
| `NepaliDatePropertiesTests` (9): all but `Today_*`, `Equals_*` | S1 |
| `NepaliDatePropertiesTests`: `Today_*` | S4 |
| `NepaliDatePropertiesTests`: `Equals_NullObject`, `Equals_DifferentType` | n/a (no `null` or `object` equality in Swift) |
| `NepaliDateMonthNameTests` (31): `MonthName_SameMonth*` | S1 |
| `NepaliDateMonthNameTests`: the other two methods (they add months) | S2 |
| `NepaliDateManipulationTests` (12): `MonthEndDate_*` | S1 |
| `NepaliDateManipulationTests`: `Subtract_*` | S2 (D-07) |
| `OptimizationVerificationTests` (133): `Operator_*`, `CompareTo_*`, `Equals_*`, `GetHashCode_*`, `Constructor_Min/MaxValue*`, `EnglishDate_*`, `MonthEndDay_*`, `DayOfWeek_*` | S1 |
| `OptimizationVerificationTests`: `Subtraction_*` | S2 |
| `OptimizationVerificationTests`: `ToString_*`, `ToUnicodeString_*`, `UnicodeConversion_*`, `ToLongDateString_*`, `SmartDateParser_*` | S3 |
| `OptimizationVerificationTests`: `*Null*` | n/a (Swift `String` is not optional) |
| `OptimizationVerificationTests`: `BulkConvert_*` | D-10 |
| `OptimizationVerificationTests`: `IsDefault_*` | D-01 |
| `NepaliDateArithmeticEdgeCaseTests` (25): `AddDays_*`, `AddMonths_*` | S2 |
| `NepaliDateArithmeticEdgeCaseTests`: `*HalfMonth*`, `*OneAndHalf*`, `*Fractional*` | D-02 |
| `NepaliDateArithmeticEdgeCaseTests`: `Constructor_DateTime*`, `Constructor_TwoDateTimes*` | S4 |
| `NepaliDateArithmeticEdgeCaseTests`: `TryParse_AutoAdjust_*` | S3 (D-06) |
| `FiscalYearTests` (11), `FiscalYearInstanceMethodTests` (45) | S2 (D-08 shapes) |
| `NepaliDateRangeTests` (19), `NepaliDateRangeExtendedTests` (64): constructors, `SingleDay`, `FromDayCount`, `For*`, `Contains*` (dates), `Enumeration`, `GetEnumerator`, `Equals`, `GetHashCode`, `Operator*Equals` | S2 |
| Range tests: `Current*` | D-14 |
| Range tests: `Contains_RangeFullyContained`, `Overlaps`, `IsAdjacentTo`, `Intersect`, `Union`, `Except`, `Split*`, `WorkingDays`, `WeekendDays`, `DatesWithInterval`, `ToString`, `Demo` | D-09 |
| `NepaliDateFormattableTests` (20), `NepaliDateParsableTests` (5), `SmartDateParserTests` (14), `StringExtensionsTests` (5) | S3 |
| `NepaliDateSerializationTests` (9): `*_String_*` | S3 (`Codable`) |
| `NepaliDateSerializationTests`: `*_Object_*`, `Xml_*` | D-11 |
| `CalendarDataTests` (35) | S4; the 6 `CalendarOffsets_*` rows test C#'s offset table and become checks on `PatroData` (coverage 2,793 days, `dayEventStart` non-decreasing) |
| `DateTimeExtensionsTests` (5) | S4 |
| `NepaliDateIsRelativeTests` (17) | D-14 (each row is written against `today(in:now:)` and `adding(days: ±1)`) |
| `BulkConvertTests` (7) | D-10 |
| `NepaliDateTypeConverterTests` (18) | n/a (`TypeConverter` is .NET only) |
| `MemoryUsageTests` (4), `MemoryOptimizationBenchmark` (3) | n/a (replaced by the malloc thresholds in `Benchmarks/`) |

Row counts per phase: S1 108, S2 139, S3 131, S4 45; deviations 88 (D-01 2, D-02 4, D-09 45,
D-10 9, D-11 3, D-14 25); n/a 31. A deviation row still gets a test where the Swift API has an
equivalent (D-07, D-14), otherwise a comment naming the D-ID.
