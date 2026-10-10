import Foundation
import Testing

@testable import NepDate

/// The PARSING §4 name of an error kind, as `parse.tsv` writes it after `ERR:`.
func kindName(_ kind: NepDateError.Kind) -> String {
  switch kind {
  case .outOfRange: return "OutOfRange"
  case .invalidMonth: return "InvalidMonth"
  case .invalidDay: return "InvalidDay"
  case .invalidGregorian: return "InvalidGregorian"
  case .invalidCharacter: return "InvalidCharacter"
  case .wrongGroupCount: return "WrongGroupCount"
  case .numberTooLong: return "NumberTooLong"
  case .ambiguous: return "Ambiguous"
  case .unrecognized: return "Unrecognized"
  }
}

/// A parse result as `parse.tsv` writes it: `YYYY-MM-DD` or `ERR:<Kind>`.
func parseResult(_ body: () throws(NepDateError) -> NepaliDate) -> String {
  do {
    return try body().format("s")
  } catch {
    return "ERR:" + kindName(error.kind)
  }
}

@Suite("Formatting")
struct FormattingTests {
  @Test("S3-01 AC1: month and weekday names")
  func names() {
    #expect(Month.ashad.shortName() == "Asa")
    #expect(Month.ashoj.shortName() == "Aso")
    #expect(Month.shrawan.shortName(.nepali) == "साउन")
    let english = Month.allCases.map { $0.name() }
    #expect(
      english == [
        "Baishakh", "Jestha", "Ashad", "Shrawan", "Bhadra", "Ashoj", "Kartik", "Mangsir", "Poush",
        "Magh", "Falgun", "Chaitra",
      ])
    let short = Month.allCases.map { $0.shortName() }
    #expect(
      short == ["Bai", "Jes", "Asa", "Shr", "Bha", "Aso", "Kar", "Man", "Pou", "Mag", "Fal", "Cha"])
    let nepali = Month.allCases.map { $0.name(.nepali) }
    #expect(
      nepali == [
        "बैशाख", "जेठ", "असार", "साउन", "भदौ", "असोज", "कार्तिक", "मंसिर", "पुष", "माघ", "फागुन", "चैत",
      ])
    #expect(Month.allCases.allSatisfy { $0.shortName(.nepali) == $0.name(.nepali) })
    let days = Weekday.allCases.map { $0.name() }
    #expect(days == weekdayNames)
    let shortDays = Weekday.allCases.map { $0.shortName() }
    #expect(shortDays == ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
    #expect(
      Weekday.allCases.map { $0.name(.nepali) } == [
        "आइतवार", "सोमवार", "मङ्गलवार", "बुधवार", "बिहिवार", "शुक्रवार", "शनिवार",
      ])
    #expect(
      Weekday.allCases.map { $0.shortName(.nepali) } == [
        "आइत", "सोम", "मङ्गल", "बुध", "बिहि", "शुक्र", "शनि",
      ])
  }

  @Test("S3-01 AC2: nepaliDigits")
  func digits() {
    #expect(nepaliDigits(2081) == "२०८१")
    #expect(nepaliDigits(5, minWidth: 2) == "०५")
    #expect(nepaliDigits(0) == "०")
    #expect(nepaliDigits(-42) == "-४२")
    #expect(nepaliDigits(1_234_567_890) == "१२३४५६७८९०")
    #expect(nepaliDigits(Int.min).count == 20)
  }

  @Test("S3-02 AC: csharp-golden/dates.tsv text columns")
  func goldenText() throws {
    let file = try VectorFile("csharp-golden/dates.tsv", separator: "\t")
    #expect(file.rows.count == 1018)
    var log = FailureLog()
    for (line, fields) in file.rows {
      guard fields.count == 16, let date = try goldenDate(fields[0]) else {
        log.record(line, "malformed")
        continue
      }
      let got = [
        date.description, date.short(lang: .nepali), date.long(), date.long(weekday: true),
        date.long(lang: .nepali), date.long(weekday: true, lang: .nepali),
        date.short(order: .dmy, separator: .dash, pad: false),
      ]
      let expected = fields[5...11].map(String.init)
      if got != expected { log.record(line, "got \(got)") }
      var buffer = "x"
      date.appendLong(to: &buffer, weekday: true, lang: .nepali)
      date.appendShort(to: &buffer, separator: .dot)
      if buffer != "x" + got[5] + date.short(separator: .dot) { log.record(line, "append forms") }
    }
    #expect(log.count == 0, "\(log.summary)")
  }

  @Test("S3-02: FORMATTING §3 and §4 examples")
  func formattingExamples() throws {
    let bhadra = try bs(2080, 5, 15)
    #expect(bhadra.short(separator: .dash) == "2080-05-15")
    #expect(bhadra.short(order: .dmy, separator: .dash, pad: false) == "15-5-2080")
    #expect(bhadra.short(lang: .nepali) == "२०८०/०५/१५")
    let shrawan = try bs(2081, 4, 15)
    #expect(shrawan.long() == "Shrawan 15, 2081")
    #expect(shrawan.long(lang: .nepali) == "साउन १५, २०८१")
    #expect(shrawan.long(weekday: true) == "Tuesday, Shrawan 15, 2081")
    #expect(shrawan.long(weekday: true, lang: .nepali) == "मङ्गलवार, साउन १५, २०८१")
    #expect(NepaliDate.min.long() == "Baishakh 01, 1901")
    #expect(NepaliDate.min.long(lang: .nepali) == "बैशाख ०१, १९०१")
    let jestha = try bs(2079, 2, 6)
    #expect(jestha.long(weekday: true, year: false, pad: false) == "Friday, Jestha 6")
    #expect(jestha.long(weekday: true, year: false, pad: false, lang: .nepali) == "शुक्रवार, जेठ ६")
  }

  @Test("S3-03 AC1: csharp-golden/format-pattern.tsv")
  func goldenPatterns() throws {
    let file = try VectorFile("csharp-golden/format-pattern.tsv", separator: "\t")
    #expect(file.rows.count == 451)
    var log = FailureLog()
    var checked = 0
    var skipped = 0
    for (line, fields) in file.rows {
      guard fields.count == 3, let date = try goldenDate(fields[0]) else {
        log.record(line, "malformed")
        continue
      }
      let pattern = String(fields[1])
      // D-04: C# abbreviates Ashad and Ashoj both as "Ash"; NepDate writes "Asa" and "Aso".
      let shortMonth = pattern.contains("MMM") && !pattern.contains("MMMM")
      if shortMonth && (date.month == 3 || date.month == 6) {
        skipped += 1
        continue
      }
      let got = date.format(pattern)
      if got != fields[2] { log.record(line, "\(pattern) gave \(got)") }
      checked += 1
    }
    #expect(skipped >= 1)
    #expect(checked + skipped == 451)
    #expect(log.count == 0, "\(log.summary)")
  }

  @Test("S3-03 AC2: FORMATTING §5 examples")
  func patternExamples() throws {
    let date = try bs(2081, 4, 15)
    #expect(date.format("yyyy-MM-dd") == "2081-04-15")
    #expect(date.format("M/d/yyyy") == "4/15/2081")
    #expect(date.format("yyyy'BS'") == "2081BS")
    #expect(date.format("yyyy\\M\\M-\\d\\d") == "2081MM-dd")
    #expect(date.format("MMM yyyy") == "Shr 2081")
    #expect(date.format("dd.MM.yy") == "15.04.81")
    #expect(date.format("yyyy-MM-dd", lang: .nepali) == "२०८१-०४-१५")
    #expect(date.format("s", lang: .nepali) == "२०८१-०४-१५")
    #expect(date.format("") == "2081/04/15" && date.format("G") == "2081/04/15")
    #expect(date.format("D") == "Shrawan 15, 2081")
    #expect(date.format("yyyy\\") == "2081")
    #expect(date.format("'unterminated yyyy") == "unterminated yyyy")
    #expect(date.format("MMMM ddd, साल yyyy", lang: .nepali) == "साउन १५, साल २०८१")
    #expect(date.format("\\साउन") == "साउन")
    var buffer = ""
    buffer.reserveCapacity(64)
    date.appendFormat("dd", to: &buffer)
    date.appendFormat("/MM", to: &buffer, lang: .nepali)
    #expect(buffer == "15/०४")
  }
}

