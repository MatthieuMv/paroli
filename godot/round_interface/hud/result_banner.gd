extends Control
class_name ResultBanner
## End-of-round card over a light dimmer. It reports the single action press;
## the host decides what the next round or retry means.

# --- Signals ---

## The player pressed the card's only action.
signal action_pressed

# --- Constants ---

## Card width where the window has room for it.
const CARD_WIDTH: float = 400.0

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
## Vertical center of the card as a share of the banner's height.
var _card_level: float = 0.5

# --- Member functions ---

## Ready callback: start hidden and relay the action.
func _ready() -> void:
	hide()
	_action.pressed.connect(_on_action)

## Cover `bounds` (parent-local size). `card_level` is the card's vertical center as a share
## of the height: one-handed layouts lower it so the action stays under the thumb.
func arrange(bounds: Vector2, card_level: float = 0.5) -> void:
	position = Vector2.ZERO
	size = bounds
	_card_level = card_level
	_card.custom_minimum_size.x = minf(CARD_WIDTH, bounds.x - 32.0)
	_place_card()

## Show the outcome. Confetti accompanies success only.
func present(succeeded: bool, eyebrow: String, title: String, detail: String, action: String) -> void:
	_eyebrow.text = eyebrow
	_title.text = title
	_detail.text = detail
	_action.text = action
	show()
	_place_card()
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
		_confetti.position = Vector2(size.x * 0.5, size.y * _card_level - 60.0)
		_confetti.restart()

## Rewrite the card's text in place, without the entrance, for example after a language change.
func relabel(eyebrow: String, title: String, detail: String, action: String) -> void:
	_eyebrow.text = eyebrow
	_title.text = title
	_detail.text = detail
	_action.text = action
	_place_card.call_deferred()

## Hide immediately; the host starts whatever comes next.
func dismiss() -> void:
	_confetti.emitting = false
	_confetti.hide()
	hide()

## Shrink the card around its text and center it on its level, inside the banner.
func _place_card() -> void:
	_card.reset_size()
	var at: Vector2 = Vector2(size.x * 0.5, size.y * _card_level) - _card.size * 0.5
	_card.position = Vector2(at.x, clampf(at.y, 16.0, maxf(16.0, size.y - _card.size.y - 16.0)))

## Close before notifying, so a host that reopens the banner is not immediately hidden again.
func _on_action() -> void:
	dismiss()
	action_pressed.emit()
