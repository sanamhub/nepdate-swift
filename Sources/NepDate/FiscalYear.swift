/// A quarter of Nepal's fiscal year, which starts on 1 Shrawan (ALGORITHM §8b).
public enum Quarter: Int, Sendable, CaseIterable {
  /// Shrawan, Bhadra, Ashoj.
  case q1 = 1
  /// Kartik, Mangsir, Poush.
  case q2
  /// Magh, Falgun, Chaitra.
  case q3
  /// Baishakh, Jestha, Ashad, in the next BS year.
  case q4

  /// The three months of the quarter, in order.
  public var months: [Month] {
    switch self {
    case .q1: return [.shrawan, .bhadra, .ashoj]
    case .q2: return [.kartik, .mangsir, .poush]
    case .q3: return [.magh, .falgun, .chaitra]
    case .q4: return [.baishakh, .jestha, .ashad]
    }
  }

  /// The quarter's first month number (4, 7, 10 or 1).
  @usableFromInline
  var firstMonth: Int { (rawValue * 3) % 12 + 1 }
}

/// A Nepali fiscal year, 1 Shrawan of ``startYear`` to the end of Ashad of the next year (D-08).
///
/// FY 2082/83 is `FiscalYear(startYear: 2082)`.
public struct FiscalYear: Sendable, Hashable, Comparable {
  /// The BS year the fiscal year starts in.
  public let startYear: Int

  /// The fiscal year that starts in `startYear`. Any year is accepted; the dates are checked
  /// when asked for.
  ///
  /// - Parameter startYear: The BS year of 1 Shrawan.
  @inlinable
  public init(startYear: Int) {
    self.startYear = startYear
  }

  /// The fiscal year that contains `date`.
  ///
  /// - Parameter date: Any date; Baishakh to Ashad belong to the fiscal year of the year before.
  @inlinable
  public init(containing date: NepaliDate) {
    startYear = date.month >= 4 ? date.year : date.year - 1
  }

  /// 1 Shrawan of ``startYear``.
  ///
  /// - Returns: The first day of the fiscal year.
  /// - Throws: `NepDateError` with kind `.outOfRange` outside BS 1901 to 2199.
  @inlinable
  public func start() throws(NepDateError) -> NepaliDate {
    try NepaliDate(year: startYear, month: 4, day: 1)
  }

  /// The last day of Ashad of the year after ``startYear``.
  ///
  /// - Returns: The last day of the fiscal year.
  /// - Throws: `NepDateError` with kind `.outOfRange` outside BS 1901 to 2199.
  @inlinable
  public func end() throws(NepDateError) -> NepaliDate {
    // Checked first, so startYear + 1 can't overflow.
    guard startYear < CalendarData.maxYear else { throw NepDateError(.outOfRange) }
    return try NepaliDate(year: startYear + 1, month: 3, day: 1).lastDayOfMonth
  }

  /// Every day of the fiscal year.
  ///
  /// - Returns: The range from ``start()`` to ``end()``.
  /// - Throws: `NepDateError` with kind `.outOfRange` outside BS 1901 to 2199.
  @inlinable
  public func range() throws(NepDateError) -> NepaliDateRange {
    NepaliDateRange(unchecked: try start(), try end())
  }

  /// Every day of one quarter of the fiscal year.
  ///
  /// - Parameter quarter: The quarter; Q4 is Baishakh to Ashad of the next BS year.
  /// - Returns: The range from the quarter's first day to its last.
  /// - Throws: `NepDateError` with kind `.outOfRange` outside BS 1901 to 2199.
  @inlinable
  public func range(of quarter: Quarter) throws(NepDateError) -> NepaliDateRange {
    var year = startYear
    if quarter == .q4 {
      guard startYear < CalendarData.maxYear else { throw NepDateError(.outOfRange) }
      year += 1
    }
    let first = try NepaliDate(year: year, month: quarter.firstMonth, day: 1)
    let last = try NepaliDate(year: year, month: quarter.firstMonth + 2, day: 1).lastDayOfMonth
    return NepaliDateRange(unchecked: first, last)
  }

  /// The label `2082/83`, or `२०८२/८३` in Nepali.
  ///
  /// - Parameter lang: The digits to use.
  /// - Returns: The start year, a slash and the last two digits of the next year.
  public func label(_ lang: Lang = .english) -> String {
    var counter = ByteCounter()
    writeLabel(lang: lang, to: &counter)
    var output = ""
    output.reserveCapacity(counter.count)
    writeLabel(lang: lang, to: &output)
    return output
  }

  func writeLabel<Sink: TextSink>(lang: Lang, to sink: inout Sink) {
    writeDigits(startYear, minWidth: 0, lang: lang, to: &sink)
    sink.appendASCII(0x2F)  // "/"
    // The remainder is made non-negative so a negative start year still gives two digits.
    writeDigits(((startYear % 100) + 101) % 100, minWidth: 2, lang: lang, to: &sink)
  }

  /// Orders fiscal years by start year.
  @inlinable
  public static func < (lhs: FiscalYear, rhs: FiscalYear) -> Bool {
    lhs.startYear < rhs.startYear
  }
}

extension NepaliDate {
  /// The fiscal year that contains this date.
  @inlinable
  public var fiscalYear: FiscalYear { FiscalYear(containing: self) }

  /// The fiscal quarter of this date: Shrawan to Ashoj is Q1, Baishakh to Ashad is Q4.
  @inlinable
  public var quarter: Quarter {
    // (m + 8) % 12 counts months from Shrawan; m is 1...12, so the fallback is never taken.
    Quarter(rawValue: (Int(m) + 8) % 12 / 3 + 1) ?? .q1
  }
}
