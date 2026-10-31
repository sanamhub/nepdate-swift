import Foundation
import NepDate

@testable import NepDatePatro

/// The repository root, three directories above this file.
let repositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()  // NepDatePatroTests
  .deletingLastPathComponent()  // Tests
  .deletingLastPathComponent()  // repository root

/// Builds a BS date in a test; a throw fails the test that called it.
func bs(_ year: Int, _ month: Int, _ day: Int) throws -> NepaliDate {
  try NepaliDate(year: year, month: month, day: day)
}

/// The English names of a day's events, in order.
func englishEvents(_ date: NepaliDate) -> [String] {
  date.calendarInfo.events.map { $0.english }
}

/// Why `shared/spec/vectors/patro-summary.json` could not be read.
enum PatroSummaryError: Error {
  /// The file is not a JSON object.
  case notAnObject
  /// The field is missing or has the wrong type.
  case missing(String)
}

/// The patro counts the hub generates in `shared/spec/vectors/patro-summary.json`. Tests read the
/// file at run time, so no test pins a number that a data update changes.
struct PatroSummary {
  let firstYear: Int
  let lastYear: Int
  let firstDay: String
  let lastDay: String
  let firstSerial: Int
  let lastSerial: Int
  let days: Int
  let tithiFirstDay: String
  let tithiLastDay: String
  let tithiFirstSerial: Int
  let tithiDays: Int
  let tithiNames: Int
  let holidays: Int
  let eventDays: Int
  let events: Int
  let eventNames: Int
  let names: Int
  let nameBytes: Int

  /// Reads the summary from the `shared/` this repository vendors.
  init() throws {
    let url = repositoryRoot.appendingPathComponent("shared/spec/vectors/patro-summary.json")
    guard
      let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
        as? [String: Any]
    else { throw PatroSummaryError.notAnObject }
    func int(_ key: String) throws -> Int {
      guard let value = object[key] as? Int else { throw PatroSummaryError.missing(key) }
      return value
    }
    func text(_ key: String) throws -> String {
      guard let value = object[key] as? String else { throw PatroSummaryError.missing(key) }
      return value
    }
    firstYear = try int("first_year")
    lastYear = try int("last_year")
    firstDay = try text("first_day")
    lastDay = try text("last_day")
    firstSerial = try int("first_serial")
    lastSerial = try int("last_serial")
    days = try int("days")
    tithiFirstDay = try text("tithi_first_day")
    tithiLastDay = try text("tithi_last_day")
    tithiFirstSerial = try int("tithi_first_serial")
    tithiDays = try int("tithi_days")
    tithiNames = try int("tithi_names")
    holidays = try int("holidays")
    eventDays = try int("event_days")
    events = try int("events")
    eventNames = try int("event_names")
    names = try int("names")
    nameBytes = try int("name_bytes")
  }
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
  let summary = try PatroSummary()
  let directory = repositoryRoot.appendingPathComponent("shared/data/patro")
  var days: [String: ReferenceDay] = [:]
  for year in stride(from: summary.firstYear, through: summary.lastYear, by: 1) {
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
