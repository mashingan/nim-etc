## sharedseq to be used for inter-thread seq like operation
## Every usage of sharedseq should make a call for ``freeColl`` to release
## the memory allocation to which scope it resides.
##
## ~~Also make sure to use lock or guard to prevent data-races.~~ (outdated)
##
## ~~In later version, the guard would be provided within collection
## so it could seamlessly used as if it's seq.~~ (Implemented)
##
## But, the allocation still should be manually released.
##
## To run this module independently, compile with:
## $ nim c -r --threads:on sharedseq
##
## Additionally, if we want to observe the memory, supply the additional
## compile info ``-d:checkMemStat``. The statistics are observed
## when the barber finished serving a customer

import locks
#TODO: For ref type element deletion
#import typeinfo

type
  Coll*[T] = object
    ## Box for linear position value in memory. The representation of
    ## linear position is a pointer of given type. It has its own guard/lock
    ## to ensure avoiding race-condition.
    ## The pointer object is created with ``create`` instead of ``createShared``
    ## so make sure the object lifetime longer than its ``coll`` field.
    coll {.guard: lock.}: ptr T   ## Consecutive array pointer of
                                  ## given type in memory.
    size: int                     ## Size the collection.
    lock: Lock                    ## Guard for ``coll`` field.

  PColl*[T] = ptr Coll[T]         ## Pointer representation of ``Coll``

template guardedWith[T](coll: PColl[T], body: untyped) =
  {.locks: [coll.lock].}:
    body

proc newColl*[T](): PColl[T] =
  ## Default constructor with zero arity
  result = create(Coll[T], 1)
  initLock result.lock
  guardedWith result: result.coll = createShared(T, 1)
  result.size = 0

proc newColl*[T](size = 0, init: T): PColl[T] =
  ## Default constructor with initial value defined
  var newsize: int
  if size == 0:
    newsize = 1
  result = create(Coll[T], newsize)
  initLock result.lock
  guardedWith result:
    result.coll = createShared(T, newsize)
    result.coll[] = init
  result.size = newsize

proc freeColl*(p: PColl){.discardable.} =
  ## Freeing the allocated shared memory
  deinitLock p.lock
  when compiles(delete p[0]):
    for i in 0 ..< p.size:
      delete p[i]
  if p.size > 0:
    guardedWith p: p.coll.freeShared
  p.dealloc

proc `$`*(p: PColl): string =
  ## Stringify the collection
  result = "["
  for i in 0..<p.size:
    guardedWith p:
      result &= $p.coll[i]
    if i != p.size - 1:
      result &= ", "
  result &= "]"

proc `[]`*[T](p: PColl[T], off: int): T =
  ## Getting the index value. O(1)
  guardedWith p:
    result = p.coll[off]

proc `[]=`*[T](p: var PColl[T], off: int, val: T) =
  ## Setting the value at index. O(1)
  guardedWith p:
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
  ##
  ## .. code-block:: nim
  ##  if x in coll:
  ##    echo $x
  ##
  var temp = p
  for i in 0..<p.len:
    if x == temp[]:
      return true
    inc temp
  false

proc contains*[T](p: PColl[T], val: T): bool =
  ## Check whether ``val`` in ``p``.
  result = false
  for i in 0..<p.size:
    guardedWith p:
      if val == p.coll[i]:
        result = true
        break

#[
template kindof[T](x: var T, whatKind: AnyKind) =
  ## To get what kind of ``x`` type. To find whether ``x`` is value or
  ## reference type.
  whatKind = toAny[T](x).kind
  cast[T](x)
]#

proc delete*(p: var PColl){.discardable.} = p.freeCol

