## This module provides a low-level implementation of the field.
##

import bitops

import ./disappearResult

import ../binary as commonBinary
import ../../../cell
import ../../../common
import ../../../pair
import ../../../position

when defined(cpu32):
  import ./bit32/binary
else:
  import ./bit64/binary

type Field* = tuple
  ## Puyo Puyo field.
  hard: BinaryField
  garbage: BinaryField
  red: BinaryField
  green: BinaryField
  blue: BinaryField
  yellow: BinaryField
  purple: BinaryField

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func zeroField*: Field {.inline.} =
  ## Returns the field with all elements zero.
  result.hard = ZeroBinaryField
  result.garbage = ZeroBinaryField
  result.red = ZeroBinaryField
  result.green = ZeroBinaryField
  result.blue = ZeroBinaryField
  result.yellow = ZeroBinaryField
  result.purple = ZeroBinaryField

# ------------------------------------------------
# Property
# ------------------------------------------------

func exist*(field: Field): BinaryField {.inline.} =
  ## Returns the binary field where any puyo exists.
  sum(field.hard, field.garbage, field.red, field.green, field.blue, field.yellow, field.purple)

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(field1: Field, field2: Field): bool {.inline.} =
  bool bitand(
    int (field1.hard == field2.hard),
    int (field1.garbage == field2.garbage),
    int (field1.red == field2.red),
    int (field1.green == field2.green),
    int (field1.blue == field2.blue),
    int (field1.yellow == field2.yellow),
    int (field1.purple == field2.purple))

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func toCell(hard, garbage, red, green, blue, yellow, purple: bool): Cell {.inline.} =
  ## Converts the values to the cell.
  return Cell bitor(
    hard.int * 1,
    garbage.int * 2,
    red.int * 3,
    green.int * 4,
    blue.int * 5,
    yellow.int * 6,
    purple.int * 7)
  
func `[]`*(field: Field, row: Row, col: Col): Cell {.inline.} =
  toCell(
    field.hard[row, col],
    field.garbage[row, col],
    field.red[row, col],
    field.green[row, col],
    field.blue[row, col],
    field.yellow[row, col],
    field.purple[row, col])

func toValues(cell: Cell): tuple[
  hard: bool, garbage: bool, red: bool, green: bool, blue: bool, yellow: bool, purple: bool
] {.inline.} =
  ## Converts the cell to the values.
  result.hard = cell == HARD
  result.garbage = cell == GARBAGE
  result.red = cell == RED
  result.green = cell == GREEN
  result.blue = cell == BLUE
  result.yellow = cell == YELLOW
  result.purple = cell == PURPLE

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
  ## Inserts :code:`cell` and shift :code:`field` upward above the location where :code:`cell` is inserted.
  let (hard, garbage, red, green, blue, yellow, purple) = cell.toValues
  field.hard.insert row, col, hard
  field.garbage.insert row, col, garbage
  field.red.insert row, col, red
  field.green.insert row, col, green
  field.blue.insert row, col, blue
  field.yellow.insert row, col, yellow
  field.purple.insert row, col, purple

func removeSqueeze*(field: var Field, row: Row, col: Col) {.inline.} =
  ## Removes the cell at :code:`(row, col)` and shift :code:`field` downward above the location where the cell is
  ## removed.
  field.hard.removeSqueeze row, col
  field.garbage.removeSqueeze row, col
  field.red.removeSqueeze row, col
  field.green.removeSqueeze row, col
  field.blue.removeSqueeze row, col
  field.yellow.removeSqueeze row, col
  field.purple.removeSqueeze row, col

# ------------------------------------------------
# Number
# ------------------------------------------------

func colorNum*(field: Field, puyo: ColorPuyo): int {.inline.} =
  ## Returns the number of :code:`puyo` in the :code:`field`.
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
  ## Returns the number of color puyoes in the :code:`field`.
  sum(field.red, field.green, field.blue, field.yellow, field.purple).popcnt

func garbageNum*(field: Field): int {.inline.} =
  ## Returns the number of hard and garbage puyoes in the :code:`field`.
  (field.hard + field.garbage).popcnt

