import math
from sugar import dump

proc sqrt_newt(x: float, init = 1.0): float =
  template newguess(guess: float): untyped =
    (guess + (x / guess)) / 2.0

  result = newguess init
  while abs(result^2 - x) > 1e-9:
    result = newguess result

proc cube_newt(x: float, init = 1.0): float =
  template newguess(guess: float): untyped =
    ((x / guess^2) + 2*guess) / 3.0

  result = newguess init
  while abs(result^3 - x) > 1e-12:
    result = newguess result

dump 2.0.sqrt_newt
dump 9.0.sqrt_newt
echo "================="
dump 8.0.cube_newt
dump 27.0.cube_newt
