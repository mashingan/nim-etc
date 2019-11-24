# rosettacode page task
#http://rosettacode.org/wiki/Finite_state_machine
# but not submitted to the rosettacode
from strutils import toLowerAscii
from strformat import `&`
type State = enum
  Ready Waiting Exit Dispense Refunding

proc select(s: State): State =
  result = Dispense
  echo &"{s} -> select -> {result}"

proc refund(s: State): State =
  result = Refunding
  echo &"{s} -> refund -> {result}"

proc deposit(s: State): State =
  result = Waiting
  echo &"{s} -> deposit -> {result}"

proc quit(s: State): State =
  result = Exit
  echo &"{s} -> quit -> {result}"

proc remove(s: State): State =
  result = Ready
  echo &"{s} -> remove -> {result}"

proc fsm =
  var state = Ready
  while state != Exit:
    case state
    of Ready:
      stdout.write "[d]ispense or [q]uit? "
      let input = stdin.readChar.toLowerAscii
      stdin.flushFile
      case input
      of 'd': state = state.deposit
      of 'q': state = state.quit
      else: echo "invalid input: ", input
    of Exit: discard
    of Waiting:
      stdout.write "[s]elect or [r]efund? "
      let input = stdin.readChar.tolowerAscii
      stdin.flushFile
      case input
      of 's': state = state.select
      of 'r': state = state.refund
      else: echo "invalid input: ", input
    of Dispense:
      state = state.remove
    of Refunding:
      # implicit transition
      echo &"{state} -> Ready"
      state = Ready

fsm()
