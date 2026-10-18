# ADR-0006: Binary size targets

- Status: Accepted
- Date: 2026-10-18
- Deciders: Sanam Pakuwal

## Context

ADR-0002 §7 set two size targets: `with-patro` minus baseline < 200 KB, and `core-only` minus
baseline < 100 KB, both on a stripped arm64 release build. S5 measured 225,632 and 91,232 bytes. S6
added the B6 canonical fast path and measured 226,032 and 108,160. Both are over the ADR-0002
numbers.

ADR-0002 is Accepted and immutable, so its text stays as written. This ADR replaces the two size
rows of §7 and leaves the rest of ADR-0002 in force.

The S6 breakdown of the `with-patro` delta (`docs/plan/S6-perf.md`) shows that most of it is data:

| Part | Bytes |
|---|---:|
| bilingual name literals (`__TEXT.__cstring`) | 65,872 |
| day tables (`__DATA.__data`) | 14,760 |
| name `switch` (`__TEXT.__text`) | 36,024 |
| the core product and patro metadata | 108,160 and about 1,200 |
| **total** | **226,032** |

S6-04 considered two ways to get under 200 KB and rejected both:

- **Per-year patro modules** would let a one-year consumer link about 1/8 of the patro data, an
  expected saving near 100 KB, but it splits `Patro.coverage` and `Patro.publicHolidays` across
  products and changes the API and the release surface.
- **A static name table with word sharing** would save about 35 KB, but an array of `String` values
  is built on first access (one allocation, against ADR-0002 §3 and B7's zero-malloc rule), a byte
  blob allocates on every read, and a statically initialised table needs `@section` and the OS 26
  runtime, above the iOS 15 floor.

S7-01 rewrote the parser as one pass and met the size goal (`core-only` 143,000, delta 91,680, under
100 KB), but cost 46 % of B6 on ubuntu and 28 % on macOS, so it was reverted. The parser's size cost
stays.

## Decision

- **`with-patro` minus baseline < 250 KB (256,000 bytes).** The measured delta is 226,032, so the
  target leaves 29,968 bytes, about one more data year.
- **`core-only` minus baseline < 120 KB (122,880 bytes).** The measured delta is 108,160, so the
  target leaves 14,720 bytes. If a later change brings the delta under 100 KB (102,400) without
  losing B6, the target tightens back to 100 KB in a new ADR.
- **Yearly growth:** the patro delta is 226,032 bytes over 8 data years, 28,254 bytes per data year.
  A ninth year is expected to add about 28 KB, for about 254 KB, inside 256,000. A second new year
  needs a new target.
- **Measurement:** macOS arm64, `swift build -c release`, stripped, against the baseline executable.
  The gate is the `size` step in `ci.yml`, with the limits in `Benchmarks/size-targets.json`.
- **Next review:** the 0.2.0 release, or when a data year is added, whichever comes first.

## Consequences

- A pull request that grows either product past its target fails the macOS CI job.
- The 250 KB target covers one data year; the next one forces the review.
- ADR-0002 §7's two size rows are superseded by this ADR. Its other targets (times, mallocs, first
  access, widget memory) are unchanged.

Sources: `docs/plan/S6-perf.md`, `docs/benchmarks.md`, S6 size runs 39071859134 and 39069711434,
S7-01 runs 39088610867 and 39088618338.
