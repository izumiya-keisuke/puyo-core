## This module implements an environment.
## An "environment" contains a field and pairs.
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
    field: Field
    pairs: Pairs
    useColors: set[ColorPuyo]
    rng: Rand

  UrlDomain* {.pure.} = enum
    ISHIKAWAPUYO = "ishikawapuyo.net"
    IPS = "ips.karou.jp"
  UrlMode* {.pure.} = enum
    EDIT = "e"
    SIMU = "s"
    VIEW = "v"
    NAZO = "n"

func colorNum*(env: Env, puyo: ColorPuyo): int {.inline.} =
  ## Gets the total number of the specified color puyoes in the environment.
  env.field.colorNum(puyo) + env.pairs.colorNum(puyo)

func colorNum*(env: Env): int {.inline.} =
  ## Gets the total number of all color puyoes in the environment.
  env.field.colorNum + 2 * env.pairs.len

func garbageNum*(env: Env): int {.inline.} =
  ## Gets the total number of garbage puyoes and hard puyoes in the environment.
  env.field.garbageNum

func puyoNum*(env: Env): int {.inline.} =
  ## Gets the total number of all puyoes in the environment.
  env.field.puyoNum + 2 * env.pairs.len

func randomPair(rng: var Rand, colors: set[ColorPuyo] | seq[ColorPuyo]): Pair {.inline.} =
  ## Returns a random pair with the specified colors.
  let idxes = colors.mapIt it.ord - ColorPuyo.low.ord
  return Pair.low.succ ColorPuyo.fullSet.card * rng.sample(idxes) + rng.sample(idxes)

func addPair*(env: var Env) {.inline.} =
  ## Adds a random pair to the last of pairs.
  env.pairs.addLast env.rng.randomPair env.useColors

func setInitialPairs(env: var Env) {.inline.} =
  ## Adds two pairs with three or less colors to the pairs.
  var colors = env.useColors.toSeq
  env.rng.shuffle colors
  let initialColors = colors[0 ..< min(colors.len, 3)]

  for _ in 0 ..< 2:
    env.pairs.addLast env.rng.randomPair initialColors

func reset*(
  env: var Env, useColors = set[ColorPuyo].none, colorNum = range[1 .. 5].none, setPairs = true, seed = int64.none
) {.inline.} =
  ## Resets the environment.
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
  ## Make an environment.
  ## If :code:`useColors` is given, :code:`colorNum` is ignored.
  result.reset useColors, colorNum.some, setPairs, seed.some

func move*(env: var Env, pos: Position, addPair = true): MoveResult {.inline, discardable.} =
  ## Puts the first pair and starts the chain until it ends, and then adds the new pair to the environment (optional).
  ## This function tracks the number of chains.
  result = env.field.move(env.pairs.popFirst, pos)

  if addPair:
    env.addPair

func moveWithRoughTracking*(env: var Env, pos: Position, addPair = true): MoveResult {.inline.} =
  ## Puts the first pair and starts the chain until it ends, and then adds the new pair to the environment (optional).
  ## Compared to :code:`move`, this function additionally tracks the total number of disappeared puyoes.
  result = env.field.moveWithRoughTracking(env.pairs.popFirst, pos)

  if addPair:
    env.addPair

func moveWithDetailedTracking*(env: var Env, pos: Position, addPair = true): MoveResult {.inline.} =
  ## Puts the first pair and starts the chain until it ends, and then adds the new pair to the environment (optional).
  ## Compared to :code:`moveWithRoughTracking`,
  ## this function additionally tracks the number of disappeared puyoes in each chain.
  result = env.field.moveWithDetailedTracking(env.pairs.popFirst, pos)

  if addPair:
    env.addPair

func moveWithFullTracking*(env: var Env, pos: Position, addPair = true): MoveResult {.inline.} =
  ## Puts the first pair and starts the chain until it ends, and then adds the new pair to the environment (optional).
  ## This function tracks everything.
  result = env.field.moveWithFullTracking(env.pairs.popFirst, pos)

  if addPair:
    env.addPair

const EnvSep = "\n======\n"

func `$`*(env: Env): string {.inline.} =
  &"{env.field}{EnvSep}{env.pairs}"

func toStr*(env: Env, positions = Positions.none): string {.inline.} =
  ## Converts the environment to a string.
  &"{env.field}{EnvSep}{env.pairs.toStr positions}"

func toUrl*(env: Env, positions = Positions.none, mode = SIMU, domain = ISHIKAWAPUYO): string {.inline.} =
  ## Converts the environment to a url.
  const Protocols: array[UrlDomain, string] = ["https", "http"]

  result = &"{Protocols[domain]}://{domain}/simu/p{mode}.html"

  let
    fieldUrl = env.field.toUrl
    pairsUrl = env.pairs.toUrl positions
  if fieldUrl == "" and pairsUrl == "":
    return

  result &= &"?{fieldUrl}_{pairsUrl}"

func getColors(field: Field, pairs: Pairs): set[ColorPuyo] {.inline.} =
  ## Gets all used colors.
  ColorPuyo.toSeq.filterIt(field.colorNum(it) > 0 or pairs.colorNum(it) > 0).toSet

func toEnvPositions*(
  str: string, url: bool, useColors = set[ColorPuyo].none, seed = 0'i64
): Option[tuple[env: Env, positions: Positions]] {.inline.} =
  ## Converts the string to an environment and positions.
  ## If the conversions fails, returns none.
  ## If :code:`useColors` is not given, detects it automatically.
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
      useColors: if useColors.isSome: useColors.get else: getColors(field.get, pairsPositions.get.pairs),
      rng: seed.initRand,
    ).Env,
    positions: pairsPositions.get.positions,
  )
  
func toEnv*(str: string, url: bool, useColors = set[ColorPuyo].none, seed = 0'i64): Option[Env] {.inline.} =
  ## Converts the string to an environment.
  ## If the conversions fails, returns none.
  ## If :code:`useColors` is not given, detects it automatically.
  let envPositions = str.toEnvPositions(url, useColors, seed)
  return if envPositions.isSome: envPositions.get.env.some else: Env.none

func toArrays*(env: Env): tuple[field: array[Row, array[Col, Cell]], pairs: seq[array[2, Cell]]] {.inline.} =
  ## Converts the environment to arrays.
  (field: env.field.toArray, pairs: env.pairs.toArray)

func toEnv*(
  fieldArray: array[Row, array[Col, Cell]],
  pairsArray: openArray[array[2, ColorPuyo]],
  useColors = set[ColorPuyo].none,
  seed = 0'i64,
): Env {.inline.} =
  ## Converts the arrays to an environment.
  ## If :code:`useColors` is not given, detects it automatically.
  result.field = fieldArray.toField
  result.pairs = pairsArray.toPairs
  result.useColors = if useColors.isSome: useColors.get else: getColors(result.field, result.pairs)
  result.rng = seed.initRand
