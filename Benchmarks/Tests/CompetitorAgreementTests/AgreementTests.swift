// The "agrees" column of docs/benchmarks.md: does each competitor with a conversion API return the
// shared/data answer for all 64 BENCHMARK §2 dates? This is a test, not a timing.
//
// The 64 dates are rebuilt here from shared/data/calendar/bs-calendar.json and Hinnant's civil
// arithmetic, without calling NepDate, so "agrees with shared/data" is not circular.

import Foundation
import Testing

import BenchmarkInputs
import NRLNishan

#if canImport(nepali_date_picker_core)
  import nepali_date_picker_core
#endif

enum SharedDataError: Error {
  case missingCalendar
  case badYearRange
  case serialOutsideRange
}

/// The 64 dates and their serials, derived from shared/data alone.
struct SharedDataDates {
  static let count = 64

  let bs: [(year: Int, month: Int, day: Int)]
  let ad: [(year: Int, month: Int, day: Int)]
  let serials: [Int]

  init() throws {
    let repository = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()  // CompetitorAgreementTests
      .deletingLastPathComponent()  // Tests
      .deletingLastPathComponent()  // Benchmarks
      .deletingLastPathComponent()  // repository root
    let path = repository.appendingPathComponent("shared/data/calendar/bs-calendar.json")
    guard let data = try? Data(contentsOf: path) else { throw SharedDataError.missingCalendar }
    let calendar = try JSONDecoder().decode(CalendarFile.self, from: data)

    let years = calendar.monthLengths.keys.compactMap(Int.init).sorted()
    guard years == Array(1901...2199) else { throw SharedDataError.badYearRange }
    var lengths: [[Int]] = []
    for year in years {
      guard let months = calendar.monthLengths[String(year)], months.count == 12 else {
        throw SharedDataError.badYearRange
      }
      lengths.append(months)
    }

    func yearLength(_ year: Int) -> Int { lengths[year - 1901].reduce(0, +) }
    func serial(year: Int, month: Int, day: Int) -> Int {
      var total = 0
      for y in 1901..<year { total += yearLength(y) }
      for m in 0..<(month - 1) { total += lengths[year - 1901][m] }
      return total + day - 1
    }
    func bsDate(from serial: Int) -> (year: Int, month: Int, day: Int)? {
      var rest = serial
      var year = 1901
      while year <= 2199, rest >= yearLength(year) {
        rest -= yearLength(year)
        year += 1
      }
      guard year <= 2199 else { return nil }
      var month = 1
      while month <= 12, rest >= lengths[year - 1901][month - 1] {
        rest -= lengths[year - 1901][month - 1]
        month += 1
      }
      guard month <= 12 else { return nil }
      return (year, month, rest + 1)
    }

    let first = serial(year: 2000, month: 1, day: 1)
    let last = serial(year: 2090, month: 12, day: 30)
    let step = (last - first) / (Self.count - 1)
    let epoch = daysFromCivil(1844, 4, 11)

    var bs: [(year: Int, month: Int, day: Int)] = []
    var ad: [(year: Int, month: Int, day: Int)] = []
    var serials: [Int] = []
    for index in 0..<Self.count {
      let value = first + index * step
      guard let date = bsDate(from: value) else { throw SharedDataError.serialOutsideRange }
      bs.append(date)
      ad.append(civilFromDays(epoch + value))
      serials.append(value)
    }
    self.bs = bs
    self.ad = ad
    self.serials = serials
  }
}

struct CalendarFile: Decodable {
  let monthLengths: [String: [Int]]

  enum CodingKeys: String, CodingKey {
    case monthLengths = "month_lengths"
  }
}

/// Howard Hinnant's days_from_civil, independent of the library under test.
func daysFromCivil(_ year: Int, _ month: Int, _ day: Int) -> Int {
  let y = month <= 2 ? year - 1 : year
  let era = (y >= 0 ? y : y - 399) / 400
  let yoe = y - era * 400
  let doy = (153 * ((month + 9) % 12) + 2) / 5 + day - 1
  return era * 146097 + yoe * 365 + yoe / 4 - yoe / 100 + doy - 719468
}

/// Howard Hinnant's civil_from_days.
func civilFromDays(_ days: Int) -> (year: Int, month: Int, day: Int) {
  let z = days + 719468
  let era = (z >= 0 ? z : z - 146096) / 146097
  let doe = z - era * 146097
  let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  let mp = (5 * doy + 2) / 153
  let day = doy - (153 * mp + 2) / 5 + 1
  let month = mp < 10 ? mp + 3 : mp - 9
  return (yoe + era * 400 + (month <= 2 ? 1 : 0), month, day)
}

