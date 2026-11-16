extends SceneTree
## Feature-local regression checks may inspect die internals; production callers may not.

# --- Constants ---

## Instantiate the same isolated scene used by gameplay and the debug viewer.
const DIE_SCENE: PackedScene = preload("res://die/die.tscn")

# --- Member functions ---

## Wait until the tree can accept scene children.
func _initialize() -> void:
	_run.call_deferred()

## Exercise every native color, preset, face, and activation without a viewer dependency.
func _run() -> void:
	var die: ParoliDie = DIE_SCENE.instantiate() as ParoliDie
	var second: ParoliDie = DIE_SCENE.instantiate() as ParoliDie
	root.add_child(die)
	root.add_child(second)
	die.set_process(false)
	second.set_process(false)
	assert(die._finish.material != second._finish.material)

	# A palette update must never mutate another die instance's material.
	var palette: Dictionary[String, Color] = DieLibrary.palette()
	for color_name: String in palette:
		die.palette_color = color_name
		assert(die.body_color == palette[color_name])
	assert(second.body_color == Color("f48665"))

	# Startup and long-running sustain use the same typed analytic sampling path.
	for id: String in DieLibrary.effect_ids():
		die.effect = id
		if id != "none":
			for seconds: float in [0.0, 0.08, 0.3, 3.0, 30.0]:
				die._vfx.sample(seconds, 1.145)
				assert(die._vfx._particles.get_child_count() > 0)
		die.roll(1)
		die._process(0.62)
		die.activate()
		for step: int in 30:
			die._process(0.05)
		assert(die.is_consumed())

	# Settling must put the requested numbered face exactly upward.
	for value: int in range(1, 7):
		die.roll(value)
		die._process(0.62)
		assert(not die.is_rolling())
		assert((die._body.basis * ParoliDie.NORMALS[value - 1]).dot(Vector3.UP) > 0.999)

	# An upgrade layout reprints the physical faces and lands on a face showing the value.
	die.faces = [1, 1, 1, 3, 3, 3]
	var printed: PackedInt32Array = []
	for position_: int in 6:
		printed.append(die._body.get_node("Face%d" % (position_ + 1)).get_child_count())
	assert(printed == PackedInt32Array([1, 1, 1, 3, 3, 3]), "Each physical face prints its layout value")
	die.roll(3)
	die._process(0.62)
	var top: int = -1
	for position_: int in 6:
		if (die._body.basis * ParoliDie.NORMALS[position_]).dot(Vector3.UP) > 0.999:
			top = position_
	assert(top >= 0 and die.faces[top] == 3, "The die lands on a face printed with the requested value")
	assert(second._body.get_node("Face4").get_child_count() == 4, "Layouts are per die")
	die.palette_color = "Sky"
	for pip: MeshInstance3D in die._body.get_node("Face5").get_children():
		assert((pip.material_override as StandardMaterial3D).albedo_color == die.ink_color, "Reprinted pips follow the palette")
	die.faces = [1, 2, 3]
	assert(die.faces == PackedInt32Array([1, 1, 1, 3, 3, 3]), "Malformed layouts are ignored")
	die.faces = ParoliDie.STANDARD_FACES
	for value: int in range(1, 7):
		assert(die._body.get_node("Face%d" % value).get_child_count() == value)

	# The finish module keeps its own uniforms and supports simultaneous effects.
	for seconds: float in [0.0, 0.4, 1.4, 3.0, 9.0]:
		die._finish.sample(seconds, true, true, false)
	die.reduced_motion = true
	die.activate()
	die._process(0.01)
	assert(die.is_consumed())
	die.roll(1)
	die._process(0.01)
	assert(not die.is_consumed())
	print("PASS: 15 colors, 14 VFX, all activations, six faces, face layouts, material isolation, finishes, reduced motion, replay.")
	quit()
