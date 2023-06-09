# Package

version       = "0.3.0"
author        = "Keisuke Izumiya"
description   = "Puyo Puyo Library"
license       = "Apache-2.0 OR MPL-2.0"

srcDir        = "src"
installExt    = @["nim"]


# Dependencies

requires "nim >= 1.6.14"

requires "nimsimd >= 1.2.5"


# Tasks

import os
import strformat

task test, "Test":
  let mainFile = "./src/puyo_core.nim".unixToNativePath
  exec &"nim doc --project --index {mainFile}"
  rmDir "./src/htmldocs".unixToNativePath

  exec "testament all"
