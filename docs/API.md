# Public API

The complete public surface of `NepDate` and `NepDatePatro`. A new public symbol changes this file
in the same pull request. Behaviour is specified in [`shared/spec/`](../shared/spec/README.md);
naming and errors follow [ADR-0003](adr/0003-api-conventions-errors-and-parity.md).

Every type is a value type and `Sendable`. The examples use `import NepDate` unless a section says
otherwise.

```swift
import NepDate

let date = try NepaliDate(year: 2081, month: 4, day: 15)  // 2081-04-15
```

## Dates, identity and comparison

```swift
public struct NepaliDate: Sendable, BitwiseCopyable, Hashable, Comparable, Codable,
                          CustomStringConvertible, LosslessStringConvertible, Strideable
```

| Member | Example |
|---|---|
| `static let min: NepaliDate` | `NepaliDate.min` is 1901-01-01. |
| `static let max: NepaliDate` | `NepaliDate.max` is 2199-12-30. |
| `init(year: Int, month: Int, day: Int) throws(NepDateError)` | `try NepaliDate(year: 2081, month: 4, day: 15)` |
| `init(gregorianYear: Int, month: Int, day: Int) throws(NepDateError)` | `try NepaliDate(gregorianYear: 2024, month: 7, day: 30)` |
| `init?(_ description: String)` | `NepaliDate("2081/04/15")` parses strictly. |
| `var year: Int` | `date.year` is `2081`. |
| `var month: Int` | `date.month` is `4`. |
| `var day: Int` | `date.day` is `15`. |
| `var bsMonth: Month` | `date.bsMonth == .shrawan` |
| `var weekday: Weekday` | `date.weekday == .tuesday` |
| `var dayOfYear: Int` | `date.dayOfYear` is `109`. |
| `var monthLength: Int` | `date.monthLength` is `32`. |
| `var yearLength: Int` | `date.yearLength` is `366`. |
| `var firstDayOfMonth: NepaliDate` | `date.firstDayOfMonth` is 2081-04-01. |
| `var lastDayOfMonth: NepaliDate` | `date.lastDayOfMonth` is 2081-04-32. |
| `var gregorian: (year: Int, month: Int, day: Int)` | `date.gregorian` is `(2024, 7, 30)`. |
| `var fiscalYear: FiscalYear` | `date.fiscalYear.startYear` is `2081`. |
| `var quarter: Quarter` | `date.quarter == .q1` |
| `func hash(into:)` | The day count, so equal dates hash equally. |
| `==`, `!=`, `<`, `<=`, `>`, `>=` | Order is by day. |
| `let (y, m, d) = (date.year, date.month, date.day)` | The three components, for destructuring. |

A value is always a real date. The three checks run in the order year, month, day, and the error
says which one failed. `min` is BS 1901-01-01 (AD 1844-04-11) and `max` is BS 2199-12-30 (AD
2143-04-15).

`NepaliDate` is 8 bytes: the day count plus the year, month and day, so conversion and comparison
read no table. `BitwiseCopyable` promises there is no reference inside it.

## Conversion and serialization

```swift
import Foundation

let bs = try NepaliDate(gregorianYear: 2024, month: 7, day: 30)  // 2081-04-15
let ad = bs.date(in: TimeZone(identifier: "Asia/Kathmandu")!)   // midnight in Kathmandu
let back = try NepaliDate(ad, in: TimeZone(identifier: "UTC")!)
```

| Member | Example |
|---|---|
| `init(_ date: Date, in timeZone: TimeZone) throws(NepDateError)` | `try NepaliDate(Date(), in: .current)` |
| `func date(in timeZone: TimeZone) -> Date` | `date.date(in: .current)` is local midnight. |
| `init?(ymd: Int)` | `NepaliDate(ymd: 20810415)` |
| `var ymd: Int` | `date.ymd` is `20810415`. |
| `static func fromGregorian(_ dates: some Sequence<Date>, in timeZone: TimeZone) throws(NepDateError) -> [NepaliDate]` | Converts a batch in input order. |
| `static func gregorianDates(from strings: some Sequence<String>, in timeZone: TimeZone) throws(NepDateError) -> [Date]` | Parses and converts a batch in input order. |
| `static func gregorianDates(from dates: some Sequence<NepaliDate>, in timeZone: TimeZone) -> [Date]` | Converts a batch of dates in input order. |

The `Date` forms take a `TimeZone` explicitly, because the calendar date of an instant depends on
the zone. The time of day is discarded.

