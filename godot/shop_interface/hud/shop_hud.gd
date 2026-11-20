extends Control
class_name ShopHud
## Shop HUD: the stock, the player's rack and die columns, purse, and the two shop actions.
## On desktop the stock lies on the table's back half. On phones everything for sale sits
## in one labelled counter card, so what is the shop's and what is the player's never mix. Everything is drag and drop: pressing an item picks it up, and
## releasing it over a destination becomes an intent (buy, place, move, sell). The HUD then
## animates what the host confirms. Prices, stock, and ownership stay in ShopSession,
## which this HUD only reads.

# --- Types ---

## What the player is currently holding, if anything.
enum Held { NONE, OFFER, JOKER, BONUS }

# --- Signals ---

## Buy shelf slot `offer_index`; bonuses carry the receiving die.
signal buy_requested(offer_index: int, die_id: StringName)
## Sell an owned bonus or Joker.
signal sell_requested(owner_id: StringName)
## Move a bonus between dice.
signal move_requested(from_die: StringName, to_die: StringName)
## Pay to restock the whole shelf.
signal refresh_pressed
## Leave the shop.
signal leave_pressed
## The player picked something up.
signal picked
## A freshly stocked slot landed on the shelf (`order` counts from zero).
signal dealt(order: int)
## A press was refused; `at` is a window-pixel point near the cause.
signal refused(reason: String, at: Vector2)
## The pointer reached an interactive element; hosts may answer with a soft tick.
signal hover_ticked
## The player asked for the main menu from the settings card.
signal main_menu_requested

# --- Constants ---

## Unscaled shelf slot footprint in HUD units.
const SLOT_SIZE: Vector2 = Vector2(92.0, 126.0)
## Height kept above a shelf row for its group captions.
const CAPTION_HEIGHT: float = 24.0
## Height of the counter's heading and help lines in portrait, above its two rows of goods.
const TALL_HEADER: float = 70.0
## Height of the counter in phone landscape: a heading column and one row of goods.
const SIDE_COUNTER: float = 124.0
## Width the counter's row of goods needs in phone landscape; the heading takes the rest.
const SIDE_GOODS_WIDTH: float = 460.0
## Counter fill on phones: a pale lavender that sets the shop apart from the cream status
## cards and from the cream tiles lying on it.
const COUNTER_FILL: Color = Color(0.905882, 0.85098, 0.929412)
## Shelf groups, in caption order.
const GROUP_JOKERS: int = 0
## Known bonuses.
const GROUP_BONUSES: int = 1
## Pointer travel, in HUD units, before a picked-up item starts following the pointer.
const DRAG_DISTANCE: float = 6.0
## Shelf slot scene; one per known offer.
const SLOT: PackedScene = preload("res://shop_interface/hud/offer_card.tscn")
## Floating text scene; instances free themselves.
const POPUP: PackedScene = preload("res://round_interface/hud/score_popup.tscn")
## Glossary key of the help line shown while nothing is held.
const NOTE_IDLE: StringName = &"ui.shop.note.idle"

# --- Member variables ---

## Removes springs, sway, deals, and flights across every widget.
var reduced_motion: bool = false:
	set(value):
		reduced_motion = value
		if is_node_ready():
			_apply_motion()
## While true the HUD ignores presses: the host is presenting a purchase that is still
## resolving. Locking puts down whatever is held.
var locked: bool = false:
	set(value):
		locked = value
		if value and is_node_ready():
			_release()
