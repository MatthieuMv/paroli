extends RefCounted
class_name HudLayout
## Where a table screen puts its HUD for one window. The round and the shop solve the same
## layout, so the rack, the table, the die columns, the purse, and the actions stay put when
## one screen replaces the other. It decides positions only; widgets and rules live elsewhere.
##
## All rectangles are in HUD units. On a phone one unit is about one density-independent
## pixel, so text and touch targets keep their physical size whatever the screen's resolution.

# --- Types ---

## Arrangement chosen from the window's shape and its size in logical pixels.
enum Shape {
	## Desktop and tablet landscape: status band above the table, tray below it.
	WIDE,
	## Phone landscape: status rail on the left, rack and actions under the right thumb.
	SIDE,
	## Portrait: status at the top; rack, table, die columns, and actions stacked at the
	## bottom, where one thumb reaches them.
	TALL,
}

# --- Constants ---

## Smallest HUD space, in units, the desktop arrangement needs; larger windows scale it up.
const WIDE_DESIGN: Vector2 = Vector2(1280.0, 900.0)
## Smallest HUD space the phone landscape arrangement needs.
const SIDE_DESIGN: Vector2 = Vector2(780.0, 400.0)
## Smallest HUD space the portrait arrangement needs.
const TALL_DESIGN: Vector2 = Vector2(400.0, 720.0)
## Aspect ratio below which the portrait arrangement is used.
const TALL_ASPECT: float = 1.1
## Aspect ratio from which a small landscape window uses the side rails.
const SIDE_ASPECT: float = 1.5
## Below this desktop zoom the status band and tray would be too small to read or press,
## so wide windows switch to the side rails instead.
const WIDE_MIN_ZOOM: float = 0.72
## Largest HUD units per logical pixel on the phone arrangements (tablets, large windows).
const PHONE_MAX_ZOOM: float = 1.35
## World units between neighboring die columns; mirrors the table's roll markers.
const COLUMN_SPACING: float = 3.5
## Table half width kept in view in portrait. The dice need 8.2 units either side of the
## center; the felt runs off both edges of the window and the side rails with it, so dice
## and their columns are as large as the width allows.
const TALL_HALF_WIDTH: float = 10.2
## Largest scoreboard scale on a side rail, so the factor tiles stay in proportion to the
## Joker and bonus tiles beside the table.
const SIDE_BOARD_SCALE: float = 0.8
## Scale of the goal meter and shop sign in portrait, relative to the scoreboard under it.
const TALL_GOAL_SCALE: float = 0.8
## Unscaled goal meter and shop sign height.
const STATUS_HEIGHT: float = 118.0
## Unscaled goal meter and shop sign width on desktop; phones lay the card out to their width.
const STATUS_WIDTH: float = 300.0
## Unscaled purse footprint.
const PURSE_SIZE: Vector2 = Vector2(104.0, 48.0)
## Side of the settings button.
const GEAR: float = 46.0
## Space between the settings button and its neighbor.
const GEAR_GAP: float = 10.0
## Screen density, in dots per inch, at which a phone's logical pixel is one screen pixel.
const MOBILE_BASE_DPI: float = 160.0
## Largest share of a window side the display may reserve for cutouts and system bars.
const MAX_INSET: float = 0.12

# --- Member variables ---

## Chosen arrangement.
var shape: Shape = Shape.WIDE
## Window pixels per HUD unit.
var ui_scale: float = 1.0
## HUD size in units: the window divided by `ui_scale`.
var size: Vector2
## Slot of the top status card (goal meter, shop sign), at its on-screen size.
var status: Rect2
## Scale of the status card; it is laid out `status.size.x / status_scale` units wide.
var status_scale: float = 1.0
## Slot of the scoreboard, at its on-screen size. The shop keeps part of its stock there.
var board: Rect2
## Scale of the scoreboard inside its slot.
var board_scale: float = 1.0
## Whether the scoreboard stacks its two tiles (side rails) instead of setting them side by side.
var board_stacked: bool = false
## Top-left corner of the Joker rack.
var rack: Vector2
## Side of one rack tile.
var rack_card: float = 98.0
## Space between rack tiles.
var rack_gap: float = 8.0
## Tiles per rack row: four in a line, or two for the 2 × 2 block of the side rails.
var rack_columns: int = 4
## Room left for the table. The stage fits the table inside it.
var table: Rect2
## Table half width, in world units, that must stay in view.
var table_half_width: float = StageCamera.TABLE_HALF_WIDTH
## Clear space between the framed table and the die columns under it.
var dock_gap: float = 14.0
## Top-left corner of the purse.
var purse: Vector2
## Slot of the secondary action (roll, refresh).
var secondary: Rect2
## Slot of the primary action (play, next round), nearest the thumb.
var primary: Rect2
## Slot of the one-line instruction; empty where there is no room for it.
var hint: Rect2
## Slot of the settings button.
var settings: Rect2

