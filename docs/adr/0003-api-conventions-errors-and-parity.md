# ADR-0003: API conventions, errors and parity mapping

- Status: Accepted
- Date: 2026-10-06
- Deciders: Sanam Pakuwal

## Decision

**Conventions** (full surface in `docs/API.md`): Swift API Design Guidelines; throwing initialisers
with **typed throws** (`throws(NepDateError)`); `LosslessStringConvertible` for the strict format;
`Codable` as a single string; collections (`NepaliDateRange`) conform to `RandomAccessCollection` so
SwiftUI `ForEach` and `for in` work without copying.

`today(in:)` defaults to Nepal time. `init(_:in:)` takes the time zone explicitly: the date of a
`Date` depends on the zone, and guessing the device zone is how off-by-one-day bugs start.

**Errors:** one `NepDateError` with a `Kind` enum; no `NSError` bridging needed.

**Parity** (`shared/spec/PARITY.md`, applies unchanged):

| ID | Swift |
|---|---|
| D-01 | no default initialiser; invalid dates throw |
| D-02, D-03 | `adding(months:overflow:)`, `adding(days:)`, integers only |
| D-04 | `Month.shortName` returns `Asa` / `Aso` |
| D-05, D-06 | `parse` / `init?(_:)` (strict), `parseLenient` |
| D-07 | `days(until:) -> Int` |
| D-08 | `FiscalYear` with `start`, `end`, `range(of:)` |
| D-09 | `NepaliDateRange` as a collection only |
| D-10 | not ported |
| D-11 | `Codable` as `"YYYY-MM-DD"` |
| D-12 | `monthLength`; year length via `NepaliDateRange.year(y).count` |
| D-13 | product `NepDatePatro` (hub ADR-0004); `calendarInfo` is an extension on `NepaliDate` declared in that module |
| D-14 | not ported; `today(in:)` and `adding(days: ±1)` |
| D-15 | `lang` parameter on every formatter |
