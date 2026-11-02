# Other Swift libraries for the Bikram Sambat calendar

Checked 2026-11-02 against GitHub, the Swift Package Index, CocoaPods and the swift-foundation
sources. The selection follows [`shared/spec/BENCHMARK.md`](../shared/spec/BENCHMARK.md) section 7.
Usage is GitHub stars plus dependents, read on 2026-11-02, and whether the package is in the Swift
Package Index. The bar is 10 stars or a Swift Package Index entry, first release at least 12 months
before 2026-11-02, a release or commit in the last 36 months, a license, not archived or deprecated,
and a build on the current Swift toolchain.

## Candidate table

| Library | Stars | First release | Last release | License | Kind | Verdict |
|---|---:|---|---|---|---|---|
| `shivathapaa/Nepali-Date-Picker-SPM` | 13 | 2024-09-14 | 2026-09-21 | MPL-2.0 | SwiftPM package around a Kotlin/Native XCFramework | selected |
| `nrlnishan/NepaliDateConverter` | 4 | 2019 | 2019-06-01 | MIT | CocoaPods source, no SwiftPM | fails 10 stars and the 36-month bar |
| `NepaliCalendar` (CocoaPods) | not on GitHub | 2015 | 2015 | MIT | Objective-C pod | fails 10 stars and the 36-month bar |
| `junkeri-opensource-ios/NepaliIOSSamayaPicker` | not measured | 2025 | 2025 | MIT | UI picker | fails the 12-month bar and has no conversion API |

The Swift Package Index search for `nepali` returns only `sanamhub/nepdate-swift`. The
shivathapaa package is not indexed there, but its GitHub repository has the stars and release
history above.

## Selected library

`shivathapaa/Nepali-Date-Picker-SPM` 3.3.0 is the only candidate that passes. The package ships an
arm64 macOS XCFramework, so the benchmark runs only on the macOS runner. The harness calls
`NepaliDateConverter.shared.convertNepaliToEnglish(nepaliYYYY:nepaliMM:nepaliDD:)` for B1 and
`convertEnglishToNepali(englishYYYY:englishMM:englishDD:)` for B2.

## Correctness

shivathapaa differs from `shared/data` by one day at BS 2086-07-23, 2088-01-04 and 2089-06-10, in
both directions. It agrees on 61 of the 64 dates. A fast wrong answer is listed, never ranked first.

## Sources

https://github.com/shivathapaa/Nepali-Date-Picker,
https://github.com/shivathapaa/Nepali-Date-Picker-SPM,
https://github.com/nrlnishan/NepaliDateConverter,
https://swiftpackageindex.com/search?query=nepali,
https://github.com/swiftlang/swift-foundation.
