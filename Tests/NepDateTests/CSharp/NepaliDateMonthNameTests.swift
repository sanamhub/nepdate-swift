import Testing

@testable import NepDate

@Suite("NepaliDateMonthNameTests")
struct NepaliDateMonthNameTests {
  @Test(
    "NepaliDateMonthNameTests.MonthName_AllMonths_ReturnCorrectEnum",
    arguments: zip(1...12, Month.allCases))
  func monthNameAllMonths(month: Int, expected: Month) throws {
    #expect(try bs(2080, month, 1).bsMonth == expected)
  }

  @Test("NepaliDateMonthNameTests.MonthName_SameMonthDifferentDays_AllReturnSameEnum")
  func monthNameSameMonthDifferentDays() throws {
    let first = try bs(2080, 4, 1)
    #expect(first.bsMonth == .shrawan)
    #expect(try bs(2080, 4, 15).bsMonth == .shrawan)
    #expect(first.lastDayOfMonth.bsMonth == .shrawan)
  }

  @Test(
    "NepaliDateMonthNameTests.MonthName_SameMonthDifferentYears_AllReturnSameEnum",
    arguments: [2070, 2080, 2090, 2100])
  func monthNameSameMonthDifferentYears(year: Int) throws {
    #expect(try bs(year, 9, 1).bsMonth == .poush)
  }

  @Test("NepaliDateMonthNameTests.MonthName_AddingOneMonth_AdvancesEnum")
  func monthNameAddingOneMonth() throws {
    let falgun = try bs(2080, 11, 1)
    #expect(falgun.bsMonth == .falgun)
    #expect(try falgun.adding(months: 1).bsMonth == .chaitra)
  }

  @Test("NepaliDateMonthNameTests.MonthName_YearBoundary_WrapsFromChaitraToBasikhakh")
  func monthNameYearBoundary() throws {
    #expect(try bs(2080, 12, 1).bsMonth == .chaitra)
    #expect(try bs(2081, 1, 1).bsMonth == .baishakh)
  }

  @Test(
    "NepaliDateMonthNameTests.NepaliMonthsEnum_IntegerValueMatchesMonthNumber",
    arguments: zip(Month.allCases, 1...12))
  func monthEnumRawValue(month: Month, expected: Int) {
    #expect(month.rawValue == expected)
  }
}
