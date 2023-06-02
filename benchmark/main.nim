import math
import options
import std/monotimes
import sugar
import times

import ../src/puyo_core/cell
import ../src/puyo_core/common
import ../src/puyo_core/env as envLib
import ../src/puyo_core/field as fieldLib
import ../src/puyo_core/pair
import ../src/puyo_core/position

template benchmark(fn: () -> Duration, loop = 1.Positive) =
  let durations = collect:
    for _ in 0 ..< loop:
      fn()

  echo fn.astToStr, ": ", durations.sum div loop

template core(duration: var Duration, body: untyped) =
  let t1 = getMonoTime()
  body
  let t2 = getMonoTime()

  duration += t2 - t1

proc indexSetter: Duration =
  var field = zeroField()
  for row in Row.low .. Row.high:
    for col in Col.low .. Col.high:
      core result:
        field[row, col] = RED

proc put: Duration =
  var field = zeroField()
  let positions: array[Col, Position] = [POS_1U, POS_2U, POS_3U, POS_4U, POS_5U, POS_6U]
  for _ in 0 ..< 6:
    for col in Col.low .. Col.high:
      let pos = positions[col]
      core result:
        field.put RG, pos

let env = """
by.yrr
gb.gry
rbgyyr
gbgyry
ryrgby
yrgbry
ryrgbr
ryrgbr
rggbyb
gybgbb
rgybgy
rgybgy
rgybgy
======
bg""".toEnv(false).get

proc disappear: Duration =
  var field = zeroField()
  field[5, 4] = RED
  field[5, 5] = RED
  field[5, 5] = RED
  field[6, 4] = RED
  core result:
    field.disappear

proc drop: Duration =
  var field = zeroField()
  field[2, 3] = RED
  core result:
    field.drop

proc move: Duration =
  var env2 = env
  core result:
    env2.move(POS_3U, false)

proc moveWithRoughTracking: Duration =
  var env2 = env
  core result:
    discard env2.moveWithRoughTracking(POS_3U, false)

proc moveWithDetailTracking: Duration =
  var env2 = env
  core result:
    discard env2.moveWithDetailTracking(POS_3U, false)

proc moveWithFullTracking: Duration =
  var env2 = env
  core result:
    discard env2.moveWithFullTracking(POS_3U, false)

when isMainModule:
  benchmark indexSetter, 10 ^ 3
  benchmark put, 10 ^ 3
  benchmark disappear, 10 ^ 3
  benchmark drop, 10 ^ 3
  benchmark move, 10 ^ 3
  benchmark moveWithRoughTracking, 10 ^ 3
  benchmark moveWithDetailTracking, 10 ^ 3
  benchmark moveWithFullTracking, 10 ^ 3
