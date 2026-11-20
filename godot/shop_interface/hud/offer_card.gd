extends Control
class_name OfferCard
## One slot on the shop shelf: a known offer with its price tag. It reports presses and hover; the shop decides what a press means.

# --- Signals ---

## Primary press or tap on a slot that still holds something.
signal pressed(slot: OfferCard)
## Pointer entered or left a slot that still holds something.
signal hover_changed(slot: OfferCard, hovered: bool)

# --- Constants ---

## Smallest scale the price pill is drawn at, whatever the slot's own scale.
const SMALLEST_TAG_SCALE: float = 0.8

# --- Member variables ---

## Index into ShopSession.offers.
var offer_index: int = -1
## `ShopSession.JOKER` or `ShopSession.BONUS`.
var family: StringName
## Known content; null for an emptied slot.
var definition: IllustratedDefinition
## Whether the slot still holds something to buy.
var stocked: bool = false
## Removes the deal pop.
var reduced_motion: bool = false:
	set(value):
		reduced_motion = value
		if is_node_ready():
			card.reduced_motion = value
## Item tile; the slot, not the tile, answers the pointer.
@onready var card: BuildCard = $Card
## Price pill under the tile.
@onready var _tag: PanelContainer = $Tag
## Asking price.
@onready var _price: Label = $Tag/Row/Price

# --- Member functions ---

## Ready callback: the whole slot is one pointer target.
func _ready() -> void:
	mouse_entered.connect(_on_pointer.bind(true))
	mouse_exited.connect(_on_pointer.bind(false))

## Scale the slot about its top-left corner. Small slots (phones) keep their price pill
## readable: it shrinks less than the tile and grows downward from the tile's edge.
func fit(slot_scale: float) -> void:
	scale = Vector2.ONE * slot_scale
	_tag.pivot_offset = Vector2(_tag.size.x * 0.5, 0.0)
	_tag.scale = Vector2.ONE * maxf(1.0, SMALLEST_TAG_SCALE / slot_scale)

## Show a known offer, or the emptied slot it leaves once sold.
func show_offer(offer: ShopOffer, index: int, affordable: bool) -> void:
	offer_index = index
	family = offer.family
	definition = null if offer.sold else offer.definition
	stocked = not offer.sold
	if offer.sold:
		card.clear()
	elif card.definition != offer.definition:
		card.show_definition(offer.definition, &"")
	_show_price(offer.price, affordable)

## Shake the tile and bump the price to refuse a press.
func refuse() -> void:
	card.refuse()
	if not reduced_motion:
		Juice.punch(_tag, 0.18, 0.35)

## Pop the slot in after a delay, for a freshly stocked shelf.
func deal(delay: float) -> void:
	if reduced_motion or not stocked:
		return
	card.modulate.a = 0.0
	_tag.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(_land)

## Second half of a deal: appear with a pop.
func _land() -> void:
	card.modulate.a = 1.0
	_tag.modulate.a = 1.0
	Juice.pop_in(card, 0.26)

## Price pill: hidden for emptied slots, tinted when the purse is too light.
func _show_price(price: int, affordable: bool) -> void:
	_tag.visible = stocked
	_price.text = str(price)
	var tone: Color = GameColors.INK if affordable else KeywordColors.for_role(&"mult")
	_price.add_theme_color_override("font_color", tone)
	_price.add_theme_color_override("font_outline_color", tone)
	_tag.modulate.a = 1.0 if affordable else 0.8
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if stocked else Control.CURSOR_ARROW

## Hover lifts the tile.
func _on_pointer(entered: bool) -> void:
	if not stocked:
		return
	card.set_hovered(entered)
	hover_changed.emit(self, entered)

## A primary press or tap on stocked goods goes to the shop.
func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button and button.pressed and button.button_index == MOUSE_BUTTON_LEFT and stocked:
		pressed.emit(self)
		accept_event()
