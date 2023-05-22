## This module implements a binary field using a 64bit bitboard.
##

import bitops
import sequtils

import ../../../../common
import ../../../../intrinsic
import ../../../../util

type BinaryField* = tuple
  left: uint64
  right: uint64

const
  ZeroBinaryField* = (left: 0'u64, right: 0'u64)
  OneBinaryField* = (left: 0x0000_3ffe_3ffe_3ffe'u64, right: 0x3ffe_3ffe_3ffe_0000'u64)
  FloorBinaryField* = (left: 0x0000_0001_0001_0001'u64, right: 0x0001_0001_0001_0000'u64)

func `+`*(field, other: BinaryField): BinaryField {.inline.} =
  result.left = field.left or other.left
  result.right = field.right or other.right

func `+=`*(field: var BinaryField, other: BinaryField) {.inline.} =
  field.left = field.left or other.left
  field.right = field.right or other.right

func `-`(field, other: BinaryField): BinaryField {.inline.} =
  result.left = field.left.clearMasked other.left
  result.right = field.right.clearMasked other.right

func `*`(field, other: BinaryField): BinaryField {.inline.} =
  result.left = field.left and other.left
  result.right = field.right and other.right

func `xor`*(field, other: BinaryField): BinaryField {.inline.} =
  result.left = field.left xor other.left
  result.right = field.right xor other.right

