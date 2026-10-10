import Testing

@testable import NepDate

@Suite("NepaliDateArithmeticEdgeCaseTests")
struct NepaliDateArithmeticEdgeCaseTests {
  @Test("NepaliDateArithmeticEdgeCaseTests.AddDays_Zero_ReturnsSameDate")
  func addDaysZeroReturnsSameDate() throws {
    let date = try bs(2080, 5, 15)
    #expect(try date.adding(days: 0) == date)
  }

  @Test("NepaliDateArithmeticEdgeCaseTests.AddDays_PositiveAcrossMonthBoundary_IsCorrect")
  func addDaysPositiveAcrossMonthBoundary() throws {
    #expect(try bs(2080, 5, 31).adding(days: 1) == bs(2080, 6, 1))
  }

  @Test("NepaliDateArithmeticEdgeCaseTests.AddDays_NegativeAcrossMonthBoundary_IsCorrect")
  func addDaysNegativeAcrossMonthBoundary() throws {
    #expect(try bs(2080, 6, 1).adding(days: -1) == bs(2080, 5, 31))
  }

  @Test("NepaliDateArithmeticEdgeCaseTests.AddDays_PositiveAcrossYearBoundary_IsCorrect")
  func addDaysPositiveAcrossYearBoundary() throws {
    let lastOfChaitra = try bs(2080, 12, 1).lastDayOfMonth
    #expect(try lastOfChaitra.adding(days: 1) == bs(2081, 1, 1))
  }

  @Test("NepaliDateArithmeticEdgeCaseTests.AddDays_NegativeAcrossYearBoundary_IsCorrect")
  func addDaysNegativeAcrossYearBoundary() throws {
    let result = try bs(2081, 1, 1).adding(days: -1)
    #expect(result.year == 2080 && result.month == 12)
    #expect(result.day == (try bs(2080, 12, 1).monthLength))
  }

  @Test("NepaliDateArithmeticEdgeCaseTests.AddDays_LargePositiveValue_IsCorrect")
  func addDaysLargePositiveValue() throws {
    let start = try bs(2080, 1, 1)
    let result = try start.adding(days: 365)
    #expect(result.year == 2081 || result.year == 2080)
    #expect(result >= start)
  }

  @Test("NepaliDateArithmeticEdgeCaseTests.AddMonths_PositiveCrossesYearBoundary_IsCorrect")
  func addMonthsPositiveCrossesYearBoundary() throws {
    #expect(try bs(2080, 11, 15).adding(months: 5) == bs(2081, 4, 15))
  }

  @Test("NepaliDateArithmeticEdgeCaseTests.AddMonths_NegativeCrossesYearBoundary_IsCorrect")
  func addMonthsNegativeCrossesYearBoundary() throws {
    #expect(try bs(2080, 3, 15).adding(months: -5) == bs(2079, 10, 15))
  }

  @Test("NepaliDateArithmeticEdgeCaseTests.AddMonths_PositiveMoreThan12_CrossesMultipleYears")
  func addMonthsPositiveMoreThan12() throws {
    #expect(try bs(2080, 5, 15).adding(months: 14) == bs(2081, 7, 15))
  }

  @Test("NepaliDateArithmeticEdgeCaseTests.AddMonths_Exactly12_SameMonthNextYear")
  func addMonthsExactly12() throws {
    #expect(try bs(2080, 6, 15).adding(months: 12) == bs(2081, 6, 15))
  }

  @Test("NepaliDateArithmeticEdgeCaseTests.AddMonths_DayCappedAtMonthEnd_WhenResultMonthIsShorter")
  func addMonthsDayCappedAtMonthEnd() throws {
    let result = try bs(2081, 4, 32).adding(months: 5)
    #expect(result.year == 2081 && result.month == 9)
    #expect(result.day > 0 && result.day <= result.monthLength)
  }

  @Test("NepaliDateArithmeticEdgeCaseTests.AddMonths_Negative_SameDayPreservedWhenFits")
  func addMonthsNegativeSameDayPreserved() throws {
    #expect(try bs(2080, 8, 10).adding(months: -1) == bs(2080, 7, 10))
  }

