# ADR-0002: Representation, tables and performance

- Status: Accepted
- Date: 2026-10-07 (rewritten; replaces the 2026-10-06 version, which stored a 4-byte y/m/d and
  binary-searched a year table)
- Deciders: Sanam Pakuwal

## Context

Performance is the top priority of the NepDate family. `shared/spec/BENCHMARK.md` §6 sets the Swift
target: B1 (BS to AD), B2 (AD to BS) and B7 (patro info) within 1.5× of C# NepDate, and zero bytes
allocated per operation. The library also runs inside an iOS widget extension, which the system
kills at about 30 MB, and on watchOS, where `Int` is 32 bits on `arm64_32`.

C# NepDate on the reference machine (hub H6, `docs/benchmarks/dotnet.md` in the hub, .NET 10,
BenchmarkDotNet, pinned to logical CPU 2, rerun 2026-10-09 with no other jobs):

| ID | C# ns/op | C# bytes/op | Swift target (1.5×) |
|---|---|---|---|
| B1 | 13.29 | 0 | ≤ 19.9 ns, 0 mallocs |
| B2 | 18.64 | 0 | ≤ 28.0 ns, 0 mallocs |
| B3 | 17.50 | 0 | 0 mallocs |
| B4 | 18.85 | 0 | 0 mallocs |
| B5 | 153.02 | 435 | 1 malloc (the result) |
| B6 | 21.55 | 0 | 0 mallocs |
| B7 | 47.93 | 51 | ≤ 71.9 ns, 0 mallocs |
| B8 | 3,132.66 | 1,429 | 0 mallocs |

C# stores `Year`, `Month`, `Day` as `int` plus a `DateTime?` computed in the constructor. BS to AD
reads one 3,588-entry tuple table and calls `DateTime.AddDays`; AD to BS reads a 3,589-entry table
and walks back through BS months. Patro data is sorted `ushort` day offsets searched with
`Array.BinarySearch`, and `GetCalendarInfo` allocates two `string[]` per call (the 51 bytes in B7).

Swift facts that shape the design (sources at the end):

- A global or `static let` is initialised lazily on first access through `swift_once`, unless the
  optimiser turns the initialiser into static data. Arrays of integer literals qualify. The array
  object still needs its header (class metadata); where the stdlib can't provide it statically, the
  runtime fills it in once (`swift_initStaticObject`). Either way the cost is one pass, once, of a
  few microseconds (estimated) over at most 28 KB.
- `InlineArray` (SE-0453) needs the Swift 6.2 runtime: iOS, macOS, watchOS, tvOS 26 and later.
  `@section` (SE-0492, Swift 6.3) guarantees static initialisation, but only for literals, tuples
  and `InlineArray`, not `Array` or `String`.
- `Span` (SE-0447) back-deploys to iOS 12.2, but `Array.span` and `String.utf8.span` need OS 26.
- Untyped `throws` boxes the error in `any Error` (a heap allocation). Typed throws (SE-0413)
  returns the error by value.
- A `String` of 15 UTF-8 bytes or fewer is stored inline (10 bytes on 32-bit watchOS). A string
  literal is immortal static data: returning one allocates nothing and needs no retain.
