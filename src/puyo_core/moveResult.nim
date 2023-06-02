## This module implements the moving result.
##

import math
import options
import sequtils
import std/setutils
import sugar

import ./cell
import ./common

type MoveResult* = tuple
  ## Moving result.
  ## * :code:`chainNum`: Number of chains.
  ## * :code:`totalDisappearNums`: Number of each puyoes that disappeared.
  ## * :code:`disappearNums`: Number of each puyoes that disappeared in each chain.
  ## * :code:`detailDisappearNums`: Number of each puyoes in each connected component that disappeared in each chain.
  chainNum: Natural
  totalDisappearNums: Option[array[Puyo, Natural]]
  disappearNums: Option[seq[array[Puyo, Natural]]]
  detailDisappearNums: Option[seq[array[Puyo, seq[Natural]]]]

# ------------------------------------------------
# Number
# ------------------------------------------------

func puyoNum*(res: MoveResult): int {.inline.} =
  ## Returns the number of puyoes that disappeared.
  # for performance, we only assert instead of using Option type as the return value.
  assert res.totalDisappearNums.isSome, "`MoveResult.puyoNum` requires that `MoveResult.totalDisappearNums` be set."

  return res.totalDisappearNums.get.sum

func colorNum*(res: MoveResult): int {.inline.} =
  ## Returns the number of color puyoes that disappeared.
  # for performance, we only assert instead of using Option type as the return value.
  assert res.totalDisappearNums.isSome, "`MoveResult.colorNum` requires that `MoveResult.totalDisappearNums` be set."

  return res.totalDisappearNums.get[ColorPuyo.low.Puyo .. ColorPuyo.high.Puyo].sum

func puyoNums*(res: MoveResult): seq[int] {.inline.} =
  ## Returns the number of puyoes that disappeared in each chain.
  # for performance, we only assert instead of using Option type as the return value.
  assert res.disappearNums.isSome, "`MoveResult.puyoNums` requires that `MoveResult.disappearNums` be set."

  return res.disappearNums.get.mapIt it.sum.int

func colorNums*(res: MoveResult): seq[int] {.inline.} =
  ## Returns the number of color puyoes that disappeared in each chain.
  # for performance, we only assert instead of using Option type as the return value.
  assert res.disappearNums.isSome, "`MoveResult.colorNums` requires that `MoveResult.disappearNums` be set."

  return res.disappearNums.get.mapIt it[ColorPuyo.low.Puyo .. ColorPuyo.high.Puyo].sum.int

# ------------------------------------------------
# Score
# ------------------------------------------------

func totalNumAndConnectBonus(
  numsInConnectComponents: seq[Natural],
): tuple[totalNum: int, connectBonus: int] {.inline.} =
  ## Returns the number of puyoes that disappeared and the connect bonus.
  const ConnectBonuses = collect:
    for connect in 0 .. Height.pred * Width:
      if connect <= 4:
        0
      elif connect in 5 .. 10:
        connect - 3
      else:
        10

  for num in numsInConnectComponents:
    result.totalNum.inc num
    result.connectBonus.inc ConnectBonuses[num]

func score*(res: MoveResult): int {.inline.} =
  ## Returns the score.
  # for performance, we only assert instead of using Option type as the return value.
  assert res.detailDisappearNums.isSome, "`MoveResult.score` requires that `MoveResult.detailDisappearNums` be set."

  const
    ChainBonuses = collect:
      for chain in 0 .. Height * Width div 4:
        if chain <= 1:
          0
        elif chain in 2 .. 5:
          8 * 2 ^ (chain - 2)
        else:
          64 + 32 * (chain - 5)
    ColorBonuses = collect:
      for color in 0 .. ColorPuyo.fullSet.card:
        if color <= 1:
          0
        else:
          3 * 2 ^ (color - 2)

  for chainIdx, numsInConnectComponentArray in res.detailDisappearNums.get:
    let
      (redNum, redConnectBonus) = numsInConnectComponentArray[RED].totalNumAndConnectBonus
      (greenNum, greenConnectBonus) = numsInConnectComponentArray[GREEN].totalNumAndConnectBonus
      (blueNum, blueConnectBonus) = numsInConnectComponentArray[BLUE].totalNumAndConnectBonus
      (yellowNum, yellowConnectBonus) = numsInConnectComponentArray[YELLOW].totalNumAndConnectBonus
      (purpleNum, purpleConnectBonus) = numsInConnectComponentArray[PURPLE].totalNumAndConnectBonus

      chainBonus = ChainBonuses[chainIdx.succ]
      connectBonus = redConnectBonus + greenConnectBonus + blueConnectBonus + yellowConnectBonus + purpleConnectBonus
      colorBonus = ColorBonuses[
        (redNum > 0).int + (greenNum > 0).int + (blueNum > 0).int + (yellowNum > 0).int + (purpleNum > 0).int
      ]

    result.inc 10 * (redNum + greenNum + blueNum + yellowNum + purpleNum) * max(
      chainBonus + connectBonus + colorBonus, 1
    )
