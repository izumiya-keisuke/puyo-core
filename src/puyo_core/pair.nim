## This modules implements a pair of puyoes.
## Out of the two puyoes, the one that is the axis of the rotation is "axis" puyo, and the other is "child" puyo.
##

import deques
import math
import options
import sequtils
import std/setutils
import strformat
import strutils
import sugar
import tables

import ./cell
import ./position

type
  Pair* {.pure.} = enum
    RR = $RED & $RED
    RG = $RED & $GREEN
    RB = $RED & $BLUE
    RY = $RED & $YELLOW
    RP = $RED & $PURPLE

    GR = $GREEN & $RED
    GG = $GREEN & $GREEN
    GB = $GREEN & $BLUE
    GY = $GREEN & $YELLOW
    GP = $GREEN & $PURPLE

    BR = $BLUE & $RED
    BG = $BLUE & $GREEN
    BB = $BLUE & $BLUE
    BY = $BLUE & $YELLOW
    BP = $BLUE & $PURPLE

    YR = $YELLOW & $RED
    YG = $YELLOW & $GREEN
    YB = $YELLOW & $BLUE
    YY = $YELLOW & $YELLOW
    YP = $YELLOW & $PURPLE

    PR = $PURPLE & $RED
    PG = $PURPLE & $GREEN
    PB = $PURPLE & $BLUE
    PY = $PURPLE & $YELLOW
    PP = $PURPLE & $PURPLE

  Pairs* = Deque[Pair]

func axis*(pair: Pair): Cell {.inline.} =
  ## Gets the axis-puyo in the pair.
  ColorPuyo.low.succ pair.ord div ColorPuyo.fullSet.card

func child*(pair: Pair): Cell {.inline.} =
  ## Gets the child-puyo in the pair.
  ColorPuyo.low.succ pair.ord mod ColorPuyo.fullSet.card

func makePair*(axis, child: ColorPuyo): Pair {.inline.} =
  ## Returns a pair with the given axis and child.
  Pair.low.succ (axis.ord - ColorPuyo.low.ord) * ColorPuyo.fullSet.card + (child.ord - ColorPuyo.low.ord)
  
func `axis=`*(pair: var Pair, color: ColorPuyo) {.inline.} =
  ## Sets the axis puyo.
  pair = makePair(color, pair.child)

func `child=`*(pair: var Pair, color: ColorPuyo) {.inline.} =
  ## Sets the child puyo.
  pair = makePair(pair.axis, color)

func isDouble*(pair: Pair): bool {.inline.} =
  ## Returns true if the pair is double (monochromatic).
  pair in {RR, GG, BB, YY, PP}

func swapped*(pair: Pair): Pair {.inline.} =
  ## Returns a pair whose axis-puyo and child-puyo are swapped.
  makePair(pair.child, pair.axis)

func swap*(pair: var Pair) {.inline.} =
  ## Swaps the axis-puyo and the child-puyo in the pair.
  pair = pair.swapped

func colorNum*(pair: Pair, puyo: ColorPuyo): int {.inline.} =
  ## Gets the total number of the specified color puyoes in the pair.
  (pair.axis == puyo).int + (pair.child == puyo).int

const PairPosSep = '|'

func toStr*(pair: Pair, pos = Position.none): string {.inline.} =
  ## Converts the pair to a string.
  result = $pair
  if pos.isSome:
    result &= &"{PairPosSep}{pos.get}"

const PairToUrl = "0coAM2eqCO4gsEQ6iuGS8kwIU"

func toUrl*(pair: Pair, pos = Position.none): string {.inline.} =
  ## Converts the pair to a url.
  return PairToUrl[pair.ord - Pair.low.ord] & pos.toUrl

func toPairPosition*(str: string, url: bool): Option[tuple[pair: Pair, pos: Option[Position]]] {.inline.} =
  ## Converts the string to a pair and a position.
  ## If the conversions fails, returns none.
  const
    UrlToPair = collect:
      for i, url in PairToUrl:
        {url: some Pair.low.succ i}
    StrToPair = collect:
      for pair in Pair:
        {$pair: some pair}

  var
    pair = Pair.none
    pos = Option[Position].none
  if url:
    if str.len != 2:
      return

    pair = UrlToPair.getOrDefault str[0]
    pos = ($str[1]).toPosition true
  else:
    let strings = str.split PairPosSep
    if strings.len notin 1 .. 2:
      return

    pair = StrToPair.getOrDefault strings[0]
    pos = if strings.len == 2: strings[1].toPosition false else: Position.none.some

  if pair.isNone or pos.isNone:
    return

  return some (pair: pair.get, pos: pos.get)

