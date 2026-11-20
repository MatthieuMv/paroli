extends Control
class_name SettingsMenu
## Settings button and its card: sound, language, and the way back to the main menu.
## It covers its HUD so the card can dim everything under it, but lets the pointer through
## while closed. Preferences live in `GameSettings`; the card only edits them.

# --- Signals ---

## The player asked for the main menu. The action stays disabled until a host enables it.
signal main_menu_requested
## The card opened or closed; hosts may pause hover feedback meanwhile.
signal open_changed(open: bool)

# --- Constants ---

## Card width where the window has room for it.
const CARD_WIDTH: float = 340.0
## Opacity of an action that is not available yet.
const UNAVAILABLE_ALPHA: float = 0.45

# --- Member variables ---

## Removes the pop-in.
var reduced_motion: bool = false
## Whether the main menu action is offered; there is no main menu yet.
var main_menu_available: bool = false:
	set(value):
		main_menu_available = value
		if is_node_ready():
			_show_main_menu()
## Glossary for the card's captions.
var _words: KeywordCatalog = GameKeywords.new()
## Preferences the card edits.
var _settings: GameSettings = GameSettings.shared()
## Button with the cog, placed by the HUD.
@onready var _gear: Button = $Gear
## Dimmer behind the open card; a press on it closes the card.
@onready var _dim: ColorRect = $Dim
## Centered settings card.
@onready var _card: PanelContainer = $Card
## Card heading.
@onready var _title: Label = %Title
## Caption of the sound row.
@onready var _sound_caption: Label = %SoundCaption
## Sound on or off.
@onready var _sound: Button = %Sound
## Caption of the language row.
@onready var _language_caption: Label = %LanguageCaption
## One button per language, in `GameSettings.LOCALES` order.
@onready var _languages: Array[Button] = [%French as Button, %English as Button]
## Back to the main menu.
@onready var _main_menu: Button = %MainMenu
## Closes the card.
@onready var _close: Button = %Close

# --- Member functions ---

## Ready callback: start closed and follow the shared preferences.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.hide()
	_card.hide()
	_gear.pressed.connect(open)
	_dim.gui_input.connect(_on_dim_input)
	_sound.toggled.connect(_settings.set_sound_enabled)
	for index: int in _languages.size():
		_languages[index].pressed.connect(_on_language.bind(index))
		_languages[index].text = GameSettings.LOCALE_NAMES[GameSettings.LOCALES[index]]
	_main_menu.pressed.connect(_on_main_menu)
	_close.pressed.connect(close)
	_settings.changed.connect(_refresh)
	_refresh()

## Cover `bounds` (parent-local size) and put the cog in `gear` (parent-local rectangle).
func arrange(bounds: Vector2, gear: Rect2) -> void:
	position = Vector2.ZERO
	size = bounds
	_gear.position = gear.position
	_gear.size = gear.size
	_card.custom_minimum_size.x = minf(CARD_WIDTH, bounds.x - 32.0)
	_place_card()

## Window-pixel rectangle of the settings button.
func button_rect() -> Rect2:
	return _gear.get_global_rect()

## Whether the card is showing.
func is_open() -> bool:
	return _card.visible

## Show the card over a dimmed screen.
func open() -> void:
	if is_open():
		return
	_refresh()
	_dim.show()
	_card.show()
	_place_card()
	if not reduced_motion:
		Juice.pop_in(_card, 0.24)
	open_changed.emit(true)

## Hide the card.
func close() -> void:
	if not is_open():
		return
	_dim.hide()
	_card.hide()
	open_changed.emit(false)

## Escape closes an open card.
func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if is_open() and key and key.pressed and key.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()

## Center the card, shrunk around its contents.
func _place_card() -> void:
	_card.reset_size()
	_card.position = ((size - _card.size) * 0.5).max(Vector2.ONE * 8.0)

## Show the current preferences in the current language.
func _refresh() -> void:
	_title.text = _words.render(&"ui.settings", {}, "")
	_sound_caption.text = _words.render(&"ui.settings.sound", {}, "")
	_language_caption.text = _words.render(&"ui.settings.language", {}, "")
	_main_menu.text = _words.render(&"ui.settings.main_menu", {}, "")
	_close.text = _words.render(&"ui.settings.close", {}, "")
	_sound.set_pressed_no_signal(_settings.sound_enabled)
	_sound.text = _words.render(&"ui.settings.on" if _settings.sound_enabled else &"ui.settings.off", {}, "")
	var active: String = _settings.active_locale()
	for index: int in _languages.size():
		_languages[index].set_pressed_no_signal(GameSettings.LOCALES[index] == active)
	_show_main_menu()
	if is_open():
		_place_card.call_deferred()

## Grey the main menu action out while there is no main menu.
func _show_main_menu() -> void:
	_main_menu.disabled = not main_menu_available
	_main_menu.modulate.a = 1.0 if main_menu_available else UNAVAILABLE_ALPHA

## A press on the dimmed screen closes the card.
func _on_dim_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		close()
		_dim.accept_event()

## Switch language; pressing the current one again keeps it selected.
func _on_language(index: int) -> void:
	_settings.set_locale(GameSettings.LOCALES[index])
	_refresh()

## Close, then report the request.
func _on_main_menu() -> void:
	close()
	main_menu_requested.emit()
