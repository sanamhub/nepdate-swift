import Testing

@testable import NepDate

/// C# `IParsable<T>` maps to `LosslessStringConvertible`; `ISpanParsable<T>` to parsing a
/// `Substring` in place.
func parseGeneric<T: LosslessStringConvertible>(_ text: String, as type: T.Type) -> T? {
  T(text)
}

@Suite("NepaliDateParsableTests")
struct NepaliDateParsableTests {
  let expected = try! NepaliDate(year: 2081, month: 4, day: 15)

  @Test("NepaliDateParsableTests.Parse_Via_GenericConstraint_Returns_CorrectDate")
  func parseViaGenericConstraint() {
    #expect(parseGeneric("2081-04-15", as: NepaliDate.self) == expected)
  }

  @Test("NepaliDateParsableTests.TryParse_Via_GenericConstraint_ValidDate_Returns_True")
  func tryParseViaGenericConstraintValid() {
    #expect(parseGeneric("2081/04/15", as: NepaliDate.self) == expected)
  }

  @Test("NepaliDateParsableTests.TryParse_Via_GenericConstraint_InvalidDate_Returns_False")
  func tryParseViaGenericConstraintInvalid() {
    #expect(parseGeneric("garbage", as: NepaliDate.self) == nil)
  }

  @Test("NepaliDateParsableTests.SpanParse_Via_GenericConstraint_Returns_CorrectDate")
  func spanParseViaGenericConstraint() throws {
    let text = "2081-04-15"
    #expect(try NepaliDate.parse(text[...]) == expected)
  }

  @Test("NepaliDateParsableTests.SpanTryParse_Via_GenericConstraint_ValidDate_Returns_True")
  func spanTryParseViaGenericConstraint() {
    let text = "2081/04/15"
    #expect((try? NepaliDate.parse(text[...])) == expected)
  }
}
