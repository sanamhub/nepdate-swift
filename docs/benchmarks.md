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

## B6 fast path, same-run before and after

The B6 row in the tables above is from the previous full run. The strict parser gained a
canonical-shape fast path: exactly 10 ASCII bytes with digits at 0 to 3, 5 to 6 and 8 to 9 and a
strict separator at 4 and 7, with the general loop as the fallback. This run measures `main`
(c061506, old) and the change (new) in one job, alternating old and new five times each, with the
C# baseline on the same runner:
https://github.com/sanamhub/nepdate-swift/actions/runs/39070430969

| Runner and load | old p50 ns/op | new p50 ns/op | change | old p90 | new p90 | C# same runner ns/op | old/C# | new/C# |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| ubuntu-latest, AMD EPYC 7763, 4 vCPU, shared | 63.3 | 31.6 | -50.0 % | 63.5 | 32.1 | 28.2 | 2.25 | 1.12 |
| macos-latest, Apple M1 virtual, 3 vCPU, shared | 56.6 | 32.5 | -42.5 % | 72.9 | 39.1 | 24.6 | 2.30 | 1.32 |

Both sides allocate 0. The quiet full run before a release replaces the B6 row above with the new
number.

## B5 allocation

B5 returns a new `String`, so one allocation per operation is the design. A valgrind memcheck run of
1,000 calls of `long(weekday: true, lang: .nepali)` recorded exactly 1,000 mallocs of 96 bytes, one
per call; the result is 59 UTF-8 bytes. The allocating form is 93.7 ns/op slower than B5a on both
runners in the same run (531.2 against 437.5 on ubuntu, 390.6 against 296.9 on macOS), which covers
the allocation, the byte-counting first pass and the `String` return. A hot loop uses
`appendLong(to:)`, which is B5a and allocates 0.

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
The baseline executable links neither product, so the deltas are what each product adds. The targets
are ADR-0006, which replaces ADR-0002 §7's two size rows; the limits are in
`Benchmarks/size-targets.json` and the macOS CI job checks them on every pull request and on `main`.

| Binary | Stripped bytes | Delta from baseline | Target (ADR-0006) | Result |
|---|---:|---:|---|---|
| baseline | 51,320 | 0 | none | |
| core-only | 159,480 | 108,160 | less than 120 KB (122,880 B) | pass |
| with-patro | 277,352 | 226,032 | less than 250 KB (256,000 B) | pass |

The patro product adds 117,872 bytes over `core-only`: 65,872 of bilingual name literals, 14,760 of
day tables and 36,024 of the name switch. S5 measured 142,552 and 276,952 against the old 100 KB and
200 KB targets; the parser fast path added 16,928 bytes to `core-only` and almost nothing to
`with-patro`, which dead-strips it. The section and symbol breakdown, the two rejected options and
the one data year of headroom are in [`plan/S6-perf.md`](plan/S6-perf.md) and
[`adr/0006-binary-size-targets.md`](adr/0006-binary-size-targets.md).

S7 tried a one-pass parser that met the size target (`core-only` 143,000, delta 91,680) but cost
46 % of B6 on ubuntu and 28 % on macOS, so it was reverted; see
[`plan/S7-size.md`](plan/S7-size.md).

## Targets

ADR-0002 §7 for the times and mallocs, ADR-0006 for the two size rows: B1, B2 and B7 within 1.5
times C# on the same runner, zero mallocs for B1 to B4, B5a, B6 to B8, and one malloc for B5.

| Target | ubuntu-latest (shared EPYC 9V45) | macos-latest (shared M1) | Result |
|---|---|---|---|
| B1 at most 1.5 times C# | 1.33 | 0.88 | pass |
| B2 at most 1.5 times C# | 0.55 | 0.71 | pass |
| B7 at most 1.5 times C# | 1.01 | 0.86 | pass |
| 0 mallocs, B1 to B4, B6 to B8 | 0 | 0 | pass |
| 1 malloc, B5 | 1 | 1 | pass |
| `core-only` under 120 KB (ADR-0006) | 108,160 bytes | | pass |
| `with-patro` under 250 KB (ADR-0006) | 226,032 bytes | | pass |

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
