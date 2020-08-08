# need nim > 1.2 because of the fix in asynchttpserver to avoid crash
# when reading the nil headers
# by default the opssize is 8 but we can define during compile for
# different opssize value e.g.:
# nim c -d:opssize=64 poolconn.nim
# for trying 64 operations

import std/[deques, asyncdispatch, httpclient, tables, math, times,
            asynchttpserver]
import sugar

type
  Pool = ref object
    conns: TableRef[int, AsyncHttpClient]
    available: Deque[int]

proc getConn(p: Pool): Future[(int, AsyncHttpClient)] {.async.} =
  var count = 0
  while true:
    if p.available.len != 0:
        let id = p.available.popLast
        return (id, p.conns[id])
    else:
        #discard sleepAsync 100
        try: poll(100)
        except:
          dump count
          inc count

proc returnConn(p: Pool, id: int) =
  p.available.addFirst id

proc newPool(size: int): Pool =
  new result
  result.conns = newTable[int, AsyncHttpClient](size)
  result.available = initDeque[int](size)
  for i in 0 ..< size:
    result.conns[i] = newAsyncHttpClient()
    result.available.addLast i

proc ops(pool: Pool, conn: AsyncHttpClient, id, count: int): Future[string] {.async.} =
  result = await conn.getContent("http://localhost:3000/" & $count)
  pool.returnConn id

proc main (ser: AsyncHttpServer) {.async.} =
  const opsSize {.intdefine.} = 8
  var pool = newPool((opsSize div 2).nextPowerOfTwo)
  var clientops = newseq[Future[string]]()
  #var clientops = newseq[string]()
  for i in 1 .. opsSize:
    echo "ops: ", i
    let (id, conn) = await pool.getConn
    #clientops.add(await pool.ops(conn, id, i))
    clientops.add(pool.ops(conn, id, i))
    #echo await pool.ops(conn, id, i)

  discard await all(clientops)
  ser.close()

var server = newAsyncHttpServer()
proc cb(req: Request) {.async.} =
  echo "got request of path: ", req.url.path
  let slowsleep = sleepAsync(500) # to emulate slow operation
  await slowsleep

  let responsetext = "Hello 異世界" & req.url.path
  await req.respond(Http200, responsetext)
  echo "response finished: ", req.url.path

proc serveop =
  let poolops = [server.serve(Port 3000, cb), main(server)]
  asyncCheck poolops[0]
  waitfor poolops[1]

let start = cpuTime()
serveop()
echo "ended after: ", cpuTime() - start
