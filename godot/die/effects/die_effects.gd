@tool
extends Node3D
class_name DieEffects
## Owns particle nodes, palette bindings, billboarding, and activation snapshots.
## The parent die uses this API without reaching into individual particle nodes.

# --- Types ---

## One pooled bubble-pop sprite and the radius captured at activation time.
class BubblePop:
	## Container for the four outward tick meshes.
	var node: Node3D
	## Shared material for these four ticks only.
	var material: ShaderMaterial
	## Captured bubble size before inflation.
	var size: float

	## Store the owned objects needed by absolute-time sampling.
	func _init(node_: Node3D, material_: ShaderMaterial, size_: float) -> void:
		node = node_
		material = material_
		size = size_

# --- Member variables ---

## Body-derived particle palette color.
var color: Color = GameColors.PEACH
## Neutral outline color shared with the parent die.
var ink: Color = GameColors.INK
## Selected preset identity; none owns no particle hierarchy.
var _preset: String = "none"
## Native scene hierarchy owned exclusively by this renderer.
var _particles: Node3D
## Per-instance materials and palette roles.
var _bindings: Array[DieLibrary.MaterialBinding] = []
## Numeric parameters for the selected analytic recipe.
var _recipe: Dictionary[String, float] = {}
## Pooled transient bubble ticks.
var _pops: Array[BubblePop] = []
## Absolute local transforms captured once at activation.
var _activation_starts: Array[Transform3D] = []

# --- Member functions ---

## Restore hidden particles and release any previous activation sprites.
func reset_activation() -> void:
	clear_pops()
	_activation_starts.clear()
	if _particles:
		for particle: Node3D in _particles.get_children():
			particle.show()

## Capture current particle transforms without exposing the hierarchy to the parent.
func begin_activation() -> void:
	capture_pops()
	_activation_starts.clear()
	if _particles:
		for particle: Node3D in _particles.get_children():
			_activation_starts.append(particle.transform)

## Apply activation poses to the same particles that were present at trigger time.
func sample_activation(progress: float, seconds: float) -> void:
	paint(1 - DieActivation.smooth((progress - 0.35) / 0.65))
	sample_pops(seconds)
	if not _particles:
		return
	for index: int in _activation_starts.size():
		var pose: DieActivation.ParticlePose = DieActivation.particle(
			_preset, progress, seconds, index, _activation_starts[index]
		)
		var particle: Node3D = _particles.get_child(index) as Node3D
		particle.transform = pose.transform
		particle.visible = pose.visible

## Instance the owned particle scene and reset transient activation sprites.
func select(id: String) -> void:
	clear_pops()
	if _particles:
		remove_child(_particles)
		_particles.queue_free()
	_bindings.clear()
	_preset = id
	if id == "none":
		_particles = null
		return
	_recipe = DieLibrary.recipe(id)
	_particles = DieLibrary.build_effect(id, _bindings)
	_particles.position = Vector3.ZERO
	_particles.scale = Vector3.ONE
	add_child(_particles)
	paint()

## Refresh instance-local particle colors with an optional departure fade.
func paint(alpha: float = 1.0) -> void:
	for binding: DieLibrary.MaterialBinding in _bindings:
		binding.paint(color, ink, alpha)

