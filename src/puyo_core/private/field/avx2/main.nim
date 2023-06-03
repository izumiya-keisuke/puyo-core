## This module provides a low-level implementation of the field.
##

import bitops

import ./binary
import ./disappearResult
import ../binary as commonBinary
import ../../../cell
import ../../../common
import ../../../pair
import ../../../position

type Field* = tuple
  ## Puyo Puyo field.
  hardGarbage: BinaryField
  noneRed: BinaryField
  greenBlue: BinaryField
  yellowPurple: BinaryField

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func zeroField*: Field {.inline.} =
  ## Returns the field with all elements zero.
  result.hardGarbage = zeroBinaryField()
  result.noneRed = zeroBinaryField()
  result.greenBlue = zeroBinaryField()
  result.yellowPurple = zeroBinaryField()

# ------------------------------------------------
# Property
# ------------------------------------------------

func exist*(field: Field): BinaryField {.inline.} =
  ## Returns the binary field where any puyo exists.
  sum(field.hardGarbage, field.noneRed, field.greenBlue, field.yellowPurple).exist

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(field1, field2: Field): bool {.inline.} =
  bool bitand(
    int (field1.hardGarbage == field2.hardGarbage),
    int (field1.noneRed == field2.noneRed),
    int (field1.greenBlue == field2.greenBlue),
    int (field1.yellowPurple == field2.yellowPurple))
  
# ------------------------------------------------
# Indexer
# ------------------------------------------------

func toCell(hardGarbage, noneRed, greenBlue, yellowPurple: WhichColor): Cell {.inline.} =
  ## Converts the values to the cell.
  return Cell bitor(
    bitor(hardGarbage.color1, hardGarbage.color2 shl 1),
    bitor(noneRed.color2, noneRed.color2 shl 1),
    bitor(greenBlue.color1 shl 2, greenBlue.color2 shl 2, greenBlue.color2),
    bitor(
      yellowPurple.color1 shl 2,
      yellowPurple.color2.shl 2,
      yellowPurple.color1 shl 1,
      yellowPurple.color2 shl 1,
      yellowPurple.color2))

func `[]`*(field: Field, row: Row, col: Col): Cell {.inline.} =
  return toCell(
    field.hardGarbage[row, col],
    field.noneRed[row, col],
    field.greenBlue[row, col],
    field.yellowPurple[row, col])

