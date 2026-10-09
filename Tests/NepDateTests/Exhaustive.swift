import Testing

@testable import NepDate

@Suite("Exhaustive")
struct ExhaustiveTests {
  /// Walks all 109,212 days in order, keeping the expected BS date by hand, so `init(serial:)` is
  /// checked against counting rather than against itself.
  @Test("S1-05: every serial round-trips through BS and AD")
  func everySerial() {
    var log = FailureLog()
    var year = 1901
    var month = 1
    var day = 1
    var checked = 0
    for serial in Int32(0)...CalendarData.maxSerial {
      let date = NepaliDate(serial: serial)
      if date.serial != serial || date.year != year || date.month != month || date.day != day {
        log.record(Int(serial), "init(serial:) gave \(date.year)-\(date.month)-\(date.day)")
      }
      if (try? NepaliDate(year: year, month: month, day: day))?.serial != serial {
        log.record(Int(serial), "init(year:month:day:) disagrees")
      }
      let g = date.gregorian
      if (try? NepaliDate(gregorianYear: g.year, month: g.month, day: g.day)) != date {
        log.record(Int(serial), "AD \(g) does not convert back")
      }
      checked += 1
      day += 1
      if day > date.monthLength {
        day = 1
        month += 1
        if month > 12 {
          month = 1
          year += 1
        }
      }
    }
    #expect(checked == 109212)
    #expect(year == 2200 && month == 1 && day == 1)
    #expect(log.count == 0, "\(log.summary)")
  }

  @Test("S1-05: every month length is 29 to 32 and the bucket table needs at most one step")
  func monthTables() {
    let starts = CalendarData.monthStart
    for i in 0..<(starts.count - 1) {
      #expect((29...32).contains(starts[i + 1] - starts[i]), "month index \(i)")
    }
    for (bucket, month) in CalendarData.monthAtBucket.enumerated() {
      let serial = Int32(bucket * 16)
      #expect(starts[Int(month)] <= serial && serial < starts[Int(month) + 1], "bucket \(bucket)")
    }
  }
}