@Test("BenchmarkInputs are the shared/data dates")
func benchmarkInputsMatchSharedData() throws {
  let shared = try SharedDataDates()
  let inputs = try BenchmarkInputs()
  #expect(shared.serials.count == 64)
  #expect(shared.serials[0] == 36161, "BS 2000-01-01 is serial 36161 (ALGORITHM §2)")
  #expect(inputs.bs.count == 64)
  for index in 0..<64 {
    #expect(inputs.bs[index].year == shared.bs[index].year, "BS date \(index)")
    #expect(inputs.bs[index].month == shared.bs[index].month, "BS date \(index)")
    #expect(inputs.bs[index].day == shared.bs[index].day, "BS date \(index)")
    #expect(inputs.ad[index].year == shared.ad[index].year, "AD date \(index)")
    #expect(inputs.ad[index].month == shared.ad[index].month, "AD date \(index)")
    #expect(inputs.ad[index].day == shared.ad[index].day, "AD date \(index)")
  }
}

@Test("nrlnishan agrees with shared/data on 62 of 64 B1 dates and 59 of 64 B2 dates")
func nrlnishanAgreement() throws {
  let shared = try SharedDataDates()
  let converter = NRLNishan.DateConverter()
  var englishAgrees = 0
  var nepaliAgrees = 0
  var details: [String] = []

  for index in 0..<64 {
    let bs = shared.bs[index]
    let ad = shared.ad[index]
    let english = converter.getEnglishDate(
      nepaliDate: DateModel(year: bs.year, month: bs.month, day: bs.day))
    if english?.year == ad.year, english?.month == ad.month, english?.day == ad.day {
      englishAgrees += 1
    } else {
      details.append(
        "B1 \(bs.year)-\(bs.month)-\(bs.day): expected \(ad.year)-\(ad.month)-\(ad.day), got \(String(describing: english))"
      )
    }

    let nepali = converter.getNepaliDate(
      englishDate: DateModel(year: ad.year, month: ad.month, day: ad.day))
    if nepali?.year == bs.year, nepali?.month == bs.month, nepali?.day == bs.day {
      nepaliAgrees += 1
    } else {
      details.append(
        "B2 \(ad.year)-\(ad.month)-\(ad.day): expected \(bs.year)-\(bs.month)-\(bs.day), got \(String(describing: nepali))"
      )
    }
  }

  print("nrlnishan: B1 \(englishAgrees)/64, B2 \(nepaliAgrees)/64")
  for detail in details { print("nrlnishan: \(detail)") }
  // Its table differs from shared/data in BS 2062 and 2081 to 2089, and getNepaliDate uses a strict
  // `>` against the month length, so a date on a month boundary gets day 32 or 33.
  #expect(englishAgrees == 62, "B1 agreement changed: \(details.joined(separator: "; "))")
  #expect(nepaliAgrees == 59, "B2 agreement changed: \(details.joined(separator: "; "))")
}

#if os(macOS) && arch(arm64)
  @Test("shivathapaa agrees with shared/data on 61 of 64 B1 and B2 dates")
  func shivathapaaAgreement() throws {
    let shared = try SharedDataDates()
    let converter = nepali_date_picker_core.NepaliDateConverter.shared
    var englishAgrees = 0
    var nepaliAgrees = 0
    var details: [String] = []

    for index in 0..<64 {
      let bs = shared.bs[index]
      let ad = shared.ad[index]
      let english = converter.convertNepaliToEnglish(
        nepaliYYYY: Int32(bs.year), nepaliMM: Int32(bs.month), nepaliDD: Int32(bs.day))
      if Int(english.year) == ad.year, Int(english.month) == ad.month,
        Int(english.dayOfMonth) == ad.day
      {
        englishAgrees += 1
      } else {
        details.append(
          "B1 \(bs.year)-\(bs.month)-\(bs.day): expected \(ad.year)-\(ad.month)-\(ad.day), got \(english.year)-\(english.month)-\(english.dayOfMonth)"
        )
      }

      let nepali = converter.convertEnglishToNepali(
        englishYYYY: Int32(ad.year), englishMM: Int32(ad.month), englishDD: Int32(ad.day))
      if Int(nepali.year) == bs.year, Int(nepali.month) == bs.month,
        Int(nepali.dayOfMonth) == bs.day
      {
        nepaliAgrees += 1
      } else {
        details.append(
          "B2 \(ad.year)-\(ad.month)-\(ad.day): expected \(bs.year)-\(bs.month)-\(bs.day), got \(nepali.year)-\(nepali.month)-\(nepali.dayOfMonth)"
        )
      }
    }

    print("shivathapaa: B1 \(englishAgrees)/64, B2 \(nepaliAgrees)/64")
    for detail in details { print("shivathapaa: \(detail)") }
    // Its tables differ from shared/data by one day at BS 2086-07-23, 2088-01-04 and 2089-06-10;
    // each mismatch shows up in both directions.
    #expect(englishAgrees == 61, "B1 agreement: \(details.joined(separator: "; "))")
    #expect(nepaliAgrees == 61, "B2 agreement: \(details.joined(separator: "; "))")
  }
#endif
