import NepDate

/// A tithi or event name: a 2-byte id into the generated name table (ADR-0002 §3).
public struct Named: Sendable, Hashable {
  /// Index into `PatroData.name(_:)`.
  @usableFromInline let id: UInt16

  @inlinable
  init(id: UInt16) {
    self.id = id
  }

  /// The name in Nepali (Devanagari).
  public var nepali: String { PatroData.name(id).nepali }

  /// The name in English (Latin letters).
  public var english: String { PatroData.name(id).english }

  /// The name in one language.
  ///
  /// - Parameter lang: `.nepali` for ``nepali``, `.english` for ``english``.
  /// - Returns: The name in that language.
  public func name(_ lang: Lang = .english) -> String {
    lang == .nepali ? nepali : english
  }
}

/// The events of one day, in display order (PATRO §1). Reading them allocates nothing.
public struct PatroEvents: RandomAccessCollection, Sendable, Hashable {
  /// Offset of the first event in `PatroData.eventNameIDs`.
  @usableFromInline let start: UInt16
  /// Offset one past the last event.
  @usableFromInline let end: UInt16

  @inlinable
  init(start: UInt16, end: UInt16) {
    self.start = start
    self.end = end
  }

  /// Always 0.
  @inlinable
  public var startIndex: Int { 0 }

  /// The number of events.
  @inlinable
  public var endIndex: Int { Int(end) - Int(start) }

  /// The event at a position.
  ///
  /// - Parameter position: An index in `startIndex..<endIndex`.
  /// - Returns: The event's name.
  @inlinable
  public subscript(position: Int) -> Named {
    Named(id: PatroData.eventNameIDs[Int(start) + position])
  }

  /// Two lists are equal when they hold the same names in the same order.
  ///
  /// - Parameters:
  ///   - lhs: One list.
  ///   - rhs: The other list.
  /// - Returns: True when the names match in order.
  @inlinable
  public static func == (lhs: PatroEvents, rhs: PatroEvents) -> Bool {
    lhs.elementsEqual(rhs)
  }

  /// Hashes the names in order, so equal lists hash equally.
  ///
  /// - Parameter hasher: The hasher to feed.
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(count)
    for name in self { hasher.combine(name) }
  }
}

/// The patro data of one day (PATRO §2).
public struct CalendarInfo: Sendable, Hashable {
  /// The tithi (lunar day), or `nil` when the data has none for the day.
  public let tithi: Named?
  /// Whether the day is a gazetted public holiday.
  public let isPublicHoliday: Bool
  /// The day's events in display order; empty when there are none.
  public let events: PatroEvents

  @inlinable
  init(tithi: Named?, isPublicHoliday: Bool, events: PatroEvents) {
    self.tithi = tithi
    self.isPublicHoliday = isPublicHoliday
    self.events = events
  }
}

extension NepaliDate {
  /// The tithi, public holiday flag and events of this date (PATRO §2).
  ///
  /// One subtraction, one bounds check and three table reads; no search and no allocation. A date
  /// outside ``Patro/coverage`` gives no tithi, no holiday and no events.
  @inlinable
  public var calendarInfo: CalendarInfo {
    // serial is 0...109211, so the difference fits in Int32.
    let k = Int(serial &- PatroData.coverageFirst)
    guard UInt(bitPattern: k) < UInt(PatroData.dayInfo.count) else {
      return CalendarInfo(tithi: nil, isPublicHoliday: false, events: PatroEvents(start: 0, end: 0))
    }
    let info = PatroData.dayInfo[k]
    let tithi = info & 0x3F
    return CalendarInfo(
      // tithi is 1...63 here, so tithi - 1 can't wrap.
      tithi: tithi == 0 ? nil : Named(id: UInt16(tithi &- 1)),
      isPublicHoliday: info & 0x80 != 0,
      // k < dayInfo.count and dayEventStart has one entry more, so k + 1 is in bounds.
      events: PatroEvents(start: PatroData.dayEventStart[k], end: PatroData.dayEventStart[k &+ 1]))
  }
}

/// Queries over the whole patro data set (PATRO §2).
public enum Patro {
  /// The smallest range holding every day with patro data, BS 2077-01-01 to 2084-08-20.
  public static var coverage: NepaliDateRange {
    NepaliDateRange(
      unchecked: NepaliDate(serial: PatroData.coverageFirst),
      NepaliDate(serial: PatroData.coverageLast))
  }

  /// Every public holiday in the data, in ascending order, found by scanning the day table.
  public static var publicHolidays: some Sequence<NepaliDate> {
    PatroData.dayInfo.indices.lazy.filter { PatroData.dayInfo[$0] & 0x80 != 0 }.map {
      // $0 < dayInfo.count = 2,793, so the sum stays inside the covered serials.
      NepaliDate(serial: PatroData.coverageFirst &+ Int32($0))
    }
  }
}
