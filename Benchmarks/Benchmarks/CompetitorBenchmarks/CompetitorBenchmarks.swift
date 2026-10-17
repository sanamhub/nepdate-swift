// B1 and B2 for the two Swift libraries in docs/competitors.md that have a conversion API, over the
// same 64 dates as BENCHMARK §2. Times are per iteration of 64 operations, like NepDateBenchmarks.
//
// The shivathapaa engine is an arm64 macOS XCFramework, so its two benchmarks exist only there.
// The nrlnishan converter is vendored MIT source and runs on Linux and macOS.

import Benchmark
import BenchmarkInputs
import NepaliDateConverter

#if canImport(nepali_date_picker_core)
  import nepali_date_picker_core
#endif

let benchmarks: @Sendable () -> Void = {
  let configuration = Benchmark.Configuration(
    metrics: [.wallClock, .cpuTotal, .mallocCountTotal], scalingFactor: .one)

  guard let inputs = try? BenchmarkInputs() else {
    fatalError("benchmark inputs could not be built")
  }
  let bs = inputs.bs
  let ad = inputs.ad

  // The converter and its values are setup, so the timed loop measures one conversion only.
  let nrlnishan = NepaliDateConverter.DateConverter()
  let bsModels = bs.map { DateModel(year: $0.year, month: $0.month, day: $0.day) }
  let adModels = ad.map { DateModel(year: $0.year, month: $0.month, day: $0.day) }

  Benchmark("nrlnishan-B1") { benchmark in
    for _ in benchmark.scaledIterations {
      for model in bsModels { blackHole(nrlnishan.getEnglishDate(nepaliDate: model)) }
    }
  }

  Benchmark("nrlnishan-B2") { benchmark in
    for _ in benchmark.scaledIterations {
      for model in adModels { blackHole(nrlnishan.getNepaliDate(englishDate: model)) }
    }
  }

  #if canImport(nepali_date_picker_core)
    let shivathapaa = nepali_date_picker_core.NepaliDateConverter.shared

    Benchmark("shivathapaa-B1") { benchmark in
      for _ in benchmark.scaledIterations {
        for date in bs {
          blackHole(
            shivathapaa.convertNepaliToEnglish(
              nepaliYYYY: Int32(date.year), nepaliMM: Int32(date.month), nepaliDD: Int32(date.day)))
        }
      }
    }

    Benchmark("shivathapaa-B2") { benchmark in
      for _ in benchmark.scaledIterations {
        for date in ad {
          blackHole(
            shivathapaa.convertEnglishToNepali(
              englishYYYY: Int32(date.year), englishMM: Int32(date.month), englishDD: Int32(date.day)))
        }
      }
    }
  #endif
}
