extends Control
class_name ScoreBoard
## Combination plate with the Points × Mult readouts and the revealed total.
## It animates host-supplied values; scoring arithmetic and timing belong to the host.

# --- Member variables ---

## Removes springs, digit rolls, and travel; values still update in order.
var reduced_motion: bool = false
## Points currently drawn; tweened for a short digit roll.
var shown_points: float = 0.0:
	set(value):
		shown_points = value
		_write(_points, value, true)
## Mult currently drawn; fractional once percentages apply.
var shown_mult: float = 0.0:
	set(value):
		shown_mult = value
		_write(_mult, value, false)
## Total currently drawn during the reveal count-up.
var shown_total: float = 0.0:
	set(value):
		shown_total = value
		if is_node_ready():
			_total_value.text = Juice.number(roundf(value))
			Juice.fit(_total_value, 46, 22)
## Whether the tiles currently show numbers instead of the resting dash.
var _has_values: bool = false
## Digit-roll tweens, one per readout, replaced by newer values.
var _rolls: Dictionary[StringName, Tween] = {}
## Resting position of the total plate inside this widget; flights return here.
var _total_home: Vector2
## Pill naming the recognized combination, or a short hint.
@onready var _plate: PanelContainer = %Plate
## Text inside the plate.
@onready var _plate_text: Label = %PlateText
## Sky tile.
@onready var _points_tile: Control = %PointsTile
## Cherry tile.
@onready var _mult_tile: Control = %MultTile
## Points readout.
@onready var _points: Label = %Points
## Mult readout.
@onready var _mult: Label = %Mult
## Multiplication sign between the tiles.
@onready var _times: Label = %Times
## Shared percentage pool, shown only while it is nonzero.
@onready var _percent: PanelContainer = %Percent
## Text inside the percentage pill.
@onready var _percent_text: Label = %PercentText
## Revealed total plate, covering the tiles after the final beat.
@onready var _total: Control = %Total
## Number inside the total plate.
@onready var _total_value: Label = %TotalValue

# --- Member functions ---

## Ready callback: apply semantic keyword tones and start at rest.
func _ready() -> void:
	_total_home = _total.position
	for label: Label in [%Points, %PointsTitle]:
		_tone(label, &"points")
	for label: Label in [%Mult, %MultTitle, %PercentText]:
		_tone(label, &"mult")
	show_hint("")

## Localized captions for the two factors.
func set_titles(points_title: String, mult_title: String) -> void:
	(%PointsTitle as Label).text = points_title.to_upper()
	(%MultTitle as Label).text = mult_title.to_upper()

## The multiplication sign sits on the wallpaper, so it follows the wall's ink.
func set_wall_ink(ink: Color) -> void:
	_times.add_theme_color_override("font_color", ink)

## Show guidance instead of a combination; the tiles rest on a dash.
func show_hint(text: String) -> void:
	_has_values = false
	_kill_rolls()
	_set_plate(text, true)
	_points.text = "–"
	_mult.text = "–"
	_percent.hide()
	_points_tile.modulate.a = 0.55
	_mult_tile.modulate.a = 0.55
	_times.modulate.a = 0.4

## Show the recognized combination with its base values only (D-023).
func show_combination(title: String, base_points: int, base_mult: int, emphasize: bool) -> void:
	_has_values = true
	_kill_rolls()
	_set_plate(title, false)
	_percent.hide()
	_points_tile.modulate.a = 1.0
	_mult_tile.modulate.a = 1.0
	_times.modulate.a = 1.0
	shown_points = float(base_points)
	shown_mult = float(base_mult)
	if emphasize and not reduced_motion:
		Juice.punch(_plate, 0.2, 0.5, 0.05)
		Juice.punch(_points_tile, 0.07, 0.35)
		Juice.punch(_mult_tile, 0.07, 0.35)

## Step the points readout; `strength` scales the tile's reaction.
func set_points(value: int, strength: float) -> void:
	_roll(&"shown_points", float(value))
	_hit(_points_tile, strength, -1.0)

## Step the flat Mult readout.
func set_mult(value: float, strength: float) -> void:
	_roll(&"shown_mult", value)
	_hit(_mult_tile, strength, 1.0)

## Show the running percentage pool beside the Mult tile.
func set_percent(value: int, strength: float) -> void:
	_percent_text.text = Juice.signed(float(value)) + "%"
	_percent.reset_size()
	var first: bool = not _percent.visible
	_percent.visible = value != 0
	if reduced_motion:
		return
	if first:
		Juice.pop_in(_percent)
	else:
		Juice.punch(_percent, 0.25 * strength, 0.4, 0.08)

