# rosetta page
#http://rosettacode.org/wiki/Decision_tables

import tables
from strformat import `&`
type
  LightState = enum
    Light1 Light2 Light3 Light4 Light5 Light6 Light7 Light8
  LightInfo = set[LightState]

template `as`(a, b: untyped): untyped =
  cast[b](a)

const
  # actions
  powerCable = {Light3}
  printerCable = {Light1, Light3}
  printerSoftware = {Light1, Light3, Light5, Light7}
  checkInk = {Light1, Light2, Light6}
  checkPaper = {Light2, Light4}

let
  condTable = {
    "printer not printing": {Light1, Light2, Light3, Light4},
    "red light flashing": {Light3, Light4, Light7, Light8},
    "printer unrecognized": {Light1, Light3, Light5, Light7}}.toTable

  actionsTable = {
    powerCable as uint8: "Check the power cable.",
    printerCable as uint8: "Check the printer-computer cable.",
    printerSoftware as uint8: "Ensure the software is installed.",
    checkInk as uint8: "Check/replace ink.",
    checkPaper as uint8: "Check for paper jam."
    }.toTable

proc main =
  var lights: LightInfo
  for k, v in condTable:
    var input = '\0'
    while input != 'y' and input != 'n':
      stdout.write &"Is {k} ([y]es or [n]o)? "
      input = stdin.readChar
      stdin.flushFile
      if input notin "yn":
        echo &"only 'y' or 'n', but got '{input}' inputted"
    if input == 'y':
      lights = lights + v

  echo lights
  let sympton = lights as uint8
  var hasproblem = false
  for k, v in actionsTable:
    #if k <= sympton:
    if (k as LightInfo) <= lights:
      hasproblem = true
      echo v

  if not hasproblem:
    echo "No action/problem detected!"

main()
