import std/[asynchttpserver, asyncdispatch]


var server = newAsyncHttpServer()
proc cb(req: Request) {.async.} =
  echo "got request of path: ", req.url.path
  discard sleepAsync(500) # to emulate slow operation
  let responsetext = "Hello 異世界" & req.url.path
  await req.respond(Http200, responsetext)

echo "serving on port 3000"
waitFor server.serve(Port 3000, cb)
