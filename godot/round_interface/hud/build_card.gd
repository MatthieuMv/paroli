extends Control
class_name BuildCard
## Toy tile for one owned bonus or Joker: idle sway, hover lift, eligibility shine, trigger punch.
## Presentation only; it never evaluates the definition it displays.

# --- Signals ---

## Pointer entered or left an occupied card; the HUD owns the tooltip.
signal hover_changed(card: BuildCard, hovered: bool)

# --- Constants ---

## Seconds between eligibility sweeps, including the pause after each pass.
const SHINE_PERIOD: float = 1.9
## Seconds one sweep takes to cross the artwork.
const SHINE_SECONDS: float = 0.75

# --- Member variables ---

## Runtime owner identity (`bonus:die_2`, `joker:<id>`); empty while the slot is free.
var owner_id: StringName
## Displayed definition; null while the slot is free.
var definition: IllustratedDefinition
## Removes sway, tilt, and spring oscillation; state cues remain visible.
var reduced_motion: bool = false
## Whether the pending play would trigger this card.
var _eligible: bool = false
## Smoothed hover amount, 0–1.
var _hover: float = 0.0
## Hover goal set by pointer signals.
var _hover_target: float = 0.0
## Idle clock; a per-card phase keeps neighbors out of step.
var _clock: float = 0.0
## Phase offset derived from the node's position among its siblings.
var _phase: float = 0.0
## Seconds since the last trigger; large values mean the spring is at rest.
var _punch_clock: float = 10.0
## Strength of the current trigger spring.
var _punch_strength: float = 0.0
## Clock for the repeating eligibility sweep.
var _shine_clock: float = 0.0
## Ghost outline shown while the slot is free.
@onready var _slot: Panel = $Slot
## Animated tile; layout stays on the root so transforms never disturb neighbors.
@onready var _body: Control = $Body
## Illustration with the instance-local shine material.
@onready var _art: TextureRect = $Body/Art

# --- Member functions ---

## Ready callback: connect pointer feedback and start empty.
func _ready() -> void:
	_phase = float(get_index()) * 1.37
	mouse_entered.connect(_on_pointer.bind(true))
	mouse_exited.connect(_on_pointer.bind(false))
	clear()

## Display an owned definition under its runtime identity.
func show_definition(definition_: IllustratedDefinition, owner_id_: StringName) -> void:
	definition = definition_
	owner_id = owner_id_
	_art.texture = definition_.load_artwork()
	_slot.hide()
	_body.show()
	set_eligible(false)

## Return to the free-slot outline.
func clear() -> void:
	definition = null
	owner_id = &""
	_art.texture = null
	_body.hide()
	_slot.show()
	_eligible = false
	_hover_target = 0.0

## Tint the free-slot outline for the wall it sits on; faint on any scheme.
func set_slot_ink(ink: Color) -> void:
	var style: StyleBoxFlat = _slot.get_theme_stylebox("panel") as StyleBoxFlat
	# Cream needs a little more opacity than plum to read as the same quiet outline.
	var boost: float = 1.0 if ink.get_luminance() < 0.5 else 1.8
	style.bg_color = Color(ink, 0.035 * boost)
	style.border_color = Color(ink, 0.13 * boost)

## Report whether the slot is free.
func is_empty() -> bool:
	return definition == null

## Start or stop the eligibility cue for the pending play.
func set_eligible(enabled: bool) -> void:
	if enabled and not _eligible:
		_shine_clock = 0.0
	_eligible = enabled
	if not enabled:
		_set_shine(-1.0)

## Punch the tile when its effect resolves during scoring.
func trigger(strength: float = 1.0) -> void:
	_punch_clock = 0.0
	_punch_strength = strength
	_shine_clock = 0.0

## Global point just outside the tile, for popups that must not cover the artwork.
func anchor(below: bool) -> Vector2:
	var local: Vector2 = Vector2(size.x * 0.5, size.y + 6.0 if below else -6.0)
	return get_global_transform() * local

## Process callback: compose idle, hover, eligibility, and trigger motion on the body only.
func _process(delta: float) -> void:
	if is_empty():
		return
	_clock += delta
	_punch_clock += delta
	_hover = lerpf(_hover, _hover_target, 1.0 - exp(-delta * 16.0))
	var sway: float = 0.0 if reduced_motion else sin(_clock * 1.15 + _phase)
	var spring: float = 0.0
	if _punch_clock < 1.2:
		spring = exp(-_punch_clock * 6.5) * _punch_strength
		if not reduced_motion:
			spring *= cos(_punch_clock * 24.0)
	var tilt: float = 0.0
	if not reduced_motion and _hover > 0.01:
		tilt = (get_local_mouse_position().x / maxf(size.x, 1.0) - 0.5) * 0.2 * _hover
	var lift: float = _hover * 5.0 + (3.0 if _eligible else 0.0)
	_body.pivot_offset = size * 0.5
	_body.position = Vector2(0.0, sway * 1.5 - lift)
	_body.rotation = sway * 0.018 + tilt + spring * 0.11
	_body.scale = Vector2.ONE * (1.0 + _hover * 0.07) + Vector2(spring * 0.26, spring * 0.2)
	if _eligible:
		_shine_clock += delta
		_set_shine(fmod(_shine_clock, SHINE_PERIOD) / SHINE_SECONDS)
	elif _punch_clock < SHINE_SECONDS:
		# A single sweep accompanies a trigger even when the cue was not running.
		_set_shine(_punch_clock / SHINE_SECONDS)
	else:
		_set_shine(-1.0)

## Forward the sweep position to this card's own material.
func _set_shine(progress: float) -> void:
	(_art.material as ShaderMaterial).set_shader_parameter("progress", progress)

## Hover only matters for occupied cards.
func _on_pointer(entered: bool) -> void:
	if is_empty():
		return
	_hover_target = 1.0 if entered else 0.0
	hover_changed.emit(self, entered)
