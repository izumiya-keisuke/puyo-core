import options
import unittest

import ../../src/puyo_core/position {.all.}

proc main* =
  # axisCol, childCol, childDir
  block:
    check POS_2R.axisCol == 2
    check POS_2R.childCol == 3
    check POS_2R.childDir == RIGHT

  # shiftedRight, shiftedLeft, shiftRight, shiftLeft
  block:
    for (pos, answer) in [(POS_2R, POS_3R), (POS_6L, POS_6L)]:
      check pos.shiftedRight == answer

      var pos2 = pos
      pos2.shiftRight
      check pos2 == answer

    for (pos, answer) in [(POS_3D, POS_2D), (POS_1U, POS_1U)]:
      check pos.shiftedLeft == answer

      var pos2 = pos
      pos2.shiftLeft
      check pos2 == answer

  # rotatedRight, rotatedLeft, rotateRight, rotateLeft
  block:
    for (pos, answer) in [(POS_4L, POS_4U), (POS_6U, POS_5R)]:
      check pos.rotatedRight == answer

      var pos2 = pos
      pos2.rotateRight
      check pos2 == answer

    for (pos, answer) in [(POS_5D, POS_5R), (POS_1U, POS_2L)]:
      check pos.rotatedLeft == answer

      var pos2 = pos
      pos2.rotateLeft
      check pos2 == answer

  # makePosition
  block:
    check makePosition(5, LEFT) == POS_5L

  # toUrl, toPosition
  block:
    for (pos, url) in [(POS_4D.some, "u"), (Position.none, "1")]:
      check pos.toUrl == url
      check url.toPosition(true) == pos.some
      if pos.isSome:
        check $pos.get == $pos.get.axisCol & $pos.get.childDir
