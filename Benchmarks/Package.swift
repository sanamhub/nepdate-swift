// swift-tools-version: 6.0
import PackageDescription

// Benchmarks live in their own package so users of NepDate never resolve package-benchmark
// (ADR-0001). Run from the repository root:
//   swift package --package-path Benchmarks benchmark
let package = Package(
  name: "Benchmarks",
  platforms: [.macOS(.v13)],
  dependencies: [
    .package(path: ".."),
    .package(url: "https://github.com/ordo-one/package-benchmark", exact: "1.36.4"),
  ],
  targets: [
    .target(
      name: "BenchmarkInputs",
      dependencies: [.product(name: "NepDate", package: "nepdate-swift")]),
    .executableTarget(
      name: "NepDateBenchmarks",
      dependencies: [
        "BenchmarkInputs",
        .product(name: "NepDate", package: "nepdate-swift"),
        .product(name: "Benchmark", package: "package-benchmark"),
      ],
      path: "Benchmarks/NepDateBenchmarks",
      plugins: [.plugin(name: "BenchmarkPlugin", package: "package-benchmark")]),
    .executableTarget(
      name: "first-access",
      dependencies: [.product(name: "NepDate", package: "nepdate-swift")]),
  ],
  swiftLanguageModes: [.v6]
)
