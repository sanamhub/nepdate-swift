# `NepDate` (Swift): public API contract (v0.1)

The complete public surface for v0.1. Implement exactly this; a new public symbol needs this file
changed in the same PR, approved by the human. Behaviour: `shared/spec/`. Conventions: ADR-0003.
Every type is a value type and `Sendable`.

```swift
// ---------- module NepDate ----------
public struct NepaliDate: Sendable, BitwiseCopyable, Hashable, Comparable, Codable,
                          CustomStringConvertible, LosslessStringConvertible {
    public static let min: NepaliDate                         // 1901-01-01
    public static let max: NepaliDate                         // 2199-12-30

    public init(year: Int, month: Int, day: Int) throws(NepDateError)
    public init(gregorianYear: Int, month: Int, day: Int) throws(NepDateError)
    public init?(_ description: String)                       // strict parse (LosslessStringConvertible)
    public static func parse(_ string: some StringProtocol) throws(NepDateError) -> NepaliDate      // PARSING §1
    public static func parseLenient(_ string: some StringProtocol) throws(NepDateError) -> NepaliDate // PARSING §2

    public var year: Int { get }
    public var month: Int { get }                             // 1...12
    public var day: Int { get }
    public var bsMonth: Month { get }
    public var weekday: Weekday { get }                       // Sunday-first
    public var dayOfYear: Int { get }
    public var monthLength: Int { get }                       // 29...32
    public var firstDayOfMonth: NepaliDate { get }
    public var lastDayOfMonth: NepaliDate { get }
    public var gregorian: (year: Int, month: Int, day: Int) { get }

    public func adding(days: Int) throws(NepDateError) -> NepaliDate
    public func adding(months: Int, overflow: MonthOverflow = .clamp) throws(NepDateError) -> NepaliDate
    public func adding(years: Int, overflow: MonthOverflow = .clamp) throws(NepDateError) -> NepaliDate
    public func days(until other: NepaliDate) -> Int          // other - self (D-07)
    public func diff(to other: NepaliDate) -> DateDiff        // ALGORITHM §8a
    public var fiscalYear: FiscalYear { get }
    public var quarter: Quarter { get }

    public var description: String { get }                    // "YYYY/MM/DD"
    public func short(order: DateOrder = .ymd, separator: Separator = .slash,
                      pad: Bool = true, lang: Lang = .english) -> String
    public func long(weekday: Bool = false, year: Bool = true, pad: Bool = true,
                     lang: Lang = .english) -> String
    public func format(_ pattern: String, lang: Lang = .english) -> String   // FORMATTING §5
    // Same output, appended to the caller's buffer (ADR-0002 §4):
    public func appendShort(to output: inout String, order: DateOrder = .ymd, separator: Separator = .slash,
                            pad: Bool = true, lang: Lang = .english)
    public func appendLong(to output: inout String, weekday: Bool = false, year: Bool = true,
                           pad: Bool = true, lang: Lang = .english)
    public func appendFormat(_ pattern: String, to output: inout String, lang: Lang = .english)
    // Codable: single string "YYYY-MM-DD" (D-11); decoding uses the strict parser.
}

#if canImport(Foundation)
extension NepaliDate {
    public init(_ date: Date, in timeZone: TimeZone) throws(NepDateError)   // calendar date of `date` in `timeZone`
    public func date(in timeZone: TimeZone) -> Date                       // midnight in `timeZone`
    public static func today(in timeZone: TimeZone? = nil) -> NepaliDate  // nil: Asia/Kathmandu, or fixed UTC+05:45 if the zone database lacks it
}
#endif

public enum Lang: Sendable, Hashable { case english, nepali }
public enum Month: Int, Sendable, CaseIterable, Comparable {
    case baishakh = 1, jestha, ashad, shrawan, bhadra, ashoj, kartik, mangsir, poush, magh, falgun, chaitra
    public func name(_ lang: Lang = .english) -> String       // FORMATTING §1
    public func shortName(_ lang: Lang = .english) -> String  // D-04: Asa / Aso
}
public enum Weekday: Int, Sendable, CaseIterable { case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday
    public func name(_ lang: Lang = .english) -> String
    public func shortName(_ lang: Lang = .english) -> String
}
public func nepaliDigits(_ n: Int, minWidth: Int = 0) -> String

public struct NepDateError: Error, Sendable, Hashable {
    public enum Kind: Sendable, Hashable {
        case outOfRange, invalidMonth, invalidDay(monthLength: Int), invalidGregorian
        case invalidCharacter, wrongGroupCount, numberTooLong, ambiguous, unrecognized
    }
    public let kind: Kind
}

public enum MonthOverflow: Sendable { case clamp, spill }     // ALGORITHM §8
public struct DateDiff: Sendable, Hashable { public let isNegative: Bool; public let years, months, days, totalDays: Int }
public enum DateOrder: Sendable { case ymd, ydm, myd, mdy, dym, dmy }
public enum Separator: Character, Sendable { case slash = "/", backslash = "\\", dot = ".", underscore = "_", dash = "-", space = " " }

public struct FiscalYear: Sendable, Hashable, Comparable {   // FY 2082/83 = FiscalYear(startYear: 2082)
    public init(startYear: Int)
    public init(containing date: NepaliDate)
    public let startYear: Int
    public func start() throws(NepDateError) -> NepaliDate
    public func end() throws(NepDateError) -> NepaliDate
    public func range() throws(NepDateError) -> NepaliDateRange
    public func range(of quarter: Quarter) throws(NepDateError) -> NepaliDateRange
    public func label(_ lang: Lang = .english) -> String      // "2082/83" / "२०८२/८३"
}
public enum Quarter: Int, Sendable, CaseIterable { case q1 = 1, q2, q3, q4; public var months: [Month] { get } }

public struct NepaliDateRange: RandomAccessCollection, Sendable, Hashable {  // inclusive; D-09
    public init?(_ start: NepaliDate, _ end: NepaliDate)      // nil if start > end
    public static func month(year: Int, month: Int) throws(NepDateError) -> NepaliDateRange
    public static func year(_ year: Int) throws(NepDateError) -> NepaliDateRange
    public var lowerBound: NepaliDate { get }
    public var upperBound: NepaliDate { get }
    // RandomAccessCollection: startIndex, endIndex, subscript(position:) -> NepaliDate, count, contains(_:)
}

// ---------- module NepDatePatro (imports NepDate; hub ADR-0004) ----------
public struct CalendarInfo: Sendable, Hashable {                // PATRO §2
    public let tithi: Named?
    public let isPublicHoliday: Bool
    public let events: PatroEvents                            // file order
}
public struct PatroEvents: RandomAccessCollection, Sendable, Hashable {  // Element == Named, Index == Int
    // startIndex, endIndex, subscript(position:) -> Named; == and hash compare the names in order
}
public struct Named: Sendable, Hashable {                     // 2 bytes: an id into the generated names
    public var nepali: String { get }
    public var english: String { get }
    public func name(_ lang: Lang = .english) -> String
}
extension NepaliDate { public var calendarInfo: CalendarInfo { get } }    // never fails
public enum Patro {
    public static var coverage: NepaliDateRange { get }
    public static var publicHolidays: some Sequence<NepaliDate> { get }  // ascending
}
```

