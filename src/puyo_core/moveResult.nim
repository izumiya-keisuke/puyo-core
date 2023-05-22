## This module implements a moving result.
##

import math
import options
import sequtils
import std/setutils
import sugar

import ./cell
import ./common

type MoveResult* = tuple
  chainNum: Natural
  totalDisappearNums: Option[array[Puyo, Natural]]
  disappearNums: Option[seq[array[Puyo, Natural]]]
  detailedDisappearNums: Option[seq[array[Puyo, seq[Natural]]]]

func puyoNum*(res: MoveResult): int {.inline.} =
  ## Gets the total number of disappeared puyoes.
  ## This function assumes that :code:`res.totalDisappearNums` is not none.
  res.totalDisappearNums.get.sum

func colorNum*(res: MoveResult): int {.inline.} =
  ## Gets the total number of disappeared color puyoes.
  ## This function assumes that :code:`res.totalDisappearNums` is not none.
  res.totalDisappearNums.get[ColorPuyo.low.Puyo .. ColorPuyo.high.Puyo].sum

func puyoNums*(res: MoveResult): seq[int] {.inline.} =
  ## Gets the number of disappeared puyoes at each chain.
  ## This function assumes that :code:`res.disappearNums` is not none.
  res.disappearNums.get.mapIt it.sum.int

func colorNums*(res: MoveResult): seq[int] {.inline.} =
  ## Gets the number of disappeared color puyoes at each chain.
  ## This function assumes that :code:`res.disappearNums` is not none.
  res.disappearNums.get.mapIt it[ColorPuyo.low.Puyo .. ColorPuyo.high.Puyo].sum.int

func calcDisappearNumAndConnectBonus(
  detailedDisappearNums: seq[Natural],
): tuple[disappearNum: int, connectBonus: int] {.inline.} =
  ## Returns the number of disappeared puyoes and a connect bonus.
  const ConnectBonuses = collect:
    for connect in 0 .. Height.pred * Width:
      if connect <= 4:
        0
      elif connect in 5 .. 10:
        connect - 3
      else:
        10

  for num in detailedDisappearNums:
    result.disappearNum.inc num
    result.connectBonus.inc ConnectBonuses[num]

func score*(res: MoveResult): int {.inline.} =
  ## Returns the score.
  ## This function assumes that res.detailedDisappearNums is not none.
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

  for i, disappearNumsForEachPuyo in res.detailedDisappearNums.get:
    let
      (redNum, redConnectBonus) = disappearNumsForEachPuyo[RED].calcDisappearNumAndConnectBonus
      (greenNum, greenConnectBonus) = disappearNumsForEachPuyo[GREEN].calcDisappearNumAndConnectBonus
      (blueNum, blueConnectBonus) = disappearNumsForEachPuyo[BLUE].calcDisappearNumAndConnectBonus
      (yellowNum, yellowConnectBonus) = disappearNumsForEachPuyo[YELLOW].calcDisappearNumAndConnectBonus
      (purpleNum, purpleConnectBonus) = disappearNumsForEachPuyo[PURPLE].calcDisappearNumAndConnectBonus

      chainBonus = ChainBonuses[i.succ]
      connectBonus = redConnectBonus + greenConnectBonus + blueConnectBonus + yellowConnectBonus + purpleConnectBonus
      colorBonus = ColorBonuses[
        (redNum > 0).int + (greenNum > 0).int + (blueNum > 0).int + (yellowNum > 0).int + (purpleNum > 0).int
      ]

    result.inc 10 * (redNum + greenNum + blueNum + yellowNum + purpleNum) * max(
      chainBonus + connectBonus + colorBonus, 1
    )
