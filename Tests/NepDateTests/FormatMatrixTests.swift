import Testing

#if canImport(Foundation)
  import Foundation
#endif

@testable import NepDate

@Suite("Format matrix")
struct FormatMatrixTests {
  @Test("csharp-golden/format-matrix.tsv")
  func matrix() throws {
    let file = try VectorFile("csharp-golden/format-matrix.tsv", separator: "\t")
    #expect(file.rows.count == 102)
    var log = FailureLog()
    for (line, fields) in file.rows {
      guard fields.count == 10 else {
        log.record(line, "malformed")
        continue
      }
      let kind = fields[0]
      let expected = String(fields[8])
      do {
        let date = try vectorDate(String(fields[1]))
        switch kind {
        case "short":
          guard let order = dateOrder(fields[2]), let separator = dateSeparator(fields[3]) else {
            log.record(line, "malformed order or separator")
            continue
          }
          let got = date.short(
            order: order, separator: separator, pad: fields[4] == "true",
            lang: language(fields[5]))
          if got != expected { log.record(line, "short got \(got)") }
        case "try_format":
          let pattern = String(fields[6])
          guard let capacity = Int(fields[7]) else {
            log.record(line, "malformed capacity")
            continue
          }
          // The port's NF07 form appends to a caller's buffer and always writes the whole text;
          // the C# column records ERR when its fixed buffer is too small, so that case is
          // checked against the full text instead.
          let full = pattern == "default" ? date.description : date.format(pattern)
          var buffer = ""
          if pattern == "default" {
            date.appendShort(to: &buffer)
          } else {
            date.appendFormat(pattern, to: &buffer)
          }
          if buffer != full { log.record(line, "append gave \(buffer), want \(full)") }
          if expected != "ERR" && expected != full {
            log.record(line, "full text \(full), want \(expected)")
          }
          if (capacity >= full.utf8.count) != (expected != "ERR") {
            log.record(line, "capacity \(capacity) disagrees with \(expected)")
          }
        default:
          log.record(line, "unknown kind \(kind)")
        }
      } catch {
        log.record(line, "threw \(error)")
      }
    }
    #expect(log.count == 0, "\(log.summary)")
  }
}

#if canImport(Foundation)
  @Suite("FormatStyle")
  struct FormatStyleTests {
    @Test("short and long styles match the formatter methods")
    func styles() throws {
      let date = try bs(2081, 4, 15)
      #expect(date.formatted() == "2081/04/15")
      #expect(date.formatted(.short) == "2081/04/15")
      #expect(date.formatted(.long) == "Shrawan 15, 2081")
      #expect(
        date.formatted(NepaliDate.FormatStyle(order: .dmy, separator: .dash)) == "15-04-2081")
      #expect(date.formatted(NepaliDate.FormatStyle(language: .nepali)) == "२०८१/०४/१५")
      #expect(
        date.formatted(NepaliDate.FormatStyle(form: .long, language: .nepali))
          == "साउन १५, २०८१")
      #expect(
        date.formatted(NepaliDate.FormatStyle(form: .long, weekday: true))
          == "Tuesday, Shrawan 15, 2081")
      #expect(
        date.formatted(
          NepaliDate.FormatStyle(form: .long, weekday: true, year: false, pad: false))
          == "Tuesday, Shrawan 15")
    }

    @Test("a style is Codable")
    func styleCodable() throws {
      let style = NepaliDate.FormatStyle(
        form: .long, order: .dmy, separator: .dot, language: .nepali, weekday: true, year: false,
        pad: false)
      let data = try JSONEncoder().encode(style)
      let back = try JSONDecoder().decode(NepaliDate.FormatStyle.self, from: data)
      #expect(back == style)
    }

    @Test("a style works where any FormatStyle is expected")
    func genericStyle() throws {
      let date = try bs(2081, 4, 15)
      func render<Style: FormatStyle>(_ style: Style, _ value: Style.FormatInput)
        -> Style.FormatOutput where Style.FormatInput == NepaliDate
      {
        style.format(value)
      }
      #expect(render(NepaliDate.FormatStyle.long, date) == "Shrawan 15, 2081")
      #expect(render(NepaliDate.FormatStyle.short, date) == "2081/04/15")
    }
  }
#endif
