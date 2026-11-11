extends Control
## Manual impacts and a queued die → bonus → Joker scoring demonstration.

# --- Member variables ---

## Viewer uses only the reusable widget's public API and completion signals.
@onready var _score: ScoreWidget = %ScoreWidget
## Fixture values track queued snapshots so rapid clicks never lose a trigger.
var _points: float = 10.0
var _mult: float = 2.0
var _serial: int = 0

# --- Member functions ---

## Connect individual impacts and the authored scoring chain.
func _ready() -> void:
	(%DieHit as Button).pressed.connect(_die_hit)
	(%BonusHit as Button).pressed.connect(_bonus_hit)
	(%JokerHit as Button).pressed.connect(_joker_hit)
	(%Chain as Button).pressed.connect(_chain)
	(%Large as Button).pressed.connect(_large)
	(%Reset as Button).pressed.connect(_reset)
	(%Reduced as CheckButton).toggled.connect(_set_reduced)
	(%Ratio as HSlider).value_changed.connect(_preview_ratio)
	_score.step_finished.connect(_sync_ratio)
	_reset()

## Simulate one die's face contribution.
func _die_hit() -> void:
	_points += 6.0
	_enqueue("die", 0.85)

## Simulate an additive bonus contribution.
func _bonus_hit() -> void:
	_mult += 2.0
	_enqueue("bonus", 1.25)

## Simulate a resolved Joker snapshot; the production host owns actual rules.
func _joker_hit() -> void:
	_mult *= 1.5
	_enqueue("joker", 1.8)

## Play five distinct die hits, two bonuses, then a stronger Joker payoff.
func _chain() -> void:
	_reset()
	for value: float in [2.0, 4.0, 6.0, 3.0, 5.0]:
		_points += value
		_enqueue("die", 0.75 + float(_serial) * 0.08)
	_bonus_hit()
	_bonus_hit()
	_joker_hit()

## Stress numeric fit and fractional Mult without adding other widget content.
func _large() -> void:
	_points = 1234567.0
	_mult = 987.65
	_enqueue("large", 2.0)

## Cancel playback immediately and reset the fixture baseline.
func _reset() -> void:
	_points = 10.0
	_mult = 2.0
	_serial = 0
	_score.set_round_context(0.0, 100.0)
	_score.set_values(_points, _mult)
	_sync_ratio(&"")

## Change accessibility mode without dropping queued sources.
func _set_reduced(enabled: bool) -> void:
	_score.reduced_motion = enabled

## Give every manual or automatic source a unique synchronization ID.
func _enqueue(kind: String, strength: float) -> void:
	_serial += 1
	_score.trigger(StringName("%s_%d" % [kind, _serial]), _points, _mult, strength)

## Scrub across target without extra information in the production widget.
func _preview_ratio(ratio: float) -> void:
	_points = 100.0
	_mult = ratio
	_score.set_values(_points, _mult)
	_sync_ratio(&"")

## Keep the debug-only ratio control in sync with the completed source.
func _sync_ratio(_source_id: StringName) -> void:
	(%Ratio as HSlider).set_value_no_signal(_score.score_ratio)
	(%RatioLabel as Label).text = "Score / target  %.2f×" % _score.score_ratio