# --- Static functions ---

## Lay a window out. `viewport` is in window pixels; `density` is window pixels per logical
## pixel, and zero asks the display.
static func solve(viewport: Vector2, density: float = 0.0) -> HudLayout:
	var layout: HudLayout = HudLayout.new()
	var pixel_ratio: float = density if density > 0.0 else display_density()
	var logical: Vector2 = viewport / pixel_ratio
	var aspect: float = viewport.x / maxf(viewport.y, 1.0)
	var wide_zoom: float = minf(logical.x / WIDE_DESIGN.x, logical.y / WIDE_DESIGN.y)
	var zoom: float = 1.0
	if aspect < TALL_ASPECT:
		layout.shape = Shape.TALL
		zoom = clampf(minf(logical.x / TALL_DESIGN.x, logical.y / TALL_DESIGN.y), 0.5, PHONE_MAX_ZOOM)
	elif wide_zoom < WIDE_MIN_ZOOM and aspect >= SIDE_ASPECT:
		layout.shape = Shape.SIDE
		zoom = clampf(minf(logical.x / SIDE_DESIGN.x, logical.y / SIDE_DESIGN.y), 0.5, PHONE_MAX_ZOOM)
	else:
		layout.shape = Shape.WIDE
		zoom = clampf(wide_zoom, 0.4, 2.0)
	layout.ui_scale = pixel_ratio * zoom
	layout.size = viewport / layout.ui_scale
	# Cutouts and system bars, converted to HUD units: (left, top, right, bottom).
	var insets: Vector4 = display_insets(viewport) / layout.ui_scale
	match layout.shape:
		Shape.TALL:
			layout._solve_tall(insets)
		Shape.SIDE:
			layout._solve_side(insets)
		_:
			layout._solve_wide()
	return layout

## Window pixels per logical pixel on the main screen: about 2.6 on a current phone, 1 on a
## desktop monitor. Never below 1, so a display that reports nothing keeps the desktop sizes.
static func display_density() -> float:
	if OS.has_feature("mobile"):
		# Android and iOS define a logical pixel as 1/160 inch. Their reported scale is
		# not used: Android rounds it to a bucket and caps it by the project's window size.
		return maxf(1.0, float(DisplayServer.screen_get_dpi()) / MOBILE_BASE_DPI)
	# Desktop and browsers report the ratio directly (the browser's device pixel ratio).
	return maxf(1.0, DisplayServer.screen_get_scale())

## Window-pixel margins the display reserves for cutouts and system bars, as
## (left, top, right, bottom). Only phones and tablets report them; each is capped.
static func display_insets(viewport: Vector2) -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var safe: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	if safe.size.x <= 0.0 or safe.size.y <= 0.0:
		return Vector4.ZERO
	var limit: Vector2 = viewport * MAX_INSET
	return Vector4(
		clampf(safe.position.x, 0.0, limit.x),
		clampf(safe.position.y, 0.0, limit.y),
		clampf(viewport.x - safe.end.x, 0.0, limit.x),
		clampf(viewport.y - safe.end.y, 0.0, limit.y))

# --- Member functions ---

## Die column spacing in HUD units once the stage has fitted the table into `rect`.
func column_spacing(rect: Vector2) -> float:
	return StageCamera.fit(rect, table_half_width) * COLUMN_SPACING

## Desktop: goal, scoreboard, and rack share one band; purse, columns, and actions share the tray.
func _solve_wide() -> void:
	var margin: float = 28.0
	var tray_top: float = size.y - 160.0
	status = Rect2(margin, 30.0, STATUS_WIDTH, STATUS_HEIGHT)
	board = Rect2((size.x - ScoreBoard.ROW_SIZE.x) * 0.5, 24.0, ScoreBoard.ROW_SIZE.x, ScoreBoard.ROW_SIZE.y)
	rack_card = 98.0
	rack = Vector2(size.x - margin - (rack_card * 4.0 + rack_gap * 3.0), 32.0)
	table = Rect2(0.0, 168.0, size.x, tray_top - 168.0)
	purse = Vector2(margin, tray_top + 26.0)
	hint = Rect2(margin, tray_top + 86.0, 250.0, 54.0)
	secondary = Rect2(size.x - margin - 176.0, tray_top + 12.0, 176.0, 62.0)
	primary = Rect2(size.x - margin - 176.0, tray_top + 84.0, 176.0, 62.0)
	# The settings button sits in the band's free gap, right of the goal.
	settings = Rect2(status.end.x + 14.0, status.position.y, GEAR, GEAR)

