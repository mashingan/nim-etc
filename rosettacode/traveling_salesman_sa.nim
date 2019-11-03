# simulated annealing traveling salesman
# https://rosettacode.org/wiki/Simulated_Annealing
import math, random, sugar, strformat, os
from times import cpuTime

const
  kT = 1
  kMax = 1_000_000

proc randomNeighbor(x: int): int =
  case x
  of 0:
    rand([1, 10, 11])
  of 9:
    rand([8, 18, 19])
  of 90:
    rand([80, 81, 91])
  of 99:
    rand([88, 89, 98])
  elif x > 0 and x < 9:   # top ceiling
    rand [x-1, x+1, x+9, x+10, x+11]
  elif x > 90 and x < 99: # bottom floor
    rand [x-11, x-10, x-9, x-1, x+1]
  elif x mod 10 == 0:     # left wall
    rand([x-10, x-9, x+1, x+10, x+11])
  elif (x+1) mod 10 == 0: # right wall
    rand([x-11, x-10, x-1, x+9, x+10])
  else: # center
    rand([x-11, x-10, x-9, x-1, x+1, x+9, x+10, x+11])

proc neighbor(s: seq[int]): seq[int] =
  result = s
  var city = rand s
  var cityNeighbor = city.randomNeighbor
  while cityNeighbor == 0 or city == 0:
    city = rand s
    cityNeighbor = city.randomNeighbor
  result[s.find city].swap result[s.find cityNeighbor]

func distNeighbor(a, b: int): float =
  template divmod(a: int): (int, int) = (a div 10, a mod 10)
  let
    (diva, moda) = a.divmod
    (divb, modb) = b.divmod
  hypot((diva-divb).float, (moda-modb).float)

func temperature(k, kmax: float): float =
  kT * (1 - (k / kmax))

func pdelta(eDelta, temp: float): float =
  if eDelta < 0: 1.0
  else: exp(-eDelta / temp)

func energy(path: seq[int]): float =
  var sum = 0.distNeighbor path[0]
  for i in 1 ..< path.len:
    sum += path[i-1].distNeighbor(path[i])
  sum + path[^1].distNeighbor 0

proc main =
  randomize()
  var
    s = block:
      var x = lc[x | (x <- 0 .. 99), int]
      template shuffler: int = rand(1 .. x.len-1)
      for i in 1 .. x.len-1:
        x[i].swap x[shuffler()]
      x
  let startTime = cpuTime()
  echo fmt"E(s0): {energy s:6.4f}"
  for k in 0 .. kMax:
    var
      temp = temperature(float k, float kMax)
      lastenergy = energy s
      newneighbor = s.neighbor
      newenergy = newneighbor.energy
    if k mod (kMax div 10) == 0:
      echo fmt"k: {k:7} T: {temp:6.2f} Es: {lastenergy:6.4f}"
    var deltaEnergy = newenergy - lastenergy
    if pDelta(deltaEnergy, temp) >= rand(1.0):
      s = newneighbor

  s.add 0
  echo fmt"E(sFinal): {energy s:6.4f}"
  echo fmt"path: {s}"
  echo fmt"ended after: {cpuTime() - startTime}"

main()
