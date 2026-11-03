import Testing

@testable import NepDate

@Suite("Range vectors")
struct RangeVectorTests {
  @Test("csharp-golden/ranges.tsv")
  func ranges() throws {
    let file = try VectorFile("csharp-golden/ranges.tsv", separator: "\t")
    #expect(file.rows.count == 54)
    var log = FailureLog()
    for (line, fields) in file.rows {
      guard fields.count == 6 else {
        log.record(line, "malformed")
        continue
      }
      let operation = fields[2]
      let argument = String(fields[3])
      let expected = String(fields[4])
      // A D-xx note holds the port's expected value, so it is compared as written.
      do {
        let start = try vectorDate(String(fields[0]))
        let end = try vectorDate(String(fields[1]))
        let range = NepaliDateRange(start, end)
        if operation == "construct" {
          let got = range == nil ? "ERR" : rangeText(range)
          if got != expected { log.record(line, "construct \(got)") }
          continue
        }
        guard let range else {
          log.record(line, "no range for \(operation)")
          continue
        }
        let got: String
        switch operation {
        case "length":
          got = String(range.count)
        case "contains_date":
          got = String(range.contains(try vectorDate(argument)))
        case "contains_range":
          got = String(range.contains(try vectorRange(argument)))
        case "overlaps":
          got = String(range.overlaps(try vectorRange(argument)))
        case "is_adjacent_to":
          got = String(range.isAdjacent(to: try vectorRange(argument)))
        case "intersect":
          got = rangeText(range.intersection(try vectorRange(argument)))
        case "union":
          got = rangeText(range.union(try vectorRange(argument)))
        case "except":
          got = rangesText(range.subtracting(try vectorRange(argument)))
        case "equals":
          got = String(range == (try vectorRange(argument)))
        case "to_string":
          got = range.description
        case "enumerate":
          got = datesText(Array(range))
        default:
          got = "unknown \(operation)"
        }
        if got != expected { log.record(line, "\(operation) got \(got)") }
      } catch {
        if expected != "ERR" { log.record(line, "threw \(error)") }
        if fields[2] == "construct" && expected == "ERR" { continue }
      }
    }
    #expect(log.count == 0, "\(log.summary)")
  }

  @Test("csharp-golden/range-factories.tsv")
  func factories() throws {
    let file = try VectorFile("csharp-golden/range-factories.tsv", separator: "\t")
    #expect(file.rows.count == 27)
    var log = FailureLog()
    for (line, fields) in file.rows {
      guard fields.count == 4 else {
        log.record(line, "malformed")
        continue
      }
      let factory = fields[0]
      let argument = String(fields[1])
      let expected = String(fields[2])
      var got = "ERR"
      do {
        switch factory {
        case "single_day":
          got = rangeText(NepaliDateRange.singleDay(try vectorDate(argument)))
        case "from_day_count":
          let parts = argument.split(separator: ",").map(String.init)
          guard parts.count == 2, let count = Int(parts[1]) else {
            log.record(line, "malformed from_day_count")
            continue
          }
          got = rangeText(try NepaliDateRange(start: vectorDate(parts[0]), dayCount: count))
        case "for_month":
          let parts = argument.split(separator: ",").compactMap { Int($0) }
          guard parts.count == 2 else {
            log.record(line, "malformed for_month")
            continue
          }
          got = rangeText(try NepaliDateRange.month(year: parts[0], month: parts[1]))
        case "for_calendar_year":
          guard let year = Int(argument) else {
            log.record(line, "malformed for_calendar_year")
            continue
          }
          got = rangeText(try NepaliDateRange.year(year))
        case "for_fiscal_year":
          guard let year = Int(argument) else {
            log.record(line, "malformed for_fiscal_year")
            continue
          }
          got = rangeText(try FiscalYear(startYear: year).range())
        case "construct":
          let parts = argument.split(separator: ",").map(String.init)
          guard parts.count == 2 else {
            log.record(line, "malformed construct")
            continue
          }
          let range = try NepaliDateRange(vectorDate(parts[0]), vectorDate(parts[1]))
          got = range == nil ? "ERR" : rangeText(range)
        default:
          log.record(line, "unknown factory \(factory)")
          continue
        }
      } catch {
        got = "ERR"
      }
      if got != expected { log.record(line, "\(factory) \(argument) got \(got)") }
    }
    #expect(log.count == 0, "\(log.summary)")
  }

  @Test("csharp-golden/range-splits.tsv")
  func splits() throws {
    let file = try VectorFile("csharp-golden/range-splits.tsv", separator: "\t")
    #expect(file.rows.count == 9)
    var log = FailureLog()
    for (line, fields) in file.rows {
      guard fields.count == 5 else {
        log.record(line, "malformed")
        continue
      }
      let operation = fields[2]
      let expected = String(fields[3])
      do {
        let range = try NepaliDateRange(
          vectorDate(String(fields[0])), vectorDate(String(fields[1])))
        guard let range else {
          log.record(line, "no range")
          continue
        }
        let got: String
        switch operation {
        case "split_by_month": got = rangesText(range.splitByMonth())
        case "split_by_fiscal_quarter": got = rangesText(range.splitByFiscalQuarter())
        default: got = "unknown \(operation)"
        }
        if got != expected { log.record(line, "\(operation) got \(got)") }
      } catch {
        log.record(line, "threw \(error)")
      }
    }
    #expect(log.count == 0, "\(log.summary)")
  }

