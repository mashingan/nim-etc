const header = "<setjmp.h>"
type JmpBuf* {.header: header, importc: "jmp_buf".} = object


proc setjmp*(buf: var JmpBuf): int {.header:header, importc: "setjmp".}
proc longjmp*(buf: JmpBuf, ret = (-1)) {.header:header, importc: "longjmp".}
