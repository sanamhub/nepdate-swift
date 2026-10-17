// S6-02: the canonical fast path must not change any answer and must not decline a canonical shape.
// `parseSlow` and `parseCanonical` are internal, so this target builds with
// `-Xswiftc -enable-testing` (see the fuzz job and the note in Fuzz/Package.swift).

@testable import NepDate

/// A parse result that can be compared, so a date and an error are told apart.
private enum Outcome: Equatable {
  case date(NepaliDate)
  case error(NepDateError)
}

private func outcome(_ body: () throws(NepDateError) -> NepaliDate) -> Outcome {
  do {
    return .date(try body())
  } catch {
    return .error(error)
  }
}

/// The test oracle for the shape the fast path must accept.
private func canonicalShape(_ text: String) -> Bool {
  let bytes = Array(text.utf8)
  guard bytes.count == 10 else { return false }
  let separatorAt4 = bytes[4] == 0x2D || bytes[4] == 0x2F || bytes[4] == 0x2E
    || bytes[4] == 0x5F || bytes[4] == 0x5C || bytes[4] == 0x20 || bytes[4] == 0x7C
  let separatorAt7 = bytes[7] == 0x2D || bytes[7] == 0x2F || bytes[7] == 0x2E
    || bytes[7] == 0x5F || bytes[7] == 0x5C || bytes[7] == 0x20 || bytes[7] == 0x7C
  guard separatorAt4 && separatorAt7 else { return false }
  for index in [0, 1, 2, 3, 5, 6, 8, 9] where !(bytes[index] >= 0x30 && bytes[index] <= 0x39) {
    return false
  }
  return true
}

// The raw pointer from libFuzzer is the one place unsafe pointers are allowed (AGENTS.md §2).
@_cdecl("LLVMFuzzerTestOneInput")
public func fuzz(_ data: UnsafePointer<UInt8>, _ size: Int) -> CInt {
  let text = String(decoding: UnsafeBufferPointer(start: data, count: size), as: UTF8.self)
  let fast = outcome { try NepaliDate.parse(text) }
  let slow = outcome { try NepaliDate.parseSlow(text) }
  if fast != slow {
    fatalError("parse(\(text)) = \(fast), parseSlow = \(slow)")
  }
  if canonicalShape(text) {
    do {
      if try NepaliDate.parseCanonical(text.utf8) == nil {
        fatalError("canonical text declined by the fast path: \(text)")
      }
    } catch {
      fatalError("canonical text threw \(error): \(text)")
    }
  }
  return 0
}
