## This module implements intrinsic functions.
## 
## This module partly uses `zp7 <https://github.com/zwegner/zp7>`_, distributed under the MIT license.
## * Copyright (c) 2020 Zach Wegner
## * https://opensource.org/license/mit/
## 

const
  # TODO: detect automatically
  bmi2 {.booldefine.} = true
  avx2 {.booldefine.} = true

  UseBmi2* = bmi2 and not defined(arm) and not defined(js)
  UseAvx2* = avx2 and not defined(arm) and not defined(js)

# BMI2
when UseBmi2:
  when defined(gcc):
    {.passc: "-mbmi2".}
    {.passl: "-mbmi2".}

  ## Parallel bits extract.
  func pext*(a, mask: uint32): uint32 {.header: "<immintrin.h>", importc: "_pext_u32".}
  func pext*(a, mask: uint64): uint64 {.header: "<immintrin.h>", importc: "_pext_u64".}
else:
  import bitops

  const
    BitNum64 = 6
    BitNum32 = 5

  type Masks*[T: uint32 or uint64] = tuple
    mask: T
    bits: array[when T is uint32: BitNum32 else: BitNum64, T]

  func toMasks*[T: uint32 or uint64](mask: T): Masks[T] {.inline.} =
    ## Returns masks for pext.
    when T is uint32:
      const BitNum = BitNum32
      type SignedT = int32
    else:
      const BitNum = BitNum64
      type SignedT = int64

    result.mask = mask

    var lastMask = cast[SignedT](mask.bitnot)
    for i in 0 ..< BitNum.pred:
      var bit = lastMask shl 1
      for j in 0 ..< BitNum:
        bit = bit xor (bit shl (1 shl j))

      result.bits[i] = cast[T](bit)
      lastMask = lastMask and bit

    result.bits[^1] = cast[T](-lastMask shl 1)

  # TODO: use this function in fall
  func pext*[T: uint32 or uint64](a: T, masks: Masks[T]): T {.inline.} =
    ## Parallel bits extract.
    const BitNum = when T is uint32: BitNum32 else: BitNum64

    result = a and masks.mask

    for i in 0 ..< BitNum:
      let bit = masks.bits[i]
      result = (result and bit.bitnot) or ((result and bit) shr (1 shl i))

  func pext*[T: uint32 or uint64](a, mask: T): T {.inline.} =
    ## Parallel bits extract.
    a.pext mask.toMasks

# AVX2
when UseAvx2:
  when defined(gcc):
    {.passc: "-mavx2".}
    {.passl: "-mavx2".}

  import strutils

  import nimsimd/avx2 as nimavx2

  func `$`*(a: M256i): string {.inline.} =
    # NOTE: YMM[e3, e2, e1, e0] == array[e0, e1, e2, e3]
    let `array` = cast[array[4, uint64]](a)
    return $[`array`[3].toHex, `array`[2].toHex, `array`[1].toHex, `array`[0].toHex]
