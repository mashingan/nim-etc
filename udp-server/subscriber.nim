import net

var
  socket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  serverAddress = "localhost"
  serverPort = Port(3000)

stdout.write "Insert your name: "
var name = stdin.readLine

socket.sendTo(serverAddress, serverPort, "subscribe " & name)
while true:
  var
    data = ""
    address = ""
    length = 1024
    port: Port
  discard socket.recvFrom(data, length, address, port)
  echo data

close socket
