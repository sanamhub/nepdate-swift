import Testing

@testable import NepDate

@Suite("Concurrency")
struct ConcurrencyTests {
  static let tasks = 8
  static let datesPerTask = 10_000

  /// Converts `count` dates spread over the range, starting at `offset`, and folds the results
  /// into one number, so two runs can be compared cheaply.
  static func convert(offset: Int, count: Int) -> Int {
    var checksum = 0
    for k in 0..<count {
      let serial = Int32((offset + k * 10) % 109212)
      let date = NepaliDate(serial: serial)
      let g = date.gregorian
      guard let back = try? NepaliDate(gregorianYear: g.year, month: g.month, day: g.day) else {
        return -1
      }
      checksum = checksum &* 31 &+ back.year &* 10_000 &+ back.month &* 100 &+ back.day
    }
    return checksum
  }

  @Test("8 tasks convert 10,000 dates each; results equal a single-threaded run")
  func parallelConversion() async {
    let results = await withTaskGroup(of: (Int, Int).self) { group in
      for task in 0..<Self.tasks {
        group.addTask { (task, Self.convert(offset: task * 7, count: Self.datesPerTask)) }
      }
      var results = [Int](repeating: 0, count: Self.tasks)
      for await (task, checksum) in group { results[task] = checksum }
      return results
    }
    for task in 0..<Self.tasks {
      #expect(results[task] == Self.convert(offset: task * 7, count: Self.datesPerTask))
      #expect(results[task] != -1)
    }
  }
}
