import NepDate
import Testing

@testable import NepDatePatro

// C#'s CalendarDataTests check its internal arrays (CalendarStrings, CalendarOffsets, TithiData,
// EventData, HolidayData). The same facts are checked on PatroData (ADR-0002 §3), which keeps
// dense per-day tables instead of sorted day offsets. The six CalendarOffsets rows check that every
// covered day has its own offset and that dayEventStart spans the events.

@Suite("CalendarDataTests")
struct CalendarDataTests {
  /// Every date from 2001-01-01 to the last day of 2089, a superset of the coverage.
  static func wideRange() throws -> NepaliDateRange {
    let end = try bs(2089, 12, 1).lastDayOfMonth
    return try #require(NepaliDateRange(try bs(2001, 1, 1), end))
  }

  @Test("CalendarDataTests.CalendarStrings_Pool_IsNonEmpty")
  func poolIsNonEmpty() throws {
    let summary = try PatroSummary()
    let last = try #require(UInt16(exactly: summary.names - 1), "\(summary.names) names")
    #expect(!PatroData.name(0).english.isEmpty)
    #expect(!PatroData.name(last).english.isEmpty)
  }

  @Test("CalendarDataTests.CalendarStrings_Pool_AllEntriesHaveNonEmptyNpAndEn")
  func poolAllEntriesNonEmpty() throws {
    let summary = try PatroSummary()
    let count = try #require(UInt16(exactly: summary.names), "\(summary.names) names")
    for id in UInt16(0)..<count {
      #expect(!PatroData.name(id).nepali.isEmpty, "name \(id)")
      #expect(!PatroData.name(id).english.isEmpty, "name \(id)")
    }
  }

  @Test("CalendarDataTests.CalendarOffsets_MonthStart_HasExpectedLength")
  func offsetsHaveExpectedLength() {
    #expect(PatroData.dayEventStart.count == PatroData.dayInfo.count + 1)
  }

  @Test("CalendarDataTests.CalendarOffsets_MonthStart_IsStrictlyMonotonic")
  func offsetsAreMonotonic() {
    let starts = PatroData.dayEventStart
    #expect(zip(starts, starts.dropFirst()).allSatisfy { $0 <= $1 })
  }

  @Test("CalendarDataTests.CalendarOffsets_TotalDays_MatchesExpectedCount")
  func totalDays() throws {
    let summary = try PatroSummary()
    #expect(PatroData.dayInfo.count == summary.days)
    #expect(Patro.coverage.count == summary.days)
  }

  @Test("CalendarDataTests.CalendarOffsets_GetOffset_BaseYear_Month1_Day1_ReturnsZero")
  func firstDayIsOffsetZero() throws {
    let summary = try PatroSummary()
    #expect(try NepaliDate.parse(summary.firstDay).serial == PatroData.coverageFirst)
  }

  @Test("CalendarDataTests.CalendarOffsets_GetOffset_OutOfRange_ReturnsNegativeOne")
  func dayBeforeCoverageHasNoOffset() throws {
    let summary = try PatroSummary()
    let before = try NepaliDate.parse(summary.firstDay).adding(days: -1)
    #expect(before.serial - PatroData.coverageFirst == -1)
    #expect(before.calendarInfo.events.isEmpty && !before.calendarInfo.isPublicHoliday)
  }

  @Test("CalendarDataTests.CalendarOffsets_GetOffset_AllOffsetsAreUniqueSentinel")
  func everyCoveredDayHasItsOwnOffset() throws {
    let summary = try PatroSummary()
    let offsets = Patro.coverage.map { Int($0.serial - PatroData.coverageFirst) }
    #expect(offsets == Array(0..<summary.days))
  }

  @Test("CalendarDataTests.TithiData_DayOffsets_IsStrictlySorted")
  func tithiDaysAreContiguous() throws {
    // PATRO §3: one tithi for every day from the summary's first tithi day to its last, no gap.
    let summary = try PatroSummary()
    let withTithi = Patro.coverage.filter { $0.calendarInfo.tithi != nil }
    #expect(withTithi.first == (try NepaliDate.parse(summary.tithiFirstDay)))
    #expect(withTithi.last == (try NepaliDate.parse(summary.tithiLastDay)))
    #expect(zip(withTithi, withTithi.dropFirst()).allSatisfy { $0.days(until: $1) == 1 })
  }

  @Test("CalendarDataTests.TithiData_AllPoolIds_AreInRange")
  func tithiIDsAreInRange() throws {
    let summary = try PatroSummary()
    #expect(PatroData.dayInfo.allSatisfy { Int($0 & 0x3F) <= summary.tithiNames })
  }

