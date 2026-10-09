# S4: Patro product and Foundation interop

Read first: hub ADR-0004 (patro in a separate package), `shared/spec/PATRO.md`, ADR-0001,
ADR-0002 §1 and §3, ADR-0004 gate 6, `docs/API.md` (module `NepDatePatro`, the `#if canImport(Foundation)`
extension), `shared/spec/PARITY.md` D-13, D-14, `shared/spec/PORT-PLAN.md` phase 4.

Rule for the whole phase: nothing under `Sources/NepDate/` mentions `NepDatePatro`, tithi,
holidays or events.

## Tasks

### S4-01 Product `NepDatePatro` and its generated tables
- `Package.swift`: add product `.library(name: "NepDatePatro", targets: ["NepDatePatro"])`, target
  `NepDatePatro` (dependencies `["NepDate"]`) and test target `NepDatePatroTests`. `.spi.yml`:
  `documentation_targets: [NepDate, NepDatePatro]`.
- In `NepDate`, the serial accessors are `package` (SE-0386): the stored `package let serial: Int32`
  and `package init(serial: Int32)` (non-failing; the caller passes a valid serial), both
  `@usableFromInline`. `package` symbols are visible to `NepDatePatro` and invisible to users, so
  they are not public API.
- `codegen` also writes `Sources/NepDatePatro/Patro.generated.swift` (same two header lines) from
  `shared/data/patro/*.json`, files in numeric year order, days in date order, as
  `enum PatroData` (ADR-0002 §3): `coverageFirst: Int32 = 64285`, `coverageLast: Int32 = 67077`,
  `dayInfo: [UInt8]` (one per covered day; bits 0 to 5 tithi name id + 1, bit 7 public holiday),
  `dayEventStart: [UInt16]` (covered days + 1 offsets), `eventNameIDs: [UInt16]` (file order), and
  `static func name(_ id: UInt16) -> (nepali: String, english: String)`, a `switch` with one case
  per distinct `(np, en)` pair, ids 0 to 31 being the tithi names in first-seen order. A
  `// 2081-01-01` comment at the start of each BS month in `dayInfo`.
- The generator exits 1 on a day key that isn't a valid BS date, a day outside
  `coverageFirst...coverageLast`, more than 63 tithi names, or more than 65,535 event entries. It
  prints the size of each table in bytes.
- AC1: `dayInfo.count == 2793`, `dayEventStart.count == 2794`, `dayEventStart.last == 3032`,
  `eventNameIDs.count == 3032`, 753 `name` cases, 32 tithi names, 294 days with bit 7 set
  (PATRO §3 counts).
- AC2: `codegen --check` passes; `swift build --target NepDate` still passes.

### S4-02 Queries
`NepaliDate.calendarInfo` (an extension declared in `NepDatePatro`), `Patro.coverage`,
`Patro.publicHolidays`, `Named`, `PatroEvents` (PATRO §2, `docs/API.md`). `calendarInfo` is
`@inlinable`: `k = serial - coverageFirst`, one unsigned bounds check, then `dayInfo[k]` and two
`dayEventStart` loads; no search, no allocation. It never fails: a date outside the data gives
`tithi == nil`, `isPublicHoliday == false` and an empty `events`. `PatroEvents` holds two `UInt16`
offsets; its subscript returns `Named(id: eventNameIDs[i])`. `Named.nepali` and `.english` read the
`switch`. `publicHolidays` is a lazy sequence scanning `dayInfo` for bit 7.
- AC1: every row of the PATRO §4 anchor table, events compared in order.
- AC2: `Patro.coverage` is 2077-01-01 to 2084-08-20 (both inclusive).
- AC3: `Array(Patro.publicHolidays)` has 294 dates in ascending order, and each has
  `calendarInfo.isPublicHoliday == true`.

### S4-03 `Examples` package and the patro-free core check
- `Examples/Package.swift`: tools 6.0, `.package(path: "..")`, three executable targets:
  `baseline` (prints a fixed string, imports nothing from this repo), `core-only` (imports only
  `NepDate`; converts, formats and parses a date and prints the results) and `with-patro` (imports
  `NepDate` and `NepDatePatro`; prints `calendarInfo` of 2081-01-01). A path dependency's package
  identity is its directory name, so products are referenced as
  `.product(name: "NepDate", package: "nepdate-swift")`; the checkout folder must be named
  `nepdate-swift` (state this in `CONTRIBUTING.md`).
- Gate 6 in `scripts/ci.sh` (ADR-0004): build `Examples` in release mode, then
  `grep -a -q 'World Day Against Human Trafficking'` must succeed on `with-patro` and fail on `core-only`. `ci.ps1`
  prints `skipped`.
