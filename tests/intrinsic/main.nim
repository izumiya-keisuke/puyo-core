import unittest

import ../../src/puyo_core/private/intrinsic {.all.}

proc main* =
  # ------------------------------------------------
  # BMI2
  # ------------------------------------------------

  # pext
  block:
    #check 0b0100_1011'u32.pext(0b1101_0010'u32) == 0b0000_0101'u32
    check 0b0100_1011'u64.pext(0b1101_0010'u64) == 0b0000_0101'u64
