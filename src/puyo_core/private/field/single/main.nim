## This module implements a field using a bitboard.
##

import bitops
import options
import std/setutils

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
  bin2: BinaryField
  bin1: BinaryField
  bin0: BinaryField

func `==`*(field1: Field, field2: Field): bool {.inline.} =
  field1.bin2 == field2.bin2 and field1.bin1 == field2.bin1 and field1.bin0 == field2.bin0

func `+=`(field: var Field, other: Field) {.inline.} =
  field.bin2 += other.bin2
  field.bin1 += other.bin1
  field.bin0 += other.bin0

func `[]`*(field: Field, row: Row, col: Col): Cell {.inline.} =
  Cell.low.succ (field.bin2[row, col].int * 4 + field.bin1[row, col].int * 2 + field.bin0[row, col].int)

func `[]=`*(field: var Field, row: Row, col: Col, cell: Cell) {.inline.} =
  let val = cell.int
  field.bin2[row, col] = val.testBit 2
  field.bin1[row, col] = val.testBit 1
  field.bin0[row, col] = val.testBit 0

func insert*(field: var Field, row: Row, col: Col, cell: Cell) {.inline.} =
  ## Inserts a cell and shifts puyoes up above where inserted.
  let val = cell.int

  field.bin2.insert row, col, val.testBit 2
  field.bin2.trimField

  field.bin1.insert row, col, val.testBit 1
  field.bin1.trimField

  field.bin0.insert row, col, val.testBit 0
  field.bin0.trimField

func removeSqueeze*(field: var Field, row: Row, col: Col) {.inline.} =
  ## Removes a cell and shifts puyoes down above where removed.
  field.bin2.removeSqueeze row, col
  field.bin1.removeSqueeze row, col
  field.bin0.removeSqueeze row, col

func zeroField*: Field {.inline.} =
  ## Returns a field with all elements zero.
  (bin2: ZeroBinaryField, bin1: ZeroBinaryField, bin0: ZeroBinaryField)

# Cell extractors.
func extractHard(field: Field): BinaryField {.inline.} = field.bin0.clearMasked(field.bin2).clearMasked(field.bin1)
func extractGarbage(field: Field): BinaryField {.inline.} = field.bin1.clearMasked(field.bin2).clearMasked(field.bin0)
func extractRed(field: Field): BinaryField {.inline.} = field.bin1.clearMasked(field.bin2).masked(field.bin0)
func extractGreen(field: Field): BinaryField {.inline.} = field.bin2.clearMasked(field.bin1).clearMasked(field.bin0)
func extractBlue(field: Field): BinaryField {.inline.} = field.bin2.clearMasked(field.bin1).masked(field.bin0)
func extractYellow(field: Field): BinaryField {.inline.} = field.bin2.masked(field.bin1).clearMasked(field.bin0)
func extractPurple(field: Field): BinaryField {.inline.} = field.bin2.masked(field.bin1).masked(field.bin0)

func colorNum*(field: Field, puyo: ColorPuyo): int {.inline.} =
  ## Gets the total number of the specified color puyoes in the field.
  case puyo
  of RED:
    return field.extractRed.popcnt
  of GREEN:
    return field.extractGreen.popcnt
  of BLUE:
    return field.extractBlue.popcnt
  of YELLOW:
    return field.extractYellow.popcnt
  of PURPLE:
    return field.extractPurple.popcnt

func colorNum*(field: Field): int {.inline.} =
  ## Gets the total number of all color puyoes in the field.
  field.bin2.popcnt + field.extractRed.popcnt

func garbageNum*(field: Field): int {.inline.} =
  ## Gets the total number of garbage puyoes and hard puyoes in the field.
  field.extractGarbage.popcnt + field.extractHard.popcnt

func exist(field: Field): BinaryField {.inline.} =
  ## Gets where any puyo exists.
  add(field.bin2, field.bin1, field.bin0)

