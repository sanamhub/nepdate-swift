/// An inclusive range of dates, from ``lowerBound`` to ``upperBound``.
///
/// A range is never empty: the failable initialiser returns `nil` when the end is before the
/// start, and the factories either throw or return only valid bounds. The range is a
/// `RandomAccessCollection` indexed by day count with `Int` indices, so `count` and
/// `contains(_:)` are O(1) and SwiftUI's `ForEach` and `for in` read it without copying.
public struct NepaliDateRange: RandomAccessCollection, Sendable, Hashable, CustomStringConvertible {
  /// The first date in the range.
  public let lowerBound: NepaliDate
  /// The last date in the range.
  public let upperBound: NepaliDate

  /// Creates the range from `start` to `end`, both included, or `nil` when `start` is after `end`.
  ///
  /// - Parameters:
  ///   - start: The first date.
  ///   - end: The last date.
  @inlinable
  public init?(_ start: NepaliDate, _ end: NepaliDate) {
    guard start <= end else { return nil }
    self.init(unchecked: start, end)
  }

  /// Creates a range of `dayCount` days starting at `start`.
  ///
  /// - Parameters:
  ///   - start: The first date.
  ///   - dayCount: The number of days, at least 1.
  /// - Throws: `NepDateError` with kind `.invalidArgument` when `dayCount` is below 1, and
  ///   `.outOfRange` when the last day would pass BS 2199-12-30.
  @inlinable
  public init(start: NepaliDate, dayCount: Int) throws(NepDateError) {
    guard dayCount >= 1 else { throw NepDateError(.invalidArgument) }
    let span = Int(CalendarData.maxSerial) - Int(start.serial)
    guard dayCount - 1 <= span else { throw NepDateError(.outOfRange) }
    self.init(unchecked: start, NepaliDate(serial: start.serial + Int32(dayCount - 1)))
  }

  /// Stores bounds the caller knows are in order. `package` so `NepDatePatro` can return its
  /// coverage without an optional.
  @inlinable
  package init(unchecked start: NepaliDate, _ end: NepaliDate) {
    lowerBound = start
    upperBound = end
  }

  /// The one-day range of `date`.
  ///
  /// - Parameter date: The only date in the range.
  /// - Returns: The range from `date` to `date`.
  @inlinable
  public static func singleDay(_ date: NepaliDate) -> NepaliDateRange {
    NepaliDateRange(unchecked: date, date)
  }

  /// Every day of one BS month.
  ///
  /// - Parameters:
  ///   - year: The BS year, 1901 to 2199.
  ///   - month: The month, 1 to 12.
  /// - Returns: The range from day 1 to the month's last day.
  /// - Throws: `NepDateError` with kind `.outOfRange` or `.invalidMonth`, as
  ///   `NepaliDate.init(year:month:day:)` does.
  @inlinable
  public static func month(year: Int, month: Int) throws(NepDateError) -> NepaliDateRange {
    let first = try NepaliDate(year: year, month: month, day: 1)
    return NepaliDateRange(unchecked: first, first.lastDayOfMonth)
  }

  /// Every day of one BS year, Baishakh 1 to the last day of Chaitra.
  ///
  /// - Parameter year: The BS year, 1901 to 2199.
  /// - Returns: The range; its `count` is the year's length, 364 to 367 days (D-12).
  /// - Throws: `NepDateError` with kind `.outOfRange` for a year outside 1901...2199.
  @inlinable
  public static func year(_ year: Int) throws(NepDateError) -> NepaliDateRange {
    let first = try NepaliDate(year: year, month: 1, day: 1)
    let last = try NepaliDate(year: year, month: 12, day: 1).lastDayOfMonth
    return NepaliDateRange(unchecked: first, last)
  }

  /// The day count of ``lowerBound`` as an `Int`.
  @inlinable
  public var startIndex: Int { Int(lowerBound.serial) }

  /// One past the day count of ``upperBound`` as an `Int`.
  @inlinable
  public var endIndex: Int { Int(upperBound.serial) + 1 }

