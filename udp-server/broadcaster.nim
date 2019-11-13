# compile with --threads:on
# add --threadAnalysis:off for convenience purpose

import net, tables, strutils, threadpool

type
  SubscriberO = object
    name, address: string
    port: Port

  Subscriber = ref SubscriberO

proc `$`(s: Subscriber): string =
  s.name & " subscribing from " & s.address & " at port " & $s.port

proc newSubscribe(name, address: string; port: Port): Subscriber =
  Subscriber(name: name, address: address, port: port)

var running = false
var server = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
server.bindAddr Port(3000)
echo "server bound to port 3000"

var subscribers = initTable[string, Subscriber]()

proc send(msg, towhom: string) =
  let subscriber = subscribers[towhom]
  server.sendTo(subscriber.address, subscriber.port, msg)

proc broadcast(msg: string) =
  for s in subscribers.values:
    server.sendTo(s.address, s.port, msg)

var newcommand = false
proc command() {.thread.} =
  newcommand = true
  let data = stdin.readLine
  var cmd = newSeq[string]()
  if data.startsWith '/':
    cmd = data.split(maxsplit=2)
    echo "now cmd[0] ", cmd[0]
  else:
    cmd.add data
  echo "the command is ", cmd
  case cmd.len
  of 1:
    case cmd[0]
    of "quit":
      running = false
      echo "good bye"
    of "list":
      let total = subscribers.len
      if total == 1:
        echo "There is 1 subscriber."
      else:
        echo "There are ", total, " subscribers."
      for subscriber in subscribers.values:
        echo subscriber
    else:
      broadcast cmd[0]
  of 3 .. int.high:
    echo "going to send to ", cmd[1]
    if subscribers.hasKey cmd[1].toLowerAscii:
      send(cmd[2], cmd[1])
    else:
      echo "Invalid subscriber name"
  else:
    echo "Invalid command"

  newcommand = false

var newsubscription = false
proc waitingForSubscriber() {.thread.} =
  newsubscription = true
  var
    data = ""
    address = ""
    port: Port
    length = 1024
  discard server.recvFrom(data, length, address, port)
  let cmd = data.split(maxsplit=2)
  case cmd.len
  of 2:
    case cmd[0]
    of "subscribe":
      var subscriber = newSubscribe(cmd[1].toLowerAscii, address, port)
      echo "new subscriber ", subscriber
      subscribers[cmd[1]] = subscriber
    of "quit":
      echo "Who's going to quit? ", cmd[1]
      if subscribers.hasKey cmd[1]:
        subscribers.del cmd[1]
    else:
      echo "Unknown subscription request"
  else:
    echo "Invalid subscription request"

  newsubscription = false

running = true
spawn command()

template unless(x, body: untyped): untyped =
  if not x:
    body

while running:
  #if not newcommand:
  unless newcommand:
    spawn command()

  #if newsubscription:
  unless newsubscription:
    spawn waitingForSubscriber()

close server
