## The :code:`puyo_core` module implements `Puyo Puyo <https://puyo.sega.jp/>`_.
## With :code:`import puyo_core`, you can use all features provided by this module.
## Documentations:
## * `Cell <./puyo_core/cell.html>`_
## * `Common <./puyo_core/common.html>`_
## * `Environment <./puyo_core/env.html>`_
## * `Field <./puyo_core/field.html>`_
## * `MoveResult <./puyo_core/moveResult.html>`_
## * `Pair <./puyo_core/pair.html>`_
## * `Position <./puyo_core/position.html>`_
##
## This module uses BMI2 and AVX2 by default.
## To prevent their use, specify :code:`-d:bmi2=false` or :code:`-d:avx2=false` to the compile options.
##

import ./puyo_core/cell
export cell.Cell, cell.ColorPuyo, cell.Puyo, cell.toCell

import ./puyo_core/common
export common.Row, common.Col, common.Height, common.Width

import ./puyo_core/env
export
  env.Env,
  env.UrlDomain,
  env.UrlMode,
  env.addPair,
  env.reset,
  env.makeEnv,
  env.colorNum,
  env.garbageNum,
  env.puyoNum,
  env.move,
  env.moveWithRoughTracking,
  env.moveWithDetailTracking,
  env.moveWithFullTracking,
  env.`$`,
  env.toStr,
  env.toUrl,
  env.toEnvPositions,
  env.toEnv,
  env.toArrays

import ./puyo_core/field
export
  field.Field,
  field.zeroField,
  field.`==`,
  field.`[]`,
  field.`[]=`,
  field.insert,
  field.removeSqueeze,
  field.colorNum,
  field.garbageNum,
  field.connect3,
  field.connect3V,
  field.connect3H,
  field.connect3L,
  field.shiftedUp,
  field.shiftedDown,
  field.shiftedRight,
  field.shiftedLeft,
  field.disappear,
  field.willDisappear,
  field.put,
  field.drop,
  field.toArray,
  field.toField,
  field.isDead,
  field.puyoNum,
  field.invalidPositions,
  field.validPositions,
  field.validDoublePositions,
  field.shiftUp,
  field.shiftDown,
  field.shiftRight,
  field.shiftLeft,
  field.move,
  field.moveWithRoughTracking,
  field.moveWithDetailTracking,
  field.moveWithFullTracking,
  field.`$`,
  field.toUrl

import ./puyo_core/moveResult
export
  moveResult.MoveResult,
  moveResult.puyoNum,
  moveResult.colorNum,
  moveResult.puyoNums,
  moveResult.colorNums,
  moveResult.score

import ./puyo_core/pair
export
  pair.Pair,
  pair.Pairs,
  pair.makePair,
  pair.axis,
  pair.child,
  pair.`axis=`,
  pair.`child=`,
  pair.isDouble,
  pair.`==`,
  pair.swapped,
  pair.swap,
  pair.colorNum,
  pair.`$`,
  pair.toStr,
  pair.toUrl,
  pair.toPairPosition,
  pair.toPairsPositions,
  pair.toPair,
  pair.toPairs,
  pair.toArray

import ./puyo_core/position
export
  position.Direction,
  position.Position,
  position.Positions,
  position.DoublePositions,
  position.makePosition,
  position.axisCol,
  position.childCol,
  position.childDir,
  position.movedRight,
  position.movedLeft,
  position.moveRight,
  position.moveLeft,
  position.rotatedRight,
  position.rotatedLeft,
  position.rotateRight,
  position.rotateLeft,
  position.toUrl,
  position.toPosition
