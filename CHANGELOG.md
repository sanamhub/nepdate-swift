# Changelog

All notable changes to this package are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions are SwiftPM tags without a `v`
prefix (ADR-0005).

## [Unreleased]

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