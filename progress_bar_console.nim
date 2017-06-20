# The snippet to answer question in the forum
# https://forum.nim-lang.org/t/3009

import strutils, terminal
from os import sleep

proc showBar(content: string) =
  stdout.eraseLine
  stdout.write("[$1]" % [content])
  stdout.flushFile

var content = ' '.repeat 10
for progress in 0 ..< 10:
  content[progress] = '#'
  sleep 100
  showBar content
