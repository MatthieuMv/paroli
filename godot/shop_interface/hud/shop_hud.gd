extends Control
class_name ShopHud
## Shop HUD: stock on the table's back half, the player's rack and die columns, purse, and
## the two shop actions. Everything is drag and drop: pressing an item picks it up, and
## releasing it over a destination becomes an intent (buy, place, move, sell). The HUD then
## animates what the host confirms. Prices, stock, and ownership stay in ShopSession,
## which this HUD only reads.

# --- Types ---

## What the player is currently holding, if anything.
enum Held { NONE, OFFER, JOKER, BONUS }

# --- Signals ---

## Buy shelf slot `offer_index`; bonuses carry the receiving die. Index -1 is never sent.
signal buy_requested(offer_index: int, die_id: StringName)
## Buy an unknown item of a family at its discount; bonuses carry the receiving die.
signal random_requested(family: StringName, die_id: StringName)
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

# --- Constants ---

## Reference window for the landscape arrangement.
const WIDE_DESIGN: Vector2 = Vector2(1280.0, 900.0)
## Reference window for the portrait arrangement.
const TALL_DESIGN: Vector2 = Vector2(540.0, 960.0)
## Aspect ratio below which the portrait arrangement is used.
const TALL_ASPECT: float = 1.1
## Unscaled die dock footprint in HUD units.
const DOCK_SIZE: Vector2 = Vector2(104.0, 126.0)
## Unscaled shelf slot footprint in HUD units.
const SLOT_SIZE: Vector2 = Vector2(92.0, 126.0)
## Pointer travel before a picked-up item starts following the pointer.
const DRAG_DISTANCE: float = 6.0
## Shelf slot scene; one per known offer plus the random purchases.
const SLOT: PackedScene = preload("res://shop_interface/hud/offer_card.tscn")
## Floating text scene; instances free themselves.
const POPUP: PackedScene = preload("res://round_interface/hud/score_popup.tscn")
## Help line shown while nothing is held.
const NOTE_IDLE: String = "Drag an item where it goes: Jokers to the rack, bonuses to a die."

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
## Shelf slots in display order: known offers, then random purchases.
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
## Window pixels per HUD unit.
var _ui_scale: float = 1.0
## Whether the portrait arrangement is active.
var _tall: bool = false
## Top of the bottom tray in HUD units.
var _tray_top: float = 0.0
## Top of the action buttons in HUD units; docks must end above it.
var _actions_top: float = 0.0
## Shelf area on the felt, in HUD units.
var _shelf_rect: Rect2
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
## Shelf group captions, drawn on the felt.
@onready var _captions: Array[Label] = [$CaptionJokers as Label, $CaptionBonuses as Label, $CaptionLucky as Label]

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
	_ghost.hide()
	_sell_badge.hide()
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
	_popups.size = size
	_close_tooltip()
	return Rect2(0.0, top * _ui_scale, viewport.x, (_tray_top - top) * _ui_scale)

## Align docks and the shelf with the framed table (all inputs in window pixels).
func align_table(columns: PackedFloat32Array, table_bottom: float, shelf: Rect2, die_rects: Array[Rect2]) -> void:
	var spacing: float = absf(columns[1] - columns[0]) / _ui_scale if columns.size() > 1 else 200.0
	var dock_scale: float = _dock_scale(spacing)
	var dock_top: float = table_bottom / _ui_scale + (6.0 if _tall else 14.0)
	if _tall:
		dock_scale = minf(dock_scale, maxf(0.4, (_actions_top - 14.0 - dock_top) / DOCK_SIZE.y))
	for index: int in mini(columns.size(), _docks.get_child_count()):
		var dock: DieDock = _docks.get_child(index) as DieDock
		dock.scale = Vector2.ONE * dock_scale
		dock.position = Vector2(columns[index] / _ui_scale - DOCK_SIZE.x * 0.5 * dock_scale, dock_top)
	_shelf_rect = Rect2(shelf.position / _ui_scale, shelf.size / _ui_scale)
	_die_rects = die_rects
	_layout_shelf()

## Show a freshly stocked shop: the caption, the build, and a new shelf that deals in.
func show_shop(session: ShopSession, caption: String, words_: KeywordCatalog, locale_: String, deal: bool) -> void:
	_session = session
	words = words_
	locale = locale_
	_title.text = caption
	_build_shelf(deal)
	sync()

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

## Turn an unknown shelf tile over to show what a random purchase found.
func reveal_random(family: StringName, found: IllustratedDefinition) -> void:
	for slot: OfferCard in _slots:
		if slot.is_mystery() and slot.family == family:
			_origin = slot.card.get_global_rect()
			slot.reveal(found)

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
	for card: BuildCard in _jokers.get_children():
		card.set_slot_ink(ink)
	for dock: DieDock in _docks.get_children():
		dock.card.set_slot_ink(ink)

