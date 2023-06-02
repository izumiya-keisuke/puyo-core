## This module implements common types and constants.
##

type
  Row* = range[1 .. 13] ## The top row is 1, the bottom one is 13.
  Col* = range[1 .. 6] ## The left column is 1, the right on is 6.

const
  Height* = Row.high - Row.low + 1 ## Height of the field, including ghost.
  Width* = Col.high - Col.low + 1 ## Width of the field.
