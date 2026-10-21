<p align="center">
  <img src="https://raw.githubusercontent.com/sanamhub/nepdate-swift/main/docs/assets/nepdate-swift-128.png" width="128" alt="NepDate for Swift logo">
</p>

<h1 align="center">nepdate-swift</h1>

<p align="center">
  <a href="https://github.com/sanamhub/nepdate-swift/actions/workflows/ci.yml"><img src="https://github.com/sanamhub/nepdate-swift/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/sanamhub/nepdate-swift/releases"><img src="https://img.shields.io/github/v/release/sanamhub/nepdate-swift?include_prereleases&sort=semver&logo=swift" alt="Release"></a>
  <a href="https://swiftpackageindex.com/sanamhub/nepdate-swift"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsanamhub%2Fnepdate-swift%2Fbadge%3Ftype%3Dswift-versions" alt="Swift versions"></a>
  <a href="https://swiftpackageindex.com/sanamhub/nepdate-swift"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsanamhub%2Fnepdate-swift%2Fbadge%3Ftype%3Dplatforms" alt="Platforms"></a>
  <a href="https://github.com/sanamhub/nepdate-swift/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="License: MIT"></a>
</p>

Bikram Sambat (Nepali calendar) for Swift. Part of the NepDate family: shared data and spec live
in the hub [`sanamhub/nepdate`](https://github.com/sanamhub/nepdate); the C# original is
[NepDate](https://github.com/RajuPrasai/NepDate). The iOS app in
[`nepdate-mobile`](https://github.com/sanamhub/nepdate-mobile) is its first user.

- SwiftPM package with two products: `NepDate` (conversion, formatting, parsing, arithmetic, fiscal
  year) and `NepDatePatro`, the patro (पात्रो, the Nepali almanac: tithi, public holidays and events
  for BS 2077-01-01 to 2084-08-20). `NepDatePatro` depends on `NepDate`, never the reverse, so an
  app that only converts dates links no patro data. Both are released together from one tag.
- Built for speed: an 8-byte `NepaliDate`, conversion in two or three table reads with no loop,
  patro lookups in O(1), and no heap allocation for conversion, arithmetic, parsing or patro
  lookups. Targets and how they are measured: [ADR-0002](docs/adr/0002-representation-and-performance.md).
- Pure Swift, Swift 6 language mode, every type `Sendable`. No dependencies. The core does not need
  Foundation; `Date` interop compiles in where Foundation exists. Small enough for widget and watch
  extensions.
- BS 1901-01-01 to 2199-12-30 (AD 1844-04-11 to 2143-04-15). Same results as C# NepDate and every
  other port, proved by the shared vectors.
- Apple, Linux and Windows, all three in CI. Android and Wasm builds come from the Swift Package
  Index build matrix once the package is listed there.

Foundation's `Calendar.Identifier.vikram` (iOS 26+) is the Indian lunisolar Vikram calendar, not
Nepal's solar Bikram Sambat; its months don't match. Apple has no Nepali calendar
([docs/competitors.md](docs/competitors.md)). Use this package for Nepali dates.

> **Status:** 0.1.0-beta.1, the first public pre-release. The API is listed in
> [docs/API.md](docs/API.md) and may still change before 0.1.0. Patro data (tithi, holidays,
> events) is informational, not an official calendar.

## Install

Add the package to `Package.swift`. SwiftPM only picks a pre-release when the requirement names
one:

```swift
.package(url: "https://github.com/sanamhub/nepdate-swift", exact: "0.1.0-beta.1")
```

Then depend on `NepDate`, or on `NepDatePatro` as well for tithi, holidays and events:

```swift
.product(name: "NepDate", package: "nepdate-swift"),
.product(name: "NepDatePatro", package: "nepdate-swift"),
```

## Quick start

Core conversion, formatting and parsing, with no patro data linked:

```swift
import NepDate

do {
  let date = try NepaliDate(year: 2081, month: 4, day: 15)
  print(date.format("s"))
  print(date.long(weekday: true))
  print(try NepaliDate.parse("2081-04-15").description)
} catch {
  print("error: \(error)")
}
```

The same date with the patro product, which links the tithi, holiday and event tables:

```swift
import NepDate
import NepDatePatro

let date = (try? NepaliDate(year: 2081, month: 1, day: 1)) ?? .min
let info = date.calendarInfo
print(info.tithi?.english ?? "no tithi")
for event in info.events {
  print(event.english)
}
```

Both blocks are the `Examples` programs, so CI builds and runs them.

## More

| Topic | Where |
|---|---|
| Every public symbol | [docs/API.md](docs/API.md) |
| Speed and allocations, against the other Swift libraries and C# NepDate | [docs/benchmarks.md](docs/benchmarks.md) |
| The other Swift libraries | [docs/competitors.md](docs/competitors.md) |
| Why it is built this way | [docs/adr/](docs/adr/README.md) |
| The algorithm and data shared by every port | [shared/spec/](shared/spec/README.md) |
| What changed in each version | [CHANGELOG.md](CHANGELOG.md) |
| Building, gates and pull requests | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Reporting a vulnerability | [SECURITY.md](SECURITY.md) |
| A wrong date, holiday or tithi | the hub's [data error form](https://github.com/sanamhub/nepdate/issues/new/choose) |
| The other languages | [sanamhub/nepdate](https://github.com/sanamhub/nepdate#packages) |

The repository holds four packages: the library at the root, and `Tools/Codegen` (generates the
Swift tables from `shared/data`), `Benchmarks`, `Fuzz` and `Examples` beside it, so the library
products have no dependencies.

## License

MIT ([LICENSE](LICENSE)). Calendar data from NepDate by Raju Prasai and contributors, MIT
([shared/data/NOTICE](shared/data/NOTICE)). Not affiliated with the Government of Nepal.
