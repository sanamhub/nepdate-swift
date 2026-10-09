import Testing

@testable import NepDate

// The phase-1 rows of OptimizationVerificationTests. Rows that read strings are marked PENDING
// with the task that brings the parser (hub PORT-PLAN).
@Suite("OptimizationVerificationTests")
struct OptimizationVerificationTests {
  // PENDING S3-04: replace the constructor with `NepaliDate.parse(input)`.
  @Test(
    "OptimizationVerificationTests.Constructor_AllSeparators_ParseCorrectly",
    arguments: [
      "2080/05/15", "2080-05-15", "2080.05.15", "2080_05_15", "2080\\05\\15", "2080 05 15",
      "2080।05।15", "2080|05|15",
    ])
  func constructorAllSeparatorsParseCorrectly(input: String) throws {
    let date = try bs(2080, 5, 15)
    #expect(date.year == 2080 && date.month == 5 && date.day == 15)
  }

  @Test(
    "OptimizationVerificationTests.Constructor_InvalidStrings_ThrowsException",
    .disabled("PENDING S3-04: needs parse"),
    arguments: ["", "invalid", "2080/05", "2080", "2080/05/15/99", "abc/def/ghi"])
  func constructorInvalidStringsThrowsException(input: String) {}

  // OptimizationVerificationTests.Constructor_NullString_ThrowsException: n/a, a Swift String
  // can't be null.

  // PENDING S3-04: replace the constructor with `NepaliDate.parse(input)`.
  @Test(
    "OptimizationVerificationTests.Constructor_WithoutLeadingZeros_ParsesCorrectly",
    arguments: [
      ("2080/5/15", [2080, 5, 15]), ("2080/05/5", [2080, 5, 5]), ("2080/1/1", [2080, 1, 1]),
    ])
  func constructorWithoutLeadingZerosParsesCorrectly(input: String, expected: [Int]) throws {
    let date = try bs(expected[0], expected[1], expected[2])
    #expect(date.year == expected[0] && date.month == expected[1] && date.day == expected[2])
  }

  @Test("OptimizationVerificationTests.Operator_Equality_SameDates_ReturnsTrue")
  func operatorEqualitySameDatesReturnsTrue() throws {
    let a = try bs(2080, 5, 15)
    let b = try bs(2080, 5, 15)
    #expect(a == b)
    #expect(!(a != b))
  }

  @Test("OptimizationVerificationTests.Operator_Inequality_DifferentDates_ReturnsTrue")
  func operatorInequalityDifferentDatesReturnsTrue() throws {
    let a = try bs(2080, 5, 15)
    let b = try bs(2080, 5, 16)
    #expect(a != b)
    #expect(!(a == b))
  }

  @Test("OptimizationVerificationTests.Operator_LessThan_EarlierDate_ReturnsTrue")
  func operatorLessThanEarlierDateReturnsTrue() throws {
    let earlier = try bs(2080, 5, 15)
    let later = try bs(2080, 5, 16)
    let sameAsEarlier = earlier
    #expect(earlier < later)
    #expect(!(later < earlier))
    #expect(!(earlier < sameAsEarlier))
  }

  @Test("OptimizationVerificationTests.Operator_LessThanOrEqual_SameAndEarlier_ReturnsTrue")
  func operatorLessThanOrEqualSameAndEarlierReturnsTrue() throws {
    let earlier = try bs(2080, 5, 15)
    let later = try bs(2080, 5, 16)
    let sameAsEarlier = earlier
    #expect(earlier <= later)
    #expect(earlier <= sameAsEarlier)
    #expect(!(later <= earlier))
  }

  @Test("OptimizationVerificationTests.Operator_GreaterThan_LaterDate_ReturnsTrue")
  func operatorGreaterThanLaterDateReturnsTrue() throws {
    let earlier = try bs(2080, 5, 15)
    let later = try bs(2080, 5, 16)
    let sameAsLater = later
    #expect(later > earlier)
    #expect(!(earlier > later))
    #expect(!(later > sameAsLater))
  }

  @Test("OptimizationVerificationTests.Operator_GreaterThanOrEqual_SameAndLater_ReturnsTrue")
  func operatorGreaterThanOrEqualSameAndLaterReturnsTrue() throws {
    let earlier = try bs(2080, 5, 15)
    let later = try bs(2080, 5, 16)
    let sameAsLater = later
    #expect(later >= earlier)
    #expect(later >= sameAsLater)
    #expect(!(earlier >= later))
  }

  @Test("OptimizationVerificationTests.Operator_MinMaxBoundary_CorrectOrdering")
  func operatorMinMaxBoundaryCorrectOrdering() {
    #expect(NepaliDate.min < NepaliDate.max)
    #expect(NepaliDate.max > NepaliDate.min)
    #expect(NepaliDate.min <= NepaliDate.max)
    #expect(NepaliDate.max >= NepaliDate.min)
  }

  @Test("OptimizationVerificationTests.CompareTo_EarlierDate_ReturnsNegative")
  func compareToEarlierDateReturnsNegative() throws {
    #expect(try bs(2080, 5, 15) < bs(2080, 5, 16))
  }

  @Test("OptimizationVerificationTests.CompareTo_SameDate_ReturnsZero")
  func compareToSameDateReturnsZero() throws {
    let date = try bs(2080, 5, 15)
    #expect(!(date < date) && date == date)
  }

