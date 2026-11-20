extends Control
class_name GearIcon
## Small drawn cog for the settings button: plum outline, cream body, open hub.

# --- Constants ---

## Teeth around the rim.
const TEETH: int = 8

# --- Member functions ---

## Redraw crisply whenever layout changes the icon size.
func _ready() -> void:
	resized.connect(queue_redraw)

## Draw callback: one outlined polygon for the toothed rim, then the hub hole.
func _draw() -> void:
	var center: Vector2 = size * 0.5
	var outer: float = minf(size.x, size.y) * 0.5 - 1.5
	var inner: float = outer * 0.74
	# Each tooth is a flat-topped bump: two points on the rim circle, two on the tip circle.
	var points: PackedVector2Array = []
	var step: float = TAU / float(TEETH)
	for tooth: int in TEETH:
		var middle: float = step * float(tooth)
		for corner: Vector2 in [Vector2(-0.5, inner), Vector2(-0.28, outer), Vector2(0.28, outer), Vector2(0.5, inner)]:
			points.append(center + Vector2.from_angle(middle + corner.x * step) * corner.y)
	draw_colored_polygon(points, GameColors.CONTROL_SURFACE)
	points.append(points[0])
	draw_polyline(points, GameColors.INK, 2.0, true)
	draw_circle(center, outer * 0.32, GameColors.INK, true, -1.0, true)
	draw_circle(center, outer * 0.32 - 2.0, GameColors.LAVENDER, true, -1.0, true)
