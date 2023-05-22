## This module implements intrinsic functions.
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

  func pext*[T: uint32 | uint64](a, mask: T): T {.inline.} =
    ## Parallel bits extract.
    # TODO: make faster
    var
      m = mask
      digit = 1.T
    while m != 0:
      if bitand(a, m, m.bitnot.succ) != 0:
        result = result or digit

      m = m and m.pred
      digit = digit shl 1

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