  @Test("csharp-golden/range-days.tsv")
  func days() throws {
    let file = try VectorFile("csharp-golden/range-days.tsv", separator: "\t")
    #expect(file.rows.count == 18)
    var log = FailureLog()
    for (line, fields) in file.rows {
      guard fields.count == 6 else {
        log.record(line, "malformed")
        continue
      }
      let operation = fields[2]
      let argument = String(fields[3])
      let expected = String(fields[4])
      do {
        let range = try NepaliDateRange(
          vectorDate(String(fields[0])), vectorDate(String(fields[1])))
        guard let range else {
          log.record(line, "no range")
          continue
        }
        let got: String
        switch operation {
        case "dates_with_interval":
          guard let interval = Int(argument) else {
            log.record(line, "malformed interval")
            continue
          }
          got = datesText(try range.dates(every: interval))
        case "working_days":
          got = datesText(range.workingDays(excludingSunday: argument == "true"))
        case "weekend_days":
          got = datesText(range.weekendDays(includingSunday: argument == "true"))
        case "enumerate":
          got = datesText(Array(range))
        default:
          got = "unknown \(operation)"
        }
        if got != expected { log.record(line, "\(operation) got \(got)") }
      } catch {
        if expected != "ERR" { log.record(line, "threw \(error)") }
      }
    }
    #expect(log.count == 0, "\(log.summary)")
  }

  @Test("csharp-golden/range-format.tsv")
  func formatting() throws {
    let file = try VectorFile("csharp-golden/range-format.tsv", separator: "\t")
    #expect(file.rows.count == 18)
    var log = FailureLog()
    for (line, fields) in file.rows {
      guard fields.count == 8 else {
        log.record(line, "malformed")
        continue
      }
      let kind = fields[2]
      let expected = String(fields[6])
      do {
        let range = try NepaliDateRange(
          vectorDate(String(fields[0])), vectorDate(String(fields[1])))
        guard let range else {
          if expected == "ERR" { continue }
          log.record(line, "no range")
          continue
        }
        let got: String
        if kind == "default" {
          got = range.description
        } else {
          guard let order = dateOrder(fields[3]), let separator = dateSeparator(fields[4]) else {
            log.record(line, "malformed format")
            continue
          }
          got = range.formatted(order: order, separator: separator, lang: language(fields[5]))
        }
        if got != expected { log.record(line, "\(kind) got \(got)") }
      } catch {
        if expected != "ERR" { log.record(line, "threw \(error)") }
      }
    }
    #expect(log.count == 0, "\(log.summary)")
  }

  @Test("fromDayCount and dates(every:) at Int.max do not overflow or wrap")
  func maximumInputs() throws {
    let start = try bs(2081, 4, 15)
    let range = try NepaliDateRange(start: start, dayCount: 3)
    #expect(try range.dates(every: Int.max) == [start])
    #expect(try range.dates(every: 2) == [start, try start.adding(days: 2)])
    expectError(.invalidArgument) { _ = try range.dates(every: 0) }
    expectError(.invalidArgument) { _ = try range.dates(every: -1) }
    expectError(.outOfRange) { _ = try NepaliDateRange(start: start, dayCount: Int.max) }
    expectError(.outOfRange) { _ = try NepaliDateRange(start: .max, dayCount: 2) }
    expectError(.invalidArgument) { _ = try NepaliDateRange(start: start, dayCount: 0) }
    #expect(try NepaliDateRange(start: NepaliDate.max, dayCount: 1) == .singleDay(NepaliDate.max))
  }

  @Test("a valid range at the data end never throws")
  func dataEnd() throws {
    let last = try NepaliDateRange(start: try bs(2199, 11, 30), dayCount: 31)
    #expect(last.count == 31)
    #expect(Array(last).last == NepaliDate.max)
    #expect(last.splitByMonth().last?.upperBound == NepaliDate.max)
    #expect(last.splitByFiscalQuarter().last?.upperBound == NepaliDate.max)
    #expect(last.workingDays().last == NepaliDate.max)
    #expect(try last.dates(every: 1).last == NepaliDate.max)
    #expect(!last.isAdjacent(to: NepaliDateRange.singleDay(NepaliDate.max)))
  }
}

/// The `DateOrder` value of a `format-matrix.tsv` cell.
func dateOrder(_ text: Substring) -> DateOrder? {
  switch text {
  case "Ymd": return .ymd
  case "Ydm": return .ydm
  case "Myd": return .myd
  case "Mdy": return .mdy
  case "Dym": return .dym
  case "Dmy": return .dmy
  default: return nil
  }
}

/// The `Separator` value of a `format-matrix.tsv` cell.
func dateSeparator(_ text: Substring) -> Separator? {
  switch text {
  case "Slash": return .slash
  case "Backslash": return .backslash
  case "Dot": return .dot
  case "Underscore": return .underscore
  case "Dash": return .dash
  case "Space": return .space
  default: return nil
  }
}

/// The `Lang` value of a vector cell.
func language(_ text: Substring) -> Lang {
  text == "ne" ? .nepali : .english
}
