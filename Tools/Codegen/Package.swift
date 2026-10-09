// swift-tools-version: 6.0
import PackageDescription

// Dev-time tools, kept out of the library package so users never resolve them (ADR-0001).
let package = Package(
  name: "Codegen",
  platforms: [.macOS(.v13)],
  targets: [
    .executableTarget(name: "codegen"),
    .executableTarget(name: "coverage-check"),
  ],
  swiftLanguageModes: [.v6]
)
