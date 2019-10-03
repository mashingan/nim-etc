#[
# Nim 0.17.0
# tested with various C compiler:
# gcc version 7.1.0 (Rev2, Built by MSYS2 project)
# gcc version 4.8.4 (Ubuntu 4.8.4-2ubuntu1~14.04.3)
# Microsoft (R) C/C++ Optimizing Compiler Version 19.00.24213.1 for x64
# gcc version 5.4.0 20160609 (Ubuntu 5.4.0-6ubuntu1~16.04.4)
# clang version 3.8.0-2ubuntu4 (tags/RELEASE_380/final)
# Ubuntu clang version 3.4-1ubuntu3 (tags/RELEASE_34/final) (based on LLVM 3.4)
]#
import strutils, sequtils, algorithm, math, tables
import macros
from os import paramCount, paramStr


type
  Map = object
    length, wide: int
    terrain: seq[string]

  Pos = object
    row, col: int

  Faction = char
  Army = object
    faction: Faction
    pos: Pos
    region: seq[Pos]
  Armies = seq[Army]

  DispatchResult = object
    army: Army
    contested: Armies

proc `==`(p1, p2: Pos): bool =
  p1.row == p2.row and p1.col == p2.col


proc cmp(x, y: Pos): int =
  #[
  if x == y: 0
  elif (x.row.float64.pow(2) + x.col.float64.pow(2)).sqrt >=
       (y.row.float64.pow(2) + y.col.float64.pow(2)).sqrt:
    1
  else:
    -1
    ]#
  if x == y: 0
  elif x.row > y.row: 1
  elif x.row == y.row:
    if x.col > y.col: 1
    else: -1
  else: -1

proc `==`(a1, a2: Army): bool =
  a1.pos == a2.pos or (a1.faction == a2.faction and a1.region == a2.region)

macro to(where, coord, op): typed =
  result = newNimNode nnkStmtList
  var templateDef = newNimNode nnkTemplateDef
  templateDef.add newIdentNode("to" & $where)

  var formalParam = newNimNode(nnkFormalParams).add(
    ident "untyped",
    newIdentDefs(ident "pos", ident "Pos"))

  var body = newNimNode(nnkStmtList).add(
    newDotExpr(ident "pos", newIdentNode($coord)).
      infix($op, newIntLitNode 1))

  templateDef.add(
    newEmptyNode(), newEmptyNode(), formalParam,
    newEmptyNode(), newEmptyNode(), body)
  result.add templateDef


#[
template toNorth(pos: Pos): untyped = pos.y - 1
template toEast (pos: Pos): untyped = pos.x + 1
template toSouth(pos: Pos): untyped = pos.y + 1
template toWest (pos: Pos): untyped = pos.x - 1
]#
to("North", "row", "-")
to("East" , "col", "+")
to("South", "row", "+")
to("West" , "col", "-")

proc definePlace(where: NimNode, place: string): (string, string, string) =
  if place == "north" or place == "south":
    result = ("row", "to" & $where, "col")
  elif place == "west" or place == "east":
    result = ("col", "to" & $where, "row")

macro available(where): typed =
  result = newNimNode nnkStmtList
  var templateDef = newNimNode nnkTemplateDef
  var place = $where
  place[0] = place[0].toLowerAscii
  templateDef.add newIdentNode($place & "Available")

  var formalParams = newNimNode(nnkFormalParams).add(
    ident "bool",
    newIdentDefs(ident "map", ident "Map"),
    newIdentDefs(ident "pos", ident "Pos"))

  let (pos1, pos2, pos3) = where.definePlace place
  echo("where $1 with $2 $3 $4" % [place, pos1, pos2, pos3])
  var letitpos1 = newLetStmt(ident pos1,
    newDotExpr(ident "pos", ident pos2))
  var letitpos2 = newLetStmt(ident pos3,
    newDotExpr(ident "pos", ident pos3))

  var
    op: string
    filterValue: NimNode
  case place
  of "north", "west":
    op = ">="
    filterValue = newIntLitNode 0
  of "south":
    op = "<"
    filterValue = newDotExpr(ident "map", ident "length")
  of "east":
    op = "<"
    filterValue = newDotExpr(ident "map", ident "wide")
  var cond1 = ident(pos1).infix(op, filterValue)
  var cond2 = newCall(newDotExpr(ident "map", ident "notMountainAt"),
    ident "row", ident "col")
  var ifStmt = newIfStmt(
    (cond1.infix("and", cond2), newStmtList(ident "true")))
  ifStmt.add(newNimNode(nnkElse).add newStmtList(ident "false"))

  var body = newStmtList(letitpos1, letitpos2, ifStmt)
  templateDef.add(
    newEmptyNode(), newEmptyNode(), formalParams,
    newEmptyNode(), newEmptyNode(), body)
  result.add templateDef

