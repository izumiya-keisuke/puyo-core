## This module implements a binary field using AVX2.
##

import bitops
import sequtils
import std/setutils

import nimsimd/avx2

import ../../../common
import ../../../intrinsic
import ../../../position
import ../../../util

type BinaryField* = M256i ## [color1:col0, ..., color1:col7, color2:col0, ..., color2:col7]

func `==`*(field1: BinaryField, field2: BinaryField): bool {.inline.} =
  cast[bool](mm256_testc_si256(mm256_setzero_si256(), mm256_xor_si256(field1, field2)))
func `+`*(field1: BinaryField, field2: BinaryField): BinaryField {.inline.} = mm256_or_si256(field1, field2)
func `-`(field1: BinaryField, field2: BinaryField): BinaryField {.inline.} = mm256_andnot_si256(field2, field1)
func `*`*(field1: BinaryField, field2: BinaryField): BinaryField {.inline.} = mm256_and_si256(field1, field2)
func `xor`*(field1: BinaryField, field2: BinaryField): BinaryField {.inline.} = mm256_xor_si256(field1, field2)
func `shl`(field: BinaryField, imm8: int8 or uint8): BinaryField {.inline.} = mm256_slli_epi16(field, cast[int32](imm8))
func `shr`(field: BinaryField, imm8: int8 or uint8): BinaryField {.inline.} = mm256_srli_epi16(field, cast[int32](imm8))
func `+=`*(field1: var BinaryField, field2: BinaryField) {.inline.} = field1 = field1 + field2
func `-=`*(field1: var BinaryField, field2: BinaryField) {.inline.} = field1 = field1 - field2

func zeroBinaryField*: BinaryField {.inline.} =
  ## Returns a field with all elements zero.
  mm256_setzero_si256()

func floorBinaryField*: BinaryField {.inline.} =
  ## Returns a field with floor bits one.
  mm256_set1_epi16(0b0000_0000_0000_0001)

func bits[T: SomeInteger](val: 0'u8 .. 2'u8): (T, T) {.inline.} =
  ## Returns the first color bit and second color bit
  (cast[T](val and 1), cast[T](val == 2))

func filled*(val: 0'u8 .. 2'u8): BinaryField {.inline.} =
  ## Returns a field filled with the given value.
  let (color1, color2) = bits[int64](val)
  return mm256_set_epi64x(-color1, -color1, -color2, -color2) # if color* == 1, then -color* is -1 (all bits are 1)

func isZero*(field: BinaryField): bool {.inline.} =
  ## Returns whether the field is all zero or not.
  cast[bool](mm256_testc_si256(zeroBinaryField(), field))

func isLeftRight[T: SomeInteger](col: Col): (T, T) {.inline.} =
  ## Returns whether the column is left (col0-col3) or right (col4-col7).
  let left = cast[T](col <= 3)
  return (left, 1 - left)

func cellMasks(row: Row, col: Col): (uint64, uint64) {.inline.} =
  ## Returns masks at (row, col) for left (col0-col3) and right (col4-col7).
  let (left, right) = isLeftRight[uint64](col)
  return ((0x8000_0000_0000_0000'u64 shr (16 * col + row + 1)) * left, (1'u64 shl (16 * (7 - col) + 14 - row)) * right)

func `[]`*(field: BinaryField, row: Row, col: Col): int {.inline.} =
  let (left, right) = cellMasks(row, col)
  return mm256_testc_si256(field, mm256_set_epi64x(left, right, 0, 0)) or
    mm256_testc_si256(field, mm256_set_epi64x(0, 0, left, right)) shl 1

func `[]=`*(field: var BinaryField, row: Row, col: Col, val: 0'u8 .. 2'u8) {.inline.} =
  let
    (left, right) = cellMasks(row, col)
    (color1, color2) = bits[uint8](val)

  field = field - mm256_set_epi64x(left, right, left, right) +
    mm256_set_epi64x(left * color1, right * color1, left * color2, right * color2)