`Codable` reads and writes one string in the canonical `YYYY-MM-DD` form. The decoder accepts
exactly that form, so the slash form and a non-padded date are rejected even though `parse` accepts
them.

```swift
import Foundation

let date = try NepaliDate(year: 2081, month: 4, day: 15)
let json = try JSONEncoder().encode([date])  // ["2081-04-15"]
let back = try JSONDecoder().decode([NepaliDate].self, from: json)
```

The `YYYYMMDD` integer is decimal year, month and day. A value that does not name a valid date,
including a negative value and a value wider than eight digits, gives `nil`; it never wraps into 32
bits.

## Arithmetic

```swift
let date = try NepaliDate(year: 2081, month: 4, day: 15)
let later = try date.adding(months: 2)                  // 2081-06-15
let spilled = try date.adding(months: 2, overflow: .spill)
let gap = date.days(until: later)                       // 63
let diff = date.diff(to: later)                         // 0 years, 2 months, 0 days
```

| Member | Example |
|---|---|
| `enum MonthOverflow { case clamp, spill }` | `try date.adding(months: 2, overflow: .spill)` |
| `func adding(days: Int) throws(NepDateError) -> NepaliDate` | `try date.adding(days: 10)` |
| `func adding(months: Int, overflow: MonthOverflow = .clamp) throws(NepDateError) -> NepaliDate` | `try date.adding(months: 2)` |
| `func adding(years: Int, overflow: MonthOverflow = .clamp) throws(NepDateError) -> NepaliDate` | `try date.adding(years: 1)` |
| `func days(until other: NepaliDate) -> Int` | `date.days(until: later)` is positive when `later` is later. |
| `func diff(to other: NepaliDate) -> DateDiff` | `date.diff(to: later)` |
| `func distance(to other: NepaliDate) -> Int` | The `Strideable` distance, the same as `days(until:)`. |
| `func advanced(by days: Int) -> NepaliDate` | `date.advanced(by: 10)` |
| `static func + (NepaliDate, Int) -> NepaliDate` | `date + 10` |
| `static func - (NepaliDate, Int) -> NepaliDate` | `date - 10` |
| `static func + (Int, NepaliDate) -> NepaliDate` | `10 + date` |
| `static func - (NepaliDate, NepaliDate) -> DateDiff` | `later - date` |

`adding(months:overflow:)` takes a whole number of months. `.clamp` uses the target month's last
day, and `.spill` carries the extra days into the following month. For example, 2081-04-32 plus two
months is 2081-06-30 with clamp and 2081-07-02 with spill.

The named `days(until:)` counts from this date to `other`, so it is positive when `other` is later.
The `-` operator between two dates keeps the C# direction and counts from the right date to the
left, so `later - date` returns a `DateDiff` with `totalDays == later.days(until: date)` negated.
The two names answer different questions and are not interchangeable.

`advanced(by:)` and the day operators trap when the result leaves the supported range, like integer
arithmetic. Use `adding(days:)` when the count may not fit.

## Formatting

```swift
let date = try NepaliDate(year: 2081, month: 4, day: 15)
date.description                      // 2081/04/15
date.short(separator: .dash)          // 2081-04-15
date.short(order: .dmy, pad: false)   // 15/4/2081
date.long()                           // Shrawan 15, 2081
date.long(weekday: true)              // Tuesday, Shrawan 15, 2081
date.long(lang: .nepali)              // साउन १५, २०८१
date.format("yyyy-MM-dd")             // 2081-04-15
date.format("MMM yyyy")               // Shr 2081
```

| Member | Example |
|---|---|
| `var description: String` | `date.description` is `2081/04/15`. |
| `func short(order:separator:pad:lang:) -> String` | `date.short(order: .dmy, separator: .dash, pad: false)` |
| `func long(weekday:year:pad:lang:) -> String` | `date.long(weekday: true, year: false)` |
| `func format(_ pattern: String, lang: Lang = .english) -> String` | `date.format("yyyy'BS'")` |
| `func appendShort(to:order:separator:pad:lang:)` | `date.appendShort(to: &output)` |
| `func appendLong(to:weekday:year:pad:lang:)` | `date.appendLong(to: &output)` |
| `func appendFormat(_:to:lang:)` | `date.appendFormat("dd", to: &output)` |
| `enum DateOrder { case ymd, ydm, myd, mdy, dym, dmy }` | `date.short(order: .mdy)` |
| `enum Separator { case slash, backslash, dot, underscore, dash, space }` | `date.short(separator: .dot)` |
| `enum Lang { case english, nepali }` | `date.long(lang: .nepali)` |
| `func nepaliDigits(_ n: Int, minWidth: Int = 0) -> String` | `nepaliDigits(2081)` is `२०८१`. |