  @Test("CalendarDataTests.TithiData_EntryCount_MatchesSummary")
  func tithiCount() throws {
    let summary = try PatroSummary()
    #expect(Patro.coverage.filter { $0.calendarInfo.tithi != nil }.count == summary.tithiDays)
  }

  @Test("CalendarDataTests.EventData_DayOffsets_IsStrictlySorted")
  func eventDaysAreSorted() {
    let days = Patro.coverage.filter { !$0.calendarInfo.events.isEmpty }
    #expect(zip(days, days.dropFirst()).allSatisfy { $0 < $1 })
  }

  @Test("CalendarDataTests.EventData_SliceStart_IsNonDecreasing")
  func eventStartsAreNonDecreasing() {
    let starts = PatroData.dayEventStart
    #expect(zip(starts, starts.dropFirst()).allSatisfy { $0 <= $1 })
  }

  @Test("CalendarDataTests.EventData_SliceStart_SentinelEqualsEntriesLength")
  func eventStartSentinel() {
    #expect(PatroData.dayEventStart.first == 0)
    #expect(Int(PatroData.dayEventStart.last ?? 0) == PatroData.eventNameIDs.count)
  }

  @Test("CalendarDataTests.EventData_AllEntries_AreInRange")
  func eventIDsAreInRange() throws {
    let summary = try PatroSummary()
    let count = try #require(UInt16(exactly: summary.names), "\(summary.names) names")
    #expect(PatroData.eventNameIDs.allSatisfy { $0 < count })
  }

  @Test("CalendarDataTests.EventData_DayCount_MatchesSummary")
  func eventDayCount() throws {
    let summary = try PatroSummary()
    #expect(Patro.coverage.filter { !$0.calendarInfo.events.isEmpty }.count == summary.eventDays)
  }

  @Test("CalendarDataTests.HolidayData_DayOffsets_IsStrictlySorted")
  func holidaysAreSorted() {
    let holidays = Array(Patro.publicHolidays)
    #expect(zip(holidays, holidays.dropFirst()).allSatisfy { $0 < $1 })
  }

  @Test("CalendarDataTests.HolidayData_Count_MatchesSummary")
  func holidayCount() throws {
    let summary = try PatroSummary()
    #expect(Array(Patro.publicHolidays).count == summary.holidays)
  }

  @Test("CalendarDataTests.NepaliDate_2081_01_01_CalendarData")
  func newYear2081() throws {
    let info = try bs(2081, 1, 1).calendarInfo
    #expect(info.tithi?.nepali == "पञ्चमी")
    #expect(info.tithi?.english == "Panchami")
    #expect(info.isPublicHoliday)
    #expect(info.events.map { $0.nepali }.contains("नयाँ वर्ष"))
    #expect(info.events.map { $0.english }.contains("New Year"))
  }

  @Test("CalendarDataTests.NepaliDate_2081_01_02_Tithi_IsShashthi")
  func shashthi() throws {
    let info = try bs(2081, 1, 2).calendarInfo
    #expect(info.tithi?.nepali == "षष्ठी")
    #expect(info.tithi?.english == "Shashthi")
  }

  @Test("CalendarDataTests.NepaliDate_2081_01_05_IsPublicHoliday")
  func ramNavami() throws {
    let info = try bs(2081, 1, 5).calendarInfo
    #expect(info.isPublicHoliday)
    #expect(info.tithi?.nepali == "नवमी")
    #expect(info.tithi?.english == "Navami")
  }

  @Test("CalendarDataTests.NepaliDate_2081_02_15_IsPublicHoliday_GanatantraDiwas")
  func republicDay() throws {
    let info = try bs(2081, 2, 15).calendarInfo
    #expect(info.isPublicHoliday)
    #expect(info.events.map { $0.nepali }.contains("गणतन्त्र दिवस"))
    #expect(info.events.map { $0.english }.contains("Republic Day"))
  }

  @Test("CalendarDataTests.NepaliDate_2080_11_01_CalendarData")
  func chaturthi() throws {
    let info = try bs(2080, 11, 1).calendarInfo
    #expect(info.tithi?.nepali == "चतुर्थी")
    #expect(info.tithi?.english == "Chaturthi")
    #expect(!info.isPublicHoliday)
    #expect(info.events.map { $0.nepali }.contains("जनयुद्ध दिवस"))
    #expect(info.events.map { $0.english }.contains("People's War Day"))
  }

  @Test("CalendarDataTests.NepaliDate_BeforeRange_AllPropertiesReturnDefaults")
  func beforeRange() throws {
    let info = try bs(2000, 6, 15).calendarInfo
    #expect(info.tithi == nil && !info.isPublicHoliday && info.events.isEmpty)
  }

