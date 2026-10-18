// Strict and lenient parsing (PARSING §1 and §2) over the input's UTF-8 bytes. Tokens are index
// ranges into the input, never `Substring` or `Array` values, so parsing allocates nothing
// (ADR-0002 §5).

/// What one character of the input is to the parsers.
@usableFromInline
enum ScannedCharacter {
  /// An ASCII or Devanagari digit, 0 to 9.
  case digit(Int)
  /// One of `- / _ \ space | ।`, which both parsers split on.
  case separator
  /// `.`: a separator for strict parsing; for lenient parsing it splits only numbers.
  case dot
  /// `,`: a separator for lenient parsing only.
  case comma
  /// Anything else, one byte at a time.
  case other
}

/// Reads the character at `i` and returns it with the index after it. A Devanagari digit is
/// `E0 A5 A6` to `E0 A5 AF` and `।` is `E0 A5 A4`; any other byte is `.other` on its own.
@inlinable
func scanCharacter<Bytes: Collection>(
  _ utf8: Bytes, at i: Bytes.Index
) -> (ScannedCharacter, Bytes.Index) where Bytes.Element == UInt8 {
  let byte = utf8[i]
  let next = utf8.index(after: i)
  switch byte {
  case 0x30...0x39:
    return (.digit(Int(byte - 0x30)), next)
  case 0x2D, 0x2F, 0x5F, 0x5C, 0x20, 0x7C:
    return (.separator, next)
  case 0x2E:
    return (.dot, next)
  case 0x2C:
    return (.comma, next)
  case 0xE0:
    guard next != utf8.endIndex, utf8[next] == 0xA5 else { return (.other, next) }
    let third = utf8.index(after: next)
    guard third != utf8.endIndex else { return (.other, next) }
    let last = utf8[third]
    if last >= 0xA6 && last <= 0xAF { return (.digit(Int(last - 0xA6)), utf8.index(after: third)) }
    if last == 0xA4 { return (.separator, utf8.index(after: third)) }
    return (.other, next)
  default:
    return (.other, next)
  }
}

extension NepaliDate: LosslessStringConvertible {
  /// Parses `description` strictly, as ``parse(_:)`` does, or returns `nil`.
  ///
  /// - Parameter description: Year, month and day, for example `2081/04/15`.
  @inlinable
  public init?(_ description: String) {
    guard let date = try? NepaliDate.parse(description) else { return nil }
    self = date
  }
}

extension NepaliDate {
  /// Parses year, month and day in that order (PARSING §1).
  ///
  /// Digits may be ASCII or Devanagari, mixed (D-05). The numbers are separated by any of
  /// `- / . _ \ space । |`; leading, trailing and repeated separators are ignored.
  ///
  /// - Parameter string: The text, a `String` or a `Substring`.
  /// - Returns: The date.
  /// - Throws: `NepDateError` with kind `.invalidCharacter`, `.wrongGroupCount` (not exactly
  ///   three numbers, so also for empty input), `.numberTooLong` (more than 4 digits), or
  ///   `.outOfRange`, `.invalidMonth` and `.invalidDay(monthLength:)` from validation.
  @inlinable
  public static func parse(_ string: some StringProtocol) throws(NepDateError) -> NepaliDate {
    let utf8 = string.utf8
    if let date = try parseCanonical(utf8) { return date }
    return try parseSlow(utf8)
  }

  /// Parses the canonical shape `YYYY?MM?DD`: exactly 10 ASCII bytes, digits at 0 to 3, 5 to 6 and
  /// 8 to 9, and a strict separator at 4 and 7.
  ///
  /// Returns `nil` when the shape does not match, and `parse` then runs `parseSlow`. The fields go
  /// through ``init(year:month:day:)``, so the range, month and day checks and their error order
  /// are the ones the loop uses.
  @inlinable
  static func parseCanonical<Bytes: Collection>(
    _ utf8: Bytes
  ) throws(NepDateError) -> NepaliDate? where Bytes.Element == UInt8 {
    // One pass with a position counter. The 11th byte ends it, so a long input costs 11 steps and
    // only a 10-byte input can match.
    var position = 0
    var year = 0
    var month = 0
    var day = 0
    for byte in utf8 {
      guard position < 10 else { return nil }
      switch position {
      case 0, 1, 2, 3:
        guard isASCIIDigitByte(byte) else { return nil }
        year = year * 10 + Int(byte - 0x30)
      case 4, 7:
        guard isStrictSeparatorByte(byte) else { return nil }
      case 5, 6:
        guard isASCIIDigitByte(byte) else { return nil }
        month = month * 10 + Int(byte - 0x30)
      default:
        guard isASCIIDigitByte(byte) else { return nil }
        day = day * 10 + Int(byte - 0x30)
      }
      position += 1
    }
    guard position == 10 else { return nil }
    return try NepaliDate(year: year, month: month, day: day)
  }

