extends Node3D
class_name ShopInterface
## Playable shop between rounds: the same table and dice as a round, with stock laid on the
## felt's back half. It turns the HUD's intents into ShopSession calls and presents what the
## session commits. Prices, stock, and ownership rules stay in the session and its ShopRules.

# --- Signals ---

## The player pressed the leave action; the host starts whatever comes next.
signal leave_requested
## The player asked for the main menu from the settings card.
signal main_menu_requested

# --- Constants ---

## Back-left corner of the shelf area on the felt, in table-local space.
const SHELF_BACK_LEFT: Vector3 = Vector3(-9.7, 0.0, -6.35)
## Front-right corner of the shelf area, short of the row where the dice rest.
const SHELF_FRONT_RIGHT: Vector3 = Vector3(9.7, 0.0, -1.2)
## Glossary key for each reason the session gives when it refuses a purchase.
const REFUSAL_WORDS: Dictionary[String, StringName] = {
	ShopSession.NO_COINS: &"ui.shop.refusal.no_coins",
	ShopSession.NO_JOKER_SLOT: &"ui.shop.refusal.no_joker_slot",
	ShopSession.NO_BONUS_SLOT: &"ui.shop.refusal.no_bonus_slot",
	ShopSession.SOLD: &"ui.shop.refusal.sold",
	ShopSession.INVALID: &"ui.shop.refusal.invalid",
}

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
## Window pixels per logical pixel, which sizes the HUD for the screen it is on. Zero follows
## the display; checks set it to lay a phone out in an offscreen viewport.
@export_range(0.0, 4.0, 0.125) var display_density: float = 0.0:
	set(value):
		display_density = value
		if is_node_ready():
			_layout()
## Whether the settings card offers the way back to the main menu; hosts that have one
## enable it and listen to `main_menu_requested`.
@export var main_menu_available: bool = false:
	set(value):
		main_menu_available = value
		if is_node_ready():
			_hud.settings.main_menu_available = value
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
## Language the texts on screen are written in.
var _shown_locale: String = TranslationServer.get_locale()

# --- Member functions ---

## Ready callback: connect the HUD's intents and frame the table.
func _ready() -> void:
	_hud.buy_requested.connect(_on_buy_requested)
	_hud.sell_requested.connect(_on_sell_requested)
	_hud.move_requested.connect(_on_move_requested)
	_hud.refresh_pressed.connect(_on_refresh_pressed)
	_hud.leave_pressed.connect(_on_leave_pressed)
	_hud.refused.connect(_on_refused)
	_hud.picked.connect(_audio.play.bind(&"pickup", 0, 0.0, 0.06))
	_hud.dealt.connect(_on_dealt)
	_hud.hover_ticked.connect(_audio.play.bind(&"hover", 0, 0.0, 0.1))
	_hud.main_menu_requested.connect(main_menu_requested.emit)
	_hud.settings.main_menu_available = main_menu_available
	GameSettings.shared().changed.connect(_on_settings_changed)
	if not GameSettings.shared().sound_enabled:
		muted = true
	stage.backdrop_changed.connect(_on_backdrop_changed)
	_on_backdrop_changed()
	_audio.muted = muted
	_apply_motion()
	get_viewport().size_changed.connect(_layout)
	_layout()

## Whether a purchase is still being presented; presses are ignored until it settles.
func is_busy() -> bool:
	return _hud.locked

## Localized caption for the visit before a given round, for hosts that have no better line.
func round_caption(round_number: int) -> String:
	return _words.render(&"ui.shop.before_round", {"round": str(round_number)}, locale)

## Start a shop visit on the host's session: fresh stock, refresh cost back at its base.
func open_shop(session: ShopSession, caption: String) -> void:
	_session = session
	_caption = caption
	_hud.locked = false
	session.open()
	_show_dice()
	_hud.show_shop(session, caption, _words, locale, true)

## Replace the line under the shop's name; hosts call it again after a language change.
func set_caption(caption: String) -> void:
	_caption = caption
	_hud.show_caption(caption)

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
	var free: Rect2 = _hud.arrange(viewport, display_density)
	stage.frame(free, viewport, _hud.layout.table_half_width)
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

## Say why a press did nothing, in the player's language. The session's reason is a
## stable English code; unknown ones are shown as they are.
func _on_refused(reason: String, at: Vector2) -> void:
	var text: String = _words.render(REFUSAL_WORDS[reason], {}, locale) if REFUSAL_WORDS.has(reason) else reason
	_hud.popup(at, text, GameColors.CHERRY, 19)
	_audio.play(&"deny")

## Each slot of a new shelf lands with a tick that climbs the ladder.
func _on_dealt(order: int) -> void:
	_audio.play(&"deal", order, 0.0, 0.05)

## Follow the shared preferences: sound at once; a new language rewrites the shop's texts
## in place, without dealing the shelf again.
func _on_settings_changed() -> void:
	muted = not GameSettings.shared().sound_enabled
	if TranslationServer.get_locale() == _shown_locale:
		return
	_shown_locale = TranslationServer.get_locale()
	if _session and not is_busy():
		_hud.show_shop(_session, _caption, _words, locale, false)

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
