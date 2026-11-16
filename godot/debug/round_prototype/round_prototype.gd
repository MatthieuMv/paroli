extends Node
class_name RoundPrototype
## Debug host for the round interface: equips fixture builds, owns the run, and chains rounds
## with a shop visit between them. Targets, coins, and shop rules here are test fixtures.

# --- Constants ---

## Each cleared round multiplies the target by this fixture factor.
const TARGET_GROWTH: float = 1.6
## Shop scene shown between cleared rounds; parked outside the tree while a round plays.
const SHOP: PackedScene = preload("res://shop_interface/shop_interface.tscn")
## Reveal speeds cycled by the debug control.
const SPEEDS: PackedFloat32Array = [1.0, 1.5, 2.0]
## Wallpaper color schemes to compare: pastel washes, mid-tones, then dark walls.
const BACKDROPS: Array[BackdropPreset] = [
	preload("res://table_stage/backdrop/presets/paper.tres"),
	preload("res://table_stage/backdrop/presets/sand.tres"),
	preload("res://table_stage/backdrop/presets/butter.tres"),
	preload("res://table_stage/backdrop/presets/peach_cream.tres"),
	preload("res://table_stage/backdrop/presets/blush.tres"),
	preload("res://table_stage/backdrop/presets/lavender.tres"),
	preload("res://table_stage/backdrop/presets/sky.tres"),
	preload("res://table_stage/backdrop/presets/mint.tres"),
	preload("res://table_stage/backdrop/presets/lagoon.tres"),
	preload("res://table_stage/backdrop/presets/periwinkle.tres"),
	preload("res://table_stage/backdrop/presets/honey.tres"),
	preload("res://table_stage/backdrop/presets/cocoa.tres"),
	preload("res://table_stage/backdrop/presets/plum_night.tres"),
	preload("res://table_stage/backdrop/presets/deep_lagoon.tres"),
	preload("res://table_stage/backdrop/presets/espresso.tres"),
]
## Captions for StageBackdrop.Motif values, in enum order.
const MOTIFS: PackedStringArray = ["Plain", "Sparkles", "Dots", "Stripes", "Diamonds"]

# --- Member variables ---

## Reusable round presentation under test.
@onready var _round: RoundInterface = $Round
## Collapsible debug options.
@onready var _panel: PanelContainer = %Panel
## Shop prices and stock; edit the resource in the Inspector to iterate on the shop.
@export var shop_rules: ShopRules = preload("res://shop_interface/session/shop_rules.tres")
## Fixture builds, from a full chain showcase down to bare dice.
var _builds: Array[RunFixtures.Build] = RunFixtures.builds()
## Shop scene, created on the first visit and reused afterwards.
var _shop: ShopInterface
## Shop logic for the current run; one session keeps its event IDs unique across visits.
var _shop_session: ShopSession
## Whether a cleared round leads to a shop visit before the next round.
var _shops_enabled: bool = true
## Selected fixture.
var _build_index: int = 0
## Selected reveal speed.
var _speed_index: int = 0
## Selected wallpaper color scheme; starts on the stage's authored default, Plum night.
var _backdrop_index: int = 12
## Selected wallpaper pattern; starts on the round interface's authored default.
var _motif_index: int = StageBackdrop.Motif.SPARKLES
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
	(%Shops as Button).toggled.connect(_on_shops_toggled)
	_round.continue_requested.connect(_on_continue_requested)
	_round.busy_changed.connect(_on_busy_changed)
	_refresh_labels()
	_new_run()

## Start a fresh run with the selected fixture.
func _new_run() -> void:
	_show_round()
	var build: RunFixtures.Build = _builds[_build_index]
	var run: MechanicsRun = RunFixtures.equip(build, 4)
	_session = RoundSession.new(run)
	_session.coins_per_unused_play = 2
	_shop_session = ShopSession.new(run, shop_rules)
	_round_number = 1
	_target = build.target
	_round.start_round(_session, _round_number, _target)

## Clearing a round raises the target and visits the shop; failing ends the run.
func _on_continue_requested(succeeded: bool) -> void:
	if not succeeded:
		_new_run()
		return
	_round_number += 1
	_target = roundf(_target * TARGET_GROWTH / 10.0) * 10.0
	if _shops_enabled:
		_show_shop()
	else:
		_round.start_round(_session, _round_number, _target)

## Swap the round out for the shop. Only one table scene is in the tree at a time, so
## there is a single camera and environment.
func _show_shop() -> void:
	if not _shop:
		_shop = SHOP.instantiate() as ShopInterface
		_shop.name = "Shop"
		_shop.leave_requested.connect(_on_shop_left)
	remove_child(_round)
	add_child(_shop)
	move_child(_shop, 0)
	_shop.reduced_motion = _round.reduced_motion
	_shop.muted = _round.muted
	_shop.stage.backdrop_preset = _round.stage.backdrop_preset
	_shop.stage.backdrop_motif = _round.stage.backdrop_motif
	_shop.open_shop(_shop_session, "Before round %d" % _round_number)

## Bring the round back, wherever the host currently is.
func _show_round() -> void:
	if _round.is_inside_tree():
		return
	remove_child(_shop)
	add_child(_round)
	move_child(_round, 0)

## Whichever scene is parked outside the tree would otherwise outlive this host.
func _exit_tree() -> void:
	if _shop and not _shop.is_inside_tree():
		_shop.free()
	if not _round.is_inside_tree():
		_round.free()

## Leaving the shop starts the next round with whatever was bought.
func _on_shop_left() -> void:
	_show_round()
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
	_round.stage.backdrop_preset = BACKDROPS[_backdrop_index]
	if _shop:
		_shop.stage.backdrop_preset = BACKDROPS[_backdrop_index]
	_refresh_labels()

## Cycle the wallpaper pattern; it combines with any color scheme.
func _next_motif() -> void:
	_motif_index = (_motif_index + 1) % MOTIFS.size()
	_round.stage.backdrop_motif = _motif_index as StageBackdrop.Motif
	if _shop:
		_shop.stage.backdrop_motif = _motif_index as StageBackdrop.Motif
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
	if _shop:
		_shop.reduced_motion = enabled

## Toggle sound effects.
func _on_sound_toggled(enabled: bool) -> void:
	_round.muted = not enabled
	if _shop:
		_shop.muted = not enabled

## Choose whether cleared rounds lead to the shop.
func _on_shops_toggled(enabled: bool) -> void:
	_shops_enabled = enabled

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
