extends SceneTree
## Round interface integration check: layout, preview boundary, a full reveal, and round end.
## Pass `-- --capture` with a display to save reference frames under /tmp.

# --- Constants ---

## Reusable scene under test; the debug host is not required.
const ROUND: PackedScene = preload("res://round_interface/round_interface.tscn")

## Window pixels per logical pixel of the phone the layout checks stand in for.
const PHONE_DENSITY: float = 2.625
## Smallest side, in logical pixels, of anything the player presses.
const TOUCH_TARGET: float = 44.0

# --- Member variables ---

## Offscreen viewport standing in for the game window.
var _viewport: SubViewport

# --- Member functions ---

## Wait for the scene tree before building the viewport.
func _initialize() -> void:
	_run.call_deferred()

## Drive two plays through the public intents and inspect this feature's own widgets.
func _run() -> void:
	var capture: bool = "--capture" in OS.get_cmdline_user_args()
	# A failed assertion aborts this coroutine; never leave a window open waiting for it.
	create_timer(60.0).timeout.connect(_abort)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1280, 900)
	_viewport.msaa_3d = root.msaa_3d
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	# Standalone subviewports need the mouse-enter notification normally sent by their container.
	_viewport.notify_mouse_entered()
	var round_view: RoundInterface = ROUND.instantiate() as RoundInterface
	_viewport.add_child(round_view)
	round_view.muted = true
	round_view.reduced_motion = not capture
	var hud: RoundHud = round_view.get_node("Interface/Hud") as RoundHud
	var table: ParoliTable = round_view.get_node("Stage/Table") as ParoliTable
	var hold: DiceHoldController = round_view.get_node("HoldController") as DiceHoldController
	var dice: Array[ParoliDie] = []
	for die: ParoliDie in round_view.get_node("Stage/Dice").get_children():
		dice.append(die)
	# Showcase-like fixture; the forced table state below clears this target on the second play.
	var catalog: EffectsCatalog = EffectsCatalog.new()
	var run: MechanicsRun = MechanicsRun.new(4)
	assert(run.install_upgrade(catalog.upgrade(&"all_for_one")).is_empty())
	assert(run.install_upgrade(catalog.upgrade(&"odd_master")).is_empty())
	assert(run.equip_bonus(catalog.bonus(&"family_spirit"), &"die_1", 2).is_empty())
	assert(run.equip_bonus(catalog.bonus(&"pair_partner"), &"die_4", 2).is_empty())
	assert(run.add_joker(catalog.joker(&"match_master"), 3).is_empty())
	assert(run.add_joker(catalog.joker(&"odd_squad"), 3).is_empty())
	var session: RoundSession = RoundSession.new(run, 20261116)
	session.coins_per_unused_play = 2
	round_view.start_round(session, 1, 2500.0)
	assert(round_view.is_busy(), "The opening throw locks input")
	await _until_idle(round_view)
	var play: ActionButton = hud.get_node("Play") as ActionButton
	var roll: ActionButton = hud.get_node("Roll") as ActionButton
	# Layout: every die column has its dock, and the table stays between the HUD bands.
	for index: int in dice.size():
		assert(table.contains_roll_position(table.to_local(dice[index].global_position)))
	var docks: Node = hud.get_node("Docks")
	var camera: Camera3D = round_view.get_node("Stage/Camera") as Camera3D
	for index: int in dice.size():
		var dock: Control = docks.get_child(index) as Control
		var column: float = camera.unproject_position(dice[index].global_position).x
		assert(absf(dock.get_global_rect().get_center().x - column) < 2.0, "Dock %d is off its die column" % index)
	_assert_backdrop_covers(round_view)
	assert((hud.get_node("Jokers/Joker1") as BuildCard).owner_id == &"joker:match_master")
	assert((hud.get_node("Jokers/Joker3") as BuildCard).is_empty())
	# Upgraded dice print their permanent layout on the model; ordinary dice keep 1–6.
	assert(dice[0].faces == PackedInt32Array([1, 1, 1, 3, 3, 3]) and dice[1].faces == PackedInt32Array([1, 1, 3, 3, 5, 5]))
	assert(dice[2].faces == ParoliDie.STANDARD_FACES)
	# Nothing is selected yet: no combination, no upgrade particles, nothing to play.
	_force_values(run, [3, 3, 5, 3, 6])
	assert(play.disabled and not roll.disabled, "Only rolling is possible before a selection")
	assert(not (hud.score.get_node("%Plate") as Control).visible or (hud.score.get_node("%PlateText") as Label).text == "Select dice to play")
	for die: ParoliDie in dice:
		assert(not die.effect_enabled, "Unselected dice never show upgrade particles")
		assert(not (die.get_node("Effects") as Node3D).visible, "A roll must not re-show disabled particles")
		assert(not die.shine_enabled, "No die shines before a combination exists")
	# A real press on a die must reach it through the HUD overlay and move it to the play row.
	await physics_frame
	await _click(camera.unproject_position(dice[0].global_position + Vector3.UP * 1.145))
	assert(hold.is_held(dice[0]), "The HUD must not block die picking")
	assert(play.disabled == not round_view.reduced_motion, "A sliding die blocks play")
	while not hold.can_mutate(dice[0]):
		await process_frame
	# One selected die: the combination appears with base values only (D-023).
	assert(hud.score.shown_points == 5.0 and hud.score.shown_mult == 1.0, "A single die previews 5 × 1")
	assert(not dice[0].effect_enabled, "All for one has no matching played die yet")
	assert(dice[0].shine_enabled, "The single selected die is the combination and shines")
	assert(not (dice[0].get_node("HoldHighlight") as Node3D).visible, "Selected dice show no gold ring")
	hold.toggle_hold(dice[1])
	hold.toggle_hold(dice[3])
	while not (hold.can_mutate(dice[1]) and hold.can_mutate(dice[3])):
		await process_frame
	await process_frame
	assert(hud.score.shown_points == 20.0 and hud.score.shown_mult == 4.0, "Three of a kind previews 20 × 4")
	assert(dice[0].effect_enabled and dice[1].effect_enabled, "Selected upgrades with an active reward show particles")
	assert((dice[0].get_node("Effects") as Node3D).visible and (dice[1].get_node("Effects") as Node3D).visible)
	assert(not dice[2].effect_enabled and not dice[4].effect_enabled)
	assert(dice[0].shine_enabled and dice[1].shine_enabled and dice[3].shine_enabled, "Combination members shine")
	assert(not dice[2].shine_enabled and not dice[4].shine_enabled)
	# Eligible cards carry the halo; others do not.
	assert((hud.get_node("Jokers/Joker1/Body/Glow") as Control).visible, "Matchmaker will trigger")
	assert((hud.get_node("Docks/Dock1/Card/Body/Glow") as Control).visible, "Copycat will trigger")
	assert(not (hud.get_node("Docks/Dock4/Card/Body/Glow") as Control).visible, "Sock Mate needs a Pair")
	# A fourth selected die that is not part of the combination does not shine.
	hold.toggle_hold(dice[4])
	while not hold.can_mutate(dice[4]):
		await process_frame
	await process_frame
	assert(hud.score.shown_points == 20.0 and not dice[4].shine_enabled and dice[0].shine_enabled)
	assert(dice[4].cracks_enabled, "A selected die that adds nothing cracks")
	assert(not dice[0].cracks_enabled and not dice[2].cracks_enabled, "Members and unselected dice never crack")
	hold.toggle_hold(dice[4])
	while not hold.can_mutate(dice[4]):
		await process_frame
	await process_frame
	assert(not dice[4].cracks_enabled, "Back on the roll row, the die is whole again")
	# An extra die that still feeds an effect is not idle: the odd 5 scores for Odd Squad.
	hold.toggle_hold(dice[2])
	while not hold.can_mutate(dice[2]):
		await process_frame
	await process_frame
	assert(not dice[2].cracks_enabled and not dice[2].shine_enabled, "Useful extras neither crack nor shine")
	hold.toggle_hold(dice[2])
	while not hold.can_mutate(dice[2]):
		await process_frame
	# One press on a die column pins its sheet: upgrade and bonus together.
	var tooltip: BuildTooltip = hud.get_node("Tooltip") as BuildTooltip
	var dock_one: Control = hud.get_node("Docks/Dock1") as Control
	await _click(dock_one.get_global_rect().get_center())
	assert(tooltip.visible and (tooltip.get_node("%Section2") as Control).visible, "Die 1 explains its upgrade and its bonus")
	assert(((tooltip.get_node("%Section1") as Control).get_node("Title") as Label).text == "All for one")
	assert(hold.is_held(dice[0]), "Inspecting a die column never changes the selection")
	var away: InputEventMouseMotion = InputEventMouseMotion.new()
	away.position = Vector2(640.0, 20.0)
	away.global_position = away.position
	_viewport.push_input(away, true)
	await process_frame
	assert(tooltip.visible, "A pinned sheet survives the pointer leaving")
	await _click(Vector2(640.0, 20.0))
	assert(not tooltip.visible, "A press elsewhere releases the pinned sheet")
	# An upgraded die without a bonus still has a one-section sheet.
	await _click((hud.get_node("Docks/Dock2") as Control).get_global_rect().get_center())
	assert(tooltip.visible and not (tooltip.get_node("%Section2") as Control).visible)
	await _click(Vector2(640.0, 20.0))
	assert(not roll.disabled and not play.disabled)
	# Deselecting an upgraded die silences it again, even though it sits beside its matches.
	hold.toggle_hold(dice[1])
	while not hold.can_mutate(dice[1]):
		await process_frame
	await process_frame
	assert(not dice[1].effect_enabled, "An upgrade on the roll row stays silent")
	await process_frame
	assert(not (dice[1].get_node("Effects") as Node3D).visible, "Disabled particles stay hidden across frames")
	hold.toggle_hold(dice[1])
	while not hold.can_mutate(dice[1]):
		await process_frame
	if capture:
		await _settle(0.6)
		await _save("/tmp/paroli-round-choose.png")
	# First play, through a real press on the button: the reveal locks dice and actions.
	await _click(play.get_global_rect().get_center())
	assert(round_view.is_busy(), "Scoring locks input")
	assert(play.disabled and roll.disabled)
	await _click(camera.unproject_position(dice[2].global_position + Vector3.UP * 1.145))
	assert(not hold.is_held(dice[2]), "Dice ignore presses during a reveal")
	if capture:
		await _settle(1.7)
		await _save("/tmp/paroli-round-chain.png")
		await _settle(1.9)
		await _save("/tmp/paroli-round-total.png")
	await _until_idle(round_view)
	assert(run.previous_validations == 1 and run.round_active)
	assert(is_equal_approx(hud.goal.shown_score, run.round_score), "The goal meter banks the committed score")
	assert(run.find_die(&"die_5").value == 6, "Dice left on the roll row keep their value")
	for index: int in [0, 1, 3]:
		assert(not hold.is_held(dice[index]) and not dice[index].is_consumed(), "Played dice re-enter on the roll row")
		assert(dice[index].global_position.is_equal_approx(table.get_roll_positions()[index]))
	assert(play.disabled, "A new selection is needed after a play")
	# Second play with the same forced state clears the target.
	_force_values(run, [3, 3, 5, 3, 6])
	for index: int in [0, 1, 3]:
		hold.toggle_hold(dice[index])
	while not (hold.can_mutate(dice[0]) and hold.can_mutate(dice[1]) and hold.can_mutate(dice[3])):
		await process_frame
	await process_frame
	hud.play_pressed.emit()
	await _until_idle(round_view)
	assert(not run.round_active and not run.run_failed)
	assert(hud.banner.visible, "A finished round shows its result")
	if capture:
		await _settle(0.5)
		await _save("/tmp/paroli-round-cleared.png")
	assert((hud.banner.get_node("Confetti") as CanvasItem).visible == not round_view.reduced_motion, "Confetti accompanies a success shown with motion")
	# A loss shown right after that win must not inherit its confetti.
	hud.banner.present(false, "", "Out of plays", "", "Try again")
	assert(not (hud.banner.get_node("Confetti") as CanvasItem).visible, "No confetti on a lost round")
	hud.banner.present(true, "", "Round cleared!", "", "Next round")
	var continued: Array[bool] = []
	round_view.continue_requested.connect(func(succeeded: bool) -> void: continued.append(succeeded))
	hud.continue_pressed.emit()
	assert(continued == [true], "The host hears the result exactly once")
	# Tablet and phone shapes: docks never reach the action buttons, widgets never overlap.
	for shape: Vector2i in [Vector2i(1000, 1000), Vector2i(900, 1100), Vector2i(768, 1024), Vector2i(1024, 768), Vector2i(1366, 1024), Vector2i(540, 960), Vector2i(1280, 900)]:
		_viewport.size = shape
		await process_frame
		await process_frame
		for index: int in dice.size():
			var dock_rect: Rect2 = (docks.get_child(index) as Control).get_global_rect()
			for action: ActionButton in [roll, play]:
				assert(not dock_rect.grow(4.0).intersects(action.get_global_rect()), "Dock %d touches %s at %s" % [index, action.name, shape])
			assert(dock_rect.end.y <= float(shape.y), "Dock %d leaves the window at %s" % [index, shape])
		assert(not hud.goal.get_global_rect().intersects(hud.score.get_global_rect()), "Goal and scoreboard overlap at %s" % shape)
		_assert_backdrop_covers(round_view)
	# Portrait arrangement keeps docks on their columns too.
	_viewport.size = Vector2i(540, 960)
	await process_frame
	await process_frame
	for index: int in dice.size():
		var dock: Control = docks.get_child(index) as Control
		var column: float = camera.unproject_position(table.get_roll_positions()[index]).x
		assert(absf(dock.get_global_rect().get_center().x - column) < 2.0)
	_assert_backdrop_covers(round_view)
	assert(round_view.start_round(session, 2, 5000.0))
	await _until_idle(round_view)
	for die: ParoliDie in dice:
		assert(not hold.is_held(die) and not die.is_consumed(), "A new round starts with every die on the roll row")
	# Celebration springs must not disturb the scaled portrait layout.
	var goal_rect: Rect2 = hud.goal.get_global_rect()
	hud.goal.reduced_motion = false
	hud.goal.celebrate("CLEARED")
	await _settle(0.7)
	assert(hud.goal.get_global_rect().is_equal_approx(goal_rect), "The goal meter keeps its layout size after celebrating")
	assert(not hud.goal.get_global_rect().intersects(hud.score.get_global_rect()), "Goal meter and scoreboard never overlap")
	if capture:
		await _settle(0.6)
		await _save("/tmp/paroli-round-portrait.png")
	# Phones: the HUD is sized in logical pixels, so a 1080-pixel-wide screen at density
	# 2.625 gets finger-sized targets instead of a shrunken desktop layout.
	round_view.display_density = PHONE_DENSITY
	for phone: Vector2i in [Vector2i(1080, 2378), Vector2i(2378, 1080), Vector2i(1080, 1920)]:
		_viewport.size = phone
		await process_frame
		await process_frame
		await _assert_phone_layout(round_view, phone)
		if capture:
			await _settle(0.4)
			await _save("/tmp/paroli-round-phone-%dx%d.png" % [phone.x, phone.y])
	# A small desktop window is a different case from a dense phone screen of the same shape.
	round_view.display_density = 1.0
	_viewport.size = Vector2i(2378, 1080)
	await process_frame
	await process_frame
	assert(hud.layout.shape == HudLayout.Shape.WIDE, "A large desktop window keeps the desktop arrangement")
	round_view.display_density = 0.0
	print("PASS: round interface layout, preview boundary, reveal, banking, result, portrait, phones.")
	quit()

