# Benchmarks

B1 to B8 of [`shared/spec/BENCHMARK.md`](../shared/spec/BENCHMARK.md), with B1 and B2 for every
Swift library in [`competitors.md`](competitors.md) that has a conversion API. The numbers come from
the `bench-full` workflow, run 39062202496 on 2026-10-17.

## Why the runners and not the reference machine

BENCHMARK §1 names a Windows reference machine. package-benchmark supports Linux and macOS only, so
the Swift benchmarks cannot run there. The Swift numbers are therefore GitHub-runner numbers, and
C# NepDate is measured on the same runner by the vendored `Benchmarks/Vendor/dotnet-bench`, so the
ratio compares the two libraries on the same CPU and OS. The reference-machine column is copied
from the hub's `docs/benchmarks/dotnet.md` for context only and is never divided by a runner number.

Both runners are GitHub-hosted shared machines, and the workflow does not control the machine load.
Read p50 and p90 together, and read the ratios as noisy: the same ubuntu job measured B1 at 1.14 on
an earlier run of this workflow and at 1.33 on this one. The earlier run also met the targets.

## Runners

| Item | ubuntu-latest | macos-latest |
|---|---|---|
| Host | GitHub-hosted, shared, load not controlled | GitHub-hosted, shared, load not controlled |
| CPU | AMD EPYC 9V45, 4 vCPU (2 cores, 2 threads each) | Apple M1 (virtual), 3 vCPU |
| OS | Ubuntu 24.04, kernel 6.17.0-1022-azure | macOS 26.6.2 (25G83) |
| Swift | 6.4 | 6.3.3 (swiftlang-6.3.3.1.3) |
| Xcode | not used | 26.6 (17F113) |
| .NET | SDK 10.0.402, runtime 10.0.13 | SDK 10.0.402, runtime 10.0.13 |
| Run date (UTC) | 2026-10-17T19:22:59Z | 2026-10-17T19:23:08Z |
| Job | [ubuntu job](https://github.com/sanamhub/nepdate-swift/actions/runs/39062202496/job/117482288230) | [macos job](https://github.com/sanamhub/nepdate-swift/actions/runs/39062202496/job/117482288124) |

The reference-machine C# numbers in the tables below were measured on 2026-10-09 with .NET 10 on a
12th Gen Intel Core i5-12500H (4 performance + 8 efficiency cores), Windows 11, Ultimate Performance
power plan, pinned to logical CPU 2, with no other jobs.

## How to read the tables

- One benchmark iteration runs all 64 inputs of BENCHMARK §2. package-benchmark's scaling factor is
  a power of 1,000, so `.one` leaves the value per iteration; each ns/op below is that value divided
  by 64.
- p50 and p90 are package-benchmark's percentiles. They are not a mean and a standard deviation.
- `mallocs/op` is `mallocCountTotal` minus the `Baseline` benchmark, divided by 64. The Linux harness
  allocates 16 times per iteration on its own (0.25 per operation), so a 0 in the table means
  NepDate added no allocation.
- The C# column is BenchmarkDotNet's mean with `OperationsPerInvoke = 64`, already per operation.
- "C# reference machine" is the hub's .NET 10 column from a different machine. It is not comparable
  with a runner number and no ratio uses it.

## ubuntu-latest results

Runner: ubuntu-latest, AMD EPYC 9V45, 4 vCPU, shared GitHub runner, machine load not controlled.

| ID | Operation | ubuntu p50 ns/op | ubuntu p90 ns/op | NepDate mallocs/op | C# .NET 10 ns/op, same runner | ratio Swift/C# | C# ns/op, reference machine (i5-12500H) |
|---|---|---:|---:|---:|---:|---:|---:|
| B1 | BS to AD | 13.1 | 13.5 | 0 | 9.9 | 1.33 | 13.29 |
| B2 | AD to BS | 9.4 | 9.7 | 0 | 17.0 | 0.55 | 18.64 |
| B3 | add 1000 days | 8.0 | 8.3 | 0 | 16.5 | 0.48 | 17.50 |
| B4 | add 13 months, clamp | 4.8 | 5.0 | 0 | 13.8 | 0.35 | 18.85 |
| B5 | long format, Nepali, weekday | 296.9 | 312.5 | 1 | 134.5 | 2.21 | 153.02 |
| B6 | strict parse | 34.4 | 36.3 | 0 | 14.5 | 2.37 | 21.55 |
| B7 | patro info | 30.5 | 31.5 | 0 | 30.3 | 1.01 | 47.93 |
| B8 | patro month grid | 1,468.8 | 1,546.9 | 0 | 1,188.4 | 1.24 | 3,132.66 |

B5 allocates the returned string, one per operation. B5a is the same format into a reused buffer:

| Benchmark | ubuntu p50 ns/op | ubuntu p90 ns/op | mallocs/op | What it is |
|---|---:|---:|---:|---|
| B5a | 250.0 | 265.6 | 0 | B5 with `appendLong(to:)` and a warm buffer |
| B7-sorted | 44.5 | 45.5 | 0 | PATRO §3's binary-search layout, for comparison with B7 |
| MonthRange | 65.4 | 68.4 | 0 | one month of `NepaliDateRange` per input |

## macos-latest results

Runner: macos-latest, Apple M1 (virtual), 3 vCPU, shared GitHub runner, machine load not controlled.

| ID | Operation | macos p50 ns/op | macos p90 ns/op | NepDate mallocs/op | C# .NET 10 ns/op, same runner | ratio Swift/C# | C# ns/op, reference machine (i5-12500H) |
|---|---|---:|---:|---:|---:|---:|---:|
| B1 | BS to AD | 20.8 | 56.6 | 0 | 23.6 | 0.88 | 13.29 |
| B2 | AD to BS | 20.2 | 50.1 | 0 | 28.5 | 0.71 | 18.64 |
| B3 | add 1000 days | 14.3 | 44.3 | 0 | 26.2 | 0.55 | 17.50 |
| B4 | add 13 months, clamp | 13.7 | 35.2 | 0 | 15.6 | 0.88 | 18.85 |
| B5 | long format, Nepali, weekday | 390.6 | 937.5 | 1 | 183.2 | 2.13 | 153.02 |
| B6 | strict parse | 52.7 | 137.5 | 0 | 24.4 | 2.16 | 21.55 |
| B7 | patro info | 39.7 | 55.4 | 0 | 46.2 | 0.86 | 47.93 |
| B8 | patro month grid | 1,531.2 | 2,843.8 | 0 | 3,233.6 | 0.47 | 3,132.66 |

The macOS p90 is much wider than p50 (B6: 52.7 against 137.5). The runner is a 3-vCPU virtual M1, so
the last decile includes scheduler jitter that p50 does not.

| Benchmark | macos p50 ns/op | macos p90 ns/op | mallocs/op | What it is |
|---|---:|---:|---:|---|
| B5a | 296.9 | 734.4 | 0 | B5 with `appendLong(to:)` and a warm buffer |
| B7-sorted | 100.9 | 264.5 | 0 | PATRO §3's binary-search layout, for comparison with B7 |
| MonthRange | 79.4 | 214.2 | 0 | one month of `NepaliDateRange` per input |

## Competitors

B1 and B2 over the same 64 dates, run by the `CompetitorBenchmarks` target. The "agrees" columns come
from `Benchmarks/Tests/CompetitorAgreementTests`, which rebuilds the 64 dates from
`shared/data/calendar/bs-calendar.json` and Hinnant's arithmetic without calling NepDate.

| Library | Runner and load | B1 ns/op | B1 agrees | B2 ns/op | B2 agrees | mallocs/op (B1 / B2) |
|---|---|---:|---|---:|---|---|
| nrlnishan/NepaliDateConverter | ubuntu-latest, EPYC 9V45, shared | 718.8 | no, 62 of 64 | 4,828.1 | no, 59 of 64 | 1.25 / 2.25 |
| nrlnishan/NepaliDateConverter | macos-latest, M1, shared | 1,687.5 | no, 62 of 64 | 17,015.6 | no, 59 of 64 | 2 / 3 |
| shivathapaa/Nepali-Date-Picker-SPM | ubuntu-latest, EPYC 9V45, shared | not run: the XCFramework has an arm64 macOS slice only | | | | |
| shivathapaa/Nepali-Date-Picker-SPM | macos-latest, M1, shared | 921.9 | no, 61 of 64 | 1,015.6 | no, 61 of 64 | 2 / 2 |

Neither competitor is ranked above this package. Both are slower on B1 and B2 and both disagree with
`shared/data` on some dates:

- nrlnishan's month table differs from `shared/data` in BS 2062 and 2081 to 2089. B1 misses BS
  2088-01-04 and 2089-06-10 by one day. B2 misses five dates: three land on a month boundary and get
  day 32 or 33 from its strict `>` comparison, and the other two are the same one-day shift.
- shivathapaa differs from `shared/data` by one day at BS 2086-07-23, 2088-01-04 and 2089-06-10, in
  both directions.

## Size

`Examples` built with `swift build -c release`, stripped, arm64, on macos-latest with Swift 6.3.3.
The baseline executable links neither product, so the deltas are what each product adds.

| Binary | Stripped bytes | Delta from baseline | Target (ADR-0002 §7) | Result |
|---|---:|---:|---|---|
| baseline | 51,320 | 0 | none | |
| core-only | 142,552 | 91,232 | less than 100 KB | pass |
| with-patro | 276,952 | 225,632 | less than 200 KB | **miss by 20,832 bytes** |

The miss holds under either reading of KB: 225,632 is above 200,000 and above 204,800. The patro
product adds the dense day tables, the event tables and the 753-case name `switch` with its string
literals, which is more than ADR-0002's estimate of 120 to 170 KB. No optimisation was attempted
after the measurement; the number is reported as measured.

## Targets

ADR-0002 §7: B1, B2 and B7 within 1.5 times C# on the same runner, zero mallocs for B1 to B4, B5a,
B6 to B8, and one malloc for B5.

| Target | ubuntu-latest (shared EPYC 9V45) | macos-latest (shared M1) | Result |
|---|---|---|---|
| B1 at most 1.5 times C# | 1.33 | 0.88 | pass |
| B2 at most 1.5 times C# | 0.55 | 0.71 | pass |
| B7 at most 1.5 times C# | 1.01 | 0.86 | pass |
| 0 mallocs, B1 to B4, B6 to B8 | 0 | 0 | pass |
| 1 malloc, B5 | 1 | 1 | pass |
| `core-only` under 100 KB | 91,232 bytes | | pass |
| `with-patro` under 200 KB | 225,632 bytes | | miss, reported above |

The `bench` job in `ci.yml` checks the malloc thresholds on every pull request. The times are printed
there but not gated, because shared runners are noisy.

## Reproduce

```
gh workflow run bench-full.yml
```

or the same steps by hand: `swift package --package-path Benchmarks benchmark --target
NepDateBenchmarks --format histogramPercentiles`, then the same with `--target CompetitorBenchmarks`,
then `dotnet run -c Release -f net10.0 --project Benchmarks/Vendor/dotnet-bench -- --filter "*"`, then
`python3 Benchmarks/scripts/ratio.py`, then `swift test --package-path Benchmarks`.
