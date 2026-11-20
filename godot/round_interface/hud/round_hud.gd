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
## The player asked for the main menu from the settings card.
signal main_menu_requested

# --- Constants ---

## Popup fill colors by semantic role; plum outlines keep them readable on felt and paper.
const POPUP_COLORS: Dictionary[StringName, Color] = {
	&"points": GameColors.SKY,
	&"mult": GameColors.CHERRY,
	&"coins": GameColors.BUTTER,
	&"tempo": GameColors.TANGERINE,
}
## Result card height, as a share of the window, in portrait: low enough for a thumb.
const TALL_CARD_LEVEL: float = 0.6
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
## Arrangement solved by the last `arrange()`: shape, scale, and every widget's slot.
var layout: HudLayout = HudLayout.new()
## Round target and banked score.
@onready var goal: GoalMeter = $Goal
## Combination plate, factor tiles, and revealed total.
@onready var score: ScoreBoard = $Score
## End-of-round card.
@onready var banner: ResultBanner = $Banner
## Settings button and card, above everything else.
@onready var settings: SettingsMenu = $Settings
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
## A press or tap pins the tooltip until the next press elsewhere; hover alone never pins.
var _tooltip_pinned: bool = false

# --- Member functions ---

## Ready callback: connect intents and hover explanations.
func _ready() -> void:
	_roll.pressed.connect(_on_roll)
	_play.pressed.connect(_on_play)
	banner.action_pressed.connect(_on_continue)
	settings.main_menu_requested.connect(main_menu_requested.emit)
	settings.open_changed.connect(_on_settings_open)
	_roll.mouse_entered.connect(_on_action_hover.bind(_roll))
	_play.mouse_entered.connect(_on_action_hover.bind(_play))
	for card: BuildCard in _jokers.get_children():
		card.hover_changed.connect(_on_card_hover)
		card.pressed.connect(_on_card_pressed)
	for dock: DieDock in _docks.get_children():
		dock.hover_changed.connect(_on_dock_hover)
		dock.pressed.connect(_on_dock_pressed)
	_apply_motion()

## Lay out for a window size and return the rectangle (window pixels) kept for the table.
## `density` is window pixels per logical pixel; zero asks the display. Phones get a larger
## HUD and their own arrangements (see `HudLayout`).
func arrange(viewport: Vector2, density: float = 0.0) -> Rect2:
	layout = HudLayout.solve(viewport, density)
	_ui_scale = layout.ui_scale
	scale = Vector2.ONE * _ui_scale
	position = Vector2.ZERO
	size = layout.size
	goal.size = Vector2(layout.status.size.x / layout.status_scale, HudLayout.STATUS_HEIGHT)
	_place(goal, layout.status.position, layout.status_scale)
	score.set_stacked(layout.board_stacked)
	# Only the desktop band leaves the space under the scoreboard free for a popup.
	score.merge_above = layout.shape != HudLayout.Shape.WIDE
	_place(score, layout.board.position, layout.board_scale)
	_place_rack()
	_coins.position = layout.purse
	_hint.visible = layout.hint.has_area()
	_hint.position = layout.hint.position
	_hint.size = layout.hint.size
	_roll.position = layout.secondary.position
	_roll.size = layout.secondary.size
	_play.position = layout.primary.position
	_play.size = layout.primary.size
	banner.arrange(size, TALL_CARD_LEVEL if layout.shape == HudLayout.Shape.TALL else 0.5)
	_popups.size = size
	settings.arrange(size, layout.settings)
	dismiss_tooltip()
	# A rotation moves every tile away from the pointer without telling them it left.
	for card: BuildCard in _cards():
		card.set_hovered(false)
	return Rect2(layout.table.position * _ui_scale, layout.table.size * _ui_scale)

## Align die docks and row captions with the framed table (all inputs in window pixels).
## Docks hang just below `table_bottom` and take their size from the die columns' spacing.
func align_table(columns: PackedFloat32Array, pixels_per_unit: float, table_bottom: float, play_point: Vector2, roll_point: Vector2) -> void:
	var spacing: float = absf(columns[1] - columns[0]) / _ui_scale if columns.size() > 1 else 200.0
	var foot: Vector2 = DieDock.footprint(spacing)
	var dock_top: float = table_bottom / _ui_scale + layout.dock_gap
	for index: int in mini(columns.size(), _docks.get_child_count()):
		var dock: DieDock = _docks.get_child(index) as DieDock
		# Neighbors alternate name lanes, like the dice alternate rows on the felt.
		dock.fit(spacing, index % 2)
		dock.position = Vector2(columns[index] / _ui_scale - foot.x * 0.5, dock_top)
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
	goal.set_target_caption(_spaced(words.render(&"ui.target", {}, locale)))
	_hint.text = words.render(&"ui.round_hint", {}, locale)
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

## Establish the round's name, target, and banked score without animation.
func show_round(title: String, target: float, banked: float) -> void:
	goal.set_round(_spaced(title), target, banked)

