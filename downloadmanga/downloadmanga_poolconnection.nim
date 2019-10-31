# to compile:
# nim c -d:danger -d:ssl --threads:on -o:c:/bin/downloadmanga.exe downloadmanga_poolconnection.nim
import httpclient, strutils, uri, os, osproc
import asyncdispatch, streams, parsexml, times, strformat
import sugar, math, deques, options, tables, asyncfile
import threadpool

const zip7exe = "\"C:\\Program Files\\7-zip\\7z.exe\""

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
  for i in 1 .. newsize:
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

proc download(pool: Pool, opt, chapnum, imgurl: string): Future[void] {.async.} =
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
  createDir chapnum
  echo fmt"downloading with conn id: {idConn}"
  var fname = imgurl.rsplit('/', 1)[^1]
  let (_, name, ext) = fname.splitFile
  if name.len > 2 and ext != "jpg":
    fname = name[0 .. 1].addFileExt ext
  let dirn = chapnum / fname

  try:
    file = openAsync(dirn, fmWrite)
    await file.write(await client.getContent opt & imgurl)
    echo fmt"downloaded {fname} with size {file.getFileSize}"
  except OSError:
    echo fmt"id {idConn} failed to open {dirn}"
    echo getCurrentExceptionMsg()
  except:
    echo "Cannot download ", imgurl
    echo getCurrentExceptionMsg()
  finally:
    pool.returnConn idConn
    if not file.isNil:
      close file

proc extractChapter(url: string): int =
  let
    rpos = url.find("/r/")
    nextslash = url.find("/", start=rpos+3)
    chap = url[nextslash+1 .. url.find("/", start=nextslash+1)-1]
  result = try: parseInt chap
           except: -1

proc zip(parentdir: string; chap: int) =
  let cmd = zip7exe & fmt""" a "{parentdir} - {$chap} [Mangastream].zip"  {$chap}"""
  echo cmd
  let res = execCmd(cmd)
  if res == 0:
    removeDir $chap

proc main =
  if paramCount() < 1:
    quit "Specify the url"
  let
    url = paramStr 1
    dirname = getCurrentDir().lastPathPart
    opt = if url.startsWith "https": "https:"
          else: "http:"
    poolsize =
      if paramCount() > 1:
        try: paramStr(2).parseInt
        except: 4
      else: 4
  var
    lastchap = extractChapter url
    workedchaps = newseq[int]()
  echo fmt"the pool size is {poolsize}"
  var
    pool = initPool(poolsize)
    client = newAsyncHttpClient()
    futuredownloads = newseq[Future[void]]()
    page = MangaPage(nextlink: url)
    starttime = cpuTime()
  echo page
  while true:
    page = waitFor client.getInfo(url, page.nextlink)
    echo page
    let nextchap = page.nextlink.extractChapter
    futuredownloads.add pool.download(opt, $lastchap, page.imgurl)
    if page.nextlink == "" or nextchap == -1:
      break
    elif nextchap notin workedchaps:
      workedchaps.add nextchap
    lastchap = nextchap
  waitFor all(futuredownloads)
  echo "ended after: ", cpuTime() - starttime
  for chap in workedchaps:
    spawn(dirname.zip chap)
  sync()

main()
