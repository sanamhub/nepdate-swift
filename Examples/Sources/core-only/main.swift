import NepDate

// Builds, formats and parses one date with only the core product. The release binary must not
// contain the string `World Day Against Human Trafficking` (ADR-0004 gate 6), which proves no
// patro data is linked.
do {
  let date = try NepaliDate(year: 2081, month: 4, day: 15)
  print(date.format("s"))
  print(date.long(weekday: true))
  print(try NepaliDate.parse("2081-04-15").description)
} catch {
  print("error: \(error)")
}