func toPair*(str: string, url: bool): Option[Pair] {.inline.} =
  ## Converts the string to a pair.
  ## If the conversions fails, returns none.
  let pairPos = str.toPairPosition url
  return if pairPos.isSome: pairPos.get.pair.some else: Pair.none

func toArray*(pair: Pair): array[2, Cell] {.inline.} =
  ## Converts the pair to an array.
  [pair.axis, pair.child]

func toPair*(`array`: array[2, ColorPuyo]): Pair {.inline.} =
  ## Converts the array to a pair.
  ((`array`[0].ord - ColorPuyo.low.ord) * ColorPuyo.fullSet.card + `array`[1].ord - ColorPuyo.low.ord).Pair

func `==`*(pairs, other: Pairs): bool {.inline.} = pairs.toSeq == other.toSeq

func colorNum*(pairs: Pairs, puyo: ColorPuyo): int {.inline.} =
  ## Gets the total number of the specified color puyoes in the pairs.
  sum pairs.mapIt it.colorNum puyo

const PairsSep = "\n"

func `$`*(pairs: Pairs): string {.inline.} =
  let strs = collect:
    for pair in pairs:
      $pair

  return strs.join PairsSep

func fix(positions: Option[Positions], pairsLen: Natural): Positions {.inline.} =
  ## Fixes the given positions for a pairs-to-string conversion.
  if positions.isNone:
    return Position.none.repeat pairsLen

  if positions.get.len < pairsLen:
    return positions.get & Position.none.repeat pairsLen - positions.get.len
  else:
    return positions.get[0 ..< pairsLen]

func toStr*(pairs: Pairs, positions = Positions.none): string {.inline.} =
  ## Converts the pairs to a string.
  let
    positions2 = positions.fix pairs.len
    lines = collect:
      for i, pair in pairs:
        pair.toStr positions2[i]

  return lines.join PairsSep

func toUrl*(pairs: Pairs, positions = Positions.none): string {.inline.} =
  ## Converts the pairs to a url.
  if pairs.len == 0:
    return

  let
    positions2 = positions.fix pairs.len
    urls = collect:
      for i, pair in pairs:
        pair.toUrl positions2[i]

  return urls.join

func toPairsPositions*(str: string, url: bool): Option[tuple[pairs: Pairs, positions: Positions]] {.inline.} =
  ## Converts the string to pairs and positions.
  ## If the conversions fails, returns none.
  if str == "":
    return some (pairs: initDeque[Pair](), positions: newSeq[Option[Position]]())

  var pairPosSeq: seq[Option[tuple[pair: Pair, pos: Option[Position]]]]
  if url:
    if str.len mod 2 == 1:
      return

    pairPosSeq = collect:
      for i in 0 ..< str.len div 2:
        str[2 * i .. 2 * i + 1].toPairPosition true
  else:
    pairPosSeq = collect:
      for s in str.split PairsSep:
        s.toPairPosition false

  if pairPosSeq.anyIt it.isNone:
    return

  var
    pairs = initDeque[Pair] pairPosSeq.len
    positions = newSeqOfCap[Option[Position]] pairPosSeq.len
  for pairPos in pairPosSeq:
    pairs.addLast pairPos.get.pair
    positions.add pairPos.get.pos
  return some (pairs: pairs, positions: positions)

func toPairs*(str: string, url: bool): Option[Pairs] {.inline.} =
  ## Converts the string to pairs.
  ## If the conversions fails, returns none.
  let pairsPositions = str.toPairsPositions url
  return if pairsPositions.isSome: pairsPositions.get.pairs.some else: Pairs.none

func toArray*(pairs: Pairs): seq[array[2, Cell]] {.inline.} =
  ## Converts the pairs to an array.
  collect:
    for pair in pairs:
      pair.toArray

func toPairs*(`array`: openArray[array[2, ColorPuyo]]): Pairs {.inline.} =
  ## Converts the array to pairs.
  for pairArray in `array`:
    result.addLast pairArray.toPair
