## The :code:`puyo_core` module implements `Puyo Puyo <https://puyo.sega.jp/>`_.
## With :code:`import puyo_core`, you can use all features provided by this module.
## Documentations for each features are:
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
  env.colorNum,
  env.garbageNum,
  env.puyoNum,
  env.addPair,
  env.reset,
  env.makeEnv,
  env.move,
  env.moveWithRoughTracking,
  env.moveWithDetailedTracking,
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
  field.puyoNum,
  field.shiftedUp,
  field.shiftedDown,
  field.shiftedRight,
  field.shiftedLeft,
  field.shiftUp,
  field.shiftDown,
  field.shiftRight,
  field.shiftLeft,
  field.connect3,
  field.connect3V,
  field.connect3H,
  field.connect3L,
  field.invalidPositions,
  field.validPositions,
  field.validDoublePositions,
  field.isDead,
  field.put,
  field.disappear,
  field.willDisappear,
  field.fall,
  field.move,
  field.moveWithRoughTracking,
  field.moveWithDetailedTracking,
  field.moveWithFullTracking,
  field.toArray,
  field.toField,
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
  pair.axis,
  pair.child,
  pair.makePair,
  pair.`axis=`,
  pair.`child=`,
  pair.isDouble,
  pair.swapped,
  pair.swap,
  pair.colorNum,
  pair.toStr,
  pair.toUrl,
  pair.toPairPosition,
  pair.toPair,
  pair.toArray,
  pair.`$`,
  pair.`==`,
  pair.toPairsPositions,
  pair.toPairs

import ./puyo_core/position
export
  position.Direction,
  position.Position,
  position.Positions,
  position.DoublePositions,
  position.axisCol,
  position.childCol,
  position.childDir,
  position.shiftedRight,
  position.shiftedLeft,
  position.rotatedRight,
  position.rotatedLeft,
  position.shiftRight,
  position.shiftLeft,
  position.rotateRight,
  position.rotateLeft,
  position.makePosition,
  position.toUrl,
  position.toPosition
