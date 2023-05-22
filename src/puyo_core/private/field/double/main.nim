## This module implements a field using AVX2.
##

import bitops
import options

import ./binary
import ../../../cell
import ../../../common
import ../../../moveResult
import ../../../pair
import ../../../position

type Field* = tuple
  hardGarbage: BinaryField
  noneRed: BinaryField
  greenBlue: BinaryField
  yellowPurple: BinaryField

func zeroField*: Field {.inline.} =
  ## Returns the field with all elements zero.
  (hardGarbage: zeroBinaryField(), noneRed: zeroBinaryField(),
  greenBlue: zeroBinaryField(), yellowPurple: zeroBinaryField())

func `==`*(field1: Field, field2: Field): bool {.inline.} =
  (field1.hardGarbage == field2.hardGarbage and field1.noneRed == field2.noneRed) and
  (field1.greenBlue == field2.greenBlue and field1.yellowPurple == field2.yellowPurple)

func toCell(hardGarbage: int, noneRed: int, greenBlue: int, yellowPurple: int): Cell {.inline.} =
  ## Converts the values to a cell.
  return Cell bitor(
    hardGarbage,
    noneRed or (noneRed shr 1),
    (greenBlue + 3) * (greenBlue != 0).int,
    (yellowPurple + 5) * (yellowPurple != 0).int)
  
func `[]`*(field: Field, row: Row, col: Col): Cell {.inline.} =
  toCell(
    field.hardGarbage[row, col],
    field.noneRed[row, col],
    field.greenBlue[row, col],
    field.yellowPurple[row, col])

func toValues(cell: Cell): (uint8, uint8, uint8, uint8) {.inline.} =
  ## Converts the cell to the values for sub-fields.
  let
    castCell = cast[uint8](cell)
    bit1 = uint8 castCell.testBit 1
    bit2 = uint8 castCell.testBit 2

  return (
    castCell * (castCell < 3).uint8,
    2 * (castCell == 3).uint8,
    (castCell - 3) * bit2 * (1 - bit1),
    (castCell - 5) * bit2 * bit1)

func `[]=`*(field: var Field, row: Row, col: Col, cell: Cell) {.inline.} =
  let (hardGarbage, noneRed, greenBlue, yellowPurple) = cell.toValues
  field.hardGarbage[row, col] = hardGarbage
  field.noneRed[row, col] = noneRed
  field.greenBlue[row, col] = greenBlue
  field.yellowPurple[row, col] = yellowPurple

func insert*(field: var Field, row: Row, col: Col, cell: Cell) {.inline.} =
  ## Inserts the value and shifts the field up above where the value inserted.
  let (hardGarbage, noneRed, greenBlue, yellowPurple) = cell.toValues
  field.hardGarbage.insert row, col, hardGarbage
  field.noneRed.insert row, col, noneRed
  field.greenBlue.insert row, col, greenBlue
  field.yellowPurple.insert row, col, yellowPurple

func removeSqueeze*(field: var Field, row: Row, col: Col) {.inline.} =
  ## Removes the value and shifts the field down above where the value removed.
  field.hardGarbage.removeSqueeze row, col
  field.noneRed.removeSqueeze row, col
  field.greenBlue.removeSqueeze row, col
  field.yellowPurple.removeSqueeze row, col

func colorNum*(field: Field, puyo: ColorPuyo): int {.inline.} =
  ## Returns the number of the given puyoes in the field.
  case puyo
  of RED:
    field.noneRed.popcnt 1
  of GREEN:
    field.greenBlue.popcnt 0
  of BLUE:
    field.greenBlue.popcnt 1
  of YELLOW:
    field.yellowPurple.popcnt 0
  of PURPLE:
    field.yellowPurple.popcnt 1

func colorNum*(field: Field): int {.inline.} =
  ## Returns the number of color puyoes in the field.
  field.noneRed.popcnt(1) + field.greenBlue.popcnt + field.yellowPurple.popcnt

