# Changelog

All notable changes to this package are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions are SwiftPM tags without a `v`
prefix (ADR-0005).

## [Unreleased]

### Added

- `NepaliDate.yearLength`, the length of the BS year, 364 to 367.
- `NepaliDate.isToday(in:)`, `isYesterday(in:)` and `isTomorrow(in:)`, each with an explicit zone.
- `NepaliDate(ymd:)` and `NepaliDate.ymd` for the `YYYYMMDD` integer form, and
  `NepaliDate(lenient:)` for a failable lenient parse.
- Ordered batch conversion both ways: `NepaliDate.fromGregorian(_:in:)`,
  `NepaliDate.gregorianDates(from:in:)` for strings and for dates.
- `Strideable` conformance with an `Int` stride, `distance(to:)`, `advanced(by:)`, and the `+` and
  `-` day operators.
- `NepaliDate.FormatStyle`, `.formatted(_:)` and `.formatted()` where Foundation is available.
- The full range surface: `singleDay`, `NepaliDateRange(start:dayCount:)`, the three `current*`
  factories, `contains` of a range, `overlaps`, `isAdjacent`, `intersection`, `union`,
  `subtracting`, `splitByMonth`, `splitByFiscalQuarter`, `dates(every:)`, `workingDays`,
  `weekendDays`, `description` and `formatted`.
- `NepDateError.Kind.invalidArgument` for a day count or interval below 1.
- `docs/API.md` documents every public member with an example, grouped like the hub inventory.

### Changed

- `NepaliDateRange` conforms to `CustomStringConvertible` and prints `start - end` instead of the
  default collection description.
- `DateOrder`, `Separator` and `Lang` are `Codable` and `Hashable`, which the format style needs.

### Breaking changes

- The range index type is now `Int` instead of `Int32`, matching Swift collections. Migration:
  replace `Int32` range indices with `Int`.
- A trailing `\` in a format pattern writes a literal `\`. Migration: remove the trailing `\` when the old output without it was intended.
- `NepDateError.Kind` has a new `.invalidArgument` case. Migration: add a case for `.invalidArgument`
  to exhaustive switches over `NepDateError.Kind`.

## [0.1.0-rc.1] - 2026-11-03

### Changed

- The published package check also runs weekly and daily, and reports a failure through one
  `published-check` issue.

## [0.1.0-beta.1] - 2026-10-21

First public pre-release. The API may still change before 0.1.0. One tag ships both products.

### Added

- `NepDate`: `NepaliDate`, an 8-byte value for BS 1901-01-01 to 2199-12-30, with conversion to and
  from the Gregorian calendar, day, month and year arithmetic (`MonthOverflow` picks clamp or
  spill), `diff(to:)`, fiscal years and quarters, and `NepaliDateRange`.
- Formatting in English and Nepali (`short`, `long`, `format` patterns, Nepali digits) with
  `append…(to:)` forms that write into a reused buffer, strict `parse`, lenient `parseLenient`,
  and `Codable` as `"YYYY-MM-DD"`.
- `Date` and `TimeZone` interop where Foundation exists: `init(_:in:)`, `date(in:)` and
  `today(in:)`.
- `NepDatePatro`: tithi, public holidays and events for BS 2077-01-01 to 2084-08-20 through
  `calendarInfo`, `Patro.coverage` and `Patro.publicHolidays`. The data is informational.
- No heap allocation in conversion, arithmetic, parsing or patro lookups. Benchmarks against the
  other Swift libraries and C# NepDate are in `docs/benchmarks.md`.