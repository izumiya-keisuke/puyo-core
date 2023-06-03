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
  bit2: BinaryField
  bit1: BinaryField
  bit0: BinaryField

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func zeroField*: Field {.inline.} =
  ## Returns the field with all elements zero.
  result.bit2 = ZeroBinaryField
  result.bit1 = ZeroBinaryField
  result.bit0 = ZeroBinaryField

# ------------------------------------------------
# Property
# ------------------------------------------------

func exist*(field: Field): BinaryField {.inline.} =
  ## Returns the binary field where any puyo exists.
  sum(field.bit2, field.bit1, field.bit0)

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(field1, field2: Field): bool {.inline.} =
  bool bitand(
    int (field1.bit2 == field2.bit2),
    int (field1.bit1 == field2.bit1),
    int (field1.bit0 == field2.bit0))

func `+`(field1, field2: Field): Field {.inline.} =
  result.bit2 = field1.bit2 + field2.bit2
  result.bit1 = field1.bit1 + field2.bit1
  result.bit0 = field1.bit0 + field2.bit0

func `*`(field: Field, binaryField: BinaryField): Field {.inline.} =
  result.bit2 = field.bit2 * binaryField
  result.bit1 = field.bit1 * binaryField
  result.bit0 = field.bit0 * binaryField

func `+=`(field1: var Field, field2: Field) {.inline.} =
  field1.bit2 += field2.bit2
  field1.bit1 += field2.bit1
  field1.bit0 += field2.bit0

func `-=`(field1: var Field, field2: BinaryField) {.inline.} =
  field1.bit2 -= field2
  field1.bit1 -= field2
  field1.bit0 -= field2

# ------------------------------------------------
# Indexer
# ------------------------------------------------

func toCell(bit2, bit1, bit0: bool): Cell {.inline.} =
  ## Converts the bits to the cell.
  Cell.low.succ bit2.int * 4 + bit1.int * 2 + bit0.int
  
func `[]`*(field: Field, row: Row, col: Col): Cell {.inline.} =
  toCell(field.bit2[row, col], field.bit1[row, col], field.bit0[row, col])

func toBits(cell: Cell): tuple[bit2: bool, bit1: bool, bit0: bool] {.inline.} =
  ## Returns each bit of the :code:`cell`.
  let c = cell.int
  result.bit2 = c.testBit 2
  result.bit1 = c.testBit 1
  result.bit0 = c.testBit 0

func `[]=`*(field: var Field, row: Row, col: Col, cell: Cell) {.inline.} =
  let bits = cell.toBits
  field.bit2[row, col] = bits.bit2
  field.bit1[row, col] = bits.bit1
  field.bit0[row, col] = bits.bit0

func insert*(field: var Field, row: Row, col: Col, cell: Cell) {.inline.} =
  ## Inserts :code:`cell` and shift :code:`field` upward above the location where :code:`cell` is inserted.
  let bits = cell.toBits
  field.bit2.insert row, col, bits.bit2
  field.bit1.insert row, col, bits.bit1
  field.bit0.insert row, col, bits.bit0

func removeSqueeze*(field: var Field, row: Row, col: Col) {.inline.} =
  ## Removes the cell at :code:`(row, col)` and shift :code:`field` downward above the location where the cell is
  ## removed.
  field.bit2.removeSqueeze row, col
  field.bit1.removeSqueeze row, col
  field.bit0.removeSqueeze row, col

# ------------------------------------------------
# Puyo Extract
# ------------------------------------------------

func garbage(field: Field): BinaryField {.inline.} =
  ## Returns the binary field where garbage puyoes exist.
  field.bit1 - (field.bit2 + field.bit0)

func red(field: Field): BinaryField {.inline.} =
  ## Returns the binary field where red puyoes exist.
  field.bit1 * field.bit0 - field.bit2

func green(field: Field): BinaryField {.inline.} =
  ## Returns the binary field where green puyoes exist.
  field.bit2 - (field.bit1 + field.bit0)

func blue(field: Field): BinaryField {.inline.} =
  ## Returns the binary field where blue puyoes exist.
  field.bit2 * field.bit0 - field.bit1

func yellow(field: Field): BinaryField {.inline.} =
  ## Returns the binary field where yellow puyoes exist.
  field.bit2 * field.bit1 - field.bit0

func purple(field: Field): BinaryField {.inline.} =
  ## Returns the binary field where purple puyoes exist.
  prod(field.bit2, field.bit1, field.bit0)

# ------------------------------------------------
# Number
# ------------------------------------------------

func colorNum*(field: Field, puyo: ColorPuyo): int {.inline.} =
  ## Returns the number of :code:`puyo` in the :code:`field`.
  popcnt case puyo
  of RED:
    field.red
  of GREEN:
    field.green
  of BLUE:
    field.blue
  of YELLOW:
    field.yellow
  of PURPLE:
    field.purple

func colorNum*(field: Field): int {.inline.} =
  ## Returns the number of color puyoes in the :code:`field`.
  (field.bit2 + field.red).popcnt

func garbageNum*(field: Field): int {.inline.} =
  ## Returns the number of hard and garbage puyoes in the :code:`field`.
  popcnt (field.bit0 xor field.bit1) - field.bit2