  /// The date at a day-count index.
  ///
  /// - Parameter position: An index in `startIndex..<endIndex`.
  /// - Returns: The date with that day count.
  @inlinable
  public subscript(position: Int) -> NepaliDate {
    precondition(
      position >= startIndex && position < endIndex, "index \(position) is out of bounds")
    return NepaliDate(serial: Int32(position))
  }

  /// The number of days in the range, at least 1.
  @inlinable
  public var count: Int { endIndex - startIndex }

  /// Whether `date` is in the range, in O(1).
  ///
  /// - Parameter date: The date to look for.
  /// - Returns: True when `date` is between the bounds, both included.
  @inlinable
  public func contains(_ date: NepaliDate) -> Bool {
    lowerBound <= date && date <= upperBound
  }

  /// Whether `other` lies completely inside this range.
  ///
  /// - Parameter other: The range to look for.
  /// - Returns: True when both of `other`'s bounds are in this range.
  @inlinable
  public func contains(_ other: NepaliDateRange) -> Bool {
    lowerBound <= other.lowerBound && other.upperBound <= upperBound
  }

  /// Whether the two ranges share at least one date.
  ///
  /// - Parameter other: The range to compare.
  /// - Returns: True when an end of one range is inside the other.
  @inlinable
  public func overlaps(_ other: NepaliDateRange) -> Bool {
    lowerBound <= other.upperBound && other.lowerBound <= upperBound
  }

  /// Whether one range starts the day after the other ends.
  ///
  /// A range that ends at BS 2199-12-30 has no day after it, so it is never adjacent to a later
  /// range. The mirror case before BS 1901-01-01 is also false.
  ///
  /// - Parameter other: The range to compare.
  /// - Returns: True when the two ranges touch without a gap and do not overlap.
  @inlinable
  public func isAdjacent(to other: NepaliDateRange) -> Bool {
    if upperBound < NepaliDate.max,
      NepaliDate(serial: upperBound.serial + 1) == other.lowerBound
    {
      return true
    }
    if other.upperBound < NepaliDate.max,
      NepaliDate(serial: other.upperBound.serial + 1) == lowerBound
    {
      return true
    }
    return false
  }

  /// The dates both ranges share.
  ///
  /// - Parameter other: The range to intersect with.
  /// - Returns: The overlap, or `nil` when the ranges do not overlap.
  @inlinable
  public func intersection(_ other: NepaliDateRange) -> NepaliDateRange? {
    let start = Swift.max(lowerBound, other.lowerBound)
    let end = Swift.min(upperBound, other.upperBound)
    guard start <= end else { return nil }
    return NepaliDateRange(unchecked: start, end)
  }

  /// The smallest range that covers both ranges.
  ///
  /// - Parameter other: The other range.
  /// - Returns: The range from the earlier start to the later end.
  @inlinable
  public func union(_ other: NepaliDateRange) -> NepaliDateRange {
    NepaliDateRange(
      unchecked: Swift.min(lowerBound, other.lowerBound),
      Swift.max(upperBound, other.upperBound))
  }

  /// This range with `other` removed.
  ///
  /// - Parameter other: The range to remove.
  /// - Returns: Zero, one or two ranges, in date order.
  @inlinable
  public func subtracting(_ other: NepaliDateRange) -> [NepaliDateRange] {
    guard overlaps(other) else { return [self] }
    var result: [NepaliDateRange] = []
    if lowerBound < other.lowerBound {
      result.append(
        NepaliDateRange(unchecked: lowerBound, NepaliDate(serial: other.lowerBound.serial - 1)))
    }
    if other.upperBound < upperBound {
      result.append(
        NepaliDateRange(unchecked: NepaliDate(serial: other.upperBound.serial + 1), upperBound))
    }
    return result
  }