func puyoNum*(field: Field): int {.inline.} =
  ## Gets the total number of all puyoes in the field.
  field.exist.popcnt

func shiftedUp*(field: Field): Field {.inline.} =
  ## Returns a field shifted up.
  result.bin2 = field.bin2.shiftedUp.trimmedField
  result.bin1 = field.bin1.shiftedUp.trimmedField
  result.bin0 = field.bin0.shiftedUp.trimmedField

func shiftedDown*(field: Field): Field {.inline.} =
  ## Returns a field shifted down.
  result.bin2 = field.bin2.shiftedDown.trimmedField
  result.bin1 = field.bin1.shiftedDown.trimmedField
  result.bin0 = field.bin0.shiftedDown.trimmedField

func shiftedRight*(field: Field): Field {.inline.} =
  ## Returns a field shifted right.
  result.bin2 = field.bin2.shiftedRight.trimmedField
  result.bin1 = field.bin1.shiftedRight.trimmedField
  result.bin0 = field.bin0.shiftedRight.trimmedField

func shiftedLeft*(field: Field): Field {.inline.} =
  ## Returns a field shifted left.
  result.bin2 = field.bin2.shiftedLeft.trimmedField
  result.bin1 = field.bin1.shiftedLeft.trimmedField
  result.bin0 = field.bin0.shiftedLeft.trimmedField

func masked(field: Field, mask: BinaryField): Field {.inline.} =
  ## Returns where masked.
  result.bin2 = field.bin2.masked mask
  result.bin1 = field.bin1.masked mask
  result.bin0 = field.bin0.masked mask

func connect3*(field: Field): Field {.inline.} =
  ## Returns where three color puyoes are connected.
  ## This function ignores ghost puyoes.
  field.masked add(
    field.extractRed.connect3,
    field.extractGreen.connect3,
    field.extractBlue.connect3,
    field.extractYellow.connect3,
    field.extractPurple.connect3,
  )

func connect3V*(field: Field): Field {.inline.} =
  ## Returns where three color puyoes are connected vertically.
  ## This function ignores ghost puyoes.
  field.masked add(
    field.extractRed.connect3V,
    field.extractGreen.connect3V,
    field.extractBlue.connect3V,
    field.extractYellow.connect3V,
    field.extractPurple.connect3V,
  )

func connect3H*(field: Field): Field {.inline.} =
  ## Returns where three color puyoes are connected horizontally.
  ## This function ignores ghost puyoes.
  field.masked add(
    field.extractRed.connect3H,
    field.extractGreen.connect3H,
    field.extractBlue.connect3H,
    field.extractYellow.connect3H,
    field.extractPurple.connect3H,
  )

func connect3L*(field: Field): Field {.inline.} =
  ## Returns where three color puyoes are connected by L-shape.
  ## This function ignores ghost puyoes.
  field.masked add(
    field.extractRed.connect3L,
    field.extractGreen.connect3L,
    field.extractBlue.connect3L,
    field.extractYellow.connect3L,
    field.extractPurple.connect3L,
  )

