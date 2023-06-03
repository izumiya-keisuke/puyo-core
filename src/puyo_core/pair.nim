## This modules implements the pair of two color puyoes.
## The puyo that is the axis of rotation is axis-puyo, and the other is child-puyo.
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
    ## The pair of two color puyoes.
    ## The first character means the axis-puyo, and the second one means the child-puyo.
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

  Pairs* = Deque[Pair] ## The pair sequence.

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func makePair*(axis, child: ColorPuyo): Pair {.inline.} =
  ## Returns the pair determined from the axis-puyo :code:`axis` and the child-puyo :code:`child`.
  Pair.low.succ (axis.ord - ColorPuyo.low.ord) * ColorPuyo.fullSet.card + (child.ord - ColorPuyo.low.ord)

# ------------------------------------------------
# Property
# ------------------------------------------------

func axis*(pair: Pair): ColorPuyo {.inline.} =
  ## Returns the axis-puyo.
  ColorPuyo.low.succ pair.ord div ColorPuyo.fullSet.card

func child*(pair: Pair): ColorPuyo {.inline.} =
  ## Returns the child-puyo.
  ColorPuyo.low.succ pair.ord mod ColorPuyo.fullSet.card

func `axis=`*(pair: var Pair, color: ColorPuyo) {.inline.} =
  ## Sets the axis-puyo.
  pair = makePair(color, pair.child)

func `child=`*(pair: var Pair, color: ColorPuyo) {.inline.} =
  ## Sets the child-puyo.
  pair = makePair(pair.axis, color)

func isDouble*(pair: Pair): bool {.inline.} =
  ## Returns :code:`true` if the :code:`pair` is double (monochromatic).
  pair in {RR, GG, BB, YY, PP}

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `==`*(pairs1, pairs2: Pairs): bool {.inline.} = pairs1.toSeq == pairs2.toSeq

# ------------------------------------------------
# Swap
# ------------------------------------------------

func swapped*(pair: Pair): Pair {.inline.} =
  ## Returns the pair with axis-puyo and child-puyo swapped.
  makePair(pair.child, pair.axis)

func swap*(pair: var Pair) {.inline.} =
  ## Swaps the axis-puyo and the child-puyo.
  pair = pair.swapped

# ------------------------------------------------
# Number
# ------------------------------------------------

func colorNum*(pair: Pair, puyo: ColorPuyo): int {.inline.} =
  ## Returns the number of :code:`puyo` in the :code:`pair`.
  (pair.axis == puyo).int + (pair.child == puyo).int

func colorNum*(pairs: Pairs, puyo: ColorPuyo): int {.inline.} =
  ## Returns the number of :code:`puyo` in the :code:`pairs`.
  sum pairs.mapIt it.colorNum puyo

# ------------------------------------------------
# Pair[s] -> string
# ------------------------------------------------

const PairsSep = "\n" ## Delimiter between pairs in string representation

func `$`*(pairs: Pairs): string {.inline.} =
  ## Converts :code:`pairs` to the string representation.
  let strs = collect:
    for pair in pairs:
      $pair

  return strs.join PairsSep

const PairPosSep = '|' ## Delimiter between pair and position in string representation

func toStr*(pair: Pair, pos = Position.none): string {.inline.} =
  ## Converts :code:`pair` to the string representation.
  ## If :code:`pos` is given, the position information is added to the string.
  result = $pair
  if pos.isSome:
    result &= &"{PairPosSep}{pos.get}"

func align(positions: Option[Positions], length: Natural): Positions {.inline.} =
  ## Aligns the length of :code:`positions` with :code:`length`.
  if positions.isNone:
    return Position.none.repeat length

  if positions.get.len < length:
    return positions.get & Position.none.repeat length - positions.get.len
  else:
    return positions.get[0 ..< length]

func toStr*(pairs: Pairs, positions = Positions.none): string {.inline.} =
  ## Converts :code:`pairs` and :code:`positions` to the string representation.
  let
    alignedPositions = positions.align pairs.len
    lines = collect:
      for i, pair in pairs:
        pair.toStr alignedPositions[i]

  return lines.join PairsSep

