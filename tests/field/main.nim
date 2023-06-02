import options
import std/setutils
import strutils
import unittest

import ../../src/puyo_core/cell
import ../../src/puyo_core/common
import ../../src/puyo_core/field {.all.}
import ../../src/puyo_core/position

proc main* =
  # ------------------------------------------------
  # Indexer
  # ------------------------------------------------

  # [], []=, insert, removeSqueeze
  block:
    var field = ("......\n".repeat(12) & "g.r...").toField(false).get
    check field[13, 2] == NONE
    check field[13, 3] == RED

    field[13, 3] = YELLOW
    check field[13, 3] == YELLOW

    field.insert 13, 3, GARBAGE
    check field[12, 3] == YELLOW
    check field[13, 3] == GARBAGE

    field.removeSqueeze 13, 3
    check field[12, 3] == NONE
    check field[13, 3] == YELLOW

  # ------------------------------------------------
  # Connect
  # ------------------------------------------------

  # connect3
  block:
    let
      fieldTop = "......\n".repeat 8
      fieldBottom = """
bbbbrr
rggyyr
rgbbbr
ryyygb
ybybbb"""
      three = """
......
rgg...
rgbbb.
r.....
......"""
      threeV = """
......
r.....
r.....
r.....
......"""
      threeH = """
......
......
..bbb.
......
......"""
      threeL = """
......
.gg...
.g....
......
......"""

    let field = (fieldTop & fieldBottom).toField(false).get
    check field.connect3 == (fieldTop & three).toField(false).get
    check field.connect3V == (fieldTop & threeV).toField(false).get
    check field.connect3H == (fieldTop & threeH).toField(false).get
    check field.connect3L == (fieldTop & threeL).toField(false).get

  # ------------------------------------------------
  # Shift
  # ------------------------------------------------

  # shift
  block:
    var field1 = ("......\n".repeat(12) & "..o...").toField(false).get
    let field2 = ("......\n".repeat(12) & "...o..").toField(false).get
    let field3 = ("......\n".repeat(11) & "...o..\n......").toField(false).get

    check field2.shiftedLeft == field1
    check field1.shiftedRight == field2
    check field2.shiftedUp == field3
    check field3.shiftedDown == field2

    field1.shiftRight
    check field1 == field2

    field1.shiftUp
    check field1 == field3
    
  # ------------------------------------------------
  # Disappear
  # ------------------------------------------------

  # willDisappear
  block:
    var field = zeroField()
    field[1, 1] = BLUE
    field[2, 1] = BLUE
    field[3, 1] = BLUE
    field[3, 2] = BLUE
    check not field.willDisappear

    field[4, 2] = BLUE
    check field.willDisappear

  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # isDead
  block:
    var field = zeroField()
    field[2, 3] = BLUE
    check field.isDead

    for row in Row.low .. Row.high:
      for col in Col.low .. Col.high:
        field[row, col] = BLUE
    field[2, 3] = NONE
    check not field.isDead

  # ------------------------------------------------
  # Position
  # ------------------------------------------------

  # invalidPositions, validPositions, validDoublePositions
  block:
    var field = zeroField()
    field[13, 2] = RED
    check field.invalidPositions.card == 0
    check field.validPositions == Position.fullSet
    check field.validDoublePositions == DoublePositions

    field[2, 2] = RED
    check field.invalidPositions == {POS_1U, POS_1R, POS_1D, POS_2U, POS_2R, POS_2D, POS_2L, POS_3L}

    field[3, 6] = RED
    check field.invalidPositions == {POS_2D}

    field[3, 6] = NONE
    field[2, 4] = RED
    check field.invalidPositions == {POS_2D, POS_4D}

    field[1, 2] = RED
    check field.invalidPositions == {POS_1U, POS_1R, POS_1D, POS_2U, POS_2R, POS_2D, POS_2L, POS_3L, POS_4D}

    field = zeroField()
    field[2, 2] = RED
    field[3, 3] = RED
    field[2, 4] = RED
    field[1, 5] = RED
    check field.invalidPositions == {POS_2D, POS_4R, POS_4D, POS_5U, POS_5R, POS_5D, POS_5L, POS_6U, POS_6D, POS_6L}
