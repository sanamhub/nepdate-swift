# nepdate-swift

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
- Apple, Linux, Windows, Android and Wasm (Windows in CI; Android and Wasm checked by the Swift
  Package Index build matrix).

Foundation's `Calendar.Identifier.vikram` (iOS 26+) is the Indian lunisolar Vikram calendar, not
Nepal's solar Bikram Sambat; its months don't match. Apple has no Nepali calendar
([docs/competitors.md](docs/competitors.md)). Use this package for Nepali dates.

> **Status:** not released yet. The API in [docs/API.md](docs/API.md) is complete and tested; 0.1.0
> is the first tag.

## Install

Add the package to `Package.swift` once 0.1.0 is tagged:

```swift
.package(url: "https://github.com/sanamhub/nepdate-swift", from: "0.1.0")
```

Then depend on `NepDate`, or on `NepDatePatro` as well for tithi, holidays and events.

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

## Documentation

- [docs/API.md](docs/API.md): every public symbol.
- [docs/benchmarks.md](docs/benchmarks.md): numbers against the other Swift libraries and C# NepDate.
- [docs/competitors.md](docs/competitors.md): the other Swift libraries.
- [docs/adr/](docs/adr/README.md): why it is built this way.
- [shared/spec/](shared/spec/README.md): the algorithm and the data, shared by every port.

The repository holds four packages: the library at the root, and `Tools/Codegen` (generates the
Swift tables from `shared/data`), `Benchmarks`, `Fuzz` and `Examples` beside it, so the library
products have no dependencies.

## License

MIT ([LICENSE](LICENSE)). Calendar data from NepDate by Raju Prasai and contributors, MIT
([shared/data/NOTICE](shared/data/NOTICE)). Not affiliated with the Government of Nepal.
