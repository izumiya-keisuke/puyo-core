## This module implements the position.
## Position means the location where a pair is put.
##

import options
import sugar
import tables

import ./common

type
  Direction* {.pure.} = enum
    ## The direction of the child-puyo from the axis-puyo.
    UP = "^"
    RIGHT = ">"
    DOWN = "v"
    LEFT = "<"

  Position* {.pure.} = enum
    ## The location where a pair is put.
    ## :code:`POS_<col><dir>` means that the column where the axis-puyo is :code:`<col>` and
    ## the direction of the child puyo is :code:`<dir>`.
    POS_1U = "1" & $UP
    POS_2U = "2" & $UP
    POS_3U = "3" & $UP
    POS_4U = "4" & $UP
    POS_5U = "5" & $UP
    POS_6U = "6" & $UP

    POS_1R = "1" & $RIGHT
    POS_2R = "2" & $RIGHT
    POS_3R = "3" & $RIGHT
    POS_4R = "4" & $RIGHT
    POS_5R = "5" & $RIGHT

    POS_1D = "1" & $DOWN
    POS_2D = "2" & $DOWN
    POS_3D = "3" & $DOWN
    POS_4D = "4" & $DOWN
    POS_5D = "5" & $DOWN
    POS_6D = "6" & $DOWN

    POS_2L = "2" & $LEFT
    POS_3L = "3" & $LEFT
    POS_4L = "4" & $LEFT
    POS_5L = "5" & $LEFT
    POS_6L = "6" & $LEFT

  Positions* = seq[Option[Position]] ## The position sequence. :code:`none(Position)` means that no position is given.

const DoublePositions* = {POS_1U .. POS_5R} ## All positions for the double pair; excluding duplicates.

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func makePosition*(axisCol: Col, childDir: Direction): Position {.inline.} =
  ## Returns the position determined from the axis-puyo column :code:`axisCol` and the child-puyo direction
  ## :code:`childDir`.
  const
    StartPositions: array[Direction, Position] = [POS_1U, POS_1R, POS_1D, POS_2L]
    StartColumns: array[Direction, Col] = [1.Col, 1.Col, 1.Col, 2.Col]

  return StartPositions[childDir].succ axisCol - StartColumns[childDir]

# ------------------------------------------------
# Property
# ------------------------------------------------

func axisCol*(pos: Position): Col {.inline.} =
  ## Returns the column of the axis-puyo.
  const PositionToAxisColumn: array[Position, Col] = [
    1.Col, 2, 3, 4, 5, 6,
    1, 2, 3, 4, 5,
    1, 2, 3, 4, 5, 6,
    2, 3, 4, 5, 6]

  return PositionToAxisColumn[pos]

func childCol*(pos: Position): Col {.inline.} =
  ## Returns the column of the child-puyo.
  const PositionToChildColumn: array[Position, Col] = [
    1.Col, 2, 3, 4, 5, 6,
    2, 3, 4, 5, 6,
    1, 2, 3, 4, 5, 6,
    1, 2, 3, 4, 5]

  return PositionToChildColumn[pos]

func childDir*(pos: Position): Direction {.inline.} =
  ## Returns the direction of the child-puyo.
  const PositionToChildDirection: array[Position, Direction] = [
    UP, UP, UP, UP, UP, UP,
    RIGHT, RIGHT, RIGHT, RIGHT, RIGHT,
    DOWN, DOWN, DOWN, DOWN, DOWN, DOWN,
    LEFT, LEFT, LEFT, LEFT, LEFT]

  return PositionToChildDirection[pos]

# ------------------------------------------------
# Move
# ------------------------------------------------

func movedRight*(pos: Position): Position {.inline.} =
  ## Returns the position obtained by applying a right move to :code:`pos`.
  const RightPositions: array[Position, Position] = [
    POS_2U, POS_3U, POS_4U, POS_5U, POS_6U, POS_6U,
    POS_2R, POS_3R, POS_4R, POS_5R, POS_5R,
    POS_2D, POS_3D, POS_4D, POS_5D, POS_6D, POS_6D,
    POS_3L, POS_4L, POS_5L, POS_6L, POS_6L]

  return RightPositions[pos]

