## sharedseq to be used for inter-thread seq like operation
## Every usage of sharedseq should make a call for ``freeColl`` to release
## the memory allocation to which scope it resides.
## Also make sure to use lock or guard to prevent data-races.
## In later version, the guard would be provided within collection
## so it could seamlessly used as if it's seq.
## But, the allocation still should manually released
## To run this module independently, compile with:
## $ nim c -r --threads:on sharedseq

type
  Coll*[T] = object
    coll: ptr T
    size: int

  PColl*[T] = ptr Coll[T]

proc newColl*[T](): PColl[T] =
  ## Default constructor with zero arity
  result = create(Coll[T], 1)
  result.coll = createShared(T, 1)
  result.size = 0

proc newColl*[T](size = 0, init: T): PColl[T] =
  ## Default constructor with initial value defined
  var newsize: int
  if size == 0:
    newsize = 1
  result = create(Coll[T], newsize)
  result.coll = createShared(T, newsize)
  result.coll[] = init
  result.size = newsize

proc freeColl*(p: PColl){.discardable.} =
  ## Freeing the allocated shared memory
  discard p.coll.resizeShared 0
  discard p.resize 0

proc `$`*(p: PColl): string =
  ## Stringify the collection
  result = "["
  for i in 0..<p.size:
    result &= $p.coll[i]
    if i != p.size - 1:
      result &= ", "
  result &= "]"

proc `[]`*[T](p: PColl[T], off: int): T =
  ## Getting the index value. O(1)
  p.coll[off]

proc `[]=`*[T](p: var PColl[T], off: int, val: T) =
  ## Setting the value at index. O(1)
  p.coll[off] = val

template `+`[T](p: ptr T, off: int): ptr T =
  cast[ptr p[].type](cast[ByteAddress](p) +% off * p[].sizeof)

template `[]`[T](p: ptr T, off: int): T =
  (p+off)[]

template `[]=`[T](p: ptr T, off: int, val: T) =
  (p+off)[] = val

proc len*(p: PColl): int =
  ## Getting the size of collection
  p.size

proc inc*[T](p: var ptr T) {.discardable.} =
  ## Increment the pointer position
  p = p + 1

proc contains*[T](p: ptr T, x: T): bool =
  ## Check whether ``x`` in ``p``. Can be used with ``in`` expression
  ## ```nim
  ##  if x in coll:
  ##    echo $x
  ## ```
  var temp = p
  for i in 0..<p.len:
    if x == temp[]:
      return true
    inc temp
  false

proc contains*[T](p: PColl[T], val: T): bool =
  ## Check whether ``val`` in ``p``.
  for i in 0..<p.size:
    if val == p.coll[i]:
      return true
  false

proc delete*(p: var PColl, idx: int){.discardable.} =
  ## Delete the value at index position and move all the subsequent values
  ## to fill its respective previous position. O(n)
  if idx > p.size:
    return
  var temp = p.coll + idx + 1
  p.coll[idx] = temp[]
  inc temp
  for i in idx+1..<p.size:
    if temp.isNil:
      break
    p.coll[i] = temp[]
    inc temp

  dec p.size
  p.coll = resizeShared(p.coll, p.size)


proc add*[T](p: var PColl, val: T) {.discardable.} =
  ## Append the ``val`` to ``p``. O(1)
  p.coll = resizeShared(p.coll, p.size+1)
  if p.size == 0:
    p[0] = val
  else:
    p[p.size] = val
  inc p.size


when isMainModule:
  from os import sleep
  from random import random, randomize
  import locks

  type
    Customer = ref object
      id: int
      inQueue, isDone: bool

  const
    totalCustomer = 20
    seat = 3
    cuttingTime = 1000  # in ms

  var
    lock, queue: Lock
    servedCustomers: int
    customers: array[totalCustomer, Thread[Customer]]
    seatAvailable{.guard: queue.} = newColl[int]()

  proc newCustomer(id: int): Customer =
    new result
    result.id = id
    result.inQueue = false
    result.isDone = false

  proc notInQueue(c: Customer): bool =
    not c.inQueue

  template servingAction(num: int): typed =
    echo "(b) serving customer ", num
    sleep random(cuttingTime)
    inc servedCustomers
    echo "(c) customer ", num, " finish cutting hair"

  template illegableToWait(c: Customer): untyped =
    {.locks: [queue].}:
      seatAvailable.len >= 0 and seatAvailable.len < seat and
        c.id notin seatAvailable and c.notInQueue

  template tobeTurnedAway(c: Customer): untyped =
    {.locks: [queue].}:
      c.id notin seatAvailable

  proc serving (cust: Customer) {.thread.} =

    echo "(c) customer ", cust.id, " entering shop"
    {.locks: [queue].}:
      echo "(s) current queuing: ", seatAvailable
    while true:
      let barberFree = tryAcquire lock
      if barberFree:
        {.locks: [queue].}:
          var turn: int
          if seatAvailable.len <= seat and seatAvailable.len > 0:
            turn = seatAvailable[0]
            seatAvailable.delete 0
          else:
            turn = cust.id
          echo "now seatAvailable before serving: ", seatAvailable
          servingAction turn
        release lock
        break

      elif cust.inQueue:
        continue

      elif cust.illegableToWait:
        {.locks: [queue].}:
          echo "(s) seatAvailable: ", seatAvailable
          echo "(c) customer ", cust.id, " waiting in queue"
          seatAvailable.add cust.id
          echo "(c) seatAvailable after queuing: ", seatAvailable
          cust.inQueue = true
      elif cust.tobeTurnedAway:
        {.locks: [queue].}:
          echo "seatAvailable: ", seatAvailable
        echo "(c) turn away customer ", cust.id
        break


  randomize()

  initLock lock
  initLock queue

  echo "Total customer today will be: ", totalCustomer
  for i in 1..totalCustomer:
    echo "loop in: ", i
    customers[i-1].createThread serving, newCustomer(i)

    # to make it the customer come at random time when barber working
    sleep random(cuttingTime div 2)

  joinThreads(customers)
  echo "Total served customers is ", servedCustomers

  {.locks: [queue].}:
    seatAvailable.freeColl
