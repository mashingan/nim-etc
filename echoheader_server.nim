import asynchttpserver, asyncdispatch
from strutils import join
from tables import `$`, pairs
from json import `$`, `[]=`, newJObject, newJString

var server = newAsyncHttpServer()
proc cb(req: Request) {.async.} =
  var content = newJObject()
  echo "method: ", $req.reqMethod
  echo "hostname: ", req.hostname
  echo "url: ", req.url
  echo "body: ", req.body
  echo "protocol: ", req.protocol
  content["method"] = ($req.reqMethod).newJString
  echo "filling headers"
  for header, value in req.headers.table.pairs:
    content[header] = value.join(", ").newJString
  let msg = $content
  echo "json content: ", msg
  let headers = newHttpHeaders([
    ("Content-Type", "application/json")
  ])
  await req.respond(Http200, msg, headers)


echo "server is waiting at port 3000"
waitFor server.serve(Port 3000, cb)
