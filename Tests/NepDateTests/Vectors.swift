import Foundation
import Testing

@testable import NepDate

/// A vector file under `shared/spec/vectors/`, split into rows of fields.
struct VectorFile {
  /// Data rows, header and `#` comment lines removed. `line` is the 1-based line in the file.
  let rows: [(line: Int, fields: [Substring])]

  /// Reads `name`, a path relative to `shared/spec/vectors/`, found from this file's location.
  init(_ name: String, separator: Character, filePath: String = #filePath) throws {
    let root = URL(fileURLWithPath: filePath)
      .deletingLastPathComponent()  // NepDateTests
      .deletingLastPathComponent()  // Tests
      .deletingLastPathComponent()  // repository root
    let url = root.appendingPathComponent("shared/spec/vectors/\(name)")
    let text = try String(contentsOf: url, encoding: .utf8)
    var rows: [(line: Int, fields: [Substring])] = []
    var headerSeen = false
    for (index, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated()
    {
      let trimmed = line.hasSuffix("\r") ? line.dropLast() : line
      if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
      if !headerSeen {
        headerSeen = true
        continue
      }
      rows.append(
        (index + 1, trimmed.split(separator: separator, omittingEmptySubsequences: false)))
    }
    self.rows = rows
  }
}

/// Collects the first ten failing rows of a large vector file, so one test reports them together.
struct FailureLog {
  private(set) var count = 0
  private(set) var first: [String] = []

  mutating func record(_ line: Int, _ message: String) {
    count += 1
    if first.count < 10 { first.append("line \(line): \(message)") }
  }

  var summary: String { "\(count) failing rows; first: \(first.joined(separator: "; "))" }
}

@Suite("Vectors")
struct VectorTests {
  @Test("month-boundaries.csv: bs to ad, ad to bs, weekday, month_length")
  func monthBoundaries() throws {
    let file = try VectorFile("month-boundaries.csv", separator: ",")
    #expect(file.rows.count == 7176)
    var log = FailureLog()
    for (line, fields) in file.rows {
      guard fields.count == 4, let b = ymd(fields[0]), let a = ymd(fields[1]) else {
        log.record(line, "malformed")
        continue
      }
      do {
        let date = try bs(b.0, b.1, b.2)
        let g = date.gregorian
        if g.year != a.0 || g.month != a.1 || g.day != a.2 { log.record(line, "ad \(g)") }
        if weekdayNames[date.weekday.rawValue] != fields[2] {
          log.record(line, "weekday \(date.weekday)")
        }
        if String(date.monthLength) != fields[3] {
          log.record(line, "month_length \(date.monthLength)")
        }
        let back = try ad(a.0, a.1, a.2)
        if back != date { log.record(line, "ad to bs gave serial \(back.serial)") }
      } catch {
        log.record(line, "threw \(error)")
      }
    }
    #expect(log.count == 0, "\(log.summary)")
  }

  @Test("csharp-golden/dates.tsv: ad, weekday, day_of_year, month_length")
  func goldenDates() throws {
    let file = try VectorFile("csharp-golden/dates.tsv", separator: "\t")
    #expect(file.rows.count == 1018)
    var log = FailureLog()
    for (line, fields) in file.rows {
      guard fields.count >= 5, let b = ymd(fields[0]), let a = ymd(fields[1]) else {
        log.record(line, "malformed")
        continue
      }
      do {
        let date = try bs(b.0, b.1, b.2)
        let g = date.gregorian
        if g.year != a.0 || g.month != a.1 || g.day != a.2 { log.record(line, "ad \(g)") }
        if weekdayNames[date.weekday.rawValue] != fields[2] {
          log.record(line, "weekday \(date.weekday)")
        }
        if String(date.dayOfYear) != fields[3] { log.record(line, "day_of_year \(date.dayOfYear)") }
        if String(date.monthLength) != fields[4] {
          log.record(line, "month_length \(date.monthLength)")
        }
      } catch {
        log.record(line, "threw \(error)")
      }
    }
    #expect(log.count == 0, "\(log.summary)")
  }
}