proc delete*(p: var PColl, idx: int){.discardable.} =
  ## Delete the value at index position and move all the subsequent values
  ## to fill its respective previous position. O(n)

  if idx > p.size:
    return

  # TODO: Implement for checking whether it's value type or reference type
  # To delete the element that some kind of user defined object which
  # created with some memory allocation, user need to define ``delete``
  # operation to its object in order to free the memory.

  #[
  #TODO: Finish individual reference type element deletion
  var
    thekind: AnyKind
    tempvar = p[0]
  kindof tempvar, theKind

  let isBasicObj: bool = case theKind
    of akObject, akPtr, akProc, akCstring: false
    else: true
  ]#

  var temp: ptr p[0].type
  guardedWith p:
    temp = p.coll + idx + 1
    p.coll[idx] = temp[]
  inc temp
  for i in idx+1..<p.size:
    if temp.isNil:
      break
    guardedWith p:
      when compiles(delete p.coll[i]):
        # TODO: Fix this to foolproof the memory type
        # Rely ``PColl`` users to implement ``delete`` proc for its individual
        # element. If there's no ``delete`` function implemented, will
        # the position will be overwritten with other value. The it's the
        # reference type especially ``pointer`` or ``ptr T``, this will leak
        delete p.coll[i]
      p.coll[i] = temp[]
    inc temp

  dec p.size
  guardedWith p:
    p.coll = resizeShared(p.coll, p.size)


proc add*[T](p: var PColl, val: T) {.discardable.} =
  ## Append the ``val`` to ``p``. O(1)
  guardedWith p:
    p.coll = resizeShared(p.coll, p.size+1)
  if p.size == 0:
    p[0] = val
  else:
    p[p.size] = val
  inc p.size

when defined(checkMemStat):
  proc getCollSize(p: var PColl): int =
    p[0].sizeof * p.len

when isMainModule:
  from os import sleep
  from random import random, randomize
  when defined(blocked):
    from terminal import getch
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
    lock: Lock
    servedCustomers: int
    customers: array[totalCustomer, Thread[Customer]]
    seatAvailable = newColl[int]()

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
    seatAvailable.len >= 0 and seatAvailable.len < seat and
      c.id notin seatAvailable and c.notInQueue

  template tobeTurnedAway(c: Customer): untyped =
    c.id notin seatAvailable

  proc serving (cust: Customer) {.thread.} =

    echo "(c) customer ", cust.id, " entering shop"
    echo "(s) current queuing: ", seatAvailable
    while true:
      let barberFree = tryAcquire lock
      if barberFree:
        var turn: int
        if seatAvailable.len <= seat and seatAvailable.len > 0:
          turn = seatAvailable[0]
          seatAvailable.delete 0
        else:
          turn = cust.id
        echo "now seatAvailable before serving: ", seatAvailable
        servingAction turn
        release lock
        when defined(checkMemStat):
          echo "seatAvailable memory after serving ",
            getCollSize(seatAvailable)
        break

      elif cust.inQueue:
        continue

      elif cust.illegableToWait:
        echo "(s) seatAvailable: ", seatAvailable
        echo "(c) customer ", cust.id, " waiting in queue"
        seatAvailable.add cust.id
        echo "(c) seatAvailable after queuing: ", seatAvailable
        cust.inQueue = true
      elif cust.tobeTurnedAway:
        echo "seatAvailable: ", seatAvailable
        echo "(c) turn away customer ", cust.id
        break


  randomize()

  initLock lock

  echo "Total customer today will be: ", totalCustomer
  when defined(checkMemStat):
    echo "seatAvailable initially allocated ", getCollSize(seatAvailable)
  when defined(blocked):
    stdout.write "Press a key to start"
    discard getch()
  for i in 1..totalCustomer:
    echo "loop in: ", i
    customers[i-1].createThread serving, newCustomer(i)

    # to make it the customer come at random time when barber working
    sleep random(cuttingTime div 2)

  joinThreads(customers)
  echo "Total served customers is ", servedCustomers

  when defined(checkMemStat):
    echo "Last time before freeing ", getCollSize seatAvailable

  seatAvailable.freeColl

  when defined(checkMemStat):
    echo "After freeing ", getCollSize seatAvailable

  when defined(blocked):
    stdout.write "press a key to exit"
    discard getch()
