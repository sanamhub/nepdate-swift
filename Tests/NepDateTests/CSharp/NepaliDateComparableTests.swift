import Testing

@testable import NepDate

// C# `IComparable.CompareTo(object)` and `IComparable<T>.CompareTo` both map to `Comparable`.
@Suite("NepaliDateComparableTests")
struct NepaliDateComparableTests {
  let d1 = try! NepaliDate(year: 2081, month: 1, day: 1)
  let d2 = try! NepaliDate(year: 2081, month: 6, day: 15)
  let d3 = try! NepaliDate(year: 2082, month: 1, day: 1)

  @Test("NepaliDateComparableTests.CompareTo_Object_Earlier_ReturnsNegative")
  func compareToObjectEarlierReturnsNegative() {
    #expect(d1 < d2)
  }

  @Test("NepaliDateComparableTests.CompareTo_Object_Same_ReturnsZero")
  func compareToObjectSameReturnsZero() throws {
    let same = try bs(2081, 1, 1)
    #expect(!(d1 < same) && !(same < d1) && d1 == same)
  }

  @Test("NepaliDateComparableTests.CompareTo_Object_Later_ReturnsPositive")
  func compareToObjectLaterReturnsPositive() {
    #expect(d3 > d1)
  }

  // NepaliDateComparableTests.CompareTo_Object_Null_ReturnsPositive: n/a, Swift has no null
  // NepaliDate to compare with.
  // NepaliDateComparableTests.CompareTo_WrongType_ThrowsArgumentException: n/a, `<` only accepts
  // another NepaliDate, so the wrong type is a compile error.

  @Test("NepaliDateComparableTests.CompareTo_Generic_Earlier_ReturnsNegative")
  func compareToGenericEarlierReturnsNegative() {
    #expect(d1 < d2)
  }

  @Test("NepaliDateComparableTests.CompareTo_Generic_Same_ReturnsZero")
  func compareToGenericSameReturnsZero() throws {
    #expect(d1 == (try bs(2081, 1, 1)))
  }

  @Test("NepaliDateComparableTests.CompareTo_Generic_Later_ReturnsPositive")
  func compareToGenericLaterReturnsPositive() {
    #expect(d3 > d1)
  }

  @Test("NepaliDateComparableTests.SortedSet_OrdersCorrectly")
  func sortedSetOrdersCorrectly() {
    let ordered = Set([d3, d1, d2]).sorted()
    #expect(ordered == [d1, d2, d3])
  }

  @Test("NepaliDateComparableTests.ArraySort_ViaIComparable_OrdersCorrectly")
  func arraySortViaIComparableOrdersCorrectly() {
    let dates = [d3, d1, d2].sorted(by: <)
    #expect(dates == [d1, d2, d3])
  }

  @Test("NepaliDateComparableTests.List_Sort_OrdersCorrectly")
  func listSortOrdersCorrectly() {
    var list = [d3, d1, d2]
    list.sort()
    #expect(list == [d1, d2, d3])
  }
}
