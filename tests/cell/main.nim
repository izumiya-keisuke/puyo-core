import options
import unittest

import ../../src/puyo_core/cell {.all.}

proc main* =
  # ------------------------------------------------
  # Cell <-> string
  # ------------------------------------------------

  # toCell
  block:
    for cell in Cell:
      check ($cell).toCell == some cell

    check "".toCell == none Cell
    check "H".toCell == none Cell