## Phone landscape: the table takes the full height between two rails. Status reads on the
## left; the rack and both actions sit on the right, under the thumb that presses them.
func _solve_side(insets: Vector4) -> void:
	var left: float = maxf(14.0, insets.x + 8.0)
	var right: float = maxf(14.0, insets.z + 8.0)
	var top: float = maxf(8.0, insets.y + 6.0)
	var bottom: float = size.y - maxf(8.0, insets.w + 6.0)
	var gutter: float = 10.0
	dock_gap = 2.0
	# The table is as tall as the columns under it allow. Each rail is only as wide as its
	# contents need: a readable status card on the left; on the right a 2 × 2 rack of
	# tiles the size of the bonus tiles under the table (one kind of object, one size).
	var left_rail: float = 188.0
	var right_min: float = 140.0
	var room: Vector2 = Vector2(size.x - left - right - left_rail - right_min - gutter * 2.0, bottom - top)
	var table_size: Vector2 = _table_above_docks(room)
	rack_columns = 2
	rack_card = DieDock.tile_side(column_spacing(table_size))
	rack_gap = 6.0
	var right_rail: float = maxf(right_min, rack_card * 2.0 + rack_gap + 28.0)
	var between: float = size.x - left - right - left_rail - right_rail - gutter * 2.0
	table = Rect2(left + left_rail + gutter + (between - table_size.x) * 0.5, top, table_size.x, table_size.y)
	# Left rail: goal or sign, scoreboard, purse.
	status_scale = minf(1.0, left_rail / 220.0)
	status = Rect2(left, top, left_rail, STATUS_HEIGHT * status_scale)
	purse = Vector2(left, bottom - PURSE_SIZE.y)
	settings = Rect2(left + PURSE_SIZE.x + GEAR_GAP, bottom - GEAR, GEAR, GEAR)
	var slot: Rect2 = Rect2(left, status.end.y + 8.0, left_rail, purse.y - 8.0 - status.end.y - 8.0)
	board_stacked = true
	board_scale = minf(SIDE_BOARD_SCALE, minf(slot.size.x / ScoreBoard.STACK_SIZE.x, slot.size.y / ScoreBoard.STACK_SIZE.y))
	board = Rect2(slot.get_center() - ScoreBoard.STACK_SIZE * board_scale * 0.5, ScoreBoard.STACK_SIZE * board_scale)
	# Right rail: rack on top, the two actions at the bottom corner.
	var rail_x: float = size.x - right - right_rail
	rack = Vector2(rail_x + (right_rail - rack_card * 2.0 - rack_gap) * 0.5, top + 4.0)
	var rack_bottom: float = rack.y + rack_card * 2.0 + rack_gap
	var action_height: float = clampf((bottom - rack_bottom - 12.0 - 8.0) * 0.5, 48.0, 62.0)
	primary = Rect2(rail_x, bottom - action_height, right_rail, action_height)
	secondary = Rect2(rail_x, primary.position.y - 8.0 - action_height, right_rail, action_height)

