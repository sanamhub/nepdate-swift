# Benchmarks

B1 to B8 of [`shared/spec/BENCHMARK.md`](../shared/spec/BENCHMARK.md), with B1 and B2 for the Swift
library selected in [`competitors.md`](competitors.md). The numbers come from the `bench-full`
workflow dispatched on 2026-11-02 (`run 41461933392`); the macOS job is used because the shivathapaa
package ships an arm64 macOS XCFramework. The ubuntu job ran this package and the C# baseline but
could not run the competitor.

## Why the runners and not the reference machine

BENCHMARK section 1 names a Windows reference machine. package-benchmark supports Linux and macOS
only, so the Swift benchmarks cannot run there. The Swift numbers are therefore GitHub-runner
numbers, and C# NepDate is measured on the same runner by the vendored
`Benchmarks/Vendor/dotnet-bench`, so the ratio compares the two libraries on the same CPU and OS.
The reference-machine column is copied from the hub's `docs/benchmarks/dotnet.md` for context only
and is never divided by a runner number.

Both runners are GitHub-hosted shared machines, and the workflow does not control the machine load.
Read p50 and p90 together, and read the ratios as noisy.

## Runner

| Item | Value |
|---|---|
| Host | GitHub-hosted, shared, load not controlled |
| CPU | Apple M1 (virtual), 3 vCPU |
| OS | macOS 26.6.2 (25G83) |
| Swift | 6.3.3 (swiftlang-6.3.3.1.3) |
| Xcode | 26.6 (17F113) |
| .NET | SDK 10.0.403, runtime 10.0.14 |
| Run date (UTC) | 2026-11-02T14:26:49Z |

The reference-machine C# numbers in the last column were measured on 2026-11-02 with .NET 10 on a
12th Gen Intel Core i5-12500H, Windows 11, Ultimate Performance, pinned to logical CPU 2.

## How to read the table

- One benchmark iteration runs all 64 inputs of BENCHMARK section 2. package-benchmark's scaling
  factor is a power of 1,000, so `.one` leaves the value per iteration; each ns/op below is that
  value divided by 64.
- p50 and p90 are package-benchmark's percentiles. They are not a mean and a standard deviation.
- `mallocs/op` is `mallocCountTotal` minus the `Baseline` benchmark, divided by 64. The Linux harness
  allocates 16 times per iteration on its own, so a 0 in the table means NepDate added no allocation.
- The C# column is BenchmarkDotNet's mean with `OperationsPerInvoke = 64`, already per operation.

## Results

| ID | Operation | p50 ns/op | p90 ns/op | NepDate mallocs/op | C# .NET 10 ns/op, same runner | ratio Swift/C# | C# ns/op, reference machine |
|---|---|---:|---:|---:|---:|---:|---:|
| B1 | BS to AD | 20.2 | 24.7 | 0 | 21.9 | 0.92 | 13.50 |
| B2 | AD to BS | 16.9 | 26.0 | 0 | 29.6 | 0.57 | 20.10 |
| B3 | add 1000 days | 17.6 | 26.7 | 0 | 28.6 | 0.62 | 19.05 |
| B4 | add 13 months, clamp | 19.5 | 36.5 | 0 | 16.9 | 1.16 | 20.19 |
| B5 | long format, Nepali, weekday | 421.9 | 984.4 | 1 | 215.1 | 1.96 | 150.41 |
| B6 | strict parse | 32.6 | 76.2 | 0 | 29.9 | 1.09 | 22.42 |
| B7 | patro info | 38.4 | 54.7 | 0 | 50.6 | 0.76 | 48.21 |
| B8 | patro month grid | 1,468.8 | 2,937.5 | 0 | 3,356.3 | 0.44 | 3,112.76 |

B5 allocates the returned string, one per operation. B5a is the same format into a reused buffer:

| Benchmark | p50 ns/op | p90 ns/op | mallocs/op | What it is |
|---|---:|---:|---:|---|
| B5a | 312.5 | 718.8 | 0 | B5 with `appendLong(to:)` and a warm buffer |
| B7-sorted | 109.4 | 265.6 | 0 | PATRO section 3's binary-search layout, for comparison with B7 |
| MonthRange | 78.8 | 218.1 | 0 | one month of `NepaliDateRange` per input |

## Competitor

B1 and B2 over the same 64 dates, run by the `CompetitorBenchmarks` target. The agrees counts come
from `Benchmarks/Tests/CompetitorAgreementTests`, which rebuilds the 64 dates from
`shared/data/calendar/bs-calendar.json` and Hinnant's arithmetic without calling NepDate.

| Library | B1 ns/op | B1 agrees | B2 ns/op | B2 agrees | mallocs/op (B1 / B2) |
|---|---:|---|---:|---|---|
| shivathapaa/Nepali-Date-Picker-SPM 3.3.0 | 937.5 | no, 61 of 64 | 1,062.5 | no, 61 of 64 | 2 / 2 |

shivathapaa differs from `shared/data` by one day at BS 2086-07-23, 2088-01-04 and 2089-06-10, in
both directions. It is slower than this package on both conversions.

## Targets

BENCHMARK section 6 asks for B1, B2 and B7 within 1.5 times C# on the same runner, zero mallocs for
B1 to B4 and B6 to B8, and one malloc for B5.

| Target | Result |
|---|---|
| B1 at most 1.5 times C# | 0.92, pass |
| B2 at most 1.5 times C# | 0.57, pass |
| B7 at most 1.5 times C# | 0.76, pass |
| 0 mallocs, B1 to B4 and B6 to B8 | 0, pass |
| 1 malloc, B5 | 1, pass |

The raw files are under [`raw/2026-11-02/bench-macos-latest/`](raw/2026-11-02/bench-macos-latest/),
including `ratio.md`, `machine.txt` and the package-benchmark percentile files. The same files for
the ubuntu job are in `raw/2026-11-02/bench-ubuntu-latest/`.

## Reproduce

```
gh workflow run bench-full.yml
```

The workflow checks out `main`, so a branch run needs the branch pushed first. This pass used the
existing workflow on `main`.
