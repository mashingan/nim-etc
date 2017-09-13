#[
# make sure we have proper Nim compiler in the path with
# $ nim -v (this should return a version of Nim compiler used)
#
# Then compile with:
# $ nim c -d:release -d:ssl downloadmanga
#
# if we don't have openssl installed, remove the -d:ssl option before
#
# Invoke the program with url in mangastream
# ./downloadmanga http://readms.net/r/one_piece/875/4493/1
#]#
import httpclient, htmlparser, os, xmltree, strutils

if paramCount() < 1:
  quit "specify the url-path"

type
  MangaPage = object
    imgurl, nextlink: string

var
  url = paramStr 1
  opt: string

proc process(url: string): seq[XmlNode] =
  var client = newHttpClient()
  result = client.get(url).bodyStream.parseHtml.findAll "div"
  client.close

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

if url.startsWith "https":
  opt = "https:"
else:
  opt = "http:"

var page = process(url).getInfo
while page.nextlink != "":
  var client = newHttpClient()
  client.downloadFile(opt & page.imgurl, page.imgurl.split('/')[^1])
  echo page
  page = process(page.nextlink).getInfo
