## This module implements cells.
## A "cell" means a single puyo or a blank.
##

import options
import sugar
import tables

type
  Cell* {.pure.} = enum
    NONE = "."
    HARD = "h"
    GARBAGE = "o"
    RED = "r"
    GREEN = "g"
    BLUE = "b"
    YELLOW = "y"
    PURPLE = "p"

  ColorPuyo* = range[RED .. PURPLE]
  Puyo* = range[HARD .. PURPLE]

func toCell*(str: string): Option[Cell] {.inline.} =
  ## Converts the string to a cell.
  ## If the conversion fails, returns none.
  const StrToCell = collect:
    for cell in Cell:
      {$cell: cell.some}

  return StrToCell.getOrDefault str
