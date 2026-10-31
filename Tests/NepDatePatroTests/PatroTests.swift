import NepDate
import Testing

@testable import NepDatePatro

@Suite("Patro")
struct PatroTests {
  @Test("generated table sizes match the hub's patro summary")
  func tableSizes() throws {
    let summary = try PatroSummary()
    #expect(PatroData.dayInfo.count == summary.days)
    #expect(PatroData.dayEventStart.count == summary.days + 1)
    #expect(PatroData.dayEventStart.first == 0)
    #expect(Int(PatroData.dayEventStart.last ?? 0) == summary.events)
    #expect(PatroData.eventNameIDs.count == summary.events)
    #expect(Int(PatroData.coverageLast - PatroData.coverageFirst) + 1 == summary.days)
    #expect(PatroData.dayInfo.filter { $0 & 0x80 != 0 }.count == summary.holidays)
    #expect(PatroData.dayInfo.filter { $0 & 0x3F != 0 }.count == summary.tithiDays)
    #expect(PatroData.dayInfo.allSatisfy { $0 & 0x40 == 0 })
  }

  @Test("every name id resolves, and the tithi names come first")
  func names() throws {
    let summary = try PatroSummary()
    let count = try #require(UInt16(exactly: summary.names), "\(summary.names) names")
    for id in UInt16(0)..<count {
      let name = PatroData.name(id)
      #expect(!name.nepali.isEmpty && !name.english.isEmpty, "name \(id)")
    }
    #expect(PatroData.name(count).nepali.isEmpty && PatroData.name(count).english.isEmpty)
    let tithiIDs = Set(PatroData.dayInfo.map { $0 & 0x3F }.filter { $0 != 0 })
    #expect(tithiIDs.count == summary.tithiNames)
    #expect(tithiIDs.max().map(Int.init) == summary.tithiNames)
    #expect(PatroData.eventNameIDs.allSatisfy { $0 < count })
  }

  @Test("name text and bytes match the hub's patro summary")
  func nameText() throws {
    let summary = try PatroSummary()
    let count = try #require(UInt16(exactly: summary.names), "\(summary.names) names")
    var bytes = 0
    var pairs = Set<String>()
    for id in UInt16(0)..<count {
      let name = PatroData.name(id)
      bytes += name.nepali.utf8.count + name.english.utf8.count
      // A NUL byte separates the two halves; the generator rejects control characters in names.
      pairs.insert("\(name.nepali)\u{0}\(name.english)")
    }
    #expect(bytes == summary.nameBytes)
    #expect(pairs.count == summary.names)
    // Event names are a subset of the pool; the summary counts their distinct pairs.
    var eventPairs = Set<String>()
    for event in PatroData.eventNameIDs {
      let name = PatroData.name(event)
      eventPairs.insert("\(name.nepali)\u{0}\(name.english)")
    }
    #expect(eventPairs.count == summary.eventNames)
  }

  struct Anchor: Sendable, CustomTestStringConvertible {
    let date: (Int, Int, Int)
    let tithi: String?
    let holiday: Bool
    let events: [String]
    var testDescription: String { "\(date)" }
  }

  static let anchors = [
    Anchor(
      date: (2081, 1, 1), tithi: "Panchami", holiday: true,
      events: ["New Year", "Mesh Sankranti", "Bisket Jatra"]),
    Anchor(date: (2081, 1, 2), tithi: "Shashthi", holiday: false, events: []),
    Anchor(date: (2081, 2, 15), tithi: "Panchami", holiday: true, events: ["Republic Day"]),
    Anchor(
      date: (2080, 11, 1), tithi: "Chaturthi", holiday: false,
      events: [
        "Mangala Chauthi Brata", "People's War Day", "Tilakund Chauthi", "Kumbha Sankranti",
        "World Radio Day",
      ]),
    Anchor(
      date: (2081, 4, 15), tithi: "Dashami", holiday: false,
      events: [
        "Kheer Khane Din", "World Day Against Human Trafficking", "International Friendship Day",
      ]),
    Anchor(date: (2070, 6, 15), tithi: nil, holiday: false, events: []),
    Anchor(date: (2090, 1, 1), tithi: nil, holiday: false, events: []),
  ]

