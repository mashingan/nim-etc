## Simple agent implementation on top of spawn.
## Each agent execution is ``spawn`` ed ``proc`` while the ``Agent`` is
## ``object`` instead of ``ref object``. Use ``isReady`` function from
## threadpool module for getting the returned value.
## The threadpool module is exported so it's not necessarily to import it
## anymore.
## Compile to run it with:
## $ nim c -r --threads:on agent
import threadpool
export threadpool

type
  AgentProc*[T] = proc(x: PAgent[T]): T
  Agent*[T] = object
    value: T
  PAgent*[T] = ptr Agent[T]

proc send*[T](agent: PAgent[T], exec: AgentProc[T]): T =
  ## Executing the closure ``exec`` to ``agent`` itself. The mutation or
  ## any value changing operation done within the closure.
  exec agent

template `<-`*[T](agent: var Agent[T], exec: AgentProc[T]): untyped =
  ## ``send`` asynchronously with closure.
  spawn send(agent.addr, exec)

template `<-`*[T](agent: var Agent[T], value: T): untyped =
  ## ``send`` asynchronously with immediate ``value``.
  spawn send(agent.addr, proc(x: PAgent[T]): T =
    x.value = value
    value)

proc `@`*[T](agent: var Agent[T]): var T =
  ## Setter and getter for agent value since the value field cannot be
  ## accessed directly.
  agent.value

proc `@`*[T](agent: PAgent[T]): var T =
  @(agent[])

proc makeAgent*[T](value: T): Agent[T] =
  ## Agent constructor.
  Agent[T](value: value)

when isMainModule:
  from os import sleep
  from times import cpuTime

  var agent = makeAgent 0
  var agent2 = makeAgent 10

  echo "Initial agent: ", @agent
  var start = cpuTime()
  let v = agent <- proc (x: PAgent[int]):int =
    echo "sleep it first for 2 seconds before increment"
    sleep 2000
    inc @x
    @x

  let v2 = agent2 <- proc(x: PAgent[int]): int =
    echo "Sleep it first for 2 seconds before double it"
    sleep 2000
    @x = @x * 2

  echo "During spawning: ", @agent
  var lastTime = cpuTime()
  echo "ready for looping works"
  while not v.isReady and not v2.isReady:
    var current = cpuTime()
    let difftime = (current - lastTime) * 1000
    if  difftime > 250:
      echo "Waited for ", (current - start), " seconds"
      lastTime = current
  sync()
  echo "Now agent: ", @agent
  echo "Now agent2: ", @agent2
  echo "Total time is ", cpuTime() - start, " seconds"
