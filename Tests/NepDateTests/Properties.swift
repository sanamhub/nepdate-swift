import Testing

@testable import NepDate

/// SplitMix64 (Steele, Lea and Flood 2014): a small seeded generator, so every run tests the same
/// cases and a failure can be replayed.
struct SplitMix64: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}

@Suite("Properties")
struct PropertyTests {
  static let seed: UInt64 = 0x4E45_5044_4154_4531  // "NEPDATE1"
  static let cases = 100_000

  /// The kind ALGORITHM §3 predicts, written out separately from the initialiser under test.
  static func expectedKind(_ year: Int, _ month: Int, _ day: Int) -> NepDateError.Kind? {
    guard (1901...2199).contains(year) else { return .outOfRange }
    guard (1...12).contains(month) else { return .invalidMonth }
    let index = (year - 1901) * 12 + month - 1
    let length = Int(CalendarData.monthStart[index + 1] - CalendarData.monthStart[index])
    return (1...length).contains(day) ? nil : .invalidDay(monthLength: length)
  }

  @Test("P1: init(year:month:day:) throws the ALGORITHM §3 kind or keeps the fields")
  func validationMatchesSpec() {
    var rng = SplitMix64(seed: Self.seed)
    var failures = 0
    for _ in 0..<Self.cases {
      let year = Int.random(in: 1850...2250, using: &rng)
      let month = Int.random(in: 0...14, using: &rng)
      let day = Int.random(in: 0...34, using: &rng)
      let expected = Self.expectedKind(year, month, day)
      do {
        let date = try NepaliDate(year: year, month: month, day: day)
        if expected != nil || date.year != year || date.month != month || date.day != day {
          failures += 1
        }
      } catch {
        if error.kind != expected { failures += 1 }
      }
    }
    #expect(failures == 0)
  }

  @Test("P2: serial order is date order")
  func serialOrder() {
    var rng = SplitMix64(seed: Self.seed ^ 2)
    var failures = 0
    for _ in 0..<Self.cases {
      let a = Int32.random(in: 0..<CalendarData.maxSerial, using: &rng)
      let b = Int32.random(in: (a + 1)...CalendarData.maxSerial, using: &rng)
      let first = NepaliDate(serial: a)
      let second = NepaliDate(serial: b)
      if !(first < second) || first == second { failures += 1 }
      let fieldsOrdered =
        (first.year, first.month, first.day) < (second.year, second.month, second.day)
      if !fieldsOrdered { failures += 1 }
    }
    #expect(failures == 0)
  }

  @Test("P3: init(gregorianYear:month:day:) of d.gregorian is d")
  func gregorianRoundTrip() {
    var rng = SplitMix64(seed: Self.seed ^ 3)
    var failures = 0
    for _ in 0..<Self.cases {
      let date = NepaliDate(serial: Int32.random(in: 0...CalendarData.maxSerial, using: &rng))
      let g = date.gregorian
      if (try? NepaliDate(gregorianYear: g.year, month: g.month, day: g.day)) != date {
        failures += 1
      }
    }
    #expect(failures == 0)
  }

  @Test("P4: adding n days then -n days gives the date back")
  func addDaysRoundTrip() {
    var rng = SplitMix64(seed: Self.seed ^ 4)
    var failures = 0
    for _ in 0..<Self.cases {
      let date = NepaliDate(serial: Int32.random(in: 0...CalendarData.maxSerial, using: &rng))
      let n = Int.random(in: -120_000...120_000, using: &rng)
      guard let moved = try? date.adding(days: n) else { continue }
      if (try? moved.adding(days: -n)) != date { failures += 1 }
    }
    #expect(failures == 0)
  }

  @Test("P5: days(until:) of d.adding(days: n) is n")
  func daysUntilMatchesAdding() {
    var rng = SplitMix64(seed: Self.seed ^ 5)
    var failures = 0
    for _ in 0..<Self.cases {
      let date = NepaliDate(serial: Int32.random(in: 0...CalendarData.maxSerial, using: &rng))
      let n = Int.random(in: -120_000...120_000, using: &rng)
      guard let moved = try? date.adding(days: n) else { continue }
      if date.days(until: moved) != n { failures += 1 }
    }
    #expect(failures == 0)
  }

  @Test("P6: adding months with clamp keeps the day or clamps it to the month length")
  func clampKeepsDay() {
    var rng = SplitMix64(seed: Self.seed ^ 6)
    var failures = 0
    for _ in 0..<Self.cases {
      let date = NepaliDate(serial: Int32.random(in: 0...CalendarData.maxSerial, using: &rng))
      let n = Int.random(in: -3600...3600, using: &rng)
      guard let moved = try? date.adding(months: n, overflow: .clamp) else { continue }
      let expectedDay = Swift.min(date.day, moved.monthLength)
      let monthsMoved = (moved.year - date.year) * 12 + moved.month - date.month
      if moved.day != expectedDay || monthsMoved != n { failures += 1 }
    }
    #expect(failures == 0)
  }

  @Test("P7: the diff breakdown re-added to the earlier date gives the later date")
  func diffReAdds() {
    var rng = SplitMix64(seed: Self.seed ^ 7)
    var failures = 0
    for _ in 0..<Self.cases {
      let a = NepaliDate(serial: Int32.random(in: 0...CalendarData.maxSerial, using: &rng))
      let b = NepaliDate(serial: Int32.random(in: 0...CalendarData.maxSerial, using: &rng))
      let diff = a.diff(to: b)
      let (earlier, later) = diff.isNegative ? (b, a) : (a, b)
      let months = diff.years * 12 + diff.months
      let rebuilt = try? earlier.adding(months: months).adding(days: diff.days)
      let wellFormed = diff.days >= 0 && (0...11).contains(diff.months)
      if rebuilt != later || diff.totalDays != a.days(until: b) || !wellFormed { failures += 1 }
    }
    #expect(failures == 0)
  }
}
