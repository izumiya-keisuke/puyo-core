## This module implements a field using a bitboard.
##

import bitops
import options

when defined(cpu32):
  import ./bitboard32/binaryfield
else:
  import ./bitboard64/binaryfield
import ../../../cell
import ../../../common
import ../../../moveResult
import ../../../pair
import ../../../position

type Field* = tuple
  hard: BinaryField
  garbage: BinaryField
  red: BinaryField
  green: BinaryField
  blue: BinaryField
  yellow: BinaryField
  purple: BinaryField

func zeroField*: Field {.inline.} =
  ## Returns the field with all elements zero.
  (
    hard: zeroBinaryField(),
    garbage: zeroBinaryField(),
    red: zeroBinaryField(),
    green: zeroBinaryField(),
    blue: zeroBinaryField(),
    yellow: zeroBinaryField(),
    purple: zeroBinaryField(),
  )

func `==`*(field1: Field, field2: Field): bool {.inline.} =
  cast[bool](bitand(
    cast[int](field1.hard == field2.hard),
    cast[int](field1.garbage == field2.garbage),
    cast[int](field1.red == field2.red),
    cast[int](field1.green == field2.green),
    cast[int](field1.blue == field2.blue),
    cast[int](field1.yellow == field2.yellow),
    cast[int](field1.purple == field2.purple)))

func toCell(hard, garbage, red, green, blue, yellow, purple: bool): Cell {.inline.} =
  ## Converts the values to a cell.
  return Cell bitor(
    cast[int](hard) * 1,
    cast[int](garbage) * 2,
    cast[int](red) * 3,
    cast[int](green) * 4,
    cast[int](blue) * 5,
    cast[int](yellow) * 6,
    cast[int](purple) * 7)
  
func `[]`*(field: Field, row: Row, col: Col): Cell {.inline.} =
  toCell(
    field.hard[row, col],
    field.garbage[row, col],
    field.red[row, col],
    field.green[row, col],
    field.blue[row, col],
    field.yellow[row, col],
    field.purple[row, col])

func toValues(cell: Cell): (bool, bool, bool, bool, bool, bool, bool) {.inline.} =
  ## Converts the cell to the values for sub-fields.
  let c = cast[int](cell)
  return (c == 1, c == 2, c == 3, c == 4, c == 5, c == 6, c == 7)

func `[]=`*(field: var Field, row: Row, col: Col, cell: Cell) {.inline.} =
  let (hard, garbage, red, green, blue, yellow, purple) = cell.toValues
  field.hard[row, col] = hard
  field.garbage[row, col] = garbage
  field.red[row, col] = red
  field.green[row, col] = green
  field.blue[row, col] = blue
  field.yellow[row, col] = yellow
  field.purple[row, col] = purple

func insert*(field: var Field, row: Row, col: Col, cell: Cell) {.inline.} =
  ## Inserts the value and shifts the field up above where the value inserted.
  let (hard, garbage, red, green, blue, yellow, purple) = cell.toValues
  field.hard.insert row, col, hard
  field.garbage.insert row, col, garbage
  field.red.insert row, col, red
  field.green.insert row, col, green
  field.blue.insert row, col, blue
  field.yellow.insert row, col, yellow
  field.purple.insert row, col, purple

func removeSqueeze*(field: var Field, row: Row, col: Col) {.inline.} =
  ## Removes the value and shifts the field down above where the value removed.
  field.hard.removeSqueeze row, col
  field.garbage.removeSqueeze row, col
  field.red.removeSqueeze row, col
  field.green.removeSqueeze row, col
  field.blue.removeSqueeze row, col
  field.yellow.removeSqueeze row, col
  field.purple.removeSqueeze row, col

func colorNum*(field: Field, puyo: ColorPuyo): int {.inline.} =
  ## Returns the number of the given puyoes in the field.
  case puyo
  of RED:
    field.red.popcnt
  of GREEN:
    field.green.popcnt
  of BLUE:
    field.blue.popcnt
  of YELLOW:
    field.yellow.popcnt
  of PURPLE:
    field.purple.popcnt

func colorNum*(field: Field): int {.inline.} =
  ## Returns the number of color puyoes in the field.
  field.red.popcnt + field.green.popcnt + field.blue.popcnt + field.yellow.popcnt + field.purple.popcnt

func garbageNum*(field: Field): int {.inline.} =
  ## Returns the number of hard and garbage puyoes in the field.
  field.hard.popcnt + field.garbage.popcnt

func puyoNum*(field: Field): int {.inline.} =
  ## Returns the number of puyoes in the field.
  field.colorNum + field.garbageNum

func shiftedUp*(field: Field): Field {.inline.} =
  ## Returns a field shifted up.
  result.hard = field.hard.shiftedUp
  result.garbage = field.garbage.shiftedUp
  result.red = field.red.shiftedUp
  result.green = field.green.shiftedUp
  result.blue = field.blue.shiftedUp
  result.yellow = field.yellow.shiftedUp
  result.purple = field.purple.shiftedUp

