/// The order of year, month and day in ``NepaliDate/short(order:separator:pad:lang:)``.
public enum DateOrder: Sendable {
  /// Year, month, day: `2081/04/15`.
  case ymd
  /// Year, day, month: `2081/15/04`.
  case ydm
  /// Month, year, day: `04/2081/15`.
  case myd
  /// Month, day, year: `04/15/2081`.
  case mdy
  /// Day, year, month: `15/2081/04`.
  case dym
  /// Day, month, year: `15/04/2081`.
  case dmy
}

/// The character between the numbers of a short date.
public enum Separator: Character, Sendable {
  /// `/`
  case slash = "/"
  /// `\`
  case backslash = "\\"
  /// `.`
  case dot = "."
  /// `_`
  case underscore = "_"
  /// `-`
  case dash = "-"
  /// A space.
  case space = " "

  var ascii: UInt8 {
    switch self {
    case .slash: return 0x2F
    case .backslash: return 0x5C
    case .dot: return 0x2E
    case .underscore: return 0x5F
    case .dash: return 0x2D
    case .space: return 0x20
    }
  }
}

extension NepaliDate: CustomStringConvertible {
  /// The date as `YYYY/MM/DD` with ASCII digits, for example `2081/04/15` (FORMATTING §2).
  public var description: String {
    short()
  }
}

extension NepaliDate {
  /// The date as three numbers with a separator (FORMATTING §3): `2081/04/15`, or `15-4-2081`
  /// with `order: .dmy, separator: .dash, pad: false`.
  ///
  /// - Parameters:
  ///   - order: The order of year, month and day.
  ///   - separator: The character between the numbers.
  ///   - pad: Whether month and day get two digits.
  ///   - lang: ASCII or Devanagari digits.
  /// - Returns: The formatted date.
  public func short(
    order: DateOrder = .ymd, separator: Separator = .slash, pad: Bool = true,
    lang: Lang = .english
  ) -> String {
    var counter = ByteCounter()
    writeShort(order: order, separator: separator, pad: pad, lang: lang, to: &counter)
    var output = ""
    output.reserveCapacity(counter.count)
    writeShort(order: order, separator: separator, pad: pad, lang: lang, to: &output)
    return output
  }

  /// Appends ``short(order:separator:pad:lang:)`` to `output`.
  ///
  /// - Parameters:
  ///   - output: The string to append to; it grows only when its capacity is too small.
  ///   - order: The order of year, month and day.
  ///   - separator: The character between the numbers.
  ///   - pad: Whether month and day get two digits.
  ///   - lang: ASCII or Devanagari digits.
  public func appendShort(
    to output: inout String, order: DateOrder = .ymd, separator: Separator = .slash,
    pad: Bool = true, lang: Lang = .english
  ) {
    writeShort(order: order, separator: separator, pad: pad, lang: lang, to: &output)
  }

  /// The date in words (FORMATTING §4): `Shrawan 15, 2081`, or with `weekday: true`
  /// `Tuesday, Shrawan 15, 2081`.
  ///
  /// - Parameters:
  ///   - weekday: Whether to start with the weekday's name.
  ///   - year: Whether to end with the year.
  ///   - pad: Whether the day gets two digits.
  ///   - lang: The language of names and digits.
  /// - Returns: The formatted date.
  public func long(
    weekday: Bool = false, year: Bool = true, pad: Bool = true, lang: Lang = .english
  ) -> String {
    var counter = ByteCounter()
    writeLong(weekday: weekday, year: year, pad: pad, lang: lang, to: &counter)
    var output = ""
    output.reserveCapacity(counter.count)
    writeLong(weekday: weekday, year: year, pad: pad, lang: lang, to: &output)
    return output
  }