func puyoNum*(field: Field): int {.inline.} =
  ## Returns the number of puyoes in the :code:`field`.
  field.exist.popcnt

# ------------------------------------------------
# Connect
# ------------------------------------------------

func connect3*(field: Field): Field {.inline.} =
  ## Returns the field with only the locations where exactly three color puyoes are connected.
  ## This function ignores ghost puyoes.
  field * sum(
    field.red.connect3,
    field.green.connect3,
    field.blue.connect3,
    field.yellow.connect3,
    field.purple.connect3)

func connect3V*(field: Field): Field {.inline.} =
  ## Returns the field with only the locations where exactly three color puyoes are connected vertically.
  ## This function ignores ghost puyoes.
  field * sum(
    field.red.connect3V,
    field.green.connect3V,
    field.blue.connect3V,
    field.yellow.connect3V,
    field.purple.connect3V)

func connect3H*(field: Field): Field {.inline.} =
  ## Returns the field with only the locations where exactly three color puyoes are connected horizontally.
  ## This function ignores ghost puyoes.
  field * sum(
    field.red.connect3H,
    field.green.connect3H,
    field.blue.connect3H,
    field.yellow.connect3H,
    field.purple.connect3H)

func connect3L*(field: Field): Field {.inline.} =
  ## Returns the field with only the locations where exactly three color puyoes are connected by L-shape.
  ## This function ignores ghost puyoes.
  field * sum(
    field.red.connect3L,
    field.green.connect3L,
    field.blue.connect3L,
    field.yellow.connect3L,
    field.purple.connect3L)

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftedUp*(field: Field): Field {.inline.} =
  ## Returns the field shifted upward the :code:`field`.
  result.bit2 = field.bit2.shiftedUp
  result.bit1 = field.bit1.shiftedUp
  result.bit0 = field.bit0.shiftedUp

func shiftedDown*(field: Field): Field {.inline.} =
  ## Returns the field shifted downward the :code:`field`.
  result.bit2 = field.bit2.shiftedDown
  result.bit1 = field.bit1.shiftedDown
  result.bit0 = field.bit0.shiftedDown

func shiftedRight*(field: Field): Field {.inline.} =
  ## Returns the field shifted rightward the :code:`field`.
  result.bit2 = field.bit2.shiftedRight
  result.bit1 = field.bit1.shiftedRight
  result.bit0 = field.bit0.shiftedRight

func shiftedLeft*(field: Field): Field {.inline.} =
  ## Returns the field shifted leftward the :code:`field`.
  result.bit2 = field.bit2.shiftedLeft
  result.bit1 = field.bit1.shiftedLeft
  result.bit0 = field.bit0.shiftedLeft

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

  field -= result.color + result.garbage

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
    Field (bit2: ZeroBinaryField, bit1: OneBinaryField, bit0: OneBinaryField),
    Field (bit2: OneBinaryField, bit1: ZeroBinaryField, bit0: ZeroBinaryField),
    Field (bit2: OneBinaryField, bit1: ZeroBinaryField, bit0: OneBinaryField),
    Field (bit2: OneBinaryField, bit1: OneBinaryField, bit0: ZeroBinaryField),
    Field (bit2: OneBinaryField, bit1: OneBinaryField, bit0: OneBinaryField)]

  let
    existField = field.exist
    nextPutMask = existField xor (existField + FloorBinaryField).shiftedUp
    nextPutMasks = [nextPutMask, nextPutMask.shiftedUp] # NOTE: array[bool, T] is not allowd with JS backend
    axisMask = nextPutMasks[int pos in {POS_1D, POS_2D, POS_3D, POS_4D, POS_5D, POS_6D}].column pos.axisCol
    childMask = nextPutMasks[int pos in {POS_1U, POS_2U, POS_3U, POS_4U, POS_5U, POS_6U}].column pos.childCol

  field += FillFields[pair.axis] * axisMask + FillFields[pair.child] * childMask

func drop*(field: var Field) {.inline.} =
  ## Drops floating puyoes.
  let mask = field.exist.toDropMask

  field.bit2.drop mask
  field.bit1.drop mask
  field.bit0.drop mask

# ------------------------------------------------
# Field <-> array
# ------------------------------------------------

func toArray*(field: Field): array[Row, array[Col, Cell]] {.inline.} =
  ## Converts :code:`field` to the array.
  let
    array2 = field.bit2.toArray
    array1 = field.bit1.toArray
    array0 = field.bit0.toArray

  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      result[row][col] = toCell(array2[row][col], array1[row][col], array0[row][col])

func toField*(fieldArray: array[Row, array[Col, Cell]]): Field {.inline.} =
  ## Converts :code:`fieldArray` to the field.
  var array2, array1, array0: array[Row, array[Col, bool]]
  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      let (bit2, bit1, bit0) = fieldArray[row][col].toBits
      array2[row][col] = bit2
      array1[row][col] = bit1
      array0[row][col] = bit0

  result.bit2 = array2.toBinaryField
  result.bit1 = array1.toBinaryField
  result.bit0 = array0.toBinaryField
