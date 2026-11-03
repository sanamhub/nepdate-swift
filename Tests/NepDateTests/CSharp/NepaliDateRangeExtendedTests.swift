import Testing

#if canImport(Foundation)
  import Foundation
#endif

@testable import NepDate

// The range is inclusive and never empty. A C# empty range (end before start) is `nil` here, so
// every C# empty-range test checks the `nil` result instead of an empty value.
@Suite("NepaliDateRangeExtendedTests")
struct NepaliDateRangeExtendedTests {
  @Test("NepaliDateRangeExtendedTests.ForCalendarYear_StartsAtBaishakhOne_EndsAtChaitraEnd")
  func forCalendarYearStartsAndEnds() throws {
    let range = try NepaliDateRange.year(2080)
    #expect(range.lowerBound == (try bs(2080, 1, 1)))
    #expect(range.upperBound.year == 2080 && range.upperBound.month == 12)
    #expect(range.upperBound.day == range.upperBound.monthLength)
  }

  @Test("NepaliDateRangeExtendedTests.ForCalendarYear_LengthIsReasonable")
  func forCalendarYearLengthIsReasonable() throws {
    #expect((365...366).contains(try NepaliDateRange.year(2080).count))
  }

  // The fixed clock makes the `Current*` tests deterministic.
  #if canImport(Foundation)
    @Test("NepaliDateRangeExtendedTests.CurrentMonth_StartIsFirstDayOfCurrentMonth")
    func currentMonthStart() throws {
      let utc = try zone("UTC")
      let today = NepaliDate.today(in: utc, now: fixedClock)
      let range = try NepaliDateRange.currentMonth(in: utc, now: fixedClock)
      #expect(range.lowerBound == today.firstDayOfMonth)
    }

    @Test("NepaliDateRangeExtendedTests.CurrentMonth_EndIsLastDayOfCurrentMonth")
    func currentMonthEnd() throws {
      let utc = try zone("UTC")
      let today = NepaliDate.today(in: utc, now: fixedClock)
      let range = try NepaliDateRange.currentMonth(in: utc, now: fixedClock)
      #expect(range.upperBound == today.lastDayOfMonth)
    }

    @Test("NepaliDateRangeExtendedTests.CurrentMonth_ContainsToday")
    func currentMonthContainsToday() throws {
      let utc = try zone("UTC")
      let today = NepaliDate.today(in: utc, now: fixedClock)
      #expect(try NepaliDateRange.currentMonth(in: utc, now: fixedClock).contains(today))
    }

    @Test("NepaliDateRangeExtendedTests.CurrentFiscalYear_ContainsToday")
    func currentFiscalYearContainsToday() throws {
      let utc = try zone("UTC")
      let today = NepaliDate.today(in: utc, now: fixedClock)
      #expect(try NepaliDateRange.currentFiscalYear(in: utc, now: fixedClock).contains(today))
    }

    @Test("NepaliDateRangeExtendedTests.CurrentFiscalYear_StartIsShrawan")
    func currentFiscalYearStart() throws {
      let utc = try zone("UTC")
      let range = try NepaliDateRange.currentFiscalYear(in: utc, now: fixedClock)
      #expect(range.lowerBound.month == 4)
    }

    @Test("NepaliDateRangeExtendedTests.CurrentFiscalYear_EndIsAshadh")
    func currentFiscalYearEnd() throws {
      let utc = try zone("UTC")
      let range = try NepaliDateRange.currentFiscalYear(in: utc, now: fixedClock)
      #expect(range.upperBound.month == 3)
    }

    @Test("NepaliDateRangeExtendedTests.CurrentCalendarYear_ContainsToday")
    func currentCalendarYearContainsToday() throws {
      let utc = try zone("UTC")
      let today = NepaliDate.today(in: utc, now: fixedClock)
      #expect(try NepaliDateRange.currentCalendarYear(in: utc, now: fixedClock).contains(today))
    }

