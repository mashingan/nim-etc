#[
# make sure we have proper Nim compiler in the path with
# $ nim -v (this should return a version of Nim compiler used)
#
# Then compile with:
# $ nim c -d:release -d:ssl downloadmanga
#
# if we don't have openssl installed, remove the -d:ssl option before
#
# To choose the version that simply parse the string, compile with:
# $ nim c -d:release -d:ssl -d:stringparse downloadmanga
#
# The string parse version should has better performance because it's
# only parse the page linearly instead of parse the entire xml
#
# There's additional peg parser version which yield cleaner page scraping
# compile it with:
# $ nim c -d:release -d:ssl -d:withpegs downloadmanga
#
# The different only withpegs optional compiling that omit downloading
# the image entirely
#
# Invoke the program with url in mangastream
# ./downloadmanga http://readms.net/r/one_piece/875/4493/1
#]#
import httpclient, htmlparser, os, xmltree, strutils, uri
when not defined(release):
  import sugar

when not defined(withpegs) and not defined(stringparse):
  {.error: "parsing xml version is not supported anymore.".}

when defined(withpegs):
  import pegs

if paramCount() < 1:
  quit "specify the url-path"

type
  MangaPage = object
    imgurl, nextlink: string

var
  client = newHttpClient()
  url = paramStr 1
  opt: string

proc restore(path: string): string =
  $url.parseUri.combine(path.parseUri)

proc process(url: string): seq[XmlNode] =
  client.get(url.restore).bodyStream.parseHtml.findAll "div"

proc getInfo(divs: seq[XmlNode]): MangaPage =
  result.nextlink = ""
  result.imgurl = ""
  for node in divs:
    if node.attr("class") == "page":
      result = MangaPage(
        nextlink: node.findAll("a")[0].attr("href"),
        imgurl: node.findAll("img")[0].attr("src")
      )
      break

when defined(withpegs):
  var
    base1 = peg"""@ 'div class="page">'"""
    thru1 = peg"""@ 'a href="' {@} '">'"""
    thru2 = peg"""@ 'src="' {@} '" ' .*$"""
    chapnum = peg"""@ '/r/' @ '/' {\d+} '/' .*$"""
    mangaparser = sequence(base1, thru1, thru2)

proc getInfo(link: string): MangaPage =
  when not defined(release):
    echo "restored link: ", link.restore
  when not defined(stringparse) and not defined(withpegs):
    let content = client.get(url.restore).bodyStream.parseHtml.findAll "div"
    result = content.getInfo
  else:
    let content = client.getContent link.restore
  result = MangaPage()
  when defined(withpegs):
    if content =~ mangaparser:
      var buff = newseq[string](2)
      discard content.find(mangaparser, buff)
      result.nextlink = buff[0]
      result.imgurl = buff[1]
      if buff[0] == "":
        return
      var
        currentChapter = @[""]
        nextchapter = @[""]
      discard link.find(chapnum, currentChapter)
      discard buff[0].find(chapnum, nextChapter)
      if currentChapter[0] != nextChapter[0]:
        result.nextlink = ""
  else:
    template chapterExtract(url: string): string =
      var starting = 3
      if url.startsWith "http:":
        starting += url.find("/r/") + 1

      let
        p1 = url.find("/", start = starting)
        p2 = url.find("/", start = p1+1)
      url[p1+1 .. p2-1]

    let
      classpage = "div class=\"page\">"
      thru1 = "a href=\""
      cap1 = "\">"
      thru2 = "src=\""
      cap2 = "\" "
      cppos = content.find(classpage)

    when not defined(release):
      dump cppos

    if cppos == -1:
      return
    let
      thr1found = content.find(thru1, cppos)
      cap1found = content.find(cap1, thr1found)
    when not defined(release):
      dump thr1found
      dump cap1found
    result.nextlink = content[thr1found+thru1.len .. cap1found-1]
    when not defined(release):
      dump result.nextlink
    if link.chapterExtract != result.nextlink.chapterExtract:
      when not defined(release):
        let
          currchap = link.chapterExtract
          nextchap = result.nextlink.chapterExtract
        dump link
        dump currchap
        dump nextchap
      result.nextlink = ""
      return
    let
      imgpos = content.find(thru2, cap1found)
      imgcp1 = content.find(cap2, imgpos)
    when not defined(release):
      dump imgpos
      dump imgcp1
    if imgpos == -1:
      return
    result.imgurl = content[imgpos+thru2.len .. imgcp1-1]
    when not defined(release): dump result.imgurl


if url.startsWith "https":
  opt = "https:"
else:
  opt = "http:"

while true:
  var page = getInfo url
  echo page
  if page.imgurl == "":
    break
  client.downloadFile(opt & page.imgurl, page.imgurl.split('/')[^1])
  if page.nextlink == "":
    break
  url = page.nextlink
