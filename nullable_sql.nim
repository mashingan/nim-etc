# problem question thread
# https://forum.nim-lang.org/t/4320

import options, strutils
from sequtils import map

import sugar

proc find(str: string, c, within: char, start = 0): (int, bool) =
  ## find whether the character not within specified within char
  let
    c1 = str.find(within, start = start)
    c2 = str.find(within, start = c1+1)
    pos = str.find(c, start = start)

  # not within `within` chars
  if c1 == -1 and c2 == -1 and pos != -1:
    result = (pos, true)
  # c in outer position
  elif (pos > c1 and pos > c2) or (pos < c1 and pos < c2):
    result = (pos, true)
  # c within position
  elif c1 < pos and pos < c2:
    result = (c2, false)


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
    found = false
  for arg in args:
    prevq = qpos
    while not found:
      (qpos, found) = query.find('?', '\'', start = qpos+1)
      if not found:
        builder &= query[prevq+1 .. qpos]
        prevq = qpos
    found = false
    if arg.isNone:
      builder &= query[prevq+1 .. qpos].replace("?", "NULL")
      continue
    outargs.add get(arg)
    builder &= query[prevq+1 .. qpos]

  # the left over string slice
  if qpos != -1 or qpos+1 < query.high:
    builder &= query[qpos+1 .. ^1]

  (builder, outargs)

var (q, args) = queryStr(
  "INSERT INTO table_name(name, age, info, question) VALUES(?, ?, ?, 'any question?');",
  none(string), some $19, some "is there any info?")
echo q
echo args

(q, args) = queryStr(
  "INSERT INTO table_name(name, age, question, info) VALUES(?, ?,'any question?', ?);",
  none(string), some $19, none string)
echo q
echo args
