## This module provides a low-level implementation of the binary field.
##

import bitops

import ../../../intrinsic
import ../../../../common

type BinaryField* = tuple
  ## Binary field.
  left: uint32
  center: uint32
  right: uint32

const
  ZeroBinaryField* = (left: 0'u32, center: 0'u32, right: 0'u32).BinaryField ## Binary field with all elements zero.
  OneBinaryField* = (
    left: 0xFFFF_FFFF'u32, center: 0xFFFF_FFFF'u32, right: 0xFFFF_FFFF'u32
  ).BinaryField ## Binary field with all elements one.
  FloorBinaryField* = (
    left: 0x0001_0001'u32, center: 0x0001_0001'u32, right: 0x0001_0001'u32
  ).BinaryField ## Binary field with floor bits one.

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`*(field1, field2: BinaryField): BinaryField {.inline.} =
  result.left = field1.left or field2.left
  result.center = field1.center or field2.center
  result.right = field1.right or field2.right

func `-`*(field1, field2: BinaryField): BinaryField {.inline.} =
  result.left = field1.left.clearMasked field2.left
  result.center = field1.center.clearMasked field2.center
  result.right = field1.right.clearMasked field2.right

func `*`*(field1, field2: BinaryField): BinaryField {.inline.} =
  result.left = field1.left and field2.left
  result.center = field1.center and field2.center
  result.right = field1.right and field2.right

func `*`(field: BinaryField, val: uint32): BinaryField {.inline.} =
  result.left = field.left and val
  result.center = field.center and val
  result.right = field.right and val

func `xor`*(field1, field2: BinaryField): BinaryField {.inline.} =
  result.left = field1.left xor field2.left
  result.center = field1.center xor field2.center
  result.right = field1.right xor field2.right

func `shl`(field: BinaryField, shift: SomeInteger): BinaryField {.inline.} =
  result.left = field.left shl shift
  result.center = field.center shl shift
  result.right = field.right shl shift

func `shr`(field: BinaryField, shift: SomeInteger): BinaryField {.inline.} =
  result.left = field.left shr shift
  result.center = field.center shr shift
  result.right = field.right shr shift

func `+=`*(field1: var BinaryField, field2: BinaryField) {.inline.} =
  field1 = field1 + field2

func `-=`*(field1: var BinaryField, field2: BinaryField) {.inline.} =
  field1.left.clearMask field2.left
  field1.center.clearMask field2.center
  field1.right.clearMask field2.right

func sum*(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  ## Returns the summation.
  result.left = bitor(field1.left, field2.left, field3.left)
  result.center = bitor(field1.center, field2.center, field3.center)
  result.right = bitor(field1.right, field2.right, field3.right)

func sum*(field1, field2, field3, field4, field5: BinaryField): BinaryField {.inline.} =
  ## Returns the summation.
  result.left = bitor(field1.left, field2.left, field3.left, field4.left, field5.left)
  result.center = bitor(field1.center, field2.center, field3.center, field4.center, field5.center)
  result.right = bitor(field1.right, field2.right, field3.right, field4.right, field5.right)

func sum*(field1, field2, field3, field4, field5, field6, field7: BinaryField): BinaryField {.inline.} =
  ## Returns the summation.
  result.left = bitor(field1.left, field2.left, field3.left, field4.left, field5.left, field6.left, field7.left)
  result.center =
    bitor(field1.center, field2.center, field3.center, field4.center, field5.center, field6.center, field7.center)
  result.right =
    bitor(field1.right, field2.right, field3.right, field4.right, field5.right, field6.right, field7.right)

func sum*(field1, field2, field3, field4, field5, field6, field7, field8: BinaryField): BinaryField {.inline.} =
  ## Returns the summation.
  result.left =
    bitor(field1.left, field2.left, field3.left, field4.left, field5.left, field6.left, field7.left, field8.left)
  result.center = bitor(
    field1.center,
    field2.center,
    field3.center,
    field4.center,
    field5.center,
    field6.center,
    field7.center,
    field8.center)
  result.right = bitor(
    field1.right, field2.right, field3.right, field4.right, field5.right, field6.right, field7.right, field8.right)

func prod*(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  ## Returns the production.
  result.left = bitand(field1.left, field2.left, field3.left)
  result.center = bitand(field1.center, field2.center, field3.center)
  result.right = bitand(field1.right, field2.right, field3.right)

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(field: BinaryField): int {.inline.} =
  ## Population count.
  field.left.popcount + field.center.popcount + field.right.popcount

# ------------------------------------------------
# Trim
# ------------------------------------------------

func trimmed*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field with the padding cleared.
  const Mask = 0x3FFE_3FFE'u32
  return field * (left: Mask, center: Mask, right: Mask)

func visible*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field with only the visible area.
  const Mask = 0x1FFE_1FFE'u32
  return field * (left: Mask, center: Mask, right: Mask)

func column*(field: BinaryField, col: Col): BinaryField {.inline.} =
  ## Returns the binary field with only the column :code:`col`.
  const ColMasks: array[Col, BinaryField] = [
    BinaryField (left: 0xFFFF_0000'u32, center: 0'u32, right: 0'u32),
    BinaryField (left: 0x0000_FFFF'u32, center: 0'u32, right: 0'u32),
    BinaryField (left: 0'u32, center: 0xFFFF_0000'u32, right: 0'u32),
    BinaryField (left: 0'u32, center: 0x0000_FFFF'u32, right: 0'u32),
    BinaryField (left: 0'u32, center: 0'u32, right: 0xFFFF_0000'u32),
    BinaryField (left: 0'u32, center: 0'u32, right: 0x0000_FFFF'u32)]

  return field * ColMasks[col]

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func leftCenterRightMasks(col: Col): tuple[left: uint32, center: uint32, right: uint32] {.inline.} =
  ## Returns :code:`(l, c, r)`; among :code:`l`, :code:`c`, and :code:`r`, those corresponding to :code:`col` is
  ## :code:`-1`, and the rest are :code:`0`.
  let
    c = col.int32
    bit1XorBit0 = (c and 1) xor ((c and 2) shr 1)
    bit2 = (c and 4) shr 2

  result.left = cast[uint32]((bit2 - 1) and -bit1XorBit0)
  result.center = cast[uint32](bit1XorBit0 - 1)
  result.right = cast[uint32](-bit2 and -bit1XorBit0)

func cellMasks(row: Row, col: Col): tuple[left: uint32, center: uint32, right: uint32] {.inline.} =
  ## Returns three masks with only the bit at position :code:`(row, col)` set to :code:`1`.
  const Mask = 0x4000_0000'u32
  let (leftMask, centerMask, rightMask) = col.leftCenterRightMasks
  result.left = (Mask shr (16 * (col - 1) + row)) and leftMask
  result.center = (Mask shr (16 * (col - 3) + row)) and centerMask
  result.right = (Mask shr (16 * (col - 5) + row)) and rightMask

func `[]`*(field: BinaryField, row: Row, col: Col): bool {.inline.} =
  let (leftMask, centerMask, rightMask) = cellMasks(row, col)
  return bool bitor(field.left and leftMask, field.center and centerMask, field.right and rightMask)

func exist*(field: BinaryField, row: Row, col: Col): int {.inline.} =
  ## Returns :code:`1` if the bit :code:`(row, col)` is set; otherwise, returns :code:`0`.
  field[row, col].int

func `[]=`*(field: var BinaryField, row: Row, col: Col, val: bool) {.inline.} =
  let
    (leftMask, centerMask, rightMask) = cellMasks(row, col)
    cellMask = (left: leftMask, center: centerMask, right: rightMask)

  field = field - cellMask + cellMask * cast[uint32](-val.int32)

func aboveMasks(row: Row, col: Col): tuple[left: uint32, center: uint32, right: uint32] {.inline.} =
  ## Returns three masks with only the bits at the range from :code:`(row, col)` to :code:`(0, col)` set to :code:`1`.
  const AllOne = 0xFFFF_FFFF'u32
  let (leftMask, centerMask, rightMask) = col.leftCenterRightMasks
  result.left = (AllOne.masked 16 * (2 - col) + 14 - row ..< 16 * (3 - col)) and leftMask
  result.center = (AllOne.masked 16 * (4 - col) + 14 - row ..< 16 * (5 - col)) and centerMask
  result.right = (AllOne.masked 16 * (6 - col) + 14 - row ..< 16 * (7 - col)) and rightMask

func insert*(field: var BinaryField, row: Row, col: Col, val: bool) {.inline.} =
  ## Inserts :code:`val` and shift :code:`field` upward above the location where :code:`val` is inserted.
  let
    (leftMask, centerMask, rightMask) = aboveMasks(row, col)
    moveMask = (left: leftMask, center: centerMask, right: rightMask)
    moveField = (left: field.left and leftMask, center: field.center and centerMask, right: field.right and rightMask)

  field = sum(field - moveField, moveField shl 1, (moveMask xor (moveMask shl 1)) * cast[uint32](-val.int32)).trimmed

func removeSqueeze*(field: var BinaryField, row: Row, col: Col) {.inline.} =
  ## Removes the value at :code:`(row, col)` and shift :code:`field` downward above the location where the cell is
  ## removed.
  let
    (leftMask, centerMask, rightMask) = aboveMasks(row, col)
    moveMask = (left: leftMask, center: centerMask, right: rightMask)
    moveField = (left: field.left and leftMask, center: field.center and centerMask, right: field.right and rightMask)

  field = field - moveField + (moveField - (moveMask xor (moveMask shl 1))) shr 1

# ------------------------------------------------
# Property
# ------------------------------------------------

func isZero*(field: BinaryField): bool {.inline.} =
  ## Returns :code:`true` if all elements are zero in the :code:`field`.
  field == ZeroBinaryField

# ------------------------------------------------
# Shift
# ------------------------------------------------
  
func shiftedUpWithoutTrim*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field shifted upward the :code:`field`.
  field shl 1

func shiftedDownWithoutTrim*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field shifted downward the :code:`field`.
  field shr 1

func shiftedRightWithoutTrim*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field shifted rightward the :code:`field`.
  result.left = field.left shr 16
  result.center = (field.center shr 16) or (field.left shl 16)
  result.right = (field.right shr 16) or (field.center shl 16)

func shiftedLeftWithoutTrim*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field shifted leftward the :code:`field`.
  result.left = (field.left shl 16) or (field.center shr 16)
  result.center = (field.center shl 16) or (field.right shr 16)
  result.right = field.right shl 16

# ------------------------------------------------
# Operation
# ------------------------------------------------

func drop(fieldMember: uint32, existWithFloor: uint32): uint32 {.inline.} =
  ## Drops floating cells.
  let
    col1 = fieldMember.bitsliced 17 ..< 32
    col0 = fieldMember.bitsliced 1 ..< 16

    exist1 = existWithFloor.bitsliced 17 ..< 32
    exist0 = existWithFloor.bitsliced 1 ..< 16

    newCol1 = col1.pext exist1
    newCol0 = col0.pext exist0

  return bitor(newCol1 shl 17, newCol0 shl 1)

func drop*(field: var BinaryField, existWithFloor: BinaryField) {.inline.} =
  ## Drops floating cells.
  field.left = field.left.drop existWithFloor.left
  field.center = field.center.drop existWithFloor.center
  field.right = field.right.drop existWithFloor.right

# ------------------------------------------------
# BinaryField <-> array
# ------------------------------------------------

func toArray*(field: BinaryField): array[Row, array[Col, bool]] {.inline.} =
  ## Converts :code:`field` to the array.
  for row in Row.low .. Row.high:
    result[row][1] = field.left.testBit 30 - row
    result[row][2] = field.left.testBit 14 - row
    result[row][3] = field.center.testBit 30 - row
    result[row][4] = field.center.testBit 14 - row
    result[row][5] = field.right.testBit 30 - row
    result[row][6] = field.right.testBit 14 - row

func toBinaryField*(fieldArray: array[Row, array[Col, bool]]): BinaryField {.inline.} =
  ## Converts :code:`fieldArray` to the binary field.
  for row, line in fieldArray:
    for col in 1 .. 2:
      result.left = result.left or (line[col].uint32 shl (46 - col * 16 - row))

    for col in 3 .. 4:
      result.center = result.center or (line[col].uint32 shl (78 - col * 16 - row))

    for col in 5 .. 6:
      result.right = result.right or (line[col].uint32 shl (110 - col * 16 - row))
