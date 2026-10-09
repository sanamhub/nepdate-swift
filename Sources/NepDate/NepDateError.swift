/// The one error type of `NepDate`. Switch on ``kind`` to tell the causes apart.
public struct NepDateError: Error, Sendable, Hashable {
  /// Why an operation failed.
  public enum Kind: Sendable, Hashable {
    /// The date is outside BS 1901-01-01 to 2199-12-30 (AD 1844-04-11 to 2143-04-15).
    case outOfRange
    /// The month is not 1 to 12.
    case invalidMonth
    /// The day is not 1 to the month's length, which is given.
    case invalidDay(monthLength: Int)
    /// The AD date does not exist, for example 2023-02-29.
    case invalidGregorian
    /// The text has a character that is neither a digit nor a separator.
    case invalidCharacter
    /// The text does not have three number groups.
    case wrongGroupCount
    /// A number group has more than four digits.
    case numberTooLong
    /// The text fits more than one reading, for example a two-digit year.
    case ambiguous
    /// The text could not be read as a date.
    case unrecognized
  }

  /// Why the operation failed.
  public let kind: Kind

  @usableFromInline
  init(_ kind: Kind) {
    self.kind = kind
  }
}
