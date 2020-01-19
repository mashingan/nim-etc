# ref forum post:
#https://forum.nim-lang.org/t/5829
import os, jester, asyncdispatch, htmlgen, asyncfile, asyncstreams, streams
import strutils
import ws, ws/jester_extra

settings:
  port = Port 3000

routes:
  get "/":
    var html = """
    <script>
    function submit_file() {
      let ws = new WebSocket("ws://localhost:3000/ws-upload");
      let filedom = document.querySelector("#input-field");
      ws.onmessage = function(evnt) {
        console.log(evnt.data);
      }
      ws.onopen = function(evnt) {
        ws.send(filedom.files[0].name);
        ws.send(filedom.files[0].slice());
        ws.close();
      }
      return true;
    }
    </script>
    """
    for file in walkFiles("*.*"):
      html.add "<li>" & file & "</li>"
    html.add "<form action=\"upload\" method=\"post\"enctype=\"multipart/form-data\">"
    html.add "<input id=\"input-field\" type=\"file\" name=\"file\" value=\"file\">"
    html.add "<input type=\"button\" value=\"Submit\" name=\"submit-button\" onclick=\"submit_file()\">"
    html.add "</form>"
    resp(html)

  get "/ws-upload":
    echo "in ws-upload"
    try:
      var wsconn = await newWebSocket(request)
      await wsconn.send("send the filename")
      var fname = await wsconn.receiveStrPacket()
      var f = openAsync(fname, fmWrite)
      while wsconn.readyState == Open:
        let (op, seqbyte) = await wsconn.receivePacket()
        if op != Binary:
          resp Http400, "invalid sent format"
          wsconn.close()
          return
        var cnt = 0
        if seqbyte.len < 4096:
          await f.write seqbyte.join
          continue

        while cnt < (seqbyte.len-4096):
          let datastr = seqbyte[cnt .. cnt+4095].join
          cnt.inc 4096
          await f.write(datastr)

        wsconn.close()
      f.close()
    except:
      echo "websocket close: ", getCurrentExceptionMsg()
    resp Http200, "file uploaded"

  post "/upload":
    echo "in upload"
    var f: AsyncFile
    var fstream = newFutureStream[string]("routes.upload")
    try:
      f = openAsync("uploaded.file", fmWrite)
    except IOError:
      echo getCurrentExceptionMsg()
      resp Http500, "Cannot upload file"
      return
    echo "ready to write"
    var datastream = newStringStream(request.formData.getOrDefault("file").body)
    var asyncwrite = f.writeFromStream(fstream)
    while not datastream.atEnd:
      # read each of 500 bytes
      let strdata = datastream.readStr(1024 * 1024)
      echo strdata.len
      await fstream.write strdata
    fstream.complete
    resp Http200, "uploaded"
