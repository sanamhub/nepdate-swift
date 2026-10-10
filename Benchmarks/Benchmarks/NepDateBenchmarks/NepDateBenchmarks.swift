import Benchmark
import BenchmarkInputs
import NepDate

// B1 to B6 of shared/spec/BENCHMARK.md §3, B5a (B5 into a reused buffer), and iterating one
// month's NepaliDateRange. One iteration runs all 64 inputs, so divide the
// reported time by 64 for one operation (package-benchmark's scaling factor is a power of 1,000).
// NepDate must add no malloc (ADR-0002 §7). The harness itself counts 16 per iteration on Linux
// (the Baseline benchmark, same loop without NepDate), so Thresholds/ holds 16 for each and
// `benchmark thresholds check` fails on any malloc above that. B5 returns a new String of more
// than 15 bytes, one malloc per date, so its threshold is 16 + 64 = 80.
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
  let texts = dates.map { $0.description }

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

  Benchmark("B5", configuration: configuration) { benchmark in
    for _ in benchmark.scaledIterations {
      for date in dates { blackHole(date.long(weekday: true, lang: .nepali)) }
    }
  }

  Benchmark("B5a", configuration: configuration) { benchmark in
    var buffer = ""
    buffer.reserveCapacity(256)
    for _ in benchmark.scaledIterations {
      for date in dates {
        buffer.removeAll(keepingCapacity: true)
        date.appendLong(to: &buffer, weekday: true, lang: .nepali)
        blackHole(buffer.utf8.count)
      }
    }
  }

  Benchmark("B6", configuration: configuration) { benchmark in
    for _ in benchmark.scaledIterations {
      for text in texts { blackHole(try? NepaliDate.parse(text)) }
    }
  }
}
