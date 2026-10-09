import Testing

@testable import NepDate

@Suite("DictionaryIntegrityTests")
struct DictionaryIntegrityTests {
  @Test("DictionaryIntegrityTests.AllNepaliMonths_RoundtripToEnglishAndBack_ProducesOriginalDate")
  func allNepaliMonthsRoundtrip() throws {
    var failures = 0
    for year in 1901...2199 {
      for month in 1...12 {
        let g = try bs(year, month, 1).gregorian
        let back = try ad(g.year, g.month, g.day)
        if back.year != year || back.month != month || back.day != 1 { failures += 1 }
      }
    }
    #expect(failures == 0)
  }

  @Test("DictionaryIntegrityTests.AllNepaliDays_RoundtripToEnglishAndBack_ProducesOriginalDate")
  func allNepaliDaysRoundtrip() throws {
    var total = 0
    var failures = 0
    for year in 1901...2199 {
      for month in 1...12 {
        for day in 1...(try bs(year, month, 1).monthLength) {
          let g = try bs(year, month, day).gregorian
          let back = try ad(g.year, g.month, g.day)
          if back.year != year || back.month != month || back.day != day { failures += 1 }
          total += 1
        }
      }
    }
    #expect(failures == 0)
    #expect(total > 100_000)
  }

  @Test("DictionaryIntegrityTests.AllEnglishDays_RoundtripToNepaliAndBack_ProducesOriginalDate")
  func allEnglishDaysRoundtrip() throws {
    var total = 0
    var failures = 0
    var (year, month, day) = (1844, 4, 11)
    while (year, month, day) <= (2143, 4, 15) {
      let g = try ad(year, month, day).gregorian
      if g.year != year || g.month != month || g.day != day { failures += 1 }
      total += 1
      day += 1
      if day > gregorianMonthLength(year, month) {
        day = 1
        month += 1
        if month > 12 {
          month = 1
          year += 1
        }
      }
    }
    #expect(failures == 0)
    #expect(total > 100_000)
  }

  @Test("DictionaryIntegrityTests.AllMonths_MonthEndDay_IsWithinValidRange")
  func allMonthsMonthEndDayIsWithinValidRange() throws {
    for year in 1901...2199 {
      for month in 1...12 {
        #expect((29...32).contains(try bs(year, month, 1).monthLength))
      }
    }
  }

  @Test("DictionaryIntegrityTests.ConsecutiveNepaliDays_ProduceConsecutiveEnglishDays")
  func consecutiveNepaliDaysProduceConsecutiveEnglishDays() throws {
    var violations = 0
    var previous: (year: Int, month: Int, day: Int)?
    for year in 1901...2199 {
      for month in 1...12 {
        for day in 1...(try bs(year, month, 1).monthLength) {
          let g = try bs(year, month, day).gregorian
          if let p = previous {
            let next =
              p.day < gregorianMonthLength(p.year, p.month)
              ? (p.year, p.month, p.day + 1)
              : (p.month < 12 ? (p.year, p.month + 1, 1) : (p.year + 1, 1, 1))
            if next != (g.year, g.month, g.day) { violations += 1 }
          }
          previous = g
        }
      }
    }
    #expect(violations == 0)
  }

  @Test(
    "DictionaryIntegrityTests.KnownReferenceDates_ConvertCorrectly",
    arguments: [
      [2080, 1, 1, 2023, 4, 14],
      [2000, 1, 1, 1943, 4, 14],
      [2081, 1, 1, 2024, 4, 13],
      [1901, 1, 1, 1844, 4, 11],
    ])
  func knownReferenceDatesConvertCorrectly(row: [Int]) throws {
    let g = try bs(row[0], row[1], row[2]).gregorian
    #expect(g.year == row[3] && g.month == row[4] && g.day == row[5])
    let reverse = try ad(row[3], row[4], row[5])
    #expect(reverse.year == row[0] && reverse.month == row[1] && reverse.day == row[2])
  }

  @Test("DictionaryIntegrityTests.BoundaryDates_ConvertCorrectly")
  func boundaryDatesConvertCorrectly() throws {
    let min = NepaliDate.min
    #expect(min.year == 1901 && min.month == 1 && min.day == 1)
    let minG = min.gregorian
    #expect(try ad(minG.year, minG.month, minG.day) == min)
    let max = NepaliDate.max
    #expect(max.year == 2199 && max.month == 12)
    let maxG = max.gregorian
    #expect(try ad(maxG.year, maxG.month, maxG.day) == max)
  }

  @Test("DictionaryIntegrityTests.TotalDaysInRange_MatchesEnglishDateSpan")
  func totalDaysInRangeMatchesEnglishDateSpan() throws {
    var total = 0
    for year in 1901...2199 {
      for month in 1...12 { total += try bs(year, month, 1).monthLength }
    }
    let first = NepaliDate.min.gregorian
    let last = NepaliDate.max.gregorian
    let span =
      Int(
        daysFromCivil(Int32(last.year), Int32(last.month), Int32(last.day))
          - daysFromCivil(Int32(first.year), Int32(first.month), Int32(first.day))) + 1
    #expect(span == total)
  }
}
