import Testing

@testable import NepDate

// This file stops compiling when a public type loses a conformance it promises (ADR-0004).

func requireSendable<T: Sendable>(_: T.Type) {}
func requireBitwiseCopyable<T: BitwiseCopyable>(_: T.Type) {}

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
    requireBitwiseCopyable(NepaliDate.self)
  }

  @Test("S1-03 AC2: NepaliDate is 8 bytes, aligned to 4")
  func layout() {
    #expect(MemoryLayout<NepaliDate>.size == 8)
    #expect(MemoryLayout<NepaliDate>.stride == 8)
    #expect(MemoryLayout<NepaliDate>.alignment == 4)
  }
}