func shiftedDown*(field: Field): Field {.inline.} =
  ## Returns a field shifted down.
  result.hard = field.hard.shiftedDown
  result.garbage = field.garbage.shiftedDown
  result.red = field.red.shiftedDown
  result.green = field.green.shiftedDown
  result.blue = field.blue.shiftedDown
  result.yellow = field.yellow.shiftedDown
  result.purple = field.purple.shiftedDown

func shiftedRight*(field: Field): Field {.inline.} =
  ## Returns a field shifted right.
  result.hard = field.hard.shiftedRight
  result.garbage = field.garbage.shiftedRight
  result.red = field.red.shiftedRight
  result.green = field.green.shiftedRight
  result.blue = field.blue.shiftedRight
  result.yellow = field.yellow.shiftedRight
  result.purple = field.purple.shiftedRight

func shiftedLeft*(field: Field): Field {.inline.} =
  ## Returns a field shifted left.
  result.hard = field.hard.shiftedLeft
  result.garbage = field.garbage.shiftedLeft
  result.red = field.red.shiftedLeft
  result.green = field.green.shiftedLeft
  result.blue = field.blue.shiftedLeft
  result.yellow = field.yellow.shiftedLeft
  result.purple = field.purple.shiftedLeft

func disappearCore(
  field: var Field,
): (BinaryField, BinaryField, BinaryField, BinaryField, BinaryField, BinaryField, BinaryField) {.inline.} =
  ## Removes puyoes that should disappear.
  let
    red = field.red.disappeared
    green = field.green.disappeared
    blue = field.blue.disappeared
    yellow = field.yellow.disappeared
    purple = field.purple.disappeared

    color = (red + green + blue) + (yellow + purple)
    garbage = color.expanded * field.garbage

  field.garbage -= garbage
  field.red -= red
  field.green -= green
  field.blue -= blue
  field.yellow -= yellow
  field.purple -= purple

  return (red, green, blue, yellow, purple, garbage, color)

func disappear*(field: var Field) {.inline.} =
  ## Removes puyoes that should disappear.
  discard field.disappearCore

func willDisappear*(field: Field): bool {.inline.} =
  ## Returns whether any four or more values are connected or not.
  cast[bool](bitor(
    cast[int](field.red.willDisappear),
    cast[int](field.green.willDisappear),
    cast[int](field.blue.willDisappear),
    cast[int](field.yellow.willDisappear),
    cast[int](field.purple.willDisappear)))

func exist(field: Field): BinaryField {.inline.} =
  ## Returns where any puyoes exist.
  (field.hard + field.garbage) + (field.red + field.green + field.blue) + (field.yellow + field.purple)

func fall*(field: var Field) {.inline.} =
  ## Drops floating puyoes.
  let existMask = field.exist + floorBinaryField()

  field.hard.fall existMask
  field.garbage.fall existMask
  field.red.fall existMask
  field.green.fall existMask
  field.blue.fall existMask
  field.yellow.fall existMask
  field.purple.fall existMask

func put*(field: var Field, pair: Pair, pos: Position) {.inline.} =
  ## Puts the pair.
  const
    AxisLiftPositions = {POS_1D, POS_2D, POS_3D, POS_4D, POS_5D, POS_6D}
    ChildLiftPositions = {POS_1U, POS_2U, POS_3U, POS_4U, POS_5U, POS_6U}

  let
    existMask = field.exist
    next = existMask xor (existMask + floorBinaryField()).shiftedUp

  when defined(js):
    # NOTE: somehow we cannot use the bool array and cast operator with JS backend
    let
      nexts = [next, next.shiftedUp] 
      axisMask = nexts[(pos in AxisLiftPositions).int].column(pos.axisCol)
      childMask = nexts[(pos in ChildLiftPositions).int].column(pos.childCol)
  else:
    let
      nexts = [false: next, true: next.shiftedUp] 
      axisMask = nexts[pos in AxisLiftPositions].column(pos.axisCol)
      childMask = nexts[pos in ChildLiftPositions].column(pos.childCol)

  let
    (_, _, redAxis, greenAxis, blueAxis, yellowAxis, purpleAxis) = pair.axis.toValues
    (_, _, redChild, greenChild, blueChild, yellowChild, purpleChild) = pair.child.toValues

  field.red += axisMask * redAxis.filled + childMask * redChild.filled
  field.green += axisMask * greenAxis.filled + childMask * greenChild.filled
  field.blue += axisMask * blueAxis.filled + childMask * blueChild.filled
  field.yellow += axisMask * yellowAxis.filled + childMask * yellowChild.filled
  field.purple += axisMask * purpleAxis.filled + childMask * purpleChild.filled

func move*(field: var Field, pair: Pair, pos: Position): MoveResult {.inline, discardable.} =
  ## Puts the pair and starts the chain until it ends.
  ## This function tracks the number of chains.
  field.put pair, pos

  while true:
    if field.disappearCore[6].isZero:
      return

    field.fall

    result.chainNum.inc

