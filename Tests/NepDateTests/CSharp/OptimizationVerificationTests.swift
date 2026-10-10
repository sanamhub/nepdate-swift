import Testing

@testable import NepDate

// C# `new NepaliDate(string)` is `parse(_:)`; `SmartDateParser` is `parseLenient(_:)` (D-06).
@Suite("OptimizationVerificationTests")
struct OptimizationVerificationTests {
  @Test(
    "OptimizationVerificationTests.Constructor_AllSeparators_ParseCorrectly",
    arguments: [
      "2080/05/15", "2080-05-15", "2080.05.15", "2080_05_15", "2080\\05\\15", "2080 05 15",
      "2080।05।15", "2080|05|15",
    ])
  func constructorAllSeparatorsParseCorrectly(input: String) throws {
    #expect(try NepaliDate.parse(input) == bs(2080, 5, 15))
  }

  @Test(
    "OptimizationVerificationTests.Constructor_InvalidStrings_ThrowsException",
    arguments: ["", "invalid", "2080/05", "2080", "2080/05/15/99", "abc/def/ghi"])
  func constructorInvalidStringsThrowsException(input: String) {
    #expect(throws: NepDateError.self) { try NepaliDate.parse(input) }
  }

  // OptimizationVerificationTests.Constructor_NullString_ThrowsException: n/a, a Swift String
  // can't be null.

