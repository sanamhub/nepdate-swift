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
func expectError(
  _ kind: NepDateError.Kind, sourceLocation: SourceLocation = #_sourceLocation,
  _ body: () throws(NepDateError) -> Void
) {
  do {
    try body()
    Issue.record("expected \(kind), nothing was thrown", sourceLocation: sourceLocation)
  } catch {
    #expect(error.kind == kind, sourceLocation: sourceLocation)
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
