// Gate 4 of ADR-0004: line coverage of the library sources must be at least 90 %.
//
//   swift run --package-path Tools/Codegen coverage-check "$(swift test --show-codecov-path)"

import Foundation

let threshold = 90.0
let libraryDirectories = ["/Sources/NepDate/", "/Sources/NepDatePatro/"]

/// The parts of the llvm-cov JSON export this check reads.
struct Export: Decodable {
  struct Unit: Decodable { let files: [File] }
  struct File: Decodable {
    let filename: String
    let summary: Summary
  }
  struct Summary: Decodable { let lines: Lines }
  struct Lines: Decodable {
    let count: Int
    let covered: Int
  }
  let data: [Unit]
}

func fail(_ message: String) -> Never {
  print("coverage-check: \(message)")
  exit(1)
}

let arguments = CommandLine.arguments
guard arguments.count == 2 else { fail("usage: coverage-check <codecov.json>") }

let export: Export
do {
  let data = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
  export = try JSONDecoder().decode(Export.self, from: data)
} catch {
  fail("cannot read \(arguments[1]): \(error)")
}

let files = export.data.flatMap(\.files).filter { file in
  libraryDirectories.contains { file.filename.contains($0) }
}
// No matching file means the path filter is wrong, not that coverage is perfect.
guard !files.isEmpty else { fail("no files under \(libraryDirectories) in the report") }

let total = files.reduce(0) { $0 + $1.summary.lines.count }
let covered = files.reduce(0) { $0 + $1.summary.lines.covered }
// A file of constants alone has no executable lines; that counts as fully covered.
let percent = total == 0 ? 100.0 : Double(covered) * 100 / Double(total)
let summary = String(
  format: "%.1f %% of %d lines in %d files (threshold %.0f %%)", percent, total, files.count,
  threshold)
guard percent >= threshold else { fail("line coverage \(summary)") }
print("coverage-check: line coverage \(summary)")
