/// A day of the week. The raw value counts from Sunday = 0, as in Nepal.
public enum Weekday: Int, Sendable, CaseIterable {
  /// आइतवार.
  case sunday = 0
  /// सोमवार.
  case monday
  /// मङ्गलवार.
  case tuesday
  /// बुधवार.
  case wednesday
  /// बिहिवार.
  case thursday
  /// शुक्रवार.
  case friday
  /// शनिवार.
  case saturday
}
