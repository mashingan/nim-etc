# Fake dns query using [dnsclient](https://github.com/ba0f3/dnsclient.nim].
# This emulate the DNS server with SRV service and will return the data
# of target actual server location.
# The fake server UDP listen to localhost:3000 and will return the servers:
# localhost:27018, localhost:27019, localhost:27020.
# This is developed to test the [Anonimongo](https://github.com/mashingan/anonimongo]
# local DNS seedlist test.
#
# Install the dnsclient with:
# $ nimble install dnsclient@#head
# Compile with enabling threads:
# $ nim c --threads:on fakedns_server.nim
import net, sugar, streams, strutils, endians, threadpool

import dnsclient
from private/protocol as dnsprot import parseResponse, toStream
from private/utils as dnsutils import writeShort

const
  dnsport = 3000
  mongoServer = "localhost"
  replicaPortStart = 27018

proc writeName(s: StringStream, srv: SRVRecord, server: string) =
  for sdot in server.split('.'):
    s.write sdot.len.byte
    s.write sdot
  s.write 0x00.byte

proc serialize(s: StringStream, srv: SRVRecord, server: string) =
  srv.rdlength = srv.priority.sizeof + srv.weight.sizeof +
    srv.port.sizeof
  let domsrv = server.split('.')
  for sdot in domsrv:
    srv.rdlength += byte.sizeof.uint16 + sdot.len.uint16
  srv.rdlength += byte.sizeof.uint16
  s.writeName srv, server
  s.writeShort srv.kind.uint16
  s.writeShort srv.class.uint16

  var ttl: int32
  bigEndian32(addr ttl, addr srv.ttl)
  s.write ttl

  s.writeShort srv.rdlength
  s.writeShort srv.priority
  s.writeShort srv.weight
  s.writeShort srv.port
  s.writeName srv, server

proc serialize(s: StringStream, srvs: seq[SRVRecord], server: string) =
  for srv in srvs:
    s.serialize srv, server

proc serialize(data: string): StringStream =
  var req = data.newStringStream.parseResponse
  req.header.qr = QR_RESPONSE
  req.header.ancount = 3
  var head = req.header
  result = head.toStream()
  req.question.kind = SRV
  req.question.toStream(result)
  var srvs = newseq[SRVRecord](3)
  for i in 0 ..< 3:
    srvs[i] = SRVRecord(
      name: mongoServer,
      class: IN,
      ttl: 60,
      kind: SRV,
      priority: 0,
      port: uint16(replicaPortStart+i),
      target: mongoServer,
      weight: 0)
  result.serialize(srvs, mongoServer)
  result.setPosition 0

proc server =
  var server = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  server.bindAddr(Port dnsport)
  var
    data = ""
    address = ""
    senderport: Port
    length = 64
  try:
    discard server.recvFrom(data, length, address, senderport)
    let restream = serialize data
    let datares = restream.readAll
    dump datares.len
    server.sendTo(address, senderport, datares)
  except OSError:
    echo "Error socket.recvFrom(): ", getCurrentExceptionMsg()
  finally:
    close server

spawn server()
var client = newDNSClient(server = mongoServer, port = dnsport)
var resp: Response
try:
  resp = client.sendQuery(mongoServer, SRV)
  dump resp
  echo "getting answer below ========>:"
  for rr in resp.answers:
    dump rr.repr
except TimeoutError:
  echo "Error timeout: ", getCurrentExceptionMsg()
except OSError:
  echo "error socket: ", getCurrentExceptionMsg()
except Exception as e:
  echo "Any except: ", getCurrentExceptionMsg()
  dump e.name
  dump e.parent.repr
  raise e
finally:
  sync()
