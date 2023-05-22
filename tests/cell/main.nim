import options
import unittest

import ../../src/puyo_core/cell {.all.}

proc main* =
  # toCell
  block:
    check ".".toCell == NONE.some
    check "r".toCell == RED.some