func calcDisappearNums(red, green, blue, yellow, purple, garbage: BinaryField): array[Puyo, Natural] {.inline.} =
  ## Returns the numbers of disappeared puyoes.
  result[HARD] = 0
  result[GARBAGE] = garbage.popcnt
  result[RED] = red.popcnt
  result[GREEN] = green.popcnt
  result[BLUE] = blue.popcnt
  result[YELLOW] = yellow.popcnt
  result[PURPLE] = purple.popcnt

func moveWithRoughTracking*(field: var Field, pair: Pair, pos: Position): MoveResult {.inline.} =
  ## Puts the pair and starts the chain until it ends.
  ## Compared to :code:`move`, this function additionally tracks the total number of disappeared puyoes.
  field.put pair, pos

  var totalDisappearNums: array[Puyo, Natural]
  while true:
    let (red, green, blue, yellow, purple, garbage, color) = field.disappearCore
    if color.isZero:
      result.totalDisappearNums = some totalDisappearNums
      return 

    field.fall

    result.chainNum.inc

    for puyo, num in calcDisappearNums(red, green, blue, yellow, purple, garbage):
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
    let (red, green, blue, yellow, purple, garbage, color) = field.disappearCore
    if color.isZero:
      result.totalDisappearNums = some totalDisappearNums
      result.disappearNums = some disappearNumsSeq
      return 

    field.fall

    result.chainNum.inc

    let disappearNums = calcDisappearNums(red, green, blue, yellow, purple, garbage)
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
    let (red, green, blue, yellow, purple, garbage, color) = field.disappearCore
    if color.isZero:
      result.totalDisappearNums = some totalDisappearNums
      result.disappearNums = some disappearNumsSeq
      result.detailedDisappearNums = some detailedDisappearNums
      return 

    field.fall

    result.chainNum.inc

    let disappearNums = calcDisappearNums(red, green, blue, yellow, purple, garbage)
    for puyo, num in disappearNums:
      totalDisappearNums[puyo].inc num
    disappearNumsSeq.add disappearNums

    let
      garbageDetail = garbage.connectionDetail
      redDetail = red.connectionDetail
      greenDetail = green.connectionDetail
      blueDetail = blue.connectionDetail
      yellowDetail = yellow.connectionDetail
      purpleDetail = purple.connectionDetail
    detailedDisappearNums.add [
      newSeq[Natural] 0,
      garbageDetail,
      redDetail,
      greenDetail,
      blueDetail,
      yellowDetail,
      purpleDetail,
    ]

func connect3*(field: Field): Field {.inline.} =
  ## Returns where three color puyoes are connected.
  ## This function ignores ghost puyoes.
  result.red = field.red.connect3
  result.green = field.green.connect3
  result.blue = field.blue.connect3
  result.yellow = field.yellow.connect3
  result.purple = field.purple.connect3

func connect3V*(field: Field): Field {.inline.} =
  ## Returns where three color puyoes are connected vertically.
  ## This function ignores ghost puyoes.
  result.red = field.red.connect3V
  result.green = field.green.connect3V
  result.blue = field.blue.connect3V
  result.yellow = field.yellow.connect3V
  result.purple = field.purple.connect3V

func connect3H*(field: Field): Field {.inline.} =
  ## Returns where three color puyoes are connected horizontally.
  ## This function ignores ghost puyoes.
  result.red = field.red.connect3H
  result.green = field.green.connect3H
  result.blue = field.blue.connect3H
  result.yellow = field.yellow.connect3H
  result.purple = field.purple.connect3H

func connect3L*(field: Field): Field {.inline.} =
  ## Returns where three color puyoes are connected by L-shape.
  ## This function ignores ghost puyoes.
  result.red = field.red.connect3L
  result.green = field.green.connect3L
  result.blue = field.blue.connect3L
  result.yellow = field.yellow.connect3L
  result.purple = field.purple.connect3L

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
    hard = field.hard.toArray
    garbage = field.garbage.toArray
    red = field.red.toArray
    green = field.green.toArray
    blue = field.blue.toArray
    yellow = field.yellow.toArray
    purple = field.purple.toArray

  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      result[row][col] = toCell(
        hard[row][col],
        garbage[row][col],
        red[row][col],
        green[row][col],
        blue[row][col],
        yellow[row][col],
        purple[row][col])

func toField*(`array`: array[Row, array[Col, Cell]]): Field {.inline.} =
  ## Converts the array to a field.
  var hardArray, garbageArray, redArray, greenArray, blueArray, yellowArray, purpleArray: array[Row, array[Col, bool]]
  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      let (hard, garbage, red, green, blue, yellow, purple) = `array`[row][col].toValues
      hardArray[row][col] = hard
      garbageArray[row][col] = garbage
      redArray[row][col] = red
      greenArray[row][col] = green
      blueArray[row][col] = blue
      yellowArray[row][col] = yellow
      purpleArray[row][col] = purple

  result.hard = hardArray.toBinaryField
  result.garbage = garbageArray.toBinaryField
  result.red = redArray.toBinaryField
  result.green = greenArray.toBinaryField
  result.blue = blueArray.toBinaryField
  result.yellow = yellowArray.toBinaryField
  result.purple = purpleArray.toBinaryField
