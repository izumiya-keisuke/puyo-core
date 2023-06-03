## This module provides a low-level implementation of the binary field.
##

import bitops

import nimsimd/avx2

import ../../intrinsic
import ../../../common

type
  BinaryField* = M256i ## Binary field; [color1:col0, ..., color1:col7, color2:col0, ..., color2:col7]
  WhichColor* = tuple[color1: int64, color2: int64] ## Indicates which color is specified.

  DropMask* = array[Width * 2, when UseBmi2: uint16 else: PextMask[uint16]] ## Mask used in :code:`drop`.

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func zeroBinaryField*: BinaryField {.inline.} =
  ## Returns the binary field with all elements zero.
  mm256_setzero_si256()

func floorBinaryField*: BinaryField {.inline.} =
  ## Returns the binary field with floor bits one.
  mm256_set1_epi16(0b0000_0000_0000_0001)

func filled*(which: WhichColor): BinaryField {.inline.} =
  ## Returns the binary field filled with the given color.
  let
    c1 = -which.color1
    c2 = -which.color2
  return mm256_set_epi64x(c1, c1, c2, c2)

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(field1, field2: BinaryField): bool {.inline.} =
  bool mm256_testc_si256(mm256_setzero_si256(), mm256_xor_si256(field1, field2))
func `+`*(field1, field2: BinaryField): BinaryField {.inline.} = mm256_or_si256(field1, field2)
func `-`*(field1, field2: BinaryField): BinaryField {.inline.} = mm256_andnot_si256(field2, field1)
func `*`*(field1, field2: BinaryField): BinaryField {.inline.} = mm256_and_si256(field1, field2)
func `xor`*(field1, field2: BinaryField): BinaryField {.inline.} = mm256_xor_si256(field1, field2)
func `shl`(field: BinaryField, imm8: int32): BinaryField {.inline.} = mm256_slli_epi16(field, imm8)
func `shr`(field: BinaryField, imm8: int32): BinaryField {.inline.} = mm256_srli_epi16(field, imm8)
func `+=`*(field1: var BinaryField, field2: BinaryField) {.inline.} = field1 = field1 + field2
func `-=`*(field1: var BinaryField, field2: BinaryField) {.inline.} = field1 = field1 - field2

