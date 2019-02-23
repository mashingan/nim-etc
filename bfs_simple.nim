import deques, sequtils, algorithm, tables

let
  conn = @[('a', 'b'), ('a', 'c'), ('a', 'd'), ('a', 'e'),
           ('b', 'f'), ('b', 'c'), ('b', 'g'), ('b', 'e'),
           ('c', 'h'), ('c', 'i'), ('c', 'b'), ('c', 'e'),
           ('d', 'e'), ('d', 'j'), ('d', 'k'), ('d', 'f'),
           ('e', 'l'), ('e', 'm'), ('e', 'n'), ('e', 'z')]

proc visit(conn: openarray[(char, char)], v1, v2: char): seq[char] =
  var
    visited = newseq[char]()
    neighbour = initDeque[char]()
    parent = newTable[char, char]()

  template nextVisiting(x: untyped): untyped =
    var next = conn.filterIt( it[0] == x ).mapIt( it[1] )
    for node in next:
      if node notin parent: parent[node] = x
    next
  template addedToNeighbour(ns: seq[char]) =
    for n in ns: neighbour.addLast n

  visited.add v1
  v1.nextVisiting.addedToNeighbour
  while neighbour.len > 0:
    let n = neighbour.popFirst
    if n in visited:
      continue
    else:
      visited.add n
      if n == v2:
        result = visited
        break
      n.nextVisiting.addedToNeighbour

  var curr = v2
  result = @[]
  while curr != v1:
    result.add curr
    curr = parent[curr]
  result.add v1
  result.reverse

proc main =
  let path = conn.visit('a', 'z')
  echo path

main()
