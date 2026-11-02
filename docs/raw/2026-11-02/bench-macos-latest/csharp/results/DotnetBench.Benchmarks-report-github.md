```

BenchmarkDotNet v0.15.8, macOS Tahoe 26.6.2 (25G83) [Darwin 25.6.0]
Apple M1 (Virtual), 1 CPU, 3 logical and 3 physical cores
.NET SDK 10.0.403
  [Host]     : .NET 10.0.14 (10.0.14, 10.0.1426.52326), Arm64 RyuJIT armv8.0-a
  Job-GVKUBM : .NET 10.0.14 (10.0.14, 10.0.1426.52326), Arm64 RyuJIT armv8.0-a

Runtime=.NET 10.0  

```
| Method                            | Mean        | Error      | StdDev     | Median      | Gen0   | Allocated |
|---------------------------------- |------------:|-----------:|-----------:|------------:|-------:|----------:|
| &#39;B1 BS to AD&#39;                     |    21.89 ns |   1.255 ns |   3.662 ns |    21.12 ns |      - |         - |
| &#39;B2 AD to BS&#39;                     |    29.56 ns |   1.696 ns |   4.973 ns |    27.54 ns |      - |         - |
| &#39;B3 add 1000 days&#39;                |    28.58 ns |   0.962 ns |   2.759 ns |    28.23 ns |      - |         - |
| &#39;B4 add 13 months, Clamp&#39;         |    16.87 ns |   0.457 ns |   1.289 ns |    16.81 ns |      - |         - |
| &#39;B5 long format, Nepali, weekday&#39; |   215.10 ns |   4.952 ns |  14.288 ns |   214.30 ns | 0.0694 |     435 B |
| &#39;B6 strict parse&#39;                 |    29.91 ns |   1.169 ns |   3.446 ns |    29.34 ns |      - |         - |
| &#39;B7 patro info&#39;                   |    50.61 ns |   2.241 ns |   6.466 ns |    48.64 ns | 0.0082 |      51 B |
| &#39;B8 patro month grid&#39;             | 3,356.33 ns | 107.622 ns | 315.636 ns | 3,363.37 ns | 0.2213 |    1429 B |
