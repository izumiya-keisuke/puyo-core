## This module implements a binary field using a 32bit bitboard.
##

import bitops
import sequtils

import ../util

import ../../../../common
import ../../../../intrinsic

type BinaryField* = tuple
  left: uint32
  center: uint32
  right: uint32

const
  ZeroBinaryField* = (left: 0'u32, center: 0'u32, right: 0'u32)
  OneBinaryField* = (left: 0x3ffe_3ffe'u32, center: 0x3ffe_3ffe'u32, right: 0x3ffe_3ffe'u32)
  FloorBinaryField* = (left: 0x0001_0001'u32, center: 0x0001_0001'u32, right: 0x0001_0001'u32)

func `+`*(field, other: BinaryField): BinaryField {.inline.} =
  result.left = field.left or other.left
  result.center = field.center or other.center
  result.right = field.right or other.right

func `+=`*(field: var BinaryField, other: BinaryField) {.inline.} =
  field.left = field.left or other.left
  field.center = field.center or other.center
  field.right = field.right or other.right

func `-`(field, other: BinaryField): BinaryField {.inline.} =
  result.left = field.left.clearMasked other.left
  result.center = field.center.clearMasked other.center
  result.right = field.right.clearMasked other.right

func `*`(field, other: BinaryField): BinaryField {.inline.} =
  result.left = field.left and other.left
  result.center = field.center and other.center
  result.right = field.right and other.right

func `xor`*(field, other: BinaryField): BinaryField {.inline.} =
  result.left = field.left xor other.left
  result.center = field.center xor other.center
  result.right = field.right xor other.right

func add*(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  ## Gets the total of the arguments.
  result.left = bitor(field1.left, field2.left, field3.left)
  result.center = bitor(field1.center, field2.center, field3.center)
  result.right = bitor(field1.right, field2.right, field3.right)

func add*(field1, field2, field3, field4, field5: BinaryField): BinaryField {.inline.} =
  ## Gets the total of the arguments.
  result.left = bitor(field1.left, field2.left, field3.left, field4.left, field5.left)
  result.center = bitor(field1.center, field2.center, field3.center, field4.center, field5.center)
  result.right = bitor(field1.right, field2.right, field3.right, field4.right, field5.right)

func add*(field1, field2, field3, field4, field5, field6: BinaryField): BinaryField {.inline.} =
  ## Gets the total of the arguments.
  result.left = bitor(field1.left, field2.left, field3.left, field4.left, field5.left, field6.left)
  result.center = bitor(field1.center, field2.center, field3.center, field4.center, field5.center, field6.center)
  result.right = bitor(field1.right, field2.right, field3.right, field4.right, field5.right, field6.right)

func add(field1, field2, field3, field4, field5, field6, field7, field8: BinaryField): BinaryField {.inline.} =
  ## Gets the total of the arguments.
  result.left = bitor(
    field1.left, field2.left, field3.left, field4.left, field5.left, field6.left, field7.left, field8.left
  )
  result.center = bitor(
    field1.center, field2.center, field3.center, field4.center, field5.center, field6.center, field7.center, field8.center
  )
  result.right = bitor(
    field1.right, field2.right, field3.right, field4.right, field5.right, field6.right, field7.right, field8.right
  )

func mul(field1, field2, field3: BinaryField): BinaryField {.inline.} =
  ## Gets the total product of the arguments.
  result.left = bitand(field1.left, field2.left, field3.left)
  result.center = bitand(field1.center, field2.center, field3.center)
  result.right = bitand(field1.right, field2.right, field3.right)

func leftIdx(row: Row, col: Col): int {.inline.} =
  ## Gets the bit index in the left.
  16 * (2 - col) + 14 - row

func centerIdx(row: Row, col: Col): int {.inline.} =
  ## Gets the bit index in the center.
  16 * (4 - col) + 14 - row

func rightIdx(row: Row, col: Col): int {.inline.} =
  ## Gets the bit index in the right.
  16 * (6 - col) + 14 - row

func `[]`*(field: BinaryField, row: Row, col: Col): bool {.inline.} =
  case col
  of 1, 2:
    return field.left.testBit leftIdx(row, col)
  of 3, 4:
    return field.center.testBit centerIdx(row, col)
  of 5, 6:
    return field.right.testBit rightIdx(row, col)

func `[]=`*(field: var BinaryField, row: Row, col: Col, val: bool) {.inline.} =
  case col
  of 1, 2:
    let digit = leftIdx(row, col)
    if val:
      field.left.setBit digit
    else:
      field.left.clearBit digit
  of 3, 4:
    let digit = centerIdx(row, col)
    if val:
      field.center.setBit digit
    else:
      field.center.clearBit digit
  of 5, 6:
    let digit = rightIdx(row, col)
    if val:
      field.right.setBit digit
    else:
      field.right.clearBit digit

func insert*(field: var BinaryField, row: Row, col: Col, val: bool) {.inline.} =
  ## Inserts a value and shifts values up above where inserted.
  case col
  of 1, 2:
    let
      digit = leftIdx(row, col)
      rewriteSlice = digit ..< 16 * (3 - col)
      moved = field.left.masked(rewriteSlice) shl 1

    field.left.clearMask rewriteSlice
    field.left.setMask moved
    if val:
      field.left.setBit digit
  of 3, 4:
    let
      digit = centerIdx(row, col)
      rewriteSlice = digit ..< 16 * (5 - col)
      moved = field.center.masked(rewriteSlice) shl 1

    field.center.clearMask rewriteSlice
    field.center.setMask moved
    if val:
      field.center.setBit digit
  of 5, 6:
    let
      digit = rightIdx(row, col)
      rewriteSlice = digit ..< 16 * (7 - col)
      moved = field.right.masked(rewriteSlice) shl 1

    field.right.clearMask rewriteSlice
    field.right.setMask moved
    if val:
      field.right.setBit digit

func removeSqueeze*(field: var BinaryField, row: Row, col: Col) {.inline.} =
  ## Removes a value and shifts values down above where removed.
  case col
  of 1, 2:
    let
      digit = leftIdx(row, col)
      moved = field.left.masked(digit.succ ..< 16 * (3 - col)) shr 1

    field.left.clearMask digit ..< 16 * (3 - col)
    field.left.setMask moved
  of 3, 4:
    let
      digit = centerIdx(row, col)
      moved = field.center.masked(digit.succ ..< 16 * (5 - col)) shr 1

    field.center.clearMask digit ..< 16 * (5 - col)
    field.center.setMask moved
  of 5, 6:
    let
      digit = rightIdx(row, col)
      moved = field.right.masked(digit.succ ..< 16 * (7 - col)) shr 1

    field.right.clearMask digit ..< 16 * (7 - col)
    field.right.setMask moved

func popcnt*(field: BinaryField): int {.inline.} =
  ## Gets the number of set bits in the binary field.
  field.left.popcount + field.center.popcount + field.right.popcount

func clearMask*(field: var BinaryField, mask: BinaryField) {.inline.} =
  ## Resets where masked.
  field.left.clearMask mask.left
  field.center.clearMask mask.center
  field.right.clearMask mask.right

func clearMasked*(field, mask: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field with the masked area reset.
  result.left = field.left.clearMasked mask.left
  result.center = field.center.clearMasked mask.center
  result.right = field.right.clearMasked mask.right

func mask(field: var BinaryField, mask: BinaryField) {.inline.} =
  ## Resets where not masked.
  field.left.mask mask.left
  field.center.mask mask.center
  field.right.mask mask.right

func masked*(field, mask: BinaryField): BinaryField {.inline.} =
  ## Returns where masked.
  result.left = field.left.masked mask.left
  result.center = field.center.masked mask.center
  result.right = field.right.masked mask.right

func trimField*(field: var BinaryField) {.inline.} =
  ## Resets where is not a valid field.
  field.mask OneBinaryField

func trimmedField*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where is a valid field.
  field.masked OneBinaryField

func trimmedVisible*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where is visible.
  field.masked (left: 0x1ffe_1ffe'u32, center: 0x1ffe_1ffe'u32, right: 0x1ffe_1ffe'u32)

func trimmedCol*(field: BinaryField, col: Col): BinaryField {.inline.} =
  ## Returns the binary field only with the specified column.
  const ColMasks: array[Col, BinaryField] = [
    (left: 0xffff_0000'u32, center: 0'u32, right: 0'u32),
    (left: 0x0000_ffff'u32, center: 0'u32, right: 0'u32),
    (left: 0'u32, center: 0xffff_0000'u32, right: 0'u32),
    (left: 0'u32, center: 0x0000_ffff'u32, right: 0'u32),
    (left: 0'u32, center: 0'u32, right: 0xffff_0000'u32),
    (left: 0'u32, center: 0'u32, right: 0x0000_ffff'u32),
  ]
  return field.masked ColMasks[col]

func shiftedUp(halfField: uint32): uint32 {.inline.} =
  ## Returns a half binary field shifted up.
  (halfField shl 1) and 0xfffe_fffe'u32

func shiftedDown(halfField: uint32): uint32 {.inline.} =
  ## Returns a half binary field shifted down.
  (halfField shr 1) and 0x7fff_7fff'u32

func shiftedUp*(field: BinaryField): BinaryField {.inline.} =
  ## Returns a binary field shifted up.
  result.left = field.left.shiftedUp
  result.center = field.center.shiftedUp
  result.right = field.right.shiftedUp

func shiftedDown*(field: BinaryField): BinaryField {.inline.} =
  ## Returns a binary field shifted down.
  result.left = field.left.shiftedDown
  result.center = field.center.shiftedDown
  result.right = field.right.shiftedDown

func shiftedRight*(field: BinaryField): BinaryField {.inline.} =
  ## Returns a binary field shifted right.
  result.left = field.left shr 16
  result.center = (field.center shr 16) or (field.left shl 16)
  result.right = (field.right shr 16) or (field.center shl 16)

func shiftedLeft*(field: BinaryField): BinaryField {.inline.} =
  ## Returns a binary field shifted left.
  result.left = (field.left shl 16) or (field.center shr 16)
  result.center = (field.center shl 16) or (field.right shr 16)
  result.right = field.right shl 16

func connectMasks(field: BinaryField): (BinaryField, BinaryField, BinaryField) {.inline.} =
  ## Returns an intermediate fields for calculating puyoes that will disappear.
  let
    visibleField = field.trimmedVisible

    up = visibleField * visibleField.shiftedUp
    down = visibleField * visibleField.shiftedDown
    right = visibleField * visibleField.shiftedRight
    left = visibleField * visibleField.shiftedLeft

    upAndDown = up * down
    upOrDown = up + down
    leftAndRight = left * right
    leftOrRight = left + right

    threeOrMore = upAndDown * leftOrRight + upOrDown * leftAndRight
    twoOrMore = add(upAndDown, leftAndRight, upOrDown * leftOrRight)

    doubleTwoDown = twoOrMore.shiftedDown * twoOrMore
    doubleTwoLeft = twoOrMore.shiftedLeft * twoOrMore

  return (add(threeOrMore, doubleTwoDown, doubleTwoLeft), twoOrMore, visibleField)

func expanded*(field: BinaryField): BinaryField {.inline.} =
  ## Dilates the binary field.
  add(field, field.shiftedUp, field.shiftedDown, field.shiftedRight, field.shiftedLeft)

func expandedVertically(field: BinaryField): BinaryField {.inline.} =
  ## Dilates the binary field vertically.
  add(field, field.shiftedUp, field.shiftedDown)

func expandedHorizontally(field: BinaryField): BinaryField {.inline.} =
  ## Dilates the binary field horizontally.
  add(field, field.shiftedRight, field.shiftedLeft)

func disappeared(tmpMask, twoOrMore, visibleField: BinaryField): BinaryField {.inline.} =
  ## Returns where puyoes will disappear from the return values of :code:`connectMasks`.
  if tmpMask == ZeroBinaryField:
    return ZeroBinaryField

  let
    doubleTwoUp = twoOrMore.shiftedUp * twoOrMore
    doubleTwoRight = twoOrMore.shiftedRight * twoOrMore

  return add(tmpMask, doubleTwoUp, doubleTwoRight).expanded.masked visibleField

func connect3*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where three color puyoes are connected.
  ## This function ignores ghost puyoes.
  let (tmpMask, twoOrMore, visibleField) = field.connectMasks
  return twoOrMore.expanded.masked visibleField - disappeared(tmpMask, twoOrMore, visibleField)

func connect3V*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where three color puyoes are connected vertically.
  ## This function ignores ghost puyoes.
  let
    visibleField = field.trimmedVisible

    up = visibleField.shiftedUp
    down = visibleField.shiftedDown
    right = visibleField.shiftedRight
    left = visibleField.shiftedLeft

    exclude = visibleField * add(
      right, left, up.shiftedLeft, up.shiftedRight, down.shiftedLeft, down.shiftedRight, up.shiftedUp, down.shiftedDown
    )
    upAndDown = mul(visibleField, up, down)

  return (upAndDown - exclude).expandedVertically

func connect3H*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where three color puyoes are connected horizontally.
  ## This function ignores ghost puyoes.
  let
    visibleField = field.trimmedVisible

    up = visibleField.shiftedUp
    down = visibleField.shiftedDown
    right = visibleField.shiftedRight
    left = visibleField.shiftedLeft

    exclude = visibleField * add(
      up,
      down,
      up.shiftedLeft,
      up.shiftedRight,
      down.shiftedLeft,
      down.shiftedRight,
      left.shiftedLeft,
      right.shiftedRight,
    )
    rightAndLeft = mul(visibleField, right, left)

  return (rightAndLeft - exclude).expandedHorizontally

func connect3L*(field: BinaryField): BinaryField {.inline.} =
  ## Returns where three color puyoes are connected by L-shape.
  ## This function ignores ghost puyoes.
  let
    visibleField = field.trimmedVisible

    up = visibleField * visibleField.shiftedUp
    down = visibleField * visibleField.shiftedDown
    right = visibleField * visibleField.shiftedRight
    left = visibleField * visibleField.shiftedLeft

    upAndDown = up * down
    upOrDown = up + down
    leftAndRight = left * right
    leftOrRight = left + right

    threeOrMore = upAndDown * leftOrRight + upOrDown * leftAndRight
    twoOrMore = add(upAndDown, leftAndRight, upOrDown * leftOrRight)

    threeMask = twoOrMore.expanded.masked visibleField - (
      twoOrMore * add(
        threeOrMore,
        twoOrMore.shiftedUp,
        twoOrMore.shiftedDown,
        twoOrMore.shiftedRight,
        twoOrMore.shiftedLeft,
      )
    ).expanded.masked visibleField

  return threeMask - upAndDown.expandedVertically - leftAndRight.expandedHorizontally

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
      if (col in 1 .. 2 and not field.left.testBit leftIdx(row, col)) or (
        col in 3 .. 4 and not field.center.testBit centerIdx(row, col)
      ) or (col in 5 .. 6 and not field.right.testBit rightIdx(row, col)):
        continue

      let
        up = fieldArray[row.int.pred][col]
        left = fieldArray[row][col.int.pred]
      if up == 0 and left == 0:
        fieldArray[row][col] = nextNewIdx
        nextNewIdx.inc
        continue

      if up == 0:
        fieldArray[row][col] = left
      elif left == 0:
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
  let (tmpMask, twoOrMore, visibleField) = field.connectMasks
  return disappeared(tmpMask, twoOrMore, visibleField)

func willDisappear*(field: BinaryField): bool {.inline.} =
  ## Returns whether any values will disappear.
  field.connectMasks[0] != ZeroBinaryField

func fall(halfField: uint32, exist: uint32): uint32 {.inline.} =
  ## Drops floating values in the half binary field.
  let
    col1 = halfField.bitsliced 17 ..< 32
    col0 = halfField.bitsliced 1 ..< 16

    exist1 = exist.bitsliced 17 ..< 32
    exist0 = exist.bitsliced 1 ..< 16

    fallenCol1 = col1.pext exist1
    fallenCol0 = col0.pext exist0

  return bitor(fallenCol1 shl 17, fallenCol0 shl 1)

func fall*(field: var BinaryField, exist: BinaryField) {.inline.} =
  ## Drops floating values in the binary field.
  field.left = field.left.fall exist.left
  field.center = field.center.fall exist.center
  field.right = field.right.fall exist.right

func toArray*(field: BinaryField): array[Row, array[Col, bool]] {.inline.} =
  ## Converts the binary field to an array.
  for row in Row.low .. Row.high:
    result[row][1] = field.left.testBit 30 - row
    result[row][2] = field.left.testBit 14 - row
    result[row][3] = field.center.testBit 30 - row
    result[row][4] = field.center.testBit 14 - row
    result[row][5] = field.right.testBit 30 - row
    result[row][6] = field.right.testBit 14 - row

func toBinaryField*(`array`: array[Row, array[Col, bool]]): BinaryField {.inline.} =
  ## Converts the array to a binary field.
  for row, line in `array`:
    if line[1]:
      result.left.setBit 30 - row
    else:
      result.left.clearBit 30 - row

    if line[2]:
      result.left.setBit 14 - row
    else:
      result.left.clearBit 14 - row

    if line[3]:
      result.center.setBit 30 - row
    else:
      result.center.clearBit 30 - row

    if line[4]:
      result.center.setBit 14 - row
    else:
      result.center.clearBit 14 - row

    if line[5]:
      result.right.setBit 30 - row
    else:
      result.right.clearBit 30 - row

    if line[6]:
      result.right.setBit 14 - row
    else:
      result.right.clearBit 14 - row
