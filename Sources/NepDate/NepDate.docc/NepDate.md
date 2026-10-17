# ``NepDate``

Bikram Sambat (Nepali calendar) for Swift: conversion, arithmetic, formatting, parsing and ranges
for BS 1901-01-01 to 2199-12-30 (AD 1844-04-11 to 2143-04-15).

## Overview

Every ``NepaliDate`` value is a valid date: the initialisers throw ``NepDateError`` instead of
building an invalid one. A date is 8 bytes and holds both the day count since BS 1901-01-01 and the
year, month and day, so conversion, comparison and arithmetic read no table (ADR-0002).

```swift
let date = try NepaliDate(year: 2081, month: 4, day: 15)
print(date.gregorian)            // (year: 2024, month: 7, day: 30)
print(date.long(weekday: true))  // Tuesday, Shrawan 15, 2081
```

Conversion, arithmetic, parsing and reading a patro day do not allocate. A formatter allocates once
when its result is longer than 15 UTF-8 bytes, and the `append…(to:)` forms write into a buffer the
caller reuses.

## Foundation's Vikram calendar is a different calendar

`Calendar.Identifier.vikram` (iOS 26 and later) is the Indian lunisolar Vikram calendar, not Nepal's
solar Bikram Sambat. Its month boundaries differ, and Apple ships no Nepali calendar. Use this
package for Nepali dates.

## Tithi, holidays and events

Tithi, public holidays and events are in the separate `NepDatePatro` product, which depends on
`NepDate` and never the other way round. An app that only converts dates links no patro data.

```swift
import NepDate
import NepDatePatro

let info = date.calendarInfo
print(info.tithi?.english ?? "no tithi")
for event in info.events {
  print(event.english)
}
```
