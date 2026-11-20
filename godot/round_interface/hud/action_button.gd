extends Button
class_name ActionButton
## Chunky toy button for the two round actions, with its remaining uses printed on its face.
## It reports presses; the host decides whether an action is legal.

# --- Constants ---

## Caption font size when the button is wide enough for it.
const TITLE_SIZE: int = 21
## Smallest caption font size on a narrow button.
const SMALLEST_TITLE_SIZE: int = 14
## Clear space kept between the caption and each side border.
const TITLE_MARGIN: float = 12.0
## How far the face sinks while pressed, in HUD units.
const PRESS_DEPTH: float = 3.0

# --- Member variables ---

## Semantic accent: Tangerine for rolls, Lagoon for plays.
@export var accent: Color = GameColors.LAGOON
## Face caption, set by the HUD from localized keywords.
@export var title: String = "Play":
	set(value):
		title = value
		if is_node_ready():
			_title.text = value
			_fit_title()
## Removes hover and press springs.
var reduced_motion: bool = false
## Caption and pips move together when the face is pressed down.
@onready var _content: Control = $Content
## Action name.
@onready var _title: Label = $Content/Title
## Remaining uses.
@onready var _pips: PipRow = $Content/Pips
## Coin cost row, shown instead of pips for paid actions.
@onready var _cost: HBoxContainer = $Content/Cost
## Amount inside the cost row.
@onready var _cost_amount: Label = $Content/Cost/Amount

# --- Member functions ---

## Ready callback: tint this instance's own style boxes and connect press feel.
func _ready() -> void:
	_title.text = title
	_tint(&"normal", accent.lerp(GameColors.CONTROL_SURFACE, 0.3))
	_tint(&"hover", accent.lerp(Color.WHITE, 0.42))
	_tint(&"pressed", accent.lerp(GameColors.INK, 0.08))
	button_up.connect(_on_up)
	mouse_entered.connect(_on_hover)
	resized.connect(_fit_title)
	_fit_title()

## Show how many uses remain out of those granted this round.
func set_uses(remaining: int, total: int, animate: bool) -> void:
	_pips.reduced_motion = reduced_motion
	_pips.set_uses(remaining, total, animate)

## Show a coin cost under the caption instead of use pips; a changed cost gets a small punch.
func set_cost(cost: int) -> void:
	var changed: bool = _cost.visible and _cost_amount.text != str(cost)
	_pips.hide()
	_cost.show()
	_cost_amount.text = str(cost)
	if changed and not reduced_motion:
		Juice.punch(_cost, 0.3, 0.4)

## Fade the face with the disabled state so availability reads at a glance.
func set_available(available: bool) -> void:
	disabled = not available
	_content.modulate.a = 1.0 if available else 0.4
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW

## Narrow buttons (phones in portrait) shrink a long caption instead of letting it reach
## the border. Measured against the button itself, whose size is known before its label's.
func _fit_title() -> void:
	var font: Font = _title.get_theme_font("font")
	var font_size: int = TITLE_SIZE
	while font_size > SMALLEST_TITLE_SIZE and font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > size.x - TITLE_MARGIN * 2.0:
		font_size -= 1
	_title.add_theme_font_size_override("font_size", font_size)

## The face sinks into its thick lower border while the button draws pressed. It follows the
## drawn state every frame, not press signals or redraws: a press can end while the button
## is parked outside the tree (Next round parks the shop under the pointer), and a face laid
## out there measures a zero-sized parent and comes back the wrong size. Offsets, unlike a
## position, stay relative to the anchors, so the face always spans the button.
func _process(_delta: float) -> void:
	var mode: DrawMode = get_draw_mode()
	var depth: float = PRESS_DEPTH if mode in [DRAW_PRESSED, DRAW_HOVER_PRESSED] else 0.0
	if _content.offset_top != depth:
		_content.offset_top = depth
		_content.offset_bottom = depth

## Style boxes are local to the scene instance, so tinting never leaks to the other button.
func _tint(state: StringName, color: Color) -> void:
	(get_theme_stylebox(state) as StyleBoxFlat).bg_color = color

## Release springs the whole button back.
func _on_up() -> void:
	if not reduced_motion:
		Juice.punch(self, 0.1, 0.35)

## A small lift acknowledges the pointer.
func _on_hover() -> void:
	if not disabled and not reduced_motion:
		Juice.punch(self, 0.05, 0.3)
