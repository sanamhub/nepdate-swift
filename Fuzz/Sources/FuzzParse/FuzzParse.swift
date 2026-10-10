import NepDate

// The raw pointer from libFuzzer is the one place unsafe pointers are allowed (AGENTS.md §2).
@_cdecl("LLVMFuzzerTestOneInput")
public func fuzz(_ data: UnsafePointer<UInt8>, _ size: Int) -> CInt {
  let text = String(decoding: UnsafeBufferPointer(start: data, count: size), as: UTF8.self)
  // Typed throws: the only error that can come out is a NepDateError.
  if let date = try? NepaliDate.parse(text), (try? NepaliDate.parse(date.format("s"))) != date {
    fatalError("\(date) did not round-trip through format(\"s\")")
  }
  return 0
}