func aboveMasks(row: Row, col: Col): (int64, int64) {.inline.} =
  ## Returns masks at (row, col) -- (0, col) for left and right.
  let (left, right) = isLeftRight[int64](col)
  return ((0xFFFF_FFFF_FFFF_FFFF'i64.masked 16 * (3 - col) + 14 - row ..< 16 * (4 - col)) * left,
    (0xFFFF_FFFF_FFFF_FFFF'i64.masked 16 * (7 - col) + 14 - row ..< 16 * (8 - col)) * right)

func trimmed(field: BinaryField): BinaryField {.inline.} =
  ## Returns the field with the padding cleared.
  field * mm256_set_epi64x(0x0000_3FFE_3FFE_3FFE, 0x3FFE_3FFE_3FFE_0000, 0x0000_3FFE_3FFE_3FFE, 0x3FFE_3FFE_3FFE_0000)

func visible(field: BinaryField): BinaryField {.inline.} =
  ## Returns the field with visible area.
  field * mm256_set_epi64x(0x0000_1FFE_1FFE_1FFE, 0x1FFE_1FFE_1FFE_0000, 0x0000_1FFE_1FFE_1FFE, 0x1FFE_1FFE_1FFE_0000)

func column*(field: BinaryField, col: Col): BinaryField {.inline.} =
  ## Returns the field only with the given column.
  const ColumnMask = 0x3FFE'i16
  let
    col1 = ColumnMask * cast[int16](col == 1)
    col2 = ColumnMask * cast[int16](col == 2)
    col3 = ColumnMask * cast[int16](col == 3)
    col4 = ColumnMask * cast[int16](col == 4)
    col5 = ColumnMask * cast[int16](col == 5)
    col6 = ColumnMask * cast[int16](col == 6)

  return field * mm256_set_epi16(0, col1, col2, col3, col4, col5, col6, 0, 0, col1, col2, col3, col4, col5, col6, 0)
  
func insert*(field: var BinaryField, row: Row, col: Col, val: 0'u8 .. 2'u8) {.inline.} =
  ## Inserts the value and shifts the field up above where the value inserted.
  let
    (left, right) = aboveMasks(row, col)
    moveMask = mm256_set_epi64x(left, right, left, right)
    moveField = moveMask * field

    (color1, color2) = bits[int64](val)
    insertField =
      (moveMask xor (moveMask shl 1)) * mm256_set_epi64x(left * color1, right * color1, left * color2, right * color2)

  field = field - moveField + ((moveField shl 1).trimmed + insertField)

func removeSqueeze*(field: var BinaryField, row: Row, col: Col) {.inline.} =
  ## Removes the value and shifts the field down above where the value removed.
  let
    (left, right) = aboveMasks(row, col)
    moveMask = mm256_set_epi64x(left, right, left, right)
    moveField = moveMask * field

  field = field - moveField + (moveField - (moveMask xor (moveMask shl 1))) shr 1

func popcnt*(field: BinaryField, idx: 0 .. 1): int {.inline.} =
  ## Population count.
  # NOTE: YMM[e3, e2, e1, e0] == array[e0, e1, e2, e3]
  let fieldArray = cast[array[4, uint64]](field)
  return fieldArray[2 - 2 * idx].popcount + fieldArray[3 - 2 * idx].popcount
  
func popcnt*(field: BinaryField): int {.inline.} =
  ## Population count.
  let fieldArray = cast[array[4, uint64]](field)
  return fieldArray[0].popcount + fieldArray[1].popcount + fieldArray[2].popcount + fieldArray[3].popcount

func shiftedUpWithoutTrim(field: BinaryField): BinaryField {.inline.} =
  ## Returns a field shifted up.
  field shl 1

func shiftedDownWithoutTrim(field: BinaryField): BinaryField {.inline.} =
  ## Returns a field shifted down.
  field shr 1

func shiftedRightWithoutTrim(field: BinaryField): BinaryField {.inline.} =
  ## Returns a field shifted right.
  mm256_srli_si256(field, 2)

func shiftedLeftWithoutTrim(field: BinaryField): BinaryField {.inline.} =
  ## Returns a field shifted left.
  mm256_slli_si256(field, 2)

func shiftedUp*(field: BinaryField): BinaryField {.inline.} =
  ## Returns a field shifted up and trimmed.
  field.shiftedUpWithoutTrim.trimmed

func shiftedDown*(field: BinaryField): BinaryField {.inline.} =
  ## Returns a field shifted down and trimmed.
  field.shiftedDownWithoutTrim.trimmed

func shiftedRight*(field: BinaryField): BinaryField {.inline.} =
  ## Returns a field shifted right and trimmed.
  field.shiftedRightWithoutTrim.trimmed

func shiftedLeft*(field: BinaryField): BinaryField {.inline.} =
  ## Returns a field shifted left and trimmed.
  field.shiftedLeftWithoutTrim.trimmed

func expanded*(field: BinaryField): BinaryField {.inline.} =
  ## Dilates the field.
  ## This function does not trim.
  (field + field.shiftedUpWithoutTrim + field.shiftedDownWithoutTrim) +
    (field.shiftedRightWithoutTrim + field.shiftedLeftWithoutTrim)

func expandedV(field: BinaryField): BinaryField {.inline.} =
  ## Dilates the field vertically.
  ## This function does not trim.
  field + field.shiftedUpWithoutTrim + field.shiftedDownWithoutTrim

func expandedH(field: BinaryField): BinaryField {.inline.} =
  ## Dilates the field horizontally.
  ## This function does not trim.
  field + field.shiftedRightWithoutTrim + field.shiftedLeftWithoutTrim

func connections(field: BinaryField): (BinaryField, BinaryField, BinaryField, BinaryField, BinaryField) {.inline.} =
  ## Returns intermediate fields for calculating connections.
  let
    visibleField = field.visible

    hasUp = visibleField * visibleField.shiftedDownWithoutTrim
    hasDown = visibleField * visibleField.shiftedUpWithoutTrim
    hasRight = visibleField * visibleField.shiftedLeftWithoutTrim
    hasLeft = visibleField * visibleField.shiftedRightWithoutTrim

    hasUpDown = hasUp * hasDown
    hasRightLeft = hasRight * hasLeft
    hasUpOrDown = hasUp + hasDown
    hasRightOrLeft = hasRight + hasLeft

    connect4T = hasUpDown * hasRightOrLeft + hasRightLeft * hasUpOrDown
    connect3IL = hasUpDown + hasRightLeft + hasUpOrDown * hasRightOrLeft

  return (visibleField, hasUpDown, hasRightLeft, connect4T, connect3IL)

func disappeared(visibleField: BinaryField, connect4T: BinaryField, connect3IL: BinaryField): BinaryField {.inline.} =
  ## Returns where four or more values connected.
  let
    connect4Up = connect3IL * connect3IL.shiftedUpWithoutTrim
    connect4Down = connect3IL * connect3IL.shiftedDownWithoutTrim
    connect4Right = connect3IL * connect3IL.shiftedRightWithoutTrim
    connect4Left = connect3IL * connect3IL.shiftedLeftWithoutTrim

  return ((connect4T + connect4Up + connect4Down) + (connect4Right + connect4Left)).expanded * visibleField

func disappeared*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where four or more values connected.
  let (visibleField, _, _, connect4T, connect3IL) = field.connections
  return disappeared(visibleField, connect4T, connect3IL)

func willDisappear*(field: BinaryField): bool {.inline.} =
  ## Returns whether any four or more values are connected or not.
  let
    (_, _, _, connect4T, connect3IL) = field.connections
    connect4Up = connect3IL * connect3IL.shiftedUpWithoutTrim
    connect4Right = connect3IL * connect3IL.shiftedRightWithoutTrim

  return not (connect4T + connect4Up + connect4Right).isZero

func exist*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where any values exist.
  field + mm256_permute4x64_epi64(field, 0b01_00_11_10)

func fall*(field: var BinaryField, exist: BinaryField) {.inline.} =
  ## Drops floating values.
  let
    fieldArray = cast[array[16, uint16]](field)
    existArray = cast[array[16, uint16]](exist)

  var resultArray: array[16, uint16]
  for i in 1 .. 6:
    resultArray[i] = cast[uint16](cast[uint32](fieldArray[i]).pext existArray[i])
  for i in 9 .. 14:
    resultArray[i] = cast[uint16](cast[uint32](fieldArray[i]).pext existArray[i])

  field = cast[BinaryField](resultArray)

func connectionDetail*(field: BinaryField): (seq[Natural], seq[Natural]) {.inline.} =
  ## Returns the number of values for all connected components for two colors.
  ## The order of the returned sequence is not defined.
  ## This function ignores ghost puyoes.
  var
    componentIdxArray: array[Row.high - Row.low + 3, array[Col.high - Col.low + 3, (int, Natural)]]
    uf = initUnionFind Height * Width
    nextIdx = 1.Natural

  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      let val = field[row, col]
      if val == 0:
        continue

      let
        (upVal, upIdx) = componentIdxArray[row.int.pred][col]
        (leftVal, leftIdx) = componentIdxArray[row][col.int.pred]

      if upVal == val:
        if leftVal == val:
          componentIdxArray[row][col] = (val, min(upIdx, leftIdx))
          uf.merge upIdx, leftIdx
        else:
          componentIdxArray[row][col] = (val, upIdx)
      else:
        if leftVal == val:
          componentIdxArray[row][col] = (val, leftIdx)
        else:
          componentIdxArray[row][col] = (val, nextIdx)
          nextIdx.inc

  var numsArray = [0.Natural.repeat nextIdx, 0.Natural.repeat nextIdx]
  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      let (val, idx) = componentIdxArray[row][col]
      if val == 0:
        continue

      numsArray[val.pred][uf.getRoot idx].inc

  return (numsArray[0].filterIt it > 0, numsArray[1].filterIt it > 0)

func connect3*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where three values are connected.
  ## This function ignores ghost puyoes.
  let (visibleField, _, _, connect4T, connect3IL) = field.connections
  return connect3IL.expanded * visibleField - disappeared(visibleField, connect4T, connect3IL)

func connect3V*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where three values are connected vertically.
  ## This function ignores ghost puyoes.
  let
    visibleField = field.visible

    up = visibleField.shiftedUpWithoutTrim
    down = visibleField.shiftedDownWithoutTrim
    right = visibleField.shiftedRightWithoutTrim
    left = visibleField.shiftedLeftWithoutTrim

    upDown = visibleField * up * down
    exclude = visibleField * (
      ((right + left) + (up.shiftedRightWithoutTrim + up.shiftedLeftWithoutTrim)) +
      ((down.shiftedRightWithoutTrim + down.shiftedLeftWithoutTrim) +
      (up.shiftedUpWithoutTrim + down.shiftedDownWithoutTrim)))

  return (upDown - exclude).expandedV

func connect3H*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where three values are connected horizontally.
  ## This function ignores ghost puyoes.
  let
    visibleField = field.visible

    up = visibleField.shiftedUpWithoutTrim
    down = visibleField.shiftedDownWithoutTrim
    right = visibleField.shiftedRightWithoutTrim
    left = visibleField.shiftedLeftWithoutTrim

    rightLeft = visibleField * right * left
    exclude = visibleField * (
      ((up + down) + (up.shiftedRightWithoutTrim + up.shiftedLeftWithoutTrim)) +
      ((down.shiftedRightWithoutTrim + down.shiftedLeftWithoutTrim) +
      (right.shiftedRightWithoutTrim + left.shiftedLeftWithoutTrim)))

  return (rightLeft - exclude).expandedH

func connect3L*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where three values are connected by L-shape.
  ## This function ignores ghost puyoes.
  let (visibleField, hasUpDown, hasRightLeft, connect4T, connect3IL) = field.connections
  return connect3IL.expanded * visibleField -
    (disappeared(visibleField, connect4T, connect3IL) + hasUpDown.expandedV + hasRightLeft.expandedH)

func invalidPositions*(field: BinaryField): set[Position] {.inline.} =
  ## Returns positions that cannot be put.
  const
    AllColumns = {Col.low .. Col.high}
    ExternalColsArray: array[Col, set[Col]] = [
      {1.Col}, {1.Col, 2.Col}, {}, {4.Col, 5.Col, 6.Col}, {5.Col, 6.Col}, {6.Col}
    ]
    LiftPositions: array[Col, Position] = [POS_1D, POS_2D, POS_3D, POS_4D, POS_5D, POS_6D]
    InvalidPositionsArray: array[Col, set[Position]] = [
      {POS_1U, POS_1R, POS_1D, POS_2L},
      {POS_2U, POS_2R, POS_2D, POS_2L, POS_1R, POS_3L},
      {POS_3U, POS_3R, POS_3D, POS_3L, POS_2R, POS_4L},
      {POS_4U, POS_4R, POS_4D, POS_4L, POS_3R, POS_5L},
      {POS_5U, POS_5R, POS_5D, POS_5L, POS_4R, POS_6L},
      {POS_6U, POS_6D, POS_6L, POS_5R},
    ]

  var usableColumns = AllColumns

  # If any puyo is in the 12th row, that column and the ones outside it cannot be used,
  # and the axis-puyo cannot lift at that column.
  for col in Col.low .. Col.high:
    if field[2, col] != 0:
      usableColumns = usableColumns - ExternalColsArray[col]
      result.incl LiftPositions[col]

  # If (1) there is a usable column with height 11, or (2) heights of the 2nd and 4th rows are both 12,
  # all columns are usable.
  for col in usableColumns:
    if field[3, col] != 0 or (field[2, 2] != 0 and field[2, 4] != 0):
      usableColumns = AllColumns
      break

  # If any puyo is in the 13th row, that column and the ones outside it cannot be used.
  for col in Col.low .. Col.high:
    if field[1, col] != 0:
      usableColumns = usableColumns - ExternalColsArray[col]

  for col in usableColumns.complement:
    result = result + InvalidPositionsArray[col]

func validPositions*(field: BinaryField): set[Position] {.inline.} =
  ## Get positions that can be put in the field.
  field.invalidPositions.complement

func validDoublePositions*(field: BinaryField): set[Position] {.inline.} =
  ## Get positions for a double pair that can be put in the field.
  return DoublePositions - field.invalidPositions

func isDead*(field: BinaryField): bool {.inline.} =
  ## Returns whether the field is dead or not.
  field[2, 3] != 0

func toArray*(field: BinaryField): array[Row, array[Col, int]] {.inline.} =
  ## Converts the field to an array.
  let fieldArray = cast[array[16, int16]](field)

  # NOTE: YMM[e15, ..., e0] == array[e0, ..., e15]
  for col in Col.low .. Col.high:
    let
      colVal1 = fieldArray[15 - col]
      colVal2 = fieldArray[7 - col]

    for row in Row.low .. Row.high:
      result[row][col] = cast[int](colVal1.testBit 14 - row) + cast[int](colVal2.testBit 14 - row) shl 1

func toBinaryField*(`array`: array[Row, array[Col, int]]): BinaryField {.inline.} =
  ## Converts the array to a field.
  var color1Left, color1Right, color2Left, color2Right: int64
  for row, line in `array`:
    for col in 1 .. 3:
      let
        (color1, color2) = bits[int64](cast[uint8](line[col]))
        shift = 62 - col * 16 - row
      color1Left = color1Left or (color1 shl shift)
      color2Left = color2Left or (color2 shl shift)

    for col in 4 .. 6:
      let
        (color1, color2) = bits[int64](cast[uint8](line[col]))
        shift = 126 - col * 16 - row
      color1Right = color1Right or (color1 shl shift)
      color2Right = color2Right or (color2 shl shift)

  return mm256_set_epi64x(color1Left, color1Right, color2Left, color2Right)
