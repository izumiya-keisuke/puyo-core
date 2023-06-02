## This module implements the disappearing result.
##

import sequtils

import ../../unionFind
import ../../../cell
import ../../../common

when defined(cpu32):
  import ./bit32/binary
else:
  import ./bit64/binary

type DisappearResult* = tuple
  ## Disappearing result.
  red: BinaryField
  green: BinaryField
  blue: BinaryField
  yellow: BinaryField
  purple: BinaryField
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
    res.green.popcnt,
    res.blue.popcnt,
    res.yellow.popcnt,
    res.purple.popcnt]

func connectionDetail(field: BinaryField): seq[Natural] {.inline.} =
  ## Returns the number of cells for each connected component.
  ## The order of the returned sequence is undefined.
  ## This function ignores ghost puyoes.
  # TODO: make faster
  var
    components: array[Row.high - Row.low + 3, array[Col.high - Col.low + 3, Natural]]
    uf = initUnionFind Height * Width
    nextComponentIdx = 1.Natural
  for col in Col.low .. Col.high:
    for row in Row.low .. Row.high:
      if not field[row, col]:
        continue

      let
        up = components[row.int.pred][col]
        left = components[row][col.int.pred]
      if up != 0:
        if left != 0:
          components[row][col] = min(up, left)
          uf.merge up, left
        else:
          components[row][col] = up
      else:
        if left != 0:
          components[row][col] = left
        else:
          components[row][col] = nextComponentIdx
          nextComponentIdx.inc

  var nums = 0.Natural.repeat nextComponentIdx
  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      let idx = components[row][col]
      if idx == 0:
        continue

      nums[uf.getRoot idx].inc

  return nums.filterIt it > 0

func connections*(res: DisappearResult): array[Puyo, seq[Natural]] {.inline.} =
  ## Returns the number of puyoes in each connected component.
  [
    newSeq[Natural] 0,
    res.garbage.connectionDetail,
    res.red.connectionDetail,
    res.green.connectionDetail,
    res.blue.connectionDetail,
    res.yellow.connectionDetail,
    res.purple.connectionDetail]
