## This module implements the disappearing result.
##

import bitops
import sequtils

import ./binary
import ../../unionFind
import ../../../cell
import ../../../common

type DisappearResult* = tuple
  ## Disappearing result.
  red: BinaryField
  greenBlue: BinaryField
  yellowPurple: BinaryField
  garbage: BinaryField
  color: BinaryField

func notDisappeared*(res: DisappearResult): bool {.inline.} =
  ## Returns :code:`true` if no (color) puyoes disappeared.
  res.color.isZero

func numbers*(res: DisappearResult): array[Puyo, Natural] {.inline.} =
  ## Returns the number of puyoes that disappeared.
  [
    Natural 0,
    res.garbage.popcnt,
    res.red.popcnt,
    res.greenBlue.popcnt 0,
    res.greenBlue.popcnt 1,
    res.yellowPurple.popcnt 0,
    res.yellowPurple.popcnt 1]

func connectionDetail(field: BinaryField): tuple[color1: seq[Natural], color2: seq[Natural]] {.inline.} =
  ## Returns the number of cells for each connected component.
  ## The order of the returned sequence is undefined.
  ## This function ignores ghost puyoes.
  # TODO: make faster
  let fieldArray = cast[array[16, uint16]](field)

  var
    components: array[Row.high - Row.low + 3, array[Col.high - Col.low + 3, tuple[color: int, idx: Natural]]]
    uf = initUnionFind Height * Width
    nextComponentIdx = 1.Natural
  for col in Col.low .. Col.high:
    # NOTE: YMM[e15, ..., e0] == array[e0, ..., e15]
    let
      colVal1 = fieldArray[15 - col]
      colVal2 = fieldArray[7 - col]

    for row in Row.low .. Row.high:
      let
        rowDigit = 14 - row
        color = colVal1.testBit(rowDigit).int or (colVal2.testBit(rowDigit).int shl 1)
      if color == 0:
        continue

      components[row][col].color = color

      let
        up = components[row.int.pred][col]
        left = components[row][col.int.pred]
      if up.color == color:
        if left.color == color:
          components[row][col].idx = min(up.idx, left.idx)
          uf.merge up.idx, left.idx
        else:
          components[row][col].idx = up.idx
      else:
        if left.color == color:
          components[row][col].idx = left.idx
        else:
          components[row][col].idx = nextComponentIdx
          nextComponentIdx.inc

  var numsArray = [0.Natural.repeat nextComponentIdx, 0.Natural.repeat nextComponentIdx]
  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      let (color, idx) = components[row][col]
      if color == 0:
        continue

      numsArray[color.pred][uf.getRoot idx].inc

  return (numsArray[0].filterIt it > 0, numsArray[1].filterIt it > 0)

func connections*(res: DisappearResult): array[Puyo, seq[Natural]] {.inline.} =
  ## Returns the number of puyoes in each connected component.
  let
    red = res.red.connectionDetail[1]
    greenBlue = res.greenBlue.connectionDetail
    yellowPurple = res.yellowPurple.connectionDetail
    garbage = res.garbage.connectionDetail[1]

  return [
    newSeq[Natural] 0,
    garbage,
    red,
    greenBlue[0],
    greenBlue[1],
    yellowPurple[0],
    yellowPurple[1]]
