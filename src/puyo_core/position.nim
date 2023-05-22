## This module implements positions.
## A "position" means a location where a pair is put.
##

import options
import sugar
import tables

import ./common

type
  Direction* {.pure.} = enum ## The direction where the child-puyo is when viewed from the axis-puyo.
    UP = "^"
    RIGHT = ">"
    DOWN = "v"
    LEFT = "<"

  Position* {.pure.} = enum
    POS_1U = '1' & $UP
    POS_2U = '2' & $UP
    POS_3U = '3' & $UP
    POS_4U = '4' & $UP
    POS_5U = '5' & $UP
    POS_6U = '6' & $UP

    POS_1R = '1' & $RIGHT
    POS_2R = '2' & $RIGHT
    POS_3R = '3' & $RIGHT
    POS_4R = '4' & $RIGHT
    POS_5R = '5' & $RIGHT

    POS_1D = '1' & $DOWN
    POS_2D = '2' & $DOWN
    POS_3D = '3' & $DOWN
    POS_4D = '4' & $DOWN
    POS_5D = '5' & $DOWN
    POS_6D = '6' & $DOWN

    POS_2L = '2' & $LEFT
    POS_3L = '3' & $LEFT
    POS_4L = '4' & $LEFT
    POS_5L = '5' & $LEFT
    POS_6L = '6' & $LEFT

  Positions* = seq[Option[Position]]

const DoublePositions* = {POS_1U .. POS_5R} ## The position for a double pair, excluding duplicates.

func axisCol*(pos: Position): int {.inline.} =
  ## Gets the column of the axis-puyo.
  const PosToCol: array[Position, int] = [
    1, 2, 3, 4, 5, 6,
    1, 2, 3, 4, 5,
    1, 2, 3, 4, 5, 6,
    2, 3, 4, 5, 6,
  ]

  return PosToCol[pos]

func childCol*(pos: Position): int {.inline.} =
  ## Gets the column of the child-puyo.
  const PosToCol: array[Position, int] = [
    1, 2, 3, 4, 5, 6,
    2, 3, 4, 5, 6,
    1, 2, 3, 4, 5, 6,
    1, 2, 3, 4, 5,
  ]

  return PosToCol[pos]

func childDir*(pos: Position): Direction {.inline.} =
  ## Gets the direction of the child-puyo.
  const PosToDir: array[Position, Direction] = [
    UP, UP, UP, UP, UP, UP,
    RIGHT, RIGHT, RIGHT, RIGHT, RIGHT,
    DOWN, DOWN, DOWN, DOWN, DOWN, DOWN,
    LEFT, LEFT, LEFT, LEFT, LEFT,
  ]

  return PosToDir[pos]

func shiftedRight*(pos: Position): Position {.inline.} =
  ## Returns a position shifted right.
  const Results: array[Position, Position] = [
    POS_2U, POS_3U, POS_4U, POS_5U, POS_6U, POS_6U,
    POS_2R, POS_3R, POS_4R, POS_5R, POS_5R,
    POS_2D, POS_3D, POS_4D, POS_5D, POS_6D, POS_6D,
    POS_3L, POS_4L, POS_5L, POS_6L, POS_6L,
  ]

  return Results[pos]

func shiftedLeft*(pos: Position): Position {.inline.} =
  ## Returns a position shifted left.
  const Results: array[Position, Position] = [
    POS_1U, POS_1U, POS_2U, POS_3U, POS_4U, POS_5U,
    POS_1R, POS_1R, POS_2R, POS_3R, POS_4R,
    POS_1D, POS_1D, POS_2D, POS_3D, POS_4D, POS_5D,
    POS_2L, POS_2L, POS_3L, POS_4L, POS_5L,
  ]

  return Results[pos]

func rotatedRight*(pos: Position): Position {.inline.} =
  ## Returns a position rotated right.
  const Results: array[Position, Position] = [
    POS_1R, POS_2R, POS_3R, POS_4R, POS_5R, POS_5R,
    POS_1D, POS_2D, POS_3D, POS_4D, POS_5D,
    POS_2L, POS_2L, POS_3L, POS_4L, POS_5L, POS_6L,
    POS_2U, POS_3U, POS_4U, POS_5U, POS_6U,
  ]

  return Results[pos]

func rotatedLeft*(pos: Position): Position {.inline.} =
  ## Returns a position rotated left.
  const Results: array[Position, Position] = [
    POS_2L, POS_2L, POS_3L, POS_4L, POS_5L, POS_6L,
    POS_1U, POS_2U, POS_3U, POS_4U, POS_5U,
    POS_1R, POS_2R, POS_3R, POS_4R, POS_5R, POS_5R,
    POS_2D, POS_3D, POS_4D, POS_5D, POS_6D,
  ]

  return Results[pos]

func shiftRight*(pos: var Position) {.inline.} =
  ## Shifts the position right.
  pos = pos.shiftedRight

func shiftLeft*(pos: var Position) {.inline.} =
  ## Shifts the position left.
  pos = pos.shiftedLeft

func rotateRight*(pos: var Position) {.inline.} =
  ## Rotates the position right.
  pos = pos.rotatedRight

func rotateLeft*(pos: var Position) {.inline.} =
  ## Rotates the position left.
  pos = pos.rotatedLeft

func makePosition*(axisCol: Col, childDir: Direction): Position {.inline.} =
  ## Returns a position with the given column and direction.
  const
    StartPositions: array[Direction, Position] = [POS_1U, POS_1R, POS_1D, POS_2L]
    StartColumns: array[Direction, Col] = [1.Col, 1.Col, 1.Col, 2.Col]

  return StartPositions[childDir].succ axisCol - StartColumns[childDir]

const
  PosToUrl = "02468acegikoqsuwyCEGIK"
  NoPosUrl = "1"

func toUrl*(pos: Option[Position]): string {.inline.} =
  ## Converts the position to a url.
  return if pos.isSome: $PosToUrl[pos.get.ord - Position.low.ord] else: NoPosUrl

func toPosition*(str: string, url: bool): Option[Option[Position]] {.inline.} =
  ## Converts the string to a position.
  ## If the conversion fails, returns none.
  const
    StrToPos = collect:
      for pos in Position:
        {$pos: some some pos}
    UrlToPos = collect:
      for i, url in PosToUrl:
        {$url: some some Position.low.succ i}

  if url:
    return if str == NoPosUrl: return Position.none.some else: UrlToPos.getOrDefault str
  else:
    return StrToPos.getOrDefault str
