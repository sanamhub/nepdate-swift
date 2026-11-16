# Benchmarks

B1 to B8 of [`shared/spec/BENCHMARK.md`](../shared/spec/BENCHMARK.md), with B1 and B2 for the Swift
library selected in [`competitors.md`](competitors.md). B1 to B8 of this package are measured on the
reference laptop under WSL 2 (run on 2026-11-16) and on GitHub runners through the `bench-full`
workflow (dispatched on 2026-11-02, `run 41461933392`). The competitor numbers come from the macOS
runner job, because the shivathapaa package ships an arm64 macOS XCFramework; the ubuntu job ran
this package and the C# baseline but could not run the competitor.

## Two platforms

package-benchmark supports Linux and macOS only, so the Swift benchmarks cannot run natively on the
Windows reference machine of BENCHMARK section 1. They are measured two ways:

- **Reference machine, WSL 2.** The same laptop, in WSL 2 Ubuntu 24.04 with the Swift 6.4.1 Linux
  toolchain, pinned to logical CPU 2 with `taskset`, after a 30-second idle gate. This is the
  [first results table](#reference-machine-wsl-2). C# NepDate is not measured in WSL; its column is
  the hub's .NET 10 column on the same CPU under Windows, so the ratio compares two operating
  systems.
- **GitHub runners.** The `bench-full` workflow, run on 2026-11-02, on shared GitHub-hosted
  machines whose load is not controlled. The competitor package ships an arm64 macOS XCFramework
  only, so its numbers exist only here, and C# NepDate is measured on the same runner by the
  vendored `Benchmarks/Vendor/dotnet-bench`. These are the second table and the competitor table.

The two tables are different machines and are never divided by each other. The runner tables were
not re-run on 2026-11-16: a runner run is a dispatched GitHub workflow, not a measurement on the
idle laptop.

## Reference machine, WSL 2

| Item | Value |
|---|---|
| CPU | 12th Gen Intel Core i5-12500H (4 performance + 8 efficiency cores, 16 threads, base 3.1 GHz) |
| OS | WSL 2 Ubuntu 24.04.5 LTS, kernel 6.18.58.1-microsoft-standard-WSL2, on Windows 11 Home |
| Power plan | Ultimate Performance, on AC |
| Affinity | logical CPU 2, `taskset -c 2` on the whole `swift package benchmark` command |
| Swift | 6.4.1 (swift-6.4.1-RELEASE), x86_64-unknown-linux-gnu |
| package-benchmark | 1.36.4, target `NepDateBenchmarks`, release products |
| Date of run | 2026-11-16 |
| Idle gate before the run | 4.7 percent average, 9.1 peak (30 one-second samples, Windows side) |
| Load during the run | 9.2 percent average, 31.9 peak over 72 one-second samples; the single sample above 30 percent is the third second, at the start |
| Allocations | not measured: `libjemalloc` is not installed in WSL and installing it needs root, so the run sets `BENCHMARK_DISABLE_JEMALLOC=true` |

The machine was idle: no other build, test suite or benchmark ran. The command, from a copy of the
repository whose directory is named `nepdate-swift`, was:

```
BENCHMARK_DISABLE_JEMALLOC=true taskset -c 2 swift package --package-path Benchmarks \
  --allow-writing-to-package-directory --allow-writing-to-directory results \
  benchmark --no-progress --target NepDateBenchmarks \
  --format histogramPercentiles --path results/nepdate
```

The percentile files, the `machine.txt` and the load samples are in
[`raw/2026-11-16/bench-wsl/`](raw/2026-11-16/bench-wsl/). The competitor target did not run: it is
macOS arm64 only.

| ID | Operation | p50 ns/op | p90 ns/op | C# .NET 10 ns/op, Windows | ratio Swift/C# |
|---|---|---:|---:|---:|---:|
| B1 | BS to AD | 12.6 | 12.9 | 13.27 | 0.95 |
| B2 | AD to BS | 10.2 | 10.7 | 18.70 | 0.55 |
| B3 | add 1000 days | 6.7 | 7.8 | 20.06 | 0.33 |
| B4 | add 13 months, clamp | 5.7 | 6.2 | 19.30 | 0.30 |
| B5 | long format, Nepali, weekday | 359.4 | 406.2 | 139.04 | 2.58 |
| B6 | strict parse | 22.8 | 23.4 | 21.13 | 1.08 |
| B7 | patro info | 45.2 | 46.5 | 48.63 | 0.93 |
| B8 | patro month grid | 1,578.1 | 1,750.0 | 3,274.50 | 0.48 |

B5a, B7-sorted and MonthRange on the same run: 312.5, 72.6 and 70.9 ns/op at p50. BENCHMARK section 6
asks for B1, B2 and B7 within 1.5 times C# NepDate: B1 is 0.95, B2 is 0.55 and B7 is 0.93, so the
target holds on the reference CPU. Allocation was not measured here; the runner run below measured
it.

## Runner (2026-11-02)

| Item | Value |
|---|---|
| Host | GitHub-hosted, shared, load not controlled |
| CPU | Apple M1 (virtual), 3 vCPU |
| OS | macOS 26.6.2 (25G83) |
| Swift | 6.3.3 (swiftlang-6.3.3.1.3) |
| Xcode | 26.6 (17F113) |
| .NET | SDK 10.0.403, runtime 10.0.14 |
| Run date (UTC) | 2026-11-02T14:26:49Z |

The reference-machine C# numbers in the last column were measured on 2026-11-16 with .NET 10 on a
12th Gen Intel Core i5-12500H, Windows 11, Ultimate Performance, pinned to logical CPU 2.

## How to read the table

- One benchmark iteration runs all 64 inputs of BENCHMARK section 2. package-benchmark's scaling
  factor is a power of 1,000, so `.one` leaves the value per iteration; each ns/op below is that
  value divided by 64.
- p50 and p90 are package-benchmark's percentiles. They are not a mean and a standard deviation.
- `mallocs/op` is `mallocCountTotal` minus the `Baseline` benchmark, divided by 64. The Linux harness
  allocates 16 times per iteration on its own, so a 0 in the table means NepDate added no allocation.
- The C# column is BenchmarkDotNet's mean with `OperationsPerInvoke = 64`, already per operation.

## Results on the runner

| ID | Operation | p50 ns/op | p90 ns/op | NepDate mallocs/op | C# .NET 10 ns/op, same runner | ratio Swift/C# | C# ns/op, reference machine |
|---|---|---:|---:|---:|---:|---:|---:|
| B1 | BS to AD | 20.2 | 24.7 | 0 | 21.9 | 0.92 | 13.27 |
| B2 | AD to BS | 16.9 | 26.0 | 0 | 29.6 | 0.57 | 18.70 |
| B3 | add 1000 days | 17.6 | 26.7 | 0 | 28.6 | 0.62 | 20.06 |
| B4 | add 13 months, clamp | 19.5 | 36.5 | 0 | 16.9 | 1.16 | 19.30 |
| B5 | long format, Nepali, weekday | 421.9 | 984.4 | 1 | 215.1 | 1.96 | 139.04 |
| B6 | strict parse | 32.6 | 76.2 | 0 | 29.9 | 1.09 | 21.13 |
| B7 | patro info | 38.4 | 54.7 | 0 | 50.6 | 0.76 | 48.63 |
| B8 | patro month grid | 1,468.8 | 2,937.5 | 0 | 3,356.3 | 0.44 | 3,274.50 |

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