The `append...` forms write into a string the caller reuses, which avoids a new string per call.

The pattern language is a single left-to-right pass. `yyyy` and longer runs write the four-digit
year; `y`, `yy` and `yyy` write the last two digits; `MMMM` writes the month's full name; `MMM`
writes its short name; `MM` and `M` write the month with and without a leading zero; `dd` writes a
two-digit day; any other run of `d` writes the day without a leading zero. A backslash escapes the
next character, and a backslash at the very end writes a literal backslash. Text in single quotes
is literal. `""`, `G`, `g` and `d` write the default form, `D` the long form and `s` the ISO form.

`Month` names both languages and the short English names, with `Asa` and `Aso` for Ashad and Ashoj.
`Weekday` names the days from Sunday. Both are `CaseIterable`, their `rawValue` is the month or
weekday number, and `Month` is `Comparable`.

### FormatStyle

Where Foundation is available, `NepaliDate.FormatStyle` is a `FormatStyle` value that holds the
same choices in one place, for `formatted` or for SwiftUI's `Text`.

```swift
import Foundation

let date = try NepaliDate(year: 2081, month: 4, day: 15)
date.formatted()                                        // 2081/04/15
date.formatted(.long)                                   // Shrawan 15, 2081
date.formatted(.init(order: .dmy, separator: .dash))    // 15-04-2081
date.formatted(.init(form: .long, language: .nepali))   // साउन १५, २०८१
```

`FormatStyle` has `form`, `order`, `separator`, `language`, `weekday`, `year` and `pad`, and the
static values `.short` and `.long`. It is `Codable` and `Hashable`.

## Parsing

```swift
let strict = try NepaliDate.parse("2081-04-15")
let lenient = try NepaliDate.parseLenient("15 Shrawan 2081")
let optional = NepaliDate(lenient: "Shrawan 15, 2081")
```

| Member | Example |
|---|---|
| `static func parse(_ string: some StringProtocol) throws(NepDateError) -> NepaliDate` | `try NepaliDate.parse("2081/04/15")` |
| `static func parseLenient(_ string: some StringProtocol) throws(NepDateError) -> NepaliDate` | `try NepaliDate.parseLenient("15 Shrawan 2081")` |
| `init?(_ description: String)` | `NepaliDate("2081/04/15")` |
| `init?(lenient string: some StringProtocol)` | `NepaliDate(lenient: "15 Shrawan 2081")` |
| `LosslessStringConvertible` | The strict parser, so `NepaliDate("2081/04/15")` round-trips. |

The strict parser reads year, month and day in that order. It accepts ASCII and Devanagari digits,
mixed, with up to four digits per group. The separators are `-`, `/`, `.`, `_`, `\`, space, `|` and
the danda `।`; leading, trailing and repeated separators are ignored. A fourth group, fewer than
three groups or any other character fails.

The lenient parser first tries the strict parser. It then reads a closed list of month names, drops
era markers and the words `गते` and `मिति`, and accepts two numbers with one month name or three
numbers in year-month-day or day-month-year order. A two-digit year is ambiguous and fails; it is
never expanded.

## Ranges

A range is inclusive and never empty. `NepaliDateRange(_:_:)` returns `nil` when the start is after
the end, and the factories either throw or cannot fail. `NepaliDateRange` is a
`RandomAccessCollection` indexed by `Int` day count.

```swift
let range = try NepaliDateRange(
  start: try NepaliDate(year: 2081, month: 4, day: 10), dayCount: 11)
