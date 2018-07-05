## This macro is additional modification from my thread asking on how
## to expand the defined Proc Type
## I modified and improve the answer from @mratsim here
## https://forum.nim-lang.org/t/4012#24965
## and now able to support exported procs definition

import macros

type
  Handler = proc(x: int): int

macro function_impl(head: untyped, handlertype: typed, body: untyped):
    untyped =
  var
    handlerimpl = handlertype.symbol().getImpl()
    thefunc = newNimNode nnkProcDef
    params = newSeq[NimNode]()

  for node in handlerimpl[2][0]:
    params.add node
  result = newProc(name = head,
    params = params,
    body = body)


macro function*(head_oftype, body: untyped): untyped =
  head_oftype.expectKind nnkInfix
  echo "head_oftype: ", head_oftype.repr
  echo "head_len: ", head_oftype.len

  var head, oftype: NimNode
  case $head_oftype[0]
  of "*":
    head = head_oftype[1].postfix "*"
    oftype = head_oftype[2].basename
  of "of":
    head = head_oftype[1]
    oftype = head_oftype[2]

  result = quote do: function_impl(`head`, `oftype`, `body`)

function handleThis* of Handler:
  x * 10

when isMainModule:
  echo handleThis(5)
