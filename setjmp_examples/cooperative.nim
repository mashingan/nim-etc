import ../setjmp

var mainTask, childTask: JmpBuf

proc child()

proc callWithCushion =
  var space: array[1000, char]
  space[space.high] = 'a'
  child()


proc child =
  while true:
    echo "child loop begin"
    if childTask.setjmp == 0:
      mainTask.longjmp 1

    echo "child loop end"
    if childTask.setjmp == 0:
      mainTask.longjmp 1

{.push stacktrace: off.}
proc main =
  if mainTask.setjmp == 0:
    callWithCushion()

  while true:
    echo "parent"
    if mainTask.setjmp == 0:
      childTask.longjmp 1
{.pop.}

main()
