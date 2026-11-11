extends SceneTree
## Preview integration check and deterministic screenshot of the table with dice.

# --- Constants ---

## Native preview keeps dice and table ownership separate.
const VIEWER: PackedScene = preload("res://debug/table_viewer/table_viewer.tscn")

# --- Member functions ---

## Wait for the scene tree before constructing the preview viewport.
func _initialize() -> void:
	_run.call_deferred()

## Check controls and capture the final composed view when a display is available.
func _run() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1280, 900)
	# Match the live window so screenshots cannot hide a disabled project setting.
	viewport.msaa_3d = root.msaa_3d
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var viewer: Node3D = VIEWER.instantiate() as Node3D
	viewport.add_child(viewer)
	var table: ParoliTable = viewer.get_node("Table") as ParoliTable
	var dice_root: Node3D = viewer.get_node("Dice") as Node3D
	for die: ParoliDie in dice_root.get_children():
		die.reduced_motion = true
	await process_frame
	await process_frame
	for die: ParoliDie in dice_root.get_children():
		assert(not die.is_rolling())
		assert(table.contains_roll_position(table.to_local(die.global_position)))
	(viewer.get_node("%Lavender") as Button).pressed.emit()
	assert(table.surface_color == Color("b7a3d7"))
	(viewer.get_node("%Mint") as Button).pressed.emit()
	(viewer.get_node("%Effects") as Button).toggled.emit(true)
	assert((dice_root.get_child(2) as ParoliDie).effect == "starburst")
	var hold: DiceHoldController = viewer.get_node("HoldController") as DiceHoldController
	var guardian: ParoliDie = dice_root.get_child(1) as ParoliDie
	assert(not guardian.effect_enabled)
	hold.toggle_hold(guardian)
	assert(guardian.effect_enabled, "Held Guardian supports the matching played ones")
	assert((dice_root.get_child(4) as ParoliDie).effect_enabled, "Lone Wolf benefits from a held die")
	hold.toggle_hold(guardian)
	assert(not guardian.effect_enabled)
	(viewer.get_node("%Effects") as Button).toggled.emit(false)
	if "--capture" in OS.get_cmdline_user_args():
		(viewer.get_node("%Effects") as Button).toggled.emit(true)
		hold.toggle_hold(guardian)
		assert(DisplayServer.get_name() != "headless", "Capture needs a rendering display")
		for frame: int in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/paroli-table.png")
	print("PASS: table preview, die placements, rolls, felt palette, VFX toggle.")
	quit()