- If the `with-patro` half fails (the string isn't found even though the data is linked), don't
  change the check or the table layout: stop and report it. (The check string is 35 bytes on
  purpose: Swift stores strings of 15 UTF-8 bytes or fewer inline in code, where `grep` can't see
  them.)
- AC1: gate 6 passes on Linux CI.
- AC2 (manual, in the PR): adding `NepDatePatro` to `core-only` and printing one `calendarInfo`
  makes gate 6 fail; revert before merging.

### S4-04 `Date` and `TimeZone` interop (`Sources/NepDate/Foundation.swift`)
The whole file is inside `#if canImport(Foundation)`; it uses no `Calendar` and no
`DateFormatter`.
- `init(_ date: Date, in timeZone: TimeZone)`: local seconds = `date.timeIntervalSince1970` +
  `timeZone.secondsFromGMT(for: date)`; Unix day = floor division by 86,400 (dates before 1970 are
  negative, so plain `/` is wrong); then `civilFromDays` and the BS conversion. Out of range throws
  `.outOfRange`.
- `date(in:)`: the instant of local midnight. Start from `unixDay * 86_400 - offset(at: that guess)`
  and re-read the offset once at the result, so a DST change between UTC midnight and local
  midnight is handled.
- `today(in:)`: calls an internal `today(in:now:)` with `Date()`, so tests inject the clock with
  `@testable import NepDate`. `nil` means Nepal: the offset of
  `TimeZone(identifier: "Asia/Kathmandu")`, or 20,700 seconds (UTC+05:45) when the zone database
  lacks it. Put the lookup behind an internal function that takes the lookup as a closure, so the
  fallback is testable on any machine.
- Human decision needed before this task: what `today(in:)` returns when the clock is outside
  AD 1844-04-11 to 2143-04-15 (its signature doesn't throw, and AGENTS.md forbids `fatalError` and
  force unwraps). Stop and ask if `docs/API.md` doesn't say yet.
- AC1: with the clock at 2024-07-30 18:30 UTC, `today(in: utc)` is 2081-04-15 and `today(in: nil)`
  is 2081-04-16, both with the real zone and with the lookup returning `nil`.
- AC2: `NepaliDate(d.date(in: tz), in: tz) == d` for every date in `NepaliDateRange.year(2080)` through `year(2082)` in
  `Asia/Kathmandu`, `America/New_York` and UTC.
- AC3: `NepaliDate(Date(timeIntervalSince1970: -45_920 * 86_400), in: utc)` is 1901-01-01.

### S4-05 C# catalogue rows, B7, B8
- Every C# catalogue row tagged S4 (45 rows: `CalendarDataTests`, `DateTimeExtensionsTests`,
  `NepaliDatePropertiesTests` `Today_*`, `NepaliDateArithmeticEdgeCaseTests` `Constructor_DateTime*`)
  has a test named after the row id, as in S1-06. The 6 `CalendarOffsets_*` rows check `PatroData`
  instead (coverage 2,793 days, `dayEventStart` non-decreasing). Rows that test C#'s `EventsNp` and `EventsEn`
  compare `info.events.map { $0.nepali }` and `.map { $0.english }`.
- `NepDatePatroTests/CompileTime.swift`: `requireSendable` for `CalendarInfo`, `PatroEvents`,
  `Named`, `Patro`; `MemoryLayout<Named>.size == 2`.
- Property: for every covered serial, `calendarInfo` equals a slow reference built in the test from
  the JSON files (all 2,793 days, not sampled).
- `Benchmarks`: B7 (`calendarInfo` of the 64 dates moved into coverage, BENCHMARK §3, reading
  `tithi?.id`, `isPublicHoliday` and every event's id) with threshold `.mallocCountTotal` 0; B8
  (`calendarInfo` for every day of the month, same reads) with threshold 0. A comparison benchmark
  `B7-sorted` builds sorted holiday and event-day serial arrays in setup from the public API and
  times the same lookups by binary search: the PATRO §3 evidence for the dense tables. Report both
  in the PR; if `B7-sorted` is faster, stop and report it.
- AC1: the test log lists the 45 S4 rows run.
- AC2: `bench` job green with B7 and B8 at 0 mallocs.

## Checkpoint
The agent stops here. The reviewer checks:
- [ ] `grep -rn "NepDatePatro\|tithi\|holiday" Sources/NepDate` finds nothing.
- [ ] The two `package` accessors are the only change to `NepDate` outside `Foundation.swift`.
- [ ] `PatroData` holds `dayInfo`, `dayEventStart`, `eventNameIDs` and the `name` switch, with the
  AC1 counts; no `[String]` or `[Named]` array anywhere in `Sources/NepDatePatro/`.
- [ ] `calendarInfo` has no loop and no search; out-of-coverage dates give empty info.
- [ ] Gate 6 passes on Linux; the manual negative check is described in the PR.
- [ ] The `today(in:)` out-of-range decision is recorded in `docs/API.md` by the human.
- [ ] 45 S4 catalogue rows run; the all-days patro property passes.
- [ ] `bench`: B7 and B8 at 0 mallocs; B7 against `B7-sorted` numbers in the PR.
