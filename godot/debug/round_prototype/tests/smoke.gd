extends SceneTree
## Prototype host check: fixtures equip cleanly, rounds chain, and debug controls respect the lock.
## Pass `-- --capture` with a display to save /tmp/paroli-round-prototype{,-reveal}.png.

# --- Constants ---

## Debug host under test.
const PROTOTYPE: PackedScene = preload("res://debug/round_prototype/round_prototype.tscn")

# --- Member functions ---

## Wait for the scene tree before building the viewport.
func _initialize() -> void:
	_run.call_deferred()

## Cycle every fixture and play one round through the host's own controls.
func _run() -> void:
	create_timer(60.0).timeout.connect(_abort)
	var capture: bool = "--capture" in OS.get_cmdline_user_args()
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1280, 900)
	viewport.msaa_3d = root.msaa_3d
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var prototype: Node = PROTOTYPE.instantiate()
	viewport.add_child(prototype)
	var round_view: RoundInterface = prototype.get_node("Round") as RoundInterface
	var hud: RoundHud = round_view.get_node("Interface/Hud") as RoundHud
	var hold: DiceHoldController = round_view.get_node("HoldController") as DiceHoldController
	var dice: Node = round_view.get_node("Stage/Dice")
	var build: Button = prototype.get_node("%Build") as Button
	var restart: Button = prototype.get_node("%Restart") as Button
	(prototype.get_node("%Sound") as Button).button_pressed = false
	assert(build.disabled and restart.disabled, "A run cannot be replaced during the opening throw")
	await _until_idle(round_view)
	assert(not build.disabled)
	# Showcase: four Jokers on the rack, an upgrade tag on the first die, nothing banked yet.
	assert(not (hud.get_node("Jokers/Joker4") as BuildCard).is_empty())
	assert((hud.get_node("Docks/Dock1") as DieDock).upgrade.id == &"all_for_one")
	assert(hud.goal.shown_score == 0.0)
	if capture:
		await create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/paroli-round-prototype.png")
		# Mid-reveal frame of the showcase chain: dice, bonuses, and Jokers resolving in turn.
		for index: int in 3:
			hold.toggle_hold(dice.get_child(index) as ParoliDie)
		await create_timer(0.5).timeout
		hud.play_pressed.emit()
		await create_timer(2.6).timeout
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/paroli-round-prototype-reveal.png")
		await _until_idle(round_view)
	(prototype.get_node("%Motion") as Button).button_pressed = true
	# Backdrop controls: schemes step both ways and wrap; patterns cycle independently.
	var backdrop: StageBackdrop = round_view.get_node("Stage/Camera/Backdrop") as StageBackdrop
	var hint: Label = hud.get_node("Hint") as Label
	assert(round_view.stage.backdrop_preset.title == "Plum night" and backdrop.motif == StageBackdrop.Motif.SPARKLES, "Authored default wallpaper")
	assert(hint.get_theme_color("font_color").is_equal_approx(GameColors.CHALK), "Dark walls draw their marks in cream")
	(prototype.get_node("%BackdropNext") as Button).pressed.emit()
	assert(round_view.stage.backdrop_preset.title == "Deep lagoon" and backdrop.preset == round_view.stage.backdrop_preset)
	for step: int in 3:
		(prototype.get_node("%BackdropNext") as Button).pressed.emit()
	assert(round_view.stage.backdrop_preset.title == "Sand", "Stepping past the last scheme wraps")
	assert(hint.get_theme_color("font_color").is_equal_approx(GameColors.INK), "Light walls keep plum marks")
	for step: int in 2:
		(prototype.get_node("%BackdropPrevious") as Button).pressed.emit()
	assert(round_view.stage.backdrop_preset.title == "Espresso")
	for step: int in 2:
		(prototype.get_node("%BackdropPrevious") as Button).pressed.emit()
	assert(round_view.stage.backdrop_preset.title == "Plum night")
	(prototype.get_node("%Pattern") as Button).pressed.emit()
	assert(backdrop.motif == StageBackdrop.Motif.DOTS and round_view.stage.backdrop_preset.title == "Plum night")
	for step: int in 4:
		(prototype.get_node("%Pattern") as Button).pressed.emit()
	assert(backdrop.motif == StageBackdrop.Motif.SPARKLES, "The pattern cycle returns to the default")
	# Starter, then bare dice: equipment disappears with the fixture.
	build.pressed.emit()
	await _until_idle(round_view)
	assert(build.text == "Build: Starter")
	assert((hud.get_node("Jokers/Joker2") as BuildCard).is_empty())
	build.pressed.emit()
	await _until_idle(round_view)
	assert((hud.get_node("Jokers/Joker1") as BuildCard).is_empty())
	assert((hud.get_node("Docks/Dock1") as DieDock).upgrade == null)
	# Select and play one die at a time until a result appears, then let the host chain the next round.
	var plays: int = 0
	while not hud.banner.visible and plays < 4:
		hold.toggle_hold(dice.get_child(0) as ParoliDie)
		await process_frame
		hud.play_pressed.emit()
		await _until_idle(round_view)
		plays += 1
	assert(hud.banner.visible, "Three plays always end a round")
	hud.banner.action_pressed.emit()
	assert(not hud.banner.visible)
	await _until_idle(round_view)
	assert(hud.goal.shown_score == 0.0, "The next round starts from zero")
	# A cleared round leads to the shop, and leaving it starts the next round with the same run.
	var run: MechanicsRun = (prototype as RoundPrototype)._session.run
	run.round_target = 1.0
	hold.toggle_hold(dice.get_child(0) as ParoliDie)
	await process_frame
	hud.play_pressed.emit()
	await _until_idle(round_view)
	assert(hud.banner.visible and not run.round_active and not run.run_failed)
	var coins: int = run.coins
	hud.banner.action_pressed.emit()
	var shop_view: ShopInterface = prototype.get_node_or_null("Shop") as ShopInterface
	assert(shop_view != null and shop_view.is_inside_tree() and not round_view.is_inside_tree(), "Only the shop is on stage")
	var shop_hud: ShopHud = shop_view.get_node("Interface/Hud") as ShopHud
	assert(shop_hud._coin_balance == coins and shop_hud._slots.size() == 7)
	assert((shop_hud.get_node("%Title") as Label).text == "Before round 2")
	assert(shop_view.reduced_motion and shop_view.stage.backdrop_preset == round_view.stage.backdrop_preset, "The shop inherits the host's settings")
	shop_hud.leave_pressed.emit()
	assert(round_view.is_inside_tree() and not shop_view.is_inside_tree())
	await _until_idle(round_view)
	assert(run.round_active and hud.goal.shown_score == 0.0 and run.coins == coins)
	# With shops switched off, a cleared round goes straight to the next one.
	(prototype.get_node("%Shops") as Button).button_pressed = false
	run.round_target = 1.0
	hold.toggle_hold(dice.get_child(0) as ParoliDie)
	await process_frame
	hud.play_pressed.emit()
	await _until_idle(round_view)
	hud.banner.action_pressed.emit()
	assert(round_view.is_inside_tree() and run.round_active)
	await _until_idle(round_view)
	print("PASS: round prototype fixtures, build cycling, input lock, round chaining, shop between rounds.")
	quit()

## Watchdog: report a stalled check instead of hanging.
func _abort() -> void:
	push_error("Round prototype smoke check stalled")
	quit(1)

## Advance frames until the interface accepts input again.
func _until_idle(round_view: RoundInterface) -> void:
	await process_frame
	while round_view.is_busy():
		await process_frame