## Follow the pointer: a press on an item picks it up (see the press handlers), moving
## carries it, and releasing drops it. Only a completed drag consumes the release.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not _session or locked:
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
	if _pressing and _held != Held.NONE and not _dragging and motion.position.distance_to(_press_at) > DRAG_DISTANCE:
		_start_drag()
	if _dragging:
		_ghost.position = motion.position / _ui_scale - _ghost.size * 0.5
		_mark_hot(motion.position)
	elif _held == Held.NONE:
		_hover_die(_die_at(motion.position))

## Landscape: sign and rack share the top band; purse and actions share the tray.
func _arrange_wide() -> float:
	var margin: float = 28.0
	_place(_sign, Vector2(margin, 30.0), 1.0)
	_place_rack(Vector2(size.x - margin - (98.0 * 4.0 + 8.0 * 3.0), 32.0), 98.0, 8.0)
	_tray_top = size.y - 160.0
	_actions_top = _tray_top
	_coins.position = Vector2(margin, _tray_top + 26.0)
	_sell_badge.position = Vector2(margin + 118.0, _tray_top + 31.0)
	_refresh.position = Vector2(size.x - margin - 176.0, _tray_top + 12.0)
	_refresh.size = Vector2(176.0, 62.0)
	_leave.position = Vector2(size.x - margin - 176.0, _tray_top + 84.0)
	_leave.size = Vector2(176.0, 62.0)
	return 168.0

## Portrait: sign and rack stack at the top; purse and actions run along the bottom.
func _arrange_tall() -> float:
	var margin: float = 16.0
	_place(_sign, Vector2(margin, 34.0), 0.74)
	var card: float = 84.0
	_place_rack(Vector2((size.x - (card * 4.0 + 8.0 * 3.0)) * 0.5, 142.0), card, 8.0)
	var row: float = size.y - 16.0 - 62.0
	var widest_spacing: float = size.x / (StageCamera.TABLE_HALF_WIDTH * 2.0) * 3.5
	_actions_top = row
	_tray_top = row - 14.0 - DOCK_SIZE.y * _dock_scale(widest_spacing) - 6.0
	_coins.position = Vector2(margin, row + 7.0)
	_sell_badge.position = Vector2(margin, row - 34.0)
	var left: float = margin + 112.0
	var width: float = (size.x - margin - left - 10.0) * 0.5
	_refresh.position = Vector2(left, row)
	_refresh.size = Vector2(width, 62.0)
	_leave.position = Vector2(left + width + 10.0, row)
	_leave.size = Vector2(width, 62.0)
	return 142.0 + card + 12.0

## Dock scale for a die column spacing in HUD units.
func _dock_scale(spacing: float) -> float:
	return clampf((spacing - 6.0) / DOCK_SIZE.x, 0.5, 1.0)

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

## Replace the shelf slots for a new stock; `deal` pops them in one after another.
func _build_shelf(deal: bool) -> void:
	for slot: OfferCard in _slots:
		_shelf.remove_child(slot)
		slot.queue_free()
	_slots.clear()
	var families: Array[StringName] = []
	for index: int in _session.offers.size():
		families.append(&"")
	if _session.rules.random_joker:
		families.append(ShopSession.JOKER)
	if _session.rules.random_bonus:
		families.append(ShopSession.BONUS)
	for index: int in families.size():
		var slot: OfferCard = SLOT.instantiate() as OfferCard
		_shelf.add_child(slot)
		slot.reduced_motion = reduced_motion
		slot.offer_index = index if index < _session.offers.size() else -1
		slot.family = families[index] if slot.offer_index < 0 else _session.offers[index].family
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
	var coins: int = _session.run.coins
	if slot.is_mystery():
		var price: int = _session.random_price(slot.family)
		slot.show_mystery(slot.family, price, _session.random_block(slot.family) != ShopSession.EMPTY_POOL, coins >= price)
	else:
		var offer: ShopOffer = _session.offers[slot.offer_index]
		slot.show_offer(offer, slot.offer_index, coins >= offer.price)

## Spread the slots across the felt in three groups: Jokers, bonuses, random purchases.
func _layout_shelf() -> void:
	if _slots.is_empty() or _shelf_rect.size.x <= 0.0:
		for caption: Label in _captions:
			caption.hide()
		return
	var groups: Array[int] = []
	for slot: OfferCard in _slots:
		groups.append(2 if slot.is_mystery() else (0 if slot.family == ShopSession.JOKER else 1))
	var gap: float = 12.0
	var group_gap: float = 30.0
	var breaks: int = 0
	for index: int in range(1, groups.size()):
		if groups[index] != groups[index - 1]:
			breaks += 1
	# Slots shrink together until the whole row, captions included, fits the felt.
	var free_width: float = _shelf_rect.size.x - gap * float(_slots.size() - 1 - breaks) - group_gap * float(breaks)
	var slot_scale: float = clampf(minf(free_width / (SLOT_SIZE.x * float(_slots.size())), (_shelf_rect.size.y - 24.0) / SLOT_SIZE.y), 0.4, 1.0)
	var row_width: float = SLOT_SIZE.x * slot_scale * float(_slots.size()) + gap * float(_slots.size() - 1 - breaks) + group_gap * float(breaks)
	var x: float = _shelf_rect.get_center().x - row_width * 0.5
	var y: float = _shelf_rect.position.y + 24.0 + (_shelf_rect.size.y - 24.0 - SLOT_SIZE.y * slot_scale) * 0.5
	var starts: Dictionary[int, float] = {}
	for index: int in _slots.size():
		if index > 0:
			x += group_gap if groups[index] != groups[index - 1] else gap
		if not starts.has(groups[index]):
			starts[groups[index]] = x
		_slots[index].scale = Vector2.ONE * slot_scale
		_slots[index].position = Vector2(x, y)
		x += SLOT_SIZE.x * slot_scale
	for group: int in _captions.size():
		_captions[group].visible = starts.has(group)
		if starts.has(group):
			_captions[group].position = Vector2(starts[group] + 2.0, y - 27.0)

