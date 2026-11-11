extends Control
class_name ScoreWidget
## Two-factor score readout with ordered, host-authored scoring impacts.

# --- Types ---

## One resolved snapshot. IDs let the host synchronize dice, bonus, and Joker VFX.
class Hit extends RefCounted:
	var id: StringName
	var points: float
	var mult: float
	var strength: float

# --- Signals ---

## Emitted once when a queued source begins its impact.
signal step_started(source_id: StringName)
## Emitted after the source's readout and recoil settle.
signal step_finished(source_id: StringName)
## Emitted once when all pending sources have settled.
signal sequence_finished

# --- Constants ---

## One impact includes anticipation, contact, number roll, and spring recovery.
const DURATION: float = 0.64
## Plum outline matches native dice; spark fill follows keyword palette roles.
const INK: Color = GameColors.INK

# --- Member variables ---

## Reduced motion preserves ordering but removes movement and particles.
@export var reduced_motion: bool = false:
	set(value):
		reduced_motion = value
		if is_node_ready():
			_overdrive.reduced_motion = value
			_update_overdrive(true)
## Last completed host-authored factors; no scoring rules live here.
var points: float = 0.0
var mult: float = 1.0
## Previously banked round points, excluding the combination currently being animated.
var banked_score: float = 0.0
## A zero target disables celebration until the host configures a round.
var target_score: float = 0.0
## Current presentation ratio, including the animated combination contribution.
var score_ratio: float = 0.0
## Latest displayed factors; the effect must follow digit roll, not jump to queued results.
var _readout: Vector2 = Vector2(0.0, 1.0)
## Particle scene lives behind the readouts and owns its own emission state.
@onready var _overdrive: ScoreOverdrive = %Overdrive
## Pending hits belong only to this widget instance.
var _queue: Array[Hit] = []
var _active: Hit
var _elapsed: float = 0.0
var _from: Vector2 = Vector2.ZERO
var _changed: Vector2 = Vector2.ZERO
## Authored tile hierarchy keeps layout independent of animation transforms.
@onready var _points_tile: Control = %PointsTile
@onready var _mult_tile: Control = %MultTile
@onready var _points: Label = %Points
@onready var _mult: Label = %Mult
@onready var _points_delta: Label = %PointsDelta
@onready var _mult_delta: Label = %MultDelta
@onready var _times: Label = %Times

# --- Member functions ---

## Apply shared semantic keyword colors and the initial snapshot.
func _ready() -> void:
	for label: Label in [%Points, %PointsTitle, %PointsDelta]:
		label.add_theme_color_override("font_color", KeywordColors.for_role(&"points"))
	for label: Label in [%Mult, %MultTitle, %MultDelta]:
		label.add_theme_color_override("font_color", KeywordColors.for_role(&"mult"))
	_overdrive.reduced_motion = reduced_motion
	resized.connect(_refresh_numbers)
	set_values(points, mult)

## Cancel pending presentation and immediately establish a new baseline.
func set_values(new_points: float, new_mult: float) -> void:
	assert(is_finite(new_points) and is_finite(new_mult))
	_queue.clear()
	_active = null
	points = new_points
	mult = new_mult
	if is_node_ready():
		_rest()
		_refresh_numbers()
		_update_overdrive(true)
	queue_redraw()

## Supply the banked total and round goal; zero disables VFX. No score is committed here.
func set_round_context(previous_score: float, goal: float) -> void:
	assert(is_finite(previous_score) and is_finite(goal) and previous_score >= 0.0 and goal >= 0.0)
	banked_score = previous_score
	target_score = goal
	if is_node_ready():
		_update_overdrive(goal == 0.0)

## Ratio uses the prospective total: banked points plus the current animated contribution.
func _update_overdrive(immediate: bool = false) -> void:
	var current_score: float = banked_score + maxf(_readout.x * _readout.y, 0.0)
	score_ratio = current_score / target_score if target_score > 0.0 else 0.0
	_overdrive.set_ratio(score_ratio, immediate)

## Queue an absolute resolved snapshot, not an arithmetic modifier. Strength is 0.5–2.
func trigger(source_id: StringName, new_points: float, new_mult: float, strength: float = 1.0) -> void:
	assert(is_finite(new_points) and is_finite(new_mult) and is_finite(strength))
	var hit: Hit = Hit.new()
	hit.id = source_id
	hit.points = new_points
	hit.mult = new_mult
	hit.strength = clampf(strength, 0.5, 2.0)
	_queue.append(hit)

## Let the host gate follow-up presentation without inspecting internal nodes.
func is_playing() -> bool:
	return _active != null or not _queue.is_empty()

## Consume one source at a time, with a readable beat even under reduced motion.
func _process(delta: float) -> void:
	if _active == null:
		if _queue.is_empty():
			return
		_begin_hit()
		# Signal listeners may reset or replace the sequence.
		if _active == null:
			return
	_elapsed += delta
	var duration: float = 0.12 if reduced_motion else DURATION
	var phase: float = clampf(_elapsed / duration, 0.0, 1.0)
	var roll: float = 1.0 if reduced_motion else clampf((phase - 0.12) / 0.38, 0.0, 1.0)
	roll = 1.0 - pow(1.0 - roll, 3.0)
	var readout: Vector2 = _from.lerp(Vector2(_active.points, _active.mult), roll)
	# Integer sources roll whole digits rather than inventing fractional face points.
	if _from.x == floorf(_from.x) and _active.points == floorf(_active.points):
		readout.x = roundf(readout.x)
	if _from.y == floorf(_from.y) and _active.mult == floorf(_active.mult):
		readout.y = roundf(readout.y)
	_write_numbers(readout)
	if not reduced_motion:
		_animate_tile(_points_tile, _points_delta, phase, _changed.x, -1.0)
		_animate_tile(_mult_tile, _mult_delta, phase, _changed.y, 1.0)
		_times.pivot_offset = _times.size * 0.5
		_times.scale = Vector2.ONE * (1.0 + sin(phase * PI) * 0.14 * _active.strength)
	else:
		_rest()
	queue_redraw()
	if phase >= 1.0:
		var completed: StringName = _active.id
		points = _active.points
		mult = _active.mult
		_active = null
		_rest()
		_refresh_numbers()
		step_finished.emit(completed)
		if not is_playing():
			sequence_finished.emit()

