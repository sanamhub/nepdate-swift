import Testing

@testable import NepDate

/// The canonical fast path must be indistinguishable from the general loop.
@Suite("Strict parse fast path")
struct ParseFastPathTests {
  /// Every strict separator. The danda `।` is three bytes, so its text is never canonical.
  static let separators: [Character] = ["-", "/", ".", "_", "\\", " ", "|", "।"]

  enum Outcome: Equatable {
    case date(NepaliDate)
    case error(NepDateError)
  }

  /// The closure is untyped `throws` because a literal's thrown type is not inferred from a
  /// typed-throws parameter (see `expectError`); the parser only throws `NepDateError`.
  static func outcome(_ body: () throws -> NepaliDate) -> Outcome {
    do {
      return .date(try body())
    } catch let error as NepDateError {
      return .error(error)
    } catch {
      fatalError("the strict parser threw a non-NepDateError: \(error)")
    }
  }

  /// `YYYY`, separator, two-digit month, separator, two-digit day.
  static func text(year: Int, month: Int, day: Int, separator: Character) -> String {
    let monthText = month < 10 ? "0\(month)" : "\(month)"
    let dayText = day < 10 ? "0\(day)" : "\(day)"
    return "\(year)\(separator)\(monthText)\(separator)\(dayText)"
  }

  @Test("all 109,212 dates and all strict separators parse the same on both paths")
  func everyDateAndSeparator() {
    var log = FailureLog()
    var checked = 0
    var canonicalChecked = 0
    for serial in Int32(0)...CalendarData.maxSerial {
      let date = NepaliDate(serial: serial)
      for separator in Self.separators {
        let text = Self.text(
          year: date.year, month: date.month, day: date.day, separator: separator)
        let fast = Self.outcome { try NepaliDate.parse(text) }
        let slow = Self.outcome { try NepaliDate.parseSlow(text.utf8) }
        if fast != slow {
          log.record(Int(serial), "\(text): fast \(fast), loop \(slow)")
        }
        do {
          let canonical = try NepaliDate.parseCanonical(text.utf8)
          if separator == "।" {
            if canonical != nil {
              log.record(Int(serial), "\(text): a 12-byte danda text took the canonical path")
            }
          } else if canonical == nil {
            log.record(Int(serial), "\(text): a canonical text was declined")
          } else {
            canonicalChecked += 1
          }
        } catch {
          log.record(Int(serial), "\(text): parseCanonical threw \(error)")
        }
        checked += 1
      }
    }
    #expect(checked == 109_212 * Self.separators.count)
    #expect(canonicalChecked == 109_212 * (Self.separators.count - 1))
    #expect(log.count == 0, "\(log.summary)")
  }

  @Test("canonical-shaped invalid dates fail the same way on both paths")
  func invalidCanonical() {
    let texts = [
      "0000/00/00", "9999/99/99", "1900/12/30", "2200/01/01", "2081/13/01", "2081/04/33",
      "2081/04/00", "2081/00/15",
    ]
    for text in texts {
      let fast = Self.outcome { try NepaliDate.parse(text) }
      let slow = Self.outcome { try NepaliDate.parseSlow(text.utf8) }
      #expect(fast == slow, "\(text): fast \(fast), loop \(slow)")
    }
  }
}