## Pick up shelf goods, unless the purse or the build cannot take them.
func _on_slot_pressed(slot: OfferCard) -> void:
	if locked:
		return
	_release()
	var block: String = _session.random_block(slot.family) if slot.is_mystery() else _session.buy_block(_session.offers[slot.offer_index])
	if not block.is_empty():
		slot.refuse()
		refused.emit(block, slot.get_global_rect().get_center())
		return
	_held = Held.OFFER
	_held_slot = slot
	if slot.family == ShopSession.JOKER:
		_set_note("A random Joker at a discount. Drop it on your rack." if slot.is_mystery() else "Drop it on your Joker rack to buy.")
	else:
		_set_note("A random bonus at a discount. Drop it on a die." if slot.is_mystery() else "Drop it on a die with a free slot to buy.")
	_pick_up(slot.card, slot, slot.definition)

## Pick up an owned Joker.
func _on_joker_pressed(card: BuildCard) -> void:
	if locked:
		return
	_release()
	_held = Held.JOKER
	_held_owner = card.owner_id
	_set_note("Drop it on your purse to sell.")
	_pick_up(card, card, card.definition)

## Pick up the bonus on a die column, if it has one.
func _on_dock_pressed(dock: DieDock) -> void:
	if locked or not dock.bonus:
		return
	_release()
	_held = Held.BONUS
	_held_owner = StringName("bonus:" + String(dock.die_id))
	_held_die = dock.die_id
	_set_note("Drop it on another die to move it, or on your purse to sell.")
	_pick_up(dock.card, dock, dock.bonus)

## Finish a drag: act on what lies under the pointer, or send the item back.
func _drop_at(point: Vector2) -> void:
	var die_id: StringName = _die_at(point)
	var bonus_in_hand: bool = _held == Held.BONUS or (_held == Held.OFFER and _held_slot.family == ShopSession.BONUS)
	# Flights after a drop start where the item was let go, not where it was picked up.
	_origin = _ghost.get_global_rect()
	if _holding_joker_offer() and _rack_rect().has_point(point):
		if _held_slot.is_mystery():
			random_requested.emit(ShopSession.JOKER, &"")
		else:
			buy_requested.emit(_held_slot.offer_index, &"")
	elif bonus_in_hand and die_id != &"" and die_id != _held_die:
		if die_id not in _session.free_bonus_dice():
			_dock_for(die_id).card.refuse()
			refused.emit(ShopSession.NO_BONUS_SLOT, _dock_for(die_id).get_global_rect().get_center())
			_release(true)
		elif _held == Held.BONUS:
			move_requested.emit(_held_die, die_id)
		elif _held_slot.is_mystery():
			random_requested.emit(ShopSession.BONUS, die_id)
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

## The held tile starts following the pointer; its source dims in place. Shelf goods keep
## their explanation open in the top bay; other explanations would be in the way.
func _start_drag() -> void:
	_dragging = true
	if not (_tooltip_owner is OfferCard and not _tall):
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

## Whether the player is in the middle of buying a Joker, known or random.
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

## Place the explanation next to its source. Shelf goods explain themselves in the free bay
## between the sign and the rack (landscape), so the dice and columns stay in view.
func _open_tooltip(source: Control, eyebrows: PackedStringArray, definitions: Array[BuildDefinition]) -> void:
	_tooltip_owner = source
	var rect: Rect2 = source.get_global_rect()
	var anchor: Rect2 = Rect2(rect.position / _ui_scale, rect.size / _ui_scale)
	if source is OfferCard and not _tall:
		anchor = Rect2(Vector2(size.x * 0.5 - 1.0, 8.0), Vector2(2.0, 0.0))
	_tooltip.present(anchor, size, eyebrows, definitions, words, locale)

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

## Update the contextual help line.
func _set_note(text: String) -> void:
	_note.text = text

## Push the reduced-motion preference into every widget.
func _apply_motion() -> void:
	_coins.reduced_motion = reduced_motion
	_refresh.reduced_motion = reduced_motion
	_leave.reduced_motion = reduced_motion
	_tooltip.reduced_motion = reduced_motion
	_ghost.reduced_motion = reduced_motion
	for card: BuildCard in _jokers.get_children():
		card.reduced_motion = reduced_motion
	for dock: DieDock in _docks.get_children():
		dock.card.reduced_motion = reduced_motion
	for slot: OfferCard in _slots:
		slot.reduced_motion = reduced_motion

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