## Capture the previous snapshot before notifying the host of this source.
func _begin_hit() -> void:
	_active = _queue.pop_front()
	_elapsed = 0.0
	_from = Vector2(points, mult)
	_changed = Vector2(float(not is_equal_approx(points, _active.points)), float(not is_equal_approx(mult, _active.mult)))
	_points_delta.text = _delta_text(_active.points - points)
	_mult_delta.text = _delta_text(_active.mult - mult)
	step_started.emit(_active.id)

## Brief squash anticipates contact; damped recoil gives the chunky tiles weight.
func _animate_tile(tile: Control, delta_label: Label, phase: float, changed: float, direction: float) -> void:
	var strength: float = _active.strength * changed
	var recoil: float = sin((phase - 0.12) * 18.0) * exp(-maxf(phase - 0.12, 0.0) * 5.0)
	var punch: float = -sin(phase / 0.12 * PI) * 0.08 if phase < 0.12 else recoil * 0.22
	tile.pivot_offset = tile.size * 0.5
	tile.scale = Vector2(1.0 + punch * strength, 1.0 - punch * strength * 0.6)
	tile.rotation = direction * recoil * 0.045 * strength if phase >= 0.12 else 0.0
	tile.modulate = Color.WHITE * (1.0 + maxf(recoil, 0.0) * 0.18 * strength)
	delta_label.position.y = -32.0 - maxf(phase - 0.12, 0.0) * 25.0
	delta_label.modulate.a = sin(clampf((phase - 0.08) / 0.92, 0.0, 1.0) * PI) * changed

## Restore exact resting transforms so repeated sequences cannot accumulate drift.
func _rest() -> void:
	for tile: Control in [_points_tile, _mult_tile, _times]:
		tile.scale = Vector2.ONE
		tile.rotation = 0.0
		tile.modulate = Color.WHITE
	_points_delta.modulate.a = 0.0
	_mult_delta.modulate.a = 0.0

## Draw a brief halo and ink-outlined pip diamonds outside each impacted tile.
func _draw() -> void:
	if _active == null or reduced_motion:
		return
	var phase: float = _elapsed / DURATION
	var burst: float = clampf((phase - 0.12) / 0.7, 0.0, 1.0)
	if burst <= 0.0 or burst >= 1.0:
		return
	for side: int in 2:
		if (side == 0 and _changed.x == 0.0) or (side == 1 and _changed.y == 0.0):
			continue
		var tile: Control = _points_tile if side == 0 else _mult_tile
		var center: Vector2 = tile.position + tile.size * 0.5
		var color: Color = KeywordColors.PALETTE[&"points" if side == 0 else &"mult"]
		color.a = (1.0 - burst) * 0.8
		draw_arc(center, 60.0 + burst * 45.0, 0.0, TAU, 48, color, 2.0, true)
		for index: int in 10:
			var angle: float = TAU * float(index) / 10.0 + side * 0.3
			var offset: Vector2 = Vector2(cos(angle), sin(angle))
			var pos: Vector2 = center + offset * (65.0 + burst * 48.0 * _active.strength)
			var radius: float = (3.0 + float(index % 3)) * (1.0 - burst)
			if radius < 0.4:
				continue
			var diamond: PackedVector2Array = PackedVector2Array([pos + Vector2(0, -radius), pos + Vector2(radius, 0), pos + Vector2(0, radius), pos + Vector2(-radius, 0)])
			draw_colored_polygon(diamond, color)
			diamond.append(diamond[0])
			draw_polyline(diamond, Color(INK, color.a), 1.2, true)

## Refresh from the settled state after layout changes.
func _refresh_numbers() -> void:
	_write_numbers(Vector2(points, mult))

## Fit both readouts without letting digit width change the tile geometry.
func _write_numbers(values: Vector2) -> void:
	_readout = values
	_update_overdrive()
	_points.text = format_number(values.x)
	_mult.text = format_number(values.y)
	for label: Label in [_points, _mult]:
		var font_size: int = 42
		while font_size > 12 and label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x:
			font_size -= 1
		label.add_theme_font_size_override("font_size", font_size)

## Compact signed impact readout, visible only during the active hit.
func _delta_text(value: float) -> String:
	return ("+" if value >= 0.0 else "") + format_number(value)

## Keep fractional Mult readable, with grouping and at most two display decimals.
static func format_number(value: float) -> String:
	var parts: PackedStringArray = String.num(absf(value), 2).split(".")
	var digits: String = parts[0]
	var grouped: String = ""
	for index: int in digits.length():
		if index > 0 and (digits.length() - index) % 3 == 0:
			grouped += " "
		grouped += digits[index]
	if parts.size() > 1:
		var fraction: String = parts[1]
		while fraction.ends_with("0"):
			fraction = fraction.left(-1)
		if not fraction.is_empty():
			grouped += "." + fraction
	return ("−" if value < 0.0 else "") + grouped
