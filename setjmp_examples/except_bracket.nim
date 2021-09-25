import ../setjmp

var
  exceptionEnv: JmpBuf
  exceptionType: int

proc second()

proc first =
  var myenv: JmpBuf
  echo "entering first"
  exceptionEnv.deepCopy myenv

  case exceptionEnv.setjmp
  of 3:
    echo "second failed, exception type 3; remapping to type 1"
    exceptionType = 1

  of 1:
    echo "calling second"
    #second()
    echo "second succeeded"

  else:
    myenv.deepCopy exceptionEnv
    exceptionEnv.longjmp exceptionType

  myenv.deepCopy exceptionEnv
  echo "leaving first"

proc second =
  echo "entering second"
  #exceptionType = 3
  exceptionType = 1
  exceptionEnv.longjmp exceptionType
  echo "leaving second"

{.push stacktrace: off.}
proc main =
  if exceptionEnv.setjmp != 0:
    echo "first failed, exception type: ", exceptionType
  else:
    echo "calling first"
    first()

    echo "first succeeded"
{.pop.}

main()
