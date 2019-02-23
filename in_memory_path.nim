import hashes, tables, random, strformat, sugar, sequtils
import times, os, strscans, strutils

import graflib

type
  Edgen = tuple
    a, b: string

proc hash(a: Edgen): Hash =
  var h: Hash = 0
  h = h !& a.a.hash
  h = h !& a.b.hash
  result = !$h

proc `==`(a, b: Edgen): bool =
  a.a == b.a and a.b == b.b

const
  entry = 10000
  alphabet = toSeq('a' .. 'f')
  distance = toSeq(5 .. 100)

template getLabel: string =
  var ad = @['a', 'b', 'c', 'd', 'e']
  ad.shuffle
  ad.join("")

proc `$`(s: Edgen): string =
  result = fmt"'{s.a}', '{s.b}'"

proc values(s: Edgen, e: int): string =
  result = fmt"({s}, {e})"

template getRoute(x: untyped): untyped =
  x.mapIt( it.label ).join "->"
template getCost(x: untyped): untyped =
  x.mapIt( it.weight ).foldl(a + b)

proc populateGraph(g: var Graph, entry: int): (seq[string], TableRef[Edgen, int]) =
  var buff = newseq[string]()
  var
    i = 0
    existingEdges = newTable[Edgen, int]()
  if "graph_entry.txt".fileExists:
    for entry in "graph_entry.txt".lines:
      var n1, n2: string
      var cost: int
      if scanf(entry, "('$w', '$w', $i)$.", n1, n2, cost):
        existingEdges[(n1, n2)] = cost
        buff.add n1
        buff.add n2
        g.addEdges initEdge(n1, n2, cost)

  else:
    let f = open("graph_entry.txt", fmWrite)
    while i < entry:
      let
        n1 = getLabel()
        n2 = getLabel()
        edge = (n1, n2)
      let dist = rand distance
      if edge notin existingEdges:
        existingEdges[edge] = dist
        g.addEdges initEdge[string, int](n1, n2, dist)
        f.write edge.values(dist) & "\n"
      if n1 notin buff: buff.add n1
      if n2 notin buff: buff.add n2
      inc i
  result = (buff, existingEdges)

proc lookingPath(graph: Graph, orig, dest: string):
    (seq[Vertex[string, int]], seq[Vertex[string, int]]) =
  var
    minimumCostPath = newseq[Vertex[string, int]]()
    shortestPath = newseq[Vertex[string, int]]()
    oldcost = 0
  let paths = graph.paths(initVertex(orig, 0), initVertex(dest, 0))
  if paths.len > 0:
    minimumCostPath = paths[0]
    shortestPath = paths[0]
    oldcost = minimumCostPath.getCost
  for i, path in paths[1..^1]:
    #echo fmt"{i}: {path}"
    let sla = path.getCost
    if shortestPath.len > path.len: shortestPath = path
    if oldcost > sla or oldcost == 0:
      minimumCostPath = path
      oldcost = sla
    #echo fmt"{i}: {route}: cost time {sla}"
  result = (minimumCostPath, shortestPath)

proc main =
  randomize()
  var
    start = cpuTime()
    graph = buildGraph[string, int](directed = true)
    (nodes, conn) = graph.populateGraph entry
    orig = "cadeb"
    dest = "dceab"
  echo fmt"time to populate graph: {cpuTime() - start}"
  echo fmt"Graph nodes: {graph.vertices.len}"
  echo fmt"Graph edges: {graph.edges.len}"
  echo "predetermined path"
  dump orig
  dump dest
  start = cpuTime()
  var (minimumCostPath, shortestPath) = graph.lookingPath(orig, dest)
  echo fmt"time to search path: {cpuTime() - start}"

  var
    route = minimumCostPath.getRoute
    sla = minimumCostPath.getCost
  echo fmt"minimum cost route: {route}: cost time: {sla}"
  route = shortestPath.getRoute
  sla = shortestPath.getCost
  echo fmt"shortest route: {route}: cost time: {sla}"

  var
    orig2 = rand nodes
    dest2 = rand nodes
  echo "random path"
  dump orig2
  dump dest2
  start = cpuTime()
  (minimumCostPath, shortestPath) = graph.lookingPath(orig2, dest2)
  echo fmt"time to search path: {cpuTime() - start}"

  route = minimumCostPath.getRoute
  sla = minimumCostPath.getCost
  echo fmt"minimum cost route: {route}: cost time: {sla}"
  route = shortestPath.getRoute
  sla = shortestPath.getCost
  echo fmt"shortest route: {route}: cost time: {sla}"

  start = cpuTime()
  echo "bfs shortest path"
  dump orig
  dump dest
  var bfspath = graph.shortestPath(initVertex(orig, 0), initVertex(dest, 0))
  route = bfspath.getRoute
  sla = bfspath.getCost
  echo fmt"bfs route: {route}: cost time: {sla}"
  echo fmt"time to search: {cpuTime() - start}"

  echo "bfs random orig/dest"
  dump orig2
  dump dest2
  bfspath = graph.shortestPath(initVertex(orig2, 0), initVertex(dest2, 0))
  route = bfspath.getRoute
  sla = bfspath.getCost
  echo fmt"bfs route: {route}: cost time: {sla}"
  echo fmt"time to search: {cpuTime() - start}"


main()