func garbageNum*(field: Field): int {.inline.} =
  ## Returns the number of hard and garbage puyoes in the field.
  field.hardGarbage.popcnt

func puyoNum*(field: Field): int {.inline.} =
  ## Returns the number of puyoes in the field.
  field.colorNum + field.garbageNum

func shiftedUp*(field: Field): Field {.inline.} =
  ## Returns a field shifted up.
  result.hardGarbage = field.hardGarbage.shiftedUp
  result.noneRed = field.noneRed.shiftedUp
  result.greenBlue = field.greenBlue.shiftedUp
  result.yellowPurple = field.yellowPurple.shiftedUp

func shiftedDown*(field: Field): Field {.inline.} =
  ## Returns a field shifted down.
  result.hardGarbage = field.hardGarbage.shiftedDown
  result.noneRed = field.noneRed.shiftedDown
  result.greenBlue = field.greenBlue.shiftedDown
  result.yellowPurple = field.yellowPurple.shiftedDown

func shiftedRight*(field: Field): Field {.inline.} =
  ## Returns a field shifted right.
  result.hardGarbage = field.hardGarbage.shiftedRight
  result.noneRed = field.noneRed.shiftedRight
  result.greenBlue = field.greenBlue.shiftedRight
  result.yellowPurple = field.yellowPurple.shiftedRight

func shiftedLeft*(field: Field): Field {.inline.} =
  ## Returns a field shifted left.
  result.hardGarbage = field.hardGarbage.shiftedLeft
  result.noneRed = field.noneRed.shiftedLeft
  result.greenBlue = field.greenBlue.shiftedLeft
  result.yellowPurple = field.yellowPurple.shiftedLeft

func disappearCore(
  field: var Field,
): (BinaryField, BinaryField, BinaryField, BinaryField, BinaryField) {.inline.} =
  ## Removes puyoes that should disappear.
  let
    red = field.noneRed.disappeared
    greenBlue = field.greenBlue.disappeared
    yellowPurple = field.yellowPurple.disappeared

    color = red + greenBlue + yellowPurple
    garbage = color.expanded * field.hardGarbage

  field.hardGarbage -= garbage
  field.noneRed -= red
  field.greenBlue -= greenBlue
  field.yellowPurple -= yellowPurple

  return (red, greenBlue, yellowPurple, garbage, color)

func disappear*(field: var Field) {.inline.} =
  ## Removes puyoes that should disappear.
  discard field.disappearCore

func willDisappear*(field: Field): bool {.inline.} =
  ## Returns whether any four or more values are connected or not.
  field.greenBlue.willDisappear or
  field.yellowPurple.willDisappear or
  field.noneRed.willDisappear

func exist(field: Field): BinaryField {.inline.} =
  ## Returns where any puyoes exist.
  ((field.hardGarbage + field.noneRed) + (field.greenBlue + field.yellowPurple)).exist

func fall*(field: var Field) {.inline.} =
  ## Drops floating puyoes.
  let existMask = field.exist + floorBinaryField()

  field.hardGarbage.fall existMask
  field.noneRed.fall existMask
  field.greenBlue.fall existMask
  field.yellowPurple.fall existMask

func put*(field: var Field, pair: Pair, pos: Position) {.inline.} =
  ## Puts the pair.
  const
    AxisLiftPositions = {POS_1D, POS_2D, POS_3D, POS_4D, POS_5D, POS_6D}
    ChildLiftPositions = {POS_1U, POS_2U, POS_3U, POS_4U, POS_5U, POS_6U}

  let
    existMask = field.exist
    next = existMask xor (existMask + floorBinaryField()).shiftedUp
    nexts = [false: next, true:next.shiftedUp]

    axisMask = nexts[pos in AxisLiftPositions].column(pos.axisCol)
    childMask = nexts[pos in ChildLiftPositions].column(pos.childCol)

    (_, noneRedValAxis, greenBlueValAxis, yellowPurpleValAxis) = pair.axis.toValues
    (_, noneRedValChild, greenBlueValChild, yellowPurpleValChild) = pair.child.toValues

  field.noneRed += axisMask * noneRedValAxis.filled + childMask * noneRedValChild.filled
  field.greenBlue += axisMask * greenBlueValAxis.filled + childMask * greenBlueValChild.filled
  field.yellowPurple += axisMask * yellowPurpleValAxis.filled + childMask * yellowPurpleValChild.filled

