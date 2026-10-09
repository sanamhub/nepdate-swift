import Testing

@testable import NepDate

// D-08: C# `yearOffset` becomes `FiscalYear(startYear: fy.startYear + offset)`, and
// `FiscalYearQuarters.Current` becomes `date.quarter`.
@Suite("FiscalYearInstanceMethodTests")
struct FiscalYearInstanceMethodTests {
  /// The first and last day of quarter `q` of the fiscal year that contains `date`.
  func quarter(_ date: NepaliDate, _ q: Quarter, offset: Int = 0) throws -> NepaliDateRange {
    try FiscalYear(startYear: date.fiscalYear.startYear + offset).range(of: q)
  }

  /// The last day of a BS month.
  func monthEnd(_ year: Int, _ month: Int) throws -> NepaliDate {
    try bs(year, month, 1).lastDayOfMonth
  }

  // MARK: start

  @Test("FiscalYearInstanceMethodTests.FiscalYearStartDate_DateInShrawan_ReturnsSameyearShrawan1")
  func startDateInShrawan() throws {
    #expect(try bs(2080, 4, 15).fiscalYear.start() == bs(2080, 4, 1))
  }

  @Test("FiscalYearInstanceMethodTests.FiscalYearStartDate_DateInChaitra_ReturnsSameYearShrawan1")
  func startDateInChaitra() throws {
    #expect(try bs(2080, 12, 15).fiscalYear.start() == bs(2080, 4, 1))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearStartDate_DateInBasikhakh_ReturnsPreviousYearShrawan1")
  func startDateInBaishakh() throws {
    #expect(try bs(2080, 1, 15).fiscalYear.start() == bs(2079, 4, 1))
  }

  @Test("FiscalYearInstanceMethodTests.FiscalYearStartDate_DateInAshadh_ReturnsPreviousYearShrawan1")
  func startDateInAshad() throws {
    #expect(try bs(2080, 3, 10).fiscalYear.start() == bs(2079, 4, 1))
  }

  @Test("FiscalYearInstanceMethodTests.FiscalYearStartDate_WithPositiveYearOffset_ShiftsForward")
  func startWithPositiveOffset() throws {
    let fy = try bs(2080, 4, 1).fiscalYear
    #expect(try FiscalYear(startYear: fy.startYear + 1).start() == bs(2081, 4, 1))
  }

  @Test("FiscalYearInstanceMethodTests.FiscalYearStartDate_WithNegativeYearOffset_ShiftsBackward")
  func startWithNegativeOffset() throws {
    let fy = try bs(2080, 4, 1).fiscalYear
    #expect(try FiscalYear(startYear: fy.startYear - 1).start() == bs(2079, 4, 1))
  }

  // MARK: end

  @Test("FiscalYearInstanceMethodTests.FiscalYearEndDate_DateInShrawan_ReturnsNextYearAshad")
  func endDateInShrawan() throws {
    #expect(try bs(2080, 4, 15).fiscalYear.end() == monthEnd(2081, 3))
  }

  @Test("FiscalYearInstanceMethodTests.FiscalYearEndDate_DateInChaitra_ReturnsNextYearAshadh")
  func endDateInChaitra() throws {
    let end = try bs(2080, 12, 15).fiscalYear.end()
    #expect(end.year == 2081 && end.month == 3)
  }

  @Test("FiscalYearInstanceMethodTests.FiscalYearEndDate_DateInBasikhakh_ReturnsSameYearAshadh")
  func endDateInBaishakh() throws {
    #expect(try bs(2080, 1, 15).fiscalYear.end() == monthEnd(2080, 3))
  }

  @Test("FiscalYearInstanceMethodTests.FiscalYearEndDate_WithPositiveYearOffset_ShiftsForward")
  func endWithPositiveOffset() throws {
    let fy = try bs(2080, 4, 1).fiscalYear
    let end = try FiscalYear(startYear: fy.startYear + 1).end()
    #expect(end.year == 2082 && end.month == 3)
  }

  // MARK: start and end together

  @Test("FiscalYearInstanceMethodTests.FiscalYearStartAndEndDate_DateInQ2_ReturnsBothBoundaries")
  func startAndEndInQ2() throws {
    let range = try bs(2080, 8, 15).fiscalYear.range()
    #expect(range.lowerBound == (try bs(2080, 4, 1)))
    #expect(range.upperBound.year == 2081 && range.upperBound.month == 3)
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearStartAndEndDate_DateInQ4_ReturnsPreviousFiscalYearBoundaries"
  )
  func startAndEndInQ4() throws {
    let range = try bs(2081, 2, 10).fiscalYear.range()
    #expect(range.lowerBound == (try bs(2080, 4, 1)))
    #expect(range.upperBound.year == 2081 && range.upperBound.month == 3)
  }

  // MARK: quarter starts from 2080-05-15 (Q1 of FY 2080)

  @Test("FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_ExplicitFirst_ReturnsShrawan1")
  func quarterStartExplicitFirst() throws {
    #expect(try quarter(bs(2080, 5, 15), .q1).lowerBound == bs(2080, 4, 1))
  }

  @Test("FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_ExplicitSecond_ReturnsKartik1")
  func quarterStartExplicitSecond() throws {
    #expect(try quarter(bs(2080, 5, 15), .q2).lowerBound == bs(2080, 7, 1))
  }

  @Test("FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_ExplicitThird_ReturnsMagh1")
  func quarterStartExplicitThird() throws {
    #expect(try quarter(bs(2080, 5, 15), .q3).lowerBound == bs(2080, 10, 1))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_ExplicitFourth_ReturnsNextYearBasikhakh1"
  )
  func quarterStartExplicitFourth() throws {
    #expect(try quarter(bs(2080, 5, 15), .q4).lowerBound == bs(2081, 1, 1))
  }

  // MARK: quarter ends from 2080-05-15

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_ExplicitFirst_ReturnsLastDayOfAshoj")
  func quarterEndExplicitFirst() throws {
    #expect(try quarter(bs(2080, 5, 15), .q1).upperBound == monthEnd(2080, 6))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_ExplicitSecond_ReturnsLastDayOfPoush")
  func quarterEndExplicitSecond() throws {
    #expect(try quarter(bs(2080, 5, 15), .q2).upperBound == monthEnd(2080, 9))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_ExplicitThird_ReturnsLastDayOfChaitra")
  func quarterEndExplicitThird() throws {
    #expect(try quarter(bs(2080, 5, 15), .q3).upperBound == monthEnd(2080, 12))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_ExplicitFourth_ReturnsNextYearLastDayOfAshadh"
  )
  func quarterEndExplicitFourth() throws {
    #expect(try quarter(bs(2080, 5, 15), .q4).upperBound == monthEnd(2081, 3))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterStartAndEndDate_ExplicitSecond_ReturnsBothBoundaries"
  )
  func quarterStartAndEndExplicitSecond() throws {
    let range = try quarter(bs(2080, 5, 15), .q2)
    #expect(range.lowerBound == (try bs(2080, 7, 1)))
    #expect(range.upperBound.year == 2080 && range.upperBound.month == 9)
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterStartAndEndDate_ExplicitThird_ReturnsBothBoundaries"
  )
  func quarterStartAndEndExplicitThird() throws {
    let range = try quarter(bs(2080, 5, 15), .q3)
    #expect(range.lowerBound == (try bs(2080, 10, 1)))
    #expect(range.upperBound.month == 12)
  }

  // MARK: the current quarter

  @Test("FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_Current_DateInQ1_ReturnsShrawan1")
  func currentQuarterStartInQ1() throws {
    let date = try bs(2080, 5, 15)
    #expect(try quarter(date, date.quarter).lowerBound == bs(2080, 4, 1))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_Current_DateInQ1_ReturnsLastDayOfAshoj")
  func currentQuarterEndInQ1() throws {
    let date = try bs(2080, 5, 15)
    let end = try quarter(date, date.quarter).upperBound
    #expect(end.year == 2080 && end.month == 6)
  }

  @Test("FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_Current_DateInQ2_ReturnsKartik1")
  func currentQuarterStartInQ2() throws {
    let date = try bs(2080, 8, 15)
    #expect(try quarter(date, date.quarter).lowerBound == bs(2080, 7, 1))
  }

  @Test("FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_Current_DateInQ3_ReturnsMagh1")
  func currentQuarterStartInQ3() throws {
    let date = try bs(2080, 11, 15)
    #expect(try quarter(date, date.quarter).lowerBound == bs(2080, 10, 1))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_Current_DateInQ3_ReturnsLastDayOfChaitra")
  func currentQuarterEndInQ3() throws {
    let date = try bs(2080, 11, 15)
    let end = try quarter(date, date.quarter).upperBound
    #expect(end.year == 2080 && end.month == 12)
  }

  // MARK: offsets

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_ExplicitFirstWithOffset1_ReturnsNextYearShrawan1"
  )
  func quarterStartWithOffset1() throws {
    #expect(try quarter(bs(2080, 5, 15), .q1, offset: 1).lowerBound == bs(2081, 4, 1))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_ExplicitFirstWithNegativeOffset_ReturnsPreviousYearShrawan1"
  )
  func quarterStartWithNegativeOffset() throws {
    #expect(try quarter(bs(2080, 5, 15), .q1, offset: -1).lowerBound == bs(2079, 4, 1))
  }

  // MARK: months and fiscal years

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearStartDate_AllFiscalMonths_Return2080Shrawan1",
    arguments: [4, 6, 7, 12])
  func startAllFiscalMonths(month: Int) throws {
    #expect(try bs(2080, month, 1).fiscalYear.start() == bs(2080, 4, 1))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearStartDate_Q4CalendarMonths_ReturnPreviousYearShrawan1",
    arguments: [1, 2, 3])
  func startQ4CalendarMonths(month: Int) throws {
    #expect(try bs(2080, month, 1).fiscalYear.start() == bs(2079, 4, 1))
  }

  // MARK: from 2081-02-10 (Q4 of FY 2080)

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_FromQ4Date_ExplicitFirst_ReturnsFY2080Q1Start"
  )
  func fromQ4StartFirst() throws {
    #expect(try quarter(bs(2081, 2, 10), .q1).lowerBound == bs(2080, 4, 1))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_FromQ4Date_ExplicitSecond_ReturnsFY2080Q2Start"
  )
  func fromQ4StartSecond() throws {
    #expect(try quarter(bs(2081, 2, 10), .q2).lowerBound == bs(2080, 7, 1))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_FromQ4Date_ExplicitThird_ReturnsFY2080Q3Start"
  )
  func fromQ4StartThird() throws {
    #expect(try quarter(bs(2081, 2, 10), .q3).lowerBound == bs(2080, 10, 1))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_FromQ4Date_ExplicitFourth_ReturnsFY2080Q4Start"
  )
  func fromQ4StartFourth() throws {
    #expect(try quarter(bs(2081, 2, 10), .q4).lowerBound == bs(2081, 1, 1))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_FromQ4Date_Current_ReturnsFY2080Q4Start"
  )
  func fromQ4StartCurrent() throws {
    let date = try bs(2081, 2, 10)
    #expect(try quarter(date, date.quarter).lowerBound == bs(2081, 1, 1))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_FromQ4Date_ExplicitFirst_ReturnsFY2080Q1End"
  )
  func fromQ4EndFirst() throws {
    #expect(try quarter(bs(2081, 2, 10), .q1).upperBound == monthEnd(2080, 6))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_FromQ4Date_ExplicitThird_ReturnsFY2080Q3End"
  )
  func fromQ4EndThird() throws {
    #expect(try quarter(bs(2081, 2, 10), .q3).upperBound == monthEnd(2080, 12))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_FromQ4Date_ExplicitFourth_ReturnsFY2080Q4End"
  )
  func fromQ4EndFourth() throws {
    #expect(try quarter(bs(2081, 2, 10), .q4).upperBound == monthEnd(2081, 3))
  }

  @Test(
    "FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_FromQ4Date_Current_ReturnsFY2080Q4End")
  func fromQ4EndCurrent() throws {
    let date = try bs(2081, 2, 10)
    #expect(try quarter(date, date.quarter).upperBound == monthEnd(2081, 3))
  }
}
