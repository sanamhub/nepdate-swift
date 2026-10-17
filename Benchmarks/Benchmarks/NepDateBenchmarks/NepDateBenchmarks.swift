import Benchmark
import BenchmarkInputs
import NepDate
import NepDatePatro

// B1 to B8 of shared/spec/BENCHMARK.md §3, B5a (B5 into a reused buffer), iterating one month's
// NepaliDateRange, and B7-sorted (the PATRO §3 binary-search comparison). One iteration runs all
// 64 inputs, so divide the reported time by 64 for one operation (package-benchmark's scaling
// factor is a power of 1,000). NepDate and NepDatePatro must add no malloc (ADR-0002 §7). The
// harness itself counts 16 per iteration on Linux (the Baseline benchmark, same loop without
// NepDate), so Thresholds/ holds 16 for each and `benchmark thresholds check` fails on any malloc
// above that. B5 returns a new String of more than 15 bytes, one malloc per date, so its threshold
// is 16 + 64 = 80.

/// The 64 BENCHMARK §3 inputs for B7 and B8: the benchmark dates moved into the patro coverage.
func patroInputs(coverage: NepaliDateRange) -> [NepaliDate] {
  let first = Int(coverage.startIndex)
  let step = (Int(coverage.endIndex) - 1 - first) / 63
  return (0..<64).map { coverage[Int32(first + $0 * step)] }
}

/// Everything `calendarInfo` says about one day, every name read in both languages, as the byte
/// count that keeps the work from being optimised away. The count itself is not meaningful.
func readPatroInfo(_ date: NepaliDate) -> Int {
  let info = date.calendarInfo
  var bytes = 0
  if let tithi = info.tithi {
    bytes += tithi.nepali.utf8.count + tithi.english.utf8.count
  }
  bytes += info.isPublicHoliday ? 1 : 0
  for event in info.events {
    bytes += event.nepali.utf8.count + event.english.utf8.count
  }
  return bytes
}

/// Index of `value` in the sorted `offsets`, or nil when it is absent.
func binarySearchIndex(_ offsets: [Int], _ value: Int) -> Int? {
  var lo = 0
  var hi = offsets.count
  while lo < hi {
    let mid = (lo + hi) / 2
    if offsets[mid] < value { lo = mid + 1 } else { hi = mid }
  }
  return (lo < offsets.count && offsets[lo] == value) ? lo : nil
}

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
  let coverage = Patro.coverage
  let coverageStart = coverage.lowerBound
  let patroDates = patroInputs(coverage: coverage)

  // B7-sorted setup: sorted offset arrays built once from the public API. The timed loop below
  // does the same reads by binary search (PATRO §3 evidence for the dense tables).
  var tithiOffsets: [Int] = []
  var tithiNames: [Named] = []
  var holidayOffsets: [Int] = []
  var eventOffsets: [Int] = []
  var eventNames: [[Named]] = []
  for date in coverage {
    let info = date.calendarInfo
    let offset = coverageStart.days(until: date)
    if let tithi = info.tithi {
      tithiOffsets.append(offset)
      tithiNames.append(tithi)
    }
    if info.isPublicHoliday { holidayOffsets.append(offset) }
    if !info.events.isEmpty {
      eventOffsets.append(offset)
      eventNames.append(Array(info.events))
    }
  }

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
    // The buffer's one allocation is setup, not part of what B5a measures.
    benchmark.startMeasurement()
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

  Benchmark("B7", configuration: configuration) { benchmark in
    for _ in benchmark.scaledIterations {
      var total = 0
      for date in patroDates { total += readPatroInfo(date) }
      blackHole(total)
    }
  }

  Benchmark("B8", configuration: configuration) { benchmark in
    for _ in benchmark.scaledIterations {
      var total = 0
      for date in patroDates {
        guard let month = try? NepaliDateRange.month(year: date.year, month: date.month) else {
          continue
        }
        for day in month { total += readPatroInfo(day) }
      }
      blackHole(total)
    }
  }

  Benchmark("B7-sorted", configuration: configuration) { benchmark in
    for _ in benchmark.scaledIterations {
      var total = 0
      for date in patroDates {
        let offset = coverageStart.days(until: date)
        if let i = binarySearchIndex(tithiOffsets, offset) {
          total += tithiNames[i].nepali.utf8.count + tithiNames[i].english.utf8.count
        }
        total += binarySearchIndex(holidayOffsets, offset) == nil ? 0 : 1
        if let i = binarySearchIndex(eventOffsets, offset) {
          for event in eventNames[i] {
            total += event.nepali.utf8.count + event.english.utf8.count
          }
        }
      }
      blackHole(total)
    }
  }
}