func sum*(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  ## Returns the summation.
  field1 + field2 + field3

func sum*(field1, field2, field3, field4: BinaryField): BinaryField {.inline.} =
  ## Returns the summation.
  (field1 + field2) + (field3 + field4)

func sum*(field1, field2, field3, field4, field5: BinaryField): BinaryField {.inline.} =
  ## Returns the summation.
  (field1 + field2) + (field3 + field4 + field5)

func sum*(field1, field2, field3, field4, field5, field6, field7, field8: BinaryField): BinaryField {.inline.} =
  ## Returns the summation.
  ((field1 + field2) + (field3 + field4)) + ((field5 + field6) + (field7 + field8))

func prod*(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  ## Returns the production.
  field1 * field2 * field3

# ------------------------------------------------
# Population Count
# ------------------------------------------------

func popcnt*(field: BinaryField, color: 0 .. 1): int {.inline.} =
  ## Population count for the :code:`color`.
  # NOTE: YMM[e3, e2, e1, e0] == array[e0, e1, e2, e3]
  let fieldArray = cast[array[4, uint64]](field)
  return fieldArray[2 - 2 * color].popcount + fieldArray[3 - 2 * color].popcount
  
func popcnt*(field: BinaryField): int {.inline.} =
  ## Population count.
  let fieldArray = cast[array[4, uint64]](field)
  return fieldArray[0].popcount + fieldArray[1].popcount + fieldArray[2].popcount + fieldArray[3].popcount

# ------------------------------------------------
# Trim
# ------------------------------------------------

func trimmed*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field with the padding cleared.
  const
    Left = 0x0000_3FFE_3FFE_3FFE'u64
    Right = 0x3FFE_3FFE_3FFE_0000'u64

  return field * mm256_set_epi64x(Left, Right, Left, Right)

func visible*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field with only the visible area.
  const
    Left = 0x0000_1FFE_1FFE_1FFE'u64
    Right = 0x1FFE_1FFE_1FFE_0000'u64

  return field * mm256_set_epi64x(Left, Right, Left, Right)

func leftRightMasks(col: Col): tuple[left: int64, right: int64] {.inline.} =
  ## Returns :code:`(-1, 0)` if :code:`col` is in {1, 2, 3}; otherwise returns :code:`(0, -1)`.
  let rightMask = -((col.int64 and 4) shr 2)
  result.left = -1 - rightMask
  result.right = rightMask

func column*(field: BinaryField, col: Col): BinaryField {.inline.} =
  ## Returns the binary field with only the column :code:`col`.
  let
    (leftMask, rightMask) = col.leftRightMasks
    left = (0xFFFF_0000_0000_0000'u64 shr (16 * col)) and cast[uint64](leftMask)
    right = (0x0000_0000_0000_FFFF'u64 shl (16 * (7 - col))) and cast[uint64](rightMask)

  return field * mm256_set_epi64x(left, right, left, right)
  
# ------------------------------------------------
# Indexer
# ------------------------------------------------

func cellMasks(row: Row, col: Col): tuple[left: int64, right: int64] {.inline.} =
  ## Returns two masks with only the bit at position :code:`(row, col)` set to :code:`1`.
  let (leftMask, rightMask) = col.leftRightMasks
  result.left = (0x4000_0000_0000_0000'i64 shr (16 * col + row)) and leftMask
  result.right = (1'i64 shl (16 * (7 - col) + 14 - row)) and rightMask

func `[]`*(field: BinaryField, row: Row, col: Col): WhichColor {.inline.} =
  let (left, right) = cellMasks(row, col)
  result.color1 = mm256_testc_si256(field, mm256_set_epi64x(left, right, 0, 0))
  result.color2 = mm256_testc_si256(field, mm256_set_epi64x(0, 0, left, right))

func exist*(field: BinaryField, row: Row, col: Col): int {.inline.} =
  ## Returns :code:`1` if the bit :code:`(row, col)` is set; otherwise, returns :code:`0`.
  let which = field[row, col]
  return int which.color1 or which.color2

func `[]=`*(field: var BinaryField, row: Row, col: Col, which: WhichColor) {.inline.} =
  let
    (left, right) = cellMasks(row, col)
    color1 = -which.color1
    color2 = -which.color2

  field = field - mm256_set_epi64x(left, right, left, right) +
    mm256_set_epi64x(left and color1, right and color1, left and color2, right and color2)

func aboveMasks(row: Row, col: Col): tuple[left: int64, right: int64] {.inline.} =
  ## Returns two masks with only the bits at the range from :code:`(row, col)` to :code:`(0, col)` set to :code:`1`.
  let (left, right) = col.leftRightMasks
  result.left = (-1'i64.masked 16 * (3 - col) + 14 - row ..< 16 * (4 - col)) and left
  result.right = (-1'i64.masked 16 * (7 - col) + 14 - row ..< 16 * (8 - col)) and right

func insert*(field: var BinaryField, row: Row, col: Col, which: WhichColor) {.inline.} =
  ## Inserts :code:`which` and shift :code:`field` upward above the location where :code:`which` is inserted.
  let
    (left, right) = aboveMasks(row, col)
    moveMask = mm256_set_epi64x(left, right, left, right)
    moveField = moveMask * field

    color1 = -which.color1
    color2 = -which.color2
    insertField = (moveMask xor (moveMask shl 1)) * mm256_set_epi64x(
      left and color1, right and color1, left and color2, right and color2)

  field = field - moveField + ((moveField shl 1).trimmed + insertField)

func removeSqueeze*(field: var BinaryField, row: Row, col: Col) {.inline.} =
  ## Removes the value at :code:`(row, col)` and shift :code:`field` downward above the location where the cell is
  ## removed.
  let
    (left, right) = aboveMasks(row, col)
    moveMask = mm256_set_epi64x(left, right, left, right)
    moveField = moveMask * field

  field = field - moveField + (moveField - (moveMask xor (moveMask shl 1))) shr 1

# ------------------------------------------------
# Property
# ------------------------------------------------

func isZero*(field: BinaryField): bool {.inline.} =
  ## Returns :code:`true` if all elements are zero in the :code:`field`.
  mm256_testc_si256(zeroBinaryField(), field).bool

func exist*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the field where any cells exist.
  field + mm256_permute4x64_epi64(field, 0b01_00_11_10)

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
  mm256_srli_si256(field, 2)

func shiftedLeftWithoutTrim*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field shifted leftward the :code:`field`.
  mm256_slli_si256(field, 2)

# ------------------------------------------------
# Operation
# ------------------------------------------------

func toDropMask*(existField: BinaryField): DropMask {.inline.} =
  ## Converts :code:`existField` to the drop mask.
  let existArray = cast[array[16, uint16]](existField + floorBinaryField())

  for col in 1 .. 6:
    result[col.pred] = when UseBmi2: existArray[col] else: existArray[col].toPextMask
  for col in 9 .. 14:
    result[col.pred 3] = when UseBmi2: existArray[col] else: existArray[col].toPextMask

func drop*(field: var BinaryField, mask: DropMask) {.inline.} =
  ## Drops floating cells.
  let fieldArray = cast[array[16, uint16]](field)

  var resultArray: array[16, uint16]
  for col in 1 .. 6:
    resultArray[col] = fieldArray[col].pext mask[col.pred]
  for col in 9 .. 14:
    resultArray[col] = fieldArray[col].pext mask[col.pred 3]

  field = cast[BinaryField](resultArray)

# ------------------------------------------------
# BinaryField <-> array
# ------------------------------------------------

func toArray*(field: BinaryField): array[Row, array[Col, WhichColor]] {.inline.} =
  ## Converts :code:`field` to the array.
  let fieldArray = cast[array[16, int16]](field)

  for col in Col.low .. Col.high:
    # NOTE: YMM[e15, ..., e0] == array[e0, ..., e15]
    let
      colVal1 = fieldArray[15 - col]
      colVal2 = fieldArray[7 - col]

    for row in Row.low .. Row.high:
      let rowDigit = 14 - row
      result[row][col].color1 = int64 colVal1.testBit rowDigit
      result[row][col].color2 = int64 colVal2.testBit rowDigit

func toBinaryField*(fieldArray: array[Row, array[Col, WhichColor]]): BinaryField {.inline.} =
  ## Converts :code:`fieldArray` to the binary field.
  var color1Left, color1Right, color2Left, color2Right: int64
  for row, line in fieldArray:
    for col in 1 .. 3:
      let
        which = line[col]
        shift = 62 - col * 16 - row
      color1Left = color1Left or (which.color1 shl shift)
      color2Left = color2Left or (which.color2 shl shift)

    for col in 4 .. 6:
      let
        which = line[col]
        shift = 126 - col * 16 - row
      color1Right = color1Right or (which.color1 shl shift)
      color2Right = color2Right or (which.color2 shl shift)

  return mm256_set_epi64x(color1Left, color1Right, color2Left, color2Right)
