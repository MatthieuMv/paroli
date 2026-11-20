extends Node
class_name Game
## The game itself: the main menu, then a run along its route (upgrade choice, rounds,
## shops) and back to the menu when the run ends or the player leaves it. One table screen
## is in the tree at a time, so there is a single camera and environment; the others wait
## parked outside it. Run rules live in `RunSession`; this host only decides which screen
## shows which stop, and writes the captions that name it.

# --- Constants ---

## Round screen, created with the first run and reused afterwards.
const ROUND: PackedScene = preload("res://round_interface/round_interface.tscn")
## Shop screen, created with the first run and reused afterwards.
const SHOP: PackedScene = preload("res://shop_interface/shop_interface.tscn")
## Felt point (table local) the Show upgrades action is centered on while the player
## inspects the table: the middle of the empty play row, clear of the dice and the HUD.
const INSPECT_ANCHOR: Vector3 = Vector3(0.0, 0.0, -3.5)

# --- Member variables ---

## Route length, starting purse, coin rate, and target curve; edit the resource to tune a run.
@export var rules: RunRules = preload("res://game/session/run_rules.tres")
## Shop prices and stock for every visit of a run.
@export var shop_rules: ShopRules = preload("res://shop_interface/session/shop_rules.tres")
## Removes springs, travel, and staggered timing on every screen.
@export var reduced_motion: bool = false:
	set(value):
		reduced_motion = value
		if is_node_ready():
			_apply_presentation()
## Window pixels per logical pixel, which sizes every screen for the display it is on.
## Zero follows the display; checks set it to lay a phone out in an offscreen viewport.
@export_range(0.0, 4.0, 0.125) var display_density: float = 0.0:
	set(value):
		display_density = value
		if is_node_ready():
			_apply_presentation()
## Seed of the next run's dice, shop stock, and upgrade offers; zero keeps them random.
var run_seed: int = 0
## Title screen; on stage until a run starts, and again once it ends.
@onready var _menu: MainMenu = $Menu
## Layer of the upgrade choice, above every screen's own HUD and scaled to the display.
@onready var _upgrade_layer: CanvasLayer = $UpgradeLayer
## Logical-pixel frame the upgrade choice fills.
@onready var _upgrade_frame: Control = $UpgradeLayer/Frame
## Upgrade choice shown over the round screen at the start of each biome.
@onready var _upgrades: AugmentOverlay = %Upgrades
## Sound effects of the screens this host owns outright: the upgrade choice.
@onready var _audio: RoundAudio = $Audio
## Round screen; null until the first run.
var _round: RoundInterface
## Shop screen; null until the first run.
var _shop: ShopInterface
## Screen currently in the tree.
var _screen: Node3D
## Run being played; null on the main menu.
var _run: RunSession
## Glossary for the captions this host writes.
var _words: KeywordCatalog = GameKeywords.new()
## A request for the main menu is waiting for a throw or reveal to end.
var _leaving: bool = false

# --- Member functions ---

## Ready callback: load the player's preferences and open on the main menu.
func _ready() -> void:
	GameSettings.shared().changed.connect(_on_settings_changed)
	GameSettings.shared().load_saved()
	_audio.muted = not GameSettings.shared().sound_enabled
	_screen = _menu
	_menu.new_run_requested.connect(_on_new_run_requested)
	_upgrades.upgrade_selected.connect(_on_upgrade_selected)
	_upgrades.closed.connect(_on_upgrades_closed)
	# Deferred, so the screen underneath has framed its table for the new window first.
	get_viewport().size_changed.connect(_fit_upgrades.call_deferred)
	_apply_presentation()

## Whichever screens are parked outside the tree would otherwise outlive this host.
func _exit_tree() -> void:
	for screen: Node3D in [_menu, _round, _shop]:
		if screen and not screen.is_inside_tree():
			screen.free()

## Start a fresh run at its opening upgrade choice.
func _on_new_run_requested() -> void:
	if _run:
		return
	_run = RunSession.new(rules, shop_rules, run_seed)
	_create_screens()
	_enter_stop()

## Present the run's current stop, or return to the menu once nothing is left to play.
func _enter_stop() -> void:
	var here: RunStop = _run.stop()
	if not here:
		_show_menu()
		return
	match here.kind:
		RunStop.Kind.UPGRADE:
			_offer_upgrade()
		RunStop.Kind.ROUND:
			_play_round(here)
		RunStop.Kind.SHOP:
			_visit_shop(here)

## Biome start: three upgrades over the table, which shows the build and the coming round.
func _offer_upgrade() -> void:
	_show(_round)
	_preview_coming_round()
	if not _upgrades.open(_run.upgrade_offers()):
		push_error("The upgrade choice could not open")
		return
	# Deferred, so a round screen that just returned to the tree has framed its table.
	_fit_upgrades.call_deferred()

