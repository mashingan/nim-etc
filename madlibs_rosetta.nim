#[
#rosetta-code task: http://rosettacode.org/wiki/Mad_Libs
#Almost same with current solution with different on using pegs instead of re
#]#
import pegs, strtabs, strformat, strutils, rdstdin

let strtmpl = """<name> went for a walk in the park. <he or she>
found a <noun>. <name> decided to take it home"""

echo "The story template is\n", strtmpl, "\n"
var replacer = newStringTable()
for matched in strtmpl.findAll peg"\<[^>]+\>":
  if matched in replacer: continue
  replacer[matched] = fmt"replacer for {matched}: ".readLineFromStdin.strip

var newstr = strtmpl
for k,v in replacer:
  newstr = newstr.replace(k, v)

echo "\nThe story becomes:\n"
echo newstr
