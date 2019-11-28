# rosetta page ref
#http://rosettacode.org/wiki/Tokenize_a_string_with_escaping
import streams

proc tokenzie(s: Stream, sep: static[char] = '|', esc: static[char] = '^'): seq[string] =
  var buff = ""
  while not s.atEnd():
    let c = readChar s
    case c
    of sep:
      result.add buff
      buff = ""
    of esc:
      buff.add s.readChar
    else:
      buff &= c
  result.add buff

for i, s in tokenzie(newStringStream "one^|uno||three^^^^|four^^^|^cuatro|"):
    echo i, ":", s
