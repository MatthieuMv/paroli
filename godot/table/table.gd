@tool
extends Node3D
class_name ParoliTable
## Self-contained rolling table; its local Y=0 plane is the dice resting surface.
## The table owns visual geometry and collision, never die state or roll outcomes.

# --- Constants ---

## Felt bounds in local X/Z units; the raised rail sits outside this rectangle.
const PLAY_HALF_EXTENTS: Vector2 = Vector2(10.64, 7.14)
## Radius of the felt's rounded corners, used by placement validation.
const PLAY_CORNER_RADIUS: float = 1.49

# --- Member variables ---

## Muted felt color keeps saturated dice and particle effects readable.
@export var surface_color: Color = GameColors.MINT:
	set(value):
		surface_color = value
		_repaint()
## Peach rail provides a warm frame around the mint field.
@export var rail_color: Color = GameColors.PEACH:
	set(value):
		rail_color = value
		_repaint()
## Cocoa apron and legs ground the table in the same toy-like palette.
@export var wood_color: Color = GameColors.COCOA:
	set(value):
		wood_color = value
		_repaint()
## Cream seam and piping distinguish the inset surface from the raised rail.
@export var trim_color: Color = GameColors.CHALK:
	set(value):
		trim_color = value
		_repaint()
## Small butter-colored inlays and foot caps are restrained decorative accents.
@export var accent_color: Color = GameColors.BUTTER:
	set(value):
		accent_color = value
		_repaint()
## Plum outlines match the die's pips and silhouette.
@export var ink_color: Color = GameColors.INK:
	set(value):
		ink_color = value
		_repaint()

# --- Member functions ---

## Ready callback: apply exported colors to this instance's localized materials.
func _ready() -> void:
	_repaint()

## Return suggested die origins in world space, with enough room for their VFX.
func get_roll_positions() -> PackedVector3Array:
	var result: PackedVector3Array = []
	for marker: Node3D in $RollPositions.get_children():
		result.append(marker.global_position)
	return result

## Return hold origins in roll-slot order, matching marker names rather than tree order.
func get_hold_positions() -> PackedVector3Array:
	var result: PackedVector3Array = []
	for marker: Node3D in $RollPositions.get_children():
		var hold: Marker3D = $HoldPositions.get_node_or_null(NodePath(marker.name)) as Marker3D
		if not hold:
			push_error("Missing hold marker for " + String(marker.name))
			return []
		result.append(hold.global_position)
	return result

## Validate a local-space die center against the rounded felt perimeter.
func contains_roll_position(point: Vector3, clearance: float = 1.2) -> bool:
	var offset: Vector2 = Vector2(absf(point.x), absf(point.z))
	var corner: Vector2 = offset - (PLAY_HALF_EXTENTS - Vector2.ONE * PLAY_CORNER_RADIUS)
	var distance: float = corner.max(Vector2.ZERO).length() + minf(maxf(corner.x, corner.y), 0.0)
	return distance <= PLAY_CORNER_RADIUS - maxf(clearance, 0.0)

## Recolor named visual roles without sharing mutable materials between tables.
func _repaint() -> void:
	if not is_node_ready():
		return
	_tint($Surface, surface_color)
	_tint($Rail, rail_color)
	_tint($Base, wood_color)
	_tint($Piping, trim_color)
	_tint($Stitching, trim_color)
	for foot: MeshInstance3D in $Legs.get_children():
		_tint(foot, wood_color)
	for cap: MeshInstance3D in $FootCaps.get_children():
		_tint(cap, accent_color)
	for inlay: MeshInstance3D in $Inlays.get_children():
		_tint(inlay, accent_color)
	for outline: MeshInstance3D in $Outlines.get_children():
		(outline.material_override as StandardMaterial3D).albedo_color = ink_color

## Mesh materials are authored local-to-scene so Inspector edits stay isolated.
func _tint(mesh: MeshInstance3D, color: Color) -> void:
	(mesh.material_override as ShaderMaterial).set_shader_parameter("tint", color)
