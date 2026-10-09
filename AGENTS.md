# AGENTS.md: rules for AI coding agents (Swift port)

You are implementing a planned project. Follow the plan; don't redesign it.

## 0. Before writing any code

1. Read `README.md`, this file, every ADR in `docs/adr/`, and `docs/API.md`.
2. Open `docs/plan/00-ROADMAP.md`, find your phase, read that phase file and the spec sections it
   lists under "Read first". Check its preconditions; if one is unmet, stop and say so.

## 1. Sources of truth (in priority order)

1. `shared/spec/*.md` + `shared/spec/vectors/*`: behaviour. Vectors win over prose (report the
   disagreement).
2. `docs/adr/*`: decisions. 3. `docs/plan/*`: tasks and acceptance criteria. 4. `docs/API.md`: the
   public surface.

`shared/` is a read-only copy of the hub. **Never edit it.** A data or spec problem is reported to
the human as a hub issue. Never use the C# NepDate docs as a source (`shared/spec/PARITY.md` §1).
Never use `Calendar(identifier: .vikram)` for anything.

## 2. Hard rules

- No package dependencies in `Package.swift` for the library products. Dev tools, examples,
  benchmarks and fuzz targets live in separate packages (`Tools/Codegen`, `Examples`,
  `Benchmarks`, `Fuzz`).
- The `NepDate` target never depends on, imports or contains anything from `NepDatePatro`
  (hub ADR-0004). Tithi, holiday and event data and strings live only in `Sources/NepDatePatro/`.
- No `public` symbol beyond `docs/API.md`.
- Swift 6 language mode, complete concurrency checking, every public type `Sendable`, no global
  mutable state, no `@unchecked Sendable`, no `unsafe` pointers in `Sources/` (the libFuzzer entry
  point in `Fuzz/` receives a raw pointer and is the one exception).
- Performance rules (ADR-0002): no heap allocation in conversion, arithmetic, parsing or patro
  lookups (the `Benchmarks` malloc thresholds fail CI otherwise); tables are generated `static let`
  arrays of integer literals and name strings come from generated `switch` statements; no
  `Character` iteration in hot paths; `&+`, `&-`, `&*` only below a range check that proves the
  result fits, with a comment naming it; hot public API `@inlinable`, helpers
  `@usableFromInline`; no `@frozen`; no `Calendar`, `DateFormatter` or `NumberFormatter`.
- The core never imports Foundation unconditionally; `Date` interop is behind
  `#if canImport(Foundation)`.
- No `fatalError`, `precondition` or force unwrap in library paths reachable from public API.
- Don't edit `*.generated.swift` by hand. Change `Tools/Codegen` and run it.
- Parity tests may skip rows **only** for deviations in `shared/spec/PARITY.md`, with a comment naming
  the D-ID. Don't weaken or delete a test to make CI pass.
- No features outside the plan. Secrets never go in code, logs or commits.

## 3. How to work

- One task ID at a time (`S1-03`). Test first, see it fail, then implement.
- Run `./scripts/ci.sh` (or `./scripts/ci.ps1` on Windows) before saying you're done; paste its last
  line in the PR.
- C# catalogue rows (`docs/plan/00-ROADMAP.md`, "C# test catalogue") are tests named after the
  row id, for example `@Test("NepaliDateComparableTests.CompareTo_SameDate_ReturnsZero")`.
- At the end of every phase, stop. Post the phase file's "Checkpoint" list with each item ticked
  or explained, and wait for the human's review before starting the next phase.
- PR description: task IDs, what changed and why, how tested, "What to look at first" (2–3 bullets).

## 4. Writing

All prose follows [`.claude/skills/writing-style/SKILL.md`](.claude/skills/writing-style/SKILL.md),
for every agent. DocC comments on every public symbol: summary, `- Returns:`, `- Throws:`.
**No AI attribution** in commits or PRs.