  /// The general strict scanner: any strict separator, one to four digits per group, ASCII or
  /// Devanagari digits. It is the reference the fast path is tested against.
  @inlinable
  static func parseSlow<Bytes: Collection>(
    _ utf8: Bytes
  ) throws(NepDateError) -> NepaliDate where Bytes.Element == UInt8 {
    var fields = (0, 0, 0)
    var group = 0
    var digits = 0
    var value = 0
    var i = utf8.startIndex
    while i != utf8.endIndex {
      let (character, next) = scanCharacter(utf8, at: i)
      i = next
      switch character {
      case .digit(let digit):
        guard digits < 4 else { throw NepDateError(.numberTooLong) }
        // digits < 4 above keeps value under 10,000.
        value = value &* 10 &+ digit
        digits += 1
        guard group < 3 else { throw NepDateError(.wrongGroupCount) }
      case .separator, .dot:
        if digits > 0 {
          storeField(value, at: group, in: &fields)
          group += 1
          digits = 0
          value = 0
        }
      case .comma, .other:
        throw NepDateError(.invalidCharacter)
      }
    }
    if digits > 0 {
      storeField(value, at: group, in: &fields)
      group += 1
    }
    guard group == 3 else { throw NepDateError(.wrongGroupCount) }
    return try NepaliDate(year: fields.0, month: fields.1, day: fields.2)
  }

  /// Parses dates as people type them (PARSING §2): `15 Shrawan 2080`, `Shrawan 15, 2080`,
  /// `15/04/2080`, `२०८० साउन १५ गते`.
  ///
  /// Strict parsing is tried first. Otherwise the text is split into numbers and words; era
  /// markers (`BS`, `वि.सं.`, ...) and `गते`, `मिति` are dropped. One month name (PARSING §3) and two
  /// numbers, of which exactly one has 4 digits, give day and year. Three numbers are read as
  /// year, month, day when the first has 4 digits, else as day, month, year when the last has.
  /// Two-digit years are never expanded (D-06).
  ///
  /// - Parameter string: The text, a `String` or a `Substring`.
  /// - Returns: The date.
  /// - Throws: `NepDateError` with kind `.numberTooLong`, `.ambiguous` (no 4-digit year to
  ///   anchor the order), `.unrecognized` (unknown words, two month names, or the wrong number
  ///   of numbers, so also for empty input), or a validation kind.
  @inlinable
  public static func parseLenient(_ string: some StringProtocol) throws(NepDateError)
    -> NepaliDate
  {
    if let date = try? parse(string) { return date }
    var tokens = LenientTokens()
    let utf8 = string.utf8
    var tokenStart = utf8.startIndex
    var inToken = false
    var onlyNumbers = true
    var i = utf8.startIndex
    while i != utf8.endIndex {
      let (character, next) = scanCharacter(utf8, at: i)
      switch character {
      case .separator, .comma:
        if inToken { tokens.add(utf8, tokenStart..<i, onlyNumbers: onlyNumbers) }
        inToken = false
      case .digit, .dot, .other:
        if !inToken {
          inToken = true
          tokenStart = i
          onlyNumbers = true
        }
        if case .other = character { onlyNumbers = false }
      }
      i = next
    }
    if inToken { tokens.add(utf8, tokenStart..<utf8.endIndex, onlyNumbers: onlyNumbers) }
    return try tokens.date()
  }
}

/// What lenient parsing collects from the tokens: counts and at most three numbers.
@usableFromInline
struct LenientTokens {
  @usableFromInline var numbers = (0, 0, 0)
  @usableFromInline var lengths = (0, 0, 0)
  @usableFromInline var numberCount = 0
  @usableFromInline var tooLong = false
  @usableFromInline var monthCount = 0
  @usableFromInline var month = 0
  @usableFromInline var unknownWords = 0

  @inlinable
  init() {}

  /// Adds one token. A token of digits and dots is split on the dots into numbers; any other
  /// token is a word.
  @inlinable
  mutating func add<Bytes: Collection>(
    _ utf8: Bytes, _ range: Range<Bytes.Index>, onlyNumbers: Bool
  ) where Bytes.Element == UInt8 {
    guard onlyNumbers else {
      switch lenientWord(utf8, range) {
      case 0?: break
      case let month?:
        monthCount += 1
        self.month = month
      case nil:
        unknownWords += 1
      }
      return
    }
    var value = 0
    var digits = 0
    var i = range.lowerBound
    while i != range.upperBound {
      let (character, next) = scanCharacter(utf8, at: i)
      if case .digit(let digit) = character {
        // Only the first 4 digits are kept; a longer number is an error anyway.
        if digits < 4 { value = value &* 10 &+ digit }
        digits += 1
      } else {
        addNumber(value, digits: digits)
        value = 0
        digits = 0
      }
      i = next
    }
    addNumber(value, digits: digits)
  }

