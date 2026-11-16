extends Control
class_name PipRow
## Remaining-use dots for an action button. Spent pips pop into hollow rings; gained pips pop in.

# --- Constants ---

## Center-to-center spacing between pips.
const SPACING: float = 15.0
## Resting pip radius.
const RADIUS: float = 4.5
## Seconds a spend or gain animation lasts.
const POP_SECONDS: float = 0.34

# --- Member variables ---

## Removes the pop ring; the dot state still changes immediately.
var reduced_motion: bool = false
## Uses granted this round.
var _total: int = 0
## Uses still available.
var _remaining: int = 0
## Index of the pip currently animating, or -1.
var _pop_index: int = -1
## Seconds since the animated pip changed.
var _pop_clock: float = 0.0
## Whether the animated pip was gained instead of spent.
var _pop_gain: bool = false

# --- Member functions ---

## Ready callback: idle rows do not process.
func _ready() -> void:
	set_process(false)

## Update the counts; animate the pip that changed when asked.
func set_uses(remaining: int, total: int, animate: bool) -> void:
	var previous: int = _remaining
	_total = maxi(total, remaining)
	_remaining = remaining
	if animate and not reduced_motion and remaining != previous:
		_pop_gain = remaining > previous
		_pop_index = remaining - 1 if _pop_gain else remaining
		_pop_clock = 0.0
		set_process(true)
	queue_redraw()

## Process callback: advance the single active pop.
func _process(delta: float) -> void:
	_pop_clock += delta
	if _pop_clock >= POP_SECONDS:
		_pop_index = -1
		set_process(false)
	queue_redraw()

## Draw callback: filled dots for remaining uses, hollow rings for spent ones.
func _draw() -> void:
	var ink: Color = GameColors.INK
	var start: float = (size.x - float(_total - 1) * SPACING) * 0.5
	for index: int in _total:
		var center: Vector2 = Vector2(start + float(index) * SPACING, size.y * 0.5)
		var phase: float = _pop_clock / POP_SECONDS if index == _pop_index else 1.0
		if index < _remaining:
			var grow: float = 1.0 + sin(phase * PI) * 0.7 if _pop_gain else 1.0
			draw_circle(center, RADIUS * grow, ink, true, -1.0, true)
		else:
			draw_arc(center, RADIUS - 0.75, 0.0, TAU, 24, Color(ink, 0.34), 1.5, true)
			if phase < 1.0:
				# The spent dot shrinks while a ring carries its energy outward.
				draw_circle(center, RADIUS * (1.0 - phase), ink, true, -1.0, true)
				draw_arc(center, RADIUS + phase * 9.0, 0.0, TAU, 24, Color(ink, 1.0 - phase), 2.0, true)