- SwiftPM builds source packages without library evolution, so `@frozen` has no effect here.
  Calls across the module boundary are inlined only for `@inlinable` code (or what cross-module
  optimisation chooses on its own, which we don't rely on).
- Arithmetic traps on overflow. `&+`, `&-`, `&*` don't check and are safe where a range check
  above them proves the result fits.

## Decision

### 1. `NepaliDate` stores the serial and the fields: 8 bytes

```swift
public struct NepaliDate: Sendable, BitwiseCopyable, ... {
    @usableFromInline package let serial: Int32   // days since BS 1901-01-01 (ALGORITHM §2)
    @usableFromInline let y: Int16
    @usableFromInline let m: UInt8
    @usableFromInline let d: UInt8
}
```

`MemoryLayout<NepaliDate>.size == 8`, `stride == 8`, `alignment == 4`. Every constructor already
has both forms in hand: `init(year:month:day:)` reads `monthStart[i]` to validate the day, so the
serial is one addition away; `init(serial:)` computes y/m/d. Storing both makes every later
operation table-free: `gregorian`, `weekday`, `adding(days:)`, `days(until:)`, comparison,
hashing and the patro lookup start from `serial`; `year`, `month`, `day` and the formatters read
the fields. `==`, `<` and `hash(into:)` use `serial` only (written by hand, not synthesised).
`BitwiseCopyable` (SE-0426) is declared, so the compiler proves the type has no references.

### 2. Core tables: two arrays, about 28 KB

Generated into `Sources/NepDate/Calendar.generated.swift`, `enum CalendarData` (internal,
`@usableFromInline`), as `static let` arrays of integer literals with an explicit element type:

| Table | Type, count | Bytes | Use |
|---|---|---|---|
| `monthStart` | `[Int32]`, 3,589 | 14,356 | serial of the first day of month index `i = (y - 1901) * 12 + m - 1`; `[3588] == 109212`. Month length is `monthStart[i + 1] - monthStart[i]`; year start is `monthStart[(y - 1901) * 12]` |
| `monthAtBucket` | `[UInt16]`, 6,826 | 13,652 | month index of serial `b * 16` |

`init(serial:)`: `i = monthAtBucket[s >> 4]`; if `s >= monthStart[i + 1]` then `i += 1` (once at
most, because a 16-day bucket is shorter than the shortest month, 29 days; checked over all 109,212
serials on 2026-10-07); then `y = 1901 + i / 12`, `m = i % 12 + 1`, `d = s - monthStart[i] + 1`.
That is two or three loads and no loop, against a 9-step binary search plus up to 12 month steps
in ALGORITHM §4. The month-lengths and year-start tables of the old design are dropped: both are
differences of `monthStart` entries already in cache.

Gregorian conversion is Hinnant's `civilFromDays` and `daysFromCivil` (ALGORITHM §5) on `Int32`
with `&` operators after the range check. If B1 or B2 misses its target, the replacement is
Neri and Schneider's Euclidean affine form (2023), which needs no new table; a proxy of it
matched Hinnant on every day from serial -1,000 to 120,000.

### 3. Patro tables: dense per-day arrays and a switch for names

Generated into `Sources/NepDatePatro/Patro.generated.swift`, `enum PatroData`. Coverage is
2077-01-01 to 2084-08-20: serials 64,285 to 67,077, 2,793 days. Every lookup is
`k = serial - 64285` and a bounds check, then O(1):

| Table | Type, count | Bytes | Use |
|---|---|---|---|
| `dayInfo` | `[UInt8]`, 2,793 | 2,793 | bits 0 to 5: tithi name id + 1 (0 = no tithi); bit 7: public holiday |
| `dayEventStart` | `[UInt16]`, 2,794 | 5,588 | events of day `k` are `eventNameIDs[dayEventStart[k] ..< dayEventStart[k + 1]]` |
| `eventNameIDs` | `[UInt16]`, 3,032 | 6,064 | name id per event, file order |
| `name(_ id: UInt16)` | generated `switch`, 753 cases | strings: 59,800 | `(nepali: String, english: String)` literals; ids 0 to 31 are the tithi names |

PATRO §3 suggests sorted serials and binary search for the sparse parts, and allows dense per-day
tables when a benchmark shows they are faster at an acceptable size (hub spec as of 2026-10-08;
`shared/` gets it at the next sync). The dense layout is smaller here (14.4 KB against about 19 KB
for sorted serials plus offsets) and needs no search; S4-05 benchmarks it against a binary-search
variant to give the evidence PATRO §3 asks for.
Names come from a `switch` of string literals, not a `[String]` array: an array of strings is
built on first access, a switch case is two constants in code and needs no initialisation, no
retain and no allocation. `publicHolidays` scans `dayInfo` for bit 7.

`calendarInfo` returns a value of three small fields, with no allocation:
`tithi: Named?` (`Named` holds the 2-byte id; `nepali` and `english` are computed from the switch),
`isPublicHoliday: Bool`, and `events: PatroEvents`, a `RandomAccessCollection` of `Named` that holds
two `UInt16` offsets. `Array(info.events)` gives a plain array when a caller wants one.

### 4. Strings: one allocation per formatted result, none when the caller passes a buffer

- `Month`, `Weekday` names and Devanagari digits come from `switch` statements returning literals.
- Formatters append to a `String` after `reserveCapacity` with the exact UTF-8 byte count of the
  result. A result of 15 bytes or fewer (`description`, `format("s")`, `nepaliDigits(2081)`)
  stays inline: no allocation. A longer one allocates once. Each formatter has an `append…(to:)`
  form that writes into a caller's `String`; a widget drawing a month reuses one buffer and
  allocates nothing after the first day.
- No `Character` iteration in hot paths (grapheme breaking is slow); work on `utf8`.
- `OutputSpan` (SE-0485) and `String(unsafeUninitializedCapacity:)` were considered. SE-0485
  needs a new standard library and runtime (OS 26 on Apple) and lists its `String` methods as
  still pending; the second needs unsafe pointers (AGENTS.md §2).

### 5. Parsing: over `utf8`, no copies

`parse` and `parseLenient` take `some StringProtocol`, so a `Substring` is parsed in place. They read
`utf8` once: ASCII digits `0x30...0x39`, Devanagari digits `E0 A5 A6...AF`, `।` `E0 A5 A4`. Tokens are
index ranges, never `Substring` or `Array` values. Lenient month names compare UTF-8 bytes against
generated tables; the generator fails if any name changes under NFC or NFD, so a byte comparison
equals canonical equivalence. Errors are typed (`throws(NepDateError)`).

### 6. Inlining and overflow

- Public hot paths are `@inlinable`: the three initialisers, `init(serial:)`, `year`, `month`,
  `day`, `gregorian`, `weekday`, `monthLength`, `adding(days:)`, `days(until:)`, `==`, `<`,
  `hash(into:)`, `calendarInfo`. What they call is `@usableFromInline`, including the tables.
- No `@frozen`: without library evolution it does nothing, and it would claim an ABI promise this
  package doesn't make.
- `&+`, `&-`, `&*` only below a range check that proves the result fits, with a one-line comment
  naming the check. Everything else uses the checked operators.

### 7. Targets and how they are measured

Swift benchmarks run on CI (Linux x86_64 and macOS arm64), not the reference machine, because
package-benchmark has no Windows support (BENCHMARK §1). To get a ratio on the same hardware, the
benchmark workflow also runs the hub's `tools/dotnet-bench` (.NET 10 runs on both) and divides.

| Item | Target | Estimate (unmeasured) |
|---|---|---|
| B1, B2 | ≤ 1.5× C# on the same runner | 5 to 15 ns |
| B7 | ≤ 1.5× C# on the same runner | 3 to 10 ns |
| mallocs, B1 to B4, B6 to B8 | 0 per operation | 0 |
| mallocs, B5 | 1 per operation; 0 with `appendLong(to:)` and a warm buffer | 1 / 0 |
| first access to all core tables | report; < 100 µs | 5 to 30 µs |
| `core-only` minus `baseline`, stripped arm64 | < 100 KB | 40 to 70 KB |
| `with-patro` minus `baseline`, stripped arm64 | < 200 KB | 120 to 170 KB |
| dirty memory added in a widget | < 64 KB | ≤ 43 KB (all tables) |

The estimates come from the table sizes above and from a Rust program with the same tables,
bounds-checked indexing and overflow checks, run on the reference machine on 2026-10-07 while other
builds were running: B1 11 to 16 ns, B2 9 to 31 ns, B3 1 to 5 ns, B7 2 to 13 ns. Those runs were too
noisy to be more than an order of magnitude. The C++ port's experiment with a month-start table
and 32-day block index (its ADR-0002 §8, same machine) measured B1 4.6 to 9.2 ns and B2 4.7 to 6.1 ns
without bounds checks; Swift adds one bounds check per load and, unless the tables become static
data, a `swift_once` guard per access (a load and a predictable branch), so 5 to 15 ns stays the
estimate. Measurement tasks: S1-07 (the `Benchmarks` package with
malloc thresholds on every PR, static initialisation and first access), S5-02 (B1 to B8,
competitors, C# ratio) and S5-03 (size).

## Alternatives considered

| Option | Why not |
|---|---|
| 4-byte `Int16` year, `UInt8` month and day (the previous version) | B1, B2, B3, B7 and `weekday` each need one more dependent table load to get the serial |
| `Int32` serial only | every `year`, `month`, `day` read and every formatter decodes the serial |
| C#-style direct tables (BS month to AD date, AD month to BS date) | two more tables of about 14 KB; AD to BS still walks months, and BS to AD needs a Gregorian month-length loop; the serial makes add days, diff, weekday and patro free |
| Binary search over a 300-entry year table (ALGORITHM §4 as written) | 9 compares and up to 12 month steps, against one load and one compare |
| `InlineArray` tables, or `@section` for guaranteed static data | needs iOS 26 (Swift 6.2 runtime); our floor is iOS 15. Revisit when the floor reaches 26 |
| Tuples of 3,589 elements | slow to type-check; indexing needs unsafe pointers |
| One `StaticString` byte blob read through `UnsafeRawBufferPointer` | unsafe pointers (AGENTS.md §2); string literals store bytes above `0x7F` as multi-byte UTF-8 |
| Returning `Span` for patro events | `Array.span` needs OS 26 |
| Patro names as a global `[Named]` or `[String]` | initialised on first access; the `switch` needs nothing |
| Sorted serial arrays and binary search for holidays and event days (C# layout, PATRO §3 suggestion) | up to 11 compares and about 5 KB more than the dense tables |
| `events: [Named]` in `CalendarInfo` | one array allocation per day with events |
| Untyped `throws` | boxes every error in `any Error` |

## Consequences

- `NepaliDate` is 8 bytes instead of 4. An array of 10,000 dates costs 40 KB more.
- The two stored forms must agree. Only `init(serial:)` and the validated `init(year:month:day:)`
  path create values; the exhaustive test (S1-05) checks all 109,212.
- `docs/API.md` changes: `PatroEvents`, `Named` with computed names, `append…(to:)` formatters,
  `some StringProtocol` parsing, `BitwiseCopyable`.
- Swift numbers are never in the same column as the reference-machine numbers; the comparison
  with C# is a ratio on the same CI runner.

Sources: SE-0426 (BitwiseCopyable), SE-0413 (typed throws), SE-0447 (Span), SE-0453 (InlineArray),
SE-0485 (OutputSpan), SE-0492 (section placement, accepted 2025-10, Swift 6.3) at
https://github.com/swiftlang/swift-evolution/tree/main/proposals;
https://forums.swift.org/t/using-span-on-pre-26-apple-os-versions/80513 (which Span APIs need
OS 26); https://forums.swift.org/t/inlinearray-is-only-available-in-macos-26-0-or-newer/84103;
`__StaticArrayStorage` in https://github.com/swiftlang/swift/blob/main/stdlib/public/core/ContiguousArrayBuffer.swift;
https://forums.swift.org/t/statically-initialized-arrays/6114 (array outlining into static data);
C. Neri and L. Schneider, "Euclidean affine functions and their application to calendar
algorithms", Software: Practice and Experience 53(4), 2023; C# NepDate at `cb05cb65`
(`DictionaryBridge.cs`, `CalendarBridge.cs`).
