# Contributing

Bug reports, fixes and documentation improvements are welcome. For a new feature or an API change,
open an issue first so the design can be agreed before you write code.

## Scope

This is the Swift port of the NepDate family. Calendar data and behaviour come from the hub,
[`sanamhub/nepdate`](https://github.com/sanamhub/nepdate), and are copied read-only into
`shared/`. A wrong month length, holiday or tithi is a hub issue, not a fix here. Never edit
`shared/` or a `*.generated.swift` file by hand: change `Tools/Codegen` and run it.

## Setup

You need Swift 6.0 or later. Check the repository out into a folder named `nepdate-swift`: the
`Examples` package depends on it by path, and SwiftPM takes a path dependency's identity from the
folder name.

Run the checks before opening a pull request:

```bash
./scripts/ci.sh          # macOS, Linux
pwsh ./scripts/ci.ps1    # Windows
```

The last line reads `ci: 8/8 gates passed`. The README quick start must stay byte for byte equal
to the `Examples` programs; `readme-check` fails otherwise.

## Rules for the library

- No package dependencies in the library products. Tools, benchmarks, fuzz targets and examples
  live in their own packages.
- `NepDate` never imports or contains anything from `NepDatePatro`. An app that only converts
  dates must not link the patro data.
- No public symbol beyond [docs/API.md](docs/API.md). An API change updates that file in the same
  pull request.
- Swift 6 language mode, every public type `Sendable`, no global mutable state, no
  `@unchecked Sendable`, and no unsafe pointers in `Sources/`.
- No heap allocation in conversion, arithmetic, parsing or patro lookups. The `bench` job fails on
  a new allocation (ADR-0002).
- The core never imports Foundation unconditionally. `Date` interop sits behind
  `#if canImport(Foundation)`.
- No `fatalError`, `precondition` or force unwrap on a path reachable from the public API.
- A parity test may skip a C# row only for a deviation listed in `shared/spec/PARITY.md`, with a
  comment naming it.

## Pull requests

- One change per pull request, with tests for any behaviour change.
- Add a line to `[Unreleased]` in [CHANGELOG.md](CHANGELOG.md) for anything a user would notice.
- A significant design decision gets an ADR in [docs/adr/](docs/adr/README.md). Accepted ADRs are
  not edited; a later one supersedes them.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):
  `fix(parse): reject a day of 00`.

By contributing you agree that your contribution is licensed under the MIT license
([LICENSE](LICENSE)).
