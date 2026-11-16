extends Control
class_name ScorePopup
## Floating increment: pops in, drifts, fades, then frees itself. Purely decorative.

# --- Member variables ---

## Removes the pop and drift; the number still appears and fades in place.
var reduced_motion: bool = false
## Centered row so an optional coin sits beside the number.
@onready var _body: HBoxContainer = $Body
## Outlined number; fill color is chosen by the caller's semantic role.
@onready var _text: Label = $Body/Text
## Drawn coin shown only for coin rewards.
@onready var _coin: CoinIcon = $Body/Coin

# --- Member functions ---

## Start the animation. `drift` is the signed vertical travel in pixels (negative rises).
func launch(text: String, color: Color, font_size: int = 30, drift: float = -52.0, with_coin: bool = false, seconds: float = 0.85) -> void:
	_text.text = text
	_text.add_theme_color_override("font_color", color)
	_text.add_theme_font_size_override("font_size", font_size)
	_text.add_theme_constant_override("outline_size", maxi(6, int(float(font_size) * 0.25)))
	_coin.visible = with_coin
	_coin.custom_minimum_size = Vector2.ONE * float(font_size) * 0.82
	# Center the row on this node's origin so scale and rotation pivot on the number.
	_body.reset_size()
	_body.position = -_body.size * 0.5
	var tween: Tween = create_tween().set_parallel(true)
	if not reduced_motion:
		scale = Vector2.ONE * 0.35
		rotation = randf_range(-0.14, 0.14)
		tween.tween_property(self, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "rotation", 0.0, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position:y", position.y + drift, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, seconds * 0.3).set_delay(seconds * 0.7)
	tween.chain().tween_callback(queue_free)
