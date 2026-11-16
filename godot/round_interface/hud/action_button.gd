extends Button
class_name ActionButton
## Chunky toy button for the two round actions, with its remaining uses printed on its face.
## It reports presses; the host decides whether an action is legal.

# --- Member variables ---

## Semantic accent: Tangerine for rolls, Lagoon for plays.
@export var accent: Color = GameColors.LAGOON
## Face caption, set by the HUD from localized keywords.
@export var title: String = "Play":
	set(value):
		title = value
		if is_node_ready():
			_title.text = value
## Removes hover and press springs.
var reduced_motion: bool = false
## Caption and pips move together when the face is pressed down.
@onready var _content: Control = $Content
## Action name.
@onready var _title: Label = $Content/Title
## Remaining uses.
@onready var _pips: PipRow = $Content/Pips

# --- Member functions ---

## Ready callback: tint this instance's own style boxes and connect press feel.
func _ready() -> void:
	_title.text = title
	_tint(&"normal", accent.lerp(GameColors.CONTROL_SURFACE, 0.3))
	_tint(&"hover", accent.lerp(Color.WHITE, 0.42))
	_tint(&"pressed", accent.lerp(GameColors.INK, 0.08))
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	mouse_entered.connect(_on_hover)

## Show how many uses remain out of those granted this round.
func set_uses(remaining: int, total: int, animate: bool) -> void:
	_pips.reduced_motion = reduced_motion
	_pips.set_uses(remaining, total, animate)

## Fade the face with the disabled state so availability reads at a glance.
func set_available(available: bool) -> void:
	disabled = not available
	_content.modulate.a = 1.0 if available else 0.4
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW

## Style boxes are local to the scene instance, so tinting never leaks to the other button.
func _tint(state: StringName, color: Color) -> void:
	(get_theme_stylebox(state) as StyleBoxFlat).bg_color = color

## The face sinks into its thick lower border.
func _on_down() -> void:
	_content.position.y = 3.0

## Release springs the whole button back.
func _on_up() -> void:
	_content.position.y = 0.0
	if not reduced_motion:
		Juice.punch(self, 0.1, 0.35)

## A small lift acknowledges the pointer.
func _on_hover() -> void:
	if not disabled and not reduced_motion:
		Juice.punch(self, 0.05, 0.3)