## Fold the percentage pool into Mult: the pill slams into the tile and the readout jumps.
func merge_percent(final_mult: float) -> void:
	_roll(&"shown_mult", final_mult)
	_hit(_mult_tile, 1.5, 1.0)
	if reduced_motion:
		_percent.hide()
		return
	_percent.pivot_offset = _percent.size * 0.5
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_percent, "scale", Vector2.ONE * 0.2, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(_percent, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(_rest_percent)

## Reveal the signed total over the tiles and count up to it.
func reveal_total(value: float, seconds: float) -> void:
	_total.position = _total_home
	_total.scale = Vector2.ONE
	_total.modulate.a = 1.0
	shown_total = 0.0
	if reduced_motion:
		_total.show()
		shown_total = value
		return
	# The factors lean in before the total lands on top of them.
	Juice.punch(_points_tile, 0.14, 0.3, -0.06)
	Juice.punch(_mult_tile, 0.14, 0.3, 0.06)
	Juice.pop_in(_total, 0.3)
	_roll(&"shown_total", value, seconds)

## Emphasize the finished total once its count-up lands.
func punch_total(strength: float) -> void:
	if not reduced_motion:
		Juice.punch(_total, 0.16 * strength, 0.5, 0.04)

## Send the total plate to a global point, shrinking as it travels, then hide it.
func fly_total(target: Vector2, seconds: float) -> void:
	if reduced_motion:
		_total.hide()
		return
	_total.pivot_offset = _total.size * 0.5
	var start: Vector2 = _total.global_position
	# Global position refers to the unscaled top-left; aim the plate's center at the target.
	var end: Vector2 = target - (_total.get_global_transform().basis_xform(_total.size) * 0.5)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_method(_fly_step.bind(start, end), 0.0, 1.0, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_total, "scale", Vector2.ONE * 0.3, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_total, "modulate:a", 0.0, seconds * 0.25).set_delay(seconds * 0.75)
	tween.chain().tween_callback(_total.hide)

## Fade the total away in place, for plays that credit nothing.
func drop_total(seconds: float) -> void:
	if reduced_motion:
		_total.hide()
		return
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_total, "position:y", _total_home.y + 26.0, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_total, "modulate:a", 0.0, seconds)
	tween.chain().tween_callback(_total.hide)

## Global top-center of a tile, where increments should aim.
func tile_anchor(mult: bool) -> Vector2:
	var tile: Control = _mult_tile if mult else _points_tile
	return tile.get_global_transform() * Vector2(tile.size.x * 0.5, 0.0)

## Arc the plate slightly upward on its way to the goal meter.
func _fly_step(progress: float, start: Vector2, end: Vector2) -> void:
	_total.global_position = start.lerp(end, progress) + Vector2(0.0, -46.0 * sin(progress * PI))

## Restore the hidden pill for the next play.
func _rest_percent() -> void:
	_percent.hide()
	_percent.scale = Vector2.ONE
	_percent.modulate.a = 1.0

## Recenter the plate around its new text.
func _set_plate(text: String, muted: bool) -> void:
	_plate_text.text = text
	_plate.visible = not text.is_empty()
	_plate.modulate.a = 0.62 if muted else 1.0
	_plate.reset_size()
	_plate.position.x = (size.x - _plate.size.x) * 0.5

## Roll one readout toward a value; integer steps never show invented fractions.
func _roll(property: StringName, value: float, seconds: float = 0.16) -> void:
	if _rolls.has(property):
		_rolls[property].kill()
	if reduced_motion:
		if property == &"shown_points":
			shown_points = value
		elif property == &"shown_mult":
			shown_mult = value
		else:
			shown_total = value
		return
	var tween: Tween = create_tween()
	tween.tween_property(self, NodePath(String(property)), value, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_rolls[property] = tween

## Stop pending digit rolls before an immediate value replaces them.
func _kill_rolls() -> void:
	for property: StringName in _rolls:
		_rolls[property].kill()
	_rolls.clear()

## Squash, twist, and briefly brighten a tile.
func _hit(tile: Control, strength: float, direction: float) -> void:
	if reduced_motion or strength <= 0.0:
		return
	Juice.punch(tile, 0.13 * strength, 0.42, direction * 0.05 * strength)
	tile.modulate = Color(1.18, 1.18, 1.18)
	tile.create_tween().tween_property(tile, "modulate", Color.WHITE, 0.3)

## Write a readout; whole values while rolling toward whole targets.
func _write(label: Label, value: float, whole: bool) -> void:
	if not is_node_ready() or not _has_values:
		return
	var shown: float = roundf(value) if whole or is_equal_approx(value, roundf(value)) else snappedf(value, 0.01)
	label.text = Juice.number(shown)
	Juice.fit(label, 40, 18)

## Keyword palette role, darkened for cream surfaces, with a matching faux-bold outline.
func _tone(label: Label, role: StringName) -> void:
	label.add_theme_color_override("font_color", KeywordColors.for_role(role))
	label.add_theme_color_override("font_outline_color", KeywordColors.for_role(role))
