// swift-tools-version: 6.0
import PackageDescription

// Benchmarks live in their own package so users of NepDate never resolve package-benchmark
// (ADR-0001). Run from the repository root:
//   swift package --package-path Benchmarks benchmark
//
// The shivathapaa engine is an arm64 macOS XCFramework only, so its binary target and the code that
// calls it exist only on that platform. The nrlnishan converter is vendored MIT source and builds
// everywhere.
#if os(macOS) && arch(arm64)
  let shivathapaaTargets: [Target] = [
    .binaryTarget(
      name: "nepali_date_picker_core",
      url:
        "https://github.com/shivathapaa/Nepali-Date-Picker-SPM/releases/download/3.3.0/nepali_date_picker_core.xcframework.zip",
      checksum: "57f64dac9083490e4aabf65b768b919429ffe7fb89f025a5027311bed2011ae4")
  ]
  let competitorDependencies: [Target.Dependency] = [
    "NRLNishan", .target(name: "nepali_date_picker_core"),
  ]
#else
  let shivathapaaTargets: [Target] = []
  let competitorDependencies: [Target.Dependency] = ["NRLNishan"]
#endif

let package = Package(
  name: "Benchmarks",
  platforms: [.macOS(.v13)],
  dependencies: [
    .package(path: ".."),
    .package(url: "https://github.com/ordo-one/benchmark", exact: "1.36.4"),
  ],
  targets: [
    .target(
      name: "BenchmarkInputs",
      dependencies: [.product(name: "NepDate", package: "nepdate-swift")]),
    // The MIT source of nrlnishan/NepaliDateConverter, unchanged, with its licence. The target is
    // named NRLNishan because the shivathapaa framework also declares a `NepaliDateConverter`.
    .target(
      name: "NRLNishan",
      path: "Vendor/NepaliDateConverter",
      exclude: ["LICENSE", "README.md"]),
    .executableTarget(
      name: "NepDateBenchmarks",
      dependencies: [
        "BenchmarkInputs",
        .product(name: "NepDate", package: "nepdate-swift"),
        .product(name: "NepDatePatro", package: "nepdate-swift"),
        .product(name: "Benchmark", package: "benchmark"),
      ],
      path: "Benchmarks/NepDateBenchmarks",
      plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]),
    .executableTarget(
      name: "CompetitorBenchmarks",
      dependencies: competitorDependencies + [
        "BenchmarkInputs", .product(name: "Benchmark", package: "benchmark"),
      ],
      path: "Benchmarks/CompetitorBenchmarks",
      plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]),
    .executableTarget(
      name: "first-access",
      dependencies: [.product(name: "NepDate", package: "nepdate-swift")]),
    .executableTarget(
      name: "b5-profile",
      dependencies: [.product(name: "NepDate", package: "nepdate-swift")]),
    .testTarget(
      name: "CompetitorAgreementTests",
      dependencies: ["BenchmarkInputs"] + competitorDependencies),
  ] + shivathapaaTargets,
  swiftLanguageModes: [.v6]
)
