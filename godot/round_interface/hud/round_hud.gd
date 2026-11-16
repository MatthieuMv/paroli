extends Control
class_name RoundHud
## Round HUD: goal, scoreboard, Joker rack, die docks, coins, and the two actions.
## It lays itself out around the table, reports player intents, and animates values the
## host hands it. No rules, randomness, or scoring arithmetic live here.

# --- Signals ---

## The player asked to roll the dice left on the roll row.
signal roll_pressed
## The player asked to play the selected dice.
signal play_pressed
## The player dismissed the result banner.
signal continue_pressed
## The pointer reached an interactive element; hosts may answer with a soft tick.
signal hover_ticked

# --- Constants ---

## Reference window for the landscape arrangement; larger windows scale the HUD up.
const WIDE_DESIGN: Vector2 = Vector2(1280.0, 900.0)
## Reference window for the portrait arrangement.
const TALL_DESIGN: Vector2 = Vector2(540.0, 960.0)
## Aspect ratio below which the portrait arrangement is used.
const TALL_ASPECT: float = 1.1
## Popup fill colors by semantic role; plum outlines keep them readable on felt and paper.
const POPUP_COLORS: Dictionary[StringName, Color] = {
	&"points": GameColors.SKY,
	&"mult": GameColors.CHERRY,
	&"coins": GameColors.BUTTER,
	&"tempo": GameColors.TANGERINE,
}
## Floating increment scene; instances free themselves.
const POPUP: PackedScene = preload("res://round_interface/hud/score_popup.tscn")

# --- Member variables ---

## Removes springs, sway, travel, and confetti across every widget.
var reduced_motion: bool = false:
	set(value):
		reduced_motion = value
		if is_node_ready():
			_apply_motion()
## Glossary for names and captions; supplied by the host with the build.
var words: KeywordCatalog
## Explicit locale for rendered names; empty follows the game locale.
var locale: String = ""
## Round target and banked score.
@onready var goal: GoalMeter = $Goal
## Combination plate, factor tiles, and revealed total.
@onready var score: ScoreBoard = $Score
## End-of-round card.
@onready var banner: ResultBanner = $Banner
## Four Joker slots in rack order.
@onready var _jokers: Control = $Jokers
## Five die columns in run order.
@onready var _docks: Control = $Docks
## Coin purse.
@onready var _coins: CoinChip = $Coins
## One-line instruction, shown only where there is room.
@onready var _hint: Label = $Hint
## Manual roll action with its remaining uses.
@onready var _roll: ActionButton = $Roll
## Play action with its remaining uses.
@onready var _play: ActionButton = $Play
## Parent for floating increments, above widgets and below the banner.
@onready var _popups: Control = $Popups
## Hover explanation card.
@onready var _tooltip: BuildTooltip = $Tooltip
## Caption beside the back row, where dice selected for the play wait.
@onready var _zone_play: Label = $ZonePlay
## Caption beside the front row, where the dice a manual roll rerolls stay.
@onready var _zone_roll: Label = $ZoneRoll
## Window pixels per HUD unit.
var _ui_scale: float = 1.0
## Whether the portrait arrangement is active.
var _tall: bool = false
## Top of the bottom tray in HUD units; docks and actions hang below it.
var _tray_top: float = 0.0
## Displayed allowances; the host remains authoritative.
var _plays: int = 0
## Plays granted this round.
var _plays_total: int = 0
## Displayed manual rolls.
var _rerolls: int = 0
## Manual rolls granted this round.
var _rerolls_total: int = 0
## Displayed coin balance during reveals.
var _coin_balance: int = 0
## Card or dock whose tooltip is open, so only its own exit dismisses it.
var _tooltip_owner: Control

# --- Member functions ---

## Ready callback: connect intents and hover explanations.
func _ready() -> void:
	_roll.pressed.connect(_on_roll)
	_play.pressed.connect(_on_play)
	banner.action_pressed.connect(_on_continue)
	_roll.mouse_entered.connect(_on_action_hover.bind(_roll))
	_play.mouse_entered.connect(_on_action_hover.bind(_play))
	for card: BuildCard in _jokers.get_children():
		card.hover_changed.connect(_on_card_hover)
	for dock: DieDock in _docks.get_children():
		dock.card.hover_changed.connect(_on_card_hover)
		dock.tag_hover_changed.connect(_on_tag_hover)
	_apply_motion()

