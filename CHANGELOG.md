# Changelog

All notable changes to this package are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions are SwiftPM tags without a `v`
prefix (ADR-0005).

## [Unreleased]

### Added

- A canonical-shape fast path in the strict parser, with an exhaustive differential test and a
  differential fuzz target.

## [0.1.0] - 2026-10-18

### Added

- SwiftPM package `NepDate` with product `NepDate`.
- `Tools/Codegen` package: `codegen` writes `Calendar.generated.swift` from `shared/data`, `--check` fails on drift.
- `scripts/ci.sh` and `scripts/ci.ps1` run the eight gates of ADR-0004; `coverage-check` enforces 90 % line coverage on Linux.
- CI on macOS, Linux and Windows; Dependabot for actions; community files.
- `NepaliDate` (8 bytes) with `init(year:month:day:)`, `init(gregorianYear:month:day:)`, `min`,
  `max`, `year`, `month`, `day`, `bsMonth`, `weekday`, `dayOfYear`, `monthLength`,
  `firstDayOfMonth`, `lastDayOfMonth` and `gregorian`; `Month`, `Weekday`, `Lang` and
  `NepDateError`.
- Generated `monthStart` and `monthAtBucket` tables.
- `Benchmarks` package with B1 and B2 and a zero-malloc threshold, run by the `bench` CI job.
- `adding(days:)`, `days(until:)`, `adding(months:overflow:)`, `adding(years:overflow:)` with
  `MonthOverflow`, and `diff(to:)` with `DateDiff`.
- `FiscalYear`, `Quarter`, `NepaliDate.fiscalYear` and `NepaliDate.quarter`.
- `NepaliDateRange`, a random-access collection of days with O(1) `count` and `contains`.
- Benchmarks B3, B4 and one month's range iteration.
- Month and weekday names, `nepaliDigits`, `description`, `short`, `long`, `format` and their
  `append…(to:)` forms, `DateOrder` and `Separator`.
- Strict `parse`, `init?(_:)`, lenient `parseLenient` with the generated month list, and
  `Codable` as `"YYYY-MM-DD"`.
- Benchmarks B5, B5a and B6; the `Fuzz` package and CI job.
- `NepDatePatro` product with tithi, public holiday and event tables, `calendarInfo`, `Patro.coverage`
  and `Patro.publicHolidays`.
- `Examples` package and the patro-free core gate.
- `Date` and `TimeZone` interop: `init(_:in:)`, `date(in:)` and `today(in:)`.
- Benchmarks B7, B8 and B7-sorted.
- DocC catalogue, and a README quick start that `readme-check` keeps byte for byte equal to the
  `Examples` programs.
- `docs-check`: no em dash, no internal task ID and no broken relative link in the pages a user reads.
- Full benchmarks B1 to B8 on GitHub runners, against the Swift competitors and C# NepDate on the
  same runner, with allocation counts and stripped binary sizes (`docs/benchmarks.md`).
- `release.yml`: tag and changelog preflight, the CI jobs, and a GitHub Release built from this
  changelog behind the `production` environment.
