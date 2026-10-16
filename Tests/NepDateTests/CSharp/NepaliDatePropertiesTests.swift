import Testing

#if canImport(Foundation)
  import Foundation
#endif

@testable import NepDate

@Suite("NepaliDatePropertiesTests")
struct NepaliDatePropertiesTests {
  @Test("NepaliDatePropertiesTests.EnglishDate_Conversion_ReturnsCorrectDate")
  func englishDateConversionReturnsCorrectDate() throws {
    let g = try bs(2080, 5, 15).gregorian
    #expect(g.year == 2023 && g.month == 9 && g.day == 1)
  }

  @Test("NepaliDatePropertiesTests.DayOfWeek_ReturnsCorrectValue")
  func dayOfWeekReturnsCorrectValue() throws {
    #expect(try bs(2080, 5, 15).weekday == .friday)
  }

  @Test("NepaliDatePropertiesTests.MonthEndDay_ReturnsCorrectValue")
  func monthEndDayReturnsCorrectValue() throws {
    #expect(try bs(2080, 5, 15).monthLength == 31)
  }

  @Test("NepaliDatePropertiesTests.MonthName_ReturnsCorrectEnum")
  func monthNameReturnsCorrectEnum() throws {
    #expect(try bs(2080, 5, 15).bsMonth == .bhadra)
  }

  #if canImport(Foundation)
  @Test("NepaliDatePropertiesTests.Today_ReturnsCurrentNepaliDate")
  func todayReturnsCurrentNepaliDate() throws {
    let utcZone = try zone("UTC")
    let before = try NepaliDate(Date(), in: utcZone)
    let today = NepaliDate.today(in: utcZone)
    let after = try NepaliDate(Date(), in: utcZone)
    #expect(before <= today && today <= after)
  }
  #endif

  @Test("NepaliDatePropertiesTests.DayOfYear_FirstDayOfYear_Returns1")
  func dayOfYearFirstDayOfYearReturns1() throws {
    #expect(try bs(2080, 1, 1).dayOfYear == 1)
  }

  @Test("NepaliDatePropertiesTests.DayOfYear_FirstDayOfMonth4_EqualsSum_Of_Months1To3_Plus1")
  func dayOfYearFirstDayOfMonth4() throws {
    let expected =
      try bs(2080, 1, 1).monthLength + bs(2080, 2, 1).monthLength + bs(2080, 3, 1).monthLength + 1
    #expect(try bs(2080, 4, 1).dayOfYear == expected)
  }

  // NepaliDatePropertiesTests.Equals_NullObject_ReturnsFalse: n/a, no null in Swift.
  // NepaliDatePropertiesTests.Equals_DifferentType_ReturnsFalse: n/a, `==` only accepts another
  // NepaliDate.
}