  /// One range per BS month the range touches, clipped at both ends.
  ///
  /// The last piece ends at ``upperBound`` even when the range reaches BS 2199-12-30.
  ///
  /// - Returns: The month pieces in date order.
  public func splitByMonth() -> [NepaliDateRange] {
    var pieces: [NepaliDateRange] = []
    var start = lowerBound
    while true {
      let end = Swift.min(start.lastDayOfMonth, upperBound)
      pieces.append(NepaliDateRange(unchecked: start, end))
      if end == upperBound { return pieces }
      start = NepaliDate(serial: end.serial + 1)
    }
  }

  /// One range per fiscal quarter the range touches, clipped at both ends.
  ///
  /// The last piece ends at ``upperBound`` even when the range reaches BS 2199-12-30.
  ///
  /// - Returns: The quarter pieces in date order.
  public func splitByFiscalQuarter() -> [NepaliDateRange] {
    var pieces: [NepaliDateRange] = []
    var start = lowerBound
    while true {
      let quarterStart = start.clampedMonthShift(-(start.month - start.quarter.firstMonth))
        .firstDayOfMonth
      let quarterEnd = quarterStart.clampedMonthShift(2).lastDayOfMonth
      let end = Swift.min(quarterEnd, upperBound)
      pieces.append(NepaliDateRange(unchecked: start, end))
      if end == upperBound { return pieces }
      start = NepaliDate(serial: end.serial + 1)
    }
  }

  /// Every `interval` days from ``lowerBound``.
  ///
  /// - Parameter interval: The step in days, at least 1.
  /// - Returns: The dates in ascending order, starting at ``lowerBound``.
  /// - Throws: `NepDateError` with kind `.invalidArgument` when `interval` is below 1.
  public func dates(every interval: Int) throws(NepDateError) -> [NepaliDate] {
    guard interval >= 1 else { throw NepDateError(.invalidArgument) }
    let distance = Int(upperBound.serial - lowerBound.serial)
    let days = distance / interval + 1
    var result: [NepaliDate] = []
    result.reserveCapacity(days)
    for step in 0..<days {
      result.append(NepaliDate(serial: lowerBound.serial + Int32(step * interval)))
    }
    return result
  }

  /// Every day except Saturday, and except Sunday when asked.
  ///
  /// - Parameter excludeSunday: Whether to leave out Sunday as well.
  /// - Returns: The working days in ascending order.
  public func workingDays(excludingSunday excludeSunday: Bool = false) -> [NepaliDate] {
    var result: [NepaliDate] = []
    for offset in 0...(Int(upperBound.serial) - Int(lowerBound.serial)) {
      let date = NepaliDate(serial: lowerBound.serial + Int32(offset))
      let weekday = date.weekday
      if weekday == .saturday { continue }
      if excludeSunday && weekday == .sunday { continue }
      result.append(date)
    }
    return result
  }

  /// Every Saturday, and Sunday when asked.
  ///
  /// - Parameter includeSunday: Whether to include Sunday as well.
  /// - Returns: The weekend days in ascending order.
  public func weekendDays(includingSunday includeSunday: Bool = true) -> [NepaliDate] {
    var result: [NepaliDate] = []
    for offset in 0...(Int(upperBound.serial) - Int(lowerBound.serial)) {
      let date = NepaliDate(serial: lowerBound.serial + Int32(offset))
      let weekday = date.weekday
      if weekday == .saturday || (includeSunday && weekday == .sunday) { result.append(date) }
    }
    return result
  }

  /// The two bounds as `2081/04/10 - 2081/04/20`.
  public var description: String {
    "\(lowerBound) - \(upperBound)"
  }

  /// The two bounds in the requested short form, separated by ` - `.
  ///
  /// - Parameters:
  ///   - order: The order of year, month and day.
  ///   - separator: The character between the numbers.
  ///   - lang: ASCII or Devanagari digits.
  /// - Returns: The formatted range.
  public func formatted(
    order: DateOrder = .ymd, separator: Separator = .slash, lang: Lang = .english
  ) -> String {
    var output = ""
    lowerBound.appendShort(to: &output, order: order, separator: separator, lang: lang)
    output += " - "
    upperBound.appendShort(to: &output, order: order, separator: separator, lang: lang)
    return output
  }
}
