## This module implements a binary field using a 32bit bitboard.
##

import bitops
import sequtils
import std/setutils

import ../../../../common
import ../../../../intrinsic
import ../../../../position
import ../../../../util

type BinaryField* = tuple
  left: uint32 # [col1, col2]
  center: uint32 # [col3, col4]
  right: uint32 # [col5, col6]

const ZeroBinaryField = (left: 0'u32, center: 0'u32, right: 0'u32).BinaryField

func `==`*(field1: BinaryField, field2: BinaryField): bool {.inline.} =
  cast[bool](bitand(
    cast[int](field1.left == field2.left),
    cast[int](field1.center == field2.center),
    cast[int](field1.right == field2.right)))
func `+`*(field1: BinaryField, field2: BinaryField): BinaryField {.inline.} =
  result.left = field1.left or field2.left
  result.center = field1.center or field2.center
  result.right = field1.right or field2.right
func `-`(field1: BinaryField, field2: BinaryField): BinaryField {.inline.} =
  result.left = field1.left and field2.left.bitnot
  result.center = field1.center and field2.center.bitnot
  result.right = field1.right and field2.right.bitnot
func `*`*(field1: BinaryField, field2: BinaryField): BinaryField {.inline.} =
  result.left = field1.left and field2.left
  result.center = field1.center and field2.center
  result.right = field1.right and field2.right
func `*`(field: BinaryField, val: bool): BinaryField {.inline.} =
  let castVal = cast[uint32](val)
  result.left = field.left * castVal
  result.center = field.center * castVal
  result.right = field.right * castVal
func `xor`*(field1: BinaryField, field2: BinaryField): BinaryField {.inline.} =
  result.left = field1.left xor field2.left
  result.center = field1.center xor field2.center
  result.right = field1.right xor field2.right
func `shl`(field: BinaryField, imm8: int8 or uint8): BinaryField {.inline.} =
  result.left = field.left shl imm8
  result.center = field.center shl imm8
  result.right = field.right shl imm8
func `shr`(field: BinaryField, imm8: int8 or uint8): BinaryField {.inline.} =
  result.left = field.left shr imm8
  result.center = field.center shr imm8
  result.right = field.right shr imm8
func `+=`*(field1: var BinaryField, field2: BinaryField) {.inline.} = field1 = field1 + field2
func `-=`*(field1: var BinaryField, field2: BinaryField) {.inline.} = field1 = field1 - field2

func zeroBinaryField*: BinaryField {.inline.} =
  ## Returns a field with all elements zero.
  ZeroBinaryField

func floorBinaryField*: BinaryField {.inline.} =
  ## Returns a field with floor bits one.
  (left: 0x0001_0001'u32, center: 0x0001_0001'u32, right: 0x0001_0001'u32).BinaryField

func filled*(val: bool): BinaryField {.inline.} =
  ## Returns a field filled with the given value.
  let castVal = cast[uint32](val)
  (left: 0xFFFF_FFFF'u32 * castVal, center: 0xFFFF_FFFF'u32 * castVal, right: 0xFFFF_FFFF'u32 * castVal).BinaryField

func isZero*(field: BinaryField): bool {.inline.} =
  ## Returns whether the field is all zero or not.
  field == ZeroBinaryField

func isLeftCenterRight[T: SomeInteger](col: Col): (T, T, T) {.inline.} =
  ## Returns whether the column is left (col1-col2), center (col3-col4) or right (col5-col6).
  (cast[T](col <= 2), cast[T](col in {3, 4}), cast[T](col >= 5))

func digits(row: Row, col: Col): (int, int, int) {.inline.} =
  ## Returns digits at (row, col) for left (col1-col2), center (col3-col4) and right (col5-col6).
  (16 * (2 - col) + 14 - row, 16 * (4 - col) + 14 - row, 16 * (6 - col) + 14 - row)

func `[]`*(field: BinaryField, row: Row, col: Col): bool {.inline.} =
  let
    (left, center, right) = isLeftCenterRight[int](col)
    (leftDigit, centerDigit, rightDigit) = digits(row, col)
  return cast[bool](bitor(
    cast[int](field.left.testBit leftDigit * left) * left,
    cast[int](field.center.testBit centerDigit * center) * center,
    cast[int](field.right.testBit rightDigit * right) * right))

func `[]=`*(field: var BinaryField, row: Row, col: Col, val: bool) {.inline.} =
  let
    (left, center, right) = isLeftCenterRight[uint32](col)
    (leftDigit, centerDigit, rightDigit) = digits(row, col)

  field.left.clearMask ((1'u32 shl leftDigit) * left)
  field.left.setMask ((1'u32 shl leftDigit) * left * cast[uint32](val))

  field.center.clearMask ((1'u32 shl centerDigit) * center)
  field.center.setMask ((1'u32 shl centerDigit) * center * cast[uint32](val))

  field.right.clearMask ((1'u32 shl rightDigit) * right)
  field.right.setMask ((1'u32 shl rightDigit) * right * cast[uint32](val))

func trimmed(field: BinaryField): BinaryField {.inline.} =
  ## Returns the field with the padding cleared.
  result.left = field.left and 0x3FFE_3FFE'u32
  result.center = field.center and 0x3FFE_3FFE'u32
  result.right = field.right and 0x3FFE_3FFE'u32

func trim(field: var BinaryField) {.inline.} =
  ## Returns the field with the padding cleared.
  field = field.trimmed

func visible(field: BinaryField): BinaryField {.inline.} =
  ## Returns the field with visible area.
  result.left = field.left and 0x1FFE_1FFE'u32
  result.center = field.center and 0x1FFE_1FFE'u32
  result.right = field.right and 0x1FFE_1FFE'u32

func column*(field: BinaryField, col: Col): BinaryField {.inline.} =
  ## Returns the field only with the given column.
  let
    col1 = 0x3FFE_0000'u32 * cast[uint32](col == 1)
    col2 = 0x0000_3FFE'u32 * cast[uint32](col == 2)
    col3 = 0x3FFE_0000'u32 * cast[uint32](col == 3)
    col4 = 0x0000_3FFE'u32 * cast[uint32](col == 4)
    col5 = 0x3FFE_0000'u32 * cast[uint32](col == 5)
    col6 = 0x0000_3FFE'u32 * cast[uint32](col == 6)

  result.left = field.left and (col1 or col2)
  result.center = field.center and (col3 or col4)
  result.right = field.right and (col5 or col6)
  
func insert*(field: var BinaryField, row: Row, col: Col, val: bool) {.inline.} =
  ## Inserts the value and shifts the field up above where the value inserted.
  let
    (left, center, right) = isLeftCenterRight[uint32](col)
    (leftDigit, centerDigit, rightDigit) = digits(row, col)
    moveLeft = leftDigit ..< 16 * (3 - col)
    moveCenter = centerDigit ..< 16 * (5 - col)
    moveRight = rightDigit ..< 16 * (7 - col)

  field.left = bitor(
    field.left.clearMasked moveLeft,
    (1'u32 shl leftDigit) * left * cast[uint32](val),
    (field.left.masked(moveLeft) shl 1))
  field.center = bitor(
    field.center.clearMasked moveLeft,
    (1'u32 shl leftDigit) * center * cast[uint32](val),
    (field.center.masked(moveCenter) shl 1))
  field.right = bitor(
    field.right.clearMasked moveLeft,
    (1'u32 shl rightDigit) * right * cast[uint32](val),
    field.right.masked(moveRight) shl 1)
  field.trim

func removeSqueeze*(field: var BinaryField, row: Row, col: Col) {.inline.} =
  ## Removes the value and shifts the field down above where the value removed.
  let
    (leftDigit, centerDigit, rightDigit) = digits(row, col)
    moveLeft = leftDigit ..< 16 * (3 - col)
    moveCenter = centerDigit ..< 16 * (5 - col)
    moveRight = rightDigit ..< 16 * (7 - col)

  field.left = bitor(field.left.clearMasked moveLeft, (field.left.masked(moveLeft) shr 1))
  field.center = bitor(field.center.clearMasked moveCenter, (field.center.masked(moveCenter) shr 1))
  field.right = bitor(field.right.clearMasked moveLeft, field.right.masked(moveRight) shr 1)
  field.trim

func popcnt*(field: BinaryField): int {.inline.} =
  ## Population count.
  field.left.popcount + field.center.popcount + field.right.popcount
  
func shiftedUpWithoutTrim(field: BinaryField): BinaryField {.inline.} =
  ## Returns a field shifted up.
  field shl 1

func shiftedDownWithoutTrim(field: BinaryField): BinaryField {.inline.} =
  ## Returns a field shifted down.
  field shr 1

func shiftedRightWithoutTrim(field: BinaryField): BinaryField {.inline.} =
  ## Returns a field shifted right.
  result.left = field.left shr 16
  result.center = field.center shr 16 or (field.left.bitsliced(0 ..< 16) shl 16)
  result.right = (field.right shr 16) or (field.center.bitsliced(0 ..< 16) shl 16)

func shiftedLeftWithoutTrim(field: BinaryField): BinaryField {.inline.} =
  ## Returns a field shifted left.
  result.left = (field.left shl 16) or (field.center.bitsliced(16 ..< 32))
  result.center = (field.center shl 16) or (field.right.bitsliced(16 ..< 32))
  result.right = field.right shl 16

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

func fall*(field: var BinaryField, exist: BinaryField) {.inline.} =
  ## Drops floating values.
  let
    col1 = field.left.bitsliced 16 ..< 32
    col2 = field.left.bitsliced 0 ..< 16
    col3 = field.center.bitsliced 16 ..< 32
    col4 = field.center.bitsliced 0 ..< 16
    col5 = field.right.bitsliced 16 ..< 32
    col6 = field.right.bitsliced 0 ..< 16

    exist1 = exist.left.bitsliced 16 ..< 32
    exist2 = exist.left.bitsliced 0 ..< 16
    exist3 = exist.center.bitsliced 16 ..< 32
    exist4 = exist.center.bitsliced 0 ..< 32
    exist5 = exist.right.bitsliced 16 ..< 32
    exist6 = exist.right.bitsliced 0 ..< 16

    fallCol1 = col1.pext exist1
    fallCol2 = col2.pext exist2
    fallCol3 = col3.pext exist3
    fallCol4 = col4.pext exist4
    fallCol5 = col5.pext exist5
    fallCol6 = col6.pext exist6

  field.left = bitor(fallCol1 shl 16, fallCol2)
  field.center = bitor(fallCol3 shl 16, fallCol4)
  field.right = bitor(fallCol5 shl 16, fallCol6)

func connectionDetail*(field: BinaryField): seq[Natural] {.inline.} =
  ## Returns the number of values for all connected components for two colors.
  ## The order of the returned sequence is not defined.
  ## This function ignores ghost puyoes.
  var
    componentIdxArray: array[Row.high - Row.low + 3, array[Col.high - Col.low + 3, (bool, Natural)]]
    uf = initUnionFind Height * Width
    nextIdx = 1.Natural

  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      let val = field[row, col]
      if not val:
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

  var numArray = 0.Natural.repeat nextIdx
  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      let (val, idx) = componentIdxArray[row][col]
      if not val:
        continue

      numArray[uf.getRoot idx].inc

  return numArray.filterIt it > 0

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
    if field[2, col]:
      usableColumns = usableColumns - ExternalColsArray[col]
      result.incl LiftPositions[col]

  # If (1) there is a usable column with height 11, or (2) heights of the 2nd and 4th rows are both 12,
  # all columns are usable.
  for col in usableColumns:
    if field[3, col] or (field[2, 2] and field[2, 4]):
      usableColumns = AllColumns
      break

  # If any puyo is in the 13th row, that column and the ones outside it cannot be used.
  for col in Col.low .. Col.high:
    if field[1, col]:
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
  field[2, 3]

func toArray*(field: BinaryField): array[Row, array[Col, bool]] {.inline.} =
  ## Converts the field to an array.
  for row in Row.low .. Row.high:
    result[row][1] = field.left.testBit 30 - row
    result[row][2] = field.left.testBit 14 - row
    result[row][3] = field.center.testBit 30 - row
    result[row][4] = field.center.testBit 14 - row
    result[row][5] = field.right.testBit 30 - row
    result[row][6] = field.right.testBit 14 - row

func toBinaryField*(`array`: array[Row, array[Col, bool]]): BinaryField {.inline.} =
  ## Converts the array to a field.
  for row, line in `array`:
    for col in 1 .. 2:
      let shift = 46 - col * 16 - row
      result.left = result.left or (cast[uint32](line[col]) shl shift)

    for col in 3 .. 4:
      let shift = 78 - col * 16 - row
      result.center = result.center or (cast[uint32](line[col]) shl shift)

    for col in 5 .. 6:
      let shift = 110 - col * 16 - row
      result.right = result.right or (cast[uint32](line[col]) shl shift)
