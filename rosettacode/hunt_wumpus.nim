# rosetta page ref:
#http://rosettacode.org/wiki/Hunt_The_Wumpus
#
# However this implementation isn't going to go the Wumpus page because
# the map is still random room assignment instead of dodecahedron.
# The important proc is __playing__ proc, as it will loop the state of
# whether we are still playing or not. And displaying the info of our room
# in __posInfo__ proc.

import random, strformat, sequtils, strutils, terminal

type
  Rooms = range[0 .. 19]
  RoomsMap = object
    num: Rooms
    next: seq[Rooms]
  Maze = seq[RoomsMap]
  GameState = enum
    gsPlaying gsWin gsLose gsMenu

  Ammo = range[0 .. 5]
  Game = ref object
    player: Rooms
    state: GameState
    wumpus: Rooms
    arrow: Ammo
    map: Maze
    bats: array[2, Rooms]
    pits: array[2, Rooms]

proc mumpusMove(g: Game): bool =
  template maybeWake: untyped = 1.0.rand >= 0.25
  if maybeWake():
    g.wumpus = rand g.map[g.wumpus].next
    result = true
  else:
    result = false

proc shootTo(g: Game; room: Rooms) =
  if g.arrow > 0 and room in g.map[g.player].next:
    dec g.arrow
    if g.wumpus == room:
      g.state = gsWin
      return
    if g.arrow == 0:
      g.state = gsLose
      return

    if g.mumpusMove and g.wumpus == g.player:
      g.state = gsLose
      return

proc movedBats(g: Game) =
  g.player = block:
    var newroom = rand Rooms
    while newroom == g.wumpus or newroom in g.bats or newroom in g.pits:
      newroom = rand Rooms
    newroom

proc moveTo(g: Game, room: Rooms) =
  if room == g.wumpus or room in g.pits:
    g.state = gsLose
    return
  if room in g.map[g.player].next:
    g.player = room
    return
  if room in g.bats:
    g.movedBats
    return

proc map: Maze =
  result = newseq[RoomsMap](20)
  for i in 0 .. Rooms.high:
    var next = newseq[Rooms](3)
    for j in 0 .. 2: next[j] = rand Rooms
    result[i] = RoomsMap(num: i, next: next)

proc posInfo(g: Game) =
  let nextrooms = g.map[g.player].next
  if g.wumpus in nextrooms:
    echo "You smell something terrible nearby."
  for room in nextrooms:
    if room in g.pits:
      echo "You feel a cold wind blowing from a nearby cavern."
    elif room in g.bats:
      echo "You hear a rustling."

proc getRoom(s: string, nextrooms: seq[Rooms]): Rooms =
  var pos = -1
  let roomdisplay = nextrooms.mapIt($it).join(", ")
  while pos == -1:
    stdout.write &"\n {s} To {roomdisplay} ? "
    try:
      pos = stdin.readLine.parseInt
    except:
      echo "Invalid input. Try again."
      continue

    if pos notin nextrooms:
      echo "Invalid room direction number. Try again"
      pos = -1
  pos


proc playing(g: Game): bool =
  let nextrooms = g.map[g.player].next
  let roomdisplay = nextrooms.mapIt("@" & $it).join(", ")
  echo &"You're in room {g.player}. You can:"
  echo &"a). [m]ove to room: {roomdisplay}."
  echo &"b). [s]hoot to room: {roomdisplay}."
  var choice: char
  while (stdout.write("Your choice? "); choice = getch().toLowerAscii; choice) != 'm' and choice != 's':
    echo "\nYou can only choose: m/M or s/S."
  let room = block:
    if choice == 'm': "move".getRoom nextrooms
    else: "shoot".getRoom nextrooms
  case choice
  of 'm': g.moveTo room
  of 's': g.shootTo room
  else: discard

  if g.state in [gsWin, gsLose]:
    result = false
  else:
    result = true


proc initGame: Game =
  let bats = [rand Rooms, rand Rooms]
  let pits = block:
    var res: array[2, Rooms]
    var x = -1
    var i = 0
    while i < 2:
      x = rand Rooms
      if x notin bats:
        res[i] = x
        inc i
    res
  let wumpus = block:
    var res: Rooms
    while true:
      res = rand Rooms
      if res notin pits or res notin bats: break
    res

  Game(
    player: rand Rooms,
    wumpus: wumpus,
    state: gsPlaying,
    arrow: 5,
    map: map(),
    bats: bats,
    pits: pits)

var game: Game
proc main =
  echo "Welcome to Hunt The Mumpus."
  game = initGame()
  while game.playing:
    game.posInfo

  if game.state == gsWin:
    echo "You win!"
  elif game.state == gsLose:
    echo "You lose!"

  stdout.write "Again [y/Y]? "
  case getch().toLowerAscii:
  of 'y':
    echo()
    main()
  else: discard

randomize()
main()
