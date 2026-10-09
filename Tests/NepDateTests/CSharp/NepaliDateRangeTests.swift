import Testing

@testable import NepDate

/// The range from `start` to `end`; the test fails when `start` is after `end`.
func dateRange(_ start: NepaliDate, _ end: NepaliDate) throws -> NepaliDateRange {
  try #require(NepaliDateRange(start, end))
}

// D-09: the Swift range is a collection with month, year, contains, count and iteration. C# set
// operations, splitting, working days and string forms are not ported. C# `Length` is `count`, and
// an empty C# range (end before start) is `nil`.
@Suite("NepaliDateRangeTests")
struct NepaliDateRangeTests {
  @Test("NepaliDateRangeTests.Constructor_ValidDates_CreatesRange")
  func constructorValidDatesCreatesRange() throws {
    let start = try bs(2080, 1, 1)
    let end = try bs(2080, 1, 15)
    let range = try dateRange(start, end)
    #expect(range.lowerBound == start && range.upperBound == end)
    #expect(!range.isEmpty && range.count == 15)
  }

  @Test("NepaliDateRangeTests.Constructor_EndBeforeStart_CreatesEmptyRange")
  func constructorEndBeforeStartCreatesEmptyRange() throws {
    #expect(NepaliDateRange(try bs(2080, 1, 15), try bs(2080, 1, 1)) == nil)
  }

  @Test("NepaliDateRangeTests.SingleDay_CreatesRangeWithOneDay")
  func singleDayCreatesRangeWithOneDay() throws {
    let date = try bs(2080, 1, 1)
    let range = try dateRange(date, date)
    #expect(range.lowerBound == date && range.upperBound == date && range.count == 1)
  }

  // C# `FromDayCount(start, n)` is the range from `start` to `start.adding(days: n - 1)`.
  @Test("NepaliDateRangeTests.FromDayCount_CreatesCorrectRange")
  func fromDayCountCreatesCorrectRange() throws {
    let start = try bs(2080, 1, 1)
    let range = try dateRange(start, start.adding(days: 9))
    #expect(range.lowerBound == start && range.count == 10)
    #expect(range.upperBound == (try start.adding(days: 9)))
  }

  @Test("NepaliDateRangeTests.ForMonth_CreatesCorrectRange")
  func forMonthCreatesCorrectRange() throws {
    let range = try NepaliDateRange.month(year: 2080, month: 1)
    #expect(range.lowerBound == (try bs(2080, 1, 1)))
    #expect(range.upperBound == (try bs(2080, 1, 1).lastDayOfMonth))
  }

  @Test("NepaliDateRangeTests.ForFiscalYear_CreatesCorrectRange")
  func forFiscalYearCreatesCorrectRange() throws {
    let range = try FiscalYear(startYear: 2080).range()
    #expect(range.lowerBound == (try bs(2080, 4, 1)))
    #expect(range.upperBound == (try bs(2081, 3, 1).lastDayOfMonth))
  }

  @Test("NepaliDateRangeTests.Contains_DateInRange_ReturnsTrue")
  func containsDateInRangeReturnsTrue() throws {
    let range = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    #expect(range.contains(try bs(2080, 1, 10)))
  }

  @Test("NepaliDateRangeTests.Contains_DateOutsideRange_ReturnsFalse")
  func containsDateOutsideRangeReturnsFalse() throws {
    let range = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    #expect(!range.contains(try bs(2080, 1, 20)))
  }

  // NepaliDateRangeTests.Contains_RangeFullyContained_ReturnsTrue: D-09.
  // NepaliDateRangeTests.Overlaps_RangesOverlap_ReturnsTrue: D-09.
  // NepaliDateRangeTests.Overlaps_RangesDontOverlap_ReturnsFalse: D-09.
  // NepaliDateRangeTests.IsAdjacentTo_AdjacentRanges_ReturnsTrue: D-09.
  // NepaliDateRangeTests.Intersect_OverlappingRanges_ReturnsIntersection: D-09.
  // NepaliDateRangeTests.Union_OverlappingRanges_ReturnsUnion: D-09.
  // NepaliDateRangeTests.Except_RemovingRangeFromMiddle_ReturnsTwoRanges: D-09.
  // NepaliDateRangeTests.SplitByMonth_RangeAcrossMonths_SplitsCorrectly: D-09.
  // NepaliDateRangeTests.WorkingDays_ReturnsCorrectDays: D-09.
  // NepaliDateRangeTests.Demo_RangeOperations: D-09.

  @Test("NepaliDateRangeTests.Enumeration_EnumeratesAllDaysInRange")
  func enumerationEnumeratesAllDaysInRange() throws {
    let days = Array(try dateRange(bs(2080, 1, 1), bs(2080, 1, 10)))
    #expect(days.count == 10)
    for i in 0..<10 { #expect(days[i] == (try bs(2080, 1, i + 1))) }
  }
}
