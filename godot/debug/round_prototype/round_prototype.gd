extends Node
class_name RoundPrototype
## Debug host for the round interface: equips fixture builds, owns the run, and chains rounds.
## Targets, sell values, and the unused-play coin rate here are test fixtures, not balance.

# --- Types ---

## One named fixture: equipment plus a first-round target sized to its strength.
class Build:
	extends RefCounted

	# --- Member variables ---

	## Label shown on the debug control.
	var title: String
	## Upgrades installed onto dice 1, 2, 3… in order.
	var upgrades: Array[StringName] = []
	## Bonus per die identity.
	var bonuses: Dictionary[StringName, StringName] = {}
	## Jokers in rack order.
	var jokers: Array[StringName] = []
	## First-round target; later rounds grow from it.
	var target: float = 100.0

	# --- Member functions ---

	## Declare a fixture in one readable expression.
	func _init(title_: String, upgrades_: Array[StringName], bonuses_: Dictionary[StringName, StringName], jokers_: Array[StringName], target_: float) -> void:
		title = title_
		upgrades = upgrades_
		bonuses = bonuses_
		jokers = jokers_
		target = target_

# --- Constants ---

## Each cleared round multiplies the target by this fixture factor.
const TARGET_GROWTH: float = 1.6
## Reveal speeds cycled by the debug control.
const SPEEDS: PackedFloat32Array = [1.0, 1.5, 2.0]
## Wallpaper color schemes to compare: pastel washes, mid-tones, then dark walls.
const BACKDROPS: Array[BackdropPreset] = [
	preload("res://round_interface/backdrop/presets/paper.tres"),
	preload("res://round_interface/backdrop/presets/sand.tres"),
	preload("res://round_interface/backdrop/presets/butter.tres"),
	preload("res://round_interface/backdrop/presets/peach_cream.tres"),
	preload("res://round_interface/backdrop/presets/blush.tres"),
	preload("res://round_interface/backdrop/presets/lavender.tres"),
	preload("res://round_interface/backdrop/presets/sky.tres"),
	preload("res://round_interface/backdrop/presets/mint.tres"),
	preload("res://round_interface/backdrop/presets/lagoon.tres"),
	preload("res://round_interface/backdrop/presets/periwinkle.tres"),
	preload("res://round_interface/backdrop/presets/honey.tres"),
	preload("res://round_interface/backdrop/presets/cocoa.tres"),
	preload("res://round_interface/backdrop/presets/plum_night.tres"),
	preload("res://round_interface/backdrop/presets/deep_lagoon.tres"),
	preload("res://round_interface/backdrop/presets/espresso.tres"),
]
## Captions for RoundBackdrop.Motif values, in enum order.
const MOTIFS: PackedStringArray = ["Plain", "Sparkles", "Dots", "Stripes", "Diamonds"]

# --- Member variables ---

## Reusable round presentation under test.
@onready var _round: RoundInterface = $Round
## Collapsible debug options.
@onready var _panel: PanelContainer = %Panel
## Fixture builds, from a full chain showcase down to bare dice.
var _builds: Array[Build] = [
	Build.new("Showcase", [&"all_for_one", &"odd_master", &"golden_touch"], {&"die_1": &"family_spirit", &"die_2": &"odd_charm", &"die_4": &"pair_partner", &"die_5": &"first_instinct"}, [&"match_master", &"odd_squad", &"momentum", &"extra_time"], 1500.0),
	Build.new("Starter", [&"jackpot"], {&"die_1": &"six_addict"}, [&"bipolarity"], 200.0),
	Build.new("Bare dice", [], {}, [], 100.0),
]
## Selected fixture.
var _build_index: int = 0
## Selected reveal speed.
var _speed_index: int = 0
## Selected wallpaper color scheme.
var _backdrop_index: int = 0
## Selected wallpaper pattern; starts on the round interface's authored default.
var _motif_index: int = RoundBackdrop.Motif.SPARKLES
## Current run's round logic; replaced after a failed round.
var _session: RoundSession
## Rounds cleared in this run, plus one.
var _round_number: int = 1
## Current round target.
var _target: float = 0.0

# --- Member functions ---

