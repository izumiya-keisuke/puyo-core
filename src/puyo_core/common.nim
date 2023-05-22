## This module implements common types and constants.
##

type
  Row* = range[1 .. 13]
  Col* = range[1 .. 6]

const
  Height* = Row.high - Row.low + 1
  Width* = Col.high - Col.low + 1