## Phone arrangements: everything on screen, nothing overlapping, every target finger-sized,
## and explanations opening clear of the dice.
func _assert_phone_layout(round_view: RoundInterface, phone: Vector2i) -> void:
	var hud: RoundHud = round_view.get_node("Interface/Hud") as RoundHud
	var stage: TableStage = round_view.stage
	var window: Rect2 = Rect2(Vector2.ZERO, Vector2(phone))
	var tall: bool = phone.x < phone.y
	assert(hud.layout.shape == (HudLayout.Shape.TALL if tall else HudLayout.Shape.SIDE), "Wrong arrangement at %s" % phone)
	var roll: ActionButton = hud.get_node("Roll") as ActionButton
	var play: ActionButton = hud.get_node("Play") as ActionButton
	var coins: Control = hud.get_node("Coins") as Control
	var table_rect: Rect2 = stage.camera.framed_rect
	var gear: Rect2 = hud.settings.button_rect()
	var blocks: Array[Rect2] = [hud.goal.get_global_rect(), hud.score.get_global_rect(), roll.get_global_rect(), play.get_global_rect(), coins.get_global_rect(), gear]
	assert(gear.size.x / PHONE_DENSITY >= TOUCH_TARGET, "The settings button is too small at %s" % phone)
	for card: Control in hud.get_node("Jokers").get_children():
		blocks.append(card.get_global_rect())
		assert(card.get_global_rect().size.x / PHONE_DENSITY >= TOUCH_TARGET, "Rack tile too small at %s" % phone)
	var columns: PackedFloat32Array = stage.columns()
	for index: int in 5:
		var dock: DieDock = hud.get_node("Docks").get_child(index) as DieDock
		blocks.append(dock.get_global_rect())
		assert(absf(dock.get_global_rect().get_center().x - columns[index]) < 2.0, "Dock %d is off its die column at %s" % [index, phone])
		assert(dock.card.get_global_rect().size.x / PHONE_DENSITY >= TOUCH_TARGET, "Bonus tile too small at %s" % phone)
		# One kind of object, one size: Joker tiles match the bonus tiles.
		assert(absf(dock.card.get_global_rect().size.x - (hud.get_node("Jokers/Joker1") as Control).get_global_rect().size.x) < 1.0, "Joker and bonus tiles differ in size at %s" % phone)
		assert(dock.get_global_rect().position.y >= table_rect.end.y, "Dock %d climbs onto the table at %s" % [index, phone])
	for index: int in blocks.size():
		assert(window.encloses(blocks[index]), "Widget %d leaves the window at %s" % [index, phone])
		for other: int in range(index + 1, blocks.size()):
			assert(not blocks[index].intersects(blocks[other]), "Widgets %d and %d overlap at %s" % [index, other, phone])
	for action: ActionButton in [roll, play]:
		assert(action.get_global_rect().size.y / PHONE_DENSITY >= TOUCH_TARGET, "%s is too short to press at %s" % [action.name, phone])
	# Dice drawn smaller than a fingertip get an invisible margin around them.
	for die: ParoliDie in stage.dice():
		var reach: float = (ParoliDie.BODY_SIZE + die.pick_padding * 2.0) * table_rect.size.y / (StageCamera.TABLE_TOP - StageCamera.TABLE_BOTTOM)
		assert(reach / PHONE_DENSITY >= TOUCH_TARGET, "Dice are too small to press at %s" % phone)
	if tall:
		# One hand: the rack, the table, the columns, and both actions sit in the lower part
		# of the screen, in that order, with the actions along the bottom edge.
		assert((hud.get_node("Jokers/Joker1") as Control).get_global_rect().position.y > float(phone.y) * 0.25, "The rack is out of the thumb's reach")
		assert(table_rect.get_center().y > float(phone.y) * 0.5, "The table sits too high for one hand")
		assert(play.get_global_rect().end.y > float(phone.y) * 0.95, "The actions are not at the bottom edge")
		assert(hud.goal.get_global_rect().end.y <= hud.score.get_global_rect().position.y, "The goal sits above the scoreboard")
	# A pressed die column explains itself right next to the column, above it in portrait,
	# where the finger that pressed it is not in the way.
	var tooltip: BuildTooltip = hud.get_node("Tooltip") as BuildTooltip
	var dock_one: Control = hud.get_node("Docks/Dock1") as Control
	await _click(dock_one.get_global_rect().get_center())
	await process_frame
	await process_frame
	assert(tooltip.visible, "A pressed column opens its sheet at %s" % phone)
	var sheet: Rect2 = tooltip.get_global_rect()
	assert(window.grow(1.0).encloses(sheet), "The sheet leaves the window at %s" % phone)
	assert(not sheet.intersects(dock_one.get_global_rect()), "The sheet covers the column that opened it at %s" % phone)
	assert(not tall or sheet.end.y <= dock_one.get_global_rect().position.y, "The sheet opens under the finger at %s" % phone)
	assert(sheet.grow(80.0 * PHONE_DENSITY).intersects(dock_one.get_global_rect()), "The sheet opens far from its column at %s" % phone)
	# The goal meter ignores the pointer and no die lies under it: a neutral place to press.
	await _click(hud.goal.get_global_rect().get_center())
	assert(not tooltip.visible, "A press elsewhere closes the sheet at %s" % phone)

