// swift-tools-version: 6.0
import PackageDescription

// Three small executables for the patro-free core check and the size targets (ADR-0004, ADR-0006). A path dependency's
// package identity is its directory name, so the checkout folder must be named `nepdate-swift`
// (see CONTRIBUTING.md) and the products are referenced by that name.
let package = Package(
  name: "Examples",
  platforms: [.macOS(.v12)],
  dependencies: [
    .package(path: "..")
  ],
  targets: [
    .executableTarget(name: "baseline"),
    .executableTarget(
      name: "core-only",
      dependencies: [.product(name: "NepDate", package: "nepdate-swift")]),
    .executableTarget(
      name: "with-patro",
      dependencies: [
        .product(name: "NepDate", package: "nepdate-swift"),
        .product(name: "NepDatePatro", package: "nepdate-swift"),
      ]),
  ],
  swiftLanguageModes: [.v6]
)
