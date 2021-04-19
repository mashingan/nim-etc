const header = "<setjmp.h>"
type JmpBuf* {.header: header, importc: "jmp_buf".} = object

when defined(windows) and defined(gcc):
  proc setjmp*(buf: var JmpBuf): int
    {. header:header, importc: "__builtin_setjmp".}
  proc longjmp*(buf: JmpBuf, ret = (-1))
    {. header:header, importc: "__builtin_longjmp".}

else:
  proc setjmp*(buf: var JmpBuf): int {.header:header, importc: "setjmp".}
  proc longjmp*(buf: JmpBuf, ret = (-1)) {.header:header, importc: "longjmp".}
