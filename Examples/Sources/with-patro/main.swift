import NepDate
import NepDatePatro

let date = (try? NepaliDate(year: 2081, month: 1, day: 1)) ?? .min
let info = date.calendarInfo
print(info.tithi?.english ?? "no tithi")
for event in info.events {
  print(event.english)
}
