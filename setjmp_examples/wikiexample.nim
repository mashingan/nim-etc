import ../setjmp

setControlCHook(proc() {.noconv.} =
  echo "exiting application"
  quit QuitFailure
)

var buf: JmpBuf

proc second =
  echo "second"
  longjmp(buf, 1)

proc first =
  second()
  echo "first"

{.push stacktrace: off.}
proc main =
  if buf.setjmp != 1:
    first()
  else:
    echo "main"
{.pop.}

main()
