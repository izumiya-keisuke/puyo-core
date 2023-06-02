import deques
import options
import std/setutils
import strformat
import strutils
import unittest

import ../../src/puyo_core/cell
import ../../src/puyo_core/common
import ../../src/puyo_core/env {.all.}
import ../../src/puyo_core/field
import ../../src/puyo_core/moveResult
import ../../src/puyo_core/pair
import ../../src/puyo_core/position

proc main* =
  # ------------------------------------------------
  # Pair
  # ------------------------------------------------

  # addPair
  block:
    var env = ("......\n".repeat(12) & "o.....\n======\nbb").toEnv(false).get
    env.addPair
    check env.pairs.len == 2

  # ------------------------------------------------
  # Constructor
  # ------------------------------------------------

  # reset
  block:
    var env = ("......\n".repeat(12) & "....y.\n======\nbb").toEnv(false).get
    env.reset
    check env.field == zeroField()
    check env.pairs.len == 3

  # makeEnv
  block:
    let env = makeEnv(setPairs = false)
    check env.field == zeroField()
    check env.pairs.len == 0

  # ------------------------------------------------
  # Number
  # ------------------------------------------------

  # colorNum, garbageNum, puyoNum
  block:
    let env = ("......\n".repeat(11) & "rrb...\noogg..\n======\nry\ngg").toEnv(false).get

    check env.colorNum(RED) == 3
    check env.colorNum(BLUE) == 1
    check env.colorNum(PURPLE) == 0
    check env.colorNum == 9
    check env.garbageNum == 2
    check env.puyoNum == 11

  # ------------------------------------------------
  # Move
  # ------------------------------------------------

  # move, moveWithRoughTracking, moveWithDetailTracking, moveWithFullTracking
  block:
    let
      useColors = ColorPuyo.fullSet.some
      envBefore =
        "https://ishikawapuyo.net/simu/pe.html?g00g00G00a00h00m00l00q00t03l03h06b02r_o1c1".toEnv(true, useColors).get
      envAfter = "https://ishikawapuyo.net/simu/pe.html?100302r_c1".toEnv(true, useColors).get

      pos = POS_4D

      chainNum = 3
      totalDisappearNums: array[Puyo, Natural] = [Puyo.low: 0.Natural, 2, 4, 10, 5, 0, 4]
    # HACK: somehow direct definition does not work on cpp backend w/ ARC
    var disappearNums: seq[array[Puyo, Natural]]
    disappearNums.add [0.Natural, 1, 0, 0, 5, 0, 0]
    disappearNums.add [0.Natural, 0, 0, 10, 0, 0, 0]
    disappearNums.add [0.Natural, 1, 4, 0, 0, 0, 4]
    var detailDisappearNums: seq[array[Puyo, seq[Natural]]]
    detailDisappearNums.add [@[], @[1.Natural], @[], @[], @[5.Natural], @[], @[]]
    detailDisappearNums.add [@[], @[], @[], @[4.Natural, 6], @[], @[], @[]]
    detailDisappearNums.add [@[], @[1.Natural], @[4.Natural], @[], @[], @[], @[4.Natural]]

    block:
      var env = envBefore
      let res = env.move(pos, false)
      check env == envAfter
      check res.chainNum == chainNum
      check res.totalDisappearNums.isNone
      check res.disappearNums.isNone
      check res.detailDisappearNums.isNone

    block:
      var env = envBefore
      let res = env.moveWithRoughTracking(pos, false)
      check env == envAfter
      check res.chainNum == chainNum
      check res.totalDisappearNums == totalDisappearNums.some
      check res.disappearNums.isNone
      check res.detailDisappearNums.isNone

    block:
      var env = envBefore
      let res = env.moveWithDetailTracking(pos, false)
      check env == envAfter
      check res.chainNum == chainNum
      check res.totalDisappearNums == totalDisappearNums.some
      check res.disappearNums == disappearNums.some
      check res.detailDisappearNums.isNone

    block:
      var env = envBefore
      let res = env.moveWithFullTracking(pos, false)
      check env == envAfter
      check res.chainNum == chainNum
      check res.totalDisappearNums == totalDisappearNums.some
      check res.disappearNums == disappearNums.some
      check res.detailDisappearNums == detailDisappearNums.some

  # ------------------------------------------------
  # Env <-> string
  # ------------------------------------------------

  # $, toStr, toUrl, toEnvPositions, toEnv
  block:
    let
      fieldStr = "......\n".repeat(12) & "rg.bo."
      pairsStr = "yy\ngp"
      pairsWithPosStr = "yy\ngp|2<"
      envStr = &"{fieldStr}{EnvSep}{pairsStr}"
      envWithPosStr = &"{fieldStr}{EnvSep}{pairsWithPosStr}"

      env = envStr.toEnv(false).get
      url = "https://ishikawapuyo.net/simu/ps.html?a3M_G1O1"
      urlWithPos = "https://ishikawapuyo.net/simu/ps.html?a3M_G1OC"
      positions = @[Position.none, POS_2L.some]

    check $env == envStr
    check env.toStr == envStr
    check env.toStr(positions.some) == envWithPosStr
    check env.toUrl == url
    check env.toUrl(positions.some) == urlWithPos
    check envWithPosStr.toEnvPositions(false) == (env: env, positions: positions).some
    check urlWithPos.toEnvPositions(true) == (env: env, positions: positions).some
    check envWithPosStr.toEnv(false) == env.some
    check urlWithPos.toEnv(true) == env.some

  # toArrays, toEnv
  block:
    var fieldArray: array[Row, array[Col, Cell]]
    fieldArray[13][1] = GARBAGE
    fieldArray[13][3] = PURPLE
    let env = ("......\n".repeat(12) & "o.p...\n======\nbr").toEnv(false).get

    check env.toArrays == (field: fieldArray, pairs: @[[BLUE.ColorPuyo, RED]])
    check toEnv(fieldArray, [[BLUE.ColorPuyo, RED]]) == env