func move*(field: var Field, pair: Pair, pos: Position): MoveResult {.inline, discardable.} =
  ## Puts the pair and starts the chain until it ends.
  ## This function tracks the number of chains.
  field.put pair, pos

  while true:
    if field.disappearCore[4].isZero:
      return

    field.fall

    result.chainNum.inc

func calcDisappearNums(red, greenBlue, yellowPurple, garbage: BinaryField): array[Puyo, Natural] {.inline.} =
  ## Returns the numbers of disappeared puyoes.
  result[HARD] = 0
  result[GARBAGE] = garbage.popcnt
  result[RED] = red.popcnt
  result[GREEN] = greenBlue.popcnt 0
  result[BLUE] = greenBlue.popcnt 1
  result[YELLOW] = yellowPurple.popcnt 0
  result[PURPLE] = yellowPurple.popcnt 1

func moveWithRoughTracking*(field: var Field, pair: Pair, pos: Position): MoveResult {.inline.} =
  ## Puts the pair and starts the chain until it ends.
  ## Compared to :code:`move`, this function additionally tracks the total number of disappeared puyoes.
  field.put pair, pos

  var totalDisappearNums: array[Puyo, Natural]
  while true:
    let (red, greenBlue, yellowPurple, garbage, color) = field.disappearCore
    if color.isZero:
      result.totalDisappearNums = some totalDisappearNums
      return 

    field.fall

    result.chainNum.inc

    for puyo, num in calcDisappearNums(red, greenBlue, yellowPurple, garbage):
      totalDisappearNums[puyo].inc num

func moveWithDetailedTracking*(field: var Field, pair: Pair, pos: Position): MoveResult {.inline.} =
  ## Puts the pair and starts the chain until it ends.
  ## Compared to :code:`moveWithRoughTracking`,
  ## this function additionally tracks the number of disappeared puyoes in each chain.
  field.put pair, pos

  var
    totalDisappearNums: array[Puyo, Natural]
    disappearNumsSeq: seq[array[Puyo, Natural]]
  while true:
    let (red, greenBlue, yellowPurple, garbage, color) = field.disappearCore
    if color.isZero:
      result.totalDisappearNums = some totalDisappearNums
      result.disappearNums = some disappearNumsSeq
      return 

    field.fall

    result.chainNum.inc

    let disappearNums = calcDisappearNums(red, greenBlue, yellowPurple, garbage)
    for puyo, num in disappearNums:
      totalDisappearNums[puyo].inc num
    disappearNumsSeq.add disappearNums

func moveWithFullTracking*(field: var Field, pair: Pair, pos: Position): MoveResult {.inline.} =
  ## Puts the pair and starts the chain until it ends.
  ## This function tracks everything.
  field.put pair, pos

  var
    totalDisappearNums: array[Puyo, Natural]
    disappearNumsSeq: seq[array[Puyo, Natural]]
    detailedDisappearNums: seq[array[Puyo, seq[Natural]]]
  while true:
    let (red, greenBlue, yellowPurple, garbage, color) = field.disappearCore
    if color.isZero:
      result.totalDisappearNums = some totalDisappearNums
      result.disappearNums = some disappearNumsSeq
      result.detailedDisappearNums = some detailedDisappearNums
      return 

    field.fall

    result.chainNum.inc

    let disappearNums = calcDisappearNums(red, greenBlue, yellowPurple, garbage)
    for puyo, num in disappearNums:
      totalDisappearNums[puyo].inc num
    disappearNumsSeq.add disappearNums

    let
      garbageDetail = garbage.connectionDetail[1]
      redDetail = red.connectionDetail[1]
      greenBlueDetail = greenBlue.connectionDetail
      yellowPurpleDetail = yellowPurple.connectionDetail
    detailedDisappearNums.add [
      newSeq[Natural] 0,
      garbageDetail,
      redDetail,
      greenBlueDetail[0],
      greenBlueDetail[1],
      yellowPurpleDetail[0],
      yellowPurpleDetail[1],
    ]