## Lay out for a window size and return the free rectangle (window pixels) left for the table.
func arrange(viewport: Vector2) -> Rect2:
	_tall = viewport.x / viewport.y < TALL_ASPECT
	var design: Vector2 = TALL_DESIGN if _tall else WIDE_DESIGN
	_ui_scale = clampf(minf(viewport.x / design.x, viewport.y / design.y), 0.4, 2.0)
	scale = Vector2.ONE * _ui_scale
	position = Vector2.ZERO
	size = viewport / _ui_scale
	var top: float = _arrange_tall() if _tall else _arrange_wide()
	banner.position = Vector2.ZERO
	banner.size = size
	_popups.size = size
	_tooltip.dismiss()
	return Rect2(0.0, top * _ui_scale, viewport.x, (_tray_top - top) * _ui_scale)

## Align die docks and row captions with the framed table (all inputs in window pixels).
## Docks hang just below `table_bottom`, so they stay with the table when it has spare room.
func align_table(columns: PackedFloat32Array, pixels_per_unit: float, table_bottom: float, play_point: Vector2, roll_point: Vector2) -> void:
	# Docks shrink together when die columns are closer than a dock is wide.
	var spacing: float = absf(columns[1] - columns[0]) / _ui_scale if columns.size() > 1 else 200.0
	var dock_scale: float = clampf((spacing - 6.0) / 104.0, 0.5, 1.0)
	var dock_top: float = table_bottom / _ui_scale + (6.0 if _tall else 14.0)
	for index: int in mini(columns.size(), _docks.get_child_count()):
		var dock: DieDock = _docks.get_child(index) as DieDock
		dock.scale = Vector2.ONE * dock_scale
		dock.position = Vector2(columns[index] / _ui_scale - 52.0 * dock_scale, dock_top)
	_zone_play.position = play_point / _ui_scale - Vector2(0.0, _zone_play.size.y * 0.5)
	_zone_roll.position = roll_point / _ui_scale - Vector2(0.0, _zone_roll.size.y * 0.5)
	_zone_play.visible = pixels_per_unit / _ui_scale > 24.0
	_zone_roll.visible = _zone_play.visible

## Show the run's equipment: Jokers in rack order, then each die's upgrade and bonus.
func show_build(run: MechanicsRun, words_: KeywordCatalog, locale_: String) -> void:
	words = words_
	locale = locale_
	score.set_titles(words.render(&"points", {}, locale), words.render(&"mult", {}, locale))
	_roll.title = words.render(&"roll", {}, locale).capitalize()
	_play.title = words.render(&"validation", {}, locale).capitalize()
	_zone_play.text = _spaced(words.render(&"validation", {}, locale))
	_zone_roll.text = _spaced(words.render(&"roll", {}, locale))
	var rack: int = 0
	for card: BuildCard in _jokers.get_children():
		card.clear()
	for item: OwnedDefinition in run.owned:
		if item.definition is JokerDefinition and rack < _jokers.get_child_count():
			(_jokers.get_child(rack) as BuildCard).show_definition(item.definition as JokerDefinition, item.id)
			rack += 1
	for index: int in mini(run.dice.size(), _docks.get_child_count()):
		var die: RunDie = run.dice[index]
		var upgrade: OwnedDefinition = run.find_owned(StringName("upgrade:" + String(die.id)))
		var bonus: OwnedDefinition = run.find_owned(StringName("bonus:" + String(die.id)))
		(_docks.get_child(index) as DieDock).show_die(die.id, index + 1, upgrade.definition as UpgradeDefinition if upgrade else null, bonus.definition as BonusDefinition if bonus else null, words, locale)

## Establish the round caption, target, and banked score without animation.
func show_round(round_number: int, target: float, banked: float) -> void:
	goal.set_round(_spaced("%s %d" % [words.render(&"round", {}, locale), round_number]), target, banked)

## Show remaining plays and manual rolls; `animate` pops the pip that changed.
func show_allowances(plays: int, plays_total: int, rerolls: int, rerolls_total: int, animate: bool) -> void:
	_plays = plays
	_plays_total = plays_total
	_rerolls = rerolls
	_rerolls_total = rerolls_total
	_play.set_uses(plays, plays_total, animate)
	_roll.set_uses(rerolls, rerolls_total, animate)