## Sample landing and sustained motion using the active viewport camera.
func sample(seconds: float, center_height: float) -> void:
	if not _particles:
		return
	visible = seconds >= 0.0
	if not visible:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	var facing: Basis = Basis.IDENTITY
	if camera:
		facing = global_basis.orthonormalized().inverse() * camera.global_basis.orthonormalized()
	if _preset == "orbit":
		var pose: Dictionary[String, float] = DieEffectPoses.orbit(seconds, 0, center_height, _recipe)
		_particles.scale = Vector3.ONE * pose.scale
		for i: int in _particles.get_child_count():
			var track: Node3D = _particles.get_child(i)
			# Three's Euler XYZ corresponds to Godot's reversed multiplication order.
			track.basis = Basis(Vector3.RIGHT, PI / 2 + (i - 1) * 0.35) * Basis(Vector3.UP, i * 0.35) * Basis(Vector3.BACK, i * TAU / 3 + pose.angle)
			var star: Node3D = track.get_child(1)
			star.basis = track.basis.inverse() * facing * Basis.from_scale(Vector3.ONE * 0.27)
		paint(pose.opacity)
		return
	for i: int in _particles.get_child_count():
		var p: Dictionary[String, float] = DieEffectPoses.sample(_preset, seconds, i, center_height, _recipe)
		var particle: Node3D = _particles.get_child(i)
		particle.position = Vector3(p.x * 1.2, p.y, p.z * 1.2)
		var size: float = p.get("size", 1.0)
		var stretch: float = p.get("stretch", 1.0)
		var width: float = p.get("width", 1.0)
		if _preset == "starburst" or _preset == "bolts":
			width = 1.0 / sqrt(stretch)
		var dimensions: Vector3 = Vector3(size * width, size * stretch, 1.0) * 1.5
		if _preset == "bubbles":
			dimensions = Vector3.ONE * size * 1.5
		if _preset == "confetti":
			dimensions = Vector3(p.width, p.height, 1.0) * 1.5
		particle.basis = facing * Basis(Vector3.BACK, p.get("rotation", 0.0)) * Basis(Vector3.UP, p.get("tilt", 0.0)) * Basis.from_scale(dimensions)
	paint(DieEffectPoses.smooth(seconds / 0.06))

## Project the upward body surface to protect pips in the Compatibility renderer.
func mask_top(body: Node3D) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not camera or not _particles or not visible:
		return
	# The mesh API returns heterogeneous buffers; convert immediately to packed types.
	var arrays: Array = DieLibrary.body_mesh().surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var source_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var points: PackedVector2Array = []
	var viewport_size: Vector2 = Vector2(get_viewport().size)
	var normals: Basis = body.global_basis.inverse().transposed()
	for i: int in vertices.size():
		var normal: Vector3 = normals * source_normals[i]
		if normal.normalized().y < 0.7:
			continue
		points.append(camera.unproject_position(body.to_global(vertices[i])) / viewport_size)
	var polygon: PackedVector2Array = Geometry2D.convex_hull(points)
	if polygon.size() > 1:
		polygon.resize(polygon.size() - 1)
	var count: int = mini(polygon.size(), 16)
	polygon.resize(16)
	for binding: DieLibrary.MaterialBinding in _bindings:
		binding.set_mask(polygon, count)
	for pop: BubblePop in _pops:
		pop.material.set_shader_parameter("mask_count", count)
		pop.material.set_shader_parameter("mask_polygon", polygon)

## Release transient bubble ticks when an activation is cancelled or replayed.
func clear_pops() -> void:
	for pop: BubblePop in _pops:
		pop.node.queue_free()
	_pops.clear()

## Pool four outward ticks for each currently visible bubble.
func capture_pops() -> void:
	clear_pops()
	if _preset != "bubbles" or not _particles:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	for bubble: Node3D in _particles.get_children():
		var node: Node3D = Node3D.new()
		add_child(node)
		node.position = bubble.position + Vector3(0, 0.18, 0)
		if camera:
			node.global_basis = camera.global_basis.orthonormalized()
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = preload("res://die/effects/particle.gdshader")
		for i: int in 4:
			var ray: MeshInstance3D = MeshInstance3D.new()
			var quad: QuadMesh = QuadMesh.new()
			quad.size = Vector2(0.025, 0.12)
			ray.mesh = quad
			ray.material_override = mat
			ray.rotation.z = i * PI / 2
			node.add_child(ray)
		_pops.append(BubblePop.new(node, mat, bubble.scale.x))

## Animate staggered bubble bursts from captured positions.
func sample_pops(seconds: float) -> void:
	for i: int in _pops.size():
		var pop: BubblePop = _pops[i]
		var age: float = (seconds - (0.14 + i * 0.035)) / 0.16
		pop.node.visible = age >= 0 and age < 1
		if not pop.node.visible:
			continue
		var radius: float = pop.size * 1.65 + 0.16 * (1 - pow(1 - age, 3))
		for j: int in 4:
			var ray: Node3D = pop.node.get_child(j)
			ray.position = Vector3(sin(j * PI / 2) * radius, cos(j * PI / 2) * radius, 0)
			ray.scale = Vector3.ONE * (1 - 0.5 * age)
		var tint: Color = color
		tint.a = pow(1 - age, 2)
		pop.material.set_shader_parameter("tint", tint)
