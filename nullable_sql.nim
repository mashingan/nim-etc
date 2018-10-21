# problem question thread
# https://forum.nim-lang.org/t/4320

import options, strutils
from sequtils import map

proc queryStr(query: string, args: varargs[Option[string]]):
    (string, seq[string])  =
  ## Transform '?' in query string according to optioned arguments given
  if '?' notin query:
    return (query, args.map get)
  var
    qpos = -1
    prevq = -1
    builder = ""
    outargs = newseq[string]()
  for arg in args:
    prevq = qpos
    # still need to make sure it's skipped when ? within ''
    qpos = query.find('?', start = qpos+1)
    if qpos == -1:
      builder &= query[prevq+1 .. ^1]
      break
    if arg.isNone:
      builder &= query[prevq+1 .. qpos].replace("?", "NULL")
      continue
    outargs.add get(arg)
    builder &= query[prevq+1 .. qpos]

  # the left over string slice
  if qpos != -1 or qpos+1 < query.high:
    builder &= query[qpos+1 .. ^1]

  (builder, outargs)

let (q, args) = queryStr(
  "INSERT INTO table_name(name, age, info) VALUES(?, ?, ?);",
  none(string), some $19, some "info")

echo q
echo args
