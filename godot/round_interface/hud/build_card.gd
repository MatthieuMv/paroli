extends Control
class_name BuildCard
## Toy tile for one owned bonus or Joker: idle sway, hover lift, eligibility shine, trigger punch.
## Presentation only; it never evaluates the definition it displays.

# --- Signals ---

## Pointer entered or left an occupied card; the HUD owns the tooltip.
signal hover_changed(card: BuildCard, hovered: bool)
## Primary press or tap on an occupied card; the HUD pins its explanation.
signal pressed(card: BuildCard)
## Primary press or tap on a free slot; shop screens use free slots as destinations.
signal slot_pressed(card: BuildCard)

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
## False when a containing widget (a die dock) owns pointer input for this tile.
@export var interactive: bool = true
## Removes sway, tilt, and spring oscillation; state cues remain visible.
var reduced_motion: bool = false
## Whether the pending play would trigger this card.
var _eligible: bool = false
## A tile showing a text mark instead of a definition (an unknown shop item).
var _marked: bool = false
## Whether this free slot is offered as a destination for something the player holds.
var _target: bool = false
## Whether a dragged item is currently over this destination.
var _target_hot: bool = false
## Whether the player has picked this tile up.
var _picked: bool = false
## Seconds since the last refusal shake; large values mean the tile is still.
var _shake_clock: float = 10.0
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
## Butter halo behind the tile, shown while the pending play would trigger it.
@onready var _glow: Panel = $Body/Glow
## Text mark for tiles that stand for something unknown.
@onready var _mark: Label = $Body/Mark
## Butter outline over a free slot that can receive what the player holds.
@onready var _target_outline: Panel = $Target

# --- Member functions ---

## Ready callback: connect pointer feedback and start empty.
func _ready() -> void:
	_phase = float(get_index()) * 1.37
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	mouse_entered.connect(_on_pointer.bind(true))
	mouse_exited.connect(_on_pointer.bind(false))
	clear()

## Display an owned definition under its runtime identity.
func show_definition(definition_: IllustratedDefinition, owner_id_: StringName) -> void:
	definition = definition_
	owner_id = owner_id_
	_marked = false
	_mark.hide()
	_art.texture = definition_.load_artwork()
	_slot.hide()
	_body.show()
	set_target(false)
	set_eligible(false)

## Show a tile that carries a short text mark instead of artwork, such as an unknown item.
func show_mark(text: String, owner_id_: StringName = &"") -> void:
	definition = null
	owner_id = owner_id_
	_marked = true
	_art.texture = null
	_mark.text = text
	_mark.show()
	_slot.hide()
	_body.show()
	set_target(false)
	set_eligible(false)

## Return to the free-slot outline.
func clear() -> void:
	definition = null
	owner_id = &""
	_marked = false
	_picked = false
	_art.texture = null
	_mark.hide()
	_body.hide()
	_slot.show()
	_glow.hide()
	_eligible = false
	_hover_target = 0.0

## Tint the free-slot outline for the surface it sits on; faint on any scheme. Each tile
## owns its outline, so tiles on the wallpaper and tiles on the felt can differ.
func set_slot_ink(ink: Color) -> void:
	var style: StyleBoxFlat = _slot.get_theme_stylebox("panel") as StyleBoxFlat
	# Cream needs a little more opacity than plum to read as the same quiet outline.
	var boost: float = 1.0 if ink.get_luminance() < 0.5 else 1.8
	style.bg_color = Color(ink, 0.035 * boost)
	style.border_color = Color(ink, 0.13 * boost)

## Report whether the slot is free.
func is_empty() -> bool:
	return definition == null and not _marked

## Offer or withdraw this free slot as a destination; occupied tiles ignore it.
## `hot` marks the destination a dragged item is over: solid and slightly larger.
func set_target(enabled: bool, hot: bool = false) -> void:
	_target = enabled and is_empty()
	_target_hot = _target and hot
	_target_outline.visible = _target
	_target_outline.pivot_offset = size * 0.5
	_target_outline.scale = Vector2.ONE * (1.08 if _target_hot else 1.0)

## Lift the tile while the player holds it.
func set_picked(enabled: bool) -> void:
	_picked = enabled and not is_empty()

## Shake sideways to refuse an action.
func refuse() -> void:
	_shake_clock = 0.0

## Start or stop the eligibility cue for the pending play: halo, lift, breathing, and sweep.
## Returns true when the cue has just started, so the host can mark the moment.
func set_eligible(enabled: bool) -> bool:
	var started: bool = enabled and not _eligible
	_eligible = enabled
	_glow.visible = enabled
	if started:
		_shine_clock = 0.0
		# A small pop announces the change; the halo keeps it visible afterwards.
		_punch_clock = 0.0
		_punch_strength = 0.6
	if not enabled:
		_set_shine(-1.0)
	return started

## Drive the hover lift from outside, for tiles whose container owns pointer input.
func set_hovered(hovered: bool) -> void:
	_hover_target = 1.0 if hovered and not is_empty() else 0.0

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
	_clock += delta
	if _target:
		_target_outline.modulate.a = 1.0 if reduced_motion or _target_hot else lerpf(0.45, 1.0, 0.5 + 0.5 * sin(_clock * 5.0))
	if is_empty():
		return
	_shake_clock += delta
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
		# Bounded, so a pointer left far away (a finger lifted before a rotation) cannot
		# spin the tile.
		tilt = clampf(get_local_mouse_position().x / maxf(size.x, 1.0) - 0.5, -0.5, 0.5) * 0.2 * _hover
	# An eligible tile rides higher and breathes, so it reads even between sweeps.
	var breath: float = 0.0
	if _eligible:
		breath = 1.0 if reduced_motion else 0.5 + 0.5 * sin(_clock * 4.2)
		_glow.modulate.a = lerpf(0.6, 1.0, breath)
	var lift: float = _hover * 5.0 + (6.0 if _eligible else 0.0) + (10.0 if _picked else 0.0)
	# A refusal is a short, damped sideways shake.
	var shake: float = 0.0
	if _shake_clock < 0.45:
		shake = sin(_shake_clock * 46.0) * exp(-_shake_clock * 9.0) * (2.0 if reduced_motion else 9.0)
	_body.pivot_offset = size * 0.5
	_body.position = Vector2(shake, sway * 1.5 - lift)
	_body.rotation = sway * 0.018 + tilt + spring * 0.11
	_body.scale = Vector2.ONE * (1.0 + _hover * 0.07 + (0.06 if _picked else 0.0) + (0.035 * breath if _eligible and not reduced_motion else 0.0)) + Vector2(spring * 0.26, spring * 0.2)
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
	set_hovered(entered)
	hover_changed.emit(self, entered)

## A primary press or tap asks the HUD to pin this card's explanation.
func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		if is_empty():
			slot_pressed.emit(self)
		else:
			pressed.emit(self)
		accept_event()
