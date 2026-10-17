// Gate 5 of ADR-0004: the `## Quick start` blocks in README.md are the two Examples programs, byte
// for byte. Run from the repository root:
//
//   swift run --package-path Tools/Codegen readme-check

import Foundation

/// The two programs the quick start shows, in README order.
let examplePaths = [
  "Examples/Sources/core-only/main.swift",
  "Examples/Sources/with-patro/main.swift",
]

func fail(_ message: String) -> Never {
  print("readme-check: \(message)")
  exit(1)
}

/// Reads a file as UTF-8 with LF line endings, so a Windows checkout compares equal.
func readText(_ path: String) -> String {
  guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
    let text = String(data: data, encoding: .utf8)
  else {
    fail("cannot read \(path)")
  }
  return text.replacingOccurrences(of: "\r\n", with: "\n")
}

let readme = readText("README.md")
let lines = readme.components(separatedBy: "\n")

guard let start = lines.firstIndex(of: "## Quick start") else {
  fail("README.md has no '## Quick start' heading")
}

// The section ends at the next level-2 heading.
var end = lines.count
for index in (start + 1)..<lines.count where lines[index].hasPrefix("## ") {
  end = index
  break
}

var blocks: [[String]] = []
var index = start + 1
while index < end {
  guard lines[index].hasPrefix("```") else {
    index += 1
    continue
  }
  let opening = lines[index]
  guard opening == "```swift" else {
    fail("README.md line \(index + 1): only swift blocks belong under '## Quick start'")
  }
  var block: [String] = []
  index += 1
  while index < end && !lines[index].hasPrefix("```") {
    block.append(lines[index])
    index += 1
  }
  guard index < end else { fail("README.md has an unclosed swift block under '## Quick start'") }
  blocks.append(block)
  index += 1
}

guard blocks.count == examplePaths.count else {
  fail("'## Quick start' has \(blocks.count) swift blocks, expected \(examplePaths.count)")
}

for (position, path) in examplePaths.enumerated() {
  var expected = readText(path).components(separatedBy: "\n")
  // A trailing newline gives one last empty component; the fenced block has no such line.
  if expected.last == "" { expected.removeLast() }
  let found = blocks[position]
  guard found == expected else {
    var line = 0
    while line < min(found.count, expected.count), found[line] == expected[line] { line += 1 }
    let foundLine = line < found.count ? found[line] : "<end of block>"
    let expectedLine = line < expected.count ? expected[line] : "<end of file>"
    fail(
      """
      swift block \(position + 1) under '## Quick start' differs from \(path) at line \(line + 1)
        README:     \(foundLine)
        \(path): \(expectedLine)
      """)
  }
}

print(
  "readme-check: \(blocks.count) quick start blocks match \(examplePaths.joined(separator: " and "))")