Notes:
- Typed throws (`throws(NepDateError)`) let callers switch on `error.kind` without casting.
- `NepaliDateRange` is a `RandomAccessCollection` indexed by serial, so `count` and `contains` are
  O(1) and `ForEach` in SwiftUI works directly.
- `today(in:)` defaults to Nepal time, not the device zone. It can't throw, so a clock outside
  AD 1844-04-11 to 2143-04-15 gives `min` or `max` (hub PORT-PLAN "today" rule).
- `NepDate` declares none of the `NepDatePatro` symbols. A caller of `calendarInfo` imports both
  modules. `NepDatePatro` reads a date's serial through `package` access (S4-01); `package`
  symbols are not part of this contract.
- Allocation (ADR-0002): conversion, arithmetic, parsing, `calendarInfo` and iterating its
  `events` allocate nothing. A formatter allocates once when its result is longer than 15 UTF-8
  bytes; the `append…(to:)` forms allocate only when the caller's buffer must grow.
- `NepaliDateRange.contains(_:)` and `count` are written by hand from the serials; the default
  `Sequence.contains` is O(n).

## Changes on 2026-10-07 (need the human's approval with the plan)

| Change | Why |
|---|---|
| Module `NepDateEvents` renamed `NepDatePatro`; `CalendarEvents` renamed `Patro` | hub ADR-0004 |
| `CalendarInfo.events` is `PatroEvents` instead of `[Named]` | no array allocation per day (ADR-0002 §3); `Array(info.events)` gives the old shape |
| `Named.nepali` and `Named.english` are computed `var`s, not stored `let`s | `Named` holds a 2-byte id; reading code compiles unchanged |
| `NepaliDate` declares `BitwiseCopyable` | compile-time proof of a trivial 8-byte value (ADR-0002 §1) |
| `parse` and `parseLenient` take `some StringProtocol` | parse a `Substring` without copying; `String` callers compile unchanged |
| `appendShort(to:)`, `appendLong(to:)`, `appendFormat(_:to:)` added | format into a reused buffer with no allocation (ADR-0002 §4) |