func connect3*(field: Field): Field {.inline.} =
  ## Returns where three color puyoes are connected.
  ## This function ignores ghost puyoes.
  result.noneRed = field.noneRed.connect3
  result.greenBlue = field.greenBlue.connect3
  result.yellowPurple = field.yellowPurple.connect3

func connect3V*(field: Field): Field {.inline.} =
  ## Returns where three color puyoes are connected vertically.
  ## This function ignores ghost puyoes.
  result.noneRed = field.noneRed.connect3V
  result.greenBlue = field.greenBlue.connect3V
  result.yellowPurple = field.yellowPurple.connect3V

func connect3H*(field: Field): Field {.inline.} =
  ## Returns where three color puyoes are connected horizontally.
  ## This function ignores ghost puyoes.
  result.noneRed = field.noneRed.connect3H
  result.greenBlue = field.greenBlue.connect3H
  result.yellowPurple = field.yellowPurple.connect3H

func connect3L*(field: Field): Field {.inline.} =
  ## Returns where three color puyoes are connected by L-shape.
  ## This function ignores ghost puyoes.
  result.noneRed = field.noneRed.connect3L
  result.greenBlue = field.greenBlue.connect3L
  result.yellowPurple = field.yellowPurple.connect3L

func invalidPositions*(field: Field): set[Position] {.inline.} =
  ## Returns positions that cannot be put.
  field.exist.invalidPositions

func validPositions*(field: Field): set[Position] {.inline.} =
  ## Get positions that can be put in the field.
  field.exist.validPositions

func validDoublePositions*(field: Field): set[Position] {.inline.} =
  ## Get positions for a double pair that can be put in the field.
  field.exist.validDoublePositions

func isDead*(field: Field): bool {.inline.} =
  ## Returns whether the field is dead or not.
  field.exist.isDead

func toArray*(field: Field): array[Row, array[Col, Cell]] {.inline.} =
  ## Converts the field to an array.
  let
    hardGarbage = field.hardGarbage.toArray
    noneRed = field.noneRed.toArray
    greenBlue = field.greenBlue.toArray
    yellowPurple = field.yellowPurple.toArray

  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      result[row][col] = toCell(hardGarbage[row][col], noneRed[row][col], greenBlue[row][col], yellowPurple[row][col])

func toField*(`array`: array[Row, array[Col, Cell]]): Field {.inline.} =
  ## Converts the array to a field.
  var hardGarbageArray, noneRedArray, greenBlueArray, yellowPurpleArray: array[Row, array[Col, int]]
  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      let (hardGarbage, noneRed, greenBlue, yellowPurple) = `array`[row][col].toValues
      hardGarbageArray[row][col] = cast[int](hardGarbage)
      noneRedArray[row][col] = cast[int](noneRed)
      greenBlueArray[row][col] = cast[int](greenBlue)
      yellowPurpleArray[row][col] = cast[int](yellowPurple)

  result.hardGarbage = hardGarbageArray.toBinaryField
  result.noneRed = noneRedArray.toBinaryField
  result.greenBlue = greenBlueArray.toBinaryField
  result.yellowPurple = yellowPurpleArray.toBinaryField
