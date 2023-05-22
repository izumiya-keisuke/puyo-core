## This module implements utility functions.
##

import sequtils
import sugar

type UnionFind* = tuple
  parents: seq[Natural]
  sizes: seq[Natural]

func initUnionFind*(size: Natural): UnionFind {.inline.} =
  ## Returns a new union find structure.
  result.parents = collect:
    for i in 0 ..< size:
      i.Natural

  result.sizes = 0.Natural.repeat size

func getRoot*(uf: var UnionFind, element: Natural): int {.inline.} =
  ## Returns the root of the element.
  if uf.parents[element] == element:
    return element

  uf.parents[element] = uf.parents[uf.parents[element]]
  return uf.getRoot uf.parents[element]

func merge*(uf: var UnionFind, element1, element2: Natural) {.inline.} =
  ## Merges two trees that contain the element1 and the element2 respectively.
  let
    root1 = uf.getRoot element1
    root2 = uf.getRoot element2
  if root1 == root2:
    return

  let (rootBig, rootSmall) = if uf.sizes[root1] >= uf.sizes[root2]: (root1, root2) else: (root2, root1)
  uf.sizes[rootBig].inc uf.sizes[rootSmall]
  uf.parents[rootSmall] = rootBig

func isSame*(uf: var UnionFind, element1, element2: Natural): bool {.inline.} =
  ## Returns true if the element1 and the element2 belong to the same tree.
  uf.getRoot(element1) == uf.getRoot(element2)
