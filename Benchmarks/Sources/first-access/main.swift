// Times the first conversion in a fresh process, which pays for the one-time setup of the
// calendar tables (ADR-0002 §7, target < 100 µs). Run it as its own process:
//   swift run -c release --package-path Benchmarks first-access

import NepDate

let clock = ContinuousClock()
let start = clock.now
let date = try NepaliDate(gregorianYear: 2024, month: 7, day: 30)
let elapsed = clock.now - start
let micros =
  Double(elapsed.components.attoseconds) / 1e12 + Double(elapsed.components.seconds) * 1e6
print("first-access: \(date.year)-\(date.month)-\(date.day) in \(micros) µs")