func puyoNum*(field: Field): int {.inline.} =
  ## Returns the number of puyoes in the :code:`field`.
  field.exist.popcnt

# ------------------------------------------------
# Connect
# ------------------------------------------------

func connect3*(field: Field): Field {.inline.} =
  ## Returns the field with only the locations where exactly three color puyoes are connected.
  ## This function ignores ghost puyoes.
  result.red = field.red.connect3
  result.green = field.green.connect3
  result.blue = field.blue.connect3
  result.yellow = field.yellow.connect3
  result.purple = field.purple.connect3

func connect3V*(field: Field): Field {.inline.} =
  ## Returns the field with only the locations where exactly three color puyoes are connected vertically.
  ## This function ignores ghost puyoes.
  result.red = field.red.connect3V
  result.green = field.green.connect3V
  result.blue = field.blue.connect3V
  result.yellow = field.yellow.connect3V
  result.purple = field.purple.connect3V

func connect3H*(field: Field): Field {.inline.} =
  ## Returns the field with only the locations where exactly three color puyoes are connected horizontally.
  ## This function ignores ghost puyoes.
  result.red = field.red.connect3H
  result.green = field.green.connect3H
  result.blue = field.blue.connect3H
  result.yellow = field.yellow.connect3H
  result.purple = field.purple.connect3H

func connect3L*(field: Field): Field {.inline.} =
  ## Returns the field with only the locations where exactly three color puyoes are connected by L-shape.
  ## This function ignores ghost puyoes.
  result.red = field.red.connect3L
  result.green = field.green.connect3L
  result.blue = field.blue.connect3L
  result.yellow = field.yellow.connect3L
  result.purple = field.purple.connect3L

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftedUp*(field: Field): Field {.inline.} =
  ## Returns the field shifted upward the :code:`field`.
  result.hard = field.hard.shiftedUp
  result.garbage = field.garbage.shiftedUp
  result.red = field.red.shiftedUp
  result.green = field.green.shiftedUp
  result.blue = field.blue.shiftedUp
  result.yellow = field.yellow.shiftedUp
  result.purple = field.purple.shiftedUp

func shiftedDown*(field: Field): Field {.inline.} =
  ## Returns the field shifted downward the :code:`field`.
  result.hard = field.hard.shiftedDown
  result.garbage = field.garbage.shiftedDown
  result.red = field.red.shiftedDown
  result.green = field.green.shiftedDown
  result.blue = field.blue.shiftedDown
  result.yellow = field.yellow.shiftedDown
  result.purple = field.purple.shiftedDown

func shiftedRight*(field: Field): Field {.inline.} =
  ## Returns the field shifted rightward the :code:`field`.
  result.hard = field.hard.shiftedRight
  result.garbage = field.garbage.shiftedRight
  result.red = field.red.shiftedRight
  result.green = field.green.shiftedRight
  result.blue = field.blue.shiftedRight
  result.yellow = field.yellow.shiftedRight
  result.purple = field.purple.shiftedRight

func shiftedLeft*(field: Field): Field {.inline.} =
  ## Returns the field shifted leftward the :code:`field`.
  result.hard = field.hard.shiftedLeft
  result.garbage = field.garbage.shiftedLeft
  result.red = field.red.shiftedLeft
  result.green = field.green.shiftedLeft
  result.blue = field.blue.shiftedLeft
  result.yellow = field.yellow.shiftedLeft
  result.purple = field.purple.shiftedLeft

# ------------------------------------------------
# Disappear
# ------------------------------------------------

func disappear*(field: var Field): DisappearResult {.inline, discardable.} =
  ## Removes puyoes that should disappear.
  result.red = field.red.disappeared
  result.green = field.green.disappeared
  result.blue = field.blue.disappeared
  result.yellow = field.yellow.disappeared
  result.purple = field.purple.disappeared

  result.color = sum(result.red, result.green, result.blue, result.yellow, result.purple)
  result.garbage = result.color.expanded * field.garbage

  field.garbage -= result.garbage
  field.red -= result.red
  field.green -= result.green
  field.blue -= result.blue
  field.yellow -= result.yellow
  field.purple -= result.purple

