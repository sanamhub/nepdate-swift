import Testing

@testable import NepDate

/// `YYYY-MM-DD` as a date, or `nil` for `ERR`.
func goldenDate(_ text: Substring) throws -> NepaliDate? {
  guard text != "ERR", let parts = ymd(text) else { return nil }
  return try bs(parts.0, parts.1, parts.2)
}

/// A result as the golden files write it: the date, or `ERR` for `.outOfRange`.
func goldenText(_ body: () throws -> NepaliDate) -> String {
  do {
    let date = try body()
    return "\(date.year)-\(pad(date.month))-\(pad(date.day))"
  } catch let error as NepDateError where error.kind == .outOfRange {
    return "ERR"
  } catch {
    return "unexpected \(error)"
  }
}

func pad(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }

@Suite("Arithmetic")
struct ArithmeticTests {
  @Test("S2-01 AC1: csharp-golden/add-days.tsv")
  func goldenAddDays() throws {
    let file = try VectorFile("csharp-golden/add-days.tsv", separator: "\t")
    #expect(file.rows.count == 9162)
    var log = FailureLog()
    for (line, fields) in file.rows {
      guard fields.count == 3, let start = try goldenDate(fields[0]), let n = Int(fields[1]) else {
        log.record(line, "malformed")
        continue
      }
      let got = goldenText { try start.adding(days: n) }
      if got != fields[2] { log.record(line, "got \(got)") }
    }
    #expect(log.count == 0, "\(log.summary)")
  }

  @Test("S2-01 AC2: adding(days:) at the ends and with extreme counts")
  func addDaysExtremes() {
    expectError(.outOfRange) { _ = try NepaliDate.max.adding(days: 1) }
    expectError(.outOfRange) { _ = try NepaliDate.min.adding(days: -1) }
    expectError(.outOfRange) { _ = try NepaliDate.min.adding(days: Int.min) }
    expectError(.outOfRange) { _ = try NepaliDate.max.adding(days: Int.max) }
    #expect(try NepaliDate.min.adding(days: 109211) == NepaliDate.max)
    #expect(try NepaliDate.max.adding(days: -109211) == NepaliDate.min)
  }

  @Test("S2-01 AC3 and S2-03 AC1: days(until:) is antisymmetric and equals diff totalDays")
  func daysUntilAndDiffTotals() throws {
    let file = try VectorFile("csharp-golden/dates.tsv", separator: "\t")
    let dates = try file.rows.compactMap { try goldenDate($0.fields[0]) }
    #expect(dates.count == 1018)
    for (a, b) in zip(dates.prefix(100), dates.suffix(100)) {
      #expect(a.days(until: b) == -b.days(until: a))
      #expect(a.diff(to: b).totalDays == a.days(until: b))
      #expect(b.diff(to: a).totalDays == b.days(until: a))
    }
  }

  @Test("S2-02 AC1: csharp-golden/add-months.tsv, clamp and spill")
  func goldenAddMonths() throws {
    let file = try VectorFile("csharp-golden/add-months.tsv", separator: "\t")
    #expect(file.rows.count == 10180)
    var log = FailureLog()
    for (line, fields) in file.rows {
      guard fields.count == 4, let start = try goldenDate(fields[0]), let n = Int(fields[1]) else {
        log.record(line, "malformed")
        continue
      }
      let clamp = goldenText { try start.adding(months: n, overflow: .clamp) }
      if clamp != fields[2] { log.record(line, "clamp got \(clamp)") }
      let spill = goldenText { try start.adding(months: n, overflow: .spill) }
      if spill != fields[3] { log.record(line, "spill got \(spill)") }
    }
    #expect(log.count == 0, "\(log.summary)")
  }

  @Test("S2-02 AC2: ALGORITHM §8 examples")
  func monthExamples() throws {
    let date = try bs(2081, 4, 32)
    #expect(try date.adding(months: 2) == bs(2081, 6, 30))
    #expect(try date.adding(months: 2, overflow: .spill) == bs(2081, 7, 2))
    #expect(try date.adding(months: 5) == bs(2081, 9, 29))
    #expect(try date.adding(months: 5, overflow: .spill) == bs(2081, 10, 3))
    #expect(try date.adding(years: 1) == date.adding(months: 12))
    let back = try date.adding(years: -1, overflow: .spill)
    #expect(try back == date.adding(months: -12, overflow: .spill))
  }

  @Test("S2-02 AC3: extreme month and year counts throw")
  func monthExtremes() throws {
    let date = try bs(2081, 4, 15)
    expectError(.outOfRange) { _ = try date.adding(years: .max) }
    expectError(.outOfRange) { _ = try date.adding(years: .min) }
    expectError(.outOfRange) { _ = try date.adding(months: .max) }
    expectError(.outOfRange) { _ = try date.adding(months: .min) }
    // Spilling past Chaitra 2199 is out of range even though the month itself exists.
    let bhadra = try bs(2199, 5, 32)
    #expect(try bhadra.adding(months: 7) == NepaliDate.max)
    expectError(.outOfRange) { _ = try bhadra.adding(months: 7, overflow: .spill) }
  }

  @Test("S2-03 AC2: diff breakdown and sign")
  func diffBreakdown() throws {
    let a = try bs(2081, 4, 32)
    let b = try bs(2081, 6, 30)
    let forward = a.diff(to: b)
    #expect(!forward.isNegative && forward.years == 0 && forward.months == 2 && forward.days == 0)
    let back = b.diff(to: a)
    #expect(back.isNegative && back.years == 0 && back.months == 2 && back.days == 0)
    #expect(back.totalDays == -forward.totalDays)
  }