## Deal a round. Its result card names what the route holds next.
func _play_round(here: RunStop) -> void:
	_show(_round)
	_name_round(here)
	var last: bool = _run.is_last(here)
	_round.cleared_title = &"ui.run_complete" if last else &"ui.round_cleared"
	if last:
		_round.cleared_action = &"ui.settings.main_menu"
	else:
		# A shop follows a regular round; the next biome's upgrade follows a boss.
		_round.cleared_action = &"ui.continue" if here.boss else &"ui.shop"
	_round.failed_action = &"ui.settings.main_menu"
	if not _round.start_round(_run.rounds, here.round_number, here.target):
		push_error("Round %d could not start" % here.round_number)

## Open the shop before the round its sign announces.
func _visit_shop(here: RunStop) -> void:
	_show(_shop)
	_shop.open_shop(_run.shop, _shop_caption(here))

## The result card's action: a cleared round moves on, a failed one ends the run (D-007).
func _on_continue_requested(_succeeded: bool) -> void:
	_run.advance()
	_enter_stop()

## Leaving the shop moves on to the next round.
func _on_shop_left() -> void:
	_run.advance()
	_enter_stop()

## The choice is committed before its card animates: install it at once, so the die under
## the dimmer already wears it when the cards go. A purchase chime and the die's burst
## sound with it.
func _on_upgrade_selected(upgrade_id: StringName) -> void:
	_audio.play(&"buy")
	_audio.play(&"consume", 2, -2.0)
	for message: String in _run.choose_upgrade(upgrade_id):
		push_error("Upgrade choice: " + message)
	_preview_coming_round()

## The chosen card finished its activation: the biome's first round begins.
func _on_upgrades_closed() -> void:
	if not _run:
		return
	_run.advance()
	_enter_stop()

## The settings card asked for the main menu: the run is abandoned. A throw or reveal ends
## first, because a round cannot be parked while it is playing.
func _on_main_menu_requested() -> void:
	if _leaving or not _run:
		return
	_leaving = true
	if _round.is_busy():
		while _round.is_busy():
			await _round.busy_changed
		# The lock opens while the frame's nodes are processing; swap screens between frames.
		await get_tree().process_frame
	_leaving = false
	if _run and _upgrades.cancel():
		_show_menu()

## End the run, if any, and tumble the menu's dice back in.
func _show_menu() -> void:
	_run = null
	_show(_menu)
	_menu.throw_dice()

## Put one screen on stage and park the one it replaces.
func _show(screen: Node3D) -> void:
	if screen == _screen:
		return
	remove_child(_screen)
	add_child(screen)
	move_child(screen, 0)
	_screen = screen

## Create the run's screens on the first run, with the way back to the menu switched on.
func _create_screens() -> void:
	if _round:
		return
	_round = ROUND.instantiate() as RoundInterface
	_round.name = "Round"
	_round.main_menu_available = true
	_round.continue_requested.connect(_on_continue_requested)
	_round.main_menu_requested.connect(_on_main_menu_requested)
	_shop = SHOP.instantiate() as ShopInterface
	_shop.name = "Shop"
	_shop.main_menu_available = true
	_shop.leave_requested.connect(_on_shop_left)
	_shop.main_menu_requested.connect(_on_main_menu_requested)
	_apply_presentation()

## Show the build, name, and target of the round to come on the resting round screen.
func _preview_coming_round() -> void:
	var coming: RunStop = _run.coming_round()
	if not coming:
		return
	_name_round(coming)
	_round.preview_round(_run.rounds, coming.round_number, coming.target)

## Bosses carry their biome's number; regular rounds keep the screen's own "Round N".
func _name_round(here: RunStop) -> void:
	_round.set_round_caption(_words.render(&"ui.boss", {"biome": str(here.biome)}, "") if here.boss else "")

## Line on the shop sign: which round comes next.
func _shop_caption(here: RunStop) -> String:
	if here.boss:
		return _words.render(&"ui.shop.before_boss", {}, "")
	return _shop.round_caption(here.round_number)

## Push motion and density into every screen that exists.
func _apply_presentation() -> void:
	_menu.reduced_motion = reduced_motion
	_menu.display_density = display_density
	if _round:
		_round.reduced_motion = reduced_motion
		_round.display_density = display_density
		_shop.reduced_motion = reduced_motion
		_shop.display_density = display_density
	_fit_upgrades()

## Size the upgrade choice in logical pixels, like the HUDs, and keep its Show upgrades
## action on the felt's empty play row while the player inspects the table.
func _fit_upgrades() -> void:
	if not is_inside_tree():
		return
	var density: float = display_density if display_density > 0.0 else HudLayout.display_density()
	_upgrade_layer.scale = Vector2.ONE * density
	_upgrade_frame.position = Vector2.ZERO
	_upgrade_frame.size = get_viewport().get_visible_rect().size / density
	if _round and _round.is_inside_tree():
		_upgrades.place_restore(_round.stage.project(INSPECT_ANCHOR) / density)

## Sound follows at once; host-written captions follow a language change, and each screen
## rewrites its own texts.
func _on_settings_changed() -> void:
	_audio.muted = not GameSettings.shared().sound_enabled
	if not _run:
		return
	var here: RunStop = _run.stop()
	var coming: RunStop = _run.coming_round()
	if coming:
		_name_round(coming)
	if here and here.kind == RunStop.Kind.SHOP:
		_shop.set_caption(_shop_caption(here))
	_upgrades.relabel()
	_fit_upgrades()
