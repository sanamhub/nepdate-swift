extension NepaliDate: Codable {
  /// Decodes a date from one string, exactly the encoded form `YYYY-MM-DD` (D-11).
  ///
  /// ``parse(_:)`` alone would also accept `2081/04/15`, so the string must round-trip through
  /// ``format(_:lang:)`` with the `s` pattern before it is accepted.
  ///
  /// - Parameter decoder: The decoder to read from.
  /// - Throws: `DecodingError.dataCorrupted` when the string is not a `YYYY-MM-DD` date, or the
  ///   decoder's error when the value is not a string.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let text = try container.decode(String.self)
    guard let date = try? NepaliDate.parse(text), date.format("s") == text else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "\"\(text)\" is not a YYYY-MM-DD Bikram Sambat date"))
    }
    self = date
  }

  /// Encodes the date as a single string `"YYYY-MM-DD"` (D-11).
  ///
  /// - Parameter encoder: The encoder to write to.
  /// - Throws: The encoder's error.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(format("s"))
  }
}
