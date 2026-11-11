extends SceneTree
## Render regression for layered billboard silhouettes, fills, and details.
## Run with a display; headless mode does not exercise transparency sorting.

# --- Member functions ---

## Wait until viewport construction is safe.
func _initialize() -> void:
	_run.call_deferred()

## Render isolated particles with the same palette/material path as the live die.
func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Particle render regression requires a display, not --headless.")
		quit(1)
		return
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(900, 500)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world: Node3D = Node3D.new()
	viewport.add_child(world)
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("eee9e2")
	world.add_child(environment)
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.0
	camera.position = Vector3(0.6, 14, 11)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	var ids: PackedStringArray = ["fire", "bolts", "starburst"]
	var particles: Array[Node3D] = []
	var palette_bindings: Array[DieLibrary.MaterialBinding] = []
	for index: int in ids.size():
		var bindings: Array[DieLibrary.MaterialBinding] = []
		var effect: Node3D = DieLibrary.build_effect(ids[index], bindings)
		var particle: Node3D = effect.get_child(0) as Node3D
		_clear_owner(particle)
		effect.remove_child(particle)
		world.add_child(particle)
		effect.free()
		particle.transform = Transform3D.IDENTITY
		particle.basis = camera.basis
		particle.position = camera.basis * Vector3((index - 1) * 2.8, -1.3 if index == 0 else 0.0, 0)
		particles.append(particle)
		palette_bindings.append_array(bindings)
	# The default tilted camera reproduces the original all-ink failure. Verify
	# actual framebuffer colors, not just palette uniforms or sorting flags.
	var palette: Dictionary[String, Color] = DieLibrary.palette()
	for color_name: String in palette:
		var color: Color = palette[color_name]
		for binding: DieLibrary.MaterialBinding in palette_bindings:
			binding.paint(color, Color("30223d"))
		await _check_frame(viewport, color, color_name)

	# Camera changes must not reorder the fill behind its larger ink backplate.
	for direction: Vector3 in [Vector3(0, 0, 12), Vector3(-7, 10, 12), Vector3(0.6, 14, 11)]:
		camera.position = direction
		camera.look_at(Vector3.ZERO)
		for index: int in particles.size():
			particles[index].basis = camera.basis
			particles[index].position = camera.basis * Vector3(
				(index - 1) * 2.8, -1.3 if index == 0 else 0.0, 0
			)
		for binding: DieLibrary.MaterialBinding in palette_bindings:
			binding.paint(palette["Peach"], Color("30223d"))
		await _check_frame(viewport, palette["Peach"], "Peach camera check")
	viewport.get_texture().get_image().save_png("/tmp/paroli-particle-layers.png")
	print("PASS: rendered fire/bolt/starburst fills, ink borders, fire core; 15 palette colors and three camera angles.")
	quit()

## Count solid interior pixels to catch ordering and color-space regressions.
func _check_frame(viewport: SubViewport, color: Color, label: String) -> void:
	for frame: int in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	var capture: Image = viewport.get_texture().get_image()
	var fill_counts: PackedInt32Array = [0, 0, 0]
	var ink_counts: PackedInt32Array = [0, 0, 0]
	var core_count: int = 0
	var core: Color = DieLibrary.tone_color("light", color, Color("30223d"))
	for y: int in range(50, 420):
		for x: int in range(40, 860):
			var pixel: Color = capture.get_pixel(x, y)
			var region: int = clampi(x / 300, 0, 2)
			if _matches(pixel, color):
				fill_counts[region] += 1
			if _matches(pixel, Color("30223d")):
				ink_counts[region] += 1
			if region == 0 and _matches(pixel, core):
				core_count += 1
	for index: int in 3:
		if fill_counts[index] < 300 or ink_counts[index] < 20:
			push_error("Missing fill/outline for %s particle %d" % [label, index])
			quit(1)
			return
	if core_count < 200:
		push_error("Fire core hidden or incorrectly colored for " + label)
		quit(1)

## Allow small framebuffer quantization differences while rejecting ink/other tones.
func _matches(actual: Color, expected: Color) -> bool:
	return (
		absf(actual.r - expected.r) < 0.012
		and absf(actual.g - expected.g) < 0.012
		and absf(actual.b - expected.b) < 0.012
	)

## Detached test particles no longer belong to their source PackedScene hierarchy.
func _clear_owner(node: Node) -> void:
	node.owner = null
	for child: Node in node.get_children():
		_clear_owner(child)
