// Names and digits (FORMATTING §1). Every name is a string literal returned from a `switch`, so
// it is static data: no table is built on first access and returning one allocates nothing.

extension Month {
  /// The month's name: `Shrawan`, or `साउन` in Nepali.
  ///
  /// - Parameter lang: The language of the name.
  /// - Returns: The full name.
  public func name(_ lang: Lang = .english) -> String {
    switch lang {
    case .english: return englishName
    case .nepali: return nepaliName
    }
  }

  /// The month's short name: `Shr`, and `Asa` and `Aso` for Ashad and Ashoj (D-04). Nepali has
  /// no customary abbreviation, so in Nepali this is the full name.
  ///
  /// - Parameter lang: The language of the name.
  /// - Returns: The short name.
  public func shortName(_ lang: Lang = .english) -> String {
    switch lang {
    case .english: return englishShortName
    case .nepali: return nepaliName
    }
  }

  var englishName: String {
    switch self {
    case .baishakh: return "Baishakh"
    case .jestha: return "Jestha"
    case .ashad: return "Ashad"
    case .shrawan: return "Shrawan"
    case .bhadra: return "Bhadra"
    case .ashoj: return "Ashoj"
    case .kartik: return "Kartik"
    case .mangsir: return "Mangsir"
    case .poush: return "Poush"
    case .magh: return "Magh"
    case .falgun: return "Falgun"
    case .chaitra: return "Chaitra"
    }
  }

  var englishShortName: String {
    switch self {
    case .baishakh: return "Bai"
    case .jestha: return "Jes"
    case .ashad: return "Asa"
    case .shrawan: return "Shr"
    case .bhadra: return "Bha"
    case .ashoj: return "Aso"
    case .kartik: return "Kar"
    case .mangsir: return "Man"
    case .poush: return "Pou"
    case .magh: return "Mag"
    case .falgun: return "Fal"
    case .chaitra: return "Cha"
    }
  }

  var nepaliName: String {
    switch self {
    case .baishakh: return "बैशाख"
    case .jestha: return "जेठ"
    case .ashad: return "असार"
    case .shrawan: return "साउन"
    case .bhadra: return "भदौ"
    case .ashoj: return "असोज"
    case .kartik: return "कार्तिक"
    case .mangsir: return "मंसिर"
    case .poush: return "पुष"
    case .magh: return "माघ"
    case .falgun: return "फागुन"
    case .chaitra: return "चैत"
    }
  }
}

extension Weekday {
  /// The weekday's name: `Tuesday`, or `मङ्गलवार` in Nepali.
  ///
  /// - Parameter lang: The language of the name.
  /// - Returns: The full name.
  public func name(_ lang: Lang = .english) -> String {
    switch (self, lang) {
    case (.sunday, .english): return "Sunday"
    case (.monday, .english): return "Monday"
    case (.tuesday, .english): return "Tuesday"
    case (.wednesday, .english): return "Wednesday"
    case (.thursday, .english): return "Thursday"
    case (.friday, .english): return "Friday"
    case (.saturday, .english): return "Saturday"
    case (.sunday, .nepali): return "आइतवार"
    case (.monday, .nepali): return "सोमवार"
    case (.tuesday, .nepali): return "मङ्गलवार"
    case (.wednesday, .nepali): return "बुधवार"
    case (.thursday, .nepali): return "बिहिवार"
    case (.friday, .nepali): return "शुक्रवार"
    case (.saturday, .nepali): return "शनिवार"
    }
  }

