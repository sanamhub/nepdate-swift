import NepDate
import Testing

@testable import NepDatePatro

@Suite("Patro")
struct PatroTests {
  @Test("generated table sizes match PATRO §3")
  func tableSizes() {
    #expect(PatroData.dayInfo.count == 2793)
    #expect(PatroData.dayEventStart.count == 2794)
    #expect(PatroData.dayEventStart.first == 0)
    #expect(PatroData.dayEventStart.last == 3032)
    #expect(PatroData.eventNameIDs.count == 3032)
    #expect(PatroData.coverageLast - PatroData.coverageFirst + 1 == 2793)
    #expect(PatroData.dayInfo.filter { $0 & 0x80 != 0 }.count == 294)
    #expect(PatroData.dayInfo.filter { $0 & 0x3F != 0 }.count == 2190)
    #expect(PatroData.dayInfo.allSatisfy { $0 & 0x40 == 0 })
  }

  @Test("753 names, of which ids 0 to 31 are the 32 tithi names")
  func names() {
    for id in UInt16(0)..<753 {
      let name = PatroData.name(id)
      #expect(!name.nepali.isEmpty && !name.english.isEmpty, "name \(id)")
    }
    #expect(PatroData.name(753).nepali.isEmpty && PatroData.name(753).english.isEmpty)
    let tithiIDs = Set(PatroData.dayInfo.map { $0 & 0x3F }.filter { $0 != 0 })
    #expect(tithiIDs == Set(UInt8(1)...32))
    #expect(PatroData.eventNameIDs.allSatisfy { $0 < 753 })
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

  @Test("coverage is 2077-01-01 to 2084-08-20")
  func coverage() throws {
    #expect(Patro.coverage.lowerBound == (try bs(2077, 1, 1)))
    #expect(Patro.coverage.upperBound == (try bs(2084, 8, 20)))
    #expect(Patro.coverage.count == 2793)
  }

  @Test("294 public holidays in ascending order")
  func publicHolidays() {
    let holidays = Array(Patro.publicHolidays)
    #expect(holidays.count == 294)
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
    #expect(checked == 2793)
    // Every JSON day is inside the coverage, so none was skipped.
    let covered = Set(Patro.coverage.map(key))
    #expect(reference.keys.allSatisfy { covered.contains($0) })
  }
}