## Glossary for names and captions.
var words: KeywordCatalog
## Explicit locale for rendered names; empty follows the game locale.
var locale: String = ""
## Shop state, read only.
var _session: ShopSession
## Shelf slots in display order: Jokers, then bonuses.
var _slots: Array[OfferCard] = []
## What the player holds.
var _held: Held = Held.NONE
## Shelf slot being bought, for Held.OFFER.
var _held_slot: OfferCard
## Runtime owner being moved or sold, for Held.JOKER and Held.BONUS.
var _held_owner: StringName
## Source die of a held bonus.
var _held_die: StringName
## Tile that represents the held item on screen.
var _held_tile: BuildCard
## Window-pixel rectangle the held item started from; flights begin there.
var _origin: Rect2
## Whether the primary button is down.
var _pressing: bool = false
## Window-pixel point of the current press.
var _press_at: Vector2
## Destination tile the dragged item is over, or null.
var _hot: BuildCard
## Whether the dragged item is over the purse.
var _over_purse: bool = false
## Whether the held item is following the pointer.
var _dragging: bool = false
## Die whose sheet is open because the pointer rests on the die itself.
var _hovered_die: StringName
## Element whose explanation is open.
var _tooltip_owner: Control
## Arrangement solved by the last `arrange()`; the same one a round uses for this window.
var layout: HudLayout = HudLayout.new()
## Window pixels per HUD unit.
var _ui_scale: float = 1.0
## Shelf area on the felt, in HUD units.
var _shelf_rect: Rect2
## Goods area inside the counter card on phones, in HUD units; empty on desktop.
var _goods_rect: Rect2
## Ink for marks drawn straight on the wallpaper.
var _wall_ink: Color = GameColors.INK
## Window-pixel rectangle of each die at rest, in run order.
var _die_rects: Array[Rect2] = []
## Displayed coin balance.
var _coin_balance: int = 0
## Sign with the shop's caption and the contextual help line.
@onready var _sign: Control = $Sign
## Host-supplied line, such as which round comes next.
@onready var _title: Label = %Title
## Contextual help: what a press will do right now.
@onready var _note: Label = %Note
## Four Joker slots in rack order.
@onready var _jokers: Control = $Jokers
## Parent of the generated shelf slots.
@onready var _shelf: Control = $Shelf
## Five die columns in run order.
@onready var _docks: Control = $Docks
## Coin purse; also where owned items are sold.
@onready var _coins: CoinChip = $Coins
## Sale value of the held item, shown beside the purse.
@onready var _sell_badge: PanelContainer = $SellBadge
## Amount inside the sale badge.
@onready var _sell_amount: Label = %SellAmount
## The word "sell" inside the sale badge.
@onready var _sell_word: Label = $SellBadge/Row/Word
## Paid whole-shop restock.
@onready var _refresh: ActionButton = $Refresh
## Leave the shop.
@onready var _leave: ActionButton = $Leave
## Parent for floating text.
@onready var _popups: Control = $Popups
## Tile that follows the pointer during a drag and flies on purchases and sales.
@onready var _ghost: BuildCard = $Ghost
## Hover explanation card.
@onready var _tooltip: BuildTooltip = $Tooltip
## Settings button and card, above everything else.
@onready var settings: SettingsMenu = $Settings
## Shelf group captions, drawn on the felt or on the counter.
@onready var _captions: Array[Label] = [$CaptionJokers as Label, $CaptionBonuses as Label]
## Caption naming the player's rack on phones, where it sits near the goods.
@onready var _rack_caption: Label = $CaptionRack
## Small heading on the sign: the word "shop".
@onready var _eyebrow: Label = %Eyebrow
## Sign face; phones recolor it into the counter.
@onready var _face: Panel = $Sign/Face

# --- Member functions ---

## Ready callback: connect the fixed widgets.
func _ready() -> void:
	_refresh.pressed.connect(_on_refresh)
	_leave.pressed.connect(_on_leave)
	_refresh.mouse_entered.connect(_on_action_hover.bind(_refresh))
	_leave.mouse_entered.connect(_on_action_hover.bind(_leave))
	for card: BuildCard in _jokers.get_children():
		card.pressed.connect(_on_joker_pressed)
		card.hover_changed.connect(_on_joker_hover)
	for dock: DieDock in _docks.get_children():
		dock.pressed.connect(_on_dock_pressed)
		dock.hover_changed.connect(_on_dock_hover)
	settings.main_menu_requested.connect(main_menu_requested.emit)
	settings.open_changed.connect(_on_settings_open)
	_ghost.hide()
	_sell_badge.hide()
	_apply_motion()

## Lay out for a window size and return the rectangle (window pixels) kept for the table.
## `density` is window pixels per logical pixel; zero asks the display. The arrangement is
## the round's (see `HudLayout`), so dice, columns, purse, and actions stay where they were.
func arrange(viewport: Vector2, density: float = 0.0) -> Rect2:
	layout = HudLayout.solve(viewport, density)
	_ui_scale = layout.ui_scale
	scale = Vector2.ONE * _ui_scale
	position = Vector2.ZERO
	size = layout.size
	_arrange_counter()
	_coins.position = layout.purse
	# The sale badge sits beside the purse where the tray has room, above it otherwise.
	var beside: bool = layout.shape == HudLayout.Shape.WIDE
	_sell_badge.position = layout.purse + (Vector2(118.0, 5.0) if beside else Vector2(0.0, -44.0))
	_refresh.position = layout.secondary.position
	_refresh.size = layout.secondary.size
	_leave.position = layout.primary.position
	_leave.size = layout.primary.size
	_popups.size = size
	settings.arrange(size, _settings_slot())
	_close_tooltip()
	# A rotation moves every tile away from the pointer without telling them it left.
	for card: BuildCard in _jokers.get_children():
		card.set_hovered(false)
	for dock: DieDock in _docks.get_children():
		dock.card.set_hovered(false)
	for slot: OfferCard in _slots:
		slot.card.set_hovered(false)
	return Rect2(layout.table.position * _ui_scale, layout.table.size * _ui_scale)