  @Test("CalendarDataTests.NepaliDate_AfterRange_AllPropertiesReturnDefaults")
  func afterRange() throws {
    let info = try bs(2090, 1, 1).calendarInfo
    #expect(info.tithi == nil && !info.isPublicHoliday && info.events.isEmpty)
  }

  @Test("CalendarDataTests.NepaliDate_OutsideTithiRange_TithiIsEmpty")
  func outsideTithiRange() throws {
    let summary = try PatroSummary()
    #expect(try bs(2070, 6, 15).calendarInfo.tithi == nil)
    // Inside the coverage but before the tithi data starts.
    let beforeTithi = try NepaliDate.parse(summary.tithiFirstDay).adding(days: -1)
    #expect(beforeTithi.calendarInfo.tithi == nil)
  }

  @Test("CalendarDataTests.NepaliDate_EventsNp_And_EventsEn_AlwaysHaveSameLength")
  func eventsSameLength() throws {
    for date in [
      try bs(2081, 1, 1), try bs(2081, 1, 5), try bs(2081, 2, 10), try bs(2080, 11, 1),
      try bs(2075, 1, 1),
    ] {
      let events = date.calendarInfo.events
      #expect(events.map { $0.nepali }.count == events.map { $0.english }.count)
    }
  }

  // C#'s GetCalendarInfo and its flat properties are one `calendarInfo` here, so this checks that
  // two reads agree and that `name(_:)` matches the two properties.
  @Test("CalendarDataTests.GetCalendarInfo_TithiMatchesFlatProperties")
  func infoIsStable() throws {
    let date = try bs(2081, 1, 1)
    #expect(date.calendarInfo == date.calendarInfo)
    let tithi = try #require(date.calendarInfo.tithi)
    #expect(tithi.name(.nepali) == tithi.nepali && tithi.name(.english) == tithi.english)
  }

  @Test("CalendarDataTests.AllDaysInScrapedRange_OffsetsAreInBounds")
  func offsetsInBounds() {
    let starts = PatroData.dayEventStart
    for k in 0..<PatroData.dayInfo.count {
      #expect(starts[k] <= starts[k + 1] && Int(starts[k + 1]) <= PatroData.eventNameIDs.count)
    }
  }

  @Test("CalendarDataTests.AllDaysInScrapedRange_NoExceptionOnPropertyAccess")
  func everyPropertyReads() throws {
    let end = try bs(2082, 12, 1).lastDayOfMonth
    let range = try #require(NepaliDateRange(try bs(2078, 1, 1), end))
    var reads = 0
    for date in range {
      let info = date.calendarInfo
      reads += (info.tithi?.nepali.count ?? 0) + (info.isPublicHoliday ? 1 : 0)
      reads += info.events.map { $0.english.count }.reduce(0, +)
    }
    #expect(reads > 0)
  }

  @Test("CalendarDataTests.AllTithiEntries_ResolveToNonEmptyStrings")
  func tithiNamesNonEmpty() {
    for date in Patro.coverage {
      guard let tithi = date.calendarInfo.tithi else { continue }
      #expect(!tithi.nepali.isEmpty && !tithi.english.isEmpty)
    }
  }

  @Test("CalendarDataTests.AllHolidayOffsets_AreInBounds")
  func holidaysInCoverage() {
    #expect(Patro.publicHolidays.allSatisfy { Patro.coverage.contains($0) })
  }

  @Test("CalendarDataTests.AllEventOffsets_AreInBounds")
  func eventsInCoverage() throws {
    let range = try #require(NepaliDateRange(.min, .max))
    let outside = range.filter {
      !Patro.coverage.contains($0) && !$0.calendarInfo.events.isEmpty
    }
    #expect(outside.isEmpty)
  }

  @Test("CalendarDataTests.HolidayCount_ViaApi_MatchesSummary")
  func holidayCountViaAPI() throws {
    let summary = try PatroSummary()
    let holidays = try Self.wideRange().filter { $0.calendarInfo.isPublicHoliday }
    #expect(holidays.count == summary.holidays)
  }

  // C# returns empty arrays, never null; `events` is a collection that is empty or not.
  @Test("CalendarDataTests.CalendarInfo_EventArrays_AreNeverNull")
  func eventsNeverMissing() throws {
    #expect(!(try bs(2081, 1, 1)).calendarInfo.events.isEmpty)
    #expect(try bs(2001, 1, 2).calendarInfo.events.isEmpty)
  }
}
