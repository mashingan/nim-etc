import httpclient, htmlparser, xmltree, strutils, uri, os
import asyncdispatch, sequtils

type
  MangaPage = object
    imgurl, nextlink: string

proc restore(url, path: string): string =
  $url.parseUri.combine(path.parseUri)

proc getInfo(initurl, url: string): Future[MangaPage] {.async.} =
  let
    client = newAsyncHttpClient()
    asyncrep = await client.get initurl.restore(url)
    divs = (await asyncrep.body).parseHtml.findAll "div"

  result.nextlink = ""
  result.imgurl = ""
  for node in divs:
    if node.attr("class") == "page":
      result = MangaPage(
        nextlink: node.findAll("a")[0].attr("href"),
        imgurl: node.findAll("img")[0].attr("src")
      )
      break

proc download(opt, imgurl: string): Future[void] {.async.} =
  var client = newAsyncHttpClient()
  client.headers = newHttpHeaders(
    { "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.106 Safari/537.36 OPR/38.0.2220.41"})
  try:
    let filename = imgurl.split('/')[^1]
    await client.downloadFile(opt & imgurl, filename)
    echo "downloaded: ", filename
  except:
    echo "Cannot download ", imgurl
    #echo getCurrentExceptionMsg()

proc extractChapter(url: string): int =
  let
    rpos = url.find("/r/")
    nextslash = url.find("/", start=rpos+3)
    chap = url[nextslash+1 .. url.find("/", start=nextslash+1)-1]
  if chap.all isDigit:
    result = try: parseInt chap
             except: -1
  else:
    result = -1

proc main {.async.} =
  if paramCount() < 1:
    quit "Specify the url"
  let url = paramStr 1
  let opt = if url.startsWith "https": "https:"
            else: "http:"
  let currentChapter = extractChapter url
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

waitFor main()
