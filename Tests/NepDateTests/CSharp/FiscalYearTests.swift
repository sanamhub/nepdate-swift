import Testing

@testable import NepDate

// C#'s static and instance fiscal-year methods map to `FiscalYear` (D-08): `start()`, `end()`,
// `range()` and `range(of:)`. A C# month argument picks the quarter that contains that month.
@Suite("FiscalYearTests")
struct FiscalYearTests {
  @Test("FiscalYearTests.GetFiscalYearStartAndEndDate_ValidYear_ReturnsCorrectDates")
  func getStartAndEndValidYear() throws {
    let fy = FiscalYear(startYear: 2080)
    #expect(try fy.start() == bs(2080, 4, 1))
    #expect(try fy.end() == bs(2081, 3, 1).lastDayOfMonth)
  }

  @Test(
    "FiscalYearTests.GetFiscalYearStartAndEndDate_InvalidYear_ThrowsException",
    arguments: [1843, 2200])
  func getStartAndEndInvalidYear(year: Int) {
    expectError(.outOfRange) { _ = try FiscalYear(startYear: year).range() }
  }

  @Test("FiscalYearTests.GetFiscalYearStartDate_ValidYear_ReturnsCorrectDate")
  func getStartValidYear() throws {
    #expect(try FiscalYear(startYear: 2080).start() == bs(2080, 4, 1))
  }

  @Test("FiscalYearTests.GetFiscalYearEndDate_ValidYear_ReturnsCorrectDate")
  func getEndValidYear() throws {
    #expect(try FiscalYear(startYear: 2080).end() == bs(2081, 3, 1).lastDayOfMonth)
  }

  @Test("FiscalYearTests.FiscalYearStartAndEndDate_OnNepaliDateInstance_ReturnsCorrectDates")
  func startAndEndOnInstance() throws {
    let range = try bs(2080, 6, 15).fiscalYear.range()
    #expect(range.lowerBound == (try bs(2080, 4, 1)))
    #expect(range.upperBound == (try bs(2081, 3, 1).lastDayOfMonth))
  }

  @Test("FiscalYearTests.FiscalYearStartDate_OnNepaliDateInstance_ReturnsCorrectDate")
  func startOnInstance() throws {
    #expect(try bs(2080, 6, 15).fiscalYear.start() == bs(2080, 4, 1))
  }

  @Test("FiscalYearTests.FiscalYearEndDate_OnNepaliDateInstance_ReturnsCorrectDate")
  func endOnInstance() throws {
    #expect(try bs(2080, 6, 15).fiscalYear.end() == bs(2081, 3, 1).lastDayOfMonth)
  }

  @Test("FiscalYearTests.GetFiscalYearQuarterStartAndEndDate_ValidYearAndMonth_ReturnsCorrectDates")
  func quarterStartAndEnd() throws {
    // Month 5 (Bhadra) is in Q1.
    let range = try FiscalYear(startYear: 2080).range(of: bs(2080, 5, 1).quarter)
    #expect(range.lowerBound == (try bs(2080, 4, 1)))
    #expect(range.upperBound == (try bs(2080, 6, 1).lastDayOfMonth))
  }

  @Test("FiscalYearTests.GetFiscalYearQuarterStartDate_ValidYearAndMonth_ReturnsCorrectDate")
  func quarterStart() throws {
    // Month 8 (Mangsir) is in Q2.
    let range = try FiscalYear(startYear: 2080).range(of: bs(2080, 8, 1).quarter)
    #expect(range.lowerBound == (try bs(2080, 7, 1)))
  }

  @Test("FiscalYearTests.GetFiscalYearQuarterEndDate_ValidYearAndMonth_ReturnsCorrectDate")
  func quarterEnd() throws {
    // Month 11 (Falgun) is in Q3.
    let range = try FiscalYear(startYear: 2080).range(of: bs(2080, 11, 1).quarter)
    #expect(range.upperBound == (try bs(2080, 12, 1).lastDayOfMonth))
  }
}
