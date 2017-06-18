# Slice date string to be used in iterator
# Initial problem was asked in the forum https://forum.nim-lang.org/t/3005
# and this is the result of solution.

import times

iterator `..`*(ds1, ds2: string): TimeInfo =
  var
    d1 = ds1.parse("yyyy-MM-dd")
    d2 = ds2.parse("yyyy-MM-dd")
  
  var interval: TimeInterval
  # yield day-by-day
  if d1.monthday != d2.monthday:
    interval = initInterval(hours=24)
  # yield month-by-month
  else:
    interval = initInterval(months=1)

  while d1.toTime <= d2.toTime:
    yield d1
    d1 = d1 + interval

when isMainModule:
  echo "enumerate days"
  for dt in "2017-03-10" .. "2017-03-15":
    echo dt
  echo()

  echo "enumerate months"
  for dt in "2017-03-10" .. "2017-10-10":
    echo dt
  echo()
