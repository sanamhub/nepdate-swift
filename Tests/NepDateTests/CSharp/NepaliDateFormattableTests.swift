import Testing

@testable import NepDate

// C# `IFormattable.ToString(format, provider)` is `format(_:)`; Swift string interpolation and
// `String(format:)` have no format specifiers for custom types, so those rows call `format(_:)`.
@Suite("NepaliDateFormattableTests")
struct NepaliDateFormattableTests {
  let date = try! NepaliDate(year: 2081, month: 4, day: 15)

  @Test("NepaliDateFormattableTests.ToString_NullFormat_ReturnsDefault")
  func toStringNullFormatReturnsDefault() {
    #expect(date.format("") == "2081/04/15")
  }

  @Test("NepaliDateFormattableTests.ToString_G_SameAsDefault")
  func toStringGSameAsDefault() {
    #expect(date.format("G") == date.description)
  }

  @Test("NepaliDateFormattableTests.ToString_g_SameAsDefault")
  func toStringLowerGSameAsDefault() {
    #expect(date.format("g") == date.description)
  }

  @Test("NepaliDateFormattableTests.ToString_d_SameAsDefault")
  func toStringLowerDSameAsDefault() {
    #expect(date.format("d") == "2081/04/15")
  }

  @Test("NepaliDateFormattableTests.ToString_D_ReturnsLongDateString")
  func toStringDReturnsLongDateString() {
    let result = date.format("D")
    #expect(result.contains("2081") && result.contains("Shrawan"))
  }

  @Test("NepaliDateFormattableTests.ToString_s_ReturnsSortableIsoFormat")
  func toStringSReturnsSortableIsoFormat() {
    #expect(date.format("s") == "2081-04-15")
  }

  @Test("NepaliDateFormattableTests.CustomFormat_yyyy_MM_dd_WithDash")
  func customFormatYearMonthDayWithDash() {
    #expect(date.format("yyyy-MM-dd") == "2081-04-15")
  }

  @Test("NepaliDateFormattableTests.CustomFormat_dd_MM_yyyy_WithDot")
  func customFormatDayMonthYearWithDot() {
    #expect(date.format("dd.MM.yyyy") == "15.04.2081")
  }

  @Test("NepaliDateFormattableTests.CustomFormat_MM_slash_dd_slash_yyyy")
  func customFormatMonthDayYearWithSlash() {
    #expect(date.format("MM/dd/yyyy") == "04/15/2081")
  }

  @Test("NepaliDateFormattableTests.CustomFormat_MMMxxx_ReturnsThreeCharMonthAbbreviation")
  func customFormatShortMonth() {
    let result = date.format("MMM yyyy")
    #expect(result.hasPrefix("Shr") && result.hasSuffix("2081"))
  }

  @Test("NepaliDateFormattableTests.CustomFormat_MMMM_ReturnsFullMonthName")
  func customFormatFullMonth() {
    #expect(date.format("MMMM dd, yyyy").hasPrefix("Shrawan"))
  }

  @Test("NepaliDateFormattableTests.CustomFormat_yy_ReturnsTwoDigitYear")
  func customFormatTwoDigitYear() {
    #expect(date.format("yy/MM/dd").hasPrefix("81/"))
  }

  @Test("NepaliDateFormattableTests.CustomFormat_M_WithoutLeadingZero_ReturnsUnpadded")
  func customFormatUnpaddedMonth() {
    #expect(date.format("M/d/yyyy") == "4/15/2081")
  }

  @Test("NepaliDateFormattableTests.CustomFormat_SingleDigitMonth_WithoutLeadingZero")
  func customFormatSingleDigitMonth() throws {
    #expect(try bs(2081, 1, 5).format("M/d/yyyy") == "1/5/2081")
  }

  @Test("NepaliDateFormattableTests.CustomFormat_LiteralInSingleQuotes")
  func customFormatLiteralInQuotes() {
    #expect(date.format("yyyy'BS'") == "2081BS")
  }

  @Test("NepaliDateFormattableTests.CustomFormat_BackslashEscapedTokens_ProduceLiterals")
  func customFormatBackslashEscapedTokens() {
    #expect(date.format("yyyy\\M\\M-\\d\\d") == "2081MM-dd")
  }

  @Test("NepaliDateFormattableTests.CustomFormat_BackslashBeforeLiteralChar_IsPassedThrough")
  func customFormatBackslashBeforeLiteral() {
    #expect(date.format("yyyy\\-MM\\-dd") == "2081-04-15")
  }

  @Test("NepaliDateFormattableTests.StringInterpolation_WithFormatSpecifier_UsesIFormattable")
  func stringInterpolationWithFormat() {
    #expect("\(date.format("s"))" == "2081-04-15")
  }

  @Test("NepaliDateFormattableTests.StringFormatMethod_WithSpecifier")
  func stringFormatMethod() {
    #expect(date.format("yyyy-MM-dd") == "2081-04-15")
  }

  @Test("NepaliDateFormattableTests.SortableFormat_LexicographicOrderEqualsChronologicalOrder")
  func sortableFormatOrder() throws {
    #expect(try bs(2080, 12, 30).format("s") < bs(2081, 1, 1).format("s"))
  }
}