template notMountainAt(map: Map; x, y: int): untyped =
  map.terrain[x][y] != '#'

#[
template northAvailable(map: Map, pos: Pos): bool =
  let
    x = pos.x
    y = pos.toNorth
  if x >= 0 and map.notMountainAt(x, y): true
  else: false

template eastAvailable(map: Map, pos: Pos): bool =
  let
    x = pos.toEast
    y = pos.y
  if x < map.wide and map.notMountainAt(x, y): true
  else: false

template southAvailable(map: Map, pos: Pos): bool =
  let
    x = pos.x
    y = pos.toSouth
  if y < map.length and map.notMountainAt(x, y): true
  else: false

template westAvailable(map: Map, pos: Pos): bool =
  let
    x = pos.toWest
    y = pos.y
  if x >= 0 and map.notMountainAt(x, y): true
  else: false
]#

"North".available
"South".available
"East".available
"West".available

proc nextVisiting(pos: Pos, map: var Map): seq[Pos] =
  result = newSeq[Pos]()
  if map.northAvailable(pos): result.add Pos(row: pos.toNorth, col: pos.col)
  if map.southAvailable(pos): result.add Pos(row: pos.toSouth, col: pos.col)
  if map.eastAvailable(pos): result.add Pos(row: pos.row, col: pos.toEast)
  if map.westAvailable(pos): result.add Pos(row: pos.row, col: pos.toWest)


proc getMap(f: var File): Map =
  let
    length = f.readLine.parseInt
    wide = f.readLine.parseInt
  var
    terrain = newSeq[string]()
  for i in 0 ..< length:
    terrain.add f.readLine
  Map(length: length, wide: wide, terrain: terrain)

proc `$`(map: Map): string =
  result = "The map with length " & $map.length & " and wide " &
    $map.wide & ":\n"
  let length = map.length
  for i in 0 ..< length:
    when defined(todebug):
      let
        lineinput = $i
        itslen = lineinput.len
      result &= spaces(max(0, 2-itslen)) & lineinput & " "
    result &= map.terrain[i]
    if i != length-1:
      result &= "\n"

proc dispatch(map: var Map, army: Army): DispatchResult
#proc walkMap(map: Map): Armies =
proc walkMap(map: var Map): seq[DispatchResult] =
  #result = newSeq[Army]()
  result = newSeq[DispatchResult]()
  let lowerascii = { 'a' .. 'z' }
  for i in 0 ..< map.length:
    for j in 0 ..< map.wide:
      let c = map.terrain[i][j]
      if c in lowerascii:
        result.add map.dispatch(Army(faction: c, pos: Pos(row: i, col: j)))

proc contestedTerrain(map: Map, army: Army, pos: Pos): bool =
  let atTerrain = map.terrain[pos.row][pos.col]
  if atTerrain != '.' and atTerrain != army.faction: true
  else: false

proc alliedForce(map: Map, army: Army, pos: Pos): bool =
  army.pos != pos and map.terrain[pos.row][pos.col] == army.faction

