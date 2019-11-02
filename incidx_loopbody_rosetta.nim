# rosetta page
#http://rosettacode.org/wiki/Loops/Increment_loop_index_within_loop_body

import strformat
from strutils import join, insertSep
from algorithm import reverse

func isPrime(i: int): bool =
  if i == 2 or i == 3: return true
  elif i mod 2 == 0 or i mod 3 == 0: return false
  var idx = 5
  while idx*idx <= i:
    if i mod idx == 0: return false
    idx.inc 2
    if i mod idx == 0: return false
    idx.inc 4
  result = true

# no local format integer so need to add the function to do so
func distribute(s: string, count: int): seq[string] =
  var
    buff = ""
    idx = 0
  for i in countdown(s.len-1, 0):
    buff = s[i] & buff
    inc idx
    if idx mod count == 0:
      result.add buff
      buff = ""
  if buff != "": # the left over
    result.add buff
  reverse result

const limit = 42
proc main =
  var
    i = 42
    n = 0
  while n < limit:
    if i.isPrime:
      inc n
      echo &"""n {n:>2} = {($i).insertSep(sep = ','):>19}"""
      i.inc i
      continue
    inc i

main()
