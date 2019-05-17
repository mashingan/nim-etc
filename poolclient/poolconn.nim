import std/[deques, asyncdispatch, httpclient, tables, math, times]

type
  Pool = ref object
    conns: TableRef[int, AsyncHttpClient]
    available: Deque[int]

method getConn(p: Pool): Future[(int, AsyncHttpClient)] {.base, async.} =
  while true:
    if p.available.len != 0:
        let id = p.available.popLast
        return (id, p.conns[id])
    else:
        #discard sleepAsync 100
        try:
          poll(100)
        except:
          discard

method returnConn(p: Pool, id: int) {.base.} =
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

proc main {.async.} =
  let opsSize = 8
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

let start = cpuTime()
waitFor main()
echo "ended after: ", cpuTime() - start
