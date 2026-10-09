import Testing

@testable import NepDate

@Suite("Core")
struct CoreTests {
  @Test("S1-01 AC1: generated tables")
  func generatedTables() {
    #expect(CalendarData.monthStart.count == 3589)
    #expect(CalendarData.monthStart[3588] == 109212)
    #expect(CalendarData.monthStart[12] == 365)
    #expect(CalendarData.monthAtBucket.count == 6826)
    #expect(CalendarData.epochUnixDays == -45920)
  }

  @Test("S1-02 AC: Month and Weekday raw values")
  func enumRawValues() {
    #expect(Month(rawValue: 13) == nil)
    #expect(Month(rawValue: 0) == nil)
    #expect(Month.allCases.count == 12)
    #expect(Month.baishakh.rawValue == 1 && Month.chaitra.rawValue == 12)
    #expect(Month.baishakh < Month.chaitra)
    #expect(Weekday.allCases.count == 7)
    #expect(Weekday.sunday.rawValue == 0 && Weekday.saturday.rawValue == 6)
  }

  @Test("S1-03 AC1: validation order and error kinds")
  func validation() throws {
    let longest = try bs(2081, 4, 32)
    #expect(longest.year == 2081 && longest.month == 4 && longest.day == 32)
    expectError(.invalidDay(monthLength: 32)) { _ = try NepaliDate(year: 2081, month: 4, day: 33) }
    expectError(.outOfRange) { _ = try NepaliDate(year: 1900, month: 1, day: 1) }
    expectError(.outOfRange) { _ = try NepaliDate(year: 2200, month: 1, day: 1) }
    expectError(.invalidMonth) { _ = try NepaliDate(year: 2081, month: 13, day: 1) }
    expectError(.invalidMonth) { _ = try NepaliDate(year: 2081, month: 0, day: 1) }
    expectError(.invalidDay(monthLength: 31)) { _ = try NepaliDate(year: 2081, month: 1, day: 0) }
    // Year is checked before month, month before day (ALGORITHM §3).
    expectError(.outOfRange) { _ = try NepaliDate(year: 1900, month: 13, day: 40) }
    expectError(.invalidMonth) { _ = try NepaliDate(year: 2081, month: 13, day: 40) }
  }

  @Test("S1-03: min and max")
  func minAndMax() {
    #expect(NepaliDate.min.serial == 0)
    #expect(NepaliDate.min.year == 1901 && NepaliDate.min.month == 1 && NepaliDate.min.day == 1)
    #expect(NepaliDate.max.serial == 109211)
    #expect(NepaliDate.max.year == 2199 && NepaliDate.max.month == 12 && NepaliDate.max.day == 30)
  }

  @Test("S1-04 AC1: AD range and Gregorian validity")
  func gregorianErrors() throws {
    expectError(.outOfRange) { _ = try NepaliDate(gregorianYear: 1844, month: 4, day: 10) }
    expectError(.outOfRange) { _ = try NepaliDate(gregorianYear: 2143, month: 4, day: 16) }
    expectError(.invalidGregorian) { _ = try NepaliDate(gregorianYear: 2023, month: 2, day: 29) }
    expectError(.invalidGregorian) { _ = try NepaliDate(gregorianYear: 2024, month: 13, day: 1) }
    expectError(.invalidGregorian) { _ = try NepaliDate(gregorianYear: 2024, month: 4, day: 0) }
    // A real date far outside the range is out of range, and large years don't overflow.
    expectError(.outOfRange) { _ = try NepaliDate(gregorianYear: Int.max, month: 1, day: 1) }
    expectError(.outOfRange) { _ = try NepaliDate(gregorianYear: Int.min, month: 1, day: 1) }
    #expect(try ad(1844, 4, 11) == NepaliDate.min)
    #expect(try ad(2143, 4, 15) == NepaliDate.max)
    #expect(try ad(2024, 2, 29) == bs(2080, 11, 17))
  }

  /// One row of the ALGORITHM §9 table.
  struct Reference: Sendable {
    let bs: (Int, Int, Int)
    let ad: (Int, Int, Int)
    let weekday: Weekday
  }

  @Test(
    "S1-04 AC2: ALGORITHM §9 reference values",
    arguments: [
      Reference(bs: (1901, 1, 1), ad: (1844, 4, 11), weekday: .thursday),
      Reference(bs: (2081, 1, 1), ad: (2024, 4, 13), weekday: .saturday),
      Reference(bs: (2082, 1, 1), ad: (2025, 4, 14), weekday: .monday),
      Reference(bs: (2083, 1, 1), ad: (2026, 4, 14), weekday: .tuesday),
    ])
  func referenceValues(row: Reference) throws {
    let date = try bs(row.bs.0, row.bs.1, row.bs.2)
    let g = date.gregorian
    #expect(g.year == row.ad.0 && g.month == row.ad.1 && g.day == row.ad.2)
    #expect(date.weekday == row.weekday)
    #expect(try ad(row.ad.0, row.ad.1, row.ad.2) == date)
  }

  @Test("S1-04 AC2: ALGORITHM §9 last supported day")
  func lastSupportedDay() throws {
    let g = try bs(2199, 12, 30).gregorian
    #expect(g.year == 2143 && g.month == 4 && g.day == 15)
  }

  @Test("S1-04: month properties")
  func monthProperties() throws {
    let date = try bs(2081, 4, 15)
    #expect(date.bsMonth == .shrawan)
    #expect(date.monthLength == 32)
    #expect(date.firstDayOfMonth == (try bs(2081, 4, 1)))
    #expect(date.firstDayOfMonth.day == 1)
    #expect(date.lastDayOfMonth == (try bs(2081, 4, 32)))
    #expect(date.lastDayOfMonth.day == 32)
    #expect(try bs(2081, 1, 1).dayOfYear == 1)
    #expect(NepaliDate.max.dayOfYear == 365)
    for month in 1...12 {
      #expect(try bs(2081, month, 1).bsMonth.rawValue == month)
    }
  }
}
