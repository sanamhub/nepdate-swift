import Testing

#if canImport(Foundation)
  import Foundation
#endif

@testable import NepDate

@Suite("Integer form")
struct IntegerTests {
  @Test("csharp-golden/ymd-int.tsv")
  func ymdVectors() throws {
    let file = try VectorFile("csharp-golden/ymd-int.tsv", separator: "\t")
    #expect(file.rows.count == 14)
    var log = FailureLog()
    for (line, fields) in file.rows {
      guard fields.count == 5, fields[4].hasPrefix("D-11") else {
        log.record(line, "malformed")
        continue
      }
      switch fields[0] {
      case "date":
        do {
          let date = try vectorDate(String(fields[1]))
          if String(date.ymd) != fields[2] { log.record(line, "ymd \(date.ymd)") }
          if bsText(date) != fields[3] { log.record(line, "date \(bsText(date))") }
        } catch {
          log.record(line, "threw \(error)")
        }
      case "int":
        guard let value = Int(fields[2]) else {
          log.record(line, "malformed int")
          continue
        }
        let date = NepaliDate(ymd: value)
        if fields[3] == "ERR" {
          if date != nil { log.record(line, "expected nil, got \(bsText(date!))") }
        } else if let date {
          if bsText(date) != fields[3] { log.record(line, "int gave \(bsText(date))") }
        } else {
          log.record(line, "unexpected nil")
        }
      default:
        log.record(line, "unknown kind \(fields[0])")
      }
    }
    #expect(log.count == 0, "\(log.summary)")
  }

  @Test("a wider integer never wraps into a valid date")
  func widerIntegerDoesNotWrap() {
    #expect(NepaliDate(ymd: Int.max) == nil)
    #expect(NepaliDate(ymd: Int.max - 1) == nil)
    #expect(NepaliDate(ymd: Int.min) == nil)
    #expect(NepaliDate(ymd: 0) == nil)
    #expect(NepaliDate(ymd: -20_810_415) == nil)
    #expect(NepaliDate(ymd: 120_810_415) == nil)
  }
}

#if canImport(Foundation)
  @Suite("Bulk conversion")
  struct BulkTests {
    @Test("csharp-golden/bulk.tsv keeps the input order")
    func bulkVectors() throws {
      let file = try VectorFile("csharp-golden/bulk.tsv", separator: "\t")
      #expect(file.rows.count == 6)
      let utc = try #require(TimeZone(secondsFromGMT: 0))
      var log = FailureLog()
      for (line, fields) in file.rows {
        guard fields.count == 4 else {
          log.record(line, "malformed")
          continue
        }
        let operation = fields[0]
        let input = fields[1].split(separator: ";").map(String.init)
        let expected = String(fields[2])
        let got = bulkResult {
          switch operation {
          case "to_nepali_dates", "batch_to_nepali_dates":
            let dates = try input.map { text in
              try #require(adDate(text, in: utc))
            }
            return datesText(try NepaliDate.fromGregorian(dates, in: utc))
          case "to_english_dates_from_strings", "batch_to_english_dates":
            let dates = try NepaliDate.gregorianDates(from: input, in: utc)
            return dates.map { adText($0, in: utc) }.joined(separator: ";")
          case "to_english_dates_from_dates":
            let dates = try input.map(vectorDate)
            let english = NepaliDate.gregorianDates(from: dates, in: utc)
            return english.map { adText($0, in: utc) }.joined(separator: ";")
          default:
            return "unknown \(operation)"
          }
        }
        if got != expected { log.record(line, "\(operation) got \(got)") }
      }
      #expect(log.count == 0, "\(log.summary)")
    }

    @Test("the empty inputs give empty results")
    func emptyInput() throws {
      let utc = try #require(TimeZone(secondsFromGMT: 0))
      #expect(try NepaliDate.fromGregorian([], in: utc).isEmpty)
      #expect(try NepaliDate.gregorianDates(from: [String](), in: utc).isEmpty)
      #expect(NepaliDate.gregorianDates(from: [NepaliDate](), in: utc).isEmpty)
    }
  }

  /// The vector's `ERR`: any `NepDateError` from a bulk call.
  func bulkResult(_ body: () throws -> String) -> String {
    do {
      return try body()
    } catch {
      return "ERR"
    }
  }

  @Suite("Serialization")
  struct SerializationTests {
    @Test("csharp-golden/serialization.tsv, the Codable string hook")
    func serializationVectors() throws {
      let file = try VectorFile("csharp-golden/serialization.tsv", separator: "\t")
      #expect(file.rows.count == 11)
      var log = FailureLog()
      for (line, fields) in file.rows {
        guard fields.count == 5 else {
          log.record(line, "malformed")
          continue
        }
        let kind = fields[0]
        switch kind {
        case "write":
          do {
            let date = try vectorDate(String(fields[1]))
            let json = String(decoding: try JSONEncoder().encode(date), as: UTF8.self)
            if json != fields[2] { log.record(line, "write gave \(json)") }
          } catch {
            log.record(line, "threw \(error)")
          }
        case "read":
          let json = String(fields[1])
          do {
            let date = try JSONDecoder().decode(NepaliDate.self, from: Data(json.utf8))
            if fields[3] == "ERR" { log.record(line, "expected an error, got \(bsText(date))") }
            if bsText(date) != fields[3] { log.record(line, "read gave \(bsText(date))") }
          } catch {
            if fields[3] != "ERR" { log.record(line, "read threw \(error)") }
          }
        case "roundtrip":
          do {
            let date = try vectorDate(String(fields[1]))
            let data = try JSONEncoder().encode(date)
            let json = String(decoding: data, as: UTF8.self)
            if json != fields[2] { log.record(line, "roundtrip json \(json)") }
            let back = try JSONDecoder().decode(NepaliDate.self, from: data)
            if bsText(back) != fields[3] { log.record(line, "roundtrip gave \(bsText(back))") }
          } catch {
            log.record(line, "threw \(error)")
          }
        default:
          log.record(line, "unknown kind \(kind)")
        }
      }
      #expect(log.count == 0, "\(log.summary)")
    }

    @Test("null and a non-canonical string are rejected")
    func rejectsInvalidJSON() {
      for text in ["null", "\"2081/04/15\"", "\"2081-4-15\"", "\"2081-01-32\""] {
        var threw = false
        do {
          _ = try JSONDecoder().decode(NepaliDate.self, from: Data(text.utf8))
        } catch {
          threw = true
        }
        #expect(threw, "\(text)")
      }
    }
  }
#endif
