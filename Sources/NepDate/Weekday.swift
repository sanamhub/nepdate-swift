/// A day of the week. The raw value counts from Sunday = 0, as in Nepal.
public enum Weekday: Int, Sendable, CaseIterable {
  /// आइतबार.
  case sunday = 0
  /// सोमबार.
  case monday
  /// मङ्गलबार.
  case tuesday
  /// बुधबार.
  case wednesday
  /// बिहिबार.
  case thursday
  /// शुक्रबार.
  case friday
  /// शनिबार.
  case saturday
}
