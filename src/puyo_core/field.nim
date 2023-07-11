## This module implements the field.
## The following implementations are supported:
## * Bitboard (Primitive)
## * `Bitboard (AVX2) <./private/field/avx2/main.html>`_
## 
## For performance comparison, alternative implementations can be used by the following compile-time options:
## * :code:`-d:altPrimitiveColor`
##

import options
import sequtils
import std/setutils
import strutils
import sugar
import tables

import ./cell
import ./common
import ./moveResult
import ./pair
import ./position
import ./private/field/binary
import ./private/intrinsic

when UseAvx2:
  import ./private/field/avx2/disappearResult
  import ./private/field/avx2/main
else:
  import ./private/field/primitive/disappearResult
  when defined(altPrimitiveColor):
    import ./private/field/primitive/altMainColor
  else:
    import ./private/field/primitive/main

export
  Field,
  zeroField,
  `==`,
  `[]`,
  `[]=`,
  insert,
  removeSqueeze,
  colorNum,
  garbageNum,
  puyoNum,
  connect3,
  connect3V,
  connect3H,
  connect3L,
  shiftedUp,
  shiftedDown,
  shiftedRight,
  shiftedLeft,
  disappear,
  willDisappear,
  put,
  drop,
  toArray,
  toField

# ------------------------------------------------
# Property
# ------------------------------------------------

func isDead*(field: Field): bool {.inline.} =
  ## Returns :code:`true` if :code:`field` is in a defeated state
  field.exist.isDead

# ------------------------------------------------
# Position
# ------------------------------------------------

func invalidPositions*(field: Field): set[Position] {.inline.} =
  ## Returns the invalid positions.
  field.exist.invalidPositions

func validPositions*(field: Field): set[Position] {.inline.} =
  ## Returns the valid positions.
  field.exist.validPositions

func validDoublePositions*(field: Field): set[Position] {.inline.} =
  ## Returns the valid positions for a double pair.
  field.exist.validDoublePositions

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftUp*(field: var Field) {.inline.} =
  ## Applies upward shift to the :code:`field`.
  field = field.shiftedUp

func shiftDown*(field: var Field) {.inline.} =
  ## Applies downward shift to the :code:`field`.
  field = field.shiftedDown

func shiftRight*(field: var Field) {.inline.} =
  ## Applies rightward shift to the :code:`field`.
  field = field.shiftedRight

func shiftLeft*(field: var Field) {.inline.} =
  ## Applies leftward shift to the :code:`field`.
  field = field.shiftedLeft

# ------------------------------------------------
# Move
# ------------------------------------------------

func move*(field: var Field, pair: Pair, pos: Position): MoveResult {.inline, discardable.} =
  ## Puts the :code:`pair` and advance the :code:`field` until the chain ends.
  ## This function tracks:
  ## * Number of chains
  field.put pair, pos

  while true:
    if field.disappear.notDisappeared:
      return

    field.drop

    result.chainNum.inc

func moveWithRoughTracking*(field: var Field, pair: Pair, pos: Position): MoveResult {.inline.} =
  ## Puts the :code:`pair` and advance the :code:`field` until the chain ends.
  ## This function tracks:
  ## * Number of chains
  ## * Number of each puyoes that disappeared
  field.put pair, pos

  var totalDisappearNums: array[Puyo, Natural]
  while true:
    let disappearResult = field.disappear
    if disappearResult.notDisappeared:
      result.totalDisappearNums = some totalDisappearNums
      return

    field.drop

    result.chainNum.inc
    for puyo, num in disappearResult.numbers:
      totalDisappearNums[puyo].inc num

func moveWithDetailTracking*(field: var Field, pair: Pair, pos: Position): MoveResult {.inline.} =
  ## Puts the :code:`pair` and advance the :code:`field` until the chain ends.
  ## This function tracks:
  ## * Number of chains
  ## * Number of each puyoes that disappeared
  ## * Number of each puyoes that disappeared in each chain
  field.put pair, pos

  var
    totalDisappearNums: array[Puyo, Natural]
    disappearNums: seq[array[Puyo, Natural]]
  while true:
    let disappearResult = field.disappear
    if disappearResult.notDisappeared:
      result.totalDisappearNums = some totalDisappearNums
      result.disappearNums = some disappearNums
      return 

    field.drop

    result.chainNum.inc
    let nums = disappearResult.numbers
    for puyo, num in nums:
      totalDisappearNums[puyo].inc num
    disappearNums.add nums

