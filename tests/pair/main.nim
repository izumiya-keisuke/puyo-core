import deques
import options
import unittest

import ../../src/puyo_core/cell
import ../../src/puyo_core/pair {.all.}

proc main* =
  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------
  # makePair
  block:
    check makePair(YELLOW, GREEN) == YG
    check makePair(PURPLE, PURPLE) == PP

  # ------------------------------------------------
  # Property
  # ------------------------------------------------

  # axis, child
  block:
    check BR.axis == BLUE
    check BR.child == RED

  # axis=, child=
  block:
    var pair = RR
    pair.axis = BLUE
    check pair == BR
    pair.child = GREEN
    check pair == BG

  # isDouble
  block:
    check not PR.isDouble
    check PP.isDouble

  # ------------------------------------------------
  # Operator
  # ------------------------------------------------

  # ==
  block:
    let pairs1 = [RR, PG].toDeque
    var pairs2: Pairs
    pairs2.addLast PG
    pairs2.addFirst RR
    check pairs1 == pairs2

  # ------------------------------------------------
  # Swap
  # ------------------------------------------------

  # swapped, swap
  block:
    check YB.swapped == BY
    check RR.swapped == RR

    var pair = GP
    pair.swap
    check pair == PG
