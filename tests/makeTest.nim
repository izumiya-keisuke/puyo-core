import algorithm
import os
import sequtils
import strformat
import strutils
import sugar

type TestMode = enum
  OFF
  ON
  BOTH

const
  bmi2 {.intdefine.} = BOTH
  avx2 {.intdefine.} = BOTH
  alt {.intdefine.} = BOTH

when isMainModule:
  const
    # file content
    TripleQuote = "\"\"\""
    Matrix = "<MATRIX>"
    FileContentTemplate = &"""
discard {TripleQuote}
  action: "run"
  targets: "c cpp js"
  matrix: "{Matrix}"
{TripleQuote}

import ./main

main()
"""

    # boolean flags
    BoolValues = [OFF: @["false"], ON: @["true"], BOTH: @["true", "false"]]
    Bmi2Seq = BoolValues[bmi2]
    Avx2Seq = BoolValues[avx2]

    # alternative implementation flags
    AlternativeValues = [@["altPrimitiveColor"]]
    AddDefine = (s: seq[string]) => s.mapIt(if it == "": it else: &"-d:{it}")
    AlternativeSeq =
      if AlternativeValues.len == 0: @[""]
      else:
        case alt
        of OFF:
          @[""]
        of ON:
          if AlternativeValues.len == 1: AlternativeValues[0].AddDefine
          else: AlternativeValues.product.mapIt it.AddDefine.join " "
        of BOTH:
          if AlternativeValues.len == 1: (AlternativeValues[0] & @[""]).AddDefine
          else: AlternativeValues.mapIt(it & @[""]).product.mapIt it.AddDefine.join " "

    # memory management flags
    MmSeq = @["refc", "orc", "arc"]

  let
    matrixSeq = collect:
      for values in product([Bmi2Seq, Avx2Seq, AlternativeSeq, MmSeq]):
        &"-d:bmi2={values[0]} -d:avx2={values[1]} {values[2]} --mm:{values[3]}"
    fileContent = FileContentTemplate.replace(Matrix, matrixSeq.join "; ")

  for categoryDir in (currentSourcePath().parentDir / "*").walkDirs:
    let f = (categoryDir / "test.nim").open fmWrite
    defer: f.close

    f.write fileContent
