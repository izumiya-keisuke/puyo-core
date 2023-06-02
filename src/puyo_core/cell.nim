## This module implements the cell.
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

# ------------------------------------------------
# Cell <-> string
# ------------------------------------------------

func toCell*(str: string): Option[Cell] {.inline.} =
  ## Converts :code:`str` to the cell.
  ## If the conversion fails, returns :code:`none(Cell)`.
  const StrToCell = collect:
    for cell in Cell:
      {$cell: cell.some}

  return StrToCell.getOrDefault str
