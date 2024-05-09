# Slice date string to be used in iterator
# Initial problem was asked in the forum https://forum.nim-lang.org/t/3005
# and this is the result of solution.

import std/[times, strformat]

template iterdays(ds1, ds2: string, op: untyped): untyped =
  var
    d1 = ds1.parse("yyyy-MM-dd")
    d2 = ds2.parse("yyyy-MM-dd")
  
  var interval: TimeInterval
  # yield day-by-day
  if d1.monthday != d2.monthday:
    interval = initTimeInterval(hours=24)
  # yield month-by-month
  else:
    interval = initTimeInterval(months=1)

  while `op`(d1.toTime, d2.toTime):
    yield d1
    d1 = d1 + interval

iterator `..`*(ds1, ds2: string): DateTime =
  iterdays(ds1, ds2, `<=`)

iterator `..<`*(ds1, ds2: string): DateTime =
  iterdays(ds1, ds2, `<`)

when isMainModule:
  let
    startday = "2017-03-10"
    endday = "2017-03-15"
    startmonth = "2017-03-10"
    endmonth = "2017-10-10"
  echo fmt"enumerate days {startday} .. {endday}"
  for dt in startday .. endday:
    echo dt
  echo()

  echo fmt"enumerate months {startmonth} .. {endmonth}"
  for dt in startmonth .. endmonth:
    echo dt
  echo("==============")
  echo fmt"enumerate days {startday} ..< {endday}"
  for dt in startday ..< endday:
    echo dt
  echo()

  echo fmt"enumerate months {startmonth} ..< {endmonth}"
  for dt in startmonth ..< endmonth:
    echo dt
