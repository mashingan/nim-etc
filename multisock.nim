# macro example for creating a function which both operates on Socket
# and AsyncSocket. multisock pragma and async pragma cannot be mixed together

import macros, asyncnet, asyncdispatch, strutils, sugar, net

{.hint[XDeclaredButNotUsed]: off.}

template inspect(n: untyped) =
  echo "========="
  dump `n`.kind
  dump `n`.len
  dump `n`.repr
  echo "========="

proc removeAwaitAsyncCheck(n: var NimNode) =
  if n.len < 1: return
  case n.kind
  of nnkEmpty: discard
  of nnkVarSection, nnkLetSection:
    for i, section in n:
      var nn = n[i]
      removeAwaitAsyncCheck nn
      n[i] = nn
  of nnkCommand:
    if n[0].kind != nnkDotExpr and $n[0] in ["await", "asyncCheck"]:
      n = newStmtList(n[1..^1])
  of nnkAsgn:
    var nn = n[1]
    removeAwaitAsyncCheck nn
    n[1] = nn
  of nnkOfBranch, nnkElse:
    var nn = n[^1]
    removeAwaitAsyncCheck nn
    n[^1] = nn
  else:
    for i in 0..<n.len:
      var child = n[i]
      removeAwaitAsyncCheck child
      n[i] = child

macro multisock*(prc: untyped): untyped =
  ## multisock macro operates on async proc definition
  ## with first param is AsyncSocket and returns Future
  ## which then creating the sync version of the function
  ## overload by removing `await` and `asyncCheck`
  let prcsync = prc.copy
  let syncparam = prcsync[3]
  if syncparam.kind != nnkEmpty:
    syncparam[0] = syncparam[0][1]
    for i in 1..<syncparam.len:
      let socksync = syncparam[i]
      if $socksync[1] == "AsyncSocket":
        socksync[1] = ident "Socket"
  var prcbody = prcsync[^1]
  prcbody.removeAwaitAsyncCheck
  if prc[^3].kind != nnkEmpty:
    prc[^3].add(ident "async")
  else:
    prc[^3] = quote do: {.async.}
  inspect prcsync
  inspect prc
  result = quote do:
    `prcsync`
    `prc`


proc myp(sock: AsyncSocket): Future[int] {.multisock.} =
  let
    msg1 = await sock.recv(5)
    msg2 = await sock.recv(5)
    msg3 = await sock.recv(5)
    msg4 = await sock.recv(5)
  asyncCheck sock.send("haha")
  for m in [msg1, msg2, msg3, msg4]:
    let val = try: parseInt(m) except: 0 
    result += val


proc casestry(sock: AsyncSocket): Future[int] {.multisock.} =
  let cmd = await sock.recv(1)
  if cmd.len < 1:
    result = 0
    return
  case cmd[0]
  of '0':
    result = 0
  of '1':
    result = await sock.myp
  else:
    result = await sock.myp

proc main(s: AsyncSocket): Future[void] {.multisock.} =
  discard

proc emptyArg: Future[void] {.multisock.} = discard

type
  Dummy = object

template dummy1() {.pragma.}
template dummy2(key: string) {.pragma.}

proc randomAsyncSocketArgpos(arg1: int, arg2: float,
  sock: AsyncSocket): Future[Dummy] {.multisock, inline, dummy1, dummy2("dummy2").} =
  asyncCheck sock.send("dum-dum-dummy")
  discard await sock.casestry
  result = Dummy()
