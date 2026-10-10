import Testing

@testable import NepDate

/// `parseLenient` as `parse.tsv` writes results, for rows whose outcome D-06 changes.
func lenientResult(_ text: String) -> String {
  parseResult { () throws(NepDateError) -> NepaliDate in try NepaliDate.parseLenient(text) }
}

// C# `new NepaliDate(string)` is the strict `parse(_:)`; its auto-adjust overloads become
// `parseLenient(_:)` with the explicit rules of D-06 (no swapping, no two-digit years).
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

  @Test(
    "NepaliDateConstructionTests.Constructor_ValidStringFormats_CreatesInstance",
    arguments: [
      "2080/05/15", "2080-05-15", "2080.05.15", "2080_05_15", "2080\\05\\15", "2080 05 15",
    ])
  func constructorValidStringFormatsCreatesInstance(input: String) throws {
    #expect(try NepaliDate.parse(input) == bs(2080, 5, 15))
  }

  // D-06: `05/15/2080` reads as day 5, month 15, and `80/05/15` has no 4-digit year.
  @Test(
    "NepaliDateConstructionTests.Constructor_AutoAdjustedFormats_CreatesInstance",
    arguments: [
      ("15/05/2080", "2080-05-15"), ("05/15/2080", "ERR:InvalidMonth"),
      ("2080/05/15", "2080-05-15"), ("80/05/15", "ERR:Ambiguous"),
    ])
  func constructorAutoAdjustedFormatsCreatesInstance(input: String, expected: String) {
    #expect(lenientResult(input) == expected)
  }

  // D-06: month and day are never swapped, so a month over 12 is invalid.
  @Test(
    "NepaliDateConstructionTests.Constructor_AutoAdjust_MonthOverflowWithBoundaryDay_SwapsAsDocumented",
    arguments: ["2080/13/12", "2080/15/11"])
  func constructorAutoAdjustMonthOverflow(input: String) {
    #expect(lenientResult(input) == "ERR:InvalidMonth")
  }

  // D-06, as the row above.
  @Test(
    "NepaliDateConstructionTests.TryParse_AutoAdjust_MonthOverflowWithBoundaryDay_SwapsAsDocumented"
  )
  func tryParseAutoAdjustMonthOverflow() {
    #expect((try? NepaliDate.parseLenient("2080/13/12")) == nil)
  }

  @Test(
    "NepaliDateConstructionTests.Constructor_InvalidStringFormats_ThrowsException",
    arguments: [
      ("", NepDateError.Kind.wrongGroupCount), ("invalid", .invalidCharacter),
      ("2080/5", .wrongGroupCount),
    ])
  func constructorInvalidStringFormatsThrowsException(input: String, kind: NepDateError.Kind) {
    expectError(kind) { _ = try NepaliDate.parse(input) }
  }

  @Test(
    "NepaliDateConstructionTests.Constructor_ValidFormatInvalidDate_ThrowsException",
    arguments: ["2080/5/40"])
  func constructorValidFormatInvalidDateThrowsException(input: String) {
    expectError(.invalidDay(monthLength: 31)) { _ = try NepaliDate.parse(input) }
  }

  @Test("NepaliDateConstructionTests.Constructor_EnglishDate_ConvertsCorrectly")
  func constructorEnglishDateConvertsCorrectly() throws {
    let date = try ad(2023, 8, 30)
    #expect(date.year == 2080 && date.month == 5 && date.day == 13)
  }

  @Test("NepaliDateConstructionTests.TryParse_ValidString_ReturnsTrueWithCorrectDate")
  func tryParseValidStringReturnsTrueWithCorrectDate() throws {
    #expect(NepaliDate("2080/05/15") == (try bs(2080, 5, 15)))
  }

  @Test(
    "NepaliDateConstructionTests.TryParse_InvalidString_ReturnsFalseWithDefault",
    arguments: ["", "invalid", "2080/5"])
  func tryParseInvalidStringReturnsFalseWithDefault(input: String) {
    #expect(NepaliDate(input) == nil)
  }
}
