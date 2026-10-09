import NepDate

/// The 64 benchmark dates of `shared/spec/BENCHMARK.md` §2, as BS and AD (year, month, day).
///
/// Date `i` is at serial `s0 + i * ((s1 - s0) / 63)`, where `s0` is BS 2000-01-01 and `s1` is
/// BS 2090-12-30. The serial is not public, so the day steps are taken on the AD side, where one
/// day is one day too.
public struct BenchmarkInputs: Sendable {
  public let bs: [(year: Int, month: Int, day: Int)]
  public let ad: [(year: Int, month: Int, day: Int)]

  public init() throws {
    let start = try NepaliDate(year: 2000, month: 1, day: 1).gregorian
    let end = try NepaliDate(year: 2090, month: 12, day: 30).gregorian
    let s0 = Self.unixDay(start.year, start.month, start.day)
    let step = (Self.unixDay(end.year, end.month, end.day) - s0) / 63
    var bs: [(year: Int, month: Int, day: Int)] = []
    var ad: [(year: Int, month: Int, day: Int)] = []
    for i in 0..<64 {
      let g = Self.civil(s0 + i * step)
      let date = try NepaliDate(gregorianYear: g.year, month: g.month, day: g.day)
      bs.append((date.year, date.month, date.day))
      ad.append(g)
    }
    self.bs = bs
    self.ad = ad
  }

  /// Howard Hinnant's days_from_civil, kept separate from the library under test.
  static func unixDay(_ year: Int, _ month: Int, _ day: Int) -> Int {
    let y = month <= 2 ? year - 1 : year
    let era = y / 400
    let yoe = y - era * 400
    let doy = (153 * ((month + 9) % 12) + 2) / 5 + day - 1
    return era * 146097 + yoe * 365 + yoe / 4 - yoe / 100 + doy - 719468
  }

  /// Howard Hinnant's civil_from_days.
  static func civil(_ days: Int) -> (year: Int, month: Int, day: Int) {
    let z = days + 719468
    let era = z / 146097
    let doe = z - era * 146097
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
    let mp = (5 * doy + 2) / 153
    let m = mp < 10 ? mp + 3 : mp - 9
    return (yoe + era * 400 + (m <= 2 ? 1 : 0), m, doy - (153 * mp + 2) / 5 + 1)
  }
}
