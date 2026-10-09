import Testing

@testable import NepDate

@Suite("NepaliDateManipulationTests")
struct NepaliDateManipulationTests {
  @Test("NepaliDateManipulationTests.MonthEndDate_ReturnsCorrectDate")
  func monthEndDateReturnsCorrectDate() throws {
    #expect(try bs(2080, 5, 15).lastDayOfMonth == bs(2080, 5, 31))
  }

  /// One `InlineData` row: date, months to add, expected date, spill (C# `awayFromMonthEnd`).
  struct AddMonthsRow: Sendable {
    let date: [Int]
    let months: Int
    let expected: [Int]
    var spill = false
  }

  @Test(
    "NepaliDateManipulationTests.AddMonths_ReturnsCorrectDate",
    arguments: [
      AddMonthsRow(date: [2080, 5, 15], months: 1, expected: [2080, 6, 15]),
      AddMonthsRow(date: [2080, 5, 15], months: -1, expected: [2080, 4, 15]),
      AddMonthsRow(date: [2080, 5, 15], months: 12, expected: [2081, 5, 15]),
      AddMonthsRow(date: [2081, 4, 32], months: 5, expected: [2081, 9, 29]),
      AddMonthsRow(date: [2081, 4, 32], months: 5, expected: [2081, 10, 3], spill: true),
    ])
  func addMonthsReturnsCorrectDate(row: AddMonthsRow) throws {
    let result = try bs(row.date[0], row.date[1], row.date[2])
      .adding(months: row.months, overflow: row.spill ? .spill : .clamp)
    #expect(result == (try bs(row.expected[0], row.expected[1], row.expected[2])))
  }

  @Test(
    "NepaliDateManipulationTests.AddDays_ReturnsCorrectDate",
    arguments: [
      [2080, 5, 15, 5, 2080, 5, 20], [2080, 5, 15, -5, 2080, 5, 10],
      [2080, 5, 31, 1, 2080, 6, 1], [2080, 12, 30, 5, 2081, 1, 5],
    ])
  func addDaysReturnsCorrectDate(row: [Int]) throws {
    let result = try bs(row[0], row[1], row[2]).adding(days: row[3])
    #expect(result == (try bs(row[4], row[5], row[6])))
  }

  // C# `Subtract` returns a TimeSpan; Swift returns the signed day count (D-07).
  @Test("NepaliDateManipulationTests.Subtract_TwoDates_ReturnsCorrectTimeSpan")
  func subtractTwoDatesReturnsCorrectTimeSpan() throws {
    let earlier = try bs(2080, 5, 1)
    let later = try bs(2080, 5, 16)
    #expect(earlier.days(until: later) == 15)
    #expect(later.days(until: earlier) == -15)
  }

  @Test("NepaliDateManipulationTests.Subtract_SameDate_ReturnsZero")
  func subtractSameDateReturnsZero() throws {
    let date = try bs(2080, 5, 15)
    #expect(date.days(until: date) == 0)
  }
}
