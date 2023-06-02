import options
import std/setutils
import unittest

import ../../src/puyo_core/cell
import ../../src/puyo_core/env
import ../../src/puyo_core/moveResult {.all.}
import ../../src/puyo_core/position

proc main* =
  # ------------------------------------------------
  # Number, Score
  # ------------------------------------------------

  # puyoNum, colorNum, puyoNums, colorNums, score
  block:
    let envBefore =
      "https://ishikawapuyo.net/simu/pe.html?g00g00G00a00h00m00l00q00t03l03h06b02r_o1c1".toEnv(
      true, ColorPuyo.fullSet.some
    ).get

    block:
      var env = envBefore
      let res = env.moveWithDetailTracking POS_4D
      check res.puyoNum == 25
      check res.colorNum == 23
      check res.puyoNums == @[6, 10, 9]
      check res.colorNums == @[5, 10, 8]

    block:
      var env = envBefore
      let res = env.moveWithFullTracking POS_4D
      check res.score == 2720
