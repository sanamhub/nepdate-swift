# S7: Binary size follow-ups

Read first: ADR-0002 §7, the size results in [`S6-perf.md`](S6-perf.md), the size section of
[`docs/benchmarks.md`](../benchmarks.md), ADR-0005 (ADRs are immutable), and the CI jobs in
[`.github/workflows/ci.yml`](../../.github/workflows/ci.yml).

Precondition: S6 merged on `main` (7d7d00d). S6 measured `core-only` at 159,480 bytes, +108,160
over the baseline and 16,928 over the S5 base (c061506, 142,552), and `with-patro` at 277,352
bytes, +226,032. Both are over their ADR-0002 §7 targets.

## Rules

- One task per commit.
- A size number counts only from `perf-size`, which builds `main` and the branch in one run and
  strips both. A speed number counts only from `perf-compare`, which alternates `main` and the
  branch five times per side, with C# on the same runner.
- ADR-0002 is not edited. The new targets live in ADR-0006, which says what it amends.

## Tasks

### S7-01 One-pass canonical parser

Rewrite `parseCanonical` as a single pass over the bytes: a `for` loop with a position counter that
rejects an 11th byte, digits at 0 to 3, 5 to 6 and 8 to 9, a strict separator at 4 and 7, then
`NepaliDate(year:month:day:)`. The shape, the constructor and the error order stay the same, and
everything else still falls back to `parseSlow`.

Tests: the existing exhaustive differential and `FuzzParseCanonical` stay green, and the
year-hundreds negative control is repeated on a throwaway branch.

Keep it only if one `perf-size` run and one `perf-compare` run against `main` show both:

- `core-only` at most 146,552 bytes, which is 4 KB over the S5 base c061506 (142,552);
- B6 p50 at most 1.10 times the current fast path on both runners.

Otherwise revert it and record both measurements here: the size and the B6 old/new table.

AC1: the exhaustive differential and the fuzz target are green.
AC2: the negative control fails both, or, if the rewrite is reverted, the control is run on the
code that remains.
AC3: this file records the decision and both measurements.
AC4: CI ends with `ci: 8/8 gates passed`.

### S7-02 ADR-0006 Binary size targets

`docs/adr/0006-binary-size-targets.md`, an accepted ADR that amends ADR-0002 §7 without editing it:

- `with-patro` minus baseline < 250 KB (256,000 bytes). The S6 breakdown is the reason: the delta
  is data, 65,872 bytes of bilingual names, 14,760 of day tables and a 36,024-byte name switch, and
  options A and B are rejected (A splits the product API; B allocates and breaks zero-malloc).
- `core-only` < 100 KB (102,400 bytes) if S7-01 lands under it, otherwise < 120 KB (122,880 bytes)
  with the measured cost named.
- Yearly growth: the patro delta is 226,032 bytes over 8 data years, about 28,254 bytes per data
  year; a new data year is budgeted at about 28 KB.
- Next review: the 0.2.0 release, or when a data year is added, whichever comes first.

AC: the ADR is accepted, links ADR-0002, names the numbers, the per-year growth and the review
point; the docs gate is green.

### S7-03 Size gate

- `Benchmarks/size-targets.json` holds the byte limits; the gate reads it, so no number is written
  in a workflow file.
- `Benchmarks/scripts/size-gate.py` reads the targets and the three stripped binaries, prints one
  line per product with the measured number and the limit, and exits 1 above a limit.
- The `macos` job in `ci.yml` (pull requests and `main`) builds `Examples` in release, strips the
  three binaries and runs the gate. `permissions: contents: read`, actions pinned by SHA, no
  secrets.
- Drop the `|| true` from the measurement steps the gate depends on, so a tool failure cannot pass
  as a size.
- Negative control on a throwaway PR, closed afterwards: lower the target below the current size
  and show the macOS job fails with the gate's error line.

AC1: the gate passes on the current tree.
AC2: the throwaway PR's macOS job fails with the gate's line for the lowered target.
AC3: the limits live in one checked-in file, not in YAML.

### S7-04 Docs

- `docs/benchmarks.md` size section points at ADR-0006 and the gate, and records any S7-01 change.
- `docs/plan/PROGRESS.md` rows for S7.
- `CHANGELOG.md` `[Unreleased]` only if the change is user-visible. The parser rewrite is internal
  and the size gate and ADR are repository tooling, so a line is expected only if S7-01 changes a
  public behaviour, which it must not.

AC: the docs gate is green and links resolve.

## Checkpoint

The agent stops here. The reviewer checks:

- [ ] S7-01 is kept or reverted, with both measurements recorded.
- [ ] ADR-0006 states both targets, the per-year growth and the review point, and leaves ADR-0002
  unedited.
- [ ] The gate passes on the current tree and fails on a lowered target; the limits are in one
  file.
- [ ] `docs/benchmarks.md` and `docs/plan/PROGRESS.md` are updated.
- [ ] CI green, with the `ci:` line per OS.
- [ ] No tags, releases, registry submissions or settings changes.

## Doubts

- The 4 KB and 10 % limits decide S7-01. A one-pass loop may cost more than 10 % of B6, and then it
  is reverted even if it saves size.
- The gate runs on macOS arm64 only. Linux and Windows builds have different sizes and are not
  gated.
- ADR-0002 stays unedited as an immutable record; ADR-0006 has to say clearly that it supersedes
  §7's two size rows.