func moveWithFullTracking*(field: var Field, pair: Pair, pos: Position): MoveResult {.inline.} =
  ## Puts the :code:`pair` and advance the :code:`field` until the chain ends.
  ## This function tracks:
  ## * Number of chains
  ## * Number of each puyoes that disappeared
  ## * Number of each puyoes that disappeared in each chain
  ## * Number of each puyoes in each connected component that disappeared in each chain
  field.put pair, pos

  var
    totalDisappearNums: array[Puyo, Natural]
    disappearNums: seq[array[Puyo, Natural]]
    detailDisappearNums: seq[array[Puyo, seq[Natural]]]
  while true:
    let disappearResult = field.disappear
    if disappearResult.notDisappeared:
      result.totalDisappearNums = some totalDisappearNums
      result.disappearNums = some disappearNums
      result.detailDisappearNums = some detailDisappearNums
      return 

    field.drop

    result.chainNum.inc
    let nums = disappearResult.numbers
    for puyo, num in nums:
      totalDisappearNums[puyo].inc num
    disappearNums.add nums
    detailDisappearNums.add disappearResult.connections

# ------------------------------------------------
# Field <-> string
# ------------------------------------------------

func `$`*(field: Field): string {.inline.} =
  ## Converts :code:`field` to the string representation.
  let fieldArray = field.toArray
  var lines = newSeqOfCap[string] Height
  for row in Row.low .. Row.high:
    lines.add join fieldArray[row].mapIt $it

  return lines.join "\n"

const
  UrlChars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-"
  UrlCharToIdx = collect:
    for i, c in UrlChars:
      {c: i}
  CellToIdx: array[Cell, int] = [0, -1, 6, 1, 2, 3, 4, 5]
  IdxToCell = collect:
    for cell, idx in CellToIdx:
      {idx: cell}

func toUrl*(field: Field): string {.inline.} =
  ## Converts :code:`field` to the URL.
  let fieldArray = field.toArray
  var lines = newSeqOfCap[string] Height
  for row in Row.low .. Row.high:
    var chars = newSeqOfCap[char] Height div 2
    for i in 0 ..< Width div 2:
      let
        cell1 = fieldArray[row][Col.low.succ 2 * i]
        cell2 = fieldArray[row][Col.low.succ 2 * i + 1]

      chars.add UrlChars[CellToIdx[cell1] * Cell.fullSet.card + CellToIdx[cell2]]

    lines.add chars.join

  return lines.join.strip(trailing = false, chars = {'0'})

func toField*(str: string, url: bool): Option[Field] {.inline.} =
  ## Converts :code:`str` to the field.
  ## The string representation or URL is acceptable as :code:`str`,
  ## and which type of input is specified by :code:`url`.
  ## If the conversion fails, returns :code:`none(Field)`.
  if url:
    if str == "":
      return some zeroField()

    var fieldArray: array[Row, array[Col, Cell]]
    for i, c in '0'.repeat(Height * Width div 2 - str.len) & str:
      if c notin UrlCharToIdx:
        return

      let
        idx = UrlCharToIdx[c]
        cell1 = IdxToCell[idx div Cell.fullSet.card]
        cell2 = IdxToCell[idx mod Cell.fullSet.card]
        row = Row.low.succ i div (Width div 2)
        col = Col.low.succ i mod (Width div 2) * 2

      fieldArray[row][col] = cell1
      fieldArray[row][col.succ] = cell2

    return some fieldArray.toField
  else:
    let lines = str.split '\n'
    if lines.len != Height or lines.anyIt it.len != Width: 
      return

    var fieldArray: array[Row, array[Col, Cell]]
    for i, line in lines:
      for j, c in line:
        let cell = ($c).toCell
        if cell.isNone:
          return

        fieldArray[Row.low.succ i][Col.low.succ j] = cell.get

    return some fieldArray.toField