func invalidPositions*(field: Field): set[Position] {.inline.} =
  ## Get positions that cannot be put in the field.
  const
    AllColumns = {Col.low .. Col.high}
    ExternalColsArray: array[Col, set[Col]] = [
      {1.Col}, {1.Col, 2.Col}, {}, {4.Col, 5.Col, 6.Col}, {5.Col, 6.Col}, {6.Col}
    ]
    LiftPositions: array[Col, Position] = [POS_1D, POS_2D, POS_3D, POS_4D, POS_5D, POS_6D]
    InvalidPositionsArray: array[Col, set[Position]] = [
      {POS_1U, POS_1R, POS_1D, POS_2L},
      {POS_2U, POS_2R, POS_2D, POS_2L, POS_1R, POS_3L},
      {POS_3U, POS_3R, POS_3D, POS_3L, POS_2R, POS_4L},
      {POS_4U, POS_4R, POS_4D, POS_4L, POS_3R, POS_5L},
      {POS_5U, POS_5R, POS_5D, POS_5L, POS_4R, POS_6L},
      {POS_6U, POS_6D, POS_6L, POS_5R},
    ]

  let exist = field.exist
  var usableColumns = AllColumns

  # If any puyo is in the 12th row, that column and the ones outside it cannot be used,
  # and the axis-puyo cannot lift at that column.
  for col in Col.low .. Col.high:
    if exist[2, col]:
      usableColumns = usableColumns - ExternalColsArray[col]
      result.incl LiftPositions[col]

  # If (1) there is a usable column with height 11, or (2) heights of the 2nd and 4th rows are both 12,
  # all columns are usable.
  for col in usableColumns:
    if exist[3, col] or (exist[2, 2] and exist[2, 4]):
      usableColumns = AllColumns
      break

  # If any puyo is in the 13th row, that column and the ones outside it cannot be used.
  for col in Col.low .. Col.high:
    if exist[1, col]:
      usableColumns = usableColumns - ExternalColsArray[col]

  for col in usableColumns.complement:
    result = result + InvalidPositionsArray[col]

func validPositions*(field: Field): set[Position] {.inline.} =
  ## Get positions that can be put in the field.
  field.invalidPositions.complement

func validDoublePositions*(field: Field): set[Position] {.inline.} =
  ## Get positions for a double pair that can be put in the field.
  return DoublePositions - field.invalidPositions

func isDead*(field: Field): bool {.inline.} =
  ## Returns whether the field is dead or not.
  field.exist[2, 3]

func put*(field: var Field, pair: Pair, pos: Position) {.inline.} =
  ## Puts the pair in the field.
  const
    ColorPuyoFields: array[ColorPuyo, Field] = [
      (bin2: ZeroBinaryField, bin1: OneBinaryField, bin0: OneBinaryField),
      (bin2: OneBinaryField, bin1: ZeroBinaryField, bin0: ZeroBinaryField),
      (bin2: OneBinaryField, bin1: ZeroBinaryField, bin0: OneBinaryField),
      (bin2: OneBinaryField, bin1: OneBinaryField, bin0: ZeroBinaryField),
      (bin2: OneBinaryField, bin1: OneBinaryField, bin0: OneBinaryField),
    ]
    AxisLiftPositions = {POS_1D, POS_2D, POS_3D, POS_4D, POS_5D, POS_6D}
    ChildLiftPositions = {POS_1U, POS_2U, POS_3U, POS_4U, POS_5U, POS_6U}

  let
    exist = field.exist
    next = (exist xor (exist + FloorBinaryField).shiftedUp).trimmedField
    nexts = [next, next.shiftedUp]

  field += ColorPuyoFields[pair.axis].masked nexts[(pos in AxisLiftPositions).int].trimmedCol pos.axisCol
  field += ColorPuyoFields[pair.child].masked nexts[(pos in ChildLiftPositions).int].trimmedCol pos.childCol
  
func clearMask(field: var Field, mask: BinaryField) {.inline.} =
  ## Resets where masked.
  field.bin2.clearMask mask
  field.bin1.clearMask mask
  field.bin0.clearMask mask

func disappearCore(field: var Field): (
  BinaryField, BinaryField, BinaryField, BinaryField, BinaryField, BinaryField, BinaryField
) {.inline.} =
  ## Removes cells connected by four or more and returns where puyoes disappeared.
  let
    disappearRed = field.extractRed.disappeared
    disappearGreen = field.extractGreen.disappeared
    disappearBlue = field.extractBlue.disappeared
    disappearYellow = field.extractYellow.disappeared
    disappearPurple = field.extractPurple.disappeared

    disappearColor = add(disappearRed, disappearGreen, disappearBlue, disappearYellow, disappearPurple)
    disappearGarbage = disappearColor.expanded.masked field.extractGarbage.trimmedVisible

  field.clearMask disappearColor + disappearGarbage

  return (
    disappearRed, disappearGreen, disappearBlue, disappearYellow, disappearPurple, disappearGarbage, disappearColor
  )