## Align docks, the rack, and the shelf with the framed table (all inputs in window pixels).
func align_table(columns: PackedFloat32Array, table_bottom: float, shelf: Rect2, die_rects: Array[Rect2]) -> void:
	var spacing: float = absf(columns[1] - columns[0]) / _ui_scale if columns.size() > 1 else 200.0
	var foot: Vector2 = DieDock.footprint(spacing)
	var dock_top: float = table_bottom / _ui_scale + layout.dock_gap
	for index: int in mini(columns.size(), _docks.get_child_count()):
		var dock: DieDock = _docks.get_child(index) as DieDock
		dock.fit(spacing, index % 2)
		dock.position = Vector2(columns[index] / _ui_scale - foot.x * 0.5, dock_top)
	_shelf_rect = Rect2(shelf.position / _ui_scale, shelf.size / _ui_scale)
	_die_rects = die_rects
	_place_rack()
	_layout_shelf()

## Show a freshly stocked shop: the caption, the build, and a new shelf that deals in.
func show_shop(session: ShopSession, caption: String, words_: KeywordCatalog, locale_: String, deal: bool) -> void:
	_session = session
	words = words_
	locale = locale_
	show_caption(caption)
	_eyebrow.text = _spaced(words.render(&"ui.shop", {}, locale))
	_captions[GROUP_JOKERS].text = _spaced(words.render(&"ui.shop.jokers", {}, locale))
	_captions[GROUP_BONUSES].text = _spaced(words.render(&"ui.shop.bonuses", {}, locale))
	_rack_caption.text = _spaced(words.render(&"ui.shop.your_jokers", {}, locale))
	_sell_word.text = words.render(&"ui.shop.sell", {}, locale)
	_refresh.title = words.render(&"ui.shop.refresh", {}, locale)
	_leave.title = words.render(&"ui.next_round", {}, locale)
	_place_rack()
	_build_shelf(deal)
	sync()

## Replace the host's line on the sign, for example after a language change.
func show_caption(caption: String) -> void:
	_title.text = caption

## Redraw everything that depends on shop state, after any committed change.
func sync() -> void:
	_release()
	var run: MechanicsRun = _session.run
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
	for slot: OfferCard in _slots:
		_show_slot(slot)
	_refresh.set_cost(_session.refresh_cost())
	_refresh.set_available(run.coins >= _session.refresh_cost())
	_leave.set_available(true)
	show_coins(run.coins, false)

## Show the coin balance, optionally counting to it.
func show_coins(coins: int, animate: bool) -> void:
	_coin_balance = coins
	_coins.set_coins(coins, animate)

## Fly the last picked item from where it was to its new owner's tile, then land with a punch.
func fly_to_owner(owner_id: StringName) -> void:
	var destination: BuildCard = _card_for(owner_id)
	if not destination or reduced_motion:
		if destination:
			destination.trigger(1.0)
		return
	_launch_ghost(destination.definition)
	destination.modulate.a = 0.0
	var target: Rect2 = destination.get_global_rect()
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_ghost, "position", target.position / _ui_scale, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_ghost, "size", target.size / _ui_scale, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(_land_on.bind(destination))

## Fly the last picked item into the purse and report the coins it fetched.
func fly_to_purse(sold: IllustratedDefinition, gained: int) -> void:
	popup(_coins.anchor() + Vector2(0.0, -30.0) * _ui_scale, Juice.signed(float(gained)), GameColors.BUTTER, 28, true)
	if reduced_motion:
		return
	_launch_ghost(sold)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_ghost, "position", _coins.anchor() / _ui_scale - Vector2.ONE * 18.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_ghost, "size", Vector2.ONE * 36.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_ghost, "modulate:a", 0.0, 0.1).set_delay(0.2)
	tween.chain().tween_callback(_ghost.hide)

## Spawn floating text at a window-pixel point.
func popup(at: Vector2, text: String, fill: Color, font_size: int = 24, with_coin: bool = false) -> void:
	var node: ScorePopup = POPUP.instantiate() as ScorePopup
	_popups.add_child(node)
	node.reduced_motion = reduced_motion
	node.position = at / _ui_scale
	node.launch(text, fill.lerp(Color.WHITE, 0.28), font_size, -40.0, with_coin)

## Window-pixel point above the purse, for cost popups.
func purse_anchor() -> Vector2:
	return _coins.anchor() + Vector2(0.0, -30.0) * _ui_scale

## Recolor the free-slot outlines that sit on the wallpaper.
func set_wall_ink(ink: Color) -> void:
	_wall_ink = ink
	_place_rack()
	for dock: DieDock in _docks.get_children():
		dock.card.set_slot_ink(ink)

## Follow the pointer: a press on an item picks it up (see the press handlers), moving
## carries it, and releasing drops it. Only a completed drag consumes the release.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not _session or locked or settings.is_open():
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_pressing = true
			_press_at = button.position
		else:
			_pressing = false
			if _dragging:
				_drop_at(button.position)
				get_viewport().set_input_as_handled()
			elif _held != Held.NONE:
				# A press without a drag only inspects the item.
				_release()
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if not motion:
		return
	if _pressing and _held != Held.NONE and not _dragging and motion.position.distance_to(_press_at) > DRAG_DISTANCE * _ui_scale:
		_start_drag()
	if _dragging:
		_ghost.position = motion.position / _ui_scale - _ghost.size * 0.5
		_mark_hot(motion.position)
	elif _held == Held.NONE and motion.device != InputEvent.DEVICE_ID_EMULATION:
		# A finger cannot rest on a die; only a real pointer opens sheets by hovering.
		_hover_die(_die_at(motion.position))

