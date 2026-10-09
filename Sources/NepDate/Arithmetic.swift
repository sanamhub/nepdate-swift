/// What `adding(months:overflow:)` does when the day doesn't exist in the target month
/// (ALGORITHM §8).
public enum MonthOverflow: Sendable {
  /// Use the target month's last day: 2081-04-32 plus 2 months is 2081-06-30.
  case clamp
  /// Carry the extra days into the next month: 2081-04-32 plus 2 months is 2081-07-02.
  case spill
}

/// A calendar breakdown of the days between two dates (ALGORITHM §8a).
public struct DateDiff: Sendable, Hashable {
  /// True when the other date is earlier; the breakdown is then of the swapped pair.
  public let isNegative: Bool
  /// Whole years.
  public let years: Int
  /// Whole months after the years, 0 to 11.
  public let months: Int
  /// Days after the months, 0 to 32.
  public let days: Int
  /// The signed day difference, the same as `days(until:)`.
  public let totalDays: Int

  @usableFromInline
  init(isNegative: Bool, years: Int, months: Int, days: Int, totalDays: Int) {
    self.isNegative = isNegative
    self.years = years
    self.months = months
    self.days = days
    self.totalDays = totalDays
  }
}

extension NepaliDate {
  /// Number of months in the supported range, 299 years of 12.
  @usableFromInline
  static var monthCount: Int { (CalendarData.maxYear - CalendarData.minYear + 1) * 12 }

  /// The date `days` days later, or earlier for a negative count.
  ///
  /// - Parameter days: The number of days to add.
  /// - Returns: The new date.
  /// - Throws: `NepDateError` with kind `.outOfRange` when the result is outside the range.
  @inlinable
  public func adding(days: Int) throws(NepDateError) -> NepaliDate {
    // Compared against the distances to the ends, so no sum is formed before the check and
    // `Int.max` or `Int.min` can't overflow.
    let current = Int(serial)
    guard days >= -current, days <= Int(CalendarData.maxSerial) - current else {
      throw NepDateError(.outOfRange)
    }
    return NepaliDate(serial: Int32(truncatingIfNeeded: current + days))
  }

  /// The signed number of days from this date to `other`: positive when `other` is later (D-07).
  ///
  /// - Parameter other: The date to count to.
  /// - Returns: `other` minus this date, in days.
  @inlinable
  public func days(until other: NepaliDate) -> Int {
    Int(other.serial) - Int(serial)
  }

  /// The date `months` months later, or earlier for a negative count (ALGORITHM §8).
  ///
  /// - Parameters:
  ///   - months: The number of months to add.
  ///   - overflow: What to do when the day doesn't exist in the target month.
  /// - Returns: The new date.
  /// - Throws: `NepDateError` with kind `.outOfRange` when the result is outside the range.
  @inlinable
  public func adding(months: Int, overflow: MonthOverflow = .clamp) throws(NepDateError)
    -> NepaliDate
  {
    let current = monthIndex
    // Compared against the distances to the ends, so `current + months` can't overflow.
    guard months >= -current, months < Self.monthCount - current else {
      throw NepDateError(.outOfRange)
    }
    let target = current + months
    let start = CalendarData.monthStart[target]
    let length = Int(CalendarData.monthStart[target + 1] - start)
    let day = Int(d)
    if day <= length {
      return NepaliDate(
        serial: start + Int32(day - 1), year: CalendarData.minYear + target / 12,
        month: target % 12 + 1, day: day)
    }
    switch overflow {
    case .clamp:
      return NepaliDate(
        serial: start + Int32(length - 1), year: CalendarData.minYear + target / 12,
        month: target % 12 + 1, day: length)
    case .spill:
      // The next month after Chaitra 2199 is past the range (ALGORITHM §8: y3 > MAX_YEAR).
      let next = target + 1
      guard next < Self.monthCount else { throw NepDateError(.outOfRange) }
      // Day `day - length` of the next month is `day - 1` days after this month's start.
      return NepaliDate(
        serial: start + Int32(day - 1), year: CalendarData.minYear + next / 12,
        month: next % 12 + 1, day: day - length)
    }
  }

  /// The date `years` years later, or earlier for a negative count; `adding(months: 12 * years)`.
  ///
  /// - Parameters:
  ///   - years: The number of years to add.
  ///   - overflow: What to do when the day doesn't exist in the target month.
  /// - Returns: The new date.
  /// - Throws: `NepDateError` with kind `.outOfRange` when the result is outside the range.
  @inlinable
  public func adding(years: Int, overflow: MonthOverflow = .clamp) throws(NepDateError)
    -> NepaliDate
  {
    // The range is 299 years, so a larger count is out of range, and 12 * years can't overflow.
    guard years >= -299, years <= 299 else { throw NepDateError(.outOfRange) }
    return try adding(months: 12 * years, overflow: overflow)
  }

  /// The years, months and days from this date to `other` (ALGORITHM §8a).
  ///
  /// - Parameter other: The date to measure to.
  /// - Returns: The breakdown. When `other` is earlier, `isNegative` is true and the breakdown is
  ///   from `other` to this date.
  @inlinable
  public func diff(to other: NepaliDate) -> DateDiff {
    let isNegative = other < self
    let a = isNegative ? other : self
    let b = isNegative ? self : other
    // ALGORITHM §8a hint: start at the month difference and step down. Adding n0 months lands in
    // b's month, and is after b only when a's day is later than b's, so one step is the most.
    var n = b.monthIndex - a.monthIndex
    var shifted = a.clampedMonthShift(n)
    if shifted > b {
      n -= 1
      shifted = a.clampedMonthShift(n)
    }
    return DateDiff(
      isNegative: isNegative, years: n / 12, months: n % 12, days: shifted.days(until: b),
      totalDays: days(until: other))
  }

  /// `adding(months: n, overflow: .clamp)` for an `n` the caller knows is in range.
  @inlinable
  func clampedMonthShift(_ n: Int) -> NepaliDate {
    let target = monthIndex + n
    let start = CalendarData.monthStart[target]
    let day = Swift.min(Int(d), Int(CalendarData.monthStart[target + 1] - start))
    return NepaliDate(
      serial: start + Int32(day - 1), year: CalendarData.minYear + target / 12,
      month: target % 12 + 1, day: day)
  }
}
