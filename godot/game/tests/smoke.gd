extends SceneTree
## Game check: the menu starts a run, each biome opens on an upgrade choice, rounds lead to
## shops and bosses to the next biome, and the run ends on the menu by victory, by a failed
## round, or from the settings card. Host-level presses are real pointer input.
## Pass `-- --capture` with a display to save /tmp/paroli-game-*.png.

# --- Constants ---

## Scene under test.
const GAME: PackedScene = preload("res://game/game.tscn")
## Window pixels per logical pixel of the phone the layout check stands in for.
const PHONE_DENSITY: float = 2.625

# --- Member variables ---

## Offscreen viewport standing in for the game window.
var _viewport: SubViewport
## Game under test.
var _game: Game
## Whether reference frames are saved.
var _capture: bool = false

# --- Member functions ---

## Wait for the scene tree before building the viewport.
func _initialize() -> void:
	_run.call_deferred()

## Play a two-biome run to its end, then the ways a run stops early.
func _run() -> void:
	_capture = "--capture" in OS.get_cmdline_user_args()
	create_timer(120.0).timeout.connect(_abort)
	var settings: GameSettings = GameSettings.shared()
	# Checks never read or write the player's saved preferences.
	settings.storage_path = ""
	var original: String = TranslationServer.get_locale()
	settings.set_locale("en")
	settings.set_sound_enabled(false)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1280, 900)
	_viewport.msaa_3d = root.msaa_3d
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	_viewport.notify_mouse_entered()
	# The default numbers on a shorter route: two biomes instead of five.
	var rules: RunRules = (load("res://game/session/run_rules.tres") as RunRules).duplicate() as RunRules
	rules.biomes = 2
	_game = GAME.instantiate() as Game
	_game.rules = rules
	_game.reduced_motion = true
	_game.display_density = 1.0
	_game.run_seed = 5
	_viewport.add_child(_game)
	var menu: MainMenu = _game.get_node("Menu") as MainMenu
	var overlay: AugmentOverlay = _game.get_node("%Upgrades") as AugmentOverlay
	var cards: Node = overlay.get_node("Presentation/Frame/Scroll/Cards")
	var restore: Button = overlay.get_node("Restore") as Button
	await _frames(4)
	assert(menu.is_inside_tree() and not overlay.visible and _game._run == null, "The game opens on the main menu")
	if _capture:
		await _save("menu")

	# --- New run: the round screen replaces the menu under the opening upgrade choice.
	await _click(_center(menu.get_node("Interface/Hud/%NewRun") as Control))
	var round_view: RoundInterface = _game._round
	var shop_view: ShopInterface = _game._shop
	assert(round_view.is_inside_tree() and not menu.is_inside_tree() and not shop_view.is_inside_tree(), "Only the round screen is on stage")
	assert(overlay.is_blocking() and _game._run.stop().kind == RunStop.Kind.UPGRADE)
	var hud: RoundHud = round_view.get_node("Interface/Hud") as RoundHud
	var run: RunSession = _game._run
	await _frames(4)
	assert(_eyebrow(hud) == "ROUND 1" and (hud.goal.get_node("%Target") as Label).text == "100", "The table announces the first round")
	assert(run.mechanics.coins == rules.starting_coins and (hud.get_node("Docks/Dock1") as DieDock).upgrade == null)
	assert(not run.mechanics.round_active and not round_view.is_busy(), "Nothing is dealt before the choice")
	for card: AugmentCard in cards.get_children():
		assert(Rect2(Vector2.ZERO, Vector2(1280.0, 900.0)).encloses(_rect(card).grow(-1.0)), "Upgrade cards are on screen")
	if _capture:
		await create_timer(0.6).timeout
		await _save("upgrade")
	# Inspecting the table: the way back sits on the felt, clear of everything pressed.
	await _click(_center(overlay.get_node("Presentation/Frame/Inspect") as Control))
	assert(not overlay.is_blocking() and restore.visible)
	var back: Rect2 = _rect(restore)
	assert(round_view.stage.camera.framed_rect.encloses(back), "Show upgrades sits on the table")
	for die_id: StringName in round_view.stage.views:
		assert(not back.intersects(round_view.stage.die_rect(die_id)), "Show upgrades stays off the dice")
	for dock: Control in hud.get_node("Docks").get_children():
		assert(not back.intersects(dock.get_global_rect()), "Show upgrades stays off the die columns")
	# The choice follows the language, and stays in inspection while it does.
	settings.set_locale("fr")
	assert(restore.text == "Voir les améliorations" and not overlay.is_blocking())
	assert((overlay.get_node("Presentation/Frame/Heading") as Label).text == "Améliorez un dé")
	settings.set_locale("en")
	assert(restore.text == "Show upgrades" and _eyebrow(hud) == "ROUND 1")
	if _capture:
		await _save("inspect")
	await _click(_center(restore))
	assert(overlay.is_blocking())
	# Choosing installs the upgrade on the first die at once; the round waits for the card.
	var first: StringName = (cards.get_child(1) as AugmentCard).upgrade_id
	await _click(_center(cards.get_child(1) as Control))
	assert(run.mechanics.find_owned(&"upgrade:die_1").definition.id == first)
	assert((hud.get_node("Docks/Dock1") as DieDock).upgrade.id == first, "The die column shows the new upgrade under the cards")
	assert(overlay.visible and not run.mechanics.round_active, "The round waits for the card's activation")
	await overlay.closed
	assert(run.stop().kind == RunStop.Kind.ROUND and run.mechanics.round_active and run.mechanics.round_target == 100.0)
	await _until_idle(round_view)

	# --- Biome 1: round, shop, round, shop, boss.
	await _finish_round(hud, true)
	assert(_banner_text(hud, "Title") == "Round cleared!" and _banner_text(hud, "Action") == "Shop")
	await _click(_center(hud.banner.get_node("Card/Content/Action") as Control))
	assert(shop_view.is_inside_tree() and not round_view.is_inside_tree(), "A shop follows a regular round")
	var shop_hud: ShopHud = shop_view.get_node("Interface/Hud") as ShopHud
	assert((shop_hud.get_node("%Title") as Label).text == "Before round 2" and run.shop.offers.size() == 5)
	if _capture:
		await create_timer(0.6).timeout
		await _save("shop")
	await _frames(3)
	await _click(_center(shop_hud.get_node("Leave") as Control))
	assert(round_view.is_inside_tree() and not shop_view.is_inside_tree())
	assert(run.mechanics.round_active and run.mechanics.round_target == rules.target_for(2) and _eyebrow(hud) == "ROUND 2")
	await _until_idle(round_view)
	await _finish_round(hud, true)
	await _click(_center(hud.banner.get_node("Card/Content/Action") as Control))
	assert(shop_view.is_inside_tree() and (shop_hud.get_node("%Title") as Label).text == "Before the boss")
	await _frames(3)
	_assert_face(shop_hud.get_node("Leave") as ActionButton)
	await _click(_center(shop_hud.get_node("Leave") as Control))
	assert(_eyebrow(hud) == "BOSS 1" and run.stop().boss and run.mechanics.round_target == rules.target_for(3), "The biome ends on its boss")
	await _until_idle(round_view)
	await _finish_round(hud, true)
	assert(_banner_text(hud, "Eyebrow") == "B O S S   1" and _banner_text(hud, "Action") == "Continue")

	# --- Biome 2: no shop after the boss; the next upgrade lands on the second die.
	await _click(_center(hud.banner.get_node("Card/Content/Action") as Control))
	assert(round_view.is_inside_tree() and overlay.is_blocking() and run.stop().biome == 2, "A boss leads to the next biome's upgrade")
	assert(_eyebrow(hud) == "ROUND 4" and not hud.banner.visible and hud.goal.shown_score == 0.0)
	await _frames(4)
	for die: ParoliDie in round_view.stage.dice():
		assert(not die.is_consumed(), "Dice spent by the boss are back on the table")
	for card: AugmentCard in cards.get_children():
		assert(card.upgrade_id != first, "A worn upgrade is not offered again")
	var second: StringName = (cards.get_child(0) as AugmentCard).upgrade_id
	await _click(_center(cards.get_child(0) as Control))
	await overlay.closed
	assert(run.mechanics.find_owned(&"upgrade:die_2").definition.id == second and run.mechanics.find_owned(&"upgrade:die_1").definition.id == first)
	await _until_idle(round_view)
	for regular: int in 2:
		await _finish_round(hud, true)
		await _click(_center(hud.banner.get_node("Card/Content/Action") as Control))
		assert(shop_view.is_inside_tree())
		await _frames(3)
		_assert_face(shop_hud.get_node("Leave") as ActionButton)
		await _click(_center(shop_hud.get_node("Leave") as Control))
		await _until_idle(round_view)
	# The last boss: its card closes the run and leads back to the menu.
	assert(_eyebrow(hud) == "BOSS 2" and run.is_last(run.stop()))
	await _finish_round(hud, true)
	assert(_banner_text(hud, "Title") == "Run complete!" and _banner_text(hud, "Action") == "Main menu")
	if _capture:
		await create_timer(0.6).timeout
		await _save("complete")
	await _click(_center(hud.banner.get_node("Card/Content/Action") as Control))
	assert(menu.is_inside_tree() and not round_view.is_inside_tree() and _game._run == null and not overlay.visible, "A finished run returns to the menu")

	# --- A failed round ends the run: its card leads to the menu, and the build is gone.
	await _start_run(menu, overlay, cards)
	assert(_game._run != run and _game._run.mechanics.find_owned(&"upgrade:die_2") == null, "A new run starts from bare dice")
	assert(_eyebrow(hud) == "ROUND 1" and (hud.get_node("Docks/Dock2") as DieDock).upgrade == null)
	await _until_idle(round_view)
	await _finish_round(hud, false)
	assert(_game._run.is_failed() and _banner_text(hud, "Title") == "Out of plays" and _banner_text(hud, "Action") == "Main menu")
	await _click(_center(hud.banner.get_node("Card/Content/Action") as Control))
	assert(menu.is_inside_tree() and _game._run == null)

	# --- The settings card leaves a run from the shop.
	await _start_run(menu, overlay, cards)
	await _until_idle(round_view)
	await _finish_round(hud, true)
	await _click(_center(hud.banner.get_node("Card/Content/Action") as Control))
	assert(shop_view.is_inside_tree())
	await _frames(3)
	await _click(shop_hud.settings.button_rect().get_center())
	var shop_exit: Button = shop_hud.settings.get_node("%MainMenu") as Button
	assert(shop_hud.settings.is_open() and not shop_exit.disabled, "A run offers the way back to the menu")
	await _click(_center(shop_exit))
	assert(menu.is_inside_tree() and not shop_view.is_inside_tree() and _game._run == null)
	assert((menu.get_node("Interface/Hud/Settings/%MainMenu") as Button).disabled, "The menu itself has nowhere to go back to")

	# --- It also leaves from an upgrade choice, once the player inspects the table.
	await _click(_center(menu.get_node("Interface/Hud/%NewRun") as Control))
	assert(overlay.is_blocking())
	await _click(_center(overlay.get_node("Presentation/Frame/Inspect") as Control))
	await _click(hud.settings.button_rect().get_center())
	assert(hud.settings.is_open())
	await _click(_center(hud.settings.get_node("%MainMenu") as Control))
	assert(menu.is_inside_tree() and not overlay.visible and _game._run == null, "Leaving withdraws the upgrade choice")

	# --- A request made during a throw or reveal waits for it to end.
	_game.reduced_motion = false
	await _start_run(menu, overlay, cards)
	assert(round_view.is_busy(), "The opening throw is in the air")
	round_view.main_menu_requested.emit()
	assert(round_view.is_inside_tree() and _game._run != null, "A round is never parked mid-throw")
	await _until_idle(round_view)
	await _frames(2)
	assert(menu.is_inside_tree() and _game._run == null)
	_game.reduced_motion = true

	# --- Phone portrait: the choice is laid out in logical pixels, like the HUDs.
	_viewport.size = Vector2i(1080, 2340)
	_game.display_density = PHONE_DENSITY
	await _frames(4)
	await _click(_center(menu.get_node("Interface/Hud/%NewRun") as Control))
	await _frames(8)
	var phone: Rect2 = Rect2(Vector2.ZERO, Vector2(1080.0, 2340.0))
	assert(is_equal_approx(overlay.size.x, 1080.0 / PHONE_DENSITY), "The choice is sized in logical pixels")
	for card: AugmentCard in cards.get_children():
		assert(_rect(card).size.x > 0.0 and _rect(card).position.x >= 0.0 and _rect(card).end.x <= 1080.0, "Cards fit the phone's width")
	var inspect: Control = overlay.get_node("Presentation/Frame/Inspect") as Control
	assert(phone.encloses(_rect(inspect)) and _rect(inspect).size.y / PHONE_DENSITY >= 43.5, "Inspect is a full touch target")
	if _capture:
		await create_timer(0.6).timeout
		await _save("upgrade-phone")
	await _click(_center(inspect))
	assert(phone.encloses(_rect(restore)) and _rect(restore).size.y / PHONE_DENSITY >= 43.5)
	for dock: Control in hud.get_node("Docks").get_children():
		assert(not _rect(restore).intersects(dock.get_global_rect()), "Show upgrades stays off the die columns on a phone")
	if _capture:
		await _save("inspect-phone")
	TranslationServer.set_locale(original)
	_game.queue_free()
	await _frames(2)
	print("PASS: game menu, upgrade choices, rounds, shops, bosses, run end, failure, leaving, phone layout.")
	quit()