func toWhichColor(cell: Cell): tuple[
  hardGarbage: WhichColor, noneRed: WhichColor, greenBlue: WhichColor, yellowPurple: WhichColor
] {.inline.} =
  ## Converts the cell to the values.
  let
    c = cell.int64
    bit2 = (c and 4) shr 2
    bit1 = (c and 2) shr 1
    bit0 = c and 1
    notBit2 = not bit2
    notBit1 = not bit1
    notBit0 = not bit0

  result.hardGarbage = (color1: bitand(notBit2, notBit1, bit0), color2: bitand(notBit2, bit1, notBit0))
  result.noneRed = (color1: 0'i64, color2: bitand(notBit2, bit1, bit0))
  result.greenBlue = (color1: bitand(bit2, notBit1, notBit0), color2: bitand(bit2, notBit1, bit0))
  result.yellowPurple = (color1: bitand(bit2, bit1, notBit0), color2: bitand(bit2, bit1, bit0))

func `[]=`*(field: var Field, row: Row, col: Col, cell: Cell) {.inline.} =
  let (hardGarbage, noneRed, greenBlue, yellowPurple) = cell.toWhichColor
  field.hardGarbage[row, col] = hardGarbage
  field.noneRed[row, col] = noneRed
  field.greenBlue[row, col] = greenBlue
  field.yellowPurple[row, col] = yellowPurple

func insert*(field: var Field, row: Row, col: Col, cell: Cell) {.inline.} =
  ## Inserts :code:`cell` and shift :code:`field` upward above the location where :code:`cell` is inserted.
  let (hardGarbage, noneRed, greenBlue, yellowPurple) = cell.toWhichColor
  field.hardGarbage.insert row, col, hardGarbage
  field.noneRed.insert row, col, noneRed
  field.greenBlue.insert row, col, greenBlue
  field.yellowPurple.insert row, col, yellowPurple

func removeSqueeze*(field: var Field, row: Row, col: Col) {.inline.} =
  ## Removes the cell at :code:`(row, col)` and shift :code:`field` downward above the location where the cell is
  ## removed.
  field.hardGarbage.removeSqueeze row, col
  field.noneRed.removeSqueeze row, col
  field.greenBlue.removeSqueeze row, col
  field.yellowPurple.removeSqueeze row, col

# ------------------------------------------------
# Number
# ------------------------------------------------

func colorNum*(field: Field, puyo: ColorPuyo): int {.inline.} =
  ## Returns the number of :code:`puyo` in the :code:`field`.
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
  ## Returns the number of color puyoes in the :code:`field`.
  sum(field.noneRed, field.greenBlue, field.yellowPurple).popcnt

func garbageNum*(field: Field): int {.inline.} =
  ## Returns the number of hard and garbage puyoes in the :code:`field`.
  field.hardGarbage.popcnt

func puyoNum*(field: Field): int {.inline.} =
  ## Returns the number of puyoes in the :code:`field`.
  field.exist.popcnt shr 1

# ------------------------------------------------
# Connect
# ------------------------------------------------

func connect3*(field: Field): Field {.inline.} =
  ## Returns the field with only the locations where exactly three color puyoes are connected.
  ## This function ignores ghost puyoes.
  result.noneRed = field.noneRed.connect3
  result.greenBlue = field.greenBlue.connect3
  result.yellowPurple = field.yellowPurple.connect3

func connect3V*(field: Field): Field {.inline.} =
  ## Returns the field with only the locations where exactly three color puyoes are connected vertically.
  ## This function ignores ghost puyoes.
  result.noneRed = field.noneRed.connect3V
  result.greenBlue = field.greenBlue.connect3V
  result.yellowPurple = field.yellowPurple.connect3V

func connect3H*(field: Field): Field {.inline.} =
  ## Returns the field with only the locations where exactly three color puyoes are connected horizontally.
  ## This function ignores ghost puyoes.
  result.noneRed = field.noneRed.connect3H
  result.greenBlue = field.greenBlue.connect3H
  result.yellowPurple = field.yellowPurple.connect3H

func connect3L*(field: Field): Field {.inline.} =
  ## Returns the field with only the locations where exactly three color puyoes are connected by L-shape.
  ## This function ignores ghost puyoes.
  result.noneRed = field.noneRed.connect3L
  result.greenBlue = field.greenBlue.connect3L
  result.yellowPurple = field.yellowPurple.connect3L

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftedUp*(field: Field): Field {.inline.} =
  ## Returns the field shifted upward the :code:`field`.
  result.hardGarbage = field.hardGarbage.shiftedUp
  result.noneRed = field.noneRed.shiftedUp
  result.greenBlue = field.greenBlue.shiftedUp
  result.yellowPurple = field.yellowPurple.shiftedUp

func shiftedDown*(field: Field): Field {.inline.} =
  ## Returns the field shifted downward the :code:`field`.
  result.hardGarbage = field.hardGarbage.shiftedDown
  result.noneRed = field.noneRed.shiftedDown
  result.greenBlue = field.greenBlue.shiftedDown
  result.yellowPurple = field.yellowPurple.shiftedDown

func shiftedRight*(field: Field): Field {.inline.} =
  ## Returns the field shifted rightward the :code:`field`.
  result.hardGarbage = field.hardGarbage.shiftedRight
  result.noneRed = field.noneRed.shiftedRight
  result.greenBlue = field.greenBlue.shiftedRight
  result.yellowPurple = field.yellowPurple.shiftedRight

func shiftedLeft*(field: Field): Field {.inline.} =
  ## Returns the field shifted leftward the :code:`field`.
  result.hardGarbage = field.hardGarbage.shiftedLeft
  result.noneRed = field.noneRed.shiftedLeft
  result.greenBlue = field.greenBlue.shiftedLeft
  result.yellowPurple = field.yellowPurple.shiftedLeft

# ------------------------------------------------
# Disappear
# ------------------------------------------------

func disappear*(field: var Field): DisappearResult {.inline, discardable.} =
  ## Removes puyoes that should disappear.
  result.red = field.noneRed.disappeared
  result.greenBlue = field.greenBlue.disappeared
  result.yellowPurple = field.yellowPurple.disappeared

  result.color = sum(result.red, result.greenBlue, result.yellowPurple).exist
  result.garbage = result.color.expanded * field.hardGarbage

  field.hardGarbage -= result.garbage
  field.noneRed -= result.red
  field.greenBlue -= result.greenBlue
  field.yellowPurple -= result.yellowPurple

func willDisappear*(field: Field): bool {.inline.} =
  ## Returns :code:`true` if any puyoes will disappear.
  field.greenBlue.willDisappear or
  field.yellowPurple.willDisappear or
  field.noneRed.willDisappear

# ------------------------------------------------
# Operation
# ------------------------------------------------

func put*(field: var Field, pair: Pair, pos: Position) {.inline.} =
  ## Puts the :code:`pair`.
  let
    existField = field.exist
    nextPutMask = existField xor (existField + floorBinaryField()).shiftedUp
    nextPutMasks = [nextPutMask, nextPutMask.shiftedUp]
    axisMask = nextPutMasks[int pos in {POS_1D, POS_2D, POS_3D, POS_4D, POS_5D, POS_6D}].column pos.axisCol
    childMask = nextPutMasks[int pos in {POS_1U, POS_2U, POS_3U, POS_4U, POS_5U, POS_6U}].column pos.childCol

    axisWhich = pair.axis.toWhichColor
    childWhich = pair.child.toWhichColor

  field.noneRed += axisMask * axisWhich.noneRed.filled + childMask * childWhich.noneRed.filled
  field.greenBlue += axisMask * axisWhich.greenBlue.filled + childMask * childWhich.greenBlue.filled
  field.yellowPurple += axisMask * axisWhich.yellowPurple.filled + childMask * childWhich.yellowPurple.filled

func drop*(field: var Field) {.inline.} =
  ## Drops floating puyoes.
  let mask = field.exist.toDropMask

  field.hardGarbage.drop mask
  field.noneRed.drop mask
  field.greenBlue.drop mask
  field.yellowPurple.drop mask

# ------------------------------------------------
# Field <-> array
# ------------------------------------------------

func toArray*(field: Field): array[Row, array[Col, Cell]] {.inline.} =
  ## Converts :code:`field` to the array.
  let
    hardGarbage = field.hardGarbage.toArray
    noneRed = field.noneRed.toArray
    greenBlue = field.greenBlue.toArray
    yellowPurple = field.yellowPurple.toArray

  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      result[row][col] = toCell(hardGarbage[row][col], noneRed[row][col], greenBlue[row][col], yellowPurple[row][col])

func toField*(fieldArray: array[Row, array[Col, Cell]]): Field {.inline.} =
  ## Converts :code:`fieldArray` to the field.
  var hardGarbageArray, noneRedArray, greenBlueArray, yellowPurpleArray: array[Row, array[Col, WhichColor]]
  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      let (hardGarbage, noneRed, greenBlue, yellowPurple) = fieldArray[row][col].toWhichColor
      hardGarbageArray[row][col] = hardGarbage
      noneRedArray[row][col] = noneRed
      greenBlueArray[row][col] = greenBlue
      yellowPurpleArray[row][col] = yellowPurple

  result.hardGarbage = hardGarbageArray.toBinaryField
  result.noneRed = noneRedArray.toBinaryField
  result.greenBlue = greenBlueArray.toBinaryField
  result.yellowPurple = yellowPurpleArray.toBinaryField
