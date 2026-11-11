@tool
extends RefCounted
class_name DieLibrary
## Typed access to native scene/resource definitions; no import or reconstruction step.

# --- Types ---

## One instance-owned material and its relationship to the die palette.
class MaterialBinding:
	## Material created for this die; never shared between scene instances.
	var material: Material
	## Palette role from the prototype (base, light, deep, star, ink, white).
	var tone: String
	## Baseline opacity, including translucent bubble films.
	var alpha: float

	## Capture the immutable palette role alongside the mutable material.
	func _init(material_: Material, tone_: String, alpha_: float) -> void:
		material = material_
		tone = tone_
		alpha = alpha_

	## Apply a palette update to either a solid mesh or a particle shader.
	func paint(base: Color, ink: Color, opacity: float = 1.0) -> void:
		var tint: Color = DieLibrary.tone_color(tone, base, ink)
		tint.a = alpha * opacity
		if material is ShaderMaterial:
			(material as ShaderMaterial).set_shader_parameter("tint", tint)
		else:
			(material as StandardMaterial3D).albedo_color = tint

	## Supply a per-die top-face mask only to particle materials.
	func set_mask(polygon: PackedVector2Array, count: int) -> void:
		if material is ShaderMaterial:
			var shader_material: ShaderMaterial = material as ShaderMaterial
			shader_material.set_shader_parameter("mask_count", count)
			shader_material.set_shader_parameter("mask_polygon", polygon)

# --- Constants ---

## Shared editable catalog; mutable materials are localized by scene instantiation.
const CATALOG_PATH: String = "res://die/catalog.tres"

# --- Member variables ---

## Shared immutable catalog loaded once by Godot's resource cache.
static var _catalog: DieCatalog

# --- Static functions ---

## Return the catalog without exposing mutable per-die state.
static func catalog() -> DieCatalog:
	if not _catalog:
		_catalog = load(CATALOG_PATH) as DieCatalog
	assert(_catalog != null, "Missing native die catalog")
	return _catalog

## Return named colors in the explicitly authored viewer order.
static func palette() -> Dictionary[String, Color]:
	return GameColors.palette()

## Return the authored preset order, including the disabled state.
static func effect_ids() -> PackedStringArray:
	var result: PackedStringArray = []
	for effect: DieEffectDefinition in catalog().effects:
		result.append(effect.id)
	return result

## Resolve a preset through the typed catalog rather than constructing resource paths.
static func definition(id: String) -> DieEffectDefinition:
	for effect: DieEffectDefinition in catalog().effects:
		if effect.id == id:
			return effect
	assert(false, "Unknown die effect: " + id)
	return null

## Return the preset's scalar analytic motion settings.
static func recipe(id: String) -> Dictionary[String, float]:
	return definition(id).recipe

## Use the native animation length as the consume-sequence duration.
static func activation_duration(id: String) -> float:
	return definition(id).activation.length

## Sample native linear animation tracks at absolute presentation time.
static func activation_pose(id: String, seconds: float) -> Dictionary[String, float]:
	var animation: Animation = definition(id).activation
	var result: Dictionary[String, float] = {}
	var time: float = clampf(seconds, 0.0, animation.length)
	for track: int in animation.get_track_count():
		var key: String = String(animation.track_get_path(track).get_subname(0))
		result[key] = float(animation.value_track_interpolate(track, time))
	return result

## Instantiate an editable particle scene with localized material resources.
static func build_effect(id: String, bindings: Array[MaterialBinding]) -> Node3D:
	var scene: PackedScene = definition(id).scene
	assert(scene != null, "The disabled preset has no particle scene")
	var instance: Node3D = scene.instantiate() as Node3D
	collect_bindings(instance, bindings)
	return instance

## Collect palette roles from scene-authored meshes without rebuilding their hierarchy.
static func collect_bindings(node: Node, bindings: Array[MaterialBinding]) -> void:
	if node is DiePaletteMesh:
		var mesh: DiePaletteMesh = node as DiePaletteMesh
		bindings.append(MaterialBinding.new(mesh.material_override, mesh.tone, mesh.opacity))
	for child: Node in node.get_children():
		collect_bindings(child, bindings)

## Return the same immutable mesh used by the model scene for pip protection.
static func body_mesh() -> ArrayMesh:
	return catalog().body_mesh

## Mix chromatic accents in linear RGB, matching the prototype palette.
static func tone_color(tone: String, base: Color, ink: Color) -> Color:
	var linear: Color = base.srgb_to_linear()
	match tone:
		"ink":
			return ink
		"white":
			return Color.WHITE
		"light":
			return linear.lerp(GameColors.BACKGROUND.srgb_to_linear(), 0.48).linear_to_srgb()
		"deep":
			return linear.lerp(ink.srgb_to_linear(), 0.28).linear_to_srgb()
		"star":
			return linear.lerp(ink.srgb_to_linear(), 0.45).linear_to_srgb()
	return base
