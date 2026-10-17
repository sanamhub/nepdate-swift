# Vendored: hub `tools/dotnet-bench`

Copied from `sanamhub/nepdate` at commit `1d7ca17`, the commit in `shared/VERSION`, so the C#
NepDate baseline runs on the same GitHub runner as the Swift benchmarks. The hub measures the
NepDate 2.0.7 NuGet package, which is what this project benchmarks too.

The hub repository is not on GitHub yet, so the `bench-full` workflow cannot check it out. When
`sanamhub/nepdate` is public, delete this folder and check the hub out at `shared/VERSION` instead.

Changes from the hub copy:

- `TargetFrameworks` is `net10.0` only. The hub project also runs .NET 8; the runners install .NET
  10 and the published column is the .NET 10 one.
- The affinity job is applied only on Linux. macOS has no process affinity, and BENCHMARK §1's
  reference-machine pin does not apply to a shared runner anyway.
- The embedded `bs-calendar.json` path points at this repository's `shared/data/calendar/`.

The licence is the hub's MIT licence; see the repository `LICENSE`.
