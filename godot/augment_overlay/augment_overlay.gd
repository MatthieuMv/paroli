extends Control
class_name AugmentOverlay
## Responsive choice presentation over a live game; never applies an upgrade.

# --- Signals ---

## Lets a host suspend its own gameplay shortcuts while cards cover the table.
signal presentation_changed(blocking: bool)
## Emitted exactly once on commitment, before activation; the host owns game rules.
signal upgrade_selected(upgrade_id: StringName)
## The committed choice finished its activation and the overlay dismissed itself; the host
## resumes the game. A withdrawn offer (`cancel()`) does not emit it.
signal closed

# --- Constants ---

## Smallest size of the Show upgrades action; longer captions widen it.
const RESTORE_SIZE: Vector2 = Vector2(180.0, 44.0)

# --- Member variables ---

## Opacity of the dimmer behind the cards. The light default keeps a bare table visible;
## hosts with a HUD underneath raise it so the heading stays readable over it.
@export_range(0.0, 1.0, 0.01) var dim_opacity: float = 0.28:
	set(value):
		dim_opacity = value
		if is_node_ready():
			_dimmer.color.a = value
## Translucent backdrop behind the cards; it never takes input.
@onready var _dimmer: ColorRect = $Presentation/Dimmer
## Full-screen card presentation blocks pointer input to the underlying game.
@onready var _presentation: Control = $Presentation
## Centered authored layout receives responsive bounds.
@onready var _frame: VBoxContainer = $Presentation/Frame
## The same card instances occupy one row or one column, preserving selection.
@onready var _cards: GridContainer = $Presentation/Frame/Scroll/Cards
## A single unobtrusive control remains while inspecting the game.
@onready var _restore: Button = $Restore
## Inspection cannot bypass a committed choice while its animation is playing.
@onready var _inspect: Button = $Presentation/Frame/Inspect
## Read-only vocabulary used to render the supplied definitions.
var _words: KeywordCatalog = GameKeywords.new()
## Definitions on the cards, kept so a language change can rewrite them.
var _offer: Array[UpgradeDefinition] = []
## Locale the offer is written in; empty follows the game locale.
var _locale: String = ""
## Guard against repeat input and reentrant signal handlers during activation.
var _choosing: bool = false

# --- Member functions ---

## Wire local controls and react to live window rotation or resizing.
func _ready() -> void:
	_inspect.pressed.connect(inspect_game)
	_restore.pressed.connect(show_cards)
	for card: AugmentCard in _cards.get_children():
		card.pressed.connect(_on_card_pressed.bind(card))
		card.activation_finished.connect(_on_activation_finished)
	_dimmer.color.a = dim_opacity
	resized.connect(_resize_layout)
	_resize_layout()

## Accept exactly three non-null choices; invalid input leaves the current offer untouched.
## The host owns offer generation and applying the selected ID. Call after entering the tree.
func open(upgrades: Array[UpgradeDefinition], locale: String = "") -> bool:
	if _choosing or upgrades.size() != 3:
		return false
	for upgrade: UpgradeDefinition in upgrades:
		if not upgrade:
			return false
	_offer = upgrades.duplicate()
	_locale = locale
	_write()
	_inspect.disabled = false
	show()
	show_cards()
	return true

## Rewrite the heading, actions, and cards in another language, keeping the offer and
## whether the player is inspecting the table. Ignored once a choice is committed.
func relabel(locale: String = "") -> void:
	if _choosing or not visible:
		return
	_locale = locale
	_write()

## Withdraw the offer without a choice, for a host that abandons the game underneath.
## Returns false, changing nothing, while a committed choice is still playing.
func cancel() -> bool:
	if _choosing:
		return false
	if visible:
		hide()
		presentation_changed.emit(false)
	return true

## Center the Show upgrades action on a point of this overlay, so a host can keep it off
## its own controls. Unplaced, it stays at the bottom of the overlay.
func place_restore(center: Vector2) -> void:
	_restore.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_restore.size = RESTORE_SIZE.max(_restore.get_combined_minimum_size())
	_restore.position = center - _restore.size * 0.5

## Write the heading, the actions, and every card in the offer's language.
func _write() -> void:
	($Presentation/Frame/Heading as Label).text = _words.render(&"ui.upgrade.title", {}, _locale)
	_inspect.text = _words.render(&"ui.upgrade.inspect", {}, _locale)
	_restore.text = _words.render(&"ui.upgrade.show", {}, _locale)
	for index: int in _offer.size():
		var card: AugmentCard = _cards.get_child(index) as AugmentCard
		card.configure(_offer[index], _words, _locale)

## Hide the dimmer and cards so the host game receives input normally.
func inspect_game() -> void:
	if _choosing:
		return
	_presentation.hide()
	_restore.show()
	presentation_changed.emit(false)

## Restore the exact cards and selection after inspecting the live table.
func show_cards() -> void:
	_presentation.show()
	_restore.hide()
	# Clear any host focus while this mouse/touch-only overlay owns input.
	get_viewport().gui_release_focus()
	presentation_changed.emit(true)

## Expose input ownership without requiring the host to inspect child nodes.
func is_blocking() -> bool:
	return visible and _presentation.visible

## Use viewport orientation, not a fixed desktop breakpoint, to arrange choices.
func _resize_layout() -> void:
	var portrait: bool = size.y > size.x
	var short_view: bool = size.y < 500.0
	var margin: float = 16.0 if size.x < 600.0 or short_view else 36.0
	($Presentation/Frame/Heading as Label).add_theme_font_size_override("font_size", 24 if short_view else 32)
	_frame.add_theme_constant_override("separation", 10 if short_view else 16)
	var width: float = minf(size.x - margin * 2.0, 1080.0)
	var height: float = minf(size.y - margin * 2.0, 760.0 if portrait else (310.0 if short_view else 650.0))
	_cards.columns = 1 if portrait else 3
	for card: AugmentCard in _cards.get_children():
		card.set_compact(portrait, short_view)
	# Explicit equal widths prevent long labels from changing column proportions.
	var gap: float = float(_cards.get_theme_constant("h_separation"))
	var card_width: float = (width - 16.0 - gap * float(_cards.columns - 1)) / float(_cards.columns)
	for card: AugmentCard in _cards.get_children():
		card.custom_minimum_size.x = maxf(0.0, card_width)
	# Container minimum sizes settle after changing orientation and card widths.
	_fit_frame.call_deferred(Vector2(width, height))

## Apply bounds after the previous orientation no longer constrains the frame.
func _fit_frame(dimensions: Vector2) -> void:
	_frame.size = dimensions
	_frame.position = (size - dimensions) * 0.5

## Commit once, notify game logic, then play the selected die's real activation.
func _on_card_pressed(card: AugmentCard) -> void:
	if card.take_keyword_press() or _choosing or not is_blocking():
		return
	_choosing = true
	_inspect.disabled = true
	for choice: AugmentCard in _cards.get_children():
		choice.disabled = true
	upgrade_selected.emit(card.upgrade_id)
	card.play_activation()

## Dismiss only after the native activation has finished, never on initial selection.
func _on_activation_finished() -> void:
	if not _choosing:
		return
	hide()
	_choosing = false
	presentation_changed.emit(false)
	closed.emit()
