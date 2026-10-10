extension NepaliDate: Codable {
  /// Decodes a date from a single string such as `"2081-04-15"`, read with ``parse(_:)`` (D-11).
  ///
  /// - Parameter decoder: The decoder to read from.
  /// - Throws: `DecodingError.dataCorrupted` when the string is not a valid date, or the
  ///   decoder's error when the value is not a string.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let text = try container.decode(String.self)
    do {
      self = try NepaliDate.parse(text)
    } catch {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "\"\(text)\" is not a Bikram Sambat date: \(error.kind)"))
    }
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
