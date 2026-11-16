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

## Ready callback: connect debug controls and open the first shop.
func _ready() -> void:
	(%Toggle as Button).pressed.connect(_toggle_panel)
	(%Build as Button).pressed.connect(_next_build)
	(%Restock as Button).pressed.connect(_open)
	(%Coins as Button).pressed.connect(_grant_coins)
	(%Motion as Button).toggled.connect(_on_motion_toggled)
	(%Sound as Button).toggled.connect(_on_sound_toggled)
	_shop.leave_requested.connect(_on_shop_left)
	_new_run()

## Start a fresh run with the selected fixture and open its first shop.
func _new_run() -> void:
	(%Build as Button).text = "Build: " + _builds[_build_index].title
	_session = ShopSession.new(RunFixtures.equip(_builds[_build_index], starting_coins), rules)
	_visit = 1
	_open()

## Open (or reopen) a visit: fresh stock, refresh cost back at its base.
func _open() -> void:
	_shop.open_shop(_session, "Before round %d" % (_visit + 1))

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

## Toggle sound effects.
func _on_sound_toggled(enabled: bool) -> void:
	_shop.muted = not enabled
