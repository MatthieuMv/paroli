extends SceneTree
## Table-local checks for placement bounds and independent visual materials.

# --- Constants ---

## The table is usable without loading dice or a debug viewer.
const TABLE: PackedScene = preload("res://table/table.tscn")

# --- Member functions ---

## Defer resource instantiation until the root can accept children.
func _initialize() -> void:
	_run.call_deferred()

## Check the world-space anchor contract and rounded-surface placement limits.
func _run() -> void:
	var first: ParoliTable = TABLE.instantiate() as ParoliTable
	var second: ParoliTable = TABLE.instantiate() as ParoliTable
	root.add_child(first)
	root.add_child(second)
	first.position = Vector3(3, 2, -4)
	first.rotation.y = 0.5
	assert(first.get_roll_positions().size() == 5)
	for point: Vector3 in first.get_roll_positions():
		assert(first.contains_roll_position(first.to_local(point)))
	# Hold pairing follows marker names even when their scene order changes.
	var holds: Node3D = first.get_node("HoldPositions") as Node3D
	holds.move_child(holds.get_child(0), 4)
	var positions: PackedVector3Array = first.get_hold_positions()
	assert(positions.size() == 5)
	for index: int in positions.size():
		var marker: Marker3D = holds.get_node("Die%d" % (index + 1)) as Marker3D
		assert(positions[index].is_equal_approx(marker.global_position))
		assert(first.contains_roll_position(first.to_local(positions[index])))
	assert(first.contains_roll_position(Vector3.ZERO))
	assert(not first.contains_roll_position(Vector3(10.5, 0, 7)))
	assert(not first.contains_roll_position(Vector3(12, 0, 0)))
	var first_material: ShaderMaterial = (first.get_node("Surface") as MeshInstance3D).material_override as ShaderMaterial
	var second_material: ShaderMaterial = (second.get_node("Surface") as MeshInstance3D).material_override as ShaderMaterial
	assert(first_material != second_material)
	first.surface_color = Color("b7a3d7")
	assert(second.surface_color == Color("93b99b"))
	print("PASS: independent table, local bounds, transformed anchors, material isolation.")
	quit()
