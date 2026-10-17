#if canImport(Foundation)
  import Foundation

  // `Date` and `TimeZone` interop (ADR-0001 §4). No `Calendar`, no `DateFormatter`: the floor of
  // local seconds divided by 86,400 is a Unix day, and a Unix day minus `epochUnixDays` is a
  // serial.

  extension NepaliDate {
    /// Creates the BS date that `date` falls on in `timeZone`.
    ///
    /// - Parameters:
    ///   - date: The instant to convert.
    ///   - timeZone: The zone whose calendar date is wanted.
    /// - Throws: `NepDateError` with kind `.outOfRange` when that calendar date is outside
    ///   AD 1844-04-11 to 2143-04-15.
    public init(_ date: Date, in timeZone: TimeZone) throws(NepDateError) {
      let offset = timeZone.secondsFromGMT(for: date)
      guard let serial = Self.localSerial(at: date, offset: offset) else {
        throw NepDateError(.outOfRange)
      }
      self.init(serial: serial)
    }

    /// The instant this date starts in `timeZone`, its local midnight.
    ///
    /// The offset is read at UTC midnight first and once more at the result, so a daylight-saving
    /// change between the two midnights is taken into account.
    ///
    /// - Parameter timeZone: The zone whose midnight is wanted.
    /// - Returns: The first instant of this date in `timeZone`.
    public func date(in timeZone: TimeZone) -> Date {
      // serial is 0...109211, so the Unix day is -45920...63291 and fits easily.
      let utcMidnight = Double(Int(serial) + Int(CalendarData.epochUnixDays)) * 86_400
      let firstOffset = timeZone.secondsFromGMT(for: Date(timeIntervalSince1970: utcMidnight))
      let guess = Date(timeIntervalSince1970: utcMidnight - Double(firstOffset))
      return Date(timeIntervalSince1970: utcMidnight - Double(timeZone.secondsFromGMT(for: guess)))
    }

    /// The current BS date in a time zone.
    ///
    /// When the clock is outside AD 1844-04-11 to 2143-04-15 the result is ``min`` or ``max``,
    /// whichever is nearer, because this function can't throw (PORT-PLAN phase 4).
    ///
    /// - Parameter timeZone: The zone whose calendar date is wanted. `nil` means Nepal:
    ///   `Asia/Kathmandu`, or a fixed UTC+05:45 when the zone database lacks it.
    /// - Returns: Today's date in that zone.
    public static func today(in timeZone: TimeZone? = nil) -> NepaliDate {
      today(in: timeZone, now: Date())
    }

    /// ``today(in:)`` with an injected clock and zone lookup, for tests.
    static func today(
      in timeZone: TimeZone?, now: Date,
      lookup: (String) -> TimeZone? = { TimeZone(identifier: $0) }
    ) -> NepaliDate {
      let offset = timeZone?.secondsFromGMT(for: now) ?? nepalOffset(at: now, lookup: lookup)
      if let serial = localSerial(at: now, offset: offset) { return NepaliDate(serial: serial) }
      return now.timeIntervalSince1970 < 0 ? .min : .max
    }

    /// Nepal's offset from UTC in seconds at `now`: `Asia/Kathmandu` from `lookup`, or 20,700
    /// (UTC+05:45) when `lookup` doesn't know the zone.
    static func nepalOffset(at now: Date, lookup: (String) -> TimeZone?) -> Int {
      lookup("Asia/Kathmandu")?.secondsFromGMT(for: now) ?? 20_700
    }

    /// The serial of the local calendar date of `date` at `offset` seconds from UTC, or `nil`
    /// outside the supported range.
    static func localSerial(at date: Date, offset: Int) -> Int32? {
      let seconds = date.timeIntervalSince1970 + Double(offset)
      // Floor division: a time before 1970 has a negative Unix day. A NaN fails both checks.
      let serial = (seconds / 86_400).rounded(.down) - Double(CalendarData.epochUnixDays)
      guard serial >= 0, serial <= Double(CalendarData.maxSerial) else { return nil }
      return Int32(serial)
    }
  }
#endif
