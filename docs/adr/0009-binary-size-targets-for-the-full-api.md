# ADR-0009: Binary size targets for the full API

- **Status:** accepted
- **Date:** 2026-11-03
- **Approved by:** Sanam

## Context

ADR-0006 set the size targets at `core-only` minus baseline < 120 KB (122,880 bytes) and
`with-patro` minus baseline < 250 KB (256,000 bytes), measured on macOS arm64 against deltas of
108,160 and 226,032 bytes. In this ADR 1 KB is 1,024 bytes.

The hub decided on 2026-11-02 that every port offers the full C# NepDate API. For Swift that adds
the range set operations, the month and fiscal-quarter splits, `dates(every:)`, the working and
weekend days, ordered batch conversion, `Strideable`, the `YYYYMMDD` integer form, the relative-day
predicates and `NepaliDate.FormatStyle`.

Unused functions dead-strip, but every protocol conformance and its witnesses stay in any app that
links the core. The first measurement of the full API gave 168,016 and 302,288 bytes. Most of that
was synthesized `Codable` on the format style and its option enums; encoding the style as one
integer and dropping `Codable` from the enums brought it to 131,616 and 265,872 bytes. What remains
is the new surface itself and the conformances Swift requires for it, such as `Codable` on a
`Foundation.FormatStyle`.

Two other ways were considered and rejected:

- **Moving the Foundation conformances and the clock helpers to a separate product** would keep the
  core under 120 KB but changes how users import the formatter and the time-zone functions, which
  the spec lists as part of the core API.
- **Dropping `Foundation.FormatStyle` or the `Collection` conformance of the range** would save a
  few kilobytes but loses the idioms a Swift user expects from a date and a range type.

## Decision

- **`core-only` minus baseline < 140 KB (143,360 bytes).** The measured delta is 131,616, so the
  target leaves 11,744 bytes.
- **`with-patro` minus baseline < 280 KB (286,720 bytes).** The measured delta is 265,872, so the
  target leaves 20,848 bytes, about two-thirds of one more data year at the 28,254 bytes per year
  ADR-0006 measured.
- **Measurement** stays as ADR-0006 describes: macOS arm64, `swift build -c release`, stripped,
  against the baseline executable.
- This ADR replaces the two targets of ADR-0006 and leaves the rest of it in force.

## Consequences

`Benchmarks/size-targets.json` carries the new limits. A new conformance on a public type now has a
known size cost and should be measured before it is added. A second new patro data year will need a
new target.
