| ID | Swift p50 ns/op | Swift p90 ns/op | NepDate mallocs/op | C# .NET 10 ns/op | ratio Swift/C# |
|---|---:|---:|---:|---:|---:|
| B1 | 21.9 | 22.1 | 0 | 19.2 | 1.14 |
| B2 | 17.5 | 17.8 | 0 | 31.8 | 0.55 |
| B3 | 14.7 | 15.0 | 0 | 29.9 | 0.49 |
| B4 | 8.1 | 8.5 | 0 | 24.2 | 0.34 |
| B5 | 515.6 | 515.6 | 1 | 248.9 | 2.07 |
| B6 | 31.3 | 31.3 | 0 | 26.3 | 1.19 |
| B7 | 66.2 | 67.0 | 0 | 70.8 | 0.93 |
| B8 | 2,546.9 | 2,687.5 | 0 | 2,335.1 | 1.09 |

| Extra benchmark | Swift p50 ns/op | Swift p90 ns/op | mallocs/op |
|---|---:|---:|---:|
| B5a | 421.9 | 437.5 | 0 |
| B7-sorted | 98.2 | 100.2 | 0 |
| MonthRange | 92.8 | 93.3 | 0 |

Baseline (harness only): 0.25 mallocs/op.

| Competitor benchmark | Swift p50 ns/op | Swift p90 ns/op | mallocs/op |
|---|---:|---:|---:|
| nrlnishan-B1 | 1,421.9 | 1,531.2 | 1.25 |
| nrlnishan-B2 | 8,687.5 | 8,796.9 | 2.25 |