proc dispatch(map: var Map, army: Army): DispatchResult =
  when defined(trailvisit):
    echo army.faction, " faction is dispatched with pos ", army.pos
  result.army = army
  var
    visited = newSeq[Pos]()
    contesting = newSeq[Army]()
    region = newSeq[Pos]()

  proc walkin(map: var Map, nextPos: seq[Pos]) =
    if nextPos.len == 0:
      return
    for pos in nextPos:
      if pos notin region:
        region.add pos
      if map.alliedForce(army, pos):
        when defined(trailvisit):
          stdout.write("current faction ", army.faction, " at: ")
          stdout.write(army.pos.row, " ", army.pos.col, " found allied ")
          stdout.write("force with label ", map.terrain[pos.row][pos.col])
          echo " at: ", pos.row, " ", pos.col
        map.terrain[pos.row][pos.col] = '.'
      #echo "Now pos is ", pos
      if pos in visited:
        #echo pos, " is in visited"
        continue
      elif not map.contestedTerrain(army, pos):
        visited.add pos
        map.walkin(pos.nextVisiting map)
      else:
        visited.add pos
        let otherfaction = map.terrain[pos.row][pos.col]
        when defined(trailvisit):
          stdout.write("current faction ", army.faction, " at: ")
          stdout.write(army.pos.row, " ", army.pos.col, " found enemy")
          stdout.write("force with label ", otherfaction)
          echo " at: ", pos.row, " ", pos.col
        contesting.add Army(faction: otherFaction, pos: pos)
        map.walkin(pos.nextVisiting map)

  visited.add army.pos
  region.add army.pos
  map.walkin(army.pos.nextVisiting map)
  #echo army.faction, " faction with contesting status ", contesting
  result.contested = contesting
  region.sort cmp

  result.army.region = region


proc main =
  var filename = "armyfaction.input.sample"
  when declared(paramCount) and declared(paramStr):
    if paramCount() > 0:
      filename = paramStr 1
  var fp = open filename
  var casetimes = parseInt fp.readLine


  const specificmap{.intdefine.} = 0
  when defined(todebug):
    if filename != "armyfaction.input.sample" and specificmap == 0:
      casetimes = 1
    echo "specificmap: ", specificmap
    echo "case times is ", casetimes
  for i in 1 .. casetimes:
    echo "Case ", i, ":"
    var map = fp.getMap
    if specificmap != 0 and i != specificmap:
      continue
    when defined(todebug):
      #echo "length: ", map.length, ", wide: ", map.wide
      echo map

    var
      armies = map.walkMap
      regionControllers = armies.filterIt(it.contested.len == 0)
      conflictingFactions = armies.filterIt(it.contested.len != 0)
    regionControllers.sort(proc (x, y: DispatchResult): int =
      cmp x.army.faction, y.army.faction)

    var labelfact = regionControllers.map(
      proc(x: DispatchResult): Faction = x.army.faction).toCountTable

    for faction, region in labelfact:
      echo faction, " ", region

    var conflictregion = newSeq[seq[Pos]]()
    var regionconflict = 0
    when defined(todebug):
      var countcontested = 0
    for d in conflictingFactions:
      #echo d.army.region
      when defined(todebug):
        stdout.write("conflict ", countcontested)
        echo " faction ", d.army.faction, d.army.region
        inc countcontested
      let region = d.army.region.sorted cmp
      if region notin conflictregion:
      #if d.army.region notin conflictregion:
        when defined(todebug):
          echo "faction ", d.army.faction, " region area ",
            d.army.region.len
          echo "added to list conflictregion"
        inc regionconflict
        conflictregion.add d.army.region

    when defined(todebug):
      if conflictregion.len > 1:
        let
          reg1 = conflictregion[0]
          reg2 = conflictregion[1]
          lengtharea = min(reg1.len, reg2.len)
        var count = 0
        for i in 0 ..< lengtharea:
          echo "reg1: ", reg1[i], ", reg2: ", reg2[i]
          if reg1[i] == reg2[i]:
            echo reg1[i],  " == ", reg2[i]
            inc count
          else:
            echo "not same!"
        if count != lengtharea:
          echo "it's different!"
          echo "count: ", count, " and area: ", lengtharea
    if regionconflict > 0:
      echo "contested ", regionconflict

  fp.close

when isMainModule:
  main()
