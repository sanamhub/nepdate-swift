// The prose a user reads has no em dash and every relative link resolves (ADR-0004). Run from the
// repository root:
//
//   swift run --package-path Tools/Codegen docs-check
//
// Scope: README.md, CHANGELOG.md, CONTRIBUTING.md, SECURITY.md and the top-level docs/*.md pages.

import Foundation

/// The four user-facing files at the repository root.
let rootFiles = ["README.md", "CHANGELOG.md", "CONTRIBUTING.md", "SECURITY.md"]

/// An inline link or image, with the destination in group 1.
let link = "!?\\[[^\\]]*\\]\\(([^()]*)\\)"

func fail(_ message: String) -> Never {
  print("docs-check: \(message)")
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

/// Drops inline code spans, so a link that is shown as code is not checked.
func strippingInlineCode(_ line: String) -> String {
  guard let regex = try? NSRegularExpression(pattern: "`[^`]*`") else { return line }
  let range = NSRange(line.startIndex..., in: line)
  return regex.stringByReplacingMatches(in: line, range: range, withTemplate: "")
}

/// Checks one file and appends one string per problem.
func check(_ path: String, relativeTo repository: URL, into problems: inout [String]) {
  let url = repository.appendingPathComponent(path)
  let text = readText(url.path)
  guard let linkRegex = try? NSRegularExpression(pattern: link) else {
    fail("cannot compile the link pattern")
  }
  let base = URL(fileURLWithPath: url.deletingLastPathComponent().path, isDirectory: true)

  var inFence = false
  for (index, line) in text.components(separatedBy: "\n").enumerated() {
    let number = index + 1
    if line.hasPrefix("```") || line.hasPrefix("~~~") {
      inFence.toggle()
      continue
    }
    if inFence { continue }

    if line.contains("\u{2014}") {
      problems.append("\(path):\(number): em dash (U+2014); use a colon, comma or parentheses")
    }

    let prose = strippingInlineCode(line)
    let proseRange = NSRange(prose.startIndex..., in: prose)

    for match in linkRegex.matches(in: prose, range: proseRange) {
      guard match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: prose) else {
        continue
      }
      // Strip spaces and the optional angle brackets Markdown allows around a destination.
      var destination = String(prose[range]).trimmingCharacters(in: .whitespaces)
      if destination.hasPrefix("<") && destination.hasSuffix(">") {
        destination = String(destination.dropFirst().dropLast())
      }
      if let fragment = destination.firstIndex(of: "#") {
        destination = String(destination[..<fragment])
      }
      if destination.isEmpty || destination.hasPrefix("/") || destination.contains("://")
        || destination.hasPrefix("mailto:")
      {
        continue
      }
      let resolved = URL(fileURLWithPath: destination, relativeTo: base).standardizedFileURL
      let rootPath = repository.standardizedFileURL.path
      guard
        resolved.path == rootPath || resolved.path.hasPrefix(rootPath + "/")
          || resolved.path.hasPrefix(rootPath + "\\")
      else {
        problems.append("\(path):\(number): link \(destination) leaves the repository")
        continue
      }
      if !FileManager.default.fileExists(atPath: resolved.path) {
        problems.append("\(path):\(number): link \(destination) does not resolve")
      }
    }
  }
}

func run() -> Int32 {
  let repository = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)

  var files = rootFiles
  let docs = repository.appendingPathComponent("docs", isDirectory: true)
  let pages = (try? FileManager.default.contentsOfDirectory(atPath: docs.path)) ?? []
  files += pages.filter { $0.hasSuffix(".md") }.sorted().map { "docs/\($0)" }

  var problems: [String] = []
  for path in files {
    check(path, relativeTo: repository, into: &problems)
  }

  guard problems.isEmpty else {
    for problem in problems { print("docs-check: \(problem)") }
    print("docs-check: \(problems.count) problems in \(files.count) files")
    return 1
  }
  print("docs-check: \(files.count) files, no em dash, every relative link resolves")
  return 0
}

exit(run())
