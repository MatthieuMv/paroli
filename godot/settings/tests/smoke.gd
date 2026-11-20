extends SceneTree
## Settings check: the button opens the card, sound and language reach the shared
## preferences, the main menu waits greyed out, and the dimmer closes the card.

# --- Constants ---

## Scene under test.
const MENU: PackedScene = preload("res://settings/settings_menu.tscn")

# --- Member variables ---

## Offscreen viewport standing in for the game window.
var _viewport: SubViewport

# --- Member functions ---

## Wait for the scene tree before building the viewport.
func _initialize() -> void:
	_run.call_deferred()

## Drive the card with real pointer input.
func _run() -> void:
	create_timer(30.0).timeout.connect(_abort)
	var settings: GameSettings = GameSettings.shared()
	# Checks never read or write the player's saved preferences.
	settings.storage_path = ""
	var original: String = TranslationServer.get_locale()
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(400, 720)
	root.add_child(_viewport)
	_viewport.notify_mouse_entered()
	var menu: SettingsMenu = MENU.instantiate() as SettingsMenu
	_viewport.add_child(menu)
	menu.reduced_motion = true
	menu.arrange(Vector2(400.0, 720.0), Rect2(338.0, 12.0, 46.0, 46.0))
	await process_frame
	assert(not menu.is_open() and menu.button_rect().position == Vector2(338.0, 12.0))
	# The closed menu lets presses through everywhere but its button.
	assert(menu.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	await _click(menu.button_rect().get_center())
	assert(menu.is_open(), "The button opens the card")
	# Sound.
	var sound: Button = menu.get_node("%Sound") as Button
	assert(sound.button_pressed == settings.sound_enabled)
	await _click(sound.get_global_rect().get_center())
	assert(not settings.sound_enabled and sound.text == GameKeywords.new().render(&"ui.settings.off", {}, ""))
	await _click(sound.get_global_rect().get_center())
	assert(settings.sound_enabled)
	# Language: the card itself switches language at once.
	var english: Button = menu.get_node("%English") as Button
	var french: Button = menu.get_node("%French") as Button
	await _click(english.get_global_rect().get_center())
	assert(settings.active_locale() == "en" and english.button_pressed and not french.button_pressed)
	assert((menu.get_node("%Title") as Label).text == "Settings")
	await _click(french.get_global_rect().get_center())
	assert(settings.active_locale() == "fr" and (menu.get_node("%Title") as Label).text == "Réglages")
	await _click(french.get_global_rect().get_center())
	assert(french.button_pressed, "Pressing the current language keeps it selected")
	# No main menu yet: the action is greyed out and does nothing.
	var asked: Array[bool] = []
	menu.main_menu_requested.connect(func() -> void: asked.append(true))
	var main_menu: Button = menu.get_node("%MainMenu") as Button
	assert(main_menu.disabled and main_menu.modulate.a < 1.0)
	await _click(main_menu.get_global_rect().get_center())
	assert(asked.is_empty() and menu.is_open())
	# A press on the dimmed screen closes the card.
	await _click(Vector2(10.0, 700.0))
	assert(not menu.is_open(), "The dimmer closes the card")
	await _click(menu.button_rect().get_center())
	await _click((menu.get_node("%Close") as Control).get_global_rect().get_center())
	assert(not menu.is_open(), "Close closes the card")
	TranslationServer.set_locale(original)
	print("PASS: settings button, sound, language, greyed main menu, closing.")
	quit()

## Watchdog: report a stalled check instead of hanging.
func _abort() -> void:
	push_error("Settings smoke check stalled")
	quit(1)

## Press and release the primary button at a window position.
func _click(point: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	_viewport.push_input(motion, true)
	for pressed: bool in [true, false]:
		var button: InputEventMouseButton = InputEventMouseButton.new()
		button.position = point
		button.global_position = point
		button.button_index = MOUSE_BUTTON_LEFT
		button.pressed = pressed
		_viewport.push_input(button, true)
		await process_frame
		await process_frame
