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

**Status:** phase S0 done (package skeleton, generator, CI on macOS, Linux and Windows); next: phase S1.

## Where to start

| You are | Read |
|---|---|
| an AI agent implementing a phase | [AGENTS.md](AGENTS.md) → [docs/plan/00-ROADMAP.md](docs/plan/00-ROADMAP.md) |
| reviewing the API | [docs/API.md](docs/API.md) |
| comparing with other Swift libraries | [docs/competitors.md](docs/competitors.md) |
| wondering "why is it like this?" | [docs/adr/README.md](docs/adr/README.md) |
| looking for the algorithm or data | [shared/spec/README.md](shared/spec/README.md) (changes go to the hub) |

## Layout

```
shared/                  hub copy: data/, spec/, VERSION
Package.swift            products NepDate, NepDatePatro
Sources/NepDate/         core                         (phase S0)
Sources/NepDatePatro/    tithi, holidays, events      (phase S4)
Tests/                   swift-testing, shared vectors
Tools/Codegen/           separate package: generates the Swift tables from shared/data
Benchmarks/              separate package: package-benchmark B1 to B8, malloc counts (from S1)
Fuzz/                    separate package: libFuzzer targets for the parsers, Linux (phase S3)
Examples/                separate package: core-only and with-patro executables (phase S4)
docs/                    API.md, competitors.md, adr/, plan/, runbooks/
```

## License

MIT ([LICENSE](LICENSE)). Calendar data from NepDate by Raju Prasai and contributors, MIT
([shared/data/NOTICE](shared/data/NOTICE)). Not affiliated with the Government of Nepal.
