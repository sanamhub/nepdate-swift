// Gregorian calendar arithmetic, ALGORITHM §5 (Howard Hinnant, public domain), line for line on
// Int32. Callers stay inside AD 1844-04-11 to 2143-04-15, where every intermediate value is
// non-negative and below 1,000,000, so the wrapping operators can't overflow.

/// Days from 1970-01-01 to the given proleptic Gregorian date.
/// Callers check that `year` is in 1844...2143 and the date is real (`init(gregorianYear:)`).
@inlinable
func daysFromCivil(_ year: Int32, _ month: Int32, _ day: Int32) -> Int32 {
  let y = month <= 2 ? year &- 1 : year
  let era = y / 400  // y >= 0 in our range
  let yoe = y &- era &* 400  // [0, 399]
  let mp = (month &+ 9) % 12  // March = 0 .. February = 11
  let doy = (153 &* mp &+ 2) / 5 &+ day &- 1  // [0, 365]
  let doe = yoe &* 365 &+ yoe / 4 &- yoe / 100 &+ doy
  return era &* 146097 &+ doe &- 719468
}

/// The Gregorian date of a Unix day.
/// Callers pass `serial + epochUnixDays` for a valid serial, so `days` is in -45920...63291.
@inlinable
func civilFromDays(_ days: Int32) -> (year: Int32, month: Int32, day: Int32) {
  let z = days &+ 719468
  let era = z / 146097
  let doe = z &- era &* 146097
  let yoe = (doe &- doe / 1460 &+ doe / 36524 &- doe / 146096) / 365
  let y = yoe &+ era &* 400
  let doy = doe &- (365 &* yoe &+ yoe / 4 &- yoe / 100)
  let mp = (5 &* doy &+ 2) / 153
  let d = doy &- (153 &* mp &+ 2) / 5 &+ 1
  let m = mp < 10 ? mp &+ 3 : mp &- 9
  return (m <= 2 ? y &+ 1 : y, m, d)
}

/// Days in a Gregorian month, or 0 for a month outside 1...12. Works for any year.
@inlinable
func gregorianMonthLength(_ year: Int, _ month: Int) -> Int {
  switch month {
  case 1, 3, 5, 7, 8, 10, 12: return 31
  case 4, 6, 9, 11: return 30
  case 2: return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0 ? 29 : 28
  default: return 0
  }
}
