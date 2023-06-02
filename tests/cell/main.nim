import options
import unittest

import ../../src/puyo_core/cell {.all.}

proc main* =
  # ------------------------------------------------
  # Cell <-> string
  # ------------------------------------------------

  # toCell
  block:
    check ".".toCell == some NONE
    check "r".toCell == some RED