## Position a widget and scale it about its top-left corner.
func _place(widget: Control, at: Vector2, widget_scale: float) -> void:
	widget.pivot_offset = Vector2.ZERO
	widget.position = at
	widget.scale = Vector2.ONE * widget_scale

## Size the sign for the window. On desktop it is the small card of the top band. On phones
## it becomes the counter: one card holding the heading, the help line, and every item for
## sale. In portrait the counter fills the space above the table; in landscape it lies
## across the top, over the status rail and the far side of the table.
func _arrange_counter() -> void:
	var style: StyleBoxFlat = _face.get_theme_stylebox("panel") as StyleBoxFlat
	var title_size: int = 25
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_goods_rect = Rect2()
	match layout.shape:
		HudLayout.Shape.TALL:
			var top: float = layout.status.position.y
			var card: Rect2 = Rect2(10.0, top, size.x - 20.0, layout.table.position.y - 6.0 - top)
			_place(_sign, card.position, 1.0)
			_sign.size = card.size
			# One heading line: the shop's name on the left, the host's caption on the right.
			_eyebrow.position = Vector2(16.0, 11.0)
			# The settings button sits in the counter's top-right corner; the heading and the
			# help line stop short of it.
			var heading_end: float = _settings_slot().position.x - card.position.x - 8.0
			_title.position = Vector2(card.size.x * 0.4, 5.0)
			_title.size = Vector2(heading_end - card.size.x * 0.4, 26.0)
			_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			title_size = 15
			_note.position = Vector2(16.0, 31.0)
			_note.size = Vector2(heading_end - 16.0, TALL_HEADER - 33.0)
			_goods_rect = Rect2(card.position + Vector2(10.0, TALL_HEADER), card.size - Vector2(20.0, TALL_HEADER + 8.0))
			style.bg_color = COUNTER_FILL
		HudLayout.Shape.SIDE:
			var card: Rect2 = Rect2(layout.status.position, Vector2(layout.secondary.position.x - 10.0 - layout.status.position.x, SIDE_COUNTER))
			var heading: float = clampf(card.size.x - SIDE_GOODS_WIDTH, 150.0, 260.0)
			_place(_sign, card.position, 1.0)
			_sign.size = card.size
			_eyebrow.position = Vector2(14.0, 10.0)
			_title.position = Vector2(14.0, 25.0)
			_title.size = Vector2(heading - 22.0, 24.0)
			title_size = 17
			_note.position = Vector2(14.0, 50.0)
			_note.size = Vector2(heading - 22.0, card.size.y - 58.0)
			_goods_rect = Rect2(card.position + Vector2(heading, 6.0), card.size - Vector2(heading + 10.0, 12.0))
			style.bg_color = COUNTER_FILL
		_:
			_place(_sign, layout.status.position, layout.status_scale)
			_sign.size = Vector2(layout.status.size.x / layout.status_scale, HudLayout.STATUS_HEIGHT)
			_eyebrow.position = Vector2(20.0, 12.0)
			_title.position = Vector2(20.0, 28.0)
			_title.size = Vector2(_sign.size.x - 38.0, 38.0)
			_note.position = Vector2(20.0, 66.0)
			_note.size = Vector2(_sign.size.x - 36.0, 42.0)
			style.bg_color = GameColors.CONTROL_SURFACE
	_title.add_theme_font_size_override("font_size", title_size)

## Settings button slot: the layout's, except in portrait, where it tucks inside the
## counter's top-right corner instead of straddling its border.
func _settings_slot() -> Rect2:
	if layout.shape == HudLayout.Shape.TALL:
		return Rect2(layout.settings.position + Vector2(-6.0, 6.0), layout.settings.size)
	return layout.settings

