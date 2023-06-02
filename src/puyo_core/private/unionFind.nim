## This module implements the union-find structure.
##

import sequtils
import sugar

type
  UnionFindNode* = Natural ## Node of union-find structure.

  UnionFind* = tuple
    ## Union-find structure.
    parents: seq[UnionFindNode] # parent of each node
    sizes: seq[Natural] # size of the tree with each node as a root

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func initUnionFind*(size: Natural): UnionFind {.inline.} =
  ## Returns a new union-find structure with :code:`size` nodes.
  result.parents = collect:
    for i in 0 ..< size:
      UnionFindNode i

  result.sizes = 0.Natural.repeat size

# ------------------------------------------------
# Operation
# ------------------------------------------------

func getRoot*(uf: var UnionFind, node: UnionFindNode): UnionFindNode {.inline.} =
  ## Returns the root of the :code:`node`.
  ## Path compression is also performed.
  if uf.parents[node] == node:
    return node

  # path compression
  uf.parents[node] = uf.parents[uf.parents[node]]

  return uf.getRoot uf.parents[node]

func merge*(uf: var UnionFind, node1, node2: UnionFindNode) {.inline.} =
  ## Merges the tree containing :code:`node1` and the one containing :code:`node2` using a union-by-size strategy.
  let
    root1 = uf.getRoot node1
    root2 = uf.getRoot node2
  if root1 == root2:
    return

  # union-by-size merge
  let (rootBig, rootSmall) = if uf.sizes[root1] >= uf.sizes[root2]: (root1, root2) else: (root2, root1)
  uf.sizes[rootBig].inc uf.sizes[rootSmall]
  uf.parents[rootSmall] = rootBig

func isSame*(uf: var UnionFind, node1, node2: UnionFindNode): bool {.inline.} =
  ## Returns :code:`true` if :code:`node1` and :code:`node2` are contained in the same tree.
  uf.getRoot(node1) == uf.getRoot(node2)
