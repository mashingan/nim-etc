# initial question page:
#https://www.reddit.com/r/nim/comments/ivmruj/question_regarding_macros/
import macros, sugar

type
    Entity1 = object
        i: int
        s: string

    Entity2 = object
        i: int
        c: char

# note that I simplified the procs definition to not accept any argument
# this is to simplify the example, in case you want to specific argument checking,
# you can always `getImpl` or `getTypeImpl` on it to find out its
# implementation. Or maybe just matching the procs name to specifically calling
# it with each argument definition.
proc hook1(e: Entity1) =
    echo "Hi, ", e.s

proc hook2[T: Entity1|Entity2](e: T) =
    echo "Howdy, ", e.i

proc hook3(e: Entity2) =
    echo "Yo, ", e.c

template check(n: NimNode) =
  echo "=======+++======="
  dump n.kind
  dump n.len
  dump n.repr

macro hook(h: untyped, fn: untyped): untyped =
  let fnbody = fn[^1]
  var newbody = newStmtList()
  let formalParams = fn[3]
  let argsParams = formalParams[1..^1]
  let fnArg = if argsParams.len > 0: argsParams[0][0]
              else: newEmptyNode()
  check fnArg
  for hook in h:
    if fnArg.kind != nnkEmpty:
      let whenstmt = quote do:
        when compiles(`fnArg`.`hook`): `fnArg`.`hook`
      newbody.add whenstmt
      #newbody.add newCall(hook)
  newbody.add fnbody
  fn[^1] = newbody
  result = fn
  check result

proc processA(e: Entity1) {.hook: [hook1, hook2, hook3].} =
  echo "start processA"

proc processB(e: Entity2) {.hook: [hook1, hook2, hook3].} =
  echo "start processB"


let e1 = Entity1(i: 5, s: "five")
let e2 = Entity2(i: 42, c: 'h')
processA(e1)
processB(e2)
