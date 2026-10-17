import Foundation
import NepDate

@testable import NepDatePatro

/// Builds a BS date in a test; a throw fails the test that called it.
func bs(_ year: Int, _ month: Int, _ day: Int) throws -> NepaliDate {
  try NepaliDate(year: year, month: month, day: day)
}

/// The English names of a day's events, in order.
func englishEvents(_ date: NepaliDate) -> [String] {
  date.calendarInfo.events.map { $0.english }
}

/// One day of `shared/data/patro/*.json`, decoded independently of the generator.
struct ReferenceDay: Decodable, Equatable {
  struct Pair: Decodable, Equatable {
    let np: String
    let en: String
  }
  let tithi: Pair?
  let holiday: Bool?
  let events: [Pair]?
}

/// Every day of the patro JSON files, keyed by `YYYY-MM-DD`.
func referenceDays() throws -> [String: ReferenceDay] {
  struct YearFile: Decodable { let days: [String: ReferenceDay] }
  let directory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()  // NepDatePatroTests
    .deletingLastPathComponent()  // Tests
    .deletingLastPathComponent()  // repository root
    .appendingPathComponent("shared/data/patro")
  var days: [String: ReferenceDay] = [:]
  for year in 2077...2084 {
    let data = try Data(contentsOf: directory.appendingPathComponent("\(year).json"))
    for (key, day) in try JSONDecoder().decode(YearFile.self, from: data).days {
      days[key] = day
    }
  }
  return days
}

/// `YYYY-MM-DD` of a date, as the JSON files key their days.
func key(_ date: NepaliDate) -> String {
  func two(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }
  return "\(date.year)-\(two(date.month))-\(two(date.day))"
}
