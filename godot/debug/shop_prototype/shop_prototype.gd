extends Node
class_name ShopPrototype
## Debug host for the shop interface: equips a fixture build, hands out coins, and reopens
## the shop on every exit so stock, prices, and refresh costs can be tried over and over.
## Edit `rules` in the Inspector to iterate on the shop's numbers.

# --- Member variables ---

## Shop prices and stock under test.
@export var rules: ShopRules = preload("res://shop_interface/session/shop_rules.tres")
## Coins a fresh run starts with.
@export_range(0, 99) var starting_coins: int = 20
## Reusable shop presentation under test.
@onready var _shop: ShopInterface = $Shop
## Collapsible debug options.
@onready var _panel: PanelContainer = %Panel
## Fixture builds shared with the round prototype.
var _builds: Array[RunFixtures.Build] = RunFixtures.builds()
## Selected fixture; starts on the small Starter build, which leaves room to buy.
var _build_index: int = 1
## Shop logic for the current run.
var _session: ShopSession
## Shop visits so far in this run, counting the open one.
var _visit: int = 1

# --- Member functions ---

## Ready callback: load the player's preferences, connect debug controls, and open the
## first shop.
func _ready() -> void:
	GameSettings.shared().changed.connect(_on_settings_changed)
	GameSettings.shared().load_saved()
	_on_settings_changed()
	(%Toggle as Button).pressed.connect(_toggle_panel)
	(%Build as Button).pressed.connect(_next_build)
	(%Restock as Button).pressed.connect(_open)
	(%Coins as Button).pressed.connect(_grant_coins)
	(%Motion as Button).toggled.connect(_on_motion_toggled)
	(%Sound as Button).toggled.connect(_on_sound_toggled)
	get_viewport().size_changed.connect(_scale_debug)
	_scale_debug()
	_shop.leave_requested.connect(_on_shop_left)
	_new_run()

## Draw the debug controls at the display's density, so they stay pressable on a phone.
## They sit in the top-left corner, about which the layer scales; the top-right corner
## belongs to the settings button.
func _scale_debug() -> void:
	var layer: CanvasLayer = $Debug as CanvasLayer
	layer.scale = Vector2.ONE * HudLayout.display_density()

## Start a fresh run with the selected fixture and open its first shop.
func _new_run() -> void:
	(%Build as Button).text = "Build: " + _builds[_build_index].title
	_session = ShopSession.new(RunFixtures.equip(_builds[_build_index], starting_coins), rules)
	_visit = 1
	_open()

## Open (or reopen) a visit: fresh stock, refresh cost back at its base.
func _open() -> void:
	_shop.open_shop(_session, _shop.round_caption(_visit + 1))

## Leaving simply starts the next visit; there is no round in this fixture.
func _on_shop_left() -> void:
	_visit += 1
	_open()

## Show or hide the options without covering the shop.
func _toggle_panel() -> void:
	_panel.visible = not _panel.visible

## Cycle fixtures and restart with the new one.
func _next_build() -> void:
	_build_index = (_build_index + 1) % _builds.size()
	_new_run()

## Hand out coins without leaving the shop.
func _grant_coins() -> void:
	_session.run.coins += 10
	_shop.sync()

## Toggle reduced motion.
func _on_motion_toggled(enabled: bool) -> void:
	_shop.reduced_motion = enabled

## Toggle sound effects through the shared preferences, as the settings card does.
func _on_sound_toggled(enabled: bool) -> void:
	GameSettings.shared().set_sound_enabled(enabled)

## Mirror the shared preferences: the Sound toggle, and the caption this host writes.
func _on_settings_changed() -> void:
	(%Sound as Button).set_pressed_no_signal(GameSettings.shared().sound_enabled)
	if _session:
		_shop.set_caption(_shop.round_caption(_visit + 1))
