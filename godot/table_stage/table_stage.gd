extends Node3D
class_name TableStage
## Shared 3D set for table screens: wallpaper, framed orthographic camera, table, and the
## run's five dice resting on their roll markers. Rounds and the shop instance it so the
## build looks the same everywhere. It owns presentation only: no rules, no selection.

# --- Signals ---

## The wallpaper scheme changed; interfaces recolor the marks they draw on the wall.
signal backdrop_changed

# --- Member variables ---

## Wallpaper color scheme; null keeps the backdrop material's own colors.
@export var backdrop_preset: BackdropPreset:
	set(value):
		backdrop_preset = value
		if is_node_ready():
			_apply_backdrop()
## Wallpaper pattern, independent of the color scheme.
@export var backdrop_motif: StageBackdrop.Motif = StageBackdrop.Motif.SPARKLES:
	set(value):
		backdrop_motif = value
		if is_node_ready():
			_apply_backdrop()
## Removes camera shake and wallpaper drift and makes dice settle immediately.
@export var reduced_motion: bool = false:
	set(value):
		reduced_motion = value
		if is_node_ready():
			_apply_motion()
## Scene-authored table; callers use its marker and palette API.
@onready var table: ParoliTable = $Table
## Framing and shake.
@onready var camera: StageCamera = $Camera
## Native dice by permanent identity (`die_1`…`die_5`), in run order.
var views: Dictionary[StringName, ParoliDie] = {}
## Wallpaper quad behind the table.
@onready var _backdrop: StageBackdrop = $Camera/Backdrop

# --- Member functions ---

## Ready callback: seat the dice on their roll markers and apply authored settings.
func _ready() -> void:
	var positions: PackedVector3Array = table.get_roll_positions()
	for index: int in $Dice.get_child_count():
		var die: ParoliDie = $Dice.get_child(index) as ParoliDie
		die.global_position = positions[index]
		views[StringName("die_%d" % (index + 1))] = die
	_apply_backdrop()
	_apply_motion()

## Dice in run order, for controllers that take a typed array.
func dice() -> Array[ParoliDie]:
	var result: Array[ParoliDie] = []
	for die: ParoliDie in views.values():
		result.append(die)
	return result

## Fit the table into `rect` (window pixels) and keep the wallpaper filling the view.
## Returns pixels per world unit.
func frame(rect: Rect2, viewport: Vector2) -> float:
	var pixels_per_unit: float = camera.frame(rect, viewport)
	_backdrop.cover(camera.size, viewport)
	return pixels_per_unit

## Window-pixel x of each die's roll marker, in run order.
func columns() -> PackedFloat32Array:
	var result: PackedFloat32Array = []
	for marker: Vector3 in table.get_roll_positions():
		result.append(camera.unproject_position(marker).x)
	return result

## Project a point given in table-local space to window pixels.
func project(table_point: Vector3) -> Vector2:
	return camera.unproject_position(table.to_global(table_point))

## Window-pixel rectangle covering a die at rest, for pointer hit tests done in 2D.
func die_rect(die_id: StringName) -> Rect2:
	var die: ParoliDie = views[die_id]
	var center: Vector2 = camera.unproject_position(die.global_position + Vector3.UP * 1.145)
	var reach: float = (camera.unproject_position(die.global_position + camera.global_basis.x * 1.45) - camera.unproject_position(die.global_position)).length()
	return Rect2(center - Vector2.ONE * reach, Vector2.ONE * reach * 2.0)

## Ink for marks drawn straight on the wallpaper: plum on light walls, cream on dark ones.
func wall_ink() -> Color:
	return backdrop_preset.wall_ink if backdrop_preset else GameColors.INK

## Push the wallpaper choice to the backdrop and tell listeners.
func _apply_backdrop() -> void:
	_backdrop.preset = backdrop_preset
	_backdrop.motif = backdrop_motif
	backdrop_changed.emit()

## Push the reduced-motion preference into dice, camera, and wallpaper.
func _apply_motion() -> void:
	for die: ParoliDie in views.values():
		die.reduced_motion = reduced_motion
	camera.reduced_motion = reduced_motion
	_backdrop.reduced_motion = reduced_motion
