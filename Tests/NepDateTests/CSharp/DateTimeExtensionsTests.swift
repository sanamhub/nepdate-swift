#if canImport(Foundation)
  import Foundation
  import Testing

  @testable import NepDate

  // C#'s DateTime.ToNepaliDate() maps to init(_:in:), with an explicit zone instead of
  // DateTime.Kind. The helpers utc(_:_:_:seconds:) and zone(_:) are shared with FoundationTests.
  @Suite("DateTimeExtensionsTests")
  struct DateTimeExtensionsTests {
    @Test("DateTimeExtensionsTests.ToNepaliDate_ValidDateTime_ReturnsCorrectNepaliDate")
    func validDateTime() throws {
      // 2023-09-01 is BS 2080-05-15, so the year is 2080.
      #expect(try NepaliDate(utc(2023, 9, 1), in: try zone("UTC")).year == 2080)
    }

    @Test("DateTimeExtensionsTests.ToNepaliDate_MinValue_ThrowsArgumentOutOfRangeException")
    func minValue() throws {
      expectError(.outOfRange) {
        _ = try NepaliDate(Date.distantPast, in: try zone("UTC"))
      }
    }

    @Test("DateTimeExtensionsTests.ToNepaliDate_MaxValue_ThrowsArgumentOutOfRangeException")
    func maxValue() throws {
      expectError(.outOfRange) {
        _ = try NepaliDate(Date.distantFuture, in: try zone("UTC"))
      }
    }

    @Test(
      "DateTimeExtensionsTests.ToNepaliDate_DateBeforeMinSupported_ThrowsArgumentOutOfRangeException"
    )
    func beforeMin() throws {
      // The last second of AD 1844-04-10, one second before the first supported instant.
      expectError(.outOfRange) {
        _ = try NepaliDate(utc(1844, 4, 10, seconds: 86_399), in: try zone("UTC"))
      }
    }

    @Test(
      "DateTimeExtensionsTests.ToNepaliDate_DateAfterMaxSupported_ThrowsArgumentOutOfRangeException"
    )
    func afterMax() throws {
      // The first instant of AD 2143-04-16, one day after the last supported day.
      expectError(.outOfRange) {
        _ = try NepaliDate(utc(2143, 4, 16), in: try zone("UTC"))
      }
    }
  }
#endif
