# Package

version       = "0.1.0"
author        = "Keisuke Izumiya"
description   = "Puyo Puyo Library"
license       = "Apache-2.0 OR MPL-2.0"

srcDir        = "src"
installExt    = @["nim"]


# Dependencies

requires "nim >= 1.6.12"

requires "nimsimd >= 1.2.5"


# Tasks

task test, "Test":
  exec "testament all"
