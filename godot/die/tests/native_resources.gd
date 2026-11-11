extends SceneTree
## Verify scene/resource ownership contracts without any legacy import data.

# --- Member functions ---

## Wait until the engine resource loader is ready.
func _initialize() -> void:
	_run.call_deferred()

## Exercise every native scene and check that material localization is complete.
func _run() -> void:
	var catalog: DieCatalog = DieLibrary.catalog()
	assert(GameColors.PALETTE_ORDER.size() == DieLibrary.palette().size())
	assert(GameColors.PALETTE_ORDER[0] == "Peach")
	_check_scene(catalog.model)
	for effect: DieEffectDefinition in catalog.effects:
		assert(effect.activation.length > 0.0)
		for track: int in effect.activation.get_track_count():
			assert(effect.activation.track_get_type(track) == Animation.TYPE_VALUE)
			assert(effect.activation.track_get_interpolation_type(track) == Animation.INTERPOLATION_LINEAR)
			assert(effect.activation.track_get_key_count(track) >= 2)
		if effect.id == "none":
			assert(effect.scene == null)
		else:
			assert(effect.scene != null)
			assert(not effect.recipe.is_empty())
			_check_scene(effect.scene)
	print("PASS: native model/preset scenes, shared meshes, independent materials, animation tracks, palette order.")
	quit()

## Instantiate twice to detect accidentally shared mutable material resources.
func _check_scene(scene: PackedScene) -> void:
	var first: Node3D = scene.instantiate() as Node3D
	var second: Node3D = scene.instantiate() as Node3D
	_check_nodes(first, second)
	first.free()
	second.free()

## Geometry stays shared while every painted mesh owns its instance's material.
func _check_nodes(first: Node3D, second: Node3D) -> void:
	assert(first.transform.is_equal_approx(second.transform))
	assert(first.get_child_count() == second.get_child_count())
	if first is DiePaletteMesh:
		var first_mesh: DiePaletteMesh = first as DiePaletteMesh
		var second_mesh: DiePaletteMesh = second as DiePaletteMesh
		assert(first_mesh.mesh == second_mesh.mesh)
		assert(first_mesh.material_override != second_mesh.material_override)
		assert(first_mesh.material_override.resource_local_to_scene)
		assert(first_mesh.tone == second_mesh.tone)
		assert(is_equal_approx(first_mesh.opacity, second_mesh.opacity))
		if first_mesh.material_override is ShaderMaterial:
			assert(not first_mesh.sorting_use_aabb_center)
	for index: int in first.get_child_count():
		_check_nodes(first.get_child(index) as Node3D, second.get_child(index) as Node3D)
