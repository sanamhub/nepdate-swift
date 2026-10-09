/// A Bikram Sambat month. The raw value is the month number, 1 (Baishakh) to 12 (Chaitra).
public enum Month: Int, Sendable, CaseIterable, Comparable {
  /// बैशाख, month 1.
  case baishakh = 1
  /// जेठ, month 2.
  case jestha
  /// असार, month 3.
  case ashad
  /// साउन, month 4.
  case shrawan
  /// भदौ, month 5.
  case bhadra
  /// असोज, month 6.
  case ashoj
  /// कात्तिक, month 7.
  case kartik
  /// मंसिर, month 8.
  case mangsir
  /// पुस, month 9.
  case poush
  /// माघ, month 10.
  case magh
  /// फागुन, month 11.
  case falgun
  /// चैत, month 12.
  case chaitra

  /// Orders months by number, Baishakh first.
  @inlinable
  public static func < (lhs: Month, rhs: Month) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