func willDisappear*(field: Field): bool {.inline.} =
  ## Returns :code:`true` if any puyoes will disappear.
  field.red.willDisappear or
  field.green.willDisappear or
  field.blue.willDisappear or
  field.yellow.willDisappear or
  field.purple.willDisappear

# ------------------------------------------------
# Operation
# ------------------------------------------------

func put*(field: var Field, pair: Pair, pos: Position) {.inline.} =
  ## Puts the :code:`pair`.
  const FillFields: array[ColorPuyo, Field] = [
    (hard: ZeroBinaryField, garbage: ZeroBinaryField, red: OneBinaryField, green: ZeroBinaryField,
    blue: ZeroBinaryField, yellow: ZeroBinaryField, purple: ZeroBinaryField),
    (hard: ZeroBinaryField, garbage: ZeroBinaryField, red: ZeroBinaryField, green: OneBinaryField,
    blue: ZeroBinaryField, yellow: ZeroBinaryField, purple: ZeroBinaryField),
    (hard: ZeroBinaryField, garbage: ZeroBinaryField, red: ZeroBinaryField, green: ZeroBinaryField,
    blue: OneBinaryField, yellow: ZeroBinaryField, purple: ZeroBinaryField),
    (hard: ZeroBinaryField, garbage: ZeroBinaryField, red: ZeroBinaryField, green: ZeroBinaryField,
    blue: ZeroBinaryField, yellow: OneBinaryField, purple: ZeroBinaryField),
    (hard: ZeroBinaryField, garbage: ZeroBinaryField, red: ZeroBinaryField, green: ZeroBinaryField,
    blue: ZeroBinaryField, yellow: ZeroBinaryField, purple: OneBinaryField)]

  let
    existField = field.exist
    nextPutMask = existField xor (existField + FloorBinaryField).shiftedUp
    nextPutMasks = [nextPutMask, nextPutMask.shiftedUp] # NOTE: array[bool, T] is not allowd with JS backend

    axisMask = nextPutMasks[int pos in {POS_1D, POS_2D, POS_3D, POS_4D, POS_5D, POS_6D}].column pos.axisCol
    childMask = nextPutMasks[int pos in {POS_1U, POS_2U, POS_3U, POS_4U, POS_5U, POS_6U}].column pos.childCol

    axisFill = FillFields[pair.axis]
    childFill = FillFields[pair.child]

  field.red += axisFill.red * axisMask + childFill.red * childMask
  field.green += axisFill.green * axisMask + childFill.green * childMask
  field.blue += axisFill.blue * axisMask + childFill.blue * childMask
  field.yellow += axisFill.yellow * axisMask + childFill.yellow * childMask
  field.purple += axisFill.purple * axisMask + childFill.purple * childMask

func drop*(field: var Field) {.inline.} =
  ## Drops floating puyoes.
  let mask = field.exist.toDropMask

  field.hard.drop mask
  field.garbage.drop mask
  field.red.drop mask
  field.green.drop mask
  field.blue.drop mask
  field.yellow.drop mask
  field.purple.drop mask

# ------------------------------------------------
# Field <-> array
# ------------------------------------------------

func toArray*(field: Field): array[Row, array[Col, Cell]] {.inline.} =
  ## Converts :code:`field` to the array.
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

func toField*(fieldArray: array[Row, array[Col, Cell]]): Field {.inline.} =
  ## Converts :code:`fieldArray` to the field.
  var
    hardArray: array[Row, array[Col, bool]]
    garbageArray: array[Row, array[Col, bool]]
    redArray: array[Row, array[Col, bool]]
    greenArray: array[Row, array[Col, bool]]
    blueArray: array[Row, array[Col, bool]]
    yellowArray: array[Row, array[Col, bool]]
    purpleArray: array[Row, array[Col, bool]]

  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      let (hard, garbage, red, green, blue, yellow, purple) = fieldArray[row][col].toValues
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