## Overwrite logical die values so assertions do not depend on the sampled faces.
func _force_values(run: MechanicsRun, values: PackedInt32Array) -> void:
	for index: int in values.size():
		run.dice[index].value = values[index]

## The wallpaper quad must reach past every window corner, behind the table.
func _assert_backdrop_covers(round_view: RoundInterface) -> void:
	var camera: Camera3D = round_view.get_node("Stage/Camera") as Camera3D
	var backdrop: MeshInstance3D = round_view.get_node("Stage/Camera/Backdrop") as MeshInstance3D
	var window: Vector2 = Vector2(_viewport.size)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var edge: Vector2 = camera.unproject_position(backdrop.to_global(Vector3(corner.x, corner.y, 0.0)))
		assert((edge.x - window.x * 0.5) * corner.x > window.x * 0.5, "Backdrop leaves a horizontal gap")
		assert((edge.y - window.y * 0.5) * -corner.y > window.y * 0.5, "Backdrop leaves a vertical gap")
	assert(camera.to_local(backdrop.global_position).z < -60.0, "Backdrop sits behind the table")

## Watchdog: report a stalled check instead of hanging.
func _abort() -> void:
	push_error("Round interface smoke check stalled")
	quit(1)

## Press and release the primary button at a window position, as the hold checks do.
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
		await physics_frame
		await process_frame

## Advance frames until the interface accepts input again.
func _until_idle(round_view: RoundInterface) -> void:
	await process_frame
	while round_view.is_busy():
		await process_frame

## Let animation play for a while before a capture.
func _settle(seconds: float) -> void:
	await create_timer(seconds).timeout

## Save the offscreen viewport after the frame has been drawn.
func _save(path: String) -> void:
	assert(DisplayServer.get_name() != "headless", "Capture needs a rendering display")
	await RenderingServer.frame_post_draw
	_viewport.get_texture().get_image().save_png(path)
