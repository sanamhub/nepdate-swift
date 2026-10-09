# S2: Arithmetic, diff, fiscal year, range

Read first: `shared/spec/ALGORITHM.md` §7–8b, `docs/API.md` (arithmetic, `DateDiff`, `FiscalYear`,
`Quarter`, `NepaliDateRange`), `shared/spec/PARITY.md` D-02, D-03, D-07, D-08, D-09, D-12,
`shared/spec/PORT-PLAN.md` phase 2.

## Tasks

### S2-01 `adding(days:)`, `days(until:)`
Through the serial. Compute the new serial in `Int` and range-check it before narrowing to `Int32`,
so `adding(days: .max)` throws `.outOfRange` instead of trapping.
- AC1: golden `add-days.tsv` (9162 rows; `ERR` means `.outOfRange`).
- AC2: `NepaliDate.max.adding(days: 1)` and `NepaliDate.min.adding(days: Int.min)` throw
  `.outOfRange`.
- AC3: `a.days(until: b) == -b.days(until: a)` for the first 100 golden dates paired with the last 100.

### S2-02 `adding(months:overflow:)`, `adding(years:overflow:)`
ALGORITHM §8. `MonthOverflow.clamp` is the spec's Clamp, `.spill` is the spec's Overflow. Guard
`12 * years` against `Int` overflow (throw `.outOfRange`).
- AC1: golden `add-months.tsv` (10180 rows): column `clamp` with `.clamp`, column `overflow` with
  `.spill`.
- AC2: 2081-04-32 +2 months gives 2081-06-30 (clamp) and 2081-07-02 (spill); +5 months gives
  2081-09-29 and 2081-10-03.
- AC3: `adding(years: .max)` throws `.outOfRange`.

### S2-03 `diff(to:)`
ALGORITHM §8a, starting from the hinted `n0` and stepping down; no loop over days.
`DateDiff.totalDays` is `days(until:)`; `isNegative` is true when `other < self`, and then
`years`, `months`, `days` are the breakdown of the swapped pair (all ≥ 0).
- AC1: `a.diff(to: b).totalDays == a.days(until: b)` over the golden dates paired as in S2-01 AC3.
- AC2: 2081-04-32 to 2081-06-30 is 0 years, 2 months, 0 days; the reverse has `isNegative == true`
  and the same breakdown.

### S2-04 `FiscalYear`, `Quarter`, `fiscalYear`, `quarter`
ALGORITHM §8b. `start()`, `end()`, `range()` and `range(of:)` throw `.outOfRange` outside BS
1901–2199 (`FiscalYear(startYear: 1900).start()`, `FiscalYear(startYear: 2199).end()`).
`Quarter.months` returns the three months in order (Q4 = Baishakh, Jestha, Ashad).
- AC1: golden `dates.tsv` columns `fy_start`, `fy_end`, `quarter_start`, `quarter_end` (`ERR`
  means `.outOfRange`).
- AC2: `FiscalYear(startYear: 2082).label(.nepali) == "२०८२/८३"` and `.label() == "2082/83"`;
  `FiscalYear(startYear: 2099).label() == "2099/00"`.

### S2-05 `NepaliDateRange`
`RandomAccessCollection` with `Index = Int32` serials: `startIndex` is the first serial,
`endIndex` the last serial + 1, `subscript` builds the date with `init(serial:)`. Write `count`
and `contains(_:)` by hand (O(1)); the default `contains` walks the collection. `month(year:month:)`
and `year(_:)` throw the same errors as `init(year:month:day:)`.
- AC1: for every year 1901...2199, `try NepaliDateRange.year(y).count` equals the sum of its 12
  `monthLength`s and is in 364...367.
- AC2: `try NepaliDateRange.month(year: 2081, month: 4)` has 32 elements; `NepaliDateRange(b, a)`
  is `nil` when `a < b`; a one-day range has `count == 1`.
- AC3: `Array(range)` and `for d in range` give the same dates in ascending order.

### S2-06 C# catalogue rows, extra tests, B3 and B4
- Every C# catalogue row tagged S2 (139 rows: `NepaliDateArithmeticEdgeCaseTests` `AddDays_*` and
  `AddMonths_*`, `FiscalYearTests`, `FiscalYearInstanceMethodTests`, the S2 part of the two range
  classes, `NepaliDateMonthNameTests` that add months, `NepaliDateManipulationTests` `Subtract_*`,
  `OptimizationVerificationTests` `Subtraction_*`) has a test named after the row id, as in S1-06.
  `Subtract_*` rows are written against `days(until:)` with the sign of D-07; D-02 and D-09 rows get
  a comment naming the D-ID.
- Properties (100,000 cases each): P4 `try d.adding(days: n).adding(days: -n) == d` when both are in
  range; P5 `d.days(until: try d.adding(days: n)) == n`; P6 `adding(months:overflow: .clamp)` never
  changes the day except to clamp it to `monthLength`; P7 `diff` breakdown re-added to the earlier
  date gives the later date (ALGORITHM §8a).
- `Benchmarks`: B3 (add 1000 days) and B4 (add 13 months, `.clamp`) per BENCHMARK §3, threshold
  `.mallocCountTotal` 0. `NepaliDateRange` iteration of one month gets its own benchmark, also 0.
- AC: the test log lists the 139 S2 rows run or skipped with a D-ID; the `bench` job is green.

## Checkpoint
The agent stops here. The reviewer checks:
- [ ] Read ALGORITHM §8 next to `adding(months:)`: is the spill branch's `y3 > 2199` check there?
- [ ] `adding(days:)` computes in `Int` and range-checks before narrowing; no trap on `Int.max`.
- [ ] `diff(to:)` has no loop over days.
- [ ] `NepaliDateRange.contains` and `count` don't iterate.
- [ ] All golden rows of `add-days.tsv` (9,162) and `add-months.tsv` (10,180) pass, with the counts
  asserted.
- [ ] 139 S2 catalogue rows run or carry a D-ID comment; P4 to P7 exist.
- [ ] `bench` job: B3, B4 and range iteration at 0 mallocs.