## Pop one displayed play pip (unused plays turning into coins) and return where it was.
func spend_play_pip() -> Vector2:
	_plays = maxi(0, _plays - 1)
	_play.set_uses(_plays, _plays_total, true)
	return _play.get_global_transform() * Vector2(_play.size.x * 0.5, -4.0)

## Show the coin balance; reveals then add to it step by step.
func show_coins(coins: int, animate: bool) -> void:
	_coin_balance = coins
	_coins.set_coins(coins, animate)

## Add to the displayed balance during a reveal.
func add_coins(amount: int) -> void:
	show_coins(_coin_balance + amount, true)

## Enable or disable the two actions.
func set_actions(can_roll: bool, can_play: bool) -> void:
	_roll.set_available(can_roll)
	_play.set_available(can_play)

## Run the eligibility shine on exactly these owners' cards.
func mark_eligible(owner_ids: Array[StringName]) -> void:
	for card: BuildCard in _cards():
		card.set_eligible(not card.is_empty() and card.owner_id in owner_ids)

## Punch the card of a resolving bonus or Joker; unknown owners are ignored.
func trigger_owner(owner_id: StringName, strength: float = 1.0) -> void:
	var card: BuildCard = _card_for(owner_id)
	if card:
		card.trigger(strength)

## Window-pixel point beside an owner's card for its popup; ZERO when it has no card.
func owner_anchor(owner_id: StringName) -> Vector2:
	var card: BuildCard = _card_for(owner_id)
	if not card:
		return Vector2.ZERO
	# Rack cards sit at the top edge, so their numbers drop below them.
	return card.anchor(card.get_parent() == _jokers)

## Whether an owner's popup should travel downward (rack) rather than rise (docks, dice).
func owner_drops(owner_id: StringName) -> bool:
	var card: BuildCard = _card_for(owner_id)
	return card != null and card.get_parent() == _jokers

## Spawn a floating increment at a window-pixel point.
func popup(at: Vector2, text: String, role: StringName, font_size: int = 30, drift: float = -52.0, with_coin: bool = false) -> void:
	var node: ScorePopup = POPUP.instantiate() as ScorePopup
	_popups.add_child(node)
	node.reduced_motion = reduced_motion
	node.position = at / _ui_scale
	var fill: Color = POPUP_COLORS.get(role, GameColors.CHALK)
	node.launch(text, fill.lerp(Color.WHITE, 0.28), font_size, drift, with_coin)

## Recolor the few marks drawn straight on the wallpaper so they read on light and dark walls.
func set_wall_ink(ink: Color) -> void:
	_hint.add_theme_color_override("font_color", ink)
	score.set_wall_ink(ink)
	for card: BuildCard in _cards():
		card.set_slot_ink(ink)

## Close any open explanation, for example when a reveal starts.
func dismiss_tooltip() -> void:
	_tooltip_owner = null
	_tooltip.dismiss()

## Landscape: goal, scoreboard, and rack share one band; docks and actions share the tray.
func _arrange_wide() -> float:
	var margin: float = 28.0
	_place(goal, Vector2(margin, 30.0), 1.0)
	_place(score, Vector2((size.x - 360.0) * 0.5, 24.0), 1.0)
	_place_rack(Vector2(size.x - margin - (98.0 * 4.0 + 8.0 * 3.0), 32.0), 98.0, 8.0)
	_tray_top = size.y - 158.0
	_coins.position = Vector2(margin, _tray_top + 26.0)
	_hint.visible = true
	_hint.position = Vector2(margin, _tray_top + 86.0)
	_hint.size = Vector2(250.0, 54.0)
	_roll.position = Vector2(size.x - margin - 176.0, _tray_top + 12.0)
	_roll.size = Vector2(176.0, 62.0)
	_play.position = Vector2(size.x - margin - 176.0, _tray_top + 84.0)
	_play.size = Vector2(176.0, 62.0)
	return 168.0