## Ready callback: connect debug controls and deal the first round.
func _ready() -> void:
	(%Toggle as Button).pressed.connect(_toggle_panel)
	(%Build as Button).pressed.connect(_next_build)
	(%Restart as Button).pressed.connect(_new_run)
	(%Speed as Button).pressed.connect(_next_speed)
	(%BackdropPrevious as Button).pressed.connect(_step_backdrop.bind(-1))
	(%BackdropNext as Button).pressed.connect(_step_backdrop.bind(1))
	(%Pattern as Button).pressed.connect(_next_motif)
	(%Motion as Button).toggled.connect(_on_motion_toggled)
	(%Sound as Button).toggled.connect(_on_sound_toggled)
	_round.continue_requested.connect(_on_continue_requested)
	_round.busy_changed.connect(_on_busy_changed)
	_refresh_labels()
	_new_run()

## Start a fresh run with the selected fixture.
func _new_run() -> void:
	var build: Build = _builds[_build_index]
	var catalog: EffectsCatalog = EffectsCatalog.new()
	var run: MechanicsRun = MechanicsRun.new(4)
	var errors: PackedStringArray = []
	for id: StringName in build.upgrades:
		errors.append_array(run.install_upgrade(catalog.upgrade(id)))
	for die_id: StringName in build.bonuses:
		errors.append_array(run.equip_bonus(catalog.bonus(build.bonuses[die_id]), die_id, 2))
	for id: StringName in build.jokers:
		errors.append_array(run.add_joker(catalog.joker(id), 3))
	for message: String in errors:
		push_error("Fixture build: " + message)
	_session = RoundSession.new(run)
	_session.coins_per_unused_play = 2
	_round_number = 1
	_target = build.target
	_round.start_round(_session, _round_number, _target)

## Clearing a round raises the target; failing ends the run, so a new one begins.
func _on_continue_requested(succeeded: bool) -> void:
	if not succeeded:
		_new_run()
		return
	_round_number += 1
	_target = roundf(_target * TARGET_GROWTH / 10.0) * 10.0
	_round.start_round(_session, _round_number, _target)

## Show or hide the options without covering the round.
func _toggle_panel() -> void:
	_panel.visible = not _panel.visible

## Cycle fixtures and restart with the new one.
func _next_build() -> void:
	_build_index = (_build_index + 1) % _builds.size()
	_refresh_labels()
	_new_run()

## Cycle reveal speed.
func _next_speed() -> void:
	_speed_index = (_speed_index + 1) % SPEEDS.size()
	_round.tempo = SPEEDS[_speed_index]
	_refresh_labels()

## Step through wallpaper color schemes in either direction, wrapping at the ends.
func _step_backdrop(direction: int) -> void:
	_backdrop_index = posmod(_backdrop_index + direction, BACKDROPS.size())
	_round.backdrop_preset = BACKDROPS[_backdrop_index]
	_refresh_labels()

## Cycle the wallpaper pattern; it combines with any color scheme.
func _next_motif() -> void:
	_motif_index = (_motif_index + 1) % MOTIFS.size()
	_round.backdrop_motif = _motif_index as RoundBackdrop.Motif
	_refresh_labels()

## B and Shift+B step the backdrop, P steps the pattern, so schemes can be compared
## with the debug panel closed.
func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if not key or not key.pressed or key.echo:
		return
	if key.keycode == KEY_B:
		_step_backdrop(-1 if key.shift_pressed else 1)
	elif key.keycode == KEY_P:
		_next_motif()
	else:
		return
	get_viewport().set_input_as_handled()

## Toggle reduced motion across dice, HUD, and reveal.
func _on_motion_toggled(enabled: bool) -> void:
	_round.reduced_motion = enabled

## Toggle sound effects.
func _on_sound_toggled(enabled: bool) -> void:
	_round.muted = not enabled

## A run cannot be replaced in the middle of a throw or reveal.
func _on_busy_changed(busy: bool) -> void:
	(%Build as Button).disabled = busy
	(%Restart as Button).disabled = busy

## Keep control captions in step with the selection.
func _refresh_labels() -> void:
	(%Build as Button).text = "Build: " + _builds[_build_index].title
	(%Speed as Button).text = "Speed ×%s" % String.num(SPEEDS[_speed_index], 1)
	(%BackdropName as Label).text = "%s  (%d/%d)" % [BACKDROPS[_backdrop_index].title, _backdrop_index + 1, BACKDROPS.size()]
	(%Pattern as Button).text = "Pattern: " + MOTIFS[_motif_index]
