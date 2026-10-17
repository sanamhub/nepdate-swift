# Benchmarks

Numbers for B1 to B8 of [`shared/spec/BENCHMARK.md`](../shared/spec/BENCHMARK.md), measured by the
`bench-full` workflow on GitHub runners. The tables are filled from that run.

Why the runners and not the reference machine: BENCHMARK §1 names a Windows machine, and
package-benchmark has no Windows support, so the Swift numbers can never share a column with the
reference-machine C# numbers. The comparison is a ratio against C# NepDate measured on the same
runner.
