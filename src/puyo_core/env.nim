## This module implements the environment.
## An environment contains the field and the pairs.
##

import deques
import options
import random
import sequtils
import std/setutils
import strformat
import strutils
import uri

import ./cell
import ./common
import ./field
import ./moveResult
import ./pair
import ./position

type
  Env* = tuple
    ## Puyo Puyo environment.
    field: Field
    pairs: Pairs
    useColors: set[ColorPuyo]
    rng: Rand

  UrlDomain* {.pure.} = enum
    ## URL domain of the web simulator.
    ISHIKAWAPUYO = "ishikawapuyo.net"
    IPS = "ips.karou.jp"

  UrlMode* {.pure.} = enum
    ## Mode of the web simulator.
    EDIT = "e"
    SIMU = "s"
    VIEW = "v"
    NAZO = "n"

# ------------------------------------------------
# Pair
# ------------------------------------------------

func randomPair(rng: var Rand, colors: set[ColorPuyo] or seq[ColorPuyo]): Pair {.inline.} =
  ## Returns a random pair using :code:`colors`.
  let
    idxes = colors.mapIt it.ord - ColorPuyo.low.ord
    axisIdx = rng.sample idxes
    childIdx = rng.sample idxes
  return Pair.low.succ axisIdx * ColorPuyo.fullSet.card + childIdx

func addPair*(env: var Env) {.inline.} =
  ## Adds a random pair to the tail of the pairs.
  env.pairs.addLast env.rng.randomPair env.useColors

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func setInitialPairs(env: var Env) {.inline.} =
  ## Sets the first two pairs.
  var colors = env.useColors.toSeq
  env.rng.shuffle colors
  let initialColors = colors[0 ..< min(colors.len, 3)]

  for _ in 0 ..< 2:
    env.pairs.addLast env.rng.randomPair initialColors

func reset*(
  env: var Env, useColors = set[ColorPuyo].none, colorNum = range[1 .. 5].none, setPairs = true, seed = int64.none
) {.inline.} =
  ## Resets :code:`env`.
  ## If :code:`useColors` and :code:`colorNum` are both given, :code:`colorNum` is ignored.
  if seed.isSome:
    env.rng = seed.get.initRand

  if useColors.isSome:
    env.useColors = useColors.get
  elif colorNum.isSome:
    var colors = ColorPuyo.toSeq
    env.rng.shuffle colors
    env.useColors = colors[0 ..< colorNum.get].toSet

  env.field = zeroField()

  env.pairs.clear
  if setPairs:
    env.setInitialPairs
    env.addPair

func makeEnv*(
  useColors = set[ColorPuyo].none, colorNum = range[1 .. 5](4), setPairs = true, seed = 0'i64
): Env {.inline.} =
  ## Returns the initial environment.
  ## If :code:`useColors` is given, :code:`colorNum` is ignored.
  result.reset useColors, colorNum.some, setPairs, seed.some

# ------------------------------------------------
# Number
# ------------------------------------------------

func colorNum*(env: Env, puyo: ColorPuyo): int {.inline.} =
  ## Returns the number of :code:`puyo` in the :code:`env`.
  env.field.colorNum(puyo) + env.pairs.colorNum(puyo)

func colorNum*(env: Env): int {.inline.} =
  ## Returns the number of color puyoes in the :code:`env`.
  env.field.colorNum + 2 * env.pairs.len

func garbageNum*(env: Env): int {.inline.} =
  ## Returns the number of hard and garbage puyoes in the :code:`env`.
  env.field.garbageNum

func puyoNum*(env: Env): int {.inline.} =
  ## Returns the number of puyoes in the :code:`env`.
  ## Gets the total number of all puyoes in the environment.
  env.field.puyoNum + 2 * env.pairs.len

# ------------------------------------------------
# Move
# ------------------------------------------------

func move*(env: var Env, pos: Position, addPair = true): MoveResult {.inline, discardable.} =
  ## Puts the :code:`pair` and advance the :code:`field` until the chain ends,
  ## and then adds the new pair to the :code:`env` (optional).
  ## This function tracks:
  ## * Number of chains
  result = env.field.move(env.pairs.popFirst, pos)

  if addPair:
    env.addPair

func moveWithRoughTracking*(env: var Env, pos: Position, addPair = true): MoveResult {.inline.} =
  ## Puts the :code:`pair` and advance the :code:`field` until the chain ends,
  ## and then adds the new pair to the :code:`env` (optional).
  ## This function tracks:
  ## * Number of chains
  ## * Number of each puyoes that disappeared
  result = env.field.moveWithRoughTracking(env.pairs.popFirst, pos)

  if addPair:
    env.addPair

func moveWithDetailTracking*(env: var Env, pos: Position, addPair = true): MoveResult {.inline.} =
  ## Puts the :code:`pair` and advance the :code:`field` until the chain ends,
  ## and then adds the new pair to the :code:`env` (optional).
  ## This function tracks:
  ## * Number of chains
  ## * Number of each puyoes that disappeared
  ## * Number of each puyoes that disappeared in each chain
  result = env.field.moveWithDetailTracking(env.pairs.popFirst, pos)

  if addPair:
    env.addPair

