extends Control
class_name CoinIcon
## Small drawn coin matching the bonus/Joker artwork: honey disc, plum outline, cream diamond.

# --- Member functions ---

## Redraw crisply whenever layout changes the icon size.
func _ready() -> void:
	resized.connect(queue_redraw)

## Draw callback: outline, face, inner ring, and the stamped diamond.
func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5
	draw_circle(center, radius, GameColors.INK, true, -1.0, true)
	draw_circle(center, radius - 2.0, GameColors.HONEY, true, -1.0, true)
	draw_arc(center, radius * 0.66, 0.0, TAU, 32, GameColors.BUTTER.lightened(0.2), 1.5, true)
	var reach: float = radius * 0.4
	var diamond: PackedVector2Array = [center + Vector2(0, -reach), center + Vector2(reach * 0.8, 0), center + Vector2(0, reach), center + Vector2(-reach * 0.8, 0)]
	draw_colored_polygon(diamond, GameColors.CONTROL_SURFACE)
	diamond.append(diamond[0])
	draw_polyline(diamond, GameColors.INK, 1.4, true)
