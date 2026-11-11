extends SceneTree
## Viewer integration check; production die tests remain independent of this tool.

# --- Constants ---

## The full editor-authored viewer scene, including its isolated preview world.
const VIEWER_SCENE: PackedScene = preload("res://debug/die_viewer/die_viewer.tscn")

# --- Member functions ---

## Defer scene creation until the root viewport is ready.
func _initialize() -> void:
	_run.call_deferred()

## Exercise UI callbacks and optionally capture the actual OpenGL rendering.
func _run() -> void:
	var viewer: Control = VIEWER_SCENE.instantiate() as Control
	root.add_child(viewer)
	await process_frame
	var die: ParoliDie = viewer.get_node("%Die") as ParoliDie
	die.set_process(false)

	# Named palette and preset controls must update the scene through its public API.
	var palette: GridContainer = viewer.get_node("%Palette") as GridContainer
	assert(palette.get_child_count() == 15)
	(palette.get_child(3) as Button).pressed.emit()
	assert(die.palette_color == "Lavender")
	var effects: GridContainer = viewer.get_node("%Effects") as GridContainer
	assert(effects.get_child_count() == 15)
	(effects.get_child(2) as Button).pressed.emit()
	assert(die.effect == "bubbles")
	(viewer.get_node("%Shine") as Button).toggled.emit(true)
	(viewer.get_node("%Cracks") as Button).toggled.emit(true)
	assert(die.shine_enabled and die.cracks_enabled)

	# Return to the familiar default preview for visual comparison.
	(palette.get_child(0) as Button).pressed.emit()
	(effects.get_child(1) as Button).pressed.emit()
	die.roll(1)
	die.reduced_motion = true
	await process_frame
	die.set_process(true)
	if "--capture" in OS.get_cmdline_user_args():
		for frame: int in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/paroli-viewer.png")
	print("PASS: editor-authored viewer, palette/effect controls, independent finishes.")
	quit()
