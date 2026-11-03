import Testing

@testable import NepDate

@Suite("Strideable")
struct StrideableTests {
  @Test("distance, advanced, stride and the day operators")
  func strideable() throws {
    let a = try bs(2081, 4, 15)
    let b = try bs(2081, 4, 20)
    #expect(a.distance(to: b) == 5)
    #expect(b.distance(to: a) == -5)
    #expect(b.advanced(by: -5) == a)
    #expect(a.advanced(by: 5) == b)
    #expect(
      Array(stride(from: a, through: b, by: 2))
        == [a, try a.adding(days: 2), try a.adding(days: 4)])
    #expect(a + 1 == (try a.adding(days: 1)))
    #expect(a - 1 == (try a.adding(days: -1)))
    #expect(1 + a == (try a.adding(days: 1)))
    #expect((b - a).totalDays == 5)
    #expect((a - b).totalDays == -5)
    #expect(NepaliDate.min.distance(to: NepaliDate.max) == 109_211)
  }
}

#if canImport(Foundation)
  import Foundation

  @Suite("Clock")
  struct ClockTests {
    @Test("predicates at 2024-07-30 18:30 UTC")
    func predicates() throws {
      let utc = try zone("UTC")
      let today = NepaliDate.today(in: utc, now: fixedClock)
      #expect(today.isToday(in: utc, now: fixedClock))
      #expect(!today.isYesterday(in: utc, now: fixedClock))
      #expect(!today.isTomorrow(in: utc, now: fixedClock))
      let yesterday = try today.adding(days: -1)
      let tomorrow = try today.adding(days: 1)
      let twoDaysAgo = try today.adding(days: -2)
      #expect(yesterday.isYesterday(in: utc, now: fixedClock))
      #expect(tomorrow.isTomorrow(in: utc, now: fixedClock))
      #expect(!twoDaysAgo.isYesterday(in: utc, now: fixedClock))
      let nepal = try zone("Asia/Kathmandu")
      #expect(!today.isToday(in: nepal, now: fixedClock))
    }

    @Test("predicates at the data ends")
    func boundaries() throws {
      let utc = try zone("UTC")
      #expect(!NepaliDate.min.isYesterday(in: utc, now: fixedClock))
      #expect(!NepaliDate.max.isTomorrow(in: utc, now: fixedClock))
      #expect(!NepaliDate.min.isToday(in: utc, now: fixedClock))
      #expect(!NepaliDate.max.isToday(in: utc, now: fixedClock))
    }

    @Test("the public predicates read the clock")
    func publicPredicates() throws {
      let utc = try zone("UTC")
      let today = NepaliDate.today(in: utc)
      #expect(today.isToday(in: utc))
      #expect(try today.adding(days: -1).isYesterday(in: utc))
      #expect(try today.adding(days: 1).isTomorrow(in: utc))
    }

    @Test("the current ranges use the fixed clock")
    func currentRanges() throws {
      let utc = try zone("UTC")
      let today = NepaliDate.today(in: utc, now: fixedClock)
      let month = try NepaliDateRange.currentMonth(in: utc, now: fixedClock)
      #expect(month == (try NepaliDateRange.month(year: today.year, month: today.month)))
      let fiscal = try NepaliDateRange.currentFiscalYear(in: utc, now: fixedClock)
      #expect(fiscal == (try today.fiscalYear.range()))
      let year = try NepaliDateRange.currentCalendarYear(in: utc, now: fixedClock)
      #expect(year == (try NepaliDateRange.year(today.year)))
    }

    @Test("the public current factories read the clock")
    func publicCurrentRanges() throws {
      let utc = try zone("UTC")
      let today = NepaliDate.today(in: utc)
      #expect(try NepaliDateRange.currentMonth(in: utc).contains(today))
      #expect(try NepaliDateRange.currentFiscalYear(in: utc).contains(today))
      #expect(try NepaliDateRange.currentCalendarYear(in: utc).contains(today))
    }
  }
#endif
