when not defined(posix):
  {.error: "this example is only supported on posix".}

import std/[terminal, sugar]

proc open_memstream(buf: ptr cchar, size: ptr csize_t): File
  {.importc, header: "<stdio.h>".}

type
  BufFileStreamObj = object
    buf: cstring
    size: csize_t
    file: File

  BufFileStream = ref BufFileStreamObj

proc `=destroy`(bf: var BufFileStreamObj) =
  dealloc(addr bf.buf[0])
  close(bf.file)

proc newBufFile(): BufFileStream =
  new result
  result.buf = cast[cstring](alloc(0))
  result.size = 0
  result.file = open_memstream(addr result.buf[0], addr result.size)


proc main =
  var bf = newBufFile()
  var fakestdout = bf.file
  dump fakestdout.isatty
  fakestdout.styledWrite(fgRed, "red text")
  fakestdout.styledWrite(fgGreen, "green text")
  flushFile(fakestdout)
  dump bf.buf
  dump bf.size
  dump bf.buf.len

main()
