from std/sugar import dump

type
  ObserveObj[T] = object
    value: T
    react: owned proc():T {.closure.}

proc `=copy`[T](o1: var ObserveObj[T], o2: ObserveObj[T]) {.error.}
proc `=dup`[T](o: ObserveObj[T]): ObserveObj[T] {.error.}

proc `=trace`[T](o: var ObserveObj[T], env: pointer) =
  `=trace`(o.value, env)
  if o.react != nil:
    `=trace`(o.react, env)

proc `=sink`[T](ob1: var ObserveObj[T], kenobi: ObserveObj[T]) =
  `=destroy`(ob1)
  wasMoved(ob1)
  ob1.value = kenobi.value
  ob1.react = kenobi.react
  #if ob1.react != nil: ob1.value = ob1.react()

template `:=`(o: var ObserveObj, body: untyped) =
  o.react = block:
    unown proc(): o.value.type {.closure.} = body

template `:=`(res: untyped, o: var ObserveObj) {.used.} =
  o.value = o.react()
  res = o.value

proc `$`(o: var ObserveObj): string =
  o.value = o.react()
  $o.value

proc useObservation[T](o: sink ObserveObj[T]) =
  dump o

proc `value`[T](ob1: var ObserveObj[T]): T =
  ob1.value = ob1.react()
  ob1.value

proc main =
  var a = 10
  var b = ObserveObj[int]()
  var c = ObserveObj[int]()
  b := a + 1
  c := b.value + 3
  dump a
  dump b
  dump c
  a = 20
  dump a
  dump b
  dump c
  useObservation c
  ## uncomment below for error use-after-move
  # dump c
  
main()
