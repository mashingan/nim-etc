import net

var server = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
server.bindAddr Port(3000)

echo "server ready to read line in port 3000"
while true:
  var
    data = ""
    address = ""
    length = 64
    port: Port
  discard server.recvFrom(data, length, address, port)
  echo address, " send ", data, " by ", $port
  discard server.sendTo(address, port, "server echo back " & data)
