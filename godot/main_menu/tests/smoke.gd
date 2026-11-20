extends SceneTree
## Main menu check: the dice land, the title and actions sit clear of the table on desktop
## and phone windows, New run reports once, dice reroll on a press, and the captions follow
## the language. Pass `-- --capture` with a display to save reference frames under /tmp.

# --- Constants ---

## Scene under test.
const MENU: PackedScene = preload("res://main_menu/main_menu.tscn")
## Window pixels per logical pixel of the phone the layout checks stand in for.
const PHONE_DENSITY: float = 2.625
## Smallest side, in logical pixels, of anything the player presses.
const TOUCH_TARGET: float = 44.0
## Window sizes checked, with the density each stands in for.
const WINDOWS: Array[Vector3] = [
	Vector3(1280.0, 900.0, 1.0),
	Vector3(1080.0, 2340.0, PHONE_DENSITY),
	Vector3(2340.0, 1080.0, PHONE_DENSITY),
]
## Capture file name for each window, in `WINDOWS` order.
const CAPTURES: PackedStringArray = ["desktop", "portrait", "landscape"]

# --- Member variables ---

## Offscreen viewport standing in for the game window.
var _viewport: SubViewport

# --- Member functions ---

## Wait for the scene tree before building the viewport.
func _initialize() -> void:
	_run.call_deferred()

## Drive the menu through real pointer input on each window shape.
func _run() -> void:
	var capture: bool = "--capture" in OS.get_cmdline_user_args()
	create_timer(60.0).timeout.connect(_abort)
	var settings: GameSettings = GameSettings.shared()
	# Checks never read or write the player's saved preferences.
	settings.storage_path = ""
	var original: String = TranslationServer.get_locale()
	settings.set_locale("en")
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1280, 900)
	_viewport.msaa_3d = root.msaa_3d
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	_viewport.notify_mouse_entered()
	var menu: MainMenu = MENU.instantiate() as MainMenu
	menu.muted = true
	menu.reduced_motion = not capture
	_viewport.add_child(menu)
	var hud: MainMenuHud = menu.get_node("Interface/Hud") as MainMenuHud
	var new_run: Button = hud.get_node("%NewRun") as Button
	var quit_button: Button = hud.get_node("%Quit") as Button
	var title: Label = hud.get_node("Title") as Label
	await _settle(menu)
	# Every die shows a face from one to six, in the menu's colors.
	for index: int in 5:
		var die: ParoliDie = menu.stage.dice()[index]
		assert(die.face_value >= 1 and die.face_value <= 6)
		assert(die.palette_color == MainMenu.DIE_COLORS[index])
	# Layout on each window shape.
	for index: int in WINDOWS.size():
		var window: Vector3 = WINDOWS[index]
		_viewport.size = Vector2i(int(window.x), int(window.y))
		menu.display_density = window.z
		await _frames(3)
		var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(window.x, window.y))
		var table: Rect2 = menu.stage.camera.framed_rect
		var label: String = CAPTURES[index]
		assert(bounds.encloses(new_run.get_global_rect().grow(-1.0)), "New run is on screen: " + label)
		assert(not new_run.get_global_rect().intersects(table), "New run sits clear of the table: " + label)
		assert(not title.get_global_rect().intersects(table), "The title sits clear of the table: " + label)
		assert(bounds.encloses(hud.settings.button_rect().grow(-1.0)), "Settings is on screen: " + label)
		for button: Button in [new_run, quit_button, hud.get_node("Settings/Gear") as Button]:
			var logical: Vector2 = button.get_global_rect().size / window.z
			assert(minf(logical.x, logical.y) >= TOUCH_TARGET - 0.5, "Touch target too small: %s on %s" % [button.name, label])
		if capture:
			await create_timer(0.8).timeout
			await _save("/tmp/paroli-main-menu-%s.png" % label)
	_viewport.size = Vector2i(1280, 900)
	menu.display_density = 1.0
	await _frames(3)
	# New run reports once per press and changes nothing else.
	var requests: Array[bool] = []
	menu.new_run_requested.connect(func() -> void: requests.append(true))
	await _click(new_run.get_global_rect().get_center())
	assert(requests.size() == 1, "New run reports the request")
	# A press on a die rerolls it.
	var die: ParoliDie = menu.stage.dice()[2]
	await _click(menu.stage.die_rect(&"die_3").get_center())
	assert(die.is_rolling() or menu.reduced_motion, "A pressed die rolls")
	await _settle(menu)
	# An open settings card keeps presses off the dice and the actions.
	await _click(hud.settings.button_rect().get_center())
	assert(hud.settings.is_open())
	await _click(new_run.get_global_rect().get_center())
	assert(requests.size() == 1, "The settings card covers the actions")
	# That press landed on the dimmer, which closes the card; open it again.
	assert(not hud.settings.is_open())
	await _click(hud.settings.button_rect().get_center())
	# The card speaks French, and so do the actions once it closes.
	await _click((hud.settings.get_node("%French") as Control).get_global_rect().get_center())
	assert(new_run.text == "Nouvelle partie" and quit_button.text == "Quitter")
	await _click((hud.settings.get_node("%Close") as Control).get_global_rect().get_center())
	assert(not hud.settings.is_open())
	settings.set_locale("en")
	assert(new_run.text == "New run")
	TranslationServer.set_locale(original)
	print("PASS: main menu dice, layouts, touch targets, new run, die reroll, settings, language.")
	quit()

## Watchdog: report a stalled check instead of hanging.
func _abort() -> void:
	push_error("Main menu smoke check stalled")
	quit(1)

## Wait until every die has landed.
func _settle(menu: MainMenu) -> void:
	await _frames(2)
	for attempt: int in 240:
		var rolling: bool = false
		for die: ParoliDie in menu.stage.dice():
			rolling = rolling or die.is_rolling()
		if not rolling:
			return
		await process_frame
	assert(false, "Dice never settled")

## Let a few frames pass.
func _frames(count: int) -> void:
	for frame: int in count:
		await process_frame

## Press and release the primary button at a window position.
func _click(point: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	_viewport.push_input(motion, true)
	await process_frame
	for pressed: bool in [true, false]:
		var button: InputEventMouseButton = InputEventMouseButton.new()
		button.position = point
		button.global_position = point
		button.button_index = MOUSE_BUTTON_LEFT
		button.pressed = pressed
		_viewport.push_input(button, true)
		await process_frame
		await process_frame

## Save the viewport's current frame.
func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	_viewport.get_texture().get_image().save_png(path)
	print("Saved " + path)
