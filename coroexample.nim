# compile with option:
# -d:nimCoroutines --threads:on

import coro
from os import sleep
from times import cpuTime
from random import random, randomize

type
  State = enum
    stReading, stWriting, stStop

proc main =
  var
    chan: Channel[State]
    #state = stReading
    count = 1
    sleepTotal = 0
  chan.open
  chan.send stReading # to kickstart the channel communication
  let
    producer = start(proc() =
      while true:
        #sleep 100
        var (status, state) = tryRecv chan
        if not status and state != stReading:
          echo "still waiting for channel"
        elif status and state == stStop:
          echo "Now stopping the producer"
          chan.send stStop
          break
        else:
          echo "ready for writing"
          chan.send stWriting
        suspend()
    )
    consumer = start(proc() =
      while true:
        case chan.recv
        of stWriting:
          echo "Now it's writing ", count
          if count >= 5:
            chan.send stStop
          else:
            inc count
            chan.send stReading
        of stStop:
          echo "Now stopping the consumer"
          chan.send stStop
          break
        else:
          echo "Now contention of writing"
        let sleeping = 300.random
        sleepTotal += sleeping
        sleep sleeping
        suspend()
    )
  let startTime = cpuTime()
  run()
  #[
  wait producer
  wait consumer
  ]#
  echo "The cpuTime needed is ", cpuTime() - startTime, " with sleeping ",
    sleepTotal, " ms."


when isMainModule:
  randomize()
  main()
