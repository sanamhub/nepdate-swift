import NepDate

// A driver for the B5 allocation profile. The checksum keeps the work observable, so the
// optimizer cannot drop it. The operation count is the first argument.
let operations = CommandLine.arguments.count > 1 ? (Int(CommandLine.arguments[1]) ?? 10_000) : 10_000
let date = try! NepaliDate(year: 2081, month: 4, day: 15)
var total = 0
for _ in 0..<operations {
  total += date.long(weekday: true, lang: .nepali).utf8.count
}
print(total)