  /// Appends ``long(weekday:year:pad:lang:)`` to `output`.
  ///
  /// - Parameters:
  ///   - output: The string to append to; it grows only when its capacity is too small.
  ///   - weekday: Whether to start with the weekday's name.
  ///   - year: Whether to end with the year.
  ///   - pad: Whether the day gets two digits.
  ///   - lang: The language of names and digits.
  public func appendLong(
    to output: inout String, weekday: Bool = false, year: Bool = true, pad: Bool = true,
    lang: Lang = .english
  ) {
    writeLong(weekday: weekday, year: year, pad: pad, lang: lang, to: &output)
  }

  /// The date in a .NET-style pattern (FORMATTING §5), for example `yyyy-MM-dd`.
  ///
  /// `""`, `G`, `g` and `d` give `YYYY/MM/DD`, `D` the long form and `s` `YYYY-MM-DD`. Otherwise
  /// `yyyy`, `yy`, `MMMM`, `MMM`, `MM`, `M`, `dd` and `d` are replaced, `'text'` and `\x` are
  /// literal, and every other character is copied.
  ///
  /// - Parameters:
  ///   - pattern: The pattern.
  ///   - lang: The language of names and digits; literal text is never changed.
  /// - Returns: The formatted date.
  public func format(_ pattern: String, lang: Lang = .english) -> String {
    var counter = ByteCounter()
    writeFormat(pattern, lang: lang, to: &counter)
    var output = ""
    output.reserveCapacity(counter.count)
    writeFormat(pattern, lang: lang, to: &output)
    return output
  }

  /// Appends ``format(_:lang:)`` to `output`.
  ///
  /// - Parameters:
  ///   - pattern: The pattern.
  ///   - output: The string to append to; it grows only when its capacity is too small.
  ///   - lang: The language of names and digits.
  public func appendFormat(_ pattern: String, to output: inout String, lang: Lang = .english) {
    writeFormat(pattern, lang: lang, to: &output)
  }

  func writeShort<Sink: TextSink>(
    order: DateOrder, separator: Separator, pad: Bool, lang: Lang, to sink: inout Sink
  ) {
    let fields: (DateField, DateField, DateField)
    switch order {
    case .ymd: fields = (.year, .month, .day)
    case .ydm: fields = (.year, .day, .month)
    case .myd: fields = (.month, .year, .day)
    case .mdy: fields = (.month, .day, .year)
    case .dym: fields = (.day, .year, .month)
    case .dmy: fields = (.day, .month, .year)
    }
    writeField(fields.0, pad: pad, lang: lang, to: &sink)
    sink.appendASCII(separator.ascii)
    writeField(fields.1, pad: pad, lang: lang, to: &sink)
    sink.appendASCII(separator.ascii)
    writeField(fields.2, pad: pad, lang: lang, to: &sink)
  }

  /// Writes one number of a short date; padding gives the year 4 digits and the others 2.
  func writeField<Sink: TextSink>(_ field: DateField, pad: Bool, lang: Lang, to sink: inout Sink) {
    switch field {
    case .year: writeDigits(year, minWidth: pad ? 4 : 0, lang: lang, to: &sink)
    case .month: writeDigits(month, minWidth: pad ? 2 : 0, lang: lang, to: &sink)
    case .day: writeDigits(day, minWidth: pad ? 2 : 0, lang: lang, to: &sink)
    }
  }

  func writeLong<Sink: TextSink>(
    weekday: Bool, year: Bool, pad: Bool, lang: Lang, to sink: inout Sink
  ) {
    if weekday {
      sink.appendText(self.weekday.name(lang))
      sink.appendASCII(0x2C)  // ","
      sink.appendASCII(0x20)
    }
    sink.appendText(bsMonth.name(lang))
    sink.appendASCII(0x20)
    writeDigits(day, minWidth: pad ? 2 : 0, lang: lang, to: &sink)
    if year {
      sink.appendASCII(0x2C)
      sink.appendASCII(0x20)
      writeDigits(self.year, minWidth: 4, lang: lang, to: &sink)
    }
  }

