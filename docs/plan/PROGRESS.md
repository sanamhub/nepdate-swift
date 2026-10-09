# Progress (Swift port)

Tasks from [`00-ROADMAP.md`](00-ROADMAP.md), in the format of the hub's `docs/handover.md` §3 step 7.
There is no Swift toolchain on the maintainer's Windows machine, so "CI last line" is the last line
of `scripts/ci.sh` in the green GitHub Actions run named in the row (macOS, Linux and Windows jobs).

| Task | Status | Commit | CI last line | Notes and open questions |
|---|---|---|---|---|
| S0-01 | done | ac075d7 | `ci: 7/7 gates passed` | `.swift-format` lists only `lineLength` and the two extra rules; swift-format fills in the other defaults (2-space indent). |
| S0-02 | done | 61d8034 | `ci: 7/7 gates passed` | AC1 and AC2 run as a step of the `linux` job (two runs give the same SHA-256; a trailing space makes `--check` exit 1 at line 8). The generated enum is written on four lines instead of one. |
| S0-03 | done | a86802f | `ci: 7/7 gates passed` | AC1 runs as a step of the `linux` (ci.sh) and `windows` (ci.ps1) jobs with a new unformatted file in `Sources/NepDate/`: the generated file is `swift-format-ignore-file`, so it can't be the test file. `ci.ps1` runs plain `swift test` (no coverage on Windows). `coverage-check` passes when no hand-written file exists yet, because llvm-cov omits a file of constants; it fails if a hand-written source is missing from the report. |
| S0-04 | partial | a6ee8d8 | `ci: 7/7 gates passed` | Green run: https://github.com/sanamhub/nepdate-swift/actions/runs/37957224130. Missing: the `shared-check` job and `shared-sync.yml`, blocked on hub H3 (reusable workflows) and on the human creating `sanamhub/nepdate` on GitHub. Human: branch protection on `main` and the `production` environment. macOS `latest-stable` Xcode currently gives Swift 6.3.3; Linux and Windows use 6.4.0. |
| S0 checkpoint | ready for review | fc58067 | `ci: 7/7 gates passed` (run 37957224130, all three OS jobs) | S0-04 partial as above. No C# catalogue rows in S0. |
| S0 light check | ok | | | Deviations approved by the lead agent. S0-04 shared-check and shared-sync stay blocked until `sanamhub/nepdate` has a GitHub remote. |
