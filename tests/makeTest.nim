import algorithm
import os
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

  let
    matrixSeq = collect:
      for values in product([Bmi2Seq, Avx2Seq, MmSeq]):
        let
          useBmi2 = values[0]
          useAvx2 = values[1]
          mmKind = values[2]

        &"-d:bmi2={useBmi2} -d:avx2={useAvx2} --mm:{mmKind}"
    content = FileContent.replace(Matrix, matrixSeq.join "; ")

  for categoryDir in (currentSourcePath().parentDir / "*").walkDirs:
    let f = (categoryDir / "test.nim").open fmWrite
    defer: f.close

    f.write content