range.count                      // 11
range.contains(try NepaliDate(year: 2081, month: 4, day: 15))  // true
range.description                // 2081/04/10 - 2081/04/20
range.formatted(order: .dmy, separator: .dash)  // 10-04-2081 - 20-04-2081
```

| Member | Example |
|---|---|
| `init?(_ start: NepaliDate, _ end: NepaliDate)` | `NepaliDateRange(a, b)` |
| `init(start: NepaliDate, dayCount: Int) throws(NepDateError)` | `try NepaliDateRange(start: a, dayCount: 5)` |
| `static func singleDay(_ date: NepaliDate) -> NepaliDateRange` | `NepaliDateRange.singleDay(a)` |
| `static func month(year: Int, month: Int) throws(NepDateError) -> NepaliDateRange` | `try NepaliDateRange.month(year: 2081, month: 4)` |
| `static func year(_ year: Int) throws(NepDateError) -> NepaliDateRange` | `try NepaliDateRange.year(2081)` |
| `static func currentMonth(in: TimeZone) throws(NepDateError) -> NepaliDateRange` | `try NepaliDateRange.currentMonth(in: .current)` |
| `static func currentFiscalYear(in: TimeZone) throws(NepDateError) -> NepaliDateRange` | `try NepaliDateRange.currentFiscalYear(in: .current)` |
| `static func currentCalendarYear(in: TimeZone) throws(NepDateError) -> NepaliDateRange` | `try NepaliDateRange.currentCalendarYear(in: .current)` |
| `var lowerBound: NepaliDate`, `var upperBound: NepaliDate` | The two ends, both included. |
| `var startIndex: Int`, `var endIndex: Int`, `subscript(Int) -> NepaliDate` | The collection requirements. |
| `var count: Int` | `range.count` |
| `func contains(_ date: NepaliDate) -> Bool` | `range.contains(a)` |
| `func contains(_ other: NepaliDateRange) -> Bool` | `range.contains(inner)` |
| `func overlaps(_ other: NepaliDateRange) -> Bool` | `range.overlaps(other)` |
| `func isAdjacent(to other: NepaliDateRange) -> Bool` | `range.isAdjacent(to: next)` |
| `func intersection(_ other: NepaliDateRange) -> NepaliDateRange?` | `range.intersection(other)` |
| `func union(_ other: NepaliDateRange) -> NepaliDateRange` | `range.union(other)` |
| `func subtracting(_ other: NepaliDateRange) -> [NepaliDateRange]` | `range.subtracting(other)` |
| `func splitByMonth() -> [NepaliDateRange]` | `range.splitByMonth()` |
| `func splitByFiscalQuarter() -> [NepaliDateRange]` | `range.splitByFiscalQuarter()` |
| `func dates(every interval: Int) throws(NepDateError) -> [NepaliDate]` | `try range.dates(every: 3)` |
| `func workingDays(excludingSunday: Bool = false) -> [NepaliDate]` | `range.workingDays()` |
| `func weekendDays(includingSunday: Bool = true) -> [NepaliDate]` | `range.weekendDays()` |
| `var description: String` | `2081/04/10 - 2081/04/20` |
| `func formatted(order:separator:lang:) -> String` | `range.formatted(order: .dmy)` |
| `==`, `hash(into:)` | Two ranges are equal when both bounds are equal. |

The collection conformance gives `isEmpty`, `first`, `last`, `map`, `for in` and `Array(range)`
without copying the dates. `isEmpty` is always `false`, because an empty range cannot be built.

A valid range never throws at the data end. The first and last split pieces are clipped to the
bounds, and the enumerator and the day helpers return every date up to and including 2199-12-30.
`intersection` returns `nil` for disjoint ranges, and `isAdjacent` is `false` when the other range
would have to start after 2199-12-30.

## Fiscal year

A fiscal year starts on 1 Shrawan and ends on the last day of Ashad of the next BS year. FY 2082/83
starts in 2082.

```swift
let date = try NepaliDate(year: 2081, month: 4, day: 15)
let fiscal = date.fiscalYear                       // FiscalYear(startYear: 2081)
try fiscal.start()                                 // 2081-04-01
try fiscal.end()                                   // 2082-03-32
try fiscal.range()                                 // 2081-04-01..2082-03-32
try fiscal.range(of: .q2)                          // 2081-07-01..2081-09-29
fiscal.label()                                     // 2081/82
```

| Member | Example |
|---|---|
| `enum Quarter { case q1, q2, q3, q4 }` | Shrawan to Ashoj is Q1, Baishakh to Ashad is Q4. |
| `var months: [Month]` | `Quarter.q1.months` is Shrawan, Bhadra, Ashoj. |
| `struct FiscalYear: Sendable, Hashable, Comparable` | `FiscalYear(startYear: 2081)` |
| `init(startYear: Int)` | `FiscalYear(startYear: 2081)` |
| `init(containing date: NepaliDate)` | `FiscalYear(containing: date)` |
| `let startYear: Int` | `fiscal.startYear` |
| `func start() throws(NepDateError) -> NepaliDate` | `try fiscal.start()` |
| `func end() throws(NepDateError) -> NepaliDate` | `try fiscal.end()` |
| `func range() throws(NepDateError) -> NepaliDateRange` | `try fiscal.range()` |
| `func range(of quarter: Quarter) throws(NepDateError) -> NepaliDateRange` | `try fiscal.range(of: .q1)` |
| `func label(_ lang: Lang = .english) -> String` | `fiscal.label(.nepali)` is `२०८१/८२`. |

## Patro

`NepDatePatro` is a separate product that depends on `NepDate`. It holds the tithi, public holiday
and event data for BS 2077-01-01 to 2084-08-20, and the core package links none of it.

```swift
import NepDate
import NepDatePatro

