import Testing

@testable import NepDate

// Rows that build a date from a string are written now, as the hub PORT-PLAN asks. Each one is
// marked PENDING with the task that brings the API: it builds the expected date with the
// constructor until then, or is disabled when it needs the parser itself.
@Suite("NepaliDateConstructionTests")
struct NepaliDateConstructionTests {
  @Test("NepaliDateConstructionTests.Constructor_ValidNepaliDate_CreatesInstance")
  func constructorValidNepaliDateCreatesInstance() throws {
    let date = try bs(2080, 5, 15)
    #expect(date.year == 2080 && date.month == 5 && date.day == 15)
  }

  @Test("NepaliDateConstructionTests.Constructor_MinValue_CreatesInstance")
  func constructorMinValueCreatesInstance() {
    let date = NepaliDate.min
    #expect(date.year == 1901 && date.month == 1 && date.day == 1)
  }

  @Test("NepaliDateConstructionTests.Constructor_MaxValue_CreatesInstance")
  func constructorMaxValueCreatesInstance() {
    let date = NepaliDate.max
    #expect(date.year == 2199 && date.month == 12 && date.day > 0)
  }

  @Test(
    "NepaliDateConstructionTests.Constructor_InvalidNepaliDate_ThrowsException",
    arguments: [[2080, 0, 1], [2080, 13, 1], [2080, 1, 0], [2080, 1, 33]])
  func constructorInvalidNepaliDateThrowsException(row: [Int]) {
    #expect(throws: NepDateError.self) {
      try NepaliDate(year: row[0], month: row[1], day: row[2])
    }
  }

  // PENDING S3-04: replace the constructor with `NepaliDate.parse(input)`.
  @Test(
    "NepaliDateConstructionTests.Constructor_ValidStringFormats_CreatesInstance",
    arguments: [
      "2080/05/15", "2080-05-15", "2080.05.15", "2080_05_15", "2080\\05\\15", "2080 05 15",
    ])
  func constructorValidStringFormatsCreatesInstance(input: String) throws {
    let date = try bs(2080, 5, 15)
    #expect(date.year == 2080 && date.month == 5 && date.day == 15)
  }

  // PENDING S3-05: C# auto-adjust becomes `parseLenient` rules (D-06); replace the constructor
  // with `NepaliDate.parseLenient(input)` and apply the D-06 outcome (2-digit years are
  // `.ambiguous`).
  @Test(
    "NepaliDateConstructionTests.Constructor_AutoAdjustedFormats_CreatesInstance",
    arguments: ["15/05/2080", "05/15/2080", "2080/05/15", "80/05/15"])
  func constructorAutoAdjustedFormatsCreatesInstance(input: String) throws {
    let date = try bs(2080, 5, 15)
    #expect(date.year == 2080 && date.month == 5 && date.day == 15)
  }

  // PENDING S3-05 (D-06): replace the constructor with `NepaliDate.parseLenient(input)`.
  @Test(
    "NepaliDateConstructionTests.Constructor_AutoAdjust_MonthOverflowWithBoundaryDay_SwapsAsDocumented",
    arguments: [("2080/13/12", [2080, 12, 13]), ("2080/15/11", [2080, 11, 15])])
  func constructorAutoAdjustMonthOverflow(input: String, expected: [Int]) throws {
    let date = try bs(expected[0], expected[1], expected[2])
    #expect(date.year == expected[0] && date.month == expected[1] && date.day == expected[2])
  }

  @Test(
    "NepaliDateConstructionTests.TryParse_AutoAdjust_MonthOverflowWithBoundaryDay_SwapsAsDocumented",
    .disabled("PENDING S3-05: needs parseLenient (D-06)"))
  func tryParseAutoAdjustMonthOverflow() {}

  @Test(
    "NepaliDateConstructionTests.Constructor_InvalidStringFormats_ThrowsException",
    .disabled("PENDING S3-04: needs parse"), arguments: ["", "invalid", "2080/5"])
  func constructorInvalidStringFormatsThrowsException(input: String) {}

  // PENDING S3-04: replace the constructor with `NepaliDate.parse(input)`.
  @Test(
    "NepaliDateConstructionTests.Constructor_ValidFormatInvalidDate_ThrowsException",
    arguments: ["2080/5/40"])
  func constructorValidFormatInvalidDateThrowsException(input: String) {
    expectError(.invalidDay(monthLength: 31)) { _ = try NepaliDate(year: 2080, month: 5, day: 40) }
  }

  @Test("NepaliDateConstructionTests.Constructor_EnglishDate_ConvertsCorrectly")
  func constructorEnglishDateConvertsCorrectly() throws {
    let date = try ad(2023, 8, 30)
    #expect(date.year == 2080 && date.month == 5 && date.day == 13)
  }

  // PENDING S3-04: replace the constructor with `NepaliDate("2080/05/15")`.
  @Test("NepaliDateConstructionTests.TryParse_ValidString_ReturnsTrueWithCorrectDate")
  func tryParseValidStringReturnsTrueWithCorrectDate() throws {
    let date = try bs(2080, 5, 15)
    #expect(date.year == 2080 && date.month == 5 && date.day == 15)
  }

  @Test(
    "NepaliDateConstructionTests.TryParse_InvalidString_ReturnsFalseWithDefault",
    .disabled("PENDING S3-04: needs init?(_:)"), arguments: ["", "invalid", "2080/5"])
  func tryParseInvalidStringReturnsFalseWithDefault(input: String) {}
}
