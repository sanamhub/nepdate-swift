import NepDate
import NepDatePatro

// Prints the patro info of 2081-01-01. Linking NepDatePatro pulls the whole name table into the
// release binary, so gate 6 finds `World Day Against Human Trafficking` in it.
let date = (try? NepaliDate(year: 2081, month: 1, day: 1)) ?? .min
let info = date.calendarInfo
print(info.tithi?.english ?? "no tithi")
for event in info.events {
  print(event.english)
}
