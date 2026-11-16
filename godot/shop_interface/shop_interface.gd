extends Node3D
class_name ShopInterface
## Playable shop between rounds: the same table and dice as a round, with stock laid on the
## felt's back half. It turns the HUD's intents into ShopSession calls and presents what the
## session commits. Prices, stock, and ownership rules stay in the session and its ShopRules.

# --- Signals ---

## The player pressed the leave action; the host starts whatever comes next.
signal leave_requested

# --- Constants ---

## Back-left corner of the shelf area on the felt, in table-local space.
const SHELF_BACK_LEFT: Vector3 = Vector3(-9.7, 0.0, -6.35)
## Front-right corner of the shelf area, short of the row where the dice rest.
const SHELF_FRONT_RIGHT: Vector3 = Vector3(9.7, 0.0, -1.2)

# --- Member variables ---

## Removes springs, deals, flights, and waits; purchases still resolve in order.
@export var reduced_motion: bool = false:
	set(value):
		reduced_motion = value
		if is_node_ready():
			_apply_motion()
## Silences sound effects.
@export var muted: bool = false:
	set(value):
		muted = value
		if is_node_ready():
			_audio.muted = value
## Explicit locale for names and captions; empty follows the game locale.
@export var locale: String = ""
## Shared table set: wallpaper, camera, table, and dice. Hosts may restyle its wallpaper.
@onready var stage: TableStage = $Stage
## Heads-up display.
@onready var _hud: ShopHud = $Interface/Hud
## Sound effects.
@onready var _audio: RoundAudio = $Audio
## Shop logic supplied by the host.
var _session: ShopSession
## Line shown on the shop sign, such as which round comes next.
var _caption: String = ""
## Glossary for names and captions.
var _words: KeywordCatalog = GameKeywords.new()

# --- Member functions ---

## Ready callback: connect the HUD's intents and frame the table.
func _ready() -> void:
	_hud.buy_requested.connect(_on_buy_requested)
	_hud.random_requested.connect(_on_random_requested)
	_hud.sell_requested.connect(_on_sell_requested)
	_hud.move_requested.connect(_on_move_requested)
	_hud.refresh_pressed.connect(_on_refresh_pressed)
	_hud.leave_pressed.connect(_on_leave_pressed)
	_hud.refused.connect(_on_refused)
	_hud.picked.connect(_audio.play.bind(&"pickup", 0, 0.0, 0.06))
	_hud.dealt.connect(_on_dealt)
	_hud.hover_ticked.connect(_audio.play.bind(&"hover", 0, 0.0, 0.1))
	stage.backdrop_changed.connect(_on_backdrop_changed)
	_on_backdrop_changed()
	_audio.muted = muted
	_apply_motion()
	get_viewport().size_changed.connect(_layout)
	_layout()

## Whether a purchase is still being presented; presses are ignored until it settles.
func is_busy() -> bool:
	return _hud.locked

## Start a shop visit on the host's session: fresh stock, refresh cost back at its base.
func open_shop(session: ShopSession, caption: String) -> void:
	_session = session
	_caption = caption
	_hud.locked = false
	session.open()
	_show_dice()
	_hud.show_shop(session, caption, _words, locale, true)

## Redraw after the host changed the run outside the shop's own actions (debug coins, for example).
func sync() -> void:
	_hud.sync()
	_show_dice()

## Fit the HUD to the window, frame the table in the space it leaves, then align shelf and docks.
## A host may park this scene outside the tree; it lays out again on return.
func _layout() -> void:
	if not is_inside_tree():
		return
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	stage.frame(_hud.arrange(viewport), viewport)
	var corner: Vector2 = stage.project(SHELF_BACK_LEFT)
	var die_rects: Array[Rect2] = []
	for die_id: StringName in stage.views:
		die_rects.append(stage.die_rect(die_id))
	_hud.align_table(stage.columns(), stage.camera.framed_rect.end.y, Rect2(corner, stage.project(SHELF_FRONT_RIGHT) - corner), die_rects)

## Re-entering the tree after being parked: the window may have changed meanwhile.
func _enter_tree() -> void:
	if is_node_ready():
		_layout.call_deferred()

## Buy a known offer; bonuses land on the chosen die.
func _on_buy_requested(offer_index: int, die_id: StringName) -> void:
	var offer: ShopOffer = _session.offers[offer_index]
	var coins: int = _session.run.coins
	var block: String = _session.buy(offer, die_id)
	if not block.is_empty():
		_on_refused(block, _hud.purse_anchor())
		return
	_present_purchase(offer.definition, coins, die_id)

