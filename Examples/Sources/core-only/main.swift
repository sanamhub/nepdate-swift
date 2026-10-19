import NepDate

do {
  let date = try NepaliDate(year: 2081, month: 4, day: 15)
  print(date.format("s"))
  print(date.long(weekday: true))
  print(try NepaliDate.parse("2081-04-15").description)
} catch {
  print("error: \(error)")
}