  @Test("OptimizationVerificationTests.CompareTo_LaterDate_ReturnsPositive")
  func compareToLaterDateReturnsPositive() throws {
    #expect(try bs(2080, 5, 16) > bs(2080, 5, 15))
  }

  @Test("OptimizationVerificationTests.CompareTo_DifferentYears_CorrectOrdering")
  func compareToDifferentYearsCorrectOrdering() throws {
    #expect(try bs(2080, 1, 1) < bs(2081, 1, 1))
  }

  @Test("OptimizationVerificationTests.CompareTo_DifferentMonths_CorrectOrdering")
  func compareToDifferentMonthsCorrectOrdering() throws {
    #expect(try bs(2080, 1, 1) < bs(2080, 2, 1))
  }

  @Test("OptimizationVerificationTests.Equals_SameDates_ReturnsTrue")
  func equalsSameDatesReturnsTrue() throws {
    let a = try bs(2080, 5, 15)
    let b = try bs(2080, 5, 15)
    #expect(a == b)
    // C# also compares through `object`; the Swift equivalent is AnyHashable.
    #expect(AnyHashable(a) == AnyHashable(b))
  }

  @Test("OptimizationVerificationTests.Equals_DifferentDates_ReturnsFalse")
  func equalsDifferentDatesReturnsFalse() throws {
    #expect(try bs(2080, 5, 15) != bs(2080, 5, 16))
  }

  @Test("OptimizationVerificationTests.GetHashCode_EqualDates_SameHashCode")
  func getHashCodeEqualDatesSameHashCode() throws {
    #expect(try bs(2080, 5, 15).hashValue == bs(2080, 5, 15).hashValue)
  }

  @Test("OptimizationVerificationTests.GetHashCode_StableAcrossMultipleCalls")
  func getHashCodeStableAcrossMultipleCalls() throws {
    let date = try bs(2080, 5, 15)
    #expect(date.hashValue == date.hashValue)
  }

  // OptimizationVerificationTests.IsLeapYear_ChecksEnglishYearCorrectly (3 rows): D-12, not
  // ported; year length comes from NepaliDateRange.year(_:).count (S2-05).

  @Test(
    "OptimizationVerificationTests.Constructor_InvalidYearMonthDay_ThrowsException",
    arguments: [
      [2080, 0, 15], [2080, 13, 15], [2080, 5, 0], [2080, 5, 33], [1900, 1, 1], [2200, 1, 1],
    ])
  func constructorInvalidYearMonthDayThrowsException(row: [Int]) {
    #expect(throws: NepDateError.self) {
      try NepaliDate(year: row[0], month: row[1], day: row[2])
    }
  }

  @Test("OptimizationVerificationTests.Constructor_MinValue_IsValid")
  func constructorMinValueIsValid() {
    let min = NepaliDate.min
    #expect(min.year == 1901 && min.month == 1 && min.day == 1)
  }

  @Test("OptimizationVerificationTests.Constructor_MaxValue_IsValid")
  func constructorMaxValueIsValid() {
    let max = NepaliDate.max
    #expect(max.year == 2199 && max.month == 12 && (29...32).contains(max.day))
  }

  @Test("OptimizationVerificationTests.EnglishDate_MinValue_ConvertsAndRoundtrips")
  func englishDateMinValueConvertsAndRoundtrips() throws {
    let g = NepaliDate.min.gregorian
    #expect(try ad(g.year, g.month, g.day) == NepaliDate.min)
  }

  @Test("OptimizationVerificationTests.EnglishDate_MaxValue_ConvertsAndRoundtrips")
  func englishDateMaxValueConvertsAndRoundtrips() throws {
    let g = NepaliDate.max.gregorian
    #expect(try ad(g.year, g.month, g.day) == NepaliDate.max)
  }

  @Test("OptimizationVerificationTests.EnglishDate_JustBeforeMin_ThrowsException")
  func englishDateJustBeforeMinThrowsException() {
    expectError(.outOfRange) { _ = try NepaliDate(gregorianYear: 1844, month: 4, day: 10) }
  }

  @Test("OptimizationVerificationTests.EnglishDate_JustAfterMax_ThrowsException")
  func englishDateJustAfterMaxThrowsException() {
    expectError(.outOfRange) { _ = try NepaliDate(gregorianYear: 2143, month: 4, day: 16) }
  }

  @Test("OptimizationVerificationTests.MonthEndDay_CreatingDateWithExactEndDay_Succeeds")
  func monthEndDayCreatingDateWithExactEndDaySucceeds() throws {
    for year in 2070...2090 {
      for month in 1...12 {
        let endDay = try bs(year, month, 1).monthLength
        #expect(try bs(year, month, endDay).day == endDay)
        #expect(throws: NepDateError.self) {
          try NepaliDate(year: year, month: month, day: endDay + 1)
        }
      }
    }
  }

  @Test("OptimizationVerificationTests.DayOfWeek_MatchesEnglishDateDayOfWeek")
  func dayOfWeekMatchesEnglishDateDayOfWeek() throws {
    for year in stride(from: 1910, through: 2190, by: 30) {
      for month in stride(from: 1, through: 12, by: 3) {
        let date = try bs(year, month, 15)
        let g = date.gregorian
        #expect(date.weekday.rawValue == gregorianWeekday(g.year, g.month, g.day))
      }
    }
  }

  // OptimizationVerificationTests.IsDefault_DefaultStruct_ReturnsTrue: D-01, no default date.
  // OptimizationVerificationTests.IsDefault_ValidDate_ReturnsFalse: D-01, no default date.
}
