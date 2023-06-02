## This module implements common contents related to the binary field.
##

import std/setutils

import ../intrinsic
import ../../common
import ../../position

when UseAvx2:
  import ./avx2/binary
else:
  when defined(cpu32):
    import ./primitive/bit32/binary
  else:
    import ./primitive/bit64/binary

export popcnt

type Connection = tuple
  ## Intermediate results for calculating connections.
  visible: BinaryField
  hasUpDown: BinaryField
  hasRightLeft: BinaryField
  connect4T: BinaryField
  connect3IL: BinaryField

# ------------------------------------------------
# Property
# ------------------------------------------------

func isDead*(field: BinaryField): bool {.inline.} =
  ## Returns :code:`true` if :code:`field` is in a defeated state
  bool field.exist(2, 3)

# ------------------------------------------------
# Position
# ------------------------------------------------

func invalidPositions*(field: BinaryField): set[Position] {.inline.} =
  ## Returns the invalid positions.
  const
    AllColumns = {Col.low .. Col.high}
    OuterColumns: array[2, array[Col, set[Col]]] = [
      [set[Col]({}), {}, {}, {}, {}, {}],
      [{1.Col}, {1.Col, 2.Col}, {}, {4.Col, 5.Col, 6.Col}, {5.Col, 6.Col}, {6.Col}]]
    LiftPositions: array[2, array[Col, set[Position]]] = [
      [set[Position]({}), {}, {}, {}, {}, {}],
      [{POS_1D}, {POS_2D}, {POS_3D}, {POS_4D}, {POS_5D}, {POS_6D}]]
    InvalidPositions: array[Col, set[Position]] = [
      {POS_1U, POS_1R, POS_1D, POS_2L},
      {POS_2U, POS_2R, POS_2D, POS_2L, POS_1R, POS_3L},
      {POS_3U, POS_3R, POS_3D, POS_3L, POS_2R, POS_4L},
      {POS_4U, POS_4R, POS_4D, POS_4L, POS_3R, POS_5L},
      {POS_5U, POS_5R, POS_5D, POS_5L, POS_4R, POS_6L},
      {POS_6U, POS_6D, POS_6L, POS_5R}]

  var usableColumns = AllColumns

  # If any puyo is in the 12th row, that column and its outer ones cannot be used,
  # and the axis-puyo cannot be lifted at the column.
  for col in Col.low .. Col.high:
    let row12 = field.exist(2, col)
    usableColumns = usableColumns - OuterColumns[row12][col]
    result.incl LiftPositions[row12][col]
      
  # If there is a usable column of height 11, or the heights of the 2nd and 4th columns are both 12,
  # all columns are usable.
  var allColumnsUsable = field.exist(2, 2) and field.exist(2, 4)
  for col in usableColumns:
    allColumnsUsable = allColumnsUsable or field.exist(3, col)
  usableColumns = [usableColumns, AllColumns][allColumnsUsable]

  # If any puyo is in the 12th row, that column and its outer ones cannot be used.
  for col in Col.low .. Col.high:
    usableColumns = usableColumns - OuterColumns[field.exist(1, col)][col]

  for col in usableColumns.complement:
    result = result + InvalidPositions[col]

func validPositions*(field: BinaryField): set[Position] {.inline.} =
  ## Returns the valid positions.
  field.invalidPositions.complement

func validDoublePositions*(field: BinaryField): set[Position] {.inline.} =
  ## Returns the valid positions for a double pair.
  DoublePositions - field.invalidPositions

# ------------------------------------------------
# Shift
# ------------------------------------------------

func shiftedUp*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field shifted upward the :code:`field` and then trimmed.
  field.shiftedUpWithoutTrim.trimmed

func shiftedDown*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field shifted downward the :code:`field` and then trimmed.
  field.shiftedDownWithoutTrim.trimmed

func shiftedRight*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field shifted rightward the :code:`field` and then trimmed.
  field.shiftedRightWithoutTrim.trimmed

func shiftedLeft*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field shifted leftward the :code:`field` and then trimmed.
  field.shiftedLeftWithoutTrim.trimmed

# ------------------------------------------------
# Expand
# ------------------------------------------------

func expanded*(field: BinaryField): BinaryField {.inline.} =
  ## Dilates the :code:`field`.
  ## This function does not trim.
  sum(
    field,
    field.shiftedUpWithoutTrim,
    field.shiftedDownWithoutTrim,
    field.shiftedRightWithoutTrim,
    field.shiftedLeftWithoutTrim)

func expandedV(field: BinaryField): BinaryField {.inline.} =
  ## Dilates the :code:`field` vertically.
  ## This function does not trim.
  sum(field, field.shiftedUpWithoutTrim, field.shiftedDownWithoutTrim)

