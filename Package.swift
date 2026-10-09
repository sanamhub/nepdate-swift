// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "NepDate",
  platforms: [.iOS(.v15), .macOS(.v12), .watchOS(.v8), .tvOS(.v15), .visionOS(.v1)],
  products: [
    .library(name: "NepDate", targets: ["NepDate"])
  ],
  targets: [
    .target(name: "NepDate"),
    .testTarget(name: "NepDateTests", dependencies: ["NepDate"]),
  ],
  swiftLanguageModes: [.v6]
)