  /// One left-to-right pass over the pattern's UTF-8 bytes. Pattern letters, quotes and the
  /// backslash are ASCII, so every cut between literal text falls on a scalar boundary and the
  /// literal text is copied as whole slices.
  func writeFormat<Sink: TextSink>(_ pattern: String, lang: Lang, to sink: inout Sink) {
    switch pattern {
    case "", "G", "g", "d":
      writeShort(order: .ymd, separator: .slash, pad: true, lang: lang, to: &sink)
      return
    case "D":
      writeLong(weekday: false, year: true, pad: true, lang: lang, to: &sink)
      return
    case "s":
      writeShort(order: .ymd, separator: .dash, pad: true, lang: lang, to: &sink)
      return
    default:
      break
    }
    let utf8 = pattern.utf8
    let end = utf8.endIndex
    var literalStart = utf8.startIndex
    var i = utf8.startIndex
    while i != end {
      let byte = utf8[i]
      switch byte {
      case 0x5C:  // "\": the next character is literal; at the very end it writes nothing
        writeLiteral(utf8[literalStart..<i], to: &sink)
        let next = utf8.index(after: i)
        literalStart = next
        i = next == end ? end : skipScalar(utf8, from: next)
      case 0x27:  // "'": literal text up to the next quote, or to the end
        writeLiteral(utf8[literalStart..<i], to: &sink)
        let textStart = utf8.index(after: i)
        var textEnd = textStart
        while textEnd != end && utf8[textEnd] != 0x27 { utf8.formIndex(after: &textEnd) }
        writeLiteral(utf8[textStart..<textEnd], to: &sink)
        i = textEnd == end ? end : utf8.index(after: textEnd)
        literalStart = i
      case 0x79, 0x4D, 0x64:  // "y", "M", "d"
        writeLiteral(utf8[literalStart..<i], to: &sink)
        var runEnd = utf8.index(after: i)
        var run = 1
        while runEnd != end && utf8[runEnd] == byte {
          utf8.formIndex(after: &runEnd)
          run += 1
        }
        writeToken(byte, run: run, lang: lang, to: &sink)
        i = runEnd
        literalStart = i
      default:
        utf8.formIndex(after: &i)
      }
    }
    writeLiteral(utf8[literalStart..<end], to: &sink)
  }

  func writeToken<Sink: TextSink>(_ letter: UInt8, run: Int, lang: Lang, to sink: inout Sink) {
    switch letter {
    case 0x79:  // y
      if run >= 4 {
        writeDigits(year, minWidth: 4, lang: lang, to: &sink)
      } else {
        writeDigits(year % 100, minWidth: 2, lang: lang, to: &sink)
      }
    case 0x4D:  // M
      switch run {
      case 1: writeDigits(month, minWidth: 0, lang: lang, to: &sink)
      case 2: writeDigits(month, minWidth: 2, lang: lang, to: &sink)
      case 3: sink.appendText(bsMonth.shortName(lang))
      default: sink.appendText(bsMonth.name(lang))
      }
    default:  // d
      writeDigits(day, minWidth: run == 2 ? 2 : 0, lang: lang, to: &sink)
    }
  }
}

/// One number of a short date.
enum DateField {
  case year, month, day
}

/// Copies a slice of the pattern unchanged.
func writeLiteral<Sink: TextSink>(_ bytes: Substring.UTF8View, to sink: inout Sink) {
  if !bytes.isEmpty { sink.appendSlice(Substring(bytes)) }
}

/// The index after the scalar that starts at `start`, from the length its lead byte gives.
func skipScalar(_ utf8: String.UTF8View, from start: String.Index) -> String.Index {
  let lead = utf8[start]
  let length: Int
  switch lead {
  case 0xF0...: length = 4
  case 0xE0...: length = 3
  case 0xC0...: length = 2
  default: length = 1
  }
  return utf8.index(start, offsetBy: length, limitedBy: utf8.endIndex) ?? utf8.endIndex
}
