extends Camera3D
class_name StageCamera
## Orthographic table camera: frames the table inside the HUD's free rectangle and
## adds decaying trauma shake through lens offsets, so framing and shake never fight.

# --- Constants ---

## Table half width in world units, including outline and a small breathing margin.
const TABLE_HALF_WIDTH: float = 12.45
## Highest table point along the camera's screen-up axis (back rail outline).
const TABLE_TOP: float = 7.85
## Lowest framed point along the camera's screen-up axis (front apron, feet, ground shadow).
const TABLE_BOTTOM: float = -8.6
## Distance kept between the camera and the plane it frames; orthographic, so not visible.
const DISTANCE: float = 30.0

# --- Member variables ---

## Removes shake entirely; framing is unaffected.
@export var reduced_motion: bool = false
## Largest shake offset as a fraction of the visible width.
@export_range(0.0, 0.05, 0.001) var shake_amount: float = 0.012
## Window-pixel rectangle the table occupied after the last `frame()` call.
var framed_rect: Rect2
## Current shake energy, 0–1; offsets follow its square for a soft tail.
var _trauma: float = 0.0
## Free-running clock for the two incommensurate shake oscillators.
var _clock: float = 0.0

# --- Member functions ---

## Fit the whole table into `rect` (viewport pixels), centered in any spare room.
## Returns pixels per world unit so the HUD can align columns with the dice.
func frame(rect: Rect2, viewport: Vector2) -> float:
	var pixels_per_unit: float = minf(rect.size.x / (TABLE_HALF_WIDTH * 2.0), rect.size.y / (TABLE_TOP - TABLE_BOTTOM))
	size = viewport.x / pixels_per_unit
	keep_aspect = Camera3D.KEEP_WIDTH
	var right: Vector3 = global_basis.x
	var up: Vector3 = global_basis.y
	var forward: Vector3 = -global_basis.z
	var framed_size: Vector2 = Vector2(TABLE_HALF_WIDTH * 2.0, TABLE_TOP - TABLE_BOTTOM) * pixels_per_unit
	framed_rect = Rect2(rect.get_center() - framed_size * 0.5, framed_size)
	# Screen center in table-plane coordinates, chosen so the table lands on `framed_rect`.
	var center_right: float = -(framed_rect.get_center().x - viewport.x * 0.5) / pixels_per_unit
	var center_up: float = TABLE_BOTTOM + (framed_rect.end.y - viewport.y * 0.5) / pixels_per_unit
	global_position = right * center_right + up * center_up - forward * DISTANCE
	return pixels_per_unit

## Add shake energy; repeated hits accumulate up to a readable ceiling.
func add_trauma(amount: float) -> void:
	if not reduced_motion:
		_trauma = minf(1.0, _trauma + amount)

## Process callback: decay trauma and move only the lens offsets.
func _process(delta: float) -> void:
	_clock += delta
	_trauma = maxf(0.0, _trauma - delta * 1.9)
	var power: float = _trauma * _trauma * shake_amount * size
	h_offset = sin(_clock * 57.0) * cos(_clock * 23.0) * power
	v_offset = sin(_clock * 49.0 + 1.7) * cos(_clock * 31.0) * power