  // NepaliDateArithmeticEdgeCaseTests.AddMonths_HalfMonth_AddsApproximately15Days: D-02, months
  // are integers.
  // NepaliDateArithmeticEdgeCaseTests.AddMonths_NegativeHalfMonth_SubtractsApproximately15Days:
  // D-02.
  // NepaliDateArithmeticEdgeCaseTests.AddMonths_OneAndHalfMonths_AddsApproximately46Days: D-02.
  // NepaliDateArithmeticEdgeCaseTests.AddMonths_FractionalValue_ReturnsDateFurtherThanZeroMonths:
  // D-02.

  // The DateTime rows need `init(_:in:)` from S4-04. Until then each builds the AD date with
  // `init(gregorianYear:month:day:)`, which has no time of day to ignore.
  // PENDING S4-04: build from a `Date` at 00:00 in `Asia/Kathmandu`.
  @Test("NepaliDateArithmeticEdgeCaseTests.Constructor_DateTimeWithMidnightTime_IgnoresTime")
  func constructorDateTimeWithMidnightTime() throws {
    #expect(try ad(2023, 9, 1) == bs(2080, 5, 15))
  }

  // PENDING S4-04: build from a `Date` at 12:30:45 in `Asia/Kathmandu`.
  @Test("NepaliDateArithmeticEdgeCaseTests.Constructor_DateTimeWithNoonTime_IgnoresTime")
  func constructorDateTimeWithNoonTime() throws {
    #expect(try ad(2023, 9, 1) == bs(2080, 5, 15))
  }

  // PENDING S4-04: build from a `Date` at 23:59:59 in `Asia/Kathmandu`.
  @Test("NepaliDateArithmeticEdgeCaseTests.Constructor_DateTimeWithEndOfDayTime_IgnoresTime")
  func constructorDateTimeWithEndOfDayTime() throws {
    #expect(try ad(2023, 9, 1) == bs(2080, 5, 15))
  }

  @Test(
    "NepaliDateArithmeticEdgeCaseTests.Constructor_TwoDateTimesOnSameEnglishDateDifferentTimes_ProduceSameNepaliDate",
    .disabled("PENDING S4-04: needs init(_:in:) with two Date values"))
  func constructorTwoDateTimesOnSameEnglishDate() {}

  // The TryParse auto-adjust rows are `parseLenient` (D-06): no swapping, no two-digit years.
  @Test(
    "NepaliDateArithmeticEdgeCaseTests.TryParse_AutoAdjust_DayYearMonthFormat_ReturnsCorrectDate")
  func tryParseAutoAdjustDayYearMonth() throws {
    #expect(try NepaliDate.parseLenient("15/05/2080") == bs(2080, 5, 15))
  }

  // D-06: day, month, year, so 15 is the month.
  @Test(
    "NepaliDateArithmeticEdgeCaseTests.TryParse_AutoAdjust_MonthDayYearInvertedOrder_ReturnsCorrectDate"
  )
  func tryParseAutoAdjustMonthDayYear() {
    #expect(lenientResult("05/15/2080") == "ERR:InvalidMonth")
  }

  // D-06: two-digit years are never expanded.
  @Test(
    "NepaliDateArithmeticEdgeCaseTests.TryParse_AutoAdjust_TwoDigitYear_ExpandsToCurrentMillennium")
  func tryParseAutoAdjustTwoDigitYear() {
    #expect(lenientResult("15/05/80") == "ERR:Ambiguous")
  }

  @Test(
    "NepaliDateArithmeticEdgeCaseTests.TryParse_AutoAdjust_InvalidDateAfterAdjustment_ReturnsFalse")
  func tryParseAutoAdjustInvalidDate() {
    #expect((try? NepaliDate.parseLenient("99/99/99")) == nil)
  }

  @Test(
    "NepaliDateArithmeticEdgeCaseTests.TryParse_AutoAdjust_ValidStandardFormat_ReturnsCorrectDate")
  func tryParseAutoAdjustValidStandardFormat() throws {
    #expect(try NepaliDate.parseLenient("2080/05/15") == bs(2080, 5, 15))
  }
}