## Rename the round in place, leaving its target, gauge, and stamp as they are.
func show_round_title(title: String) -> void:
	goal.set_caption(_spaced(title))

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

## Run the eligibility cue on exactly these owners' cards. Returns how many cards have just
## become eligible, so the host can mark the moment with a sound.
func mark_eligible(owner_ids: Array[StringName]) -> int:
	var started: int = 0
	for card: BuildCard in _cards():
		if card.set_eligible(not card.is_empty() and card.owner_id in owner_ids):
			started += 1
	return started

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

## Close any open explanation, pinned or not, for example when a reveal starts.
func dismiss_tooltip() -> void:
	_tooltip_owner = null
	_tooltip_pinned = false
	_tooltip.dismiss()

## A press anywhere outside the pinned source releases its explanation without consuming
## the press, so the same tap can still select a die or press a button.
func _input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if _tooltip_pinned and button and button.pressed and not _tooltip_owner.get_global_rect().has_point(button.position):
		dismiss_tooltip()

## Position a widget and scale it about its top-left corner.
func _place(widget: Control, at: Vector2, widget_scale: float) -> void:
	widget.pivot_offset = Vector2.ZERO
	widget.position = at
	widget.scale = Vector2.ONE * widget_scale

## Lay the four rack cards out in the layout's rows: one line, or a 2 × 2 block.
func _place_rack() -> void:
	_jokers.position = layout.rack
	var step: float = layout.rack_card + layout.rack_gap
	for index: int in _jokers.get_child_count():
		var card: BuildCard = _jokers.get_child(index) as BuildCard
		card.custom_minimum_size = Vector2.ONE * layout.rack_card
		card.size = Vector2.ONE * layout.rack_card
		card.position = Vector2(float(index % layout.rack_columns), floorf(float(index) / float(layout.rack_columns))) * step

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
	settings.reduced_motion = reduced_motion
	for card: BuildCard in _cards():
		card.reduced_motion = reduced_motion

## Small uppercase eyebrow lettering, as in the style guide.
func _spaced(text: String) -> String:
	return " ".join(text.to_upper().split(""))

## Explain a hovered Joker.
func _on_card_hover(card: BuildCard, hovered: bool) -> void:
	if not hovered:
		_close_tooltip(card)
		return
	hover_ticked.emit()
	_open_card(card)

## Pin a pressed Joker's explanation; pressing it again releases it.
func _on_card_pressed(card: BuildCard) -> void:
	if _tooltip_owner == card and _tooltip_pinned:
		dismiss_tooltip()
		return
	_open_card(card)
	_tooltip_pinned = true

## Explain a hovered die column: its upgrade, then its bonus.
func _on_dock_hover(dock: DieDock, hovered: bool) -> void:
	if not hovered:
		_close_tooltip(dock)
		return
	hover_ticked.emit()
	_open_dock(dock)

## Pin a pressed die column's sheet; pressing it again releases it.
func _on_dock_pressed(dock: DieDock) -> void:
	if not dock.has_details():
		return
	if _tooltip_owner == dock and _tooltip_pinned:
		dismiss_tooltip()
		return
	_open_dock(dock)
	_tooltip_pinned = true

## Single-section explanation for a rack card.
func _open_card(card: BuildCard) -> void:
	if _tooltip_owner == card:
		return
	_open_tooltip(card, [_spaced(words.render(&"joker", {}, locale))], [card.definition])

## Die sheet: every piece of equipment on one die, upgrade first.
func _open_dock(dock: DieDock) -> void:
	if _tooltip_owner == dock:
		return
	var eyebrows: PackedStringArray = []
	var definitions: Array[BuildDefinition] = []
	if dock.upgrade:
		eyebrows.append(_spaced(words.render(&"upgrade", {}, locale)))
		definitions.append(dock.upgrade)
	if dock.bonus:
		eyebrows.append(_spaced(words.render(&"bonus", {}, locale)))
		definitions.append(dock.bonus)
	_open_tooltip(dock, eyebrows, definitions)

## Open the explanation next to its source. Phones open it above the source first, clear of
## the finger that asked.
func _open_tooltip(source: Control, eyebrows: PackedStringArray, definitions: Array[BuildDefinition]) -> void:
	_tooltip_owner = source
	_tooltip_pinned = false
	var rect: Rect2 = source.get_global_rect()
	_tooltip.present(Rect2(rect.position / _ui_scale, rect.size / _ui_scale), size, eyebrows, definitions, words, locale, layout.shape != HudLayout.Shape.WIDE)

## Only the element that opened an unpinned explanation may close it.
func _close_tooltip(source: Control) -> void:
	if _tooltip_owner == source and not _tooltip_pinned:
		dismiss_tooltip()

## An opening settings card closes any explanation under it.
func _on_settings_open(open: bool) -> void:
	if open:
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
