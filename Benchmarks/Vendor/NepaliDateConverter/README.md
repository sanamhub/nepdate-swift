# Vendored: nrlnishan/NepaliDateConverter

`DateConverter.swift` is copied unchanged from
[`nrlnishan/NepaliDateConverter`](https://github.com/nrlnishan/NepaliDateConverter) at `master`
(1.0.1, 2019), MIT, with the licence in `LICENSE`. It is vendored because the library has no
SwiftPM manifest and is not on the Swift Package Index, so a benchmark cannot resolve it.

The benchmark runs B1 and B2 over the 64 `shared/spec/BENCHMARK.md` dates. Its month table differs
from `shared/data` in BS 2062 and 2081 to 2089, and `getNepaliDate` uses a strict `>` against the
month length, so a few dates disagree. `Benchmarks/Tests/CompetitorAgreementTests` records the
exact counts.