  /// The weekday's short name, for a calendar grid header: `Tue`, or `मङ्गल` in Nepali.
  ///
  /// - Parameter lang: The language of the name.
  /// - Returns: The short name.
  public func shortName(_ lang: Lang = .english) -> String {
    switch (self, lang) {
    case (.sunday, .english): return "Sun"
    case (.monday, .english): return "Mon"
    case (.tuesday, .english): return "Tue"
    case (.wednesday, .english): return "Wed"
    case (.thursday, .english): return "Thu"
    case (.friday, .english): return "Fri"
    case (.saturday, .english): return "Sat"
    case (.sunday, .nepali): return "आइत"
    case (.monday, .nepali): return "सोम"
    case (.tuesday, .nepali): return "मङ्गल"
    case (.wednesday, .nepali): return "बुध"
    case (.thursday, .nepali): return "बिहि"
    case (.friday, .nepali): return "शुक्र"
    case (.saturday, .nepali): return "शनि"
    }
  }
}

/// `n` in Devanagari digits: `nepaliDigits(2081)` is `२०८१`.
///
/// - Parameters:
///   - n: The number. A negative number gets a leading ASCII `-`.
///   - minWidth: The least number of digits; shorter numbers are padded with `०`.
/// - Returns: The digits.
public func nepaliDigits(_ n: Int, minWidth: Int = 0) -> String {
  var counter = ByteCounter()
  writeDigits(n, minWidth: minWidth, lang: .nepali, to: &counter)
  var output = ""
  output.reserveCapacity(counter.count)
  writeDigits(n, minWidth: minWidth, lang: .nepali, to: &output)
  return output
}

/// Somewhere formatted text goes. Formatters run twice through the same code: once into a
/// `ByteCounter` to learn the exact UTF-8 size, then into the `String` after one
/// `reserveCapacity` (ADR-0002 §4).
protocol TextSink {
  mutating func appendText(_ text: String)
  mutating func appendSlice(_ text: Substring)
  mutating func appendASCII(_ byte: UInt8)
}

/// Counts UTF-8 bytes instead of writing them.
struct ByteCounter: TextSink {
  var count = 0

  mutating func appendText(_ text: String) { count += text.utf8.count }
  mutating func appendSlice(_ text: Substring) { count += text.utf8.count }
  mutating func appendASCII(_ byte: UInt8) { count += 1 }
}

extension String: TextSink {
  mutating func appendText(_ text: String) { append(text) }
  mutating func appendSlice(_ text: Substring) { append(contentsOf: text) }
  mutating func appendASCII(_ byte: UInt8) { unicodeScalars.append(Unicode.Scalar(byte)) }
}

/// Writes the decimal digits of `value`, zero-padded to `minWidth` digits, in ASCII or
/// Devanagari. Goes from the highest power of ten down, so it needs no buffer.
func writeDigits<Sink: TextSink>(_ value: Int, minWidth: Int, lang: Lang, to sink: inout Sink) {
  if value < 0 { sink.appendASCII(0x2D) }
  let magnitude = value.magnitude
  var divisor: UInt = 1
  var width = 1
  while magnitude / divisor >= 10 {
    divisor *= 10
    width += 1
  }
  if minWidth > width {
    for _ in width..<minWidth { writeDigit(0, lang: lang, to: &sink) }
  }
  var rest = magnitude
  while divisor > 0 {
    writeDigit(rest / divisor, lang: lang, to: &sink)
    rest %= divisor
    divisor /= 10
  }
}

/// Writes one digit, 0 to 9.
func writeDigit<Sink: TextSink>(_ digit: UInt, lang: Lang, to sink: inout Sink) {
  switch lang {
  case .english: sink.appendASCII(UInt8(truncatingIfNeeded: 0x30 + digit))
  case .nepali: sink.appendText(devanagariDigit(digit))
  }
}

/// The Devanagari digit for 0 to 9 (U+0966 to U+096F), as a string literal.
func devanagariDigit(_ digit: UInt) -> String {
  switch digit {
  case 0: return "०"
  case 1: return "१"
  case 2: return "२"
  case 3: return "३"
  case 4: return "४"
  case 5: return "५"
  case 6: return "६"
  case 7: return "७"
  case 8: return "८"
  default: return "९"
  }
}