  @Test("PATRO §4 anchors", arguments: anchors)
  func anchor(_ anchor: Anchor) throws {
    let info = try bs(anchor.date.0, anchor.date.1, anchor.date.2).calendarInfo
    #expect(info.tithi?.english == anchor.tithi)
    #expect(info.isPublicHoliday == anchor.holiday)
    #expect(info.events.map { $0.english } == anchor.events)
  }

  @Test("coverage is the summary's first day to last day")
  func coverage() throws {
    let summary = try PatroSummary()
    #expect(Patro.coverage.lowerBound == (try NepaliDate.parse(summary.firstDay)))
    #expect(Patro.coverage.upperBound == (try NepaliDate.parse(summary.lastDay)))
    #expect(Int(PatroData.coverageFirst) == summary.firstSerial)
    #expect(Int(PatroData.coverageLast) == summary.lastSerial)
    #expect(Patro.coverage.count == summary.days)
  }

  @Test("public holidays are in ascending order")
  func publicHolidays() throws {
    let summary = try PatroSummary()
    let holidays = Array(Patro.publicHolidays)
    #expect(holidays.count == summary.holidays)
    #expect(zip(holidays, holidays.dropFirst()).allSatisfy { $0 < $1 })
    #expect(holidays.allSatisfy { $0.calendarInfo.isPublicHoliday })
  }

  @Test("a date outside the data has no tithi, no holiday and no events")
  func outside() {
    for date in [NepaliDate.min, .max] {
      let info = date.calendarInfo
      #expect(info.tithi == nil && !info.isPublicHoliday && info.events.isEmpty)
    }
  }

  @Test("Named and PatroEvents read the generated names")
  func namedAndEvents() throws {
    let info = try bs(2081, 1, 1).calendarInfo
    let tithi = try #require(info.tithi)
    #expect(tithi.nepali == "पञ्चमी")
    #expect(tithi.name() == "Panchami")
    #expect(tithi.name(.nepali) == "पञ्चमी")
    #expect(info.events.map { $0.name(.nepali) }.first == "नयाँ वर्ष")
    #expect(info.events.count == 3)
    #expect(info.events[2].english == "Bisket Jatra")
    #expect(Array(info.events).count == 3)
  }

  @Test("PatroEvents equality and hashing compare names in order")
  func eventsEquality() throws {
    let a = try bs(2081, 1, 1).calendarInfo
    #expect(a == (try bs(2081, 1, 1)).calendarInfo)
    #expect(a.events.hashValue == (try bs(2081, 1, 1)).calendarInfo.events.hashValue)
    #expect(a.events != (try bs(2081, 2, 15)).calendarInfo.events)
    // Two days without events have equal (empty) lists, though their offsets differ.
    let none1 = try bs(2081, 1, 2).calendarInfo.events
    let none2 = NepaliDate.min.calendarInfo.events
    #expect(none1 == none2)
    #expect(none1.hashValue == none2.hashValue)
  }

  @Test("every covered day equals a reference built from the JSON files")
  func everyDayMatchesJSON() throws {
    let summary = try PatroSummary()
    let reference = try referenceDays()
    var checked = 0
    for date in Patro.coverage {
      let info = date.calendarInfo
      let day = reference[key(date)]
      #expect(info.tithi?.nepali == day?.tithi?.np, "\(key(date))")
      #expect(info.tithi?.english == day?.tithi?.en, "\(key(date))")
      #expect(info.isPublicHoliday == (day?.holiday ?? false), "\(key(date))")
      #expect(info.events.map { $0.nepali } == (day?.events ?? []).map(\.np), "\(key(date))")
      #expect(info.events.map { $0.english } == (day?.events ?? []).map(\.en), "\(key(date))")
      checked += 1
    }
    #expect(checked == summary.days)
    // Every JSON day is inside the coverage, so none was skipped.
    let covered = Set(Patro.coverage.map(key))
    #expect(reference.keys.allSatisfy { covered.contains($0) })
  }
}