## Lay the four rack cards out. Desktop and phone landscape use the layout's slot (a line
## or a 2 × 2 block). In portrait the counter takes the space above the table, so the rack
## moves onto the free back half of the felt: the table then holds everything the player
## owns, Jokers above dice above bonuses.
func _place_rack() -> void:
	var at: Vector2 = layout.rack
	var on_felt: bool = layout.shape == HudLayout.Shape.TALL and _shelf_rect.has_area()
	var step: float = layout.rack_card + layout.rack_gap
	if on_felt:
		var width: float = step * 4.0 - layout.rack_gap
		at = Vector2(_shelf_rect.get_center().x - width * 0.5, _shelf_rect.end.y - layout.rack_card)
	_jokers.position = at
	for index: int in _jokers.get_child_count():
		var card: BuildCard = _jokers.get_child(index) as BuildCard
		card.custom_minimum_size = Vector2.ONE * layout.rack_card
		card.size = Vector2.ONE * layout.rack_card
		card.position = Vector2(float(index % layout.rack_columns), floorf(float(index) / float(layout.rack_columns))) * step
		card.set_slot_ink(GameColors.INK if on_felt else _wall_ink)
	# Phones name the rack, since goods of the same shape sit nearby.
	_rack_caption.visible = layout.shape != HudLayout.Shape.WIDE
	_rack_caption.reset_size()
	if on_felt:
		_rack_caption.position = Vector2(at.x + 2.0, at.y - _rack_caption.size.y - 2.0)
		_rack_caption.add_theme_color_override("font_color", GameColors.INK)
	else:
		var block: Vector2 = Vector2(step * float(layout.rack_columns) - layout.rack_gap, step * 2.0 - layout.rack_gap)
		_rack_caption.position = Vector2(at.x + (block.x - _rack_caption.size.x) * 0.5, at.y + block.y + 4.0)
		_rack_caption.add_theme_color_override("font_color", _wall_ink)

## Replace the shelf slots for a new stock; `deal` pops them in one after another.
func _build_shelf(deal: bool) -> void:
	for slot: OfferCard in _slots:
		_shelf.remove_child(slot)
		slot.queue_free()
	_slots.clear()
	for index: int in _session.offers.size():
		var slot: OfferCard = SLOT.instantiate() as OfferCard
		_shelf.add_child(slot)
		slot.reduced_motion = reduced_motion
		slot.offer_index = index
		slot.family = _session.offers[index].family
		slot.pressed.connect(_on_slot_pressed)
		slot.hover_changed.connect(_on_slot_hover)
		_slots.append(slot)
		_show_slot(slot)
		if deal:
			slot.deal(0.08 + 0.07 * float(index))
			if slot.stocked and not reduced_motion:
				get_tree().create_timer(0.08 + 0.07 * float(index)).timeout.connect(dealt.emit.bind(index))
	_layout_shelf()

## Draw one slot from the session: goods, price, and whether the purse covers it.
func _show_slot(slot: OfferCard) -> void:
	var offer: ShopOffer = _session.offers[slot.offer_index]
	slot.show_offer(offer, slot.offer_index, _session.run.coins >= offer.price)

## Lay the stock out in groups: Jokers, then bonuses. On desktop it is one row on the felt.
## On phones it fills the counter: two rows in portrait (Jokers, then bonuses), one row in
## landscape with the Jokers nearest the rack.
func _layout_shelf() -> void:
	for caption: Label in _captions:
		caption.hide()
	if _slots.is_empty():
		return
	var groups: Array[int] = [GROUP_JOKERS, GROUP_BONUSES]
	match layout.shape:
		HudLayout.Shape.TALL:
			var half: Vector2 = Vector2(_goods_rect.size.x, _goods_rect.size.y * 0.5)
			_layout_row(_slots_of([GROUP_JOKERS]), Rect2(_goods_rect.position, half))
			_layout_row(_slots_of([GROUP_BONUSES]), Rect2(_goods_rect.position + Vector2(0.0, half.y), half))
		HudLayout.Shape.SIDE:
			_layout_row(_slots_of([GROUP_BONUSES, GROUP_JOKERS]), _goods_rect)
		_:
			if _shelf_rect.has_area():
				_layout_row(_slots_of(groups), _shelf_rect)

## Slots of the given groups, group by group in the order asked.
func _slots_of(groups: Array[int]) -> Array[OfferCard]:
	var row: Array[OfferCard] = []
	for group: int in groups:
		for slot: OfferCard in _slots:
			if _group_of(slot) == group:
				row.append(slot)
	return row

## Shelf group of a slot.
func _group_of(slot: OfferCard) -> int:
	return GROUP_JOKERS if slot.family == ShopSession.JOKER else GROUP_BONUSES

## Largest slot scale at which `row` fits `area` under its captions.
func _row_scale(row: Array[OfferCard], area: Rect2) -> float:
	var free_width: float = area.size.x - _row_gaps(row)
	var free_height: float = area.size.y - CAPTION_HEIGHT
	# On phones goods are no larger than the rack and bonus tiles they turn into.
	var largest: float = 1.0 if layout.shape == HudLayout.Shape.WIDE else layout.rack_card / SLOT_SIZE.x
	return clampf(minf(free_width / (SLOT_SIZE.x * float(row.size())), free_height / SLOT_SIZE.y), 0.4, largest)

## Total space between the slots of `row`.
func _row_gaps(row: Array[OfferCard]) -> float:
	var total: float = 0.0
	for index: int in range(1, row.size()):
		total += _gap(_group_of(row[index]) != _group_of(row[index - 1]))
	return total

