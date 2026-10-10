// swift-tools-version: 6.0
import PackageDescription

// libFuzzer targets for the parsers and the pattern formatter (ADR-0004), Linux only. Build with
//   swift build -c debug --package-path Fuzz -Xswiftc -sanitize=fuzzer,address \
//     -Xswiftc -parse-as-library
// libFuzzer supplies `main`; each target exports `LLVMFuzzerTestOneInput`.
let package = Package(
  name: "Fuzz",
  dependencies: [.package(path: "..")],
  targets: [
    .executableTarget(
      name: "FuzzParse", dependencies: [.product(name: "NepDate", package: "nepdate-swift")]),
    .executableTarget(
      name: "FuzzParseLenient", dependencies: [.product(name: "NepDate", package: "nepdate-swift")]
    ),
    .executableTarget(
      name: "FuzzFormat", dependencies: [.product(name: "NepDate", package: "nepdate-swift")]),
  ],
  swiftLanguageModes: [.v6]
)
