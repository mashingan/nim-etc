# Package

version       = "0.1.0"
author        = "mashingan"
description   = "A simple jester example"
license       = "MIT"
bin           = @["crud_web"]
skipDirs      = @["test"]

# Dependencies

requires "nim >= 0.18.0"
requires "jester < 0.3.0"