const PairToUrl = "0coAM2eqCO4gsEQ6iuGS8kwIU"

func toUrl*(pair: Pair, pos = Position.none): string {.inline.} =
  ## Converts :code:`pair` and :code:`pos` to the URL.
  return PairToUrl[pair.ord - Pair.low.ord] & pos.toUrl

func toUrl*(pairs: Pairs, positions = Positions.none): string {.inline.} =
  ## Converts :code:`pairs` and :code:`positions` to the URL.
  if pairs.len == 0:
    return

  let
    alignedPositions = positions.align pairs.len
    urls = collect:
      for i, pair in pairs:
        pair.toUrl alignedPositions[i]

  return urls.join

# ------------------------------------------------
# string -> Pair[s] / Position[s]
# ------------------------------------------------

func toPairPosition*(str: string, url: bool): Option[tuple[pair: Pair, pos: Option[Position]]] {.inline.} =
  ## Converts :code:`str` to the pair and the position.
  ## The string representation or URL is acceptable as :code:`str`,
  ## and which type of input is specified by :code:`url`.
  ## If the conversions fails, returns :code:`none`.
  const
    UrlToPair = collect:
      for i, url in PairToUrl:
        {url: some Pair.low.succ i}
    StrToPair = collect:
      for pair in Pair:
        {$pair: some pair}

  var
    pair = none Pair
    pos = none Option[Position]
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
    if strings.len == 1: # no position
      pos = some Position.none
    else: # string.len == 2
      pos = strings[1].toPosition false

  if pair.isNone or pos.isNone:
    return

  return some (pair: pair.get, pos: pos.get)

func toPairsPositions*(str: string, url: bool): Option[tuple[pairs: Pairs, positions: Positions]] {.inline.} =
  ## Converts :code:`str` to the pairs and the positions.
  ## The string representation or URL is acceptable as :code:`str`,
  ## and which type of input is specified by :code:`url`.
  ## If the conversions fails, returns :code:`none`.
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

func toPair*(str: string, url: bool): Option[Pair] {.inline.} =
  ## Converts :code:`str` to the pair.
  ## The string representation or URL is acceptable as :code:`str`,
  ## and which type of input is specified by :code:`url`.
  ## If the conversions fails, returns :code:`none(Pair)`.
  let pairPos = str.toPairPosition url
  return if pairPos.isSome: pairPos.get.pair.some else: Pair.none

func toPairs*(str: string, url: bool): Option[Pairs] {.inline.} =
  ## Converts :code:`str` to the pairs.
  ## The string representation or URL is acceptable as :code:`str`,
  ## and which type of input is specified by :code:`url`.
  ## If the conversions fails, returns :code:`none(Pairs)`.
  let pairsPositions = str.toPairsPositions url
  return if pairsPositions.isSome: pairsPositions.get.pairs.some else: Pairs.none

# ------------------------------------------------
# Pair[s] <-> array
# ------------------------------------------------

func toArray*(pair: Pair): array[2, ColorPuyo] {.inline.} =
  ## Converts :code:`pair` to the array.
  [pair.axis, pair.child]

func toArray*(pairs: Pairs): seq[array[2, ColorPuyo]] {.inline.} =
  ## Converts :code:`pairs` to the array.
  collect:
    for pair in pairs:
      pair.toArray

func toPair*(puyoArray: array[2, ColorPuyo]): Pair {.inline.} =
  ## Converts :code:`puyoArray` to the pair.
  let
    axis = puyoArray[0].ord - ColorPuyo.low.ord 
    child = puyoArray[1].ord - ColorPuyo.low.ord 

  return Pair axis * ColorPuyo.fullSet.card + child

func toPairs*(puyoArray: openArray[array[2, ColorPuyo]]): Pairs {.inline.} =
  ## Converts :code:`puyoArray` to the pairs.
  for pairArray in puyoArray:
    result.addLast pairArray.toPair
