import Foundation
import Testing

@testable import NepDate

/// Builds a BS date in a test; a throw fails the test that called it.
func bs(_ year: Int, _ month: Int, _ day: Int) throws -> NepaliDate {
  try NepaliDate(year: year, month: month, day: day)
}

/// Builds the BS date of an AD date in a test.
func ad(_ year: Int, _ month: Int, _ day: Int) throws -> NepaliDate {
  try NepaliDate(gregorianYear: year, month: month, day: day)
}

/// Expects `body` to throw a `NepDateError` of the given kind.
///
/// `body` is untyped `throws`: a closure literal's thrown type is not inferred from a typed-throws
/// parameter, so the error is cast back here.
func expectError(
  _ kind: NepDateError.Kind, sourceLocation: SourceLocation = #_sourceLocation,
  _ body: () throws -> Void
) {
  do {
    try body()
    Issue.record("expected \(kind), nothing was thrown", sourceLocation: sourceLocation)
  } catch let error as NepDateError {
    #expect(error.kind == kind, sourceLocation: sourceLocation)
  } catch {
    Issue.record("expected NepDateError, got \(error)", sourceLocation: sourceLocation)
  }
}

/// English weekday names as the vector files spell them, Sunday first.
let weekdayNames = [
  "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
]

/// Splits `YYYY-MM-DD` into numbers.
func ymd(_ text: Substring) -> (Int, Int, Int)? {
  let parts = text.split(separator: "-").compactMap { Int($0) }
  return parts.count == 3 ? (parts[0], parts[1], parts[2]) : nil
}

/// Weekday of an AD date by Sakamoto's method, independent of the library's serial arithmetic.
func gregorianWeekday(_ year: Int, _ month: Int, _ day: Int) -> Int {
  let offsets = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
  let y = month < 3 ? year - 1 : year
  return (y + y / 4 - y / 100 + y / 400 + offsets[month - 1] + day) % 7
}

/// A BS date as the vector files write it: `YYYY-MM-DD`, zero padded, ASCII digits.
func bsText(_ date: NepaliDate) -> String {
  "\(date.year)-\(pad(date.month))-\(pad(date.day))"
}

/// A date parsed from the vector form `YYYY-MM-DD`.
func vectorDate(_ text: String) throws -> NepaliDate {
  guard let parts = ymd(Substring(text)) else { throw NepDateError(.invalidArgument) }
  return try bs(parts.0, parts.1, parts.2)
}

/// A range as `start..end`, or `none` when there is no range.
func rangeText(_ range: NepaliDateRange?) -> String {
  guard let range else { return "none" }
  return "\(bsText(range.lowerBound))..\(bsText(range.upperBound))"
}

/// A list of ranges separated by `;`, or `none` when the list is empty.
func rangesText(_ ranges: [NepaliDateRange]) -> String {
  ranges.isEmpty ? "none" : ranges.map(rangeText).joined(separator: ";")
}

/// A list of dates separated by `;`, or `none` when the list is empty.
func datesText(_ dates: [NepaliDate]) -> String {
  dates.isEmpty ? "none" : dates.map(bsText).joined(separator: ";")
}

/// A range parsed from `start..end`.
func vectorRange(_ text: String) throws -> NepaliDateRange {
  guard let separator = text.range(of: "..") else { throw NepDateError(.invalidArgument) }
  let start = try vectorDate(String(text[..<separator.lowerBound]))
  let end = try vectorDate(String(text[separator.upperBound...]))
  return NepaliDateRange(unchecked: start, end)
}

/// The AD date `YYYY-MM-DD` of a `Date` in `timeZone`, from Foundation so the test does not reuse
/// the library's conversion.
func adText(_ date: Date, in timeZone: TimeZone) -> String {
  let formatter = DateFormatter()
  formatter.calendar = Calendar(identifier: .gregorian)
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.timeZone = timeZone
  formatter.dateFormat = "yyyy-MM-dd"
  return formatter.string(from: date)
}

/// The `Date` at midnight of the AD date `YYYY-MM-DD` in `timeZone`.
func adDate(_ text: String, in timeZone: TimeZone) -> Date? {
  let formatter = DateFormatter()
  formatter.calendar = Calendar(identifier: .gregorian)
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.timeZone = timeZone
  formatter.dateFormat = "yyyy-MM-dd"
  return formatter.date(from: text)
}