  @Test(
    "OptimizationVerificationTests.Constructor_WithoutLeadingZeros_ParsesCorrectly",
    arguments: [
      ("2080/5/15", [2080, 5, 15]), ("2080/05/5", [2080, 5, 5]), ("2080/1/1", [2080, 1, 1]),
    ])
  func constructorWithoutLeadingZerosParsesCorrectly(input: String, expected: [Int]) throws {
    #expect(try NepaliDate.parse(input) == bs(expected[0], expected[1], expected[2]))
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

  // C# `date - date` gives a TimeSpan; Swift gives the signed day count (D-07).
  @Test("OptimizationVerificationTests.Subtraction_SameDate_ReturnsZeroDays")
  func subtractionSameDateReturnsZeroDays() throws {
    let date = try bs(2080, 5, 15)
    #expect(date.days(until: date) == 0)
  }

  @Test("OptimizationVerificationTests.Subtraction_AdjacentDays_ReturnsOneDay")
  func subtractionAdjacentDaysReturnsOneDay() throws {
    let a = try bs(2080, 5, 15)
    let b = try bs(2080, 5, 16)
    #expect(a.days(until: b) == 1)
    #expect(b.days(until: a) == -1)
  }

  @Test("OptimizationVerificationTests.Subtraction_CrossMonth_CorrectDays")
  func subtractionCrossMonthCorrectDays() throws {
    #expect(try bs(2080, 4, 32).days(until: bs(2080, 5, 1)) == 1)
  }

  @Test("OptimizationVerificationTests.Subtraction_CrossYear_CorrectDays")
  func subtractionCrossYearCorrectDays() throws {
    #expect(try bs(2080, 12, 1).lastDayOfMonth.days(until: bs(2081, 1, 1)) == 1)
  }

  // MARK: formatting (S3)

  @Test(
    "OptimizationVerificationTests.ToString_ProducesExactFormat",
    arguments: [
      ([2080, 5, 15], "2080/05/15"), ([2080, 1, 1], "2080/01/01"), ([2080, 12, 30], "2080/12/30"),
      ([1901, 1, 1], "1901/01/01"), ([2199, 12, 30], "2199/12/30"), ([2000, 6, 9], "2000/06/09"),
      ([2100, 10, 29], "2100/10/29"),
    ])
  func toStringProducesExactFormat(date: [Int], expected: String) throws {
    #expect(try bs(date[0], date[1], date[2]).description == expected)
  }

  @Test("OptimizationVerificationTests.ToString_OutputIsExactly10Characters")
  func toStringOutputIsExactly10Characters() throws {
    let text = Array(try bs(2080, 5, 15).description)
    #expect(text.count == 10 && text[4] == "/" && text[7] == "/")
  }

  @Test("OptimizationVerificationTests.ToString_AllMonthsZeroPadded")
  func toStringAllMonthsZeroPadded() throws {
    for month in 1...12 {
      let text = try bs(2080, month, 1).description
      #expect(text.dropFirst(5).prefix(2) == (month < 10 ? "0\(month)" : "\(month)"))
    }
  }

  @Test("OptimizationVerificationTests.ToString_AllDaysZeroPadded")
  func toStringAllDaysZeroPadded() throws {
    for day in 1...(try bs(2080, 1, 1).monthLength) {
      let text = try bs(2080, 1, day).description
      #expect(text.dropFirst(8) == (day < 10 ? "0\(day)" : "\(day)"))
    }
  }

  @Test("OptimizationVerificationTests.ToString_RoundtripsWithConstructor")
  func toStringRoundtripsWithConstructor() throws {
    for year in stride(from: 1901, through: 2199, by: 50) {
      for month in 1...12 {
        let date = try bs(year, month, 1)
        #expect(NepaliDate(date.description) == date)
      }
    }
  }

  /// One `InlineData` row of the `ToString(format, separator, leadingZeros)` theories.
  struct ShortRow: Sendable {
    let order: DateOrder
    let separator: Separator
    let pad: Bool
    let expected: String
  }

  @Test(
    "OptimizationVerificationTests.ToString_WithFormatAndSeparator_ProducesCorrectOutput",
    arguments: [
      ShortRow(order: .ymd, separator: .slash, pad: true, expected: "2080/05/15"),
      ShortRow(order: .ymd, separator: .dash, pad: true, expected: "2080-05-15"),
      ShortRow(order: .ymd, separator: .dot, pad: true, expected: "2080.05.15"),
      ShortRow(order: .ymd, separator: .underscore, pad: true, expected: "2080_05_15"),
      ShortRow(order: .ymd, separator: .space, pad: true, expected: "2080 05 15"),
      ShortRow(order: .ymd, separator: .backslash, pad: true, expected: "2080\\05\\15"),
      ShortRow(order: .dmy, separator: .slash, pad: true, expected: "15/05/2080"),
      ShortRow(order: .dmy, separator: .dash, pad: true, expected: "15-05-2080"),
      ShortRow(order: .mdy, separator: .slash, pad: true, expected: "05/15/2080"),
      ShortRow(order: .ydm, separator: .slash, pad: true, expected: "2080/15/05"),
      ShortRow(order: .myd, separator: .slash, pad: true, expected: "05/2080/15"),
      ShortRow(order: .dym, separator: .slash, pad: true, expected: "15/2080/05"),
    ])
  func toStringWithFormatAndSeparator(row: ShortRow) throws {
    let date = try bs(2080, 5, 15)
    #expect(date.short(order: row.order, separator: row.separator, pad: row.pad) == row.expected)
  }

  @Test(
    "OptimizationVerificationTests.ToString_WithoutLeadingZeros_ProducesCorrectOutput",
    arguments: [
      ShortRow(order: .ymd, separator: .slash, pad: false, expected: "2080/5/15"),
      ShortRow(order: .dmy, separator: .dash, pad: false, expected: "15-5-2080"),
      ShortRow(order: .mdy, separator: .dot, pad: false, expected: "5.15.2080"),
    ])
  func toStringWithoutLeadingZeros(row: ShortRow) throws {
    let date = try bs(2080, 5, 15)
    #expect(date.short(order: row.order, separator: row.separator, pad: row.pad) == row.expected)
  }

  @Test("OptimizationVerificationTests.ToUnicodeString_DefaultFormat_ConvertsAllDigits")
  func toUnicodeStringDefaultFormat() throws {
    #expect(try bs(2080, 5, 15).short(lang: .nepali) == "२०८०/०५/१५")
  }

  @Test("OptimizationVerificationTests.ToUnicodeString_EachDigitConvertsCorrectly")
  func toUnicodeStringEachDigit() throws {
    let text = try bs(1902, 3, 4).short(lang: .nepali)
    #expect(text == "१९०२/०३/०४")
    for digit in ["१", "९", "०", "२", "३", "४"] { #expect(text.contains(digit)) }
  }

  @Test("OptimizationVerificationTests.ToUnicodeString_SeparatorsPreserved")
  func toUnicodeStringSeparatorsPreserved() throws {
    let text = try bs(2080, 5, 15).short(separator: .dash, lang: .nepali)
    #expect(text.contains("-") && !text.contains("/"))
  }

  @Test("OptimizationVerificationTests.ToUnicodeString_SameLengthAsToString")
  func toUnicodeStringSameLength() throws {
    for year in stride(from: 1901, through: 2199, by: 100) {
      let date = try bs(year, 6, 15)
      #expect(date.description.count == date.short(lang: .nepali).count)
    }
  }

  // MARK: lenient parsing (S3, D-06)

  @Test(
    "OptimizationVerificationTests.SmartDateParser_NepaliDigits_ParseCorrectly",
    arguments: ["२०८०/०५/१५", "२०८०-०५-१५"])
  func smartDateParserNepaliDigits(input: String) throws {
    #expect(try lenient(input) == bs(2080, 5, 15))
  }

  @Test("OptimizationVerificationTests.SmartDateParser_PureEnglishDigits_NoConversionNeeded")
  func smartDateParserPureEnglishDigits() throws {
    #expect(try lenient("2080/05/15") == bs(2080, 5, 15))
  }

  @Test("OptimizationVerificationTests.SmartDateParser_MixedNepaliEnglishDigits_ParseCorrectly")
  func smartDateParserMixedDigits() throws {
    #expect(try lenient("2०८0/0५/१5") == bs(2080, 5, 15))
  }

  @Test(
    "OptimizationVerificationTests.SmartDateParser_WithIndicators_RemovesAndParsesCorrectly",
    arguments: [
      "2080/05/15 B.S.", "2080/05/15 BS", "2080/05/15 V.S.", "2080/05/15 VS", "2080/05/15 bs",
      "2080/05/15 v.s.",
    ])
  func smartDateParserWithIndicators(input: String) throws {
    #expect(try lenient(input) == bs(2080, 5, 15))
  }

  @Test("OptimizationVerificationTests.SmartDateParser_WithNepaliKeywords_RemovesAndParses")
  func smartDateParserWithNepaliKeywords() throws {
    #expect(try lenient("15 Shrawan 2080 गते") == bs(2080, 4, 15))
  }

  @Test("OptimizationVerificationTests.SmartDateParser_WithExtraSpaces_ParsesCorrectly")
  func smartDateParserWithExtraSpaces() throws {
    #expect(try lenient("  2080 / 05 / 15  ") == bs(2080, 5, 15))
  }

  @Test(
    "OptimizationVerificationTests.SmartDateParser_AllMonthNames_ParseCorrectly",
    arguments: zip(
      [
        "15 Baisakh 2080", "15 Jestha 2080", "15 Asar 2080", "15 Shrawan 2080", "15 Bhadra 2080",
        "15 Ashwin 2080", "15 Kartik 2080", "15 Mangsir 2080", "15 Poush 2080", "15 Magh 2080",
        "15 Falgun 2080", "15 Chaitra 2080",
      ], 1...12))
  func smartDateParserAllMonthNames(input: String, month: Int) throws {
    #expect(try lenient(input) == bs(2080, month, 15))
  }

  @Test(
    "OptimizationVerificationTests.SmartDateParser_MonthNameDifferentPositions_ParsesCorrectly",
    arguments: ["Baisakh 15, 2080", "2080 Baisakh 15"])
  func smartDateParserMonthNamePositions(input: String) throws {
    #expect(try lenient(input) == bs(2080, 1, 15))
  }

  @Test(
    "OptimizationVerificationTests.SmartDateParser_NepaliUnicodeMonthNames_ParseCorrectly",
    arguments: zip(["15 वैशाख 2080", "15 जेष्ठ 2080", "15 असार 2080", "15 श्रावण 2080"], 1...4))
  func smartDateParserNepaliMonthNames(input: String, month: Int) throws {
    #expect(try lenient(input) == bs(2080, month, 15))
  }

  // D-06: two-digit years are never expanded.
  @Test("OptimizationVerificationTests.SmartDateParser_TwoDigitYear_AdjustedTo2000s")
  func smartDateParserTwoDigitYear() {
    expectError(.ambiguous) { _ = try NepaliDate.parseLenient("80/05/15") }
  }

  @Test("OptimizationVerificationTests.SmartDateParser_InvalidInput_ThrowsFormatException")
  func smartDateParserInvalidInput() {
    expectError(.unrecognized) { _ = try NepaliDate.parseLenient("not a date") }
  }

  // OptimizationVerificationTests.SmartDateParser_NullInput_ThrowsException: n/a, a Swift String
  // can't be null.

  @Test("OptimizationVerificationTests.SmartDateParser_EmptyInput_ThrowsException")
  func smartDateParserEmptyInput() {
    expectError(.unrecognized) { _ = try NepaliDate.parseLenient("") }
  }

  @Test("OptimizationVerificationTests.SmartDateParser_WhitespaceInput_ThrowsException")
  func smartDateParserWhitespaceInput() {
    expectError(.unrecognized) { _ = try NepaliDate.parseLenient("   ") }
  }

  @Test("OptimizationVerificationTests.SmartDateParser_TryParse_ValidInput_ReturnsTrue")
  func smartDateParserTryParseValid() {
    #expect((try? NepaliDate.parseLenient("2080/05/15"))?.year == 2080)
  }

  @Test("OptimizationVerificationTests.SmartDateParser_TryParse_InvalidInput_ReturnsFalse")
  func smartDateParserTryParseInvalid() {
    #expect((try? NepaliDate.parseLenient("garbage")) == nil)
  }

  // OptimizationVerificationTests.SmartDateParser_TryParse_NullInput_ReturnsFalse: n/a, a Swift
  // String can't be null.

  @Test("OptimizationVerificationTests.ToString_EveryMonthFirstDay_RoundtripsViaConstructor")
  func toStringEveryMonthFirstDayRoundtrips() throws {
    var failures = 0
    for year in 1901...2199 {
      for month in 1...12 {
        let date = try bs(year, month, 1)
        if NepaliDate(date.description) != date { failures += 1 }
      }
    }
    #expect(failures == 0)
  }

  @Test("OptimizationVerificationTests.UnicodeConversion_AllDigits_RoundtripCorrectly")
  func unicodeConversionRoundtrip() throws {
    for year in 2070...2090 {
      for month in 1...12 {
        let date = try bs(year, month, 15)
        #expect(try lenient(date.short(lang: .nepali)) == date)
      }
    }
  }

  @Test("OptimizationVerificationTests.ToLongDateString_Default_ContainsMonthNameAndDay")
  func toLongDateStringDefault() throws {
    let text = try bs(2080, 5, 15).long()
    #expect(text.contains("15") && text.contains("2080") && text.contains(","))
  }

  @Test("OptimizationVerificationTests.ToLongDateString_WithDayName_ContainsDayOfWeek")
  func toLongDateStringWithDayName() throws {
    let date = try bs(2080, 5, 15)
    #expect(date.long(weekday: true).contains(date.weekday.name()))
  }

  @Test("OptimizationVerificationTests.ToLongDateString_WithoutYear_DoesNotContainYear")
  func toLongDateStringWithoutYear() throws {
    #expect(!(try bs(2080, 5, 15).long(year: false).contains("2080")))
  }
}