    @Test("NepaliDateRangeExtendedTests.CurrentCalendarYear_StartIsBaishakh1")
    func currentCalendarYearStart() throws {
      let utc = try zone("UTC")
      let today = NepaliDate.today(in: utc, now: fixedClock)
      let range = try NepaliDateRange.currentCalendarYear(in: utc, now: fixedClock)
      #expect(range.lowerBound == (try bs(today.year, 1, 1)))
    }
  #endif

  @Test("NepaliDateRangeExtendedTests.SplitByFiscalQuarter_EmptyRange_ReturnsEmptyArray")
  func splitByFiscalQuarterEmptyRangeReturnsEmptyArray() throws {
    #expect(NepaliDateRange(try bs(2080, 5, 10), try bs(2080, 5, 1)) == nil)
  }

  @Test(
    "NepaliDateRangeExtendedTests.SplitByFiscalQuarter_RangeWithinOneQuarter_ReturnsSingleRange")
  func splitByFiscalQuarterRangeWithinOneQuarterReturnsSingleRange() throws {
    let range = try dateRange(bs(2081, 4, 10), bs(2081, 4, 20))
    #expect(range.splitByFiscalQuarter().count == 1)
  }

  @Test(
    "NepaliDateRangeExtendedTests.SplitByFiscalQuarter_RangeSpanningTwoQuarters_ReturnsTwoRanges")
  func splitByFiscalQuarterRangeSpanningTwoQuartersReturnsTwoRanges() throws {
    let range = try dateRange(bs(2081, 6, 15), bs(2081, 7, 15))
    let pieces = range.splitByFiscalQuarter()
    #expect(pieces.count == 2)
    #expect(pieces[0].lowerBound == (try bs(2081, 6, 15)))
    #expect(pieces[0].upperBound == (try bs(2081, 6, 30)))
    #expect(pieces[1].lowerBound == (try bs(2081, 7, 1)))
    #expect(pieces[1].upperBound == (try bs(2081, 7, 15)))
  }

  @Test("NepaliDateRangeExtendedTests.SplitByFiscalQuarter_FullFiscalYear_ReturnsFourRanges")
  func splitByFiscalQuarterFullFiscalYearReturnsFourRanges() throws {
    let range = try FiscalYear(startYear: 2081).range()
    let pieces = range.splitByFiscalQuarter()
    #expect(pieces.count == 4)
    #expect(pieces.first?.lowerBound == range.lowerBound)
    #expect(pieces.last?.upperBound == range.upperBound)
  }

  @Test("NepaliDateRangeExtendedTests.SplitByFiscalQuarter_RangeInQ4Months_SingleRange")
  func splitByFiscalQuarterRangeInQ4MonthsSingleRange() throws {
    let range = try dateRange(bs(2081, 1, 1), bs(2081, 3, 30))
    let pieces = range.splitByFiscalQuarter()
    #expect(pieces.count == 1)
    #expect(pieces[0].lowerBound == range.lowerBound)
    #expect(pieces[0].upperBound == range.upperBound)
  }

  @Test("NepaliDateRangeExtendedTests.DatesWithInterval_Zero_ThrowsArgumentOutOfRangeException")
  func datesWithIntervalZeroThrows() throws {
    let range = try dateRange(bs(2080, 7, 1), bs(2080, 7, 5))
    expectError(.invalidArgument) { _ = try range.dates(every: 0) }
  }

  @Test(
    "NepaliDateRangeExtendedTests.DatesWithInterval_NegativeInterval_ThrowsArgumentOutOfRangeException"
  )
  func datesWithIntervalNegativeThrows() throws {
    let range = try dateRange(bs(2080, 7, 1), bs(2080, 7, 5))
    expectError(.invalidArgument) { _ = try range.dates(every: -1) }
  }

  @Test("NepaliDateRangeExtendedTests.DatesWithInterval_IntervalOfOne_YieldsEveryDay")
  func datesWithIntervalOneYieldsEveryDay() throws {
    let range = try dateRange(bs(2080, 7, 1), bs(2080, 7, 5))
    #expect(try range.dates(every: 1).count == 5)
  }