func disappear*(field: var Field) {.inline.} =
  ## Removes cells connected by four or more.
  discard field.disappearCore

func willDisappear*(field: Field): bool {.inline.} =
  ## Returns whether any puyo will disappear.
  field.extractRed.willDisappear or
  field.extractGreen.willDisappear or
  field.extractBlue.willDisappear or
  field.extractYellow.willDisappear or
  field.extractPurple.willDisappear

func fall*(field: var Field) {.inline.} =
  ## Drops floating puyoes.
  let exist = field.exist
  field.bin2.fall exist
  field.bin1.fall exist
  field.bin0.fall exist

func move*(field: var Field, pair: Pair, pos: Position): MoveResult {.inline, discardable.} =
  ## Puts the pair and starts the chain until it ends.
  ## This function tracks the number of chains.
  field.put pair, pos

  while true:
    if field.disappearCore[6] == ZeroBinaryField:
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
    let (
      disappearRed, disappearGreen, disappearBlue, disappearYellow, disappearPurple, disappearGarbage, disappearColor
    ) = field.disappearCore
    if disappearColor == ZeroBinaryField:
      result.totalDisappearNums = totalDisappearNums.some
      return 

    field.fall

    result.chainNum.inc

    for puyo, num in calcDisappearNums(
      disappearRed, disappearGreen, disappearBlue, disappearYellow, disappearPurple, disappearGarbage
    ):
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
    let (
      disappearRed, disappearGreen, disappearBlue, disappearYellow, disappearPurple, disappearGarbage, disappearColor
    ) = field.disappearCore
    if disappearColor == ZeroBinaryField:
      result.totalDisappearNums = totalDisappearNums.some
      result.disappearNums = disappearNumsSeq.some
      return 

    field.fall

    result.chainNum.inc

    let disappearNums = calcDisappearNums(
      disappearRed, disappearGreen, disappearBlue, disappearYellow, disappearPurple, disappearGarbage
    )
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
    let (
      disappearRed, disappearGreen, disappearBlue, disappearYellow, disappearPurple, disappearGarbage, disappearColor
    ) = field.disappearCore
    if disappearColor == ZeroBinaryField:
      result.totalDisappearNums = totalDisappearNums.some
      result.disappearNums = disappearNumsSeq.some
      result.detailedDisappearNums = detailedDisappearNums.some
      return 

    field.fall

    result.chainNum.inc

    let disappearNums = calcDisappearNums(
      disappearRed, disappearGreen, disappearBlue, disappearYellow, disappearPurple, disappearGarbage
    )
    for puyo, num in disappearNums:
      totalDisappearNums[puyo].inc num
    disappearNumsSeq.add disappearNums

    detailedDisappearNums.add [
      newSeq[Natural] 0,
      disappearGarbage.connects,
      disappearRed.connects,
      disappearGreen.connects,
      disappearBlue.connects,
      disappearYellow.connects,
      disappearPurple.connects,
    ]

func toArray*(field: Field): array[Row, array[Col, Cell]] {.inline.} =
  ## Converts the field to an array.
  let
    array2 = field.bin2.toArray
    array1 = field.bin1.toArray
    array0 = field.bin0.toArray

  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      result[row][col] = Cell.low.succ 4 * array2[row][col].int + 2 * array1[row][col].int + array0[row][col].int

func toField*(`array`: array[Row, array[Col, Cell]]): Field {.inline.} =
  ## Converts the array to a field.
  var array2, array1, array0: array[Row, array[Col, bool]]
  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      let val = `array`[row][col].int
      array2[row][col] = val.testBit 2
      array1[row][col] = val.testBit 1
      array0[row][col] = val.testBit 0

  result.bin2 = array2.toBinaryField
  result.bin1 = array1.toBinaryField
  result.bin0 = array0.toBinaryField
