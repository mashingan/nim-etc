#[
https://forum.nim-lang.org/t/3852
This example to answer the post about tracking the thread
independently from another thread using channel.
This example is blocking thread while listening the channel
]#
import std/random, threadpool
from os import sleep

const comptime = 10000

var chan: Channel[float]
chan.open

proc heavycomp =
  var sleeping = 0
  while sleeping < comptime:
    let asleep = rand(comptime - sleeping)
    sleeping += asleep
    let percent = sleeping.float / comptime.float
    sleep asleep
    chan.send percent

proc monitorcomp =
  var percent = 0.0
  while percent < 1.0:
    percent = chan.recv
    echo "Current comp at ", percent * 100, "%"

proc main =
  randomize()
  spawn(heavycomp())
  spawn(monitorcomp())
  sync()

main()