func add*(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  ## Gets the total of the arguments.
  result.left = bitor(field1.left, field2.left, field3.left)
  result.right = bitor(field1.right, field2.right, field3.right)

func add*(field1, field2, field3, field4, field5: BinaryField): BinaryField {.inline.} =
  ## Gets the total of the arguments.
  result.left = bitor(field1.left, field2.left, field3.left, field4.left, field5.left)
  result.right = bitor(field1.right, field2.right, field3.right, field4.right, field5.right)

func add*(field1, field2, field3, field4, field5, field6: BinaryField): BinaryField {.inline.} =
  ## Gets the total of the arguments.
  result.left = bitor(field1.left, field2.left, field3.left, field4.left, field5.left, field6.left)
  result.right = bitor(field1.right, field2.right, field3.right, field4.right, field5.right, field6.right)

func add(field1, field2, field3, field4, field5, field6, field7, field8: BinaryField): BinaryField {.inline.} =
  ## Gets the total of the arguments.
  result.left = bitor(
    field1.left, field2.left, field3.left, field4.left, field5.left, field6.left, field7.left, field8.left
  )
  result.right = bitor(
    field1.right, field2.right, field3.right, field4.right, field5.right, field6.right, field7.right, field8.right
  )

func mul(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  ## Gets the total product of the arguments.
  result.left = bitand(field1.left, field2.left, field3.left)
  result.right = bitand(field1.right, field2.right, field3.right)

func leftIdx(row: Row, col: Col): int {.inline.} =
  ## Gets the bit index in the left.
  16 * (3 - col) + 14 - row

func rightIdx(row: Row, col: Col): int {.inline.} =
  ## Gets the bit index in the right.
  16 * (7 - col) + 14 - row

func `[]`*(field: BinaryField, row: Row, col: Col): bool {.inline.} =
  if col <= 3:
    return field.left.testBit leftIdx(row, col)
  else:
    return field.right.testBit rightIdx(row, col)

func `[]=`*(field: var BinaryField, row: Row, col: Col, val: bool) {.inline.} =
  if col <= 3:
    let digit = leftIdx(row, col)
    if val:
      field.left.setBit digit
    else:
      field.left.clearBit digit
  else:
    let digit = rightIdx(row, col)
    if val:
      field.right.setBit digit
    else:
      field.right.clearBit digit

func insert*(field: var BinaryField, row: Row, col: Col, val: bool) {.inline.} =
  ## Inserts a value and shifts values up above where inserted.
  if col <= 3:
    let
      digit = leftIdx(row, col)
      rewriteSlice = digit ..< 16 * (4 - col)
      moved = field.left.masked(rewriteSlice) shl 1

    field.left.clearMask rewriteSlice
    field.left.setMask moved
    if val:
      field.left.setBit digit
  else:
    let
      digit = rightIdx(row, col)
      rewriteSlice = digit ..< 16 * (8 - col)
      moved = field.right.masked(rewriteSlice) shl 1

    field.right.clearMask rewriteSlice
    field.right.setMask moved
    if val:
      field.right.setBit digit

func removeSqueeze*(field: var BinaryField, row: Row, col: Col) {.inline.} =
  ## Removes a value and shifts values down above where removed.
  if col <= 3:
    let
      digit = leftIdx(row, col)
      moved = field.left.masked(digit.succ ..< 16 * (4 - col)) shr 1

    field.left.clearMask digit ..< 16 * (4 - col)
    field.left.setMask moved
  else:
    let
      digit = rightIdx(row, col)
      moved = field.right.masked(digit.succ ..< 16 * (8 - col)) shr 1

    field.right.clearMask digit ..< 16 * (8 - col)
    field.right.setMask moved

func popcnt*(field: BinaryField): int {.inline.} =
  ## Gets the number of set bits in the binary field.
  field.left.popcount + field.right.popcount

func clearMask*(field: var BinaryField, mask: BinaryField) {.inline.} =
  ## Resets where masked.
  field.left.clearMask mask.left
  field.right.clearMask mask.right

func clearMasked*(field, mask: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field with the masked area reset.
  result.left = field.left.clearMasked mask.left
  result.right = field.right.clearMasked mask.right

func mask(field: var BinaryField, mask: BinaryField) {.inline.} =
  ## Resets where not masked.
  field.left.mask mask.left
  field.right.mask mask.right

func masked*(field, mask: BinaryField): BinaryField {.inline.} =
  ## Returns where masked.
  result.left = field.left.masked mask.left
  result.right = field.right.masked mask.right

func trimField*(field: var BinaryField) {.inline.} =
  ## Resets where is not a valid field.
  field.mask OneBinaryField

func trimmedField*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where is a valid field.
  field.masked OneBinaryField

func trimmedVisible*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where is visible.
  field.masked (left: 0x0000_1ffe_1ffe_1ffe'u64, right: 0x1ffe_1ffe_1ffe_0000'u64)

func trimmedCol*(field: BinaryField, col: Col): BinaryField {.inline.} =
  ## Returns the binary field only with the specified column.
  const ColMasks: array[Col, BinaryField] = [
    (left: 0x0000_ffff_0000_0000'u64, right: 0'u64),
    (left: 0x0000_0000_ffff_0000'u64, right: 0'u64),
    (left: 0x0000_0000_0000_ffff'u64, right: 0'u64),
    (left: 0'u64, right: 0xffff_0000_0000_0000'u64),
    (left: 0'u64, right: 0x0000_ffff_0000_0000'u64),
    (left: 0'u64, right: 0x0000_0000_ffff_0000'u64),
  ]
  return field.masked ColMasks[col]

func shiftedUp(halfField: uint64): uint64 {.inline.} =
  ## Returns a half binary field shifted up.
  (halfField shl 1) and 0xfffe_fffe_fffe_fffe'u64

func shiftedDown(halfField: uint64): uint64 {.inline.} =
  ## Returns a half binary field shifted down.
  (halfField shr 1) and 0x7fff_7fff_7fff_7fff'u64

func shiftedUp*(field: BinaryField): BinaryField {.inline.} =
  ## Returns a binary field shifted up.
  result.left = field.left.shiftedUp
  result.right = field.right.shiftedUp

func shiftedDown*(field: BinaryField): BinaryField {.inline.} =
  ## Returns a binary field shifted down.
  result.left = field.left.shiftedDown
  result.right = field.right.shiftedDown

func shiftedRight*(field: BinaryField): BinaryField {.inline.} =
  ## Returns a binary field shifted right.
  result.left = field.left shr 16
  result.right = (field.right shr 16) or (field.left shl 48)

func shiftedLeft*(field: BinaryField): BinaryField {.inline.} =
  ## Returns a binary field shifted left.
  result.left = (field.left shl 16) or (field.right shr 48)
  result.right = field.right shl 16

func expanded*(field: BinaryField): BinaryField {.inline.} =
  ## Dilates the binary field.
  add(field, field.shiftedUp, field.shiftedDown, field.shiftedRight, field.shiftedLeft)

func connectFields(field: BinaryField): (BinaryField, BinaryField, BinaryField, BinaryField, BinaryField) {.inline.} =
  ## Returns intermediate fields for calculating puyoes that will disappear.
  let
    visible = field.trimmedVisible

    hasUp = visible * visible.shiftedDown
    hasDown = visible * visible.shiftedUp
    hasRight = visible * visible.shiftedLeft
    hasLeft = visible * visible.shiftedRight

    hasUpDown = hasUp * hasDown
    hasRightLeft = hasRight * hasLeft
    hasUpOrDown = hasUp + hasDown
    hasRightOrLeft = hasRight + hasLeft

    connect4T = hasUpDown * hasRightOrLeft + hasRightLeft * hasUpOrDown
    connect3IL = add(hasUpDown, hasRightLeft, hasUpOrDown * hasRightOrLeft)

  return (visible, hasUpDown, hasRightLeft, connect4T, connect3IL)

func disappeared(visible, connect4T, connect3IL: BinaryField): BinaryField {.inline.} =
  ## Returns where puyoes will disappear from the return values of :code:`connectFields`.
  let
    connect4Up = connect3IL * connect3IL.shiftedUp
    connect4Right = connect3IL * connect3IL.shiftedRight
    connect4Tmp = add(connect4T, connect4Up, connect4Right)

  if connect4Tmp == ZeroBinaryField:
    return ZeroBinaryField

  let
    connect4Down = connect3IL * connect3IL.shiftedDown
    connect4Left = connect3IL * connect3IL.shiftedLeft
  return add(connect4Tmp, connect4Down, connect4Left).expanded.masked visible

func connect3*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where three color puyoes are connected.
  ## This function ignores ghost puyoes.
  let (visible, _, _, connect4T, connect3IL) = field.connectFields
  return connect3IL.expanded.masked visible - disappeared(visible, connect4T, connect3IL)

func expandedVertically(field: BinaryField): BinaryField {.inline.} =
  ## Dilates the binary field vertically.
  add(field, field.shiftedUp, field.shiftedDown)

func connect3V*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where three color puyoes are connected vertically.
  ## This function ignores ghost puyoes.
  let
    visible = field.trimmedVisible

    up = visible.shiftedUp
    down = visible.shiftedDown
    right = visible.shiftedRight
    left = visible.shiftedLeft

    upDown = mul(visible, up, down)
    exclude = visible * add(
      right, left, up.shiftedLeft, up.shiftedRight, down.shiftedLeft, down.shiftedRight, up.shiftedUp, down.shiftedDown
    )

  return (upDown - exclude).expandedVertically

func expandedHorizontally(field: BinaryField): BinaryField {.inline.} =
  ## Dilates the binary field horizontally.
  add(field, field.shiftedRight, field.shiftedLeft)

func connect3H*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where three color puyoes are connected horizontally.
  ## This function ignores ghost puyoes.
  let
    visible = field.trimmedVisible

    up = visible.shiftedUp
    down = visible.shiftedDown
    right = visible.shiftedRight
    left = visible.shiftedLeft

    rightLeft = mul(visible, right, left)
    exclude = visible * add(
      up,
      down,
      up.shiftedLeft,
      up.shiftedRight,
      down.shiftedLeft,
      down.shiftedRight,
      left.shiftedLeft,
      right.shiftedRight,
    )

  return (rightLeft - exclude).expandedHorizontally

func connect3L*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where three color puyoes are connected by L-shape.
  ## This function ignores ghost puyoes.
  let (visible, hasUpDown, hasRightLeft, connect4T, connect3IL) = field.connectFields

  return connect3IL.expanded.masked visible - add(
    disappeared(visible, connect4T, connect3IL), hasUpDown.expandedVertically, hasRightLeft.expandedHorizontally
  )

func connects*(field: BinaryField): seq[Natural] {.inline.} =
  ## Returns the number of puyoes for all connected components.
  ## The order of the returned sequence is not defined.
  ## This function ignores ghost puyoes.
  var
    fieldArray: array[Row.high - Row.low + 3, array[Col.high - Col.low + 3, int]]
    uf = initUnionFind Height * Width
    nextNewIdx = 1

  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      if (col <= 3 and not field.left.testBit leftIdx(row, col)) or (
        col >= 4 and not field.right.testBit rightIdx(row, col)
      ):
        continue

      let
        up = fieldArray[row.int.pred][col]
        left = fieldArray[row][col.int.pred]

      if up == 0:
        if left == 0:
          fieldArray[row][col] = nextNewIdx
          nextNewIdx.inc
        else:
          fieldArray[row][col] = left
      else:
        if left == 0:
          fieldArray[row][col] = up
        else:
          fieldArray[row][col] = min(up, left)
          uf.merge up, left

  var nums = 0.Natural.repeat nextNewIdx
  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      if fieldArray[row][col] == 0:
        continue

      nums[uf.getRoot fieldArray[row][col]].inc

  return nums.filterIt it > 0

func disappeared*(field: BinaryField): BinaryField {.inline.} =
  ## Resets values connected by four or more.
  let (visible, _, _, connect4T, connect3IL) = field.connectFields
  return disappeared(visible, connect4T, connect3IL)

func willDisappear*(field: BinaryField): bool {.inline.} =
  ## Returns whether any values will disappear.
  let
    (_, _, _, connect4T, connect3IL) = field.connectFields

    connect4Up = connect3IL * connect3IL.shiftedUp
    connect4Right = connect3IL * connect3IL.shiftedRight

  return add(connect4T, connect4Up, connect4Right) != ZeroBinaryField

func fall(halfField: uint64, exist: uint64): uint64 {.inline.} =
  ## Drops floating values in the half binary field.
  let
    col3 = halfField.bitsliced 49 ..< 64
    col2 = halfField.bitsliced 33 ..< 48
    col1 = halfField.bitsliced 17 ..< 32
    col0 = halfField.bitsliced 1 ..< 16

    exist3 = exist.bitsliced 49 ..< 64
    exist2 = exist.bitsliced 33 ..< 48
    exist1 = exist.bitsliced 17 ..< 32
    exist0 = exist.bitsliced 1 ..< 16

    fallenCol3 = col3.pext exist3
    fallenCol2 = col2.pext exist2
    fallenCol1 = col1.pext exist1
    fallenCol0 = col0.pext exist0

  return bitor(fallenCol3 shl 49, fallenCol2 shl 33, fallenCol1 shl 17, fallenCol0 shl 1)

func fall*(field: var BinaryField, exist: BinaryField) {.inline.} =
  ## Drops floating values in the binary field.
  field.left = field.left.fall exist.left
  field.right = field.right.fall exist.right

func toArray*(field: BinaryField): array[Row, array[Col, bool]] {.inline.} =
  ## Converts the binary field to an array.
  for row in Row.low .. Row.high:
    result[row][1] = field.left.testBit 46 - row
    result[row][2] = field.left.testBit 30 - row
    result[row][3] = field.left.testBit 14 - row
    result[row][4] = field.right.testBit 62 - row
    result[row][5] = field.right.testBit 46 - row
    result[row][6] = field.right.testBit 30 - row

func toBinaryField*(`array`: array[Row, array[Col, bool]]): BinaryField {.inline.} =
  ## Converts the array to a binary field.
  for row, line in `array`:
    if line[1]:
      result.left.setBit 46 - row
    else:
      result.left.clearBit 46 - row

    if line[2]:
      result.left.setBit 30 - row
    else:
      result.left.clearBit 30 - row

    if line[3]:
      result.left.setBit 14 - row
    else:
      result.left.clearBit 14 - row

    if line[4]:
      result.right.setBit 62 - row
    else:
      result.right.clearBit 62 - row

    if line[5]:
      result.right.setBit 46 - row
    else:
      result.right.clearBit 46 - row

    if line[6]:
      result.right.setBit 30 - row
    else:
      result.right.clearBit 30 - row