@Suite("Parsing")
struct ParsingTests {
  @Test("S3-04 AC and S3-05 AC1: parse.tsv, strict and lenient")
  func parseVectors() throws {
    let file = try VectorFile("parse.tsv", separator: "\t")
    #expect(file.rows.count == 63)
    var log = FailureLog()
    for (line, fields) in file.rows {
      guard fields.count == 3 else {
        log.record(line, "malformed")
        continue
      }
      let input = fields[0]
      let strict = parseResult { () throws(NepDateError) -> NepaliDate in
        try NepaliDate.parse(input)
      }
      if strict != fields[1] { log.record(line, "strict \(strict)") }
      let lenient = parseResult { () throws(NepDateError) -> NepaliDate in
        try NepaliDate.parseLenient(input)
      }
      if lenient != fields[2] { log.record(line, "lenient \(lenient)") }
      // init?(_:) is the strict parser.
      if (NepaliDate(String(input)) != nil) != !fields[1].hasPrefix("ERR") {
        log.record(line, "init?(_:)")
      }
    }
    #expect(log.count == 0, "\(log.summary)")
  }

  @Test("S3-05 AC2: month-name forms and two-digit years")
  func lenientExamples() throws {
    let expected = try bs(2080, 4, 15)
    #expect(try NepaliDate.parseLenient("15 Shrawan 2080") == expected)
    #expect(try NepaliDate.parseLenient("Shrawan 15, 2080") == expected)
    #expect(try NepaliDate.parseLenient("2080 Shrawan 15") == expected)
    expectError(.ambiguous) { _ = try NepaliDate.parseLenient("15/04/80") }
  }

