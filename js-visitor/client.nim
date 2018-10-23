import htmlgen, dom

type
  Data = object
    visitors {.importc.}: int
    uniques {.importc.}: int
    ip {.importc.}: cstring

proc printInfo(data: Data) {.exportc.} =
  var infoDiv = document.getElementById "info"
  infoDiv.innerHTML = p("You're visitor number ", $data.visitors,
    ", unique visitor number ", $data.uniques,
    " today. Your ip is ", $data.ip, ".")