## Buy an unknown item: pay, turn the tile over, then let it fly to its place.
func _on_random_requested(family: StringName, die_id: StringName) -> void:
	var coins: int = _session.run.coins
	var found: IllustratedDefinition = _session.buy_random(family, die_id)
	if not found:
		_on_refused(_session.random_block(family), _hud.purse_anchor())
		return
	# The reveal is a short beat; the HUD ignores presses until the item has a home.
	_hud.reveal_random(family, found)
	_hud.locked = true
	_audio.play(&"reveal")
	_hud.popup(_hud.purse_anchor(), Juice.signed(float(_session.run.coins - coins)), GameColors.BUTTER, 26, true)
	_hud.show_coins(_session.run.coins, true)
	await _pause(0.75)
	_hud.locked = false
	_present_purchase(found, _session.run.coins, die_id)

## Sell an owned bonus or Joker into the purse.
func _on_sell_requested(owner_id: StringName) -> void:
	var item: OwnedDefinition = _session.run.find_owned(owner_id)
	var sold: IllustratedDefinition = item.definition as IllustratedDefinition if item else null
	var coins: int = _session.run.coins
	var gained: int = _session.sell(owner_id)
	if gained < 0:
		_on_refused(ShopSession.INVALID, _hud.purse_anchor())
		return
	_hud.sync()
	_count_coins(coins)
	_hud.fly_to_purse(sold, gained)
	_audio.play(&"coin", 2)
	_show_dice()

## Move a bonus to another die's free slot.
func _on_move_requested(from_die: StringName, to_die: StringName) -> void:
	var block: String = _session.move_bonus(from_die, to_die)
	if not block.is_empty():
		_on_refused(block, _hud.purse_anchor())
		return
	_hud.sync()
	_hud.fly_to_owner(StringName("bonus:" + String(to_die)))
	_audio.play(&"place")
	_hop_later(to_die)

## Pay for a whole new shelf; the next refresh costs more.
func _on_refresh_pressed() -> void:
	var coins: int = _session.run.coins
	var result: MechanicsEventResult = _session.refresh()
	if not result.errors.is_empty():
		_on_refused(ShopSession.NO_COINS, _hud.purse_anchor())
		return
	_audio.play(&"refresh")
	_hud.popup(_hud.purse_anchor(), Juice.signed(float(_session.run.coins - coins)), GameColors.BUTTER, 26, true)
	_hud.show_shop(_session, _caption, _words, locale, true)
	_count_coins(coins)

## Leave the shop.
func _on_leave_pressed() -> void:
	_audio.play(&"button")
	leave_requested.emit()

## Show a completed purchase: coins count down, the item flies home, its die answers.
func _present_purchase(definition: IllustratedDefinition, coins_before: int, die_id: StringName) -> void:
	var spent: int = coins_before - _session.run.coins
	_hud.sync()
	_count_coins(coins_before)
	if spent > 0:
		_hud.popup(_hud.purse_anchor(), Juice.signed(float(-spent)), GameColors.BUTTER, 26, true)
	if definition is JokerDefinition:
		_hud.fly_to_owner(StringName("joker:" + String(definition.id)))
	else:
		_hud.fly_to_owner(StringName("bonus:" + String(die_id)))
		_hop_later(die_id)
	_audio.play(&"buy")
	_show_dice()

## Count the purse from an earlier balance to the session's current one.
func _count_coins(from: int) -> void:
	_hud.show_coins(from, false)
	_hud.show_coins(_session.run.coins, true)

## A die hops as its new bonus lands on its column.
func _hop_later(die_id: StringName) -> void:
	if reduced_motion or not stage.views.has(die_id):
		return
	get_tree().create_timer(0.3).timeout.connect(Juice.hop.bind(stage.views[die_id], 0.7))

## Dice wear their permanent identity and show the value they last rolled.
func _show_dice() -> void:
	var run: MechanicsRun = _session.run
	UpgradePresentation.refresh(run, [], stage.views)
	for die_id: StringName in stage.views:
		var die: ParoliDie = stage.views[die_id]
		die.face_value = run.find_die(die_id).value
		die.effect_enabled = false
		die.shine_enabled = false

## Say why a press did nothing.
func _on_refused(reason: String, at: Vector2) -> void:
	_hud.popup(at, reason, GameColors.CHERRY, 19)
	_audio.play(&"deny")

## Each slot of a new shelf lands with a tick that climbs the ladder.
func _on_dealt(order: int) -> void:
	_audio.play(&"deal", order, 0.0, 0.05)

## The wallpaper changed: recolor the marks the HUD draws straight on the wall.
func _on_backdrop_changed() -> void:
	_hud.set_wall_ink(stage.wall_ink())

## Push the reduced-motion preference into the stage and HUD.
func _apply_motion() -> void:
	stage.reduced_motion = reduced_motion
	_hud.reduced_motion = reduced_motion

## Wait for a presentation beat; reduced motion keeps only a single frame.
func _pause(seconds: float) -> void:
	if reduced_motion:
		await get_tree().process_frame
	else:
		await get_tree().create_timer(seconds).timeout
