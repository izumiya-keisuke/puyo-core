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

# ------------------------------------------------
# BMI2
# ------------------------------------------------

when UseBmi2:
  when defined(gcc):
    {.passc: "-mbmi2".}
    {.passl: "-mbmi2".}

  func pext*(a, mask: uint64): uint64 {.header: "<immintrin.h>", importc: "_pext_u64".} ## Parallel bits extract.
  func pext*(a, mask: uint32): uint32 {.header: "<immintrin.h>", importc: "_pext_u32".} ## Parallel bits extract.
  func pext*(a, mask: uint16): uint16 {.inline.} = uint16 a.uint32.pext mask.uint32 ## Parallel bits extract.
else:
  import bitops

  const
    BitNum64 = 6
    BitNum32 = 5
    BitNum16 = 4

  type PextMask*[T: uint64 or uint32 or uint16] = tuple
    ## Mask used in :code:`pext`.
    mask: T
    bits: array[BitNum64, T] # FIXME: somehow when statement does not work on array's index

  func toPextMask*[T: uint64 or uint32 or uint16](mask: T): PextMask[T] {.inline.} =
    ## Converts :code:`mask` to the pext mask.
    when T is uint64:
      const BitNum = BitNum64
      type SignedT = int64
    elif T is uint32:
      const BitNum = BitNum32
      type SignedT = int32
    else:
      const BitNum = BitNum16
      type SignedT = int16

    result.mask = mask

    var lastMask = cast[SignedT](mask.bitnot)
    for i in 0 ..< BitNum.pred:
      var bit = lastMask shl 1
      for j in 0 ..< BitNum:
        bit = bit xor (bit shl (1 shl j))

      result.bits[i] = cast[T](bit)
      lastMask = lastMask and bit

    result.bits[^1] = cast[T](-lastMask shl 1)

  func pext*[T: uint64 or uint32 or uint16](a: T, masks: PextMask[T]): T {.inline.} =
    ## Parallel bits extract.
    const BitNum = when T is uint64: BitNum64 elif T is uint32: BitNum32 else: BitNum16

    result = a and masks.mask

    for i in 0 ..< BitNum:
      let bit = masks.bits[i]
      result = (result and bit.bitnot) or ((result and bit) shr (1 shl i))

  func pext*[T: uint64 or uint32 or uint16](a, mask: T): T {.inline.} =
    ## Parallel bits extract.
    a.pext mask.toPextMask

# ------------------------------------------------
# AVX2
# ------------------------------------------------

when UseAvx2:
  when defined(gcc):
    {.passc: "-mavx2".}
    {.passl: "-mavx2".}
