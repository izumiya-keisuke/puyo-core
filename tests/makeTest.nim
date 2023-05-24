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
    TripleQuote = "\"\"\""
    Matrix = "<MATRIX>"
    FileContent = &"""
discard {TripleQuote}
  action: "run"
  targets: "c cpp js"
  matrix: "{Matrix}"
{TripleQuote}

import ./main

main()
"""

    Values = [OFF: @["false"], ON: @["true"], BOTH: @["true", "false"]]
    Bmi2Seq = Values[bmi2]
    Avx2Seq = Values[avx2]

    MmSeq = @["refc", "orc", "arc"]

    AlternativeValues = [@["altSingleColor"]]
    DefineConvert = (s: seq[string]) => s.mapIt(if it == "": it else: &"-d:{it}")
    Convert = (s: seq[seq[string]]) => s.mapIt it.DefineConvert.join " "
    CompareSeq =
      if AlternativeValues.len == 0: @[""]
      else:
        case alt
        of OFF:
          @[""]
        of ON:
          if AlternativeValues.len == 1: AlternativeValues[0]
          else: AlternativeValues.product.Convert
        of BOTH:
          if AlternativeValues.len == 1: (AlternativeValues[0] & @[""]).DefineConvert
          else: AlternativeValues.mapIt(it & @[""]).product.Convert

  let
    matrixSeq = collect:
      for values in product([Bmi2Seq, Avx2Seq, MmSeq, CompareSeq]):
        let
          useBmi2 = values[0]
          useAvx2 = values[1]
          mmKind = values[2]
          compareStr = values[3]

        &"-d:bmi2={useBmi2} -d:avx2={useAvx2} --mm:{mmKind} {compareStr}"
    content = FileContent.replace(Matrix, matrixSeq.join "; ")

  for categoryDir in (currentSourcePath().parentDir / "*").walkDirs:
    let f = (categoryDir / "test.nim").open fmWrite
    defer: f.close

    f.write content
