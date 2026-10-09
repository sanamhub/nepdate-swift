/// An inclusive range of dates, from ``lowerBound`` to ``upperBound`` (D-09).
///
/// The range is a `RandomAccessCollection` indexed by day count, so `count` and `contains(_:)`
/// are O(1) and SwiftUI's `ForEach` and `for in` read it without copying.
public struct NepaliDateRange: RandomAccessCollection, Sendable, Hashable {
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

  /// Stores bounds the caller knows are in order.
  @inlinable
  init(unchecked start: NepaliDate, _ end: NepaliDate) {
    lowerBound = start
    upperBound = end
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

  /// The day count of ``lowerBound``.
  @inlinable
  public var startIndex: Int32 { lowerBound.serial }

  /// One past the day count of ``upperBound``.
  @inlinable
  public var endIndex: Int32 { upperBound.serial + 1 }

  /// The date at a day-count index.
  ///
  /// - Parameter position: An index in `startIndex..<endIndex`.
  /// - Returns: The date with that day count.
  @inlinable
  public subscript(position: Int32) -> NepaliDate {
    NepaliDate(serial: position)
  }

  /// The number of days in the range, at least 1.
  @inlinable
  public var count: Int { Int(endIndex - startIndex) }

  /// Whether `date` is in the range, in O(1).
  ///
  /// - Parameter date: The date to look for.
  /// - Returns: True when `date` is between the bounds, both included.
  @inlinable
  public func contains(_ date: NepaliDate) -> Bool {
    lowerBound <= date && date <= upperBound
  }
}
