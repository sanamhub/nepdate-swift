```

BenchmarkDotNet v0.15.8, Linux Ubuntu 24.04.5 LTS (Noble Numbat)
AMD EPYC 9V74 2.87GHz, 1 CPU, 4 logical and 2 physical cores
.NET SDK 10.0.403
  [Host]     : .NET 10.0.14 (10.0.14, 10.0.1426.52326), X64 RyuJIT x86-64-v3
  Job-LCMCON : .NET 10.0.14 (10.0.14, 10.0.1426.52326), X64 RyuJIT x86-64-v3

Affinity=0100  Runtime=.NET 10.0  

```
| Method                            | Mean        | Error     | StdDev    | Gen0   | Allocated |
|---------------------------------- |------------:|----------:|----------:|-------:|----------:|
| &#39;B1 BS to AD&#39;                     |    19.20 ns |  0.025 ns |  0.019 ns |      - |         - |
| &#39;B2 AD to BS&#39;                     |    31.84 ns |  0.134 ns |  0.112 ns |      - |         - |
| &#39;B3 add 1000 days&#39;                |    29.85 ns |  0.073 ns |  0.057 ns |      - |         - |
| &#39;B4 add 13 months, Clamp&#39;         |    24.24 ns |  0.031 ns |  0.026 ns |      - |         - |
| &#39;B5 long format, Nepali, weekday&#39; |   248.91 ns |  4.354 ns |  7.739 ns | 0.0257 |     435 B |
| &#39;B6 strict parse&#39;                 |    26.29 ns |  0.058 ns |  0.054 ns |      - |         - |
| &#39;B7 patro info&#39;                   |    70.85 ns |  1.358 ns |  1.510 ns | 0.0029 |      51 B |
| &#39;B8 patro month grid&#39;             | 2,335.11 ns | 24.362 ns | 19.020 ns | 0.0610 |    1429 B |