  @inlinable
  mutating func addNumber(_ value: Int, digits: Int) {
    guard digits > 0 else { return }
    if digits > 4 { tooLong = true }
    switch numberCount {
    case 0: (numbers.0, lengths.0) = (value, digits)
    case 1: (numbers.1, lengths.1) = (value, digits)
    case 2: (numbers.2, lengths.2) = (value, digits)
    default: break
    }
    numberCount += 1
  }

  /// PARSING §2 steps 2 to 6.
  @inlinable
  func date() throws(NepDateError) -> NepaliDate {
    if tooLong { throw NepDateError(.numberTooLong) }
    if unknownWords == 0 && monthCount == 1 && numberCount == 2 {
      let firstIsYear = lengths.0 == 4
      guard firstIsYear != (lengths.1 == 4) else { throw NepDateError(.ambiguous) }
      let (year, day, dayLength) =
        firstIsYear ? (numbers.0, numbers.1, lengths.1) : (numbers.1, numbers.0, lengths.0)
      guard dayLength <= 2 else { throw NepDateError(.ambiguous) }
      return try NepaliDate(year: year, month: month, day: day)
    }
    if unknownWords == 0 && monthCount == 0 && numberCount == 3 {
      if lengths.0 == 4 { return try NepaliDate(year: numbers.0, month: numbers.1, day: numbers.2) }
      if lengths.2 == 4 { return try NepaliDate(year: numbers.2, month: numbers.1, day: numbers.0) }
      throw NepDateError(.ambiguous)
    }
    throw NepDateError(.unrecognized)
  }
}

/// Stores a parsed number as year, month or day.
@inlinable
func storeField(_ value: Int, at group: Int, in fields: inout (Int, Int, Int)) {
  switch group {
  case 0: fields.0 = value
  case 1: fields.1 = value
  default: fields.2 = value
  }
}

/// Whether `byte` is an ASCII digit, `0` to `9`.
@inlinable
func isASCIIDigitByte(_ byte: UInt8) -> Bool { byte >= 0x30 && byte <= 0x39 }

/// Whether `byte` is one of the strict separators `- / . _ \ space |`. The danda `।` is three
/// bytes, so it can never appear in the 10-byte canonical shape.
@inlinable
func isStrictSeparatorByte(_ byte: UInt8) -> Bool {
  switch byte {
  case 0x2D, 0x2F, 0x2E, 0x5F, 0x5C, 0x20, 0x7C: return true
  default: return false
  }
}

/// Whether the bytes at `i` are the Kelvin sign U+212A (E2 84 AA), all before `end`.
@inlinable
func isKelvinSign<Bytes: Collection>(
  _ utf8: Bytes, at i: Bytes.Index, end: Bytes.Index
) -> Bool where Bytes.Element == UInt8 {
  guard utf8[i] == 0xE2 else { return false }
  var j = utf8.index(after: i)
  guard j != end, utf8[j] == 0x84 else { return false }
  j = utf8.index(after: j)
  return j != end && utf8[j] == 0xAA
}

/// The month 1 to 12 of a lenient word, 0 for a word that is dropped, or `nil` for an unknown
/// word. Words fold as PARSING §2 says, which is what Python `str.lower()` maps onto ASCII: `A`
/// to `Z` fold to lower case and the Kelvin sign U+212A folds to `k`; every other byte must
/// match exactly, so the long s U+017F does not match `s`.
@inlinable
func lenientWord<Bytes: Collection>(
  _ utf8: Bytes, _ range: Range<Bytes.Index>
) -> Int? where Bytes.Element == UInt8 {
  let length = utf8.distance(from: range.lowerBound, to: range.upperBound)
  let entries = LenientWords.entries
  let bytes = LenientWords.bytes
  var entry = 0
  while entry + 2 < entries.count {
    let offset = Int(entries[entry])
    let wordLength = Int(entries[entry + 1])
    let month = Int(entries[entry + 2])
    entry += 3
    // Folding only shrinks a word (the 3-byte Kelvin sign becomes 1 byte), never grows it.
    guard wordLength <= length else { continue }
    let end = offset + wordLength
    var i = range.lowerBound
    var k = offset
    var same = true
    while i != range.upperBound {
      var byte = utf8[i]
      var width = 1
      if byte >= 0x41 && byte <= 0x5A {
        byte += 0x20
      } else if isKelvinSign(utf8, at: i, end: range.upperBound) {
        byte = 0x6B  // k
        width = 3
      }
      if k == end || byte != bytes[k] {
        same = false
        break
      }
      utf8.formIndex(&i, offsetBy: width)
      k += 1
    }
    if same && k == end { return month }
  }
  return nil
}
