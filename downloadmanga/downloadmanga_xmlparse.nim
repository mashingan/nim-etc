import httpclient, strutils, uri, os
import asyncdispatch, streams, parsexml, times, strformat
import sugar

type
  MangaPage = object
    imgurl, nextlink: string

proc restore(url, path: string): string =
  $url.parseUri.combine(path.parseUri)

proc getInfo(initurl, url: string): Future[MangaPage] {.async.} =
  let
    client = newAsyncHttpClient()
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

proc download(opt, imgurl: string): Future[void] {.async.} =
  let client = newAsyncHttpClient()
  let fname = imgurl.rsplit('/', 1)[^1]
  client.onProgressChanged = (proc(t, p, s: BiggestInt) {.async.} =
    echo fmt"writing {fname} with size {t}"
  )
  try:
    await client.downloadFile(opt & imgurl, fname)
  except:
    echo "Cannot download ", imgurl
    #echo getCurrentExceptionMsg()

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
  let url = paramStr 1
  let opt = if url.startsWith "https": "https:"
            else: "http:"
  let currentChapter = extractChapter url
  let starttime = cpuTime()
  var futuredownloads = newseq[Future[void]]()
  var page = MangaPage(nextlink: url)
  while true:
    page = await url.getInfo(page.nextlink)
    echo page
    futuredownloads.add download(opt, page.imgurl)
    if page.nextlink == "" or
       extractChapter(page.nextlink) == -1 or
       extractChapter(page.nextlink) != currentChapter:
      break
  await all(futuredownloads)
  echo "ended after: ", cpuTime() - starttime

waitFor main()
