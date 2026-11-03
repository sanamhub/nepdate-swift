extension NepaliDate {
  /// Creates the BS date named by a `YYYYMMDD` integer (D-11).
  ///
  /// The integer is read as decimal year, month and day, so `20810415` is 2081-04-15. A value
  /// that does not name a valid date, including a negative value, gives `nil`. The conversion
  /// never wraps a wider integer into 32 bits: a value above `99991231` is rejected.
  ///
  /// - Parameter ymd: The packed year, month and day.
  @inlinable
  public init?(ymd: Int) {
    guard ymd > 0, ymd <= 99_991_231 else { return nil }
    let year = ymd / 10_000
    let month = (ymd / 100) % 100
    let day = ymd % 100
    guard let date = try? NepaliDate(year: year, month: month, day: day) else { return nil }
    self = date
  }

  /// The date as a `YYYYMMDD` integer (D-11), for example `20810415`.
  @inlinable
  public var ymd: Int { year * 10_000 + month * 100 + day }
}
