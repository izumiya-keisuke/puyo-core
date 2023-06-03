## This module provides a low-level implementation of the binary field.
##

import bitops

import ../../../intrinsic
import ../../../../common

type
  BinaryField* = tuple
    ## Binary field.
    left: uint64
    right: uint64

  DropMask* = array[Col, when UseBmi2: uint64 else: PextMask[uint64]] ## Mask used in :code:`drop`.

const
  ZeroBinaryField* = (left: 0'u64, right: 0'u64).BinaryField ## Binary field with all elements zero.
  OneBinaryField* = (
    left: 0xFFFF_FFFF_FFFF_FFFF'u64, right: 0xFFFF_FFFF_FFFF_FFFF'u64
  ).BinaryField ## Binary field with all elements one.
  FloorBinaryField* = (
    left: 0x0001_0001_0001_0001'u64, right: 0x0001_0001_0001_0001'u64
  ).BinaryField ## Binary field with floor bits one. 

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `+`*(field1, field2: BinaryField): BinaryField {.inline.} =
  result.left = field1.left or field2.left
  result.right = field1.right or field2.right

func `-`*(field1, field2: BinaryField): BinaryField {.inline.} =
  result.left = field1.left.clearMasked field2.left
  result.right = field1.right.clearMasked field2.right

func `*`*(field1, field2: BinaryField): BinaryField {.inline.} =
  result.left = field1.left and field2.left
  result.right = field1.right and field2.right

func `*`(field: BinaryField, val: uint64): BinaryField {.inline.} =
  result.left = field.left and val
  result.right = field.right and val

func `xor`*(field1, field2: BinaryField): BinaryField {.inline.} =
  result.left = field1.left xor field2.left
  result.right = field1.right xor field2.right

func `shl`(field: BinaryField, shift: SomeInteger): BinaryField {.inline.} =
  result.left = field.left shl shift
  result.right = field.right shl shift

func `shr`(field: BinaryField, shift: SomeInteger): BinaryField {.inline.} =
  result.left = field.left shr shift
  result.right = field.right shr shift

func `+=`*(field1: var BinaryField, field2: BinaryField) {.inline.} =
  field1 = field1 + field2

func `-=`*(field1: var BinaryField, field2: BinaryField) {.inline.} =
  field1.left.clearMask field2.left
  field1.right.clearMask field2.right

