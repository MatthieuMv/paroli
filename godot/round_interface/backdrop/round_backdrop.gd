extends MeshInstance3D
class_name RoundBackdrop
## Screen-filling wallpaper quad parented to the table camera, far behind the table.
## A BackdropPreset supplies the colors and `motif` the pattern; the two are independent.

# --- Types ---

## Pattern drawn over the glow. Values match the shader's `motif` uniform.
enum Motif { PLAIN, SPARKLES, DOTS, STRIPES, DIAMONDS }

# --- Member variables ---

## Color scheme; null keeps the material's authored colors.
@export var preset: BackdropPreset:
	set(value):
		preset = value
		if is_node_ready():
			_paint()
## Pattern drawn over the glow.
@export var motif: Motif = Motif.SPARKLES:
	set(value):
		motif = value
		if is_node_ready():
			_paint()
## Freezes the drifting pattern; the glow and motif stay visible.
@export var reduced_motion: bool = false
## Presentation clock handed to the shader; never advances under reduced motion.
var _clock: float = 0.0

# --- Member functions ---

## Ready callback: apply the authored scheme and pattern.
func _ready() -> void:
	_paint()

## Stretch the unit quad to cover an orthographic view of `camera_size` units across,
## with spare margin for the camera's shake offsets.
func cover(camera_size: float, viewport: Vector2) -> void:
	scale = Vector3.ONE * camera_size * maxf(1.0, viewport.y / viewport.x) * 0.75

## Process callback: advance the pattern drift.
func _process(delta: float) -> void:
	if reduced_motion:
		return
	_clock += delta
	_material().set_shader_parameter("clock", _clock)

## Push the scheme and pattern to this node's own material.
func _paint() -> void:
	_material().set_shader_parameter("motif", int(motif))
	if not preset:
		return
	_material().set_shader_parameter("center_color", preset.center_color)
	_material().set_shader_parameter("edge_color", preset.edge_color)
	_material().set_shader_parameter("mark_color", preset.mark_color)
	_material().set_shader_parameter("light_color", preset.light_color)

## Scene-local shader material authored on this node.
func _material() -> ShaderMaterial:
	return material_override as ShaderMaterial
