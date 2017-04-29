import terminal
from strutils import NewLines

proc getpasswd*(prompt: string, strlen = 30, outh = stdout): string =
  ## Shadow the input from command line console after printing the prompt
  ## to the file handle.
  outh.write prompt
  result = ""
  for i in 0..<strlen:
    let c = getch()
    if c in NewLines:
      break
    result &= c

proc main() =
  var passwd = getpasswd("Type something: ")
  echo "\nYou typed: ", passwd
  addQuitProc resetAttributes

when isMainModule:
  main()
