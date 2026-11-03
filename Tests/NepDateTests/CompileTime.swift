import Testing

@testable import NepDate

// This file stops compiling when a public type loses a conformance it promises (ADR-0004).

func requireSendable<T: Sendable>(_: T.Type) {}
func requireBitwiseCopyable<T: BitwiseCopyable>(_: T.Type) {}
func requireStrideable<T: Strideable>(_: T.Type) {}
func requireIntIndexed<T: RandomAccessCollection>(_: T.Type) where T.Index == Int {}

@Suite("CompileTime")
struct CompileTimeTests {
  @Test("every public type is Sendable; NepaliDate is BitwiseCopyable")
  func conformances() {
    requireSendable(NepaliDate.self)
    requireSendable(Month.self)
    requireSendable(Weekday.self)
    requireSendable(Lang.self)
    requireSendable(NepDateError.self)
    requireSendable(NepDateError.Kind.self)
    requireSendable(DateOrder.self)
    requireSendable(Separator.self)
    requireSendable(MonthOverflow.self)
    requireSendable(DateDiff.self)
    requireSendable(FiscalYear.self)
    requireSendable(Quarter.self)
    requireSendable(NepaliDateRange.self)
    requireBitwiseCopyable(NepaliDate.self)
    requireStrideable(NepaliDate.self)
    requireIntIndexed(NepaliDateRange.self)
    #if canImport(Foundation)
      requireSendable(NepaliDate.FormatStyle.self)
    #endif
  }

  @Test("NepaliDate is 8 bytes, aligned to 4")
  func layout() {
    #expect(MemoryLayout<NepaliDate>.size == 8)
    #expect(MemoryLayout<NepaliDate>.stride == 8)
    #expect(MemoryLayout<NepaliDate>.alignment == 4)
  }
}
