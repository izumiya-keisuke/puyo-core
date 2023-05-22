import strutils
import unittest

import nimsimd/avx2 as nimavx2

import ../../src/puyo_core/intrinsic {.all.}

proc main* =
  # pext
  block:
    check 0b0100_1011'u32.pext(0b1101_0010'u32) == 0b0000_0101'u32
    check 0b0100_1011'u64.pext(0b1101_0010'u64) == 0b0000_0101'u64

  # `$`
  when UseAvx2:
    check $mm256_set_epi64x(7, 8, 9, 10) == $[7.toHex, 8.toHex, 9.toHex, 10.toHex]
