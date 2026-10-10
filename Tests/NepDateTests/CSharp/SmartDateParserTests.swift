import Testing

@testable import NepDate

/// `parseLenient`, failing the test when it throws.
func lenient(_ text: String) throws -> NepaliDate {
  try NepaliDate.parseLenient(text)
}

// C# `SmartDateParser` is `parseLenient` (D-06): explicit rules, a closed month list, no guessing.
// Where a C# assertion relies on guessing, the row asserts the D-06 result instead and says so.
@Suite("SmartDateParserTests")
struct SmartDateParserTests {
  let expected = try! NepaliDate(year: 2080, month: 4, day: 15)

  @Test("SmartDateParserTests.Parse_StandardFormat_ReturnsCorrectDate")
  func parseStandardFormat() throws {
    for text in ["2080/04/15", "2080-04-15", "2080.04.15"] {
      #expect(try lenient(text) == expected)
    }
  }

  @Test("SmartDateParserTests.Parse_InvertedFormat_ReturnsCorrectDate")
  func parseInvertedFormat() throws {
    for text in ["15/04/2080", "15-04-2080", "15.04.2080"] {
      #expect(try lenient(text) == expected)
    }
  }

  // D-06: with the year last, the order is day, month, year; C# guesses month, day, year when the
  // middle number is over 12. Here 15 is read as the month, so the date is invalid.
  @Test("SmartDateParserTests.Parse_MonthDayYearFormat_ReturnsCorrectDate")
  func parseMonthDayYearFormat() {
    for text in ["04/15/2080", "04-15-2080", "04.15.2080"] {
      expectError(.invalidMonth) { _ = try NepaliDate.parseLenient(text) }
    }
  }

  @Test("SmartDateParserTests.Parse_WithMonthNames_ReturnsCorrectDate")
  func parseWithMonthNames() throws {
    let inputs = [
      "15 Shrawan 2080", "15 Sawan 2080", "15 Saun 2080", "Shrawan 15, 2080", "Shrawan 15 2080",
    ]
    for text in inputs { #expect(try lenient(text) == expected) }
  }

  @Test("SmartDateParserTests.Parse_WithNepaliUnicode_ReturnsCorrectDate")
  func parseWithNepaliUnicode() throws {
    for text in ["२०८०/०४/१५", "१५/०४/२०८०", "१५ श्रावण २०८०", "श्रावण १५, २०८०"] {
      #expect(try lenient(text) == expected)
    }
  }

  @Test("SmartDateParserTests.Parse_MixedFormats_ReturnsCorrectDate")
  func parseMixedFormats() throws {
    for text in ["15 साउन 2080", "साउन 15, २०८०", "15 Shrawan २०८०"] {
      #expect(try lenient(text) == expected)
    }
  }

  @Test("SmartDateParserTests.Parse_WithSuffixes_ReturnsCorrectDate")
  func parseWithSuffixes() throws {
    let inputs = [
      "15 Shrawan 2080 B.S.", "15 साउन 2080 BS", "15 Shrawan 2080 V.S.", "15 साउन, 2080 मिति",
      "15 साउन, 2080 गते",
    ]
    for text in inputs { #expect(try lenient(text) == expected) }
  }

  // D-06: `Srawan` is in the closed list (PARSING §3); `Shraawan` is not, and there is no fuzzy
  // matching.
  @Test("SmartDateParserTests.Parse_WithTypos_ReturnsCorrectDate")
  func parseWithTypos() throws {
    #expect(try lenient("15 Srawan 2080") == expected)
    expectError(.unrecognized) { _ = try NepaliDate.parseLenient("15 Shraawan 2080") }
  }

  // D-06: two- and three-digit years are never expanded.
  @Test("SmartDateParserTests.Parse_ShorterYearFormats_ReturnsCorrectDate")
  func parseShorterYearFormats() {
    expectError(.ambiguous) { _ = try NepaliDate.parseLenient("15/04/80") }
    expectError(.ambiguous) { _ = try NepaliDate.parseLenient("15/04/080") }
  }

  @Test("SmartDateParserTests.Parse_InvalidFormat_ThrowsFormatException")
  func parseInvalidFormat() {
    expectError(.unrecognized) { _ = try NepaliDate.parseLenient("not a date") }
    expectError(.invalidMonth) { _ = try NepaliDate.parseLenient("15/13/2080") }
    expectError(.invalidDay(monthLength: 31)) { _ = try NepaliDate.parseLenient("32/03/2080") }
  }

  @Test("SmartDateParserTests.TryParse_ValidFormat_ReturnsTrue")
  func tryParseValidFormat() {
    #expect((try? NepaliDate.parseLenient("15 Shrawan 2080")) == expected)
  }

  @Test("SmartDateParserTests.TryParse_InvalidFormat_ReturnsFalse")
  func tryParseInvalidFormat() {
    #expect((try? NepaliDate.parseLenient("not a date")) == nil)
  }

  @Test("SmartDateParserTests.ExtensionMethod_ToNepaliDate_ParsesCorrectly")
  func extensionMethodToNepaliDate() throws {
    for text in ["2080/04/15", "२०८०/०४/१५", "15 Shrawan 2080"] {
      #expect(try lenient(text) == expected)
    }
  }

  @Test("SmartDateParserTests.ExtensionMethod_TryToNepaliDate_ParsesCorrectly")
  func extensionMethodTryToNepaliDate() {
    #expect((try? NepaliDate.parseLenient("15 Shrawan 2080")) == expected)
  }
}

// C# `string.ToNepaliDate()` uses the smart parser, so these rows use `parseLenient`.
@Suite("StringExtensionsTests")
struct StringExtensionsTests {
  let expected = try! NepaliDate(year: 2080, month: 5, day: 15)

  @Test("StringExtensionsTests.ToNepaliDate_ValidDateString_ReturnsNepaliDate")
  func toNepaliDateValid() throws {
    #expect(try lenient("2080/05/15") == expected)
  }

  @Test("StringExtensionsTests.ToNepaliDate_NepaliDigits_ReturnsNepaliDate")
  func toNepaliDateNepaliDigits() throws {
    #expect(try lenient("२०८०/०५/१५") == expected)
  }

  @Test("StringExtensionsTests.ToNepaliDate_InvalidDateString_ThrowsFormatException")
  func toNepaliDateInvalid() {
    expectError(.unrecognized) { _ = try NepaliDate.parseLenient("not a date") }
  }

  @Test("StringExtensionsTests.TryToNepaliDate_ValidDateString_ReturnsTrue")
  func tryToNepaliDateValid() {
    #expect((try? NepaliDate.parseLenient("2080/05/15")) == expected)
  }

  @Test("StringExtensionsTests.TryToNepaliDate_InvalidDateString_ReturnsFalse")
  func tryToNepaliDateInvalid() {
    #expect((try? NepaliDate.parseLenient("not a date")) == nil)
  }
}
