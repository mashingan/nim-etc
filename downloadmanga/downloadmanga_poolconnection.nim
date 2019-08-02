import httpclient, strutils, uri, os
import asyncdispatch, streams, parsexml, times, strformat
import sugar, math, deques, options, tables, asyncfile

type
  MangaPage = object
    imgurl, nextlink: string

  Pool = ref object
    available: Deque[int]
    conns: TableRef[int, AsyncHttpClient]

proc initPool(size = 16): Pool =
  new result
  let newsize = nextPowerOfTwo size
  result.available = initDeque[int](newsize)
  result.conns = newTable[int, AsyncHttpClient](newsize)
  for i in 1 ..< newsize:
    result.available.addFirst i
    result.conns[i] = newAsyncHttpClient()

proc getConn(pool: Pool): (int, Option[AsyncHttpClient]) =
  if pool.available.len == 0:
    result = (-1, none AsyncHttpClient)
  else:
    #some pool.available.popLast
    let id = pool.available.popLast
    result = (id, some pool.conns[id])

proc returnConn(pool: Pool, connId: int) =
  pool.available.addFirst connId

proc restore(url, path: string): string =
  $url.parseUri.combine(path.parseUri)

proc getInfo(client: AsyncHttpClient, initurl, url: string):
    Future[MangaPage] {.async.} =
  let
    asyncrep = await client.get initurl.restore(url)
    body = newStringStream(await asyncrep.body)
  var x: XmlParser
  open(x, body, "dummyerr.log")
  while true:
    x.next()
    case x.kind
    of xmlElementOpen:
      if x.elementName == "div":
        x.next()
        if x.kind == xmlAttribute and
            x.attrKey == "class" and
            x.attrValue == "page":
          for _ in 1 .. 3: x.next
          result.nextlink = x.attrValue
          for _ in 1 .. 4: x.next
          result.imgurl = x.attrValue
          return

    of xmlError:
      echo x.errorMsg
      x.next()
    of xmlEof: break
    else: discard

proc download(pool: Pool, opt, imgurl: string): Future[void] {.async.} =
  var
    client: AsyncHttpClient
    idConn: int
    optval: Option[AsyncHttpClient]
    file: AsyncFile
  while true:
    (idConn, optval) = pool.getConn
    if optval.isNone:
      try: poll(10)
      except: echo getCurrentExceptionMsg()
    else:
      client = get optval
      break
  echo fmt"downloading with conn id: {idConn}"
  let fname = imgurl.rsplit('/', 1)[^1]
  file = openAsync(fname, fmWrite)
  try:
    await file.write(await client.getContent opt & imgurl)
    #echo fmt"downloaded {fname} with size {file.getFileSize}"
  except:
    echo "Cannot download ", imgurl
    #echo getCurrentExceptionMsg()
  finally:
    pool.returnConn idConn
    #close file

proc extractChapter(url: string): int =
  let
    rpos = url.find("/r/")
    nextslash = url.find("/", start=rpos+3)
    chap = url[nextslash+1 .. url.find("/", start=nextslash+1)-1]
  result = try: parseInt chap
           except: -1

proc main {.async.} =
  if paramCount() < 1:
    quit "Specify the url"
  let
    url = paramStr 1
    opt = if url.startsWith "https": "https:"
          else: "http:"
    currentChapter = extractChapter url
    poolsize =
      if paramCount() > 1:
        try: paramStr(2).parseInt
        except: 4
      else: 4
  echo fmt"the pool size is {poolsize}"
  var
    pool = initPool(poolsize)
    client = newAsyncHttpClient()
    futuredownloads = newseq[Future[void]]()
    page = MangaPage(nextlink: url)
    starttime = cpuTime()
  while true:
    page = await client.getInfo(url, page.nextlink)
    echo page
    futuredownloads.add pool.download(opt, page.imgurl)
    if page.nextlink == "" or
       extractChapter(page.nextlink) == -1 or
       extractChapter(page.nextlink) != currentChapter:
      break
  await all(futuredownloads)
  echo "ended after: ", cpuTime() - starttime

waitFor main()
