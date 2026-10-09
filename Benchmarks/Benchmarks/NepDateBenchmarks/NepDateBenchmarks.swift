import Benchmark
import BenchmarkInputs
import NepDate

// B1 and B2 of shared/spec/BENCHMARK.md §3. One iteration runs all 64 inputs, so divide the
// reported time by 64 for one operation (package-benchmark's scaling factor is a power of 1,000).
// The malloc count must stay 0 (ADR-0002 §7); Thresholds/ holds the static values that
// `benchmark thresholds check` compares against.
let benchmarks: @Sendable () -> Void = {
  let configuration = Benchmark.Configuration(
    metrics: [.wallClock, .mallocCountTotal, .instructions],
    scalingFactor: .one,
    thresholds: [.mallocCountTotal: .init(absolute: [.p90: 0])])

  // Computed here, outside the measured closures.
  guard let inputs = try? BenchmarkInputs() else {
    fatalError("benchmark inputs could not be built")
  }
  let bs = inputs.bs
  let ad = inputs.ad

  // The same loop with no NepDate call: what the harness itself allocates per iteration.
  Benchmark("Baseline", configuration: configuration) { benchmark in
    for _ in benchmark.scaledIterations {
      for date in bs { blackHole(date.day) }
    }
  }

  Benchmark("B1", configuration: configuration) { benchmark in
    for _ in benchmark.scaledIterations {
      for date in bs {
        blackHole((try? NepaliDate(year: date.year, month: date.month, day: date.day))?.gregorian)
      }
    }
  }

  Benchmark("B2", configuration: configuration) { benchmark in
    for _ in benchmark.scaledIterations {
      for date in ad {
        blackHole(try? NepaliDate(gregorianYear: date.year, month: date.month, day: date.day))
      }
    }
  }
}
