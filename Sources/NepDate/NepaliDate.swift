/// A Bikram Sambat date from BS 1901-01-01 to 2199-12-30 (AD 1844-04-11 to 2143-04-15).
///
/// Every value is a valid date: the initialisers throw instead of building an invalid one (D-01).
/// The value is 8 bytes and holds both the day count since BS 1901-01-01 and the year, month and
/// day, so conversions and comparisons read no table (ADR-0002 §1).
public struct NepaliDate: Sendable, BitwiseCopyable, Hashable, Comparable {
  /// Days since BS 1901-01-01, 0...109211 (ALGORITHM §2).
  @usableFromInline package let serial: Int32
  @usableFromInline let y: Int16
  @usableFromInline let m: UInt8
  @usableFromInline let d: UInt8

  /// The first supported date, BS 1901-01-01.
  public static let min = NepaliDate(serial: 0)

  /// The last supported date, BS 2199-12-30.
  public static let max = NepaliDate(serial: CalendarData.maxSerial)

  /// Stores fields the caller has already checked; `serial` is the serial of the date.
  @inlinable
  init(serial: Int32, year: Int, month: Int, day: Int) {
    self.serial = serial
    // The callers' checks keep year in 1901...2199, month in 1...12 and day in 1...32.
    self.y = Int16(truncatingIfNeeded: year)
    self.m = UInt8(truncatingIfNeeded: month)
    self.d = UInt8(truncatingIfNeeded: day)
  }

  /// The date `serial` days after BS 1901-01-01. `serial` must be in 0...109211.
  ///
  /// One bucket load gives the month of the bucket's first day. A 16-day bucket is shorter than
  /// any month, so the date is in that month or the next (ADR-0002 §2).
  @inlinable
  init(serial: Int32) {
    let monthStart = CalendarData.monthStart
    var i = Int(CalendarData.monthAtBucket[Int(serial >> 4)])
    if serial >= monthStart[i + 1] { i += 1 }
    self.init(
      serial: serial, year: CalendarData.minYear + i / 12, month: i % 12 + 1,
      day: Int(serial - monthStart[i]) + 1)
  }

  /// Creates the BS date `year`-`month`-`day`.
  ///
  /// The checks run in the order of ALGORITHM §3: year, then month, then day.
  ///
  /// - Parameters:
  ///   - year: The BS year, 1901 to 2199.
  ///   - month: The month, 1 (Baishakh) to 12 (Chaitra).
  ///   - day: The day, 1 to the month's length (29 to 32).
  /// - Throws: `NepDateError` with kind `.outOfRange` for a year outside 1901...2199,
  ///   `.invalidMonth` for a month outside 1...12, and `.invalidDay(monthLength:)` for a day
  ///   outside the month.
  @inlinable
  public init(year: Int, month: Int, day: Int) throws(NepDateError) {
    guard year >= CalendarData.minYear, year <= CalendarData.maxYear else {
      throw NepDateError(.outOfRange)
    }
    guard month >= 1, month <= 12 else { throw NepDateError(.invalidMonth) }
    let index = (year - CalendarData.minYear) * 12 + month - 1
    let start = CalendarData.monthStart[index]
    let length = Int(CalendarData.monthStart[index + 1] - start)
    guard day >= 1, day <= length else { throw NepDateError(.invalidDay(monthLength: length)) }
    self.init(serial: start + Int32(day - 1), year: year, month: month, day: day)
  }

  /// Creates the BS date of an AD (Gregorian) date.
  ///
  /// - Parameters:
  ///   - gregorianYear: The AD year.
  ///   - month: The AD month, 1 to 12.
  ///   - day: The AD day of the month.
  /// - Throws: `NepDateError` with kind `.invalidGregorian` when the AD date does not exist
  ///   (checked first), and `.outOfRange` when it is outside AD 1844-04-11 to 2143-04-15.
  @inlinable
  public init(gregorianYear: Int, month: Int, day: Int) throws(NepDateError) {
    guard day >= 1, day <= gregorianMonthLength(gregorianYear, month) else {
      throw NepDateError(.invalidGregorian)
    }
    guard gregorianYear >= 1844, gregorianYear <= 2143 else { throw NepDateError(.outOfRange) }
    let serial =
      daysFromCivil(Int32(gregorianYear), Int32(month), Int32(day)) - CalendarData.epochUnixDays
    guard serial >= 0, serial <= CalendarData.maxSerial else { throw NepDateError(.outOfRange) }
    self.init(serial: serial)
  }

  /// The BS year, 1901 to 2199.
  @inlinable
  public var year: Int { Int(y) }

  /// The month number, 1 (Baishakh) to 12 (Chaitra).
  @inlinable
  public var month: Int { Int(m) }

  /// The day of the month, 1 to 32.
  @inlinable
  public var day: Int { Int(d) }

  /// The month as a ``Month``.
  @inlinable
  public var bsMonth: Month {
    // m is always 1...12, so the fallback is never taken.
    Month(rawValue: Int(m)) ?? .baishakh
  }

  /// The day of the week (ALGORITHM §7).
  @inlinable
  public var weekday: Weekday {
    // BS 1901-01-01 was a Thursday (4). serial <= 109211, so serial + 4 can't overflow, and the
    // remainder is 0...6, so the fallback is never taken.
    Weekday(rawValue: Int((serial &+ 4) % 7)) ?? .sunday
  }

  /// The day of the BS year: 1 for Baishakh 1, and 364 to 367 for the last day of the year.
  @inlinable
  public var dayOfYear: Int {
    Int(serial - CalendarData.monthStart[(Int(y) - CalendarData.minYear) * 12]) + 1
  }

  /// The number of days in this date's month, 29 to 32.
  @inlinable
  public var monthLength: Int {
    let index = monthIndex
    return Int(CalendarData.monthStart[index + 1] - CalendarData.monthStart[index])
  }

  /// Day 1 of this date's month.
  @inlinable
  public var firstDayOfMonth: NepaliDate {
    NepaliDate(serial: serial - Int32(d) + 1, year: year, month: month, day: 1)
  }

  /// The last day of this date's month.
  @inlinable
  public var lastDayOfMonth: NepaliDate {
    let length = monthLength
    return NepaliDate(
      serial: serial + Int32(length - Int(d)), year: year, month: month, day: length)
  }

  /// The AD (proleptic Gregorian) date.
  @inlinable
  public var gregorian: (year: Int, month: Int, day: Int) {
    // serial is 0...109211, so the sum is -45920...63291.
    let date = civilFromDays(serial &+ CalendarData.epochUnixDays)
    return (Int(date.year), Int(date.month), Int(date.day))
  }

  /// Index of this date's month in `CalendarData.monthStart`.
  @inlinable
  var monthIndex: Int { (Int(y) - CalendarData.minYear) * 12 + Int(m) - 1 }

  /// Two dates are equal when they are the same day.
  @inlinable
  public static func == (lhs: NepaliDate, rhs: NepaliDate) -> Bool {
    lhs.serial == rhs.serial
  }

  /// Orders dates by day, earlier first.
  @inlinable
  public static func < (lhs: NepaliDate, rhs: NepaliDate) -> Bool {
    lhs.serial < rhs.serial
  }

  /// Hashes the day count only, so equal dates hash equally.
  ///
  /// - Parameter hasher: The hasher to feed.
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(serial)
  }
}
