import NepDate

// The raw pointer from libFuzzer is the one place unsafe pointers are allowed (AGENTS.md §2).
@_cdecl("LLVMFuzzerTestOneInput")
public func fuzz(_ data: UnsafePointer<UInt8>, _ size: Int) -> CInt {
  let pattern = String(decoding: UnsafeBufferPointer(start: data, count: size), as: UTF8.self)
  for date in [NepaliDate.min, NepaliDate.max] {
    _ = date.format(pattern)
    _ = date.format(pattern, lang: .nepali)
  }
  return 0
}