## Space before a slot: small inside a group, wider between groups, and tighter on phones,
## where width is better spent on the tiles.
func _gap(between_groups: bool) -> float:
	if layout.shape == HudLayout.Shape.WIDE:
		return 30.0 if between_groups else 12.0
	return 18.0 if between_groups else 6.0

## Center one row of slots in `area`, shrinking them together until they fit. A caption
## names each group above its first slot.
func _layout_row(row: Array[OfferCard], area: Rect2) -> void:
	if row.is_empty():
		return
	var slot_scale: float = _row_scale(row, area)
	var x: float = area.get_center().x - (SLOT_SIZE.x * slot_scale * float(row.size()) + _row_gaps(row)) * 0.5
	var y: float = area.position.y + CAPTION_HEIGHT + (area.size.y - CAPTION_HEIGHT - SLOT_SIZE.y * slot_scale) * 0.5
	for index: int in row.size():
		var group: int = _group_of(row[index])
		var starts_group: bool = index == 0 or group != _group_of(row[index - 1])
		if index > 0:
			x += _gap(starts_group)
		row[index].fit(slot_scale)
		row[index].position = Vector2(x, y)
		if starts_group:
			_captions[group].show()
			_captions[group].position = Vector2(x + 2.0, y - CAPTION_HEIGHT + 3.0)
		x += SLOT_SIZE.x * slot_scale

## Pick up shelf goods, unless the purse or the build cannot take them.
func _on_slot_pressed(slot: OfferCard) -> void:
	if locked:
		return
	_release()
	var block: String = _session.buy_block(_session.offers[slot.offer_index])
	if not block.is_empty():
		slot.refuse()
		refused.emit(block, slot.get_global_rect().get_center())
		return
	_held = Held.OFFER
	_held_slot = slot
	if slot.family == ShopSession.JOKER:
		_set_note(&"ui.shop.note.joker")
	else:
		_set_note(&"ui.shop.note.bonus")
	_pick_up(slot.card, slot, slot.definition)

## Pick up an owned Joker.
func _on_joker_pressed(card: BuildCard) -> void:
	if locked:
		return
	_release()
	_held = Held.JOKER
	_held_owner = card.owner_id
	_set_note(&"ui.shop.note.sell")
	_pick_up(card, card, card.definition)

## Pick up the bonus on a die column, if it has one.
func _on_dock_pressed(dock: DieDock) -> void:
	if locked or not dock.bonus:
		return
	_release()
	_held = Held.BONUS
	_held_owner = StringName("bonus:" + String(dock.die_id))
	_held_die = dock.die_id
	_set_note(&"ui.shop.note.move")
	_pick_up(dock.card, dock, dock.bonus)

## Finish a drag: act on what lies under the pointer, or send the item back.
func _drop_at(point: Vector2) -> void:
	var die_id: StringName = _die_at(point)
	var bonus_in_hand: bool = _held == Held.BONUS or (_held == Held.OFFER and _held_slot.family == ShopSession.BONUS)
	# Flights after a drop start where the item was let go, not where it was picked up.
	_origin = _ghost.get_global_rect()
	if _holding_joker_offer() and _rack_rect().has_point(point):
		buy_requested.emit(_held_slot.offer_index, &"")
	elif bonus_in_hand and die_id != &"" and die_id != _held_die:
		if die_id not in _session.free_bonus_dice():
			_dock_for(die_id).card.refuse()
			refused.emit(ShopSession.NO_BONUS_SLOT, _dock_for(die_id).get_global_rect().get_center())
			_release(true)
		elif _held == Held.BONUS:
			move_requested.emit(_held_die, die_id)
		else:
			buy_requested.emit(_held_slot.offer_index, die_id)
	elif (_held == Held.JOKER or _held == Held.BONUS) and _purse_rect().has_point(point):
		sell_requested.emit(_held_owner)
	else:
		_release(true)

## Common pick-up: remember the origin, lift the tile, light destinations, and explain it.
func _pick_up(tile: BuildCard, source: Control, definition: IllustratedDefinition) -> void:
	_held_tile = tile
	_origin = tile.get_global_rect()
	tile.set_picked(true)
	_show_destinations()
	_close_tooltip()
	if definition:
		_open_tooltip(source, [_family_caption(definition)], [definition])
	picked.emit()

