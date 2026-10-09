# Changelog

All notable changes to this package are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions are SwiftPM tags without a `v`
prefix (ADR-0005).

## [Unreleased]

### Added

- SwiftPM package `NepDate` with product `NepDate` (S0-01).
- `Tools/Codegen` package: `codegen` writes `Calendar.generated.swift` from `shared/data`, `--check` fails on drift (S0-02).
- `scripts/ci.sh` and `scripts/ci.ps1` run the seven gates of ADR-0004; `coverage-check` enforces 90 % line coverage on Linux (S0-03).
- CI on macOS, Linux and Windows; Dependabot for actions; community files (S0-04).
- `NepaliDate` (8 bytes) with `init(year:month:day:)`, `init(gregorianYear:month:day:)`, `min`,
  `max`, `year`, `month`, `day`, `bsMonth`, `weekday`, `dayOfYear`, `monthLength`,
  `firstDayOfMonth`, `lastDayOfMonth` and `gregorian`; `Month`, `Weekday`, `Lang` and
  `NepDateError` (S1-02 to S1-04).
- Generated `monthStart` and `monthAtBucket` tables (S1-01).
- `Benchmarks` package with B1 and B2 and a zero-malloc threshold, run by the `bench` CI job (S1-07).
- `adding(days:)`, `days(until:)`, `adding(months:overflow:)`, `adding(years:overflow:)` with
  `MonthOverflow`, and `diff(to:)` with `DateDiff` (S2-01 to S2-03).
- `FiscalYear`, `Quarter`, `NepaliDate.fiscalYear` and `NepaliDate.quarter` (S2-04).
- `NepaliDateRange`, a random-access collection of days with O(1) `count` and `contains` (S2-05).
- Benchmarks B3, B4 and one month's range iteration (S2-06).