func expandedH(field: BinaryField): BinaryField {.inline.} =
  ## Dilates the :code:`field` horizontally.
  ## This function does not trim.
  sum(field, field.shiftedRightWithoutTrim, field.shiftedLeftWithoutTrim)

# ------------------------------------------------
# Disappear
# ------------------------------------------------

func connections(field: BinaryField): Connection {.inline.} =
  ## Returns intermediate results for calculating connections.
  let
    visibleField = field.visible

    hasUp = visibleField * visibleField.shiftedDownWithoutTrim
    hasDown = visibleField * visibleField.shiftedUpWithoutTrim
    hasRight = visibleField * visibleField.shiftedLeftWithoutTrim
    hasLeft = visibleField * visibleField.shiftedRightWithoutTrim

    hasUpDown = hasUp * hasDown
    hasRightLeft = hasRight * hasLeft
    hasUpOrDown = hasUp + hasDown
    hasRightOrLeft = hasRight + hasLeft

    connect4T = hasUpDown * hasRightOrLeft + hasRightLeft * hasUpOrDown
    connect3IL = sum(hasUpDown, hasRightLeft, hasUpOrDown * hasRightOrLeft)

  result.visible = visibleField
  result.hasUpDown = hasUpDown
  result.hasRightLeft = hasRightLeft
  result.connect4T = connect4T
  result.connect3IL = connect3IL

func disappeared(connection: Connection): BinaryField {.inline.} =
  ## Returns the binary field where four or more cells are connected.
  let
    connect4Up = connection.connect3IL * connection.connect3IL.shiftedUpWithoutTrim
    connect4Down = connection.connect3IL * connection.connect3IL.shiftedDownWithoutTrim
    connect4Right = connection.connect3IL * connection.connect3IL.shiftedRightWithoutTrim
    connect4Left = connection.connect3IL * connection.connect3IL.shiftedLeftWithoutTrim

  return connection.visible * (
    sum(connection.connect4T, connect4Up, connect4Down, connect4Right, connect4Left)).expanded

func disappeared*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the binary field where four or more cells are connected.
  field.connections.disappeared

func willDisappear*(field: BinaryField): bool {.inline.} =
  ## Returns :code:`true` if four or more cells are connected.
  let
    connection = field.connections
    connect4Up = connection.connect3IL * connection.connect3IL.shiftedUpWithoutTrim
    connect4Right = connection.connect3IL * connection.connect3IL.shiftedRightWithoutTrim

  return not sum(connection.connect4T, connect4Up, connect4Right).isZero

# ------------------------------------------------
# Connect
# ------------------------------------------------

func connect3*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the field with only the locations where exactly three cells are connected.
  ## This function ignores ghost puyoes.
  let connection = field.connections
  return connection.connect3IL.expanded * connection.visible - connection.disappeared

func connect3V*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the field with only the locations where exactly three cells are connected vertically.
  ## This function ignores ghost puyoes.
  let
    visibleField = field.visible

    up = visibleField.shiftedUpWithoutTrim
    down = visibleField.shiftedDownWithoutTrim
    right = visibleField.shiftedRightWithoutTrim
    left = visibleField.shiftedLeftWithoutTrim

    upDown = prod(visibleField, up, down)
    exclude = visibleField * sum(
      right,
      left,
      up.shiftedRightWithoutTrim,
      up.shiftedLeftWithoutTrim,
      down.shiftedRightWithoutTrim,
      down.shiftedLeftWithoutTrim,
      up.shiftedUpWithoutTrim,
      down.shiftedDownWithoutTrim)

  return (upDown - exclude).expandedV

func connect3H*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the field with only the locations where exactly three cells are connected horizontally.
  ## This function ignores ghost puyoes.
  let
    visibleField = field.visible

    up = visibleField.shiftedUpWithoutTrim
    down = visibleField.shiftedDownWithoutTrim
    right = visibleField.shiftedRightWithoutTrim
    left = visibleField.shiftedLeftWithoutTrim

    rightLeft = prod(visibleField, right, left)
    exclude = visibleField * sum(
      up,
      down,
      up.shiftedRightWithoutTrim,
      up.shiftedLeftWithoutTrim,
      down.shiftedRightWithoutTrim,
      down.shiftedLeftWithoutTrim,
      right.shiftedRightWithoutTrim,
      left.shiftedLeftWithoutTrim)

  return (rightLeft - exclude).expandedH

func connect3L*(field: BinaryField): BinaryField {.inline.} =
  ## Returns the field with only the locations where exactly three cells are connected by L-shape.
  ## This function ignores ghost puyoes.
  let connection = field.connections
  return connection.connect3IL.expanded * connection.visible -
    sum(connection.disappeared, connection.hasUpDown.expandedV, connection.hasRightLeft.expandedH)
