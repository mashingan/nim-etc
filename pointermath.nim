## C-Like pointer math in Nim which posted in this post at Nim forum
## https://forum.nim-lang.org/t/1188#7366
## With this code as the reference, the example of shared memory in Nim code
## to solve barbershop problem is written at
## https://gist.github.com/mashingan/a91b928aae47e20149ef9024588149ec

template ptrMath*(body: untyped) =
  template `+`*[T](p: ptr T, off: int): ptr T =
    cast[ptr type(p[])](cast[ByteAddress](p) +% off * sizeof(p[]))

  template `+=`*[T](p: ptr T, off: int) =
    p = p + off

  template `-`*[T](p: ptr T, off: int): ptr T =
    cast[ptr type(p[])](cast[ByteAddress](p) -% off * sizeof(p[]))

  template `-=`*[T](p: ptr T, off: int) =
    p = p - off

  template `[]`*[T](p: ptr T, off: int): T =
    (p+off)[]

  template `[]=`*[T](p: ptr T, off: int, val: T) =
    (p+off)[] = val

  body

when isMainModule:
  ptrMath:
    var a: array[0..3, int]
    for i in a.low..a.high:
      a[i] += i
    var p = addr(a[0])
    p += 1
    p[0] -= 2
    for i in a.low..a.high:
      stdout.write a[i], " "
    echo()
    echo p[0], " ", p[1]
