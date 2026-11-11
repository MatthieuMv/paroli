extends SceneTree
## Integration checks for responsive cards, preview selection, and inspection mode.

# --- Constants ---

## Exercise the overlay on the real table, not an isolated menu background.
const VIEWER: PackedScene = preload("res://debug/table_viewer/table_viewer.tscn")

# --- Member variables ---

## Record the host-facing commitment signal without implementing upgrades.
var _selections: PackedStringArray = []

# --- Member functions ---

## Wait for scene-tree initialization before creating the test viewport.
func _initialize() -> void:
	_run.call_deferred()

## Check orientation changes, retained choice, and overlay input ownership.
func _run() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1280, 900)
	viewport.msaa_3d = root.msaa_3d
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.notify_mouse_entered()
	var viewer: Node3D = VIEWER.instantiate() as Node3D
	viewport.add_child(viewer)
	for die: ParoliDie in (viewer.get_node("Dice") as Node3D).get_children():
		die.reduced_motion = true
	var overlay: AugmentOverlay = viewer.get_node("%AugmentOverlay") as AugmentOverlay
	var cards: GridContainer = overlay.get_node("Presentation/Frame/Scroll/Cards") as GridContainer
	var first: AugmentCard = cards.get_child(0) as AugmentCard
	overlay.upgrade_selected.connect(_on_upgrade_selected)
	assert(not overlay.visible)
	overlay.open()
	assert(overlay.is_blocking())
	assert(viewport.gui_get_focus_owner() == null, "Opening preselected a focus target")
	await process_frame
	await process_frame
	await _key(viewport, KEY_TAB)
	assert(viewport.gui_get_focus_owner() == null, "Tab focused the pointer-only overlay")
	await _key(viewport, KEY_ENTER)
	assert(_selections.is_empty(), "Keyboard input selected an upgrade")
	for card: AugmentCard in cards.get_children():
		assert(card.focus_mode == Control.FOCUS_NONE)
		assert((card.get_node("Margin/Layout/Copy/Title") as Label).text == card.title)
		assert((card.get_node("Margin/Layout/Copy/Description") as Label).text == card.description)
	for dimensions: Vector2i in [Vector2i(1280, 900), Vector2i(540, 960), Vector2i(390, 844), Vector2i(320, 568), Vector2i(844, 390)]:
		viewport.size = dimensions
		for frame: int in 8:
			await process_frame
		assert(cards.columns == (1 if dimensions.y > dimensions.x else 3))
		for card: AugmentCard in cards.get_children():
			assert(card.size.x > 0.0)
			var content: BoxContainer = card.get_node("Margin/Layout") as BoxContainer
			assert(content.get_combined_minimum_size().y + 44.0 <= card.size.y + 1.0)
			assert(card.global_position.x >= 0.0)
			assert(card.global_position.x + card.size.x <= float(dimensions.x))
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png("/tmp/paroli-augments-%dx%d.png" % [dimensions.x, dimensions.y])
	viewport.size = Vector2i(1280, 900)
	for frame: int in 8:
		await process_frame
	var hold: DiceHoldController = viewer.get_node("HoldController") as DiceHoldController
	assert(hold.held_count() == 0, "Card input leaked to the dice")
	var inspect: Button = overlay.get_node("Presentation/Frame/Inspect") as Button
	await _click(viewport, inspect.get_global_rect().get_center())
	assert(not overlay.is_blocking())
	assert((overlay.get_node("Restore") as Button).visible)
	assert((overlay.get_node("Restore") as Button).focus_mode == Control.FOCUS_NONE)
	var die: ParoliDie = viewer.get_node("Dice/Die1") as ParoliDie
	var face: int = die.face_value
	var camera: Camera3D = viewer.get_node("Camera") as Camera3D
	await _click(viewport, camera.unproject_position(die.global_position + Vector3.UP * 1.145))
	assert(hold.held_count() == 1, "Inspection overlay blocked the live table")
	assert(die.face_value == face, "Preview changed a die value")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/paroli-augments-inspection.png")
	await _click(viewport, (overlay.get_node("Restore") as Button).get_global_rect().get_center())
	assert(overlay.is_blocking())
	# Each native effect must finish before dismissal; a repeated click emits nothing.
	for index: int in cards.get_child_count():
		if index > 0:
			overlay.open()
			await process_frame
			await process_frame
		var card: AugmentCard = cards.get_child(index) as AugmentCard
		await _click(viewport, card.get_global_rect().get_center())
		assert(_selections.size() == index + 1)
		assert(_selections[index] == card.upgrade_id)
		assert(overlay.visible and overlay.is_blocking(), "Closed before activation finished")
		first.pressed.emit()
		overlay.inspect_game()
		assert(_selections.size() == index + 1 and overlay.is_blocking())
		await card.activation_finished
		assert(not overlay.visible and not overlay.is_blocking())
		assert(die.face_value == face, "Choice presentation applied gameplay state")
	print("PASS: responsive live 3D cards, inspection input, one-shot choice signal, full activation before dismissal.")
	quit()


## Dispatch pointer input through GUI and physics picking, including the release.
func _click(viewport: SubViewport, point: Vector2) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		viewport.push_input(event, true)
		await physics_frame
		await process_frame


## Capture only the chosen ID; the host is responsible for any gameplay mutation.
func _on_upgrade_selected(upgrade_id: String) -> void:
	_selections.append(upgrade_id)


## Send actual key presses through viewport dispatch rather than calling focus methods.
func _key(viewport: SubViewport, key: Key, shift: bool = false) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = key
		event.physical_keycode = key
		event.pressed = pressed
		event.shift_pressed = shift
		viewport.push_input(event, true)
		await process_frame