func moveWithFullTracking*(env: var Env, pos: Position, addPair = true): MoveResult {.inline.} =
  ## Puts the :code:`pair` and advance the :code:`field` until the chain ends,
  ## and then adds the new pair to the :code:`env` (optional).
  ## This function tracks:
  ## * Number of chains
  ## * Number of each puyoes that disappeared
  ## * Number of each puyoes that disappeared in each chain
  ## * Number of each puyoes in each connected component that disappeared in each chain
  result = env.field.moveWithFullTracking(env.pairs.popFirst, pos)

  if addPair:
    env.addPair

# ------------------------------------------------
# Env -> string
# ------------------------------------------------

const EnvSep = "\n======\n"

func `$`*(env: Env): string {.inline.} =
  ## Converts :code:`env` to the string representation.
  &"{env.field}{EnvSep}{env.pairs}"

func toStr*(env: Env, positions = Positions.none): string {.inline.} =
  ## Converts :code:`env` and :code:`positions` to the string representation.
  &"{env.field}{EnvSep}{env.pairs.toStr positions}"

func toUrl*(env: Env, positions = Positions.none, mode = SIMU, domain = ISHIKAWAPUYO): string {.inline.} =
  ## Converts :code:`env` and :code:`positions` to the URL.
  const Protocols: array[UrlDomain, string] = ["https", "http"]

  result = &"{Protocols[domain]}://{domain}/simu/p{mode}.html"

  let
    fieldUrl = env.field.toUrl
    pairsUrl = env.pairs.toUrl positions
  if fieldUrl == "" and pairsUrl == "":
    return

  result &= &"?{fieldUrl}_{pairsUrl}"

# ------------------------------------------------
# string -> Env
# ------------------------------------------------

func usedColors(field: Field, pairs: Pairs): set[ColorPuyo] {.inline.} =
  ## Returns used colors.
  ColorPuyo.toSeq.filterIt(field.colorNum(it) > 0 or pairs.colorNum(it) > 0).toSet

func toEnvPositions*(
  str: string, url: bool, useColors = set[ColorPuyo].none, seed = 0'i64
): Option[tuple[env: Env, positions: Positions]] {.inline.} =
  ## Converts :code:`str` to the environment and positions.
  ## The string representation or URL is acceptable as :code:`str`,
  ## and which type of input is specified by :code:`url`.
  ## If the conversions fails, returns :code:`none`.
  var
    field: Option[Field]
    pairsPositions: Option[tuple[pairs: Pairs, positions: Positions]]
  if url:
    let uri = str.parseUri
    if (
      uri.scheme notin ["https", "http"] or
      uri.hostname notin UrlDomain.mapIt($it) or
      uri.path notin UrlMode.mapIt(&"/simu/p{it}.html")
    ):
      return

    let urls = uri.query.split '_'
    if urls.len > 2:
      return

    field = urls[0].toField true
    pairsPositions = (if urls.len == 2: urls[1] else: "").toPairsPositions true
  else:
    let strs = str.split EnvSep
    if strs.len != 2:
      return

    field = strs[0].toField false
    pairsPositions = strs[1].toPairsPositions false
  if field.isNone or pairsPositions.isNone:
    return

  return some (
    env: (
      field: field.get,
      pairs: pairsPositions.get.pairs,
      useColors: if useColors.isSome: useColors.get else: usedColors(field.get, pairsPositions.get.pairs),
      rng: seed.initRand).Env,
    positions: pairsPositions.get.positions)
  
func toEnv*(str: string, url: bool, useColors = set[ColorPuyo].none, seed = 0'i64): Option[Env] {.inline.} =
  ## Converts :code:`str` to the environment.
  ## The string representation or URL is acceptable as :code:`str`,
  ## and which type of input is specified by :code:`url`.
  ## If the conversions fails, returns :code:`none`.
  let envPositions = str.toEnvPositions(url, useColors, seed)
  return if envPositions.isSome: some envPositions.get.env else: Env.none

# ------------------------------------------------
# Env <-> array
# ------------------------------------------------

func toArrays*(env: Env): tuple[field: array[Row, array[Col, Cell]], pairs: seq[array[2, ColorPuyo]]] {.inline.} =
  ## Converts :code:`env` to the arrays.
  result.field = env.field.toArray
  result.pairs = env.pairs.toArray

func toEnv*(
  fieldArray: array[Row, array[Col, Cell]],
  pairsArray: openArray[array[2, ColorPuyo]],
  useColors = set[ColorPuyo].none,
  seed = 0'i64,
): Env {.inline.} =
  ## Converts :code:`fieldArray` and :code:`pairsArray` to the environment.
  ## If :code:`useColors` is not given, detects it automatically.
  result.field = fieldArray.toField
  result.pairs = pairsArray.toPairs
  result.useColors = if useColors.isSome: useColors.get else: usedColors(result.field, result.pairs)
  result.rng = seed.initRand
