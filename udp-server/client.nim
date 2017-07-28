import net

var socket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)

for count in 1 ..< 5:
  var mystatus = "I'm sending for " & $count & " times"
  discard socket.sendTo("localhost", Port(3000), mystatus)
  var
    data = ""
    address = ""
    senderport: Port
    length = 64
  discard socket.recvFrom(data, length, address, senderport)
  echo data
