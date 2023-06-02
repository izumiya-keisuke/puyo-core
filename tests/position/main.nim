import options
import unittest

import ../../src/puyo_core/position {.all.}

proc main* =
  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------

  # makePosition
  block:
    check makePosition(5, LEFT) == POS_5L

  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # axisCol, childCol, childDir
  block:
    check POS_2R.axisCol == 2
    check POS_2R.childCol == 3
    check POS_2R.childDir == RIGHT

  # ------------------------------------------------
  # Move
  # ------------------------------------------------

  # movedRight, movedLeft, moveRight, moveLeft
  block:
    for (pos, answer) in [(POS_2R, POS_3R), (POS_6L, POS_6L)]:
      check pos.movedRight == answer

      var pos2 = pos
      pos2.moveRight
      check pos2 == answer

    for (pos, answer) in [(POS_3D, POS_2D), (POS_1U, POS_1U)]:
      check pos.movedLeft == answer

      var pos2 = pos
      pos2.moveLeft
      check pos2 == answer

  # ------------------------------------------------
  # Rotate
  # ------------------------------------------------

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

  # ------------------------------------------------
  # Position <-> string
  # ------------------------------------------------

  # toUrl, toPosition
  block:
    for (pos, url) in [(POS_4D.some, "u"), (Position.none, "1")]:
      check pos.toUrl == url
      check url.toPosition(true) == pos.some
      if pos.isSome:
        check $pos.get == $pos.get.axisCol & $pos.get.childDir