func sum*(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  ## Returns the summation.
  result.left = bitor(field1.left, field2.left, field3.left)
  result.right = bitor(field1.right, field2.right, field3.right)

func sum*(field1, field2, field3, field4, field5: BinaryField): BinaryField {.inline.} =
  ## Returns the summation.
  result.left = bitor(field1.left, field2.left, field3.left, field4.left, field5.left)
  result.right = bitor(field1.right, field2.right, field3.right, field4.right, field5.right)

func sum*(field1, field2, field3, field4, field5, field6, field7: BinaryField): BinaryField {.inline.} =
  ## Returns the summation.
  result.left = bitor(field1.left, field2.left, field3.left, field4.left, field5.left, field6.left, field7.left)
  result.right =
    bitor(field1.right, field2.right, field3.right, field4.right, field5.right, field6.right, field7.right)

func sum*(field1, field2, field3, field4, field5, field6, field7, field8: BinaryField): BinaryField {.inline.} =
  ## Returns the summation.
  result.left =
    bitor(field1.left, field2.left, field3.left, field4.left, field5.left, field6.left, field7.left, field8.left)
  result.right = bitor(
    field1.right, field2.right, field3.right, field4.right, field5.right, field6.right, field7.right, field8.right)

func prod*(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  ## Returns the production.
  result.left = bitand(field1.left, field2.left, field3.left)
  result.right = bitand(field1.right, field2.right, field3.right)

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(field: BinaryField): int {.inline.} =
  ## Population count.
  field.left.popcount + field.right.popcount

# ------------------------------------------------
# Trim
# ------------------------------------------------

func trimmed*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field with the padding cleared.
  field * (left: 0x0000_3FFE_3FFE_3FFE'u64, right: 0x3FFE_3FFE_3FFE_0000'u64)

func visible*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field with only the visible area.
  field * (left: 0x0000_1FFE_1FFE_1FFE'u64, right: 0x1FFE_1FFE_1FFE_0000'u64)

func column*(field: BinaryField, col: Col): BinaryField {.inline.} =
  ## Returns the binary field with only the column :code:`col`.
  const ColMasks: array[Col, BinaryField] = [
    (left: 0x0000_FFFF_0000_0000'u64, right: 0'u64),
    (left: 0x0000_0000_FFFF_0000'u64, right: 0'u64),
    (left: 0x0000_0000_0000_FFFF'u64, right: 0'u64),
    (left: 0'u64, right: 0xFFFF_0000_0000_0000'u64),
    (left: 0'u64, right: 0x0000_FFFF_0000_0000'u64),
    (left: 0'u64, right: 0x0000_0000_FFFF_0000'u64)]

  return field * ColMasks[col]

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func leftRightMasks(col: Col): tuple[left: uint64, right: uint64] {.inline.} =
  ## Returns :code:`(-1, 0)` if :code:`col` is in {1, 2, 3}; otherwise returns :code:`(0, -1)`.
  let rightMask = -((col.int64 and 4) shr 2)
  result.left = cast[uint64](-1 - rightMask)
  result.right = cast[uint64](rightMask)

func cellMasks(row: Row, col: Col): tuple[left: uint64, right: uint64] {.inline.} =
  ## Returns two masks with only the bit at position :code:`(row, col)` set to :code:`1`.
  const Mask = 0x4000_0000_0000_0000'u64
  let (leftMask, rightMask) = col.leftRightMasks
  result.left = (Mask shr (16 * col + row)) and leftMask
  result.right = (Mask shr (16 * (col - 4) + row)) and rightMask

func `[]`*(field: BinaryField, row: Row, col: Col): bool {.inline.} =
  let (leftMask, rightMask) = cellMasks(row, col)
  return bool bitor(field.left and leftMask, field.right and rightMask)

func exist*(field: BinaryField, row: Row, col: Col): int {.inline.} =
  ## Returns :code:`1` if the bit :code:`(row, col)` is set; otherwise, returns :code:`0`.
  field[row, col].int

func `[]=`*(field: var BinaryField, row: Row, col: Col, val: bool) {.inline.} =
  let
    (leftMask, rightMask) = cellMasks(row, col)
    cellMask = (left: leftMask, right: rightMask)

  field = field - cellMask + cellMask * cast[uint64](-val.int64)

func aboveMasks(row: Row, col: Col): tuple[left: uint64, right: uint64] {.inline.} =
  ## Returns two masks with only the bits at the range from :code:`(row, col)` to :code:`(0, col)` set to :code:`1`.
  const AllOne = 0xFFFF_FFFF_FFFF_FFFF'u64
  let (leftMask, rightMask) = col.leftRightMasks
  result.left = (AllOne.masked 16 * (3 - col) + 14 - row ..< 16 * (4 - col)) and leftMask
  result.right = (AllOne.masked 16 * (7 - col) + 14 - row ..< 16 * (8 - col)) and rightMask

func insert*(field: var BinaryField, row: Row, col: Col, val: bool) {.inline.} =
  ## Inserts :code:`val` and shift :code:`field` upward above the location where :code:`val` is inserted.
  let
    (leftMask, rightMask) = aboveMasks(row, col)
    moveMask = (left: leftMask, right: rightMask)
    moveField = (left: field.left and leftMask, right: field.right and rightMask)

  field = sum(field - moveField, moveField shl 1, (moveMask xor (moveMask shl 1)) * cast[uint64](-val.int64)).trimmed

func removeSqueeze*(field: var BinaryField, row: Row, col: Col) {.inline.} =
  ## Removes the value at :code:`(row, col)` and shift :code:`field` downward above the location where the cell is
  ## removed.
  let
    (leftMask, rightMask) = aboveMasks(row, col)
    moveMask = (left: leftMask, right: rightMask)
    moveField = (left: field.left and leftMask, right: field.right and rightMask)

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
  result.right = bitor(field.right shr 16, field.left shl 48)

func shiftedLeftWithoutTrim*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field shifted leftward the :code:`field`.
  result.left = bitor(field.left shl 16, field.right shr 48)
  result.right = field.right shl 16

# ------------------------------------------------
# Operation
# ------------------------------------------------

func toColumnArray(field: BinaryField): array[Col, uint64] {.inline.} =
  ## Converts :code:`field` to the integer array corresponding to each column.
  result[1] = field.left.bitsliced 33 ..< 48
  result[2] = field.left.bitsliced 17 ..< 32
  result[3] = field.left.bitsliced 1 ..< 16
  result[4] = field.right.bitsliced 49 ..< 64
  result[5] = field.right.bitsliced 33 ..< 48
  result[6] = field.right.bitsliced 17 ..< 32

func toDropMask*(existField: BinaryField): DropMask {.inline.} =
  ## Converts :code:`existField` to the drop mask.
  let existFloor = (existField + FloorBinaryField).toColumnArray

  for col in Col.low .. Col.high:
    result[col] = when UseBmi2: existFloor[col] else: existFloor[col].toPextMask

func drop*(field: var BinaryField, mask: DropMask) {.inline.} =
  ## Drops floating cells.
  let fieldArray = field.toColumnArray

  field.left =
    bitor(fieldArray[1].pext(mask[1]) shl 33, fieldArray[2].pext(mask[2]) shl 17, fieldArray[3].pext(mask[3]) shl 1)
  field.right =
    bitor(fieldArray[4].pext(mask[4]) shl 49, fieldArray[5].pext(mask[5]) shl 33, fieldArray[6].pext(mask[6]) shl 17)

# ------------------------------------------------
# BinaryField <-> array
# ------------------------------------------------

func toArray*(field: BinaryField): array[Row, array[Col, bool]] {.inline.} =
  ## Converts :code:`field` to the array.
  for row in Row.low .. Row.high:
    result[row][1] = field.left.testBit 46 - row
    result[row][2] = field.left.testBit 30 - row
    result[row][3] = field.left.testBit 14 - row
    result[row][4] = field.right.testBit 62 - row
    result[row][5] = field.right.testBit 46 - row
    result[row][6] = field.right.testBit 30 - row

func toBinaryField*(fieldArray: array[Row, array[Col, bool]]): BinaryField {.inline.} =
  ## Converts :code:`fieldArray` to the binary field.
  for row, line in fieldArray:
    for col in 1 .. 3:
      result.left = result.left or (line[col].uint64 shl (62 - col * 16 - row))

    for col in 4 .. 6:
      result.right = result.right or (line[col].uint64 shl (126 - col * 16 - row))
