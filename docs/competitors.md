# Other Swift libraries for the Bikram Sambat calendar

Checked 2026-10-06, rechecked 2026-10-08 (GitHub, CocoaPods, Swift Package Index, Apple and
swift-foundation sources; no new Swift package found). Used by task S5-02. The Swift Package
Index returns no package for "nepali".

| Library | Latest | License | BS range | Approach | State |
|---|---|---|---|---|---|
| `nrlnishan/NepaliDateConverter` (CocoaPods) | 1.0.1, 2019 | MIT | 2000–2090 | month table, counts days in a loop | dead; no SwiftPM, iOS 9 |
| `shivathapaa/Nepali-Date-Picker-SPM` | 3.3.0, 2026-09 | MPL-2.0 | 1970–2100 | **Kotlin/Native binary XCFramework**, static archive ~7.7 MB per slice; arm64 only, no watchOS; needs Xcode build-setting workarounds; ships no holiday data | active |
| `NepaliCalendar` (CocoaPods) | 0.1.1, 2015 | MIT | undocumented | Objective-C | dead |
| `junkeri-opensource-ios/NepaliIOSSamayaPicker` | 2025-01 | MIT | n/a | UI picker | low activity |
| Apps (not libraries): `dibas-np/NepalKit` (GPL-3), `stha-ums/NepaliCalendarMenuBar`, `pray3m/aaza`, `nabinkhair42/nepali-calendar` | 2026 | mixed | n/a | Xcode projects | n/a |

**Foundation:** `Calendar.Identifier.vikram` is one of 11 identifiers added by the "Expanded calendar
support" proposal, declared `@available(FoundationPreview 6.2, *)` in swift-foundation's
`Calendar.swift` (rechecked 2026-10-08) and shipped in iOS/macOS 26. The proposal calls it the
"Vikram lunisolar calendar", one of the calendars "used in regions in India"; Apple's ICU fork
computes it as a Hindu lunisolar calendar for Ujjain, with adhika (repeated) days. Nepal's official
Bikram Sambat is solar with 29 to 32-day months set by the calendar committee, so month boundaries
differ. swift-foundation has no Nepali identifier, and upstream ICU and CLDR have no Nepali
calendar. So nothing native replaces this package; the README warns against `.vikram`.

**Benchmark plan:** task S5-02. Competitors run B1 (BS to AD) and B2 (AD to BS) over the 64
`shared/spec/BENCHMARK.md` dates; only this package runs B3 to B8 (no competitor has the
operation, or the shivathapaa package has it only through its Kotlin runtime).

Sources: https://github.com/nrlnishan/NepaliDateConverter,
https://github.com/shivathapaa/Nepali-Date-Picker-SPM, https://swiftpackageindex.com/search?query=nepali,
https://github.com/swiftlang/swift-foundation (Calendar.swift),
https://github.com/swiftlang/swift-foundation-icu (hinducal), https://github.com/unicode-org/cldr
(common/bcp47/calendar.xml),
https://forums.swift.org/t/pitch-expanded-calendar-support/77438.
