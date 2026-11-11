extends SceneTree
## End-to-end picking and hold interaction checks using the authored table markers.

# --- Constants ---

## Exercise the same scene and pointer dispatch used by the live table preview.
const VIEWER: PackedScene = preload("res://debug/table_viewer/table_viewer.tscn")

# --- Member functions ---

## Wait until the scene tree can create a physics-enabled viewport.
func _initialize() -> void:
	_run.call_deferred()

## Check actual mouse picking, marker pairing, reroll exclusion, and return motion.
func _run() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1280, 900)
	viewport.msaa_3d = root.msaa_3d
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	# Standalone subviewports need the mouse-enter notification normally sent by their container.
	viewport.notify_mouse_entered()
	var viewer: Node3D = VIEWER.instantiate() as Node3D
	viewport.add_child(viewer)
	var table: ParoliTable = viewer.get_node("Table") as ParoliTable
	var hold: DiceHoldController = viewer.get_node("HoldController") as DiceHoldController
	var dice_root: Node3D = viewer.get_node("Dice") as Node3D
	var camera: Camera3D = viewer.get_node("Camera") as Camera3D
	for die: ParoliDie in dice_root.get_children():
		die.reduced_motion = true
	await process_frame
	await process_frame
	await physics_frame
	var first: ParoliDie = dice_root.get_child(0) as ParoliDie
	var face: int = first.face_value
	var click: Vector2 = camera.unproject_position(first.global_position + Vector3.UP * 1.145)

	# Right clicks and button releases must not change selection.
	await _click(viewport, click, MOUSE_BUTTON_RIGHT)
	assert(not hold.is_held(first))
	await _click(viewport, click, MOUSE_BUTTON_LEFT)
	assert(hold.is_held(first), "Left-click picking did not select the die")
	assert(first.global_position.is_equal_approx(table.get_hold_positions()[0]))
	assert(first.face_value == face)
	assert(not hold.can_roll(first))

	if "--capture" in OS.get_cmdline_user_args():
		assert(DisplayServer.get_name() != "headless", "Capture needs a rendering display")
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/paroli-hold.png")

	# Rolling other dice preserves the held die's value, position, and selection.
	(viewer.get_node("%Roll") as Button).pressed.emit()
	await process_frame
	await process_frame
	assert(first.face_value == face)
	assert(first.global_position.is_equal_approx(table.get_hold_positions()[0]))
	assert(hold.held_count() == 1)

	# Clicking the die at its hold location returns it to its original roll slot.
	click = camera.unproject_position(first.global_position + Vector3.UP * 1.145)
	await _click(viewport, click, MOUSE_BUTTON_LEFT)
	assert(not hold.is_held(first))
	assert(first.global_position.is_equal_approx(table.get_roll_positions()[0]))
	assert(first.face_value == face)

	# All slots remain unique, and all-held disables the Roll action.
	for die: ParoliDie in dice_root.get_children():
		die.clicked.emit()
	assert(hold.held_count() == 5)
	assert((viewer.get_node("%Roll") as Button).disabled)
	for index: int in dice_root.get_child_count():
		var die: ParoliDie = dice_root.get_child(index) as ParoliDie
		assert(die.global_position.is_equal_approx(table.get_hold_positions()[index]))

	# Repeated clicks cannot reverse an in-flight transfer or permit a mid-slide roll.
	first.reduced_motion = false
	hold.transfer_seconds = 0.05
	first.clicked.emit()
	first.clicked.emit()
	assert(not hold.is_held(first))
	assert(not hold.can_roll(first))
	await create_timer(0.12).timeout
	assert(first.global_position.is_equal_approx(table.get_roll_positions()[0]))
	assert(hold.can_roll(first))
	assert(not (viewer.get_node("%Roll") as Button).disabled)

	# A roll cannot be interrupted by a hold request.
	first.roll(6)
	first.clicked.emit()
	assert(not hold.is_held(first))
	print("PASS: mouse picking, hold/release, paired slots, held reroll exclusion, all-held, transfer and rolling guards.")
	quit()

## Feed normal viewport input so physics picking, not a manually emitted signal, is tested.
func _click(viewport: SubViewport, point: Vector2, button: MouseButton) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	viewport.push_input(motion, true)
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.position = point
	press.global_position = point
	press.button_index = button
	press.pressed = true
	viewport.push_input(press, true)
	await physics_frame
	await process_frame
	var release: InputEventMouseButton = InputEventMouseButton.new()
	release.position = point
	release.global_position = point
	release.button_index = button
	release.pressed = false
	viewport.push_input(release, true)
	await physics_frame
	await process_frame