## Watchdog: report a stalled check instead of hanging.
func _abort() -> void:
	push_error("Game smoke check stalled")
	quit(1)

## Press New run on the menu, then take the first upgrade and wait for its card to finish.
func _start_run(menu: MainMenu, overlay: AugmentOverlay, cards: Node) -> void:
	await _click(_center(menu.get_node("Interface/Hud/%NewRun") as Control))
	assert(overlay.is_blocking(), "A run opens on its upgrade choice")
	await _click(_center(cards.get_child(0) as Control))
	await overlay.closed

## Play one die at a time until the result card shows. A one-point target clears on the
## first play; an unreachable one runs the plays out.
func _finish_round(hud: RoundHud, clear: bool) -> void:
	var round_view: RoundInterface = _game._round
	var hold: DiceHoldController = round_view.get_node("HoldController") as DiceHoldController
	var die: ParoliDie = round_view.stage.dice()[0]
	_game._run.mechanics.round_target = 1.0 if clear else 1000000000.0
	var plays: int = 0
	while not hud.banner.visible and plays < 6:
		hold.toggle_hold(die)
		await _frames(2)
		hud.play_pressed.emit()
		await _until_idle(round_view)
		plays += 1
	assert(hud.banner.visible and _game._run.is_failed() != clear, "The round ended as planned")
	await _frames(2)

