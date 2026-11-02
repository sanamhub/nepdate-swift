// B1 and B2 for the Swift library selected in docs/competitors.md, over the same 64 dates as
// BENCHMARK §2. Times are per iteration of 64 operations, like NepDateBenchmarks.
//
// The shivathapaa engine is an arm64 macOS XCFramework, so its two benchmarks exist only there.

import Benchmark
import BenchmarkInputs

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

  #if canImport(nepali_date_picker_core)
    let shivathapaa = nepali_date_picker_core.NepaliDateConverter.shared

    Benchmark("shivathapaa-B1", configuration: configuration) { benchmark in
      for _ in benchmark.scaledIterations {
        for date in bs {
          blackHole(
            shivathapaa.convertNepaliToEnglish(
              nepaliYYYY: Int32(date.year), nepaliMM: Int32(date.month), nepaliDD: Int32(date.day)))
        }
      }
    }

    Benchmark("shivathapaa-B2", configuration: configuration) { benchmark in
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
