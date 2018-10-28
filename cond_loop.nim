# Example of efficient running loop using condition and channel.
# This implements the producer and consumer pattern.
# The consumer is ``chanWaiting`` and the producer is ``chanSending``
# The consumer thread is "locking" when there's no message incoming to
# the channel mailbox.
# The producer must ``signal`` to consumer for continuing the looping and
# checking the mailbox.
#
# Due to bug of threadpool implementation (it seems), for vcc compiler
# is using thread primitive instead of spawn.
# The bug of threadpool for vcc is the second ``spawn`` ed operation
# is not executed. If the order of execution producer->consumer then it
# would work but that would defeat the meaning of asynchronous execution
# Input > 10 would stop the loop, while unrecognized input will result
# in -1
# Compile:
# $ nim c -r --threads:on cond_loop

import locks
from strutils import parseInt
from os import sleep

when not defined(vcc):
  import threadpool

var
  chan: Channel[int]
  cond: Cond
  lock: Lock
  time = 700

initLock lock
initCond cond
chan.open

proc chanWaiting() {.thread.} =
  while true:
    var res = tryRecv chan
    if res.dataAvailable:
      echo "Get the num: ", res.msg

      # to simulate the congestion or slow operation
      sleep time

      if res.msg > 10:
        echo "stopping operation"
        break

      # immediately for next loop if there's a value to avoid message
      # congestion, in the event of there's no message then it will wait
      # for the condition signaled
      continue  

    echo "waiting for next iteration"
    cond.wait lock
    echo "condition signaled"

proc chanSending() {.thread.} =
  while true:
    var num = try: stdin.readline.parseInt
              except: -1
    echo "sending ", num
    chan.send num
    echo "going to signal the condition"
    cond.signal
    if num > 10:
      break

when defined(vcc) or defined(tcc):
  var
    threadsend: Thread[void]
    threadwait: Thread[void]

  threadsend.createThread chanSending
  threadwait.createThread chanWaiting

  joinThread threadsend
  joinThread threadwait
else:
  spawn chanWaiting()
  spawn chanSending()
  sync()