## A button pressed as its screen was parked comes back with its face spanning it, raised,
## and its caption inside it.
func _assert_face(button: ActionButton) -> void:
	var face: Control = button.get_node("Content") as Control
	var caption: Control = button.get_node("Content/Title") as Control
	assert(face.size.is_equal_approx(button.size) and face.position.is_zero_approx(), "The button's face spans it at rest")
	assert(button.get_global_rect().encloses(caption.get_global_rect()), "The caption stays inside its button")

## Advance frames until the round accepts input again.
func _until_idle(round_view: RoundInterface) -> void:
	await process_frame
	while round_view.is_busy():
		await process_frame

## Let a few frames pass.
func _frames(count: int) -> void:
	for frame: int in count:
		await process_frame

## Round name on the goal card, without the eyebrow's letter spacing.
func _eyebrow(hud: RoundHud) -> String:
	return (hud.goal.get_node("%Eyebrow") as Label).text.replace("   ", "_").replace(" ", "").replace("_", " ")

## Text of one of the result card's lines.
func _banner_text(hud: RoundHud, line: String) -> String:
	var node: Node = hud.banner.get_node("Card/Content/" + line)
	return (node as Button).text if node is Button else (node as Label).text

## Window-pixel rectangle of a control, through its HUD's scale and its canvas layer's.
func _rect(control: Control) -> Rect2:
	return control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, control.size)

## Window-pixel center of a control.
func _center(control: Control) -> Vector2:
	return _rect(control).get_center()

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

## Save the viewport's current frame as a reference capture.
func _save(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path: String = "/tmp/paroli-game-%s.png" % label
	_viewport.get_texture().get_image().save_png(path)
	print("Saved " + path)