func movedLeft*(pos: Position): Position {.inline.} =
  ## Returns the position obtained by applying a left move to :code:`pos`.
  const LeftPositions: array[Position, Position] = [
    POS_1U, POS_1U, POS_2U, POS_3U, POS_4U, POS_5U,
    POS_1R, POS_1R, POS_2R, POS_3R, POS_4R,
    POS_1D, POS_1D, POS_2D, POS_3D, POS_4D, POS_5D,
    POS_2L, POS_2L, POS_3L, POS_4L, POS_5L]

  return LeftPositions[pos]

func moveRight*(pos: var Position) {.inline.} =
  ## Applies rightward move to :code:`pos`.
  pos = pos.movedRight

func moveLeft*(pos: var Position) {.inline.} =
  ## Applies leftward move to :code:`pos`.
  pos = pos.movedLeft

# ------------------------------------------------
# Rotate
# ------------------------------------------------

func rotatedRight*(pos: Position): Position {.inline.} =
  ## Returns the position obtained by applying a right (clockwise) rotation to :code:`pos`.
  const RightRotatePositions: array[Position, Position] = [
    POS_1R, POS_2R, POS_3R, POS_4R, POS_5R, POS_5R,
    POS_1D, POS_2D, POS_3D, POS_4D, POS_5D,
    POS_2L, POS_2L, POS_3L, POS_4L, POS_5L, POS_6L,
    POS_2U, POS_3U, POS_4U, POS_5U, POS_6U]

  return RightRotatePositions[pos]

func rotatedLeft*(pos: Position): Position {.inline.} =
  ## Returns the position obtained by applying a left (counterclockwise) rotation to :code:`pos`.
  const LeftRotatePositions: array[Position, Position] = [
    POS_2L, POS_2L, POS_3L, POS_4L, POS_5L, POS_6L,
    POS_1U, POS_2U, POS_3U, POS_4U, POS_5U,
    POS_1R, POS_2R, POS_3R, POS_4R, POS_5R, POS_5R,
    POS_2D, POS_3D, POS_4D, POS_5D, POS_6D]

  return LeftRotatePositions[pos]

func rotateRight*(pos: var Position) {.inline.} =
  ## Applies right (clockwise) rotation to :code:`pos`.
  pos = pos.rotatedRight

func rotateLeft*(pos: var Position) {.inline.} =
  ## Applies left (counterclockwise) rotation to :code:`pos`.
  pos = pos.rotatedLeft

# ------------------------------------------------
# Position <-> string
# ------------------------------------------------

const
  PositionToUrl = "02468acegikoqsuwyCEGIK"
  NoPositionUrl = "1" ## URL character corresponding to no position

func toUrl*(pos: Option[Position]): string {.inline.} =
  ## Converts :code:`pos` to the URL.
  if pos.isSome: $PositionToUrl[pos.get.ord - Position.low.ord] else: NoPositionUrl

func toPosition*(str: string, url: bool): Option[Option[Position]] {.inline.} =
  ## Converts :code:`str` to the position.
  ## The string representation or URL is acceptable as :code:`str`,
  ## and which type of input is specified by the :code:`url`.
  ## If the conversion fails, returns :code:`none(Option[Position])`.
  ## :code:`some(none(Position))` means that no position is given.
  runnableExamples:
    import options

    assert "4<".toPosition(false) == some POS_4L.some
    assert "1".toPosition(true) == some Position.none
    assert "xx".toPosition(false) == none Option[Position]

  const
    StringToPosition = collect:
      for pos in Position:
        {$pos: some pos.some}
    UrlToPosition = collect:
      for i, url in PositionToUrl:
        {$url: some (Position.low.succ i).some}

  if url:
    return if str == NoPositionUrl: some Position.none else: UrlToPosition.getOrDefault str
  else:
    return StringToPosition.getOrDefault str
