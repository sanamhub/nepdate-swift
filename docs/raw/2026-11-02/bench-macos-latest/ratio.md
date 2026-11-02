| ID | Swift p50 ns/op | Swift p90 ns/op | NepDate mallocs/op | C# .NET 10 ns/op | ratio Swift/C# |
|---|---:|---:|---:|---:|---:|
| B1 | 20.2 | 24.7 | 0 | 21.9 | 0.92 |
| B2 | 16.9 | 26.0 | 0 | 29.6 | 0.57 |
| B3 | 17.6 | 26.7 | 0 | 28.6 | 0.62 |
| B4 | 19.5 | 36.5 | 0 | 16.9 | 1.16 |
| B5 | 421.9 | 984.4 | 1 | 215.1 | 1.96 |
| B6 | 32.6 | 76.2 | 0 | 29.9 | 1.09 |
| B7 | 38.4 | 54.7 | 0 | 50.6 | 0.76 |
| B8 | 1,468.8 | 2,937.5 | 0 | 3,356.3 | 0.44 |

| Extra benchmark | Swift p50 ns/op | Swift p90 ns/op | mallocs/op |
|---|---:|---:|---:|
| B5a | 312.5 | 718.8 | 0 |
| B7-sorted | 109.4 | 265.6 | 0 |
| MonthRange | 78.8 | 218.1 | 0 |

Baseline (harness only): 0.00 mallocs/op.

| Competitor benchmark | Swift p50 ns/op | Swift p90 ns/op | mallocs/op |
|---|---:|---:|---:|
| nrlnishan-B1 | 1,828.1 | 3,968.8 | 2.00 |
| nrlnishan-B2 | 16,875.0 | 29,187.5 | 3.00 |
| shivathapaa-B1 | 937.5 | 2,031.2 | 2.00 |
| shivathapaa-B2 | 1,062.5 | 2,421.9 | 2.00 |
