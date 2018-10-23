import jester, asyncdispatch, json, strutils,
       times, sets, htmlgen, strtabs, httpcore

var
  visitors = 0
  uniques = initSet[string]()
  time: TimeInfo

settings:
  staticDir = "./statics"
  port = Port 3000

routes:
  get "/":
    resp body(
      `div`(id="info"),
      script(src="/client.js", `type`="text/javascript"),
      script(src="/visitors", `type`="text/javascript"))

  get "/client.js":
    const reslt = staticExec "nim -d:release js client"
    const clientjs = staticRead "nimcache/client.js"
    resp clientjs

  get "/visitors":
    let newtime = getTime().getLocalTime
    if newtime.monthDay != time.monthDay:
      visitors = 0
      init uniques
      time = newtime
    inc visitors
    let ip =
      if request.headers.hasKey "X-Forwarded-For":
        request.headers["X-Forwarded-For", 0]
      else:
        request.ip
    uniques.incl ip

    let json = %* {
      "visitors": visitors,
      "uniques": uniques.len,
      "ip": ip
    }
    resp "printInfo($#)".format(json)

runForever()
