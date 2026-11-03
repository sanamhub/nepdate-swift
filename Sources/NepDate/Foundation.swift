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
    /// whichever is nearer, because this function can't throw (hub PORT-PLAN).
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

    /// Whether this date is today in `timeZone`.
    ///
    /// - Parameter timeZone: The zone whose calendar date defines today.
    /// - Returns: True when the two dates are equal.
    public func isToday(in timeZone: TimeZone) -> Bool {
      isToday(in: timeZone, now: Date())
    }

    /// ``isToday(in:)`` with an injected clock, for tests.
    func isToday(in timeZone: TimeZone, now: Date) -> Bool {
      self == NepaliDate.today(in: timeZone, now: now)
    }

    /// Whether this date is yesterday in `timeZone`.
    ///
    /// The day before ``min`` cannot exist, so the boundary date is never yesterday.
    ///
    /// - Parameter timeZone: The zone whose calendar date defines today.
    /// - Returns: True when the two dates are one day apart.
    public func isYesterday(in timeZone: TimeZone) -> Bool {
      isYesterday(in: timeZone, now: Date())
    }

    /// ``isYesterday(in:)`` with an injected clock, for tests.
    func isYesterday(in timeZone: TimeZone, now: Date) -> Bool {
      guard let yesterday = try? NepaliDate.today(in: timeZone, now: now).adding(days: -1) else {
        return false
      }
      return self == yesterday
    }

    /// Whether this date is tomorrow in `timeZone`.
    ///
    /// The day after ``max`` cannot exist, so the boundary date is never tomorrow.
    ///
    /// - Parameter timeZone: The zone whose calendar date defines today.
    /// - Returns: True when the two dates are one day apart.
    public func isTomorrow(in timeZone: TimeZone) -> Bool {
      isTomorrow(in: timeZone, now: Date())
    }

    /// ``isTomorrow(in:)`` with an injected clock, for tests.
    func isTomorrow(in timeZone: TimeZone, now: Date) -> Bool {
      guard let tomorrow = try? NepaliDate.today(in: timeZone, now: now).adding(days: 1) else {
        return false
      }
      return self == tomorrow
    }

    /// Converts every Gregorian instant to the BS date it falls on in `timeZone`, in input order.
    ///
    /// C# `BulkConvert.ToNepaliDates` switches to PLINQ above 500 items and does not promise
    /// order; this function always keeps the input order.
    ///
    /// - Parameters:
    ///   - dates: The instants to convert.
    ///   - timeZone: The zone whose calendar dates are wanted.
    /// - Returns: One BS date per input, in input order.
    /// - Throws: `NepDateError` with kind `.outOfRange` for the first input outside the supported
    ///   span.
    public static func fromGregorian(
      _ dates: some Sequence<Date>, in timeZone: TimeZone
    ) throws(NepDateError) -> [NepaliDate] {
      var result: [NepaliDate] = []
      result.reserveCapacity(dates.underestimatedCount)
      for date in dates { result.append(try NepaliDate(date, in: timeZone)) }
      return result
    }

    /// Parses every string and returns its Gregorian midnight in `timeZone`, in input order.
    ///
    /// The first invalid string stops the call; the returned dates are all before it.
    ///
    /// - Parameters:
    ///   - strings: BS dates in the strict parse form.
    ///   - timeZone: The zone whose midnights are wanted.
    /// - Returns: One Gregorian instant per input, in input order.
    /// - Throws: `NepDateError` from ``parse(_:)`` for the first invalid string.
    public static func gregorianDates(
      from strings: some Sequence<String>, in timeZone: TimeZone
    ) throws(NepDateError) -> [Date] {
      var result: [Date] = []
      result.reserveCapacity(strings.underestimatedCount)
      for string in strings { result.append(try NepaliDate.parse(string).date(in: timeZone)) }
      return result
    }

    /// Returns the Gregorian midnight of every date in `timeZone`, in input order.
    ///
    /// - Parameters:
    ///   - dates: The BS dates to convert.
    ///   - timeZone: The zone whose midnights are wanted.
    /// - Returns: One Gregorian instant per input, in input order.
    public static func gregorianDates(
      from dates: some Sequence<NepaliDate>, in timeZone: TimeZone
    ) -> [Date] {
      dates.map { $0.date(in: timeZone) }
    }
  }

  extension NepaliDateRange {
    /// Every day of the BS month that contains today in `timeZone`.
    ///
    /// - Parameter timeZone: The zone whose calendar date defines today.
    /// - Returns: The month's range.
    /// - Throws: `NepDateError` with kind `.outOfRange` only when the clock clamps to
    ///   ``NepaliDate/min``.
    public static func currentMonth(in timeZone: TimeZone) throws(NepDateError) -> NepaliDateRange {
      try currentMonth(in: timeZone, now: Date())
    }

    /// ``currentMonth(in:)`` with an injected clock, for tests.
    static func currentMonth(in timeZone: TimeZone, now: Date) throws(NepDateError)
      -> NepaliDateRange
    {
      let today = NepaliDate.today(in: timeZone, now: now)
      return try NepaliDateRange.month(year: today.year, month: today.month)
    }

    /// Every day of the fiscal year that contains today in `timeZone`.
    ///
    /// - Parameter timeZone: The zone whose calendar date defines today.
    /// - Returns: The fiscal year's range.
    /// - Throws: `NepDateError` with kind `.outOfRange` when the clock clamps outside the fiscal
    ///   years the data supports.
    public static func currentFiscalYear(in timeZone: TimeZone) throws(NepDateError)
      -> NepaliDateRange
    {
      try currentFiscalYear(in: timeZone, now: Date())
    }

    /// ``currentFiscalYear(in:)`` with an injected clock, for tests.
    static func currentFiscalYear(in timeZone: TimeZone, now: Date) throws(NepDateError)
      -> NepaliDateRange
    {
      try NepaliDate.today(in: timeZone, now: now).fiscalYear.range()
    }

    /// Every day of the BS calendar year that contains today in `timeZone`.
    ///
    /// - Parameter timeZone: The zone whose calendar date defines today.
    /// - Returns: The calendar year's range.
    /// - Throws: `NepDateError` with kind `.outOfRange` only when the clock clamps to
    ///   ``NepaliDate/min``.
    public static func currentCalendarYear(in timeZone: TimeZone) throws(NepDateError)
      -> NepaliDateRange
    {
      try currentCalendarYear(in: timeZone, now: Date())
    }

    /// ``currentCalendarYear(in:)`` with an injected clock, for tests.
    static func currentCalendarYear(in timeZone: TimeZone, now: Date) throws(NepDateError)
      -> NepaliDateRange
    {
      try NepaliDateRange.year(NepaliDate.today(in: timeZone, now: now).year)
    }
  }

  extension NepaliDate {
    /// A reusable format for ``NepaliDate/formatted(_:)`` and for SwiftUI's `Text`.
    ///
    /// The style holds the same choices as ``NepaliDate/short(order:separator:pad:lang:)`` and
    /// ``NepaliDate/long(weekday:year:pad:lang:)`` in one value, so a view can pass it around or
    /// store it. It conforms to `FormatStyle`, so `Text(date, format: style)` and
    /// `date.formatted(style)` both work.
    public struct FormatStyle: Sendable, Hashable, Codable {
      /// Which of the two built-in formats to write.
      public enum Form: Sendable, Hashable, Codable {
        /// The three numbers in ``NepaliDate/FormatStyle/order``, separated by
        /// ``NepaliDate/FormatStyle/separator``.
        case short
        /// The long form with names and the optional weekday and year.
        case long
      }

      /// Which format to write.
      public var form: Form

      /// The order of year, month and day in the short form.
      public var order: DateOrder

      /// The character between the numbers in the short form.
      public var separator: Separator

      /// The language of names and digits.
      public var language: Lang

      /// Whether the long form starts with the weekday's name.
      public var weekday: Bool

      /// Whether the long form ends with the year.
      public var year: Bool

      /// Whether the day gets two digits, and the short form's month too.
      public var pad: Bool

      /// Creates a style.
      ///
      /// - Parameters:
      ///   - form: Which format to write.
      ///   - order: The order of year, month and day in the short form.
      ///   - separator: The character between the numbers in the short form.
      ///   - language: The language of names and digits.
      ///   - weekday: Whether the long form starts with the weekday's name.
      ///   - year: Whether the long form ends with the year.
      ///   - pad: Whether the day gets two digits, and the short form's month too.
      public init(
        form: Form = .short, order: DateOrder = .ymd, separator: Separator = .slash,
        language: Lang = .english, weekday: Bool = false, year: Bool = true, pad: Bool = true
      ) {
        self.form = form
        self.order = order
        self.separator = separator
        self.language = language
        self.weekday = weekday
        self.year = year
        self.pad = pad
      }

      /// The short style, `2081/04/15` in English.
      public static var short: FormatStyle { FormatStyle() }

      /// The long style, `Shrawan 15, 2081` in English.
      public static var long: FormatStyle { FormatStyle(form: .long) }

      /// Formats `value` with this style.
      ///
      /// - Parameter value: The date to format.
      /// - Returns: The formatted date.
      public func format(_ value: NepaliDate) -> String {
        switch form {
        case .short:
          return value.short(order: order, separator: separator, pad: pad, lang: language)
        case .long:
          return value.long(weekday: weekday, year: year, pad: pad, lang: language)
        }
      }
    }

    /// Formats this date with `style`.
    ///
    /// - Parameter style: The style to use.
    /// - Returns: The formatted date.
    public func formatted(_ style: FormatStyle) -> String {
      style.format(self)
    }

    /// Formats this date as `2081/04/15`.
    ///
    /// - Returns: The default short form.
    public func formatted() -> String {
      formatted(FormatStyle())
    }
  }

  extension NepaliDate.FormatStyle: Foundation.FormatStyle {}
#endif
