import net

var socket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)

for count in 1 ..< 5:
  var mystatus = "I'm sending for " & $count & " times"
  echo "sendTo: ", socket.sendTo("localhost", Port(3000), mystatus)
  var
    data = ""
    address = ""
    senderport: Port
    length = 64
  try:
    echo "recvFrom: ", socket.recvFrom(data, length, address, senderport)
    echo data
  except OSError:
    echo "socket.recvFrom(): ", getCurrentExceptionMsg()

