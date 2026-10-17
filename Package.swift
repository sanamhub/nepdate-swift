// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "NepDate",
  platforms: [.iOS(.v15), .macOS(.v12), .watchOS(.v8), .tvOS(.v15), .visionOS(.v1)],
  products: [
    .library(name: "NepDate", targets: ["NepDate"]),
    .library(name: "NepDatePatro", targets: ["NepDatePatro"]),
  ],
  targets: [
    .target(name: "NepDate"),
    .target(name: "NepDatePatro", dependencies: ["NepDate"]),
    .testTarget(name: "NepDateTests", dependencies: ["NepDate"]),
    .testTarget(name: "NepDatePatroTests", dependencies: ["NepDate", "NepDatePatro"]),
  ],
  swiftLanguageModes: [.v6]
)
