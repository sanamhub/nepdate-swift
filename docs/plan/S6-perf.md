# S6: Performance follow-ups

Read first: ADR-0002 §5 to §7, `shared/spec/BENCHMARK.md` §3 and §4, `docs/benchmarks.md`, the Go
port's `docs/plan/G7-b6-fast-path.md`, and `docs/plan/S5-docs-bench-release.md`.

Precondition: S5 merged on `main` (c061506). Three S5 results drive this phase: B6 is 2.2 to 2.4
times C# on the same runner, B5 carries the one allocation the API allows, and `with-patro` is
225,632 bytes over the baseline, 20,832 over the ADR target.

## Rules for this phase

- One task per commit.
- A performance number counts only from one workflow run that measures the old and the new code
  interleaved (A B A B), on the same runner, with C# measured on that runner too.
- `Benchmarks/Thresholds` stays as it is. A threshold changes only when a measured number improves;
  no time threshold exists to tighten.

## Tasks

### S6-01 Interleaved old against new

`.github/workflows/perf-compare.yml` (`workflow_dispatch`, inputs `base` default `main`, `filter`
default `^B6$`, `rounds` default 5):

- checks the dispatch ref out, adds a git worktree of `base` next to it, and builds both packages;
- for each round, runs `base`, then `head`, then repeats, exporting
  `histogramPercentiles` into a per-round directory on `ubuntu-latest` and `macos-latest`;
- runs `Benchmarks/Vendor/dotnet-bench` for the same operation on the same runner;
- `Benchmarks/scripts/ab.py` takes the median p50 over the rounds for each side, divides by 64
  operations, and prints the base/new table with each side's ratio to the same-run C# number;
- uploads the raw per-round files and the table.

AC1: one run gives base and head p50/p90 ns/op for B5 and B6 on both runners, and the ratio of each
to the same-run C# number.
AC2: the benchmark steps alternate base and head each round, and the raw per-round files are in the
run artifact.
AC3: the workflow prints both refs and commit SHAs, and the base worktree is clean.

### S6-02 B6 canonical fast path

Split the strict parser into three internal pieces: `parseCanonical`, `parseSlow` (today's loop, kept
as the reference), and `parse`, which tries the canonical shape and falls back to `parseSlow`.
Canonical means exactly 10 UTF-8 bytes, ASCII digits at positions 0 to 3, 5 to 6 and 8 to 9, and a
strict separator at 4 and 7. It builds year, month and day with digit arithmetic and calls
`NepaliDate(year:month:day:)`, so the range, month and day checks and their error order stay in the
shared path. `parseLenient` already tries `parse` first, so it gets the fast path too.

Tests, written before the numbers count:

