import Testing

@testable import NepDate

@Test func generatedTableCoversTheSupportedYears() {
  #expect(CalendarData.minYear == 1901)
  #expect(CalendarData.maxYear == 2199)
}
