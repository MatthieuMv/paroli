extends Control
class_name ResultBanner
## End-of-round card over a light dimmer. It reports the single action press;
## the host decides what the next round or retry means.

# --- Signals ---

## The player pressed the card's only action.
signal action_pressed

# --- Member variables ---

## Removes the pop-in and confetti.
var reduced_motion: bool = false
## Translucent plum dimmer keeps the table visible underneath.
@onready var _dim: ColorRect = $Dim
## Centered result card.
@onready var _card: PanelContainer = $Card
## Small spaced caption above the title.
@onready var _eyebrow: Label = %Eyebrow
## Outcome headline.
@onready var _title: Label = %Title
## Supporting figures: score, target, converted plays.
@onready var _detail: Label = %Detail
## Continue or retry.
@onready var _action: Button = %Action
## Success burst behind the card.
@onready var _confetti: CPUParticles2D = $Confetti

# --- Member functions ---

## Ready callback: start hidden and relay the action.
func _ready() -> void:
	hide()
	_action.pressed.connect(_on_action)

## Show the outcome. Confetti accompanies success only.
func present(succeeded: bool, eyebrow: String, title: String, detail: String, action: String) -> void:
	_eyebrow.text = eyebrow
	_title.text = title
	_detail.text = detail
	_action.text = action
	show()
	_card.reset_size()
	# Particles left over from an earlier win pause while the banner is hidden and would
	# resume here; the burst is drawn only for a success shown with motion.
	_confetti.emitting = false
	_confetti.visible = succeeded and not reduced_motion
	if reduced_motion:
		_dim.modulate.a = 1.0
		_card.scale = Vector2.ONE
		return
	_dim.modulate.a = 0.0
	create_tween().tween_property(_dim, "modulate:a", 1.0, 0.25)
	Juice.pop_in(_card, 0.34)
	if succeeded:
		_confetti.position = Vector2(size.x * 0.5, size.y * 0.5 - 60.0)
		_confetti.restart()

## Hide immediately; the host starts whatever comes next.
func dismiss() -> void:
	_confetti.emitting = false
	_confetti.hide()
	hide()

## Close before notifying, so a host that reopens the banner is not immediately hidden again.
func _on_action() -> void:
	dismiss()
	action_pressed.emit()
