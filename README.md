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

- SwiftPM package with two products: `NepDate` (dates, conversion, arithmetic, formatting, parsing,
  ranges, fiscal years and errors) and `NepDatePatro`, the patro (पात्रो, the Nepali almanac: tithi,
  public holidays and events for BS 2077-01-01 to 2084-08-20). `NepDatePatro` depends on `NepDate`,
  never the reverse, so an app that only converts dates links no patro data. Both are released
  together from one tag.
- Built for speed: an 8-byte `NepaliDate`, conversion in two or three table reads with no loop,
  patro lookups in O(1), and no heap allocation for conversion, arithmetic, parsing or patro
  lookups. Targets and how they are measured:
  [ADR-0002](https://github.com/sanamhub/nepdate-swift/blob/main/docs/adr/0002-representation-and-performance.md).
- Pure Swift, Swift 6 language mode, every type `Sendable`. No dependencies. The core does not need
  Foundation; `Date` interop and `FormatStyle` compile in where Foundation exists. Small enough for
  widget and watch extensions.
- BS 1901-01-01 to 2199-12-30 (AD 1844-04-11 to 2143-04-15). Same results as C# NepDate and every
  other port, proved by the shared vectors.
- Apple, Linux and Windows, all three in CI. Android and Wasm builds come from the Swift Package
  Index build matrix once the package is listed there.

Foundation's `Calendar.Identifier.vikram` (iOS 26+) is the Indian lunisolar Vikram calendar, not
Nepal's solar Bikram Sambat; its months don't match. Apple has no Nepali calendar
([docs/competitors.md](https://github.com/sanamhub/nepdate-swift/blob/main/docs/competitors.md)).
Use this package for Nepali dates.

> **Status:** 1.0.0-rc.1, the release candidate on the 1.0 line. The API is listed in
> [docs/API.md](https://github.com/sanamhub/nepdate-swift/blob/main/docs/API.md) and is stable from
> 1.0 (hub ADR-0009). Patro data (tithi, holidays, events) is informational, not an official
> calendar.

## Install

Add the package to `Package.swift`. SwiftPM only picks a pre-release when the requirement names
one:

```swift
.package(url: "https://github.com/sanamhub/nepdate-swift", exact: "1.0.0-rc.1")
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

Both blocks are the `Examples` programs, so CI builds and runs them. The complete surface, with a
short example for every member, is in [docs/API.md](https://github.com/sanamhub/nepdate-swift/blob/main/docs/API.md).

## What it covers

### Dates and comparison

```swift
import NepDate

do {
  let date = try NepaliDate(year: 2081, month: 4, day: 15)
  let (y, m, d) = (date.year, date.month, date.day)  // (2081, 4, 15)
  print(date.weekday, date.dayOfYear, date.monthLength, date.yearLength)
  print(date.adding(days: 1))  // the next day
} catch {
  print(error)
}
```

### Conversion and serialization

```swift
import Foundation
import NepDate

do {
  let date = try NepaliDate(gregorianYear: 2024, month: 7, day: 30)
  let midnight = date.date(in: .current)
  let packed = date.ymd  // 20810415
  let json = try JSONEncoder().encode(date)  // "2081-04-15"
  print(midnight, packed, json)
} catch {
  print(error)
}
```

### Arithmetic

```swift
import NepDate

do {
  let date = try NepaliDate(year: 2081, month: 4, day: 15)
  let later = try date.adding(months: 2)
  print(date.days(until: later))  // 63
  print((later - date).totalDays)  // 63
  print(try date.adding(months: 2, overflow: .spill))
} catch {
  print(error)
}
```

### Formatting

```swift
import NepDate

do {
  let date = try NepaliDate(year: 2081, month: 4, day: 15)
  print(date.short(order: .dmy, separator: .dash))  // 15-04-2081
  print(date.long(lang: .nepali))                   // साउन १५, २०८१
  print(date.format("yyyy-MM-dd"))                  // 2081-04-15
} catch {
  print(error)
}
```

### Parsing

```swift
import NepDate

do {
  let strict = try NepaliDate.parse("2081-04-15")
  let lenient = try NepaliDate.parseLenient("15 Shrawan 2081")
  let optional = NepaliDate(lenient: "Shrawan 15, 2081")
  print(strict, lenient, optional as Any)
} catch {
  print(error)
}
```

### Ranges

```swift
import NepDate

do {
  let start = try NepaliDate(year: 2081, month: 4, day: 10)
  let range = try NepaliDateRange(start: start, dayCount: 11)
  print(range.description)  // 2081/04/10 - 2081/04/20
  print(range.splitByMonth().count)
  print(range.workingDays().count)
  print(range.formatted(order: .dmy, separator: .dash))
} catch {
  print(error)
}
```

### Fiscal year

```swift
import NepDate

do {
  let date = try NepaliDate(year: 2081, month: 4, day: 15)
  let fiscal = date.fiscalYear
  print(try fiscal.range(of: .q2))  // 2081/07/01 - 2081/09/29
  print(fiscal.label())             // 2081/82
} catch {
  print(error)
}
```

### Patro

```swift
import NepDate
import NepDatePatro

let date = (try? NepaliDate(year: 2081, month: 1, day: 1)) ?? .min
let info = date.calendarInfo
print(info.tithi?.english ?? "no tithi")
print(info.isPublicHoliday)
for event in info.events {
  print(event.english)
}
```

### Errors

```swift
import NepDate

do {
  _ = try NepaliDate(year: 2080, month: 13, day: 1)
} catch let error as NepDateError {
  print(error.kind)  // invalidMonth
}
```

## More

| Topic | Where |
|---|---|
| Every public symbol | [docs/API.md](https://github.com/sanamhub/nepdate-swift/blob/main/docs/API.md) |
| Speed and allocations, against the other Swift libraries and C# NepDate | [docs/benchmarks.md](https://github.com/sanamhub/nepdate-swift/blob/main/docs/benchmarks.md) |
| The other Swift libraries | [docs/competitors.md](https://github.com/sanamhub/nepdate-swift/blob/main/docs/competitors.md) |
| Why it is built this way | [docs/adr/](https://github.com/sanamhub/nepdate-swift/blob/main/docs/adr/README.md) |
| The algorithm and data shared by every port | [shared/spec/](https://github.com/sanamhub/nepdate-swift/blob/main/shared/spec/README.md) |
| What changed in each version | [CHANGELOG.md](https://github.com/sanamhub/nepdate-swift/blob/main/CHANGELOG.md) |
| Building, gates and pull requests | [CONTRIBUTING.md](https://github.com/sanamhub/nepdate-swift/blob/main/CONTRIBUTING.md) |
| Reporting a vulnerability | [SECURITY.md](https://github.com/sanamhub/nepdate-swift/blob/main/SECURITY.md) |
| Guides and examples | [nepdate.com/docs/swift](https://nepdate.com/docs/swift/) |
| A wrong date, holiday or tithi | the hub's [data error form](https://github.com/sanamhub/nepdate/issues/new/choose) |
| The other languages | [sanamhub/nepdate](https://github.com/sanamhub/nepdate#packages) |

The repository holds four packages: the library at the root, and `Tools/Codegen` (generates the
Swift tables from `shared/data`), `Benchmarks`, `Fuzz` and `Examples` beside it, so the library
products have no dependencies.

## License

MIT ([LICENSE](https://github.com/sanamhub/nepdate-swift/blob/main/LICENSE)). Calendar data from NepDate by
Raju Prasai and contributors, MIT
([shared/data/NOTICE](https://github.com/sanamhub/nepdate-swift/blob/main/shared/data/NOTICE)). Not affiliated
with the Government of Nepal.