## Put down whatever is held and clear every cue that went with it. `fly_back` sends a
## dragged item home along the way it came instead of snapping.
func _release(fly_back: bool = false) -> void:
	var tile: BuildCard = _held_tile
	if tile:
		tile.set_picked(false)
	if fly_back and _dragging and tile and not reduced_motion:
		var home: Rect2 = tile.get_global_rect()
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(_ghost, "position", home.position / _ui_scale, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(_ghost, "size", home.size / _ui_scale, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.chain().tween_callback(_settle_back.bind(tile))
	else:
		_ghost.hide()
		if tile:
			tile.modulate.a = 1.0
	_held = Held.NONE
	_held_slot = null
	_held_tile = null
	_held_owner = &""
	_held_die = &""
	_dragging = false
	_hot = null
	_over_purse = false
	_sell_badge.hide()
	for card: BuildCard in _jokers.get_children():
		card.set_target(false)
	for dock: DieDock in _docks.get_children():
		dock.card.set_target(false)
	_close_tooltip()
	_set_note(NOTE_IDLE)

## End of a flight home: the real tile takes over from the flying one.
func _settle_back(tile: BuildCard) -> void:
	if not _dragging:
		_ghost.hide()
	tile.modulate.a = 1.0

## Light the places the held item can go.
func _show_destinations() -> void:
	if _holding_joker_offer():
		for card: BuildCard in _jokers.get_children():
			card.set_target(true)
	elif _held == Held.BONUS or _held == Held.OFFER:
		var free: Array[StringName] = _session.free_bonus_dice()
		for dock: DieDock in _docks.get_children():
			dock.card.set_target(dock.die_id in free)
	if _held == Held.JOKER or _held == Held.BONUS:
		_sell_amount.text = Juice.signed(float(_session.owned_sell_value(_held_owner)))
		_sell_badge.reset_size()
		_sell_badge.show()
		if not reduced_motion:
			Juice.pop_in(_sell_badge, 0.2)

## The held tile starts following the pointer; its source dims in place. Explanations open
## beside their source, where the item travels, so they close; only desktop shelf goods keep
## theirs, in the free band at the top.
func _start_drag() -> void:
	_dragging = true
	if not (_tooltip_owner is OfferCard and layout.shape == HudLayout.Shape.WIDE):
		_close_tooltip()
	_held_tile.modulate.a = 0.35
	_dress_ghost(_held_tile.definition)
	_ghost.size = Vector2.ONE * 84.0
	_ghost.modulate.a = 1.0
	_ghost.show()

## Brighten the destination under a dragged item, and nudge the sale badge over the purse.
func _mark_hot(point: Vector2) -> void:
	var hot: BuildCard = null
	if _holding_joker_offer() and _rack_rect().has_point(point):
		for card: BuildCard in _jokers.get_children():
			if card.is_empty():
				hot = card
				break
	elif _held == Held.BONUS or (_held == Held.OFFER and _held_slot.family == ShopSession.BONUS):
		var dock: DieDock = _dock_for(_die_at(point))
		if dock and dock.die_id in _session.free_bonus_dice():
			hot = dock.card
	if hot != _hot:
		if _hot:
			_hot.set_target(true)
		if hot:
			hot.set_target(true, true)
		_hot = hot
	var over_purse: bool = (_held == Held.JOKER or _held == Held.BONUS) and _purse_rect().has_point(point)
	if over_purse and not _over_purse and not reduced_motion:
		Juice.punch(_sell_badge, 0.22, 0.35)
	_over_purse = over_purse

## Prepare the flying tile at the last origin.
func _launch_ghost(definition: IllustratedDefinition) -> void:
	_dress_ghost(definition)
	_ghost.position = _origin.position / _ui_scale
	_ghost.size = _origin.size / _ui_scale
	_ghost.modulate.a = 1.0
	_ghost.show()

## Give the flying tile the right face.
func _dress_ghost(definition: IllustratedDefinition) -> void:
	_ghost.custom_minimum_size = Vector2.ZERO
	if definition:
		_ghost.show_definition(definition, &"")
	else:
		_ghost.show_mark("?")

## End of a purchase flight: reveal the real tile with a punch.
func _land_on(destination: BuildCard) -> void:
	_ghost.hide()
	destination.modulate.a = 1.0
	destination.trigger(1.0)

## Whether the player is in the middle of buying a Joker.
func _holding_joker_offer() -> bool:
	return _held == Held.OFFER and _held_slot.family == ShopSession.JOKER

## Die under a window-pixel point: its column below the table or the die itself.
func _die_at(point: Vector2) -> StringName:
	for index: int in _docks.get_child_count():
		var dock: DieDock = _docks.get_child(index) as DieDock
		if dock.get_global_rect().has_point(point) or (index < _die_rects.size() and _die_rects[index].has_point(point)):
			return dock.die_id
	return &""

## Column widget for a die.
func _dock_for(die_id: StringName) -> DieDock:
	for dock: DieDock in _docks.get_children():
		if dock.die_id == die_id:
			return dock
	return null

## Tile showing a runtime owner, on the rack or a die column.
func _card_for(owner_id: StringName) -> BuildCard:
	for card: BuildCard in _jokers.get_children():
		if not card.is_empty() and card.owner_id == owner_id:
			return card
	for dock: DieDock in _docks.get_children():
		if not dock.card.is_empty() and dock.card.owner_id == owner_id:
			return dock.card
	return null

## Window-pixel rectangle of the whole rack, free slots included.
func _rack_rect() -> Rect2:
	var first: Rect2 = (_jokers.get_child(0) as Control).get_global_rect()
	return first.merge((_jokers.get_child(_jokers.get_child_count() - 1) as Control).get_global_rect()).grow(8.0 * _ui_scale)

## Window-pixel rectangle of the purse and its sale badge.
func _purse_rect() -> Rect2:
	var rect: Rect2 = _coins.get_global_rect()
	if _sell_badge.visible:
		rect = rect.merge(_sell_badge.get_global_rect())
	return rect.grow(12.0 * _ui_scale)

## Resting on a die opens its sheet beside its column.
func _hover_die(die_id: StringName) -> void:
	if die_id == _hovered_die:
		return
	var previous: DieDock = _dock_for(_hovered_die)
	if previous:
		_on_dock_hover(previous, false)
	_hovered_die = die_id
	var dock: DieDock = _dock_for(die_id)
	if dock and dock.has_details():
		_on_dock_hover(dock, true)

## Explain hovered shelf goods while nothing is held.
func _on_slot_hover(slot: OfferCard, hovered: bool) -> void:
	if _held != Held.NONE:
		return
	if hovered and slot.definition:
		hover_ticked.emit()
		_open_tooltip(slot, [_family_caption(slot.definition)], [slot.definition])
	elif _tooltip_owner == slot:
		_close_tooltip()

## Explain a hovered owned Joker while nothing is held.
func _on_joker_hover(card: BuildCard, hovered: bool) -> void:
	if _held != Held.NONE:
		return
	if hovered:
		hover_ticked.emit()
		_open_tooltip(card, [_family_caption(card.definition)], [card.definition])
	elif _tooltip_owner == card:
		_close_tooltip()

## Explain a hovered die column while nothing is held: upgrade, then bonus.
func _on_dock_hover(dock: DieDock, hovered: bool) -> void:
	if _held != Held.NONE:
		return
	if not hovered:
		if _tooltip_owner == dock:
			_close_tooltip()
		return
	hover_ticked.emit()
	var eyebrows: PackedStringArray = []
	var definitions: Array[BuildDefinition] = []
	if dock.upgrade:
		eyebrows.append(_spaced(words.render(&"upgrade", {}, locale)))
		definitions.append(dock.upgrade)
	if dock.bonus:
		eyebrows.append(_spaced(words.render(&"bonus", {}, locale)))
		definitions.append(dock.bonus)
	_open_tooltip(dock, eyebrows, definitions)

## Open the explanation next to its source; phones open it above the source first, clear of
## the finger that asked. Desktop shelf goods explain themselves in the free band between the
## sign and the rack instead, so the dice stay in view.
func _open_tooltip(source: Control, eyebrows: PackedStringArray, definitions: Array[BuildDefinition]) -> void:
	_tooltip_owner = source
	var wide: bool = layout.shape == HudLayout.Shape.WIDE
	var rect: Rect2 = source.get_global_rect()
	var anchor: Rect2 = Rect2(rect.position / _ui_scale, rect.size / _ui_scale)
	if source is OfferCard and wide:
		anchor = Rect2(Vector2(size.x * 0.5 - 1.0, 8.0), Vector2(2.0, 0.0))
	_tooltip.present(anchor, size, eyebrows, definitions, words, locale, not wide)

## Close any open explanation.
func _close_tooltip() -> void:
	_tooltip_owner = null
	_tooltip.dismiss()

## Spaced family caption for an item's explanation.
func _family_caption(definition: BuildDefinition) -> String:
	return _spaced(words.render(&"joker" if definition is JokerDefinition else &"bonus", {}, locale))

## Small uppercase eyebrow lettering, as in the style guide.
func _spaced(text: String) -> String:
	return " ".join(text.to_upper().split(""))

## Update the contextual help line from its glossary key.
func _set_note(key: StringName) -> void:
	if words:
		_note.text = words.render(key, {}, locale)

## Push the reduced-motion preference into every widget.
func _apply_motion() -> void:
	_coins.reduced_motion = reduced_motion
	_refresh.reduced_motion = reduced_motion
	_leave.reduced_motion = reduced_motion
	_tooltip.reduced_motion = reduced_motion
	settings.reduced_motion = reduced_motion
	_ghost.reduced_motion = reduced_motion
	for card: BuildCard in _jokers.get_children():
		card.reduced_motion = reduced_motion
	for dock: DieDock in _docks.get_children():
		dock.card.reduced_motion = reduced_motion
	for slot: OfferCard in _slots:
		slot.reduced_motion = reduced_motion

## An opening settings card puts down whatever is held.
func _on_settings_open(open: bool) -> void:
	if open:
		_pressing = false
		_release()

## Available actions acknowledge the pointer.
func _on_action_hover(button: ActionButton) -> void:
	if not button.disabled:
		hover_ticked.emit()

## Relay the refresh intent after putting down anything held.
func _on_refresh() -> void:
	if locked:
		return
	_release()
	refresh_pressed.emit()

## Relay the leave intent after putting down anything held.
func _on_leave() -> void:
	if locked:
		return
	_release()
	leave_pressed.emit()