  /// One row of the ALGORITHM §8a table.
  struct DiffRow: Sendable {
    let a: (Int, Int, Int)
    let b: (Int, Int, Int)
    let expected: (Bool, Int, Int, Int, Int)
  }

  @Test(
    "S2-03: ALGORITHM §8a examples",
    arguments: [
      DiffRow(a: (2080, 1, 1), b: (2081, 4, 15), expected: (false, 1, 3, 14, 473)),
      DiffRow(a: (2081, 4, 15), b: (2080, 1, 1), expected: (true, 1, 3, 14, -473)),
      DiffRow(a: (2081, 4, 32), b: (2081, 5, 31), expected: (false, 0, 1, 0, 31)),
      DiffRow(a: (2081, 4, 32), b: (2081, 6, 1), expected: (false, 0, 1, 1, 32)),
      DiffRow(a: (2081, 1, 31), b: (2081, 2, 30), expected: (false, 0, 0, 30, 30)),
      DiffRow(a: (2081, 3, 15), b: (2081, 3, 15), expected: (false, 0, 0, 0, 0)),
    ])
  func diffExamples(row: DiffRow) throws {
    let diff = try bs(row.a.0, row.a.1, row.a.2).diff(to: bs(row.b.0, row.b.1, row.b.2))
    #expect(diff.isNegative == row.expected.0)
    #expect(diff.years == row.expected.1 && diff.months == row.expected.2)
    #expect(diff.days == row.expected.3 && diff.totalDays == row.expected.4)
  }

  @Test("S2-04 AC1: csharp-golden/dates.tsv fiscal and quarter columns")
  func goldenFiscal() throws {
    let file = try VectorFile("csharp-golden/dates.tsv", separator: "\t")
    #expect(file.rows.count == 1018)
    var log = FailureLog()
    for (line, fields) in file.rows {
      guard fields.count == 16, let date = try goldenDate(fields[0]) else {
        log.record(line, "malformed")
        continue
      }
      let fy = date.fiscalYear
      let got = [
        goldenText { try fy.start() }, goldenText { try fy.end() },
        goldenText { try fy.range(of: date.quarter).lowerBound },
        goldenText { try fy.range(of: date.quarter).upperBound },
      ]
      let expected = fields[12...15].map(String.init)
      if got != expected { log.record(line, "got \(got)") }
    }
    #expect(log.count == 0, "\(log.summary)")
  }

  @Test("S2-04: fiscal year bounds, quarters and labels")
  func fiscalYear() throws {
    expectError(.outOfRange) { _ = try FiscalYear(startYear: 1900).start() }
    expectError(.outOfRange) { _ = try FiscalYear(startYear: 2199).end() }
    expectError(.outOfRange) { _ = try FiscalYear(startYear: 2199).range(of: .q4) }
    expectError(.outOfRange) { _ = try FiscalYear(startYear: .max).end() }
    #expect(FiscalYear(startYear: 2082).label(.nepali) == "२०८२/८३")
    #expect(FiscalYear(startYear: 2082).label() == "2082/83")
    #expect(FiscalYear(startYear: 2099).label() == "2099/00")
    #expect(Quarter.q4.months == [.baishakh, .jestha, .ashad])
    #expect(Quarter.q1.months == [.shrawan, .bhadra, .ashoj])
    #expect(FiscalYear(startYear: 2080) < FiscalYear(startYear: 2081))
    #expect(try bs(2081, 3, 31).fiscalYear == FiscalYear(startYear: 2080))
    #expect(try bs(2081, 4, 1).fiscalYear == FiscalYear(startYear: 2081))
    let quarters = try (1...12).map { try bs(2081, $0, 1).quarter }
    #expect(quarters == [.q4, .q4, .q4, .q1, .q1, .q1, .q2, .q2, .q2, .q3, .q3, .q3])
    #expect(try FiscalYear(startYear: 2080).range().count == NepaliDateRange.year(2080).count)
  }

  @Test("S2-05 AC1: every year's range length is the sum of its months")
  func yearLengths() throws {
    for year in 1901...2199 {
      let count = try NepaliDateRange.year(year).count
      let sum = try (1...12).reduce(0) { $0 + (try bs(year, $1, 1).monthLength) }
      #expect(count == sum, "year \(year)")
      #expect((364...367).contains(count), "year \(year)")
    }
    expectError(.outOfRange) { _ = try NepaliDateRange.year(2200) }
    expectError(.invalidMonth) { _ = try NepaliDateRange.month(year: 2081, month: 13) }
  }

  @Test("S2-05 AC2 and AC3: month range, empty and one-day ranges, iteration")
  func ranges() throws {
    let shrawan = try NepaliDateRange.month(year: 2081, month: 4)
    #expect(shrawan.count == 32)
    #expect(shrawan.lowerBound == (try bs(2081, 4, 1)))
    #expect(shrawan.upperBound == (try bs(2081, 4, 32)))
    let a = try bs(2081, 4, 1)
    let b = try bs(2081, 4, 2)
    #expect(NepaliDateRange(b, a) == nil)
    let one = try #require(NepaliDateRange(a, a))
    #expect(one.count == 1 && Array(one) == [a])
    var looped: [NepaliDate] = []
    for date in shrawan { looped.append(date) }
    #expect(Array(shrawan) == looped)
    #expect(looped == looped.sorted() && looped.count == 32)
    #expect(looped.enumerated().allSatisfy { $0.element.day == $0.offset + 1 })
    #expect(shrawan.contains(a) && !shrawan.contains(try bs(2081, 5, 1)))
  }
}