  @Test("NepaliDateRangeExtendedTests.DatesWithInterval_IntervalOfTwo_YieldsOddDays")
  func datesWithIntervalTwoYieldsOddDays() throws {
    let range = try dateRange(bs(2080, 7, 1), bs(2080, 7, 10))
    #expect(
      try range.dates(every: 2) == [
        try bs(2080, 7, 1), try bs(2080, 7, 3), try bs(2080, 7, 5), try bs(2080, 7, 7),
        try bs(2080, 7, 9),
      ])
  }

  @Test(
    "NepaliDateRangeExtendedTests.DatesWithInterval_IntervalLargerThanRange_YieldsOnlyStartDate")
  func datesWithIntervalLargerThanRangeYieldsOnlyStartDate() throws {
    let range = try dateRange(bs(2080, 7, 1), bs(2080, 7, 5))
    #expect(try range.dates(every: 100) == [try bs(2080, 7, 1)])
  }

  @Test("NepaliDateRangeExtendedTests.DatesWithInterval_EmptyRange_YieldsNothing")
  func datesWithIntervalEmptyRangeYieldsNothing() throws {
    #expect(NepaliDateRange(try bs(2080, 5, 10), try bs(2080, 5, 1)) == nil)
  }

  @Test("NepaliDateRangeExtendedTests.WeekendDays_IncludeSundayTrue_ReturnsBothSaturdayAndSunday")
  func weekendDaysIncludeSundayTrueReturnsBoth() throws {
    let range = try dateRange(bs(2081, 4, 13), bs(2081, 4, 21))
    #expect(
      range.weekendDays(includingSunday: true) == [
        try bs(2081, 4, 13), try bs(2081, 4, 19), try bs(2081, 4, 20),
      ])
  }

  @Test("NepaliDateRangeExtendedTests.WeekendDays_IncludeSundayFalse_ReturnsOnlySaturday")
  func weekendDaysIncludeSundayFalseReturnsOnlySaturday() throws {
    let range = try dateRange(bs(2081, 4, 13), bs(2081, 4, 21))
    #expect(range.weekendDays(includingSunday: false) == [try bs(2081, 4, 19)])
  }

  @Test("NepaliDateRangeExtendedTests.WeekendDays_RangeWithNoWeekend_ReturnsEmpty")
  func weekendDaysRangeWithNoWeekendReturnsEmpty() throws {
    let range = try dateRange(bs(2081, 4, 15), bs(2081, 4, 15))
    #expect(range.weekendDays().isEmpty)
  }

  @Test("NepaliDateRangeExtendedTests.WeekendDays_EmptyRange_ReturnsEmpty")
  func weekendDaysEmptyRangeReturnsEmpty() throws {
    #expect(NepaliDateRange(try bs(2080, 5, 10), try bs(2080, 5, 1)) == nil)
  }

  @Test("NepaliDateRangeExtendedTests.WorkingDays_ExcludeSundayFalse_ExcludesOnlySaturday")
  func workingDaysExcludeSundayFalseExcludesOnlySaturday() throws {
    let range = try dateRange(bs(2081, 4, 13), bs(2081, 4, 21))
    let days = range.workingDays(excludingSunday: false)
    #expect(days.count == 8)
    #expect(!days.contains(try bs(2081, 4, 19)))
    #expect(days.contains(try bs(2081, 4, 13)))
  }

  @Test("NepaliDateRangeExtendedTests.WorkingDays_ExcludeSundayTrue_ExcludesBothSatAndSun")
  func workingDaysExcludeSundayTrueExcludesBoth() throws {
    let range = try dateRange(bs(2081, 4, 13), bs(2081, 4, 21))
    let days = range.workingDays(excludingSunday: true)
    #expect(days.count == 6)
    #expect(!days.contains(try bs(2081, 4, 19)))
    #expect(!days.contains(try bs(2081, 4, 20)))
  }

  @Test("NepaliDateRangeExtendedTests.WorkingDays_EmptyRange_ReturnsEmpty")
  func workingDaysEmptyRangeReturnsEmpty() throws {
    #expect(NepaliDateRange(try bs(2080, 5, 10), try bs(2080, 5, 1)) == nil)
  }

  @Test("NepaliDateRangeExtendedTests.Intersect_NonOverlappingRanges_ReturnsEmptyRange")
  func intersectNonOverlappingRangesReturnsEmpty() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 10))
    let b = try dateRange(bs(2080, 2, 1), bs(2080, 2, 10))
    #expect(a.intersection(b) == nil)
  }

  @Test("NepaliDateRangeExtendedTests.Intersect_AdjacentRanges_ReturnsEmptyRange")
  func intersectAdjacentRangesReturnsEmpty() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 10))
    let b = try dateRange(bs(2080, 1, 11), bs(2080, 1, 20))
    #expect(a.intersection(b) == nil)
  }

  @Test("NepaliDateRangeExtendedTests.Intersect_OneRangeFullyInsideOther_ReturnsInnerRange")
  func intersectOneRangeFullyInsideOtherReturnsInner() throws {
    let outer = try dateRange(bs(2080, 1, 1), bs(2080, 1, 31))
    let inner = try dateRange(bs(2080, 1, 10), bs(2080, 1, 20))
    #expect(outer.intersection(inner) == inner)
    #expect(inner.intersection(outer) == inner)
  }

  @Test("NepaliDateRangeExtendedTests.Union_LeftRangeIsEmpty_ReturnsRightRange")
  func unionLeftRangeIsEmptyReturnsRight() throws {
    let right = try dateRange(bs(2080, 1, 1), bs(2080, 1, 10))
    #expect(NepaliDateRange(try bs(2080, 2, 1), try bs(2080, 1, 1)) == nil)
    #expect(right.union(right) == right)
  }

  @Test("NepaliDateRangeExtendedTests.Union_RightRangeIsEmpty_ReturnsLeftRange")
  func unionRightRangeIsEmptyReturnsLeft() throws {
    let left = try dateRange(bs(2080, 1, 1), bs(2080, 1, 10))
    #expect(NepaliDateRange(try bs(2080, 1, 1), try bs(2079, 12, 1)) == nil)
    #expect(left.union(left) == left)
  }

  @Test("NepaliDateRangeExtendedTests.Union_NonOverlappingRanges_SpansEntireGap")
  func unionNonOverlappingRangesSpansEntireGap() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 10))
    let b = try dateRange(bs(2080, 2, 1), bs(2080, 2, 10))
    #expect(a.union(b) == (try dateRange(bs(2080, 1, 1), bs(2080, 2, 10))))
  }

  @Test("NepaliDateRangeExtendedTests.IsAdjacentTo_GapBetweenRanges_ReturnsFalse")
  func isAdjacentToGapBetweenRangesReturnsFalse() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 10))
    let b = try dateRange(bs(2080, 1, 12), bs(2080, 1, 20))
    #expect(!a.isAdjacent(to: b) && !b.isAdjacent(to: a))
  }

  @Test("NepaliDateRangeExtendedTests.IsAdjacentTo_OverlappingRanges_ReturnsFalse")
  func isAdjacentToOverlappingRangesReturnsFalse() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 10))
    let b = try dateRange(bs(2080, 1, 5), bs(2080, 1, 20))
    #expect(!a.isAdjacent(to: b) && !b.isAdjacent(to: a))
  }

  @Test("NepaliDateRangeExtendedTests.IsAdjacentTo_EmptyRange_ReturnsFalse")
  func isAdjacentToEmptyRangeReturnsFalse() throws {
    #expect(NepaliDateRange(try bs(2080, 1, 1), try bs(2079, 12, 1)) == nil)
  }

  @Test("NepaliDateRangeExtendedTests.Except_NonOverlappingExcludeRange_ReturnsOriginalRange")
  func exceptNonOverlappingExcludeRangeReturnsOriginal() throws {
    let range = try dateRange(bs(2080, 1, 1), bs(2080, 1, 10))
    let other = try dateRange(bs(2080, 2, 1), bs(2080, 2, 10))
    #expect(range.subtracting(other) == [range])
  }

  @Test("NepaliDateRangeExtendedTests.Except_ExcludeRangeFullyContainsThis_ReturnsEmptyArray")
  func exceptExcludeRangeFullyContainsThisReturnsEmptyArray() throws {
    let range = try dateRange(bs(2080, 1, 10), bs(2080, 1, 20))
    let other = try dateRange(bs(2080, 1, 1), bs(2080, 1, 31))
    #expect(range.subtracting(other).isEmpty)
  }

  @Test("NepaliDateRangeExtendedTests.Except_ExcludeOverlapsStart_ReturnsRightPart")
  func exceptExcludeOverlapsStartReturnsRightPart() throws {
    let range = try dateRange(bs(2080, 1, 1), bs(2080, 1, 20))
    let other = try dateRange(bs(2080, 1, 1), bs(2080, 1, 10))
    #expect(range.subtracting(other) == [try dateRange(bs(2080, 1, 11), bs(2080, 1, 20))])
  }

  @Test("NepaliDateRangeExtendedTests.Except_ExcludeOverlapsEnd_ReturnsLeftPart")
  func exceptExcludeOverlapsEndReturnsLeftPart() throws {
    let range = try dateRange(bs(2080, 1, 1), bs(2080, 1, 20))
    let other = try dateRange(bs(2080, 1, 10), bs(2080, 1, 20))
    #expect(range.subtracting(other) == [try dateRange(bs(2080, 1, 1), bs(2080, 1, 9))])
  }

  @Test("NepaliDateRangeExtendedTests.ToString_DefaultFormat_IsStartDashEnd")
  func toStringDefaultFormatIsStartDashEnd() throws {
    let range = try dateRange(bs(2080, 1, 15), bs(2080, 2, 10))
    #expect(range.description == "2080/01/15 - 2080/02/10")
  }

  @Test("NepaliDateRangeExtendedTests.ToString_EmptyRange_ReturnsEmptyRangeString")
  func toStringEmptyRangeReturnsEmptyRangeString() throws {
    #expect(NepaliDateRange(try bs(2080, 1, 1), try bs(2079, 12, 1)) == nil)
  }

  @Test("NepaliDateRangeExtendedTests.ToString_WithDateFormat_UsesSpecifiedFormat")
  func toStringWithDateFormatUsesSpecifiedFormat() throws {
    let range = try dateRange(bs(2080, 1, 15), bs(2080, 2, 10))
    #expect(range.formatted(order: .dmy, separator: .dash) == "15-01-2080 - 10-02-2080")
    #expect(
      range.formatted(order: .ymd, separator: .dot, lang: .nepali) == "२०८०.०१.१५ - २०८०.०२.१०")
  }

  @Test("NepaliDateRangeExtendedTests.ToString_WithDateFormat_EmptyRange_ReturnsEmptyRangeString")
  func toStringWithDateFormatEmptyRangeReturnsEmptyRangeString() throws {
    #expect(NepaliDateRange(try bs(2080, 1, 1), try bs(2079, 12, 1)) == nil)
  }

  // C# `FromDayCount(start, n)` rejects n < 1; the port throws `NepDateError` for those counts.
  @Test("NepaliDateRangeExtendedTests.FromDayCount_ZeroDays_ThrowsArgumentOutOfRangeException")
  func fromDayCountZeroDays() throws {
    let start = try bs(2080, 5, 1)
    expectError(.invalidArgument) { _ = try NepaliDateRange(start: start, dayCount: 0) }
  }

  @Test("NepaliDateRangeExtendedTests.FromDayCount_NegativeDays_ThrowsArgumentOutOfRangeException")
  func fromDayCountNegativeDays() throws {
    let start = try bs(2080, 5, 1)
    expectError(.invalidArgument) { _ = try NepaliDateRange(start: start, dayCount: -6) }
  }
}