## Portrait: scaled goal and scoreboard side by side, rack below, actions along the bottom.
func _arrange_tall() -> float:
	var margin: float = 16.0
	var shrink: float = 0.74
	var gap: float = size.x - margin * 2.0 - (300.0 + 360.0) * shrink
	_place(goal, Vector2(margin, 34.0), shrink)
	_place(score, Vector2(margin + 300.0 * shrink + gap, 28.0), shrink)
	var card: float = 84.0
	_place_rack(Vector2((size.x - (card * 4.0 + 8.0 * 3.0)) * 0.5, 142.0), card, 8.0)
	_tray_top = size.y - 196.0
	_hint.visible = false
	var row: float = size.y - 16.0 - 62.0
	_coins.position = Vector2(margin, row + 7.0)
	var left: float = margin + 112.0
	var width: float = (size.x - margin - left - 10.0) * 0.5
	_roll.position = Vector2(left, row)
	_roll.size = Vector2(width, 62.0)
	_play.position = Vector2(left + width + 10.0, row)
	_play.size = Vector2(width, 62.0)
	return 142.0 + card + 12.0

## Position a fixed-size widget and scale it about its top-left corner.
func _place(widget: Control, at: Vector2, widget_scale: float) -> void:
	widget.pivot_offset = Vector2.ZERO
	widget.position = at
	widget.scale = Vector2.ONE * widget_scale

## Lay the four rack cards out left to right.
func _place_rack(at: Vector2, card_size: float, gap: float) -> void:
	_jokers.position = at
	for index: int in _jokers.get_child_count():
		var card: BuildCard = _jokers.get_child(index) as BuildCard
		card.custom_minimum_size = Vector2.ONE * card_size
		card.size = Vector2.ONE * card_size
		card.position = Vector2(float(index) * (card_size + gap), 0.0)

## Every bonus and Joker tile, occupied or not.
func _cards() -> Array[BuildCard]:
	var cards: Array[BuildCard] = []
	for card: BuildCard in _jokers.get_children():
		cards.append(card)
	for dock: DieDock in _docks.get_children():
		cards.append(dock.card)
	return cards

## Find the tile showing a runtime owner.
func _card_for(owner_id: StringName) -> BuildCard:
	for card: BuildCard in _cards():
		if not card.is_empty() and card.owner_id == owner_id:
			return card
	return null

## Push the reduced-motion preference into every widget.
func _apply_motion() -> void:
	goal.reduced_motion = reduced_motion
	score.reduced_motion = reduced_motion
	banner.reduced_motion = reduced_motion
	_coins.reduced_motion = reduced_motion
	_roll.reduced_motion = reduced_motion
	_play.reduced_motion = reduced_motion
	_tooltip.reduced_motion = reduced_motion
	for card: BuildCard in _cards():
		card.reduced_motion = reduced_motion

## Small uppercase eyebrow lettering, as in the style guide.
func _spaced(text: String) -> String:
	return " ".join(text.to_upper().split(""))

## Explain a hovered bonus or Joker.
func _on_card_hover(card: BuildCard, hovered: bool) -> void:
	if not hovered:
		_close_tooltip(card)
		return
	hover_ticked.emit()
	var family: StringName = &"joker" if card.definition is JokerDefinition else &"bonus"
	_open_tooltip(card, card.get_global_rect(), _spaced(words.render(family, {}, locale)), card.definition)

## Explain a hovered upgrade tag.
func _on_tag_hover(dock: DieDock, hovered: bool) -> void:
	if not hovered:
		_close_tooltip(dock)
		return
	hover_ticked.emit()
	_open_tooltip(dock, dock.tag_rect(), _spaced(words.render(&"upgrade", {}, locale)), dock.upgrade)

## Place the explanation next to a window-pixel rectangle.
func _open_tooltip(source: Control, rect: Rect2, eyebrow: String, definition: BuildDefinition) -> void:
	_tooltip_owner = source
	var local: Rect2 = Rect2(rect.position / _ui_scale, rect.size / _ui_scale)
	_tooltip.present(local, size, eyebrow, definition, words, locale)

## Only the element that opened the explanation may close it.
func _close_tooltip(source: Control) -> void:
	if _tooltip_owner == source:
		dismiss_tooltip()

## Available actions acknowledge the pointer.
func _on_action_hover(button: ActionButton) -> void:
	if not button.disabled:
		hover_ticked.emit()

## Relay the roll intent.
func _on_roll() -> void:
	roll_pressed.emit()

## Relay the play intent.
func _on_play() -> void:
	play_pressed.emit()

## Relay the banner action.
func _on_continue() -> void:
	continue_pressed.emit()
