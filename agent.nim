## Simple agent implementation on top of spawn.
## Each agent execution is ``spawn`` ed ``proc`` while the ``Agent`` is
## ``object`` instead of ``ref object``. Use ``isReady`` function from
## threadpool module for getting the returned value.
## The threadpool module is exported so it's not necessarily to import it
## anymore.
## Compile to run it with:
## $ nim c -r --threads:on
import threadpool
export threadpool

type
  AgentProc*[T] = proc(x: PAgent[T]): T
  Agent*[T] = object
    value: T
  PAgent*[T] = ptr Agent[T]

proc send*[T](agent: PAgent[T], exec: AgentProc[T]): T =
  exec agent

template `<-`*[T](agent: var Agent[T], exec: AgentProc[T]): untyped =
  spawn send(agent.addr, exec)

proc `@`*[T](agent: var Agent[T]): T =
  agent.value

proc makeAgent*[T](value: T): Agent[T] =
  Agent[T](value: value)

when isMainModule:
  from os import sleep
  from times import cpuTime

  var agent = makeAgent 0

  echo "Initial agent: ", @agent
  var start = cpuTime()
  let v = agent <- proc (x: PAgent[int]):int =
    echo "sleep it first for 2 seconds before increment"
    sleep 2000
    inc x.value
    x.value

  echo "During spawning: ", @agent
  echo "is FlowVar ready? ", v.isReady
  var lastTime = cpuTime()
  echo "ready for looping works"
  while not v.isReady:
    var
      current = cpuTime()
      difftime = (current - lastTime) * 1000
    if  difftime > 250:
      echo "Waited for ", (current - start), " seconds"
      lastTime = current
  echo "Now agent: ", @agent
  echo "Total time is ", cpuTime() - start, " seconds"
