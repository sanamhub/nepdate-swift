import Testing

@testable import NepDate

// D-09 as in NepaliDateRangeTests.swift. The `Current*` rows need `today(in:)` (D-14, S4-04).
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

  @Test(
    "NepaliDateRangeExtendedTests.CurrentMonth_StartIsFirstDayOfCurrentMonth",
    .disabled("PENDING S4-04: needs today(in:) (D-14)"))
  func currentMonthStart() {}

  @Test(
    "NepaliDateRangeExtendedTests.CurrentMonth_EndIsLastDayOfCurrentMonth",
    .disabled("PENDING S4-04: needs today(in:) (D-14)"))
  func currentMonthEnd() {}

  @Test(
    "NepaliDateRangeExtendedTests.CurrentMonth_ContainsToday",
    .disabled("PENDING S4-04: needs today(in:) (D-14)"))
  func currentMonthContainsToday() {}

  @Test(
    "NepaliDateRangeExtendedTests.CurrentFiscalYear_ContainsToday",
    .disabled("PENDING S4-04: needs today(in:) (D-14)"))
  func currentFiscalYearContainsToday() {}

  @Test(
    "NepaliDateRangeExtendedTests.CurrentFiscalYear_StartIsShrawan",
    .disabled("PENDING S4-04: needs today(in:) (D-14)"))
  func currentFiscalYearStart() {}

  @Test(
    "NepaliDateRangeExtendedTests.CurrentFiscalYear_EndIsAshadh",
    .disabled("PENDING S4-04: needs today(in:) (D-14)"))
  func currentFiscalYearEnd() {}

  @Test(
    "NepaliDateRangeExtendedTests.CurrentCalendarYear_ContainsToday",
    .disabled("PENDING S4-04: needs today(in:) (D-14)"))
  func currentCalendarYearContainsToday() {}

  @Test(
    "NepaliDateRangeExtendedTests.CurrentCalendarYear_StartIsBaishakh1",
    .disabled("PENDING S4-04: needs today(in:) (D-14)"))
  func currentCalendarYearStart() {}

  // NepaliDateRangeExtendedTests.SplitByFiscalQuarter_EmptyRange_ReturnsEmptyArray: D-09.
  // NepaliDateRangeExtendedTests.SplitByFiscalQuarter_RangeWithinOneQuarter_ReturnsSingleRange:
  // D-09.
  // NepaliDateRangeExtendedTests.SplitByFiscalQuarter_RangeSpanningTwoQuarters_ReturnsTwoRanges:
  // D-09.
  // NepaliDateRangeExtendedTests.SplitByFiscalQuarter_FullFiscalYear_ReturnsFourRanges: D-09.
  // NepaliDateRangeExtendedTests.SplitByFiscalQuarter_RangeInQ4Months_SingleRange: D-09.
  // NepaliDateRangeExtendedTests.DatesWithInterval_Zero_ThrowsArgumentOutOfRangeException: D-09.
  // NepaliDateRangeExtendedTests.DatesWithInterval_NegativeInterval_ThrowsArgumentOutOfRangeException:
  // D-09.
  // NepaliDateRangeExtendedTests.DatesWithInterval_IntervalOfOne_YieldsEveryDay: D-09.
  // NepaliDateRangeExtendedTests.DatesWithInterval_IntervalOfTwo_YieldsOddDays: D-09.
  // NepaliDateRangeExtendedTests.DatesWithInterval_IntervalLargerThanRange_YieldsOnlyStartDate:
  // D-09.
  // NepaliDateRangeExtendedTests.DatesWithInterval_EmptyRange_YieldsNothing: D-09.
  // NepaliDateRangeExtendedTests.WeekendDays_IncludeSundayTrue_ReturnsBothSaturdayAndSunday: D-09.
  // NepaliDateRangeExtendedTests.WeekendDays_IncludeSundayFalse_ReturnsOnlySaturday: D-09.
  // NepaliDateRangeExtendedTests.WeekendDays_RangeWithNoWeekend_ReturnsEmpty: D-09.
  // NepaliDateRangeExtendedTests.WeekendDays_EmptyRange_ReturnsEmpty: D-09.
  // NepaliDateRangeExtendedTests.WorkingDays_ExcludeSundayFalse_ExcludesOnlySaturday: D-09.
  // NepaliDateRangeExtendedTests.WorkingDays_ExcludeSundayTrue_ExcludesBothSatAndSun: D-09.
  // NepaliDateRangeExtendedTests.WorkingDays_EmptyRange_ReturnsEmpty: D-09.

  // C# `FromDayCount(start, n)` rejects n < 1; the Swift equivalent, a range ending n - 1 days
  // after the start, is nil for those counts.
  @Test("NepaliDateRangeExtendedTests.FromDayCount_ZeroDays_ThrowsArgumentOutOfRangeException")
  func fromDayCountZeroDays() throws {
    let start = try bs(2080, 5, 1)
    #expect(NepaliDateRange(start, try start.adding(days: -1)) == nil)
  }

  @Test("NepaliDateRangeExtendedTests.FromDayCount_NegativeDays_ThrowsArgumentOutOfRangeException")
  func fromDayCountNegativeDays() throws {
    let start = try bs(2080, 5, 1)
    #expect(NepaliDateRange(start, try start.adding(days: -6)) == nil)
  }

  // NepaliDateRangeExtendedTests.Intersect_NonOverlappingRanges_ReturnsEmptyRange: D-09.
  // NepaliDateRangeExtendedTests.Intersect_AdjacentRanges_ReturnsEmptyRange: D-09.
  // NepaliDateRangeExtendedTests.Intersect_OneRangeFullyInsideOther_ReturnsInnerRange: D-09.
  // NepaliDateRangeExtendedTests.Union_LeftRangeIsEmpty_ReturnsRightRange: D-09.
  // NepaliDateRangeExtendedTests.Union_RightRangeIsEmpty_ReturnsLeftRange: D-09.
  // NepaliDateRangeExtendedTests.Union_NonOverlappingRanges_SpansEntireGap: D-09.

  @Test("NepaliDateRangeExtendedTests.Contains_ExactStartDate_ReturnsTrue")
  func containsExactStartDate() throws {
    let range = try dateRange(bs(2080, 1, 5), bs(2080, 1, 20))
    #expect(range.contains(try bs(2080, 1, 5)))
  }

  @Test("NepaliDateRangeExtendedTests.Contains_ExactEndDate_ReturnsTrue")
  func containsExactEndDate() throws {
    let range = try dateRange(bs(2080, 1, 5), bs(2080, 1, 20))
    #expect(range.contains(try bs(2080, 1, 20)))
  }

  @Test("NepaliDateRangeExtendedTests.Contains_OneDayBeforeStart_ReturnsFalse")
  func containsOneDayBeforeStart() throws {
    let range = try dateRange(bs(2080, 1, 5), bs(2080, 1, 20))
    #expect(!range.contains(try bs(2080, 1, 4)))
  }

  @Test("NepaliDateRangeExtendedTests.Contains_OneDayAfterEnd_ReturnsFalse")
  func containsOneDayAfterEnd() throws {
    let range = try dateRange(bs(2080, 1, 5), bs(2080, 1, 20))
    #expect(!range.contains(try bs(2080, 1, 21)))
  }

  // An empty C# range is nil in Swift, so it contains nothing by construction.
  @Test("NepaliDateRangeExtendedTests.Contains_EmptyRange_ContainsNothing")
  func containsEmptyRange() throws {
    let empty = NepaliDateRange(try bs(2080, 5, 10), try bs(2080, 5, 1))
    #expect(empty?.contains(try bs(2080, 5, 5)) != true)
  }

  // NepaliDateRangeExtendedTests.IsAdjacentTo_GapBetweenRanges_ReturnsFalse: D-09.
  // NepaliDateRangeExtendedTests.IsAdjacentTo_OverlappingRanges_ReturnsFalse: D-09.
  // NepaliDateRangeExtendedTests.IsAdjacentTo_EmptyRange_ReturnsFalse: D-09.
  // NepaliDateRangeExtendedTests.Except_NonOverlappingExcludeRange_ReturnsOriginalRange: D-09.
  // NepaliDateRangeExtendedTests.Except_ExcludeRangeFullyContainsThis_ReturnsEmptyArray: D-09.
  // NepaliDateRangeExtendedTests.Except_ExcludeOverlapsStart_ReturnsRightPart: D-09.
  // NepaliDateRangeExtendedTests.Except_ExcludeOverlapsEnd_ReturnsLeftPart: D-09.

  @Test("NepaliDateRangeExtendedTests.GetEnumerator_ThreeDayRange_YieldsExactlyThreeDates")
  func getEnumeratorThreeDayRange() throws {
    var dates: [NepaliDate] = []
    for date in try dateRange(bs(2080, 5, 13), bs(2080, 5, 15)) { dates.append(date) }
    #expect(dates == [try bs(2080, 5, 13), try bs(2080, 5, 14), try bs(2080, 5, 15)])
  }

  @Test("NepaliDateRangeExtendedTests.GetEnumerator_EmptyRange_YieldsNoDates")
  func getEnumeratorEmptyRange() throws {
    let empty = NepaliDateRange(try bs(2080, 5, 10), try bs(2080, 5, 1))
    let dates = empty.map { Array($0) } ?? []
    #expect(dates.isEmpty)
  }

  @Test("NepaliDateRangeExtendedTests.GetEnumerator_SingleDayRange_YieldsOneDate")
  func getEnumeratorSingleDayRange() throws {
    let date = try bs(2080, 5, 15)
    #expect(Array(try dateRange(date, date)) == [date])
  }

  // NepaliDateRangeExtendedTests.ToString_DefaultFormat_IsStartDashEnd: D-09.
  // NepaliDateRangeExtendedTests.ToString_EmptyRange_ReturnsEmptyRangeString: D-09.
  // NepaliDateRangeExtendedTests.ToString_WithDateFormat_UsesSpecifiedFormat: D-09.
  // NepaliDateRangeExtendedTests.ToString_WithDateFormat_EmptyRange_ReturnsEmptyRangeString: D-09.

  @Test("NepaliDateRangeExtendedTests.Equals_IdenticalRanges_ReturnsTrue")
  func equalsIdenticalRanges() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    let b = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    #expect(a == b)
  }

  @Test("NepaliDateRangeExtendedTests.Equals_DifferentStart_ReturnsFalse")
  func equalsDifferentStart() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    let b = try dateRange(bs(2080, 1, 2), bs(2080, 1, 15))
    #expect(a != b)
  }

  @Test("NepaliDateRangeExtendedTests.Equals_DifferentEnd_ReturnsFalse")
  func equalsDifferentEnd() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    let b = try dateRange(bs(2080, 1, 1), bs(2080, 1, 16))
    #expect(a != b)
  }

  // Two empty C# ranges are equal; in Swift both are nil.
  @Test("NepaliDateRangeExtendedTests.Equals_BothEmpty_ReturnsTrue")
  func equalsBothEmpty() throws {
    let empty1 = NepaliDateRange(try bs(2080, 5, 10), try bs(2080, 5, 1))
    let empty2 = NepaliDateRange(try bs(2079, 3, 10), try bs(2079, 3, 1))
    #expect(empty1 == empty2)
  }

  @Test("NepaliDateRangeExtendedTests.Equals_ObjectOverload_SameRange_ReturnsTrue")
  func equalsObjectOverloadSameRange() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    let b = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    #expect(AnyHashable(a) == AnyHashable(b))
  }

  // NepaliDateRangeExtendedTests.Equals_ObjectOverload_WrongType_ReturnsFalse: n/a, `==` only
  // accepts another NepaliDateRange.

  @Test("NepaliDateRangeExtendedTests.GetHashCode_EqualRanges_SameHash")
  func getHashCodeEqualRanges() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    let b = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    #expect(a.hashValue == b.hashValue)
  }

  @Test("NepaliDateRangeExtendedTests.OperatorEquals_IdenticalRanges_ReturnsTrue")
  func operatorEqualsIdenticalRanges() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    let b = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    #expect(a == b)
    #expect(!(a != b))
  }

  @Test("NepaliDateRangeExtendedTests.OperatorNotEquals_DifferentRanges_ReturnsTrue")
  func operatorNotEqualsDifferentRanges() throws {
    let a = try dateRange(bs(2080, 1, 1), bs(2080, 1, 15))
    let b = try dateRange(bs(2080, 1, 1), bs(2080, 1, 16))
    #expect(a != b)
    #expect(!(a == b))
  }
}
