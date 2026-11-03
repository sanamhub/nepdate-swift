import Testing

@testable import NepDate

/// The range from `start` to `end`; the test fails when `start` is after `end`.
func dateRange(_ start: NepaliDate, _ end: NepaliDate) throws -> NepaliDateRange {
  try #require(NepaliDateRange(start, end))
}

// The range is inclusive and never empty. A C# empty range (end before start) is `nil` here, so
// every C# empty-range test checks the `nil` result instead.
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
    let range = NepaliDateRange.singleDay(date)
    #expect(range.lowerBound == date && range.upperBound == date && range.count == 1)
  }

  // C# `FromDayCount(start, n)` is the range from `start` to `start.adding(days: n - 1)`.
  @Test("NepaliDateRangeTests.FromDayCount_CreatesCorrectRange")
  func fromDayCountCreatesCorrectRange() throws {
    let start = try bs(2080, 1, 1)
    let range = try NepaliDateRange(start: start, dayCount: 10)
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

  @Test("NepaliDateRangeTests.Contains_RangeFullyContained_ReturnsTrue")
  func containsRangeFullyContainedReturnsTrue() throws {
    let range = try dateRange(bs(2080, 1, 1), bs(2080, 1, 31))
    #expect(range.contains(try dateRange(bs(2080, 1, 5), bs(2080, 1, 20))))
    #expect(!range.contains(try dateRange(bs(2079, 12, 30), bs(2080, 1, 5))))
  }

  @Test("NepaliDateRangeTests.Overlaps_RangesOverlap_ReturnsTrue")
  func overlapsRangesOverlapReturnsTrue() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    let b = try dateRange(bs(2080, 1, 10), bs(2080, 1, 20))
    #expect(a.overlaps(b) && b.overlaps(a))
  }

  @Test("NepaliDateRangeTests.Overlaps_RangesDontOverlap_ReturnsFalse")
  func overlapsRangesDontOverlapReturnsFalse() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    let b = try dateRange(bs(2080, 1, 16), bs(2080, 1, 20))
    #expect(!a.overlaps(b) && !b.overlaps(a))
  }

  @Test("NepaliDateRangeTests.IsAdjacentTo_AdjacentRanges_ReturnsTrue")
  func isAdjacentToAdjacentRangesReturnsTrue() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    let b = try dateRange(bs(2080, 1, 16), bs(2080, 1, 20))
    #expect(a.isAdjacent(to: b) && b.isAdjacent(to: a))
  }

  @Test("NepaliDateRangeTests.Intersect_OverlappingRanges_ReturnsIntersection")
  func intersectOverlappingRangesReturnsIntersection() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    let b = try dateRange(bs(2080, 1, 10), bs(2080, 1, 20))
    #expect(a.intersection(b) == (try dateRange(bs(2080, 1, 10), bs(2080, 1, 15))))
  }

  @Test("NepaliDateRangeTests.Union_OverlappingRanges_ReturnsUnion")
  func unionOverlappingRangesReturnsUnion() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    let b = try dateRange(bs(2080, 1, 10), bs(2080, 1, 20))
    #expect(a.union(b) == (try dateRange(bs(2080, 1, 1), bs(2080, 1, 20))))
    #expect(b.union(a) == a.union(b))
  }

  @Test("NepaliDateRangeTests.Except_RemovingRangeFromMiddle_ReturnsTwoRanges")
  func exceptRemovingRangeFromMiddleReturnsTwoRanges() throws {
    let range = try dateRange(bs(2080, 1, 1), bs(2080, 1, 20))
    let removed = try dateRange(bs(2080, 1, 8), bs(2080, 1, 12))
    #expect(
      range.subtracting(removed) == [
        try dateRange(bs(2080, 1, 1), bs(2080, 1, 7)),
        try dateRange(bs(2080, 1, 13), bs(2080, 1, 20)),
      ])
  }

  @Test("NepaliDateRangeTests.SplitByMonth_RangeAcrossMonths_SplitsCorrectly")
  func splitByMonthRangeAcrossMonthsSplitsCorrectly() throws {
    let range = try dateRange(bs(2080, 1, 15), bs(2080, 3, 10))
    let pieces = range.splitByMonth()
    #expect(pieces.count == 3)
    #expect(pieces[0].lowerBound == (try bs(2080, 1, 15)))
    #expect(pieces[0].upperBound == (try bs(2080, 1, 31)))
    #expect(pieces[2].lowerBound == (try bs(2080, 3, 1)))
    #expect(pieces[2].upperBound == (try bs(2080, 3, 10)))
  }

  @Test("NepaliDateRangeTests.WorkingDays_ReturnsCorrectDays")
  func workingDaysReturnsCorrectDays() throws {
    let range = try dateRange(bs(2081, 4, 13), bs(2081, 4, 21))
    let days = range.workingDays()
    #expect(days.count == 8)
    #expect(!days.contains(try bs(2081, 4, 19)))
  }

  @Test("NepaliDateRangeTests.Demo_RangeOperations")
  func demoRangeOperations() throws {
    let range = try dateRange(bs(2081, 4, 10), bs(2081, 4, 20))
    #expect(range.count == 11)
    #expect(range.contains(try bs(2081, 4, 15)))
    #expect(range.intersection(try dateRange(bs(2081, 4, 15), bs(2081, 4, 25))) != nil)
    #expect(range.subtracting(try dateRange(bs(2081, 4, 12), bs(2081, 4, 18))).count == 2)
    #expect(range.union(range) == range)
    #expect(range.description == "2081/04/10 - 2081/04/20")
  }

  @Test("NepaliDateRangeTests.Enumeration_EnumeratesAllDaysInRange")
  func enumerationEnumeratesAllDaysInRange() throws {
    let days = Array(try dateRange(bs(2080, 1, 1), bs(2080, 1, 10)))
    #expect(days.count == 10)
    for i in 0..<10 { #expect(days[i] == (try bs(2080, 1, i + 1))) }
  }
}