let date = try NepaliDate(year: 2081, month: 1, day: 1)
let info = date.calendarInfo
info.tithi?.english       // Panchami
info.isPublicHoliday      // true
info.events.map(\.english)  // New Year, Mesh Sankranti, Bisket Jatra
```

| Member | Example |
|---|---|
| `var calendarInfo: CalendarInfo` | `date.calendarInfo` |
| `struct CalendarInfo: Sendable, Hashable` | Holds the five members below. |
| `let tithi: Named?` | `info.tithi?.nepali` |
| `let isPublicHoliday: Bool` | `info.isPublicHoliday` |
| `let events: PatroEvents` | `info.events.map(\.english)` |
| `struct Named: Sendable, Hashable` | A tithi or event name. |
| `var nepali: String`, `var english: String` | `name.nepali`, `name.english` |
| `func name(_ lang: Lang = .english) -> String` | `name.name(.nepali)` |
| `struct PatroEvents: RandomAccessCollection` | The day's events in file order. |
| `enum Patro` | `Patro.coverage` is BS 2077-01-01 to 2084-08-20. |
| `static var coverage: NepaliDateRange` | `Patro.coverage.count` |
| `static var publicHolidays: some Sequence<NepaliDate>` | `for day in Patro.publicHolidays { }` |

A date outside the data range gives no tithi, no holiday and no events; the properties never return
`nil` where the API says `Bool` or a collection. The data is informational, not an official
calendar.

## Errors

Every failure is a `NepDateError`, so a caller switches on `error.kind` without casting. The error
is `Sendable` and `Hashable`, and it conforms to `Error`.

```swift
do {
  _ = try NepaliDate(year: 2080, month: 13, day: 1)
} catch let error as NepDateError {
  switch error.kind {
  case .invalidMonth: print("month out of range")
  default: print(error.kind)
  }
}
```

| Kind | Raised by |
|---|---|
| `.outOfRange` | A date outside BS 1901-01-01 to 2199-12-30, or arithmetic that leaves it. |
| `.invalidMonth` | A month outside 1 to 12. |
| `.invalidDay(monthLength:)` | A day outside the month; the month length is carried. |
| `.invalidGregorian` | An AD date that does not exist, for example 2023-02-29. |
| `.invalidArgument` | A day count or interval below 1. |
| `.invalidCharacter` | Strict parsing met a character that is neither a digit nor a separator. |
| `.wrongGroupCount` | Strict parsing did not find exactly three number groups. |
| `.numberTooLong` | A number group has more than four digits. |
| `.ambiguous` | Lenient parsing fits more than one reading. |
| `.unrecognized` | Lenient parsing could not read the text. |

The parser reports the first failure in its own order, and validation reports year, then month, then
day. `parse` and the throwing initialisers use typed throws, so the error needs no cast.

## Concurrency, collections and performance

`NepaliDate`, `NepaliDateRange`, `FiscalYear`, `Quarter`, `Month`, `Weekday`, `Lang`, `DateOrder`,
`Separator`, `DateDiff`, `MonthOverflow` and `NepDateError` are `Sendable`. A range is a
`RandomAccessCollection` with `Int` indices, so it can cross a task boundary and drive
`ForEach` directly.

Conversion, arithmetic, parsing, `calendarInfo` and iterating a range's events allocate nothing.
`short`, `long` and `format` allocate one string per call; the `append...` forms grow the caller's
existing string only when its capacity is too small. The patro tables are generated from
[`shared/data/`](../shared/data/README.md) and never parsed at runtime.

## What changed

The [changelog](../CHANGELOG.md) lists every addition and every breaking change with its migration
line. The three source breaks in this version are the range index type, now `Int` instead of
`Int32`, the new `.invalidArgument` error case, and a trailing backslash in a format pattern, which
now writes a backslash.