- exhaustive differential: all 109,212 serials, each formatted with each of the 8 strict separators
  (`-`, `/`, `.`, `_`, `\`, space, `|`, `।`), comparing date, error kind and error value with
  `parseSlow`. The danda is 3 bytes, so it exercises the fallback rather than the fast path.
- `FuzzParseCanonical` in `Fuzz/`, a differential over arbitrary input comparing result, error kind
  and error, and requiring a canonical-shaped input to get the same answer as the reference.
- negative control: break one digit check, show the exhaustive test and the fuzz seeds fail, revert.

AC1: the exhaustive differential passes.
AC2: the fuzz target runs clean in the `fuzz` job.
AC3: the negative control fails both tests.
AC4: the interleaved B6 median gain is at least 30 % with 0 mallocs. Below 30 %, revert and report
the numbers.
AC5: `CHANGELOG.md` has an `[Unreleased]` line if the change lands; CI ends with
`ci: 8/8 gates passed`.

### S6-03 B5: the one malloc

- Locate the allocation with package-benchmark's `--allocation-stacks` on `ubuntu-latest` and
  `macos-latest`, filtered to B5, and record the stack, the count and the bytes.
- Measure its cost in the same run as B5 minus B5a, which formats the same text into a warm buffer.
- Change code only if every text column of `shared/spec/vectors/dates.tsv` stays byte-identical.
  Otherwise report the site, the bytes and the cost, and leave the code alone.

AC1: the allocation site, count and bytes are named, with the run link.
AC2: the cost share is reported from the same run.
AC3: any change keeps all 1,018 golden rows and the 451 `format-pattern.tsv` rows passing unchanged.

### S6-04 Size breakdown and two options

- Add `Benchmarks/scripts/size-breakdown.py` and a macOS step that runs `size -m`, `otool -l` and
  `nm -S` on the stripped `core-only` and `with-patro` binaries, then attributes the 225,632-byte
  delta to sections and to symbol groups (patro tables, the name `switch` and its literals, Swift
  metadata, the rest).
- Add the measured options and their expected savings to this file before any implementation.

AC1: the section table accounts for the delta, with any unexplained remainder stated.
AC2: two options, each with an expected saving, a risk and the files it touches.
AC3: no production code for the size options is written in S6; the reviewer picks first.

### S6-05 Docs and thresholds

- `docs/benchmarks.md` gains the B6 before/after table from the interleaved run, with the same-run
  C# ratio, and the B5 allocation finding.
- `CHANGELOG.md` `[Unreleased]` for S6-02 and for any S6-03 change.
- Thresholds: no change unless a measured malloc count improves. B6 stays at 0, B5 at 1.

AC: docs gate green, no threshold lowered, `ci: 8/8 gates passed`.

## Size breakdown and options (S6-04)

Measured on macos-latest, arm64, `swift build -c release`, stripped, by `perf-size` run 39069711434.
The unstripped copies gave the symbol sizes; Apple's `nm -S` reports zero sizes for Mach-O, so a
text symbol's size is the distance to the next text symbol.

| Item | Baseline to with-patro |
|---|---:|
| file size | +226,032 bytes |

| Section | Delta from baseline | Share |
|---|---:|---:|
| `__TEXT.__text` | +92,880 | 41 % |
| `__TEXT.__cstring` | +66,169 | 29 % |
| `__DATA.__data` | +45,072 | 20 % |
| `__DATA.__bss` (zerofill, not in the file) | +7,048 | 3 % |
| `__TEXT.__const` | +5,934 | 3 % |
| `__DATA_CONST.__const` | +4,560 | 2 % |
| Swift metadata, stubs, unwind | +3,550 | 2 % |
| section sum | +229,877 | |
| file delta minus section sum (page rounding, load commands) | -3,845 | |

The patro product alone, against `core-only`, is +117,872 bytes:

| Part | Bytes | What it is |
|---|---:|---|
| `__TEXT.__cstring` | +65,872 | the 753 bilingual names, 62,812 bytes of string content |
| `__TEXT.__text` | +41,964 | `PatroData.name` is 36,024 of it; the rest is `calendarInfo`, the tables' accessors and collection conformances |
| `__DATA.__data` | +14,760 | `dayInfo` 2,793, `dayEventStart` 5,588, `eventNameIDs` 6,064, plus alignment |
| metadata and rounding | -4,724 | |
| **total** | **+117,872** | |

The core product accounts for the other +108,160 bytes: 50,916 of text, 30,312 of tables, and the
rest metadata and runtime stubs.

Two options, not implemented. The reviewer picks one or the fallback.

### Option A: per-year patro modules

Split the day tables and the name switch by BS year (2077 to 2084), and let a product link only the
years it needs. A consumer that shows one year links about 1/8 of the names, tables and switch
instead of all of them.

- Expected saving for a one-year consumer: about 100 KB, or 7/8 of the patro delta
  (0.875 × 117,872 = 103,138), which puts that consumer near 123 KB. A consumer that needs every
  year saves nothing.
- Risk: new products and a changed API, because `Patro.coverage` and `Patro.publicHolidays` span the
  whole range; the release then carries several products at one tag (ADR-0005 allows it, but the
  Swift Package Index page and the README grow).

### Option B: a static name table instead of the 753-case switch

Replace `PatroData.name`'s switch (36,024 bytes of text) with a 753-entry table of offsets into one
packed string blob and a small lookup. Share the repeated English words the data shows (`Day` 179
times, `Brata` 77, `International` 59) to shorten the blob.

- Expected saving: about 29 KB of text (36,024 minus roughly 6 KB of table and 1 KB of lookup), and
  about 6 KB of the 65,872-byte string section if the word sharing gives 10 %. The delta would fall
  from 226,032 to about 191 KB, under the 200 KB target.
- Risk: a `[String]` table is built on first access, one allocation that ADR-0002 §3 and B7's
  zero-malloc rule forbid for patro lookups; a byte blob allocates a `String` on every read; a
  statically initialised table needs `@section` and the OS 26 runtime, above the iOS 15 floor.
  The table alone (29 KB) would leave 197 KB, only 3 KB under 200,000.

### Fallback

Keep the code and raise the ADR-0002 §7 `with-patro` target from 200 KB to 250 KB, with this
breakdown as the reason. No code change.

## Checkpoint

The agent stops here. The reviewer checks:

- [ ] The interleaved run and the before/after table, with the same-run C# ratios.
- [ ] The exhaustive differential and the fuzz target; the negative control failed both.
- [ ] B5's malloc site and cost; any change is byte-identical on the golden vectors.
- [ ] The size breakdown accounts for 225,632 bytes and the two options are costed.
- [ ] Thresholds unchanged except for measured improvements.
- [ ] CI green, with the `ci:` line per OS.

## Doubts

- The 30 % B6 landing threshold follows the Go G7 plan. The request asked for the fast path without
  a number; 30 % is the precedent, not a requirement.
- The danda `।` is 3 bytes, so no 10-byte canonical input can contain it. It is in the exhaustive set
  to prove the fallback, not the fast path.
- `--allocation-stacks` needs the Swift Runtime module: Linux with Swift 6.4, macOS 26. The macOS
  runner is 26.6, so both should work. If one does not, the other is the evidence.
- The size options are written after the breakdown, in S6-04, and are not implemented in this phase.
