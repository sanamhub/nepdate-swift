#if canImport(Foundation)
  import Foundation
  import Testing

  @testable import NepDate

  /// 2024-07-30 18:30 UTC, the clock of PORT-PLAN phase 4: BS 2081-04-15 in UTC, 2081-04-16 in
  /// Nepal.
  let fixedClock = Date(timeIntervalSince1970: 1_722_364_200)

  /// A zone from the database; a missing zone fails the calling test.
  func zone(_ identifier: String) throws -> TimeZone {
    try #require(TimeZone(identifier: identifier))
  }

  /// The instant `seconds` after UTC midnight starting AD `year`-`month`-`day`.
  func utc(_ year: Int, _ month: Int, _ day: Int, seconds: Int = 0) -> Date {
    // Hinnant's days_from_civil, separate from the library's Int32 version.
    let y = month <= 2 ? year - 1 : year
    let era = (y >= 0 ? y : y - 399) / 400
    let yoe = y - era * 400
    let doy = (153 * ((month + 9) % 12) + 2) / 5 + day - 1
    let days = era * 146097 + yoe * 365 + yoe / 4 - yoe / 100 + doy - 719468
    return Date(timeIntervalSince1970: Double(days * 86_400 + seconds))
  }

  @Suite("Foundation")
  struct FoundationTests {
    @Test("S4-04 AC1: today at 2024-07-30 18:30 UTC, real zone database")
    func todayWithZoneDatabase() throws {
      let utcZone = try zone("UTC")
      #expect(NepaliDate.today(in: utcZone, now: fixedClock) == (try bs(2081, 4, 15)))
      #expect(NepaliDate.today(in: nil, now: fixedClock) == (try bs(2081, 4, 16)))
    }

    @Test("S4-04 AC1: today at 2024-07-30 18:30 UTC, zone database without Asia/Kathmandu")
    func todayWithoutNepalZone() throws {
      let utcZone = try zone("UTC")
      let none: (String) -> TimeZone? = { _ in nil }
      #expect(NepaliDate.today(in: utcZone, now: fixedClock, lookup: none) == (try bs(2081, 4, 15)))
      #expect(NepaliDate.today(in: nil, now: fixedClock, lookup: none) == (try bs(2081, 4, 16)))
      #expect(NepaliDate.nepalOffset(at: fixedClock, lookup: none) == 20_700)
      #expect(NepaliDate.nepalOffset(at: fixedClock) { TimeZone(identifier: $0) } == 20_700)
    }

    @Test("S4-04: today(in:) reads the system clock")
    func todayReadsClock() throws {
      let utcZone = try zone("UTC")
      let before = try NepaliDate(Date(), in: utcZone)
      let today = NepaliDate.today(in: utcZone)
      let after = try NepaliDate(Date(), in: utcZone)
      #expect(before <= today && today <= after)
      // 2026 or later is BS 2083 or later.
      #expect(NepaliDate.today() >= (try bs(2083, 1, 1)))
    }

    @Test("S4-04: a clock outside the range gives min or max")
    func todayOutsideRange() throws {
      let utcZone = try zone("UTC")
      #expect(NepaliDate.today(in: utcZone, now: utc(1843, 1, 1)) == .min)
      #expect(NepaliDate.today(in: utcZone, now: utc(2200, 1, 1)) == .max)
      #expect(NepaliDate.today(in: nil, now: Date.distantPast) == .min)
      #expect(NepaliDate.today(in: nil, now: Date.distantFuture) == .max)
    }

    @Test(
      "S4-04 AC2: date(in:) round-trips every day of 2080 to 2082",
      arguments: ["Asia/Kathmandu", "America/New_York", "UTC"])
    func roundTrip(_ identifier: String) throws {
      let tz = try zone(identifier)
      var count = 0
      for year in 2080...2082 {
        for date in try NepaliDateRange.year(year) {
          let midnight = date.date(in: tz)
          #expect(try NepaliDate(midnight, in: tz) == date, "\(date) in \(identifier)")
          // One second earlier is the day before.
          let before = try NepaliDate(midnight.addingTimeInterval(-1), in: tz)
          #expect(before.days(until: date) == 1, "\(date) in \(identifier)")
          count += 1
        }
      }
      #expect(count == 1096)
    }

    @Test("S4-04 AC3: the first supported day, before 1970")
    func firstDay() throws {
      let date = try NepaliDate(Date(timeIntervalSince1970: -45_920 * 86_400), in: try zone("UTC"))
      #expect(date == .min)
      #expect(date == (try bs(1901, 1, 1)))
    }

    @Test("S4-04: init(_:in:) uses floor division and checks both ends")
    func conversionEdges() throws {
      let utcZone = try zone("UTC")
      // One second before 1970-01-01 is 1969-12-31.
      let lastOf1969 = try NepaliDate(Date(timeIntervalSince1970: -1), in: utcZone)
      #expect(lastOf1969 == (try ad(1969, 12, 31)))
      #expect(try NepaliDate(utc(2143, 4, 15, seconds: 86_399), in: utcZone) == .max)
      #expect(NepaliDate.min.date(in: utcZone) == utc(1844, 4, 11))
      expectError(.outOfRange) {
        _ = try NepaliDate(utc(1844, 4, 10, seconds: 86_399), in: utcZone)
      }
      expectError(.outOfRange) { _ = try NepaliDate(utc(2143, 4, 16), in: utcZone) }
      expectError(.outOfRange) {
        _ = try NepaliDate(Date(timeIntervalSince1970: .nan), in: utcZone)
      }
    }

    @Test("S4-04: Nepal's midnight is 18:15 UTC the day before")
    func nepalMidnight() throws {
      let midnight = try bs(2081, 4, 16).date(in: try zone("Asia/Kathmandu"))
      #expect(midnight == utc(2024, 7, 31, seconds: -20_700))
    }
  }
#endif