## Portrait: everything the player touches hangs from the bottom edge (actions, die
## columns, table, rack); the goal and scoreboard fill what is left above.
func _solve_tall(insets: Vector4) -> void:
	var margin: float = 16.0
	var top: float = maxf(12.0, insets.y + 6.0)
	var bottom: float = size.y - maxf(14.0, insets.w + 8.0)
	var inner: float = size.x - margin * 2.0
	# The settings button takes the top-right corner; the status beside it is that much narrower.
	settings = Rect2(size.x - margin - GEAR, top, GEAR, GEAR)
	var status_room: float = inner - GEAR - GEAR_GAP
	dock_gap = 4.0
	table_half_width = TALL_HALF_WIDTH
	# Bottom row: purse, then the two actions sharing the rest of the width.
	var action_height: float = 68.0
	var actions_top: float = bottom - action_height
	purse = Vector2(margin, actions_top + (action_height - PURSE_SIZE.y) * 0.5)
	var actions_left: float = margin + PURSE_SIZE.x + 8.0
	var action_width: float = (size.x - margin - actions_left - 8.0) * 0.5
	secondary = Rect2(actions_left, actions_top, action_width, action_height)
	primary = Rect2(actions_left + action_width + 8.0, actions_top, action_width, action_height)
	# Joker tiles are the size of the bonus tiles under the table: one kind of object, one
	# size. Until the table is fitted, assume the largest tile the window's width allows.
	rack_card = DieDock.tile_side(column_spacing(Vector2(size.x, size.y)))
	# Status: goal over scoreboard on phones; side by side once the window is wide enough.
	var in_row: bool = status_room >= (STATUS_WIDTH + ScoreBoard.ROW_SIZE.x + 16.0) * 0.72
	var block_scale: float = minf(1.0, (status_room - 16.0) / (STATUS_WIDTH + ScoreBoard.ROW_SIZE.x)) if in_row else 1.0
	var block_height: float = ScoreBoard.ROW_SIZE.y * block_scale if in_row else STATUS_HEIGHT * TALL_GOAL_SCALE + 8.0 + ScoreBoard.ROW_SIZE.y
	var smallest_block: float = block_height if in_row else block_height * 0.7
	# The table and its columns take what the rack and the smallest status leave.
	var room: Vector2 = Vector2(size.x, actions_top - 10.0 - top - smallest_block - 10.0 - rack_card - 8.0)
	var table_size: Vector2 = _table_above_docks(room)
	var spacing: float = column_spacing(table_size)
	var docks_top: float = actions_top - 10.0 - DieDock.footprint(spacing).y
	table = Rect2((size.x - table_size.x) * 0.5, docks_top - dock_gap - table_size.y, table_size.x, table_size.y)
	# The rack shares the die columns' pitch, so both rows of tiles read as one grid.
	rack_card = DieDock.tile_side(spacing)
	rack_gap = clampf(spacing - rack_card, 4.0, 12.0)
	rack = Vector2((size.x - rack_card * 4.0 - rack_gap * 3.0) * 0.5, table.position.y - 8.0 - rack_card)
	var block_room: float = rack.y - 10.0 - top
	if in_row:
		status_scale = block_scale
		board_scale = block_scale
		var row_width: float = (STATUS_WIDTH + 16.0 + ScoreBoard.ROW_SIZE.x) * block_scale
		status = Rect2(margin + (status_room - row_width) * 0.5, top + 6.0 * block_scale, STATUS_WIDTH * block_scale, STATUS_HEIGHT * block_scale)
		board = Rect2(status.end.x + 16.0 * block_scale, top, ScoreBoard.ROW_SIZE.x * block_scale, ScoreBoard.ROW_SIZE.y * block_scale)
	else:
		block_scale = clampf(block_room / block_height, 0.7, 1.0)
		# The goal is a slim bar across the top; the scoreboard keeps the larger share.
		status_scale = block_scale * TALL_GOAL_SCALE
		board_scale = minf(block_scale, inner / ScoreBoard.ROW_SIZE.x)
		var status_width: float = minf(status_room, 440.0)
		status = Rect2(margin + (status_room - status_width) * 0.5, top, status_width, STATUS_HEIGHT * status_scale)
		# The scoreboard stays next to the rack and the dice it describes; spare height
		# opens between it and the goal.
		var board_size: Vector2 = ScoreBoard.ROW_SIZE * board_scale
		board = Rect2((size.x - board_size.x) * 0.5, maxf(status.end.y + 6.0, rack.y - 10.0 - board_size.y), board_size.x, board_size.y)

## Largest table that fits `room` together with the die columns hanging under it.
## Column height depends on the table's size, so two passes settle it.
func _table_above_docks(room: Vector2) -> Vector2:
	var depth: float = StageCamera.TABLE_TOP - StageCamera.TABLE_BOTTOM
	var fitted: Vector2 = Vector2(room.x, room.x * depth / (table_half_width * 2.0))
	for pass_index: int in 3:
		var docks: float = DieDock.footprint(column_spacing(fitted)).y + dock_gap
		var height: float = maxf(40.0, minf(room.x * depth / (table_half_width * 2.0), room.y - docks))
		fitted = Vector2(height * table_half_width * 2.0 / depth, height)
	return fitted
