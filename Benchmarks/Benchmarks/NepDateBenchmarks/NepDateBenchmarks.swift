import Benchmark
import BenchmarkInputs
import NepDate

// B1 to B4 of shared/spec/BENCHMARK.md §3, and iterating one month's NepaliDateRange. One iteration runs all 64 inputs, so divide the
// reported time by 64 for one operation (package-benchmark's scaling factor is a power of 1,000).
// NepDate must add no malloc (ADR-0002 §7). The harness itself counts 16 per iteration on Linux
// (the Baseline benchmark, same loop without NepDate), so Thresholds/ holds 16 for each and
// `benchmark thresholds check` fails on any malloc above that.
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
  let dates = bs.compactMap { try? NepaliDate(year: $0.year, month: $0.month, day: $0.day) }

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

  Benchmark("B3", configuration: configuration) { benchmark in
    for _ in benchmark.scaledIterations {
      for date in dates { blackHole(try? date.adding(days: 1000)) }
    }
  }

  Benchmark("B4", configuration: configuration) { benchmark in
    for _ in benchmark.scaledIterations {
      for date in dates { blackHole(try? date.adding(months: 13, overflow: .clamp)) }
    }
  }

  // Every day of each input date's month, as a widget drawing a month would read them.
  Benchmark("MonthRange", configuration: configuration) { benchmark in
    for _ in benchmark.scaledIterations {
      for date in dates {
        guard let month = try? NepaliDateRange.month(year: date.year, month: date.month) else {
          continue
        }
        for day in month { blackHole(day) }
      }
    }
  }
}