  /// Every Devanagari name in the closed list is the same in NFC and NFD (the generator checks
  /// it), so an NFD input is byte-identical to the NFC one and matches. A canonically equivalent
  /// spelling in neither form would not match; no name in the list has such a spelling.
  @Test("S3-05: Devanagari month names in NFD")
  func nfdInput() throws {
    for (text, month) in [("15 साउन 2080", 4), ("15 श्रावण 2080", 4), ("1 मार्गशीर्ष 2080", 8)] {
      let nfd = text.decomposedStringWithCanonicalMapping
      #expect(Array(nfd.utf8) == Array(text.utf8))
      #expect(try NepaliDate.parseLenient(nfd).month == month)
    }
  }

  @Test("S3-04: a Substring parses in place")
  func substring() throws {
    let text = "date: 2081/04/15!"
    let start = text.index(text.startIndex, offsetBy: 6)
    let end = text.index(before: text.endIndex)
    #expect(try NepaliDate.parse(text[start..<end]) == bs(2081, 4, 15))
    #expect(try NepaliDate.parseLenient(text[start..<end]) == bs(2081, 4, 15))
  }

  @Test("S3-06 AC1 and AC2: Codable as a single string")
  func codable() throws {
    let date = try bs(2081, 4, 15)
    let data = try JSONEncoder().encode([date])
    #expect(String(decoding: data, as: UTF8.self) == "[\"2081-04-15\"]")
    #expect(try JSONDecoder().decode([NepaliDate].self, from: data) == [date])
    var corrupted = false
    do {
      _ = try JSONDecoder().decode([NepaliDate].self, from: Data("[\"2081-04-33\"]".utf8))
    } catch DecodingError.dataCorrupted {
      corrupted = true
    } catch {
      Issue.record("expected dataCorrupted, got \(error)")
    }
    #expect(corrupted)
  }

  @Test("S3-06 AC3: description round-trips through init?(_:) for every golden date")
  func losslessRoundTrip() throws {
    let file = try VectorFile("csharp-golden/dates.tsv", separator: "\t")
    let dates = try file.rows.compactMap { try goldenDate($0.fields[0]) }
    #expect(dates.count == 1018)
    #expect(dates.allSatisfy { NepaliDate($0.description) == $0 })
  }
}
