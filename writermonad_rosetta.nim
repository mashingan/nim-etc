# rosetta page
#https://rosettacode.org/wiki/Monads/Writer_monad

from math import sqrt
from sugar import `=>`

type
  WriterUnit = (float, string)
  WriterBind = proc(a: WriterUnit): WriterUnit

proc bindWith(f: proc(x: float): float; log: string): WriterBind =
  result = (proc(a: WriterUnit): WriterUnit =
    (f(a[0]), a[1] & log)
  )

var
  logRoot = sqrt.bindWith "obtained square root, "
  logAddOne = ((x: float) => x+1'f).bindWith "added 1, "
  logHalf = ((x: float) => x/2'f).bindWith "divided by 2, "

echo (5.0, "").logRoot.logAddOne.logHalf
