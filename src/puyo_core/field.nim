## This module implements common functions relating to a field and exports the implementation of a field.
## Currently supported implementations are as follows:
## * `Bitboard <./private/field/single/main.html>`_
## * `AVX2 <./private/field/double/main.html>`_
## 
## For performance comparison,
## alternative implementations can be applied by adding the following options when compiling:
## * :code:`-d:altSingleColor`: [Bitboard] Keep binary fields corresponding to each color.
##

import options
import sequtils
import std/setutils
import strutils
import sugar
import tables

import ./cell
import ./common
import ./intrinsic
when UseAvx2:
  import ./private/field/double/main
else:
  when defined(altSingleColor):
    import ./alternative/field/singleColor/main
  else:
    import ./private/field/single/main

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
  shiftedUp,
  shiftedDown,
  shiftedRight,
  shiftedLeft,
  connect3,
  connect3V,
  connect3H,
  connect3L,
  invalidPositions,
  validPositions,
  validDoublePositions,
  isDead,
  put,
  disappear,
  willDisappear,
  fall,
  move,
  moveWithRoughTracking,
  moveWithDetailedTracking,
  moveWithFullTracking,
  toArray,
  toField

func `$`*(field: Field): string {.inline.} =
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
  ## Converts the field to a url.
  let fieldArray = field.toArray
  var lineStrs = newSeqOfCap[string] Height
  for row in Row.low .. Row.high:
    var chars = newSeqOfCap[char] Height div 2
    for i in 0 ..< Width div 2:
      let
        cell1 = fieldArray[row][Col.low.succ 2 * i]
        cell2 = fieldArray[row][Col.low.succ 2 * i + 1]

      chars.add UrlChars[CellToIdx[cell1] * Cell.fullSet.card + CellToIdx[cell2]]

    lineStrs.add chars.join

  return lineStrs.join.strip(trailing = false, chars = {'0'})

func toField*(str: string, url: bool): Option[Field] {.inline.} =
  ## Converts the string to a field.
  ## If the conversions fails, returns none.
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

func shiftUp*(field: var Field) {.inline.} =
  ## Shifts the field up.
  field = field.shiftedUp

func shiftDown*(field: var Field) {.inline.} =
  ## Shifts the field down.
  field = field.shiftedDown

func shiftRight*(field: var Field) {.inline.} =
  ## Shifts the field right.
  field = field.shiftedRight

func shiftLeft*(field: var Field) {.inline.} =
  ## Shifts the field left.
  field = field.shiftedLeft
