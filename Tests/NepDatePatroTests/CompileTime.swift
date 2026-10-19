import Testing

@testable import NepDatePatro

// This file stops compiling when a public type loses a conformance it promises (ADR-0004).

func requireSendable<T: Sendable>(_: T.Type) {}

@Suite("PatroCompileTime")
struct PatroCompileTimeTests {
  @Test("every public NepDatePatro type is Sendable")
  func conformances() {
    requireSendable(CalendarInfo.self)
    requireSendable(PatroEvents.self)
    requireSendable(Named.self)
    requireSendable(Patro.self)
  }

  @Test("Named is 2 bytes")
  func layout() {
    #expect(MemoryLayout<Named>.size == 2)
  }
}
