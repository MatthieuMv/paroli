extends Node
class_name DiceHoldController
## Owns a hand's hold selection and transfers; table and die scenes stay independent.
## This is presentation interaction state, not an authoritative scoring or turn model.

# --- Signals ---

## Emitted immediately when selection changes, and again after a transfer completes.
signal changed

# --- Member variables ---

## Duration of the floor-level slide; reduced-motion dice move immediately.
@export_range(0.0, 1.0, 0.01) var transfer_seconds: float = 0.28
## Table exposes marker locations through its public API.
var _table: ParoliTable
## Stable slot index for each die; two dice can never claim the same hold marker.
var _slots: Dictionary[ParoliDie, int] = {}
## Selection is recorded when a transfer starts, so rolling cannot race a hold click.
var _held: Dictionary[ParoliDie, bool] = {}
## Per-die tweens allow independent transfers while rejecting repeat clicks in flight.
var _transfers: Dictionary[ParoliDie, Tween] = {}

# --- Member functions ---

## Bind once to ready scene instances; slot order is the supplied dice array order.
func configure(table: ParoliTable, dice: Array[ParoliDie]) -> void:
	assert(_slots.is_empty(), "Configure a hold controller only once")
	assert(table.get_roll_positions().size() >= dice.size(), "Missing roll slots")
	assert(table.get_hold_positions().size() >= dice.size(), "Missing hold slots")
	_table = table
	for index: int in dice.size():
		var die: ParoliDie = dice[index]
		assert(not _slots.has(die), "A die cannot occupy two slots")
		_slots[die] = index
		_held[die] = false
		die.interaction_enabled = true
		die.clicked.connect(toggle_hold.bind(die))
		die.set_hold_highlight(false)

## Return selection state without exposing controller dictionaries.
func is_held(die: ParoliDie) -> bool:
	return _held.get(die, false)

## A die may change selection only while settled and outside an active transfer.
func can_mutate(die: ParoliDie) -> bool:
	return _slots.has(die) and not _transfers.has(die) and not die.is_rolling() and not die.is_consumed()

## Prevent rolls while held, moving, already rolling, or consumed.
func can_roll(die: ParoliDie) -> bool:
	return can_mutate(die) and not is_held(die)

## Return the number of selected dice for UI feedback.
func held_count() -> int:
	var count: int = 0
	for die: ParoliDie in _held:
		if _held[die]:
			count += 1
	return count

## Toggle a settled die and slide it to its own matching hold or roll marker.
func toggle_hold(die: ParoliDie) -> void:
	if not can_mutate(die):
		return
	var held: bool = not is_held(die)
	var positions: PackedVector3Array = _table.get_hold_positions() if held else _table.get_roll_positions()
	if positions.size() <= _slots[die]:
		return
	_held[die] = held
	die.set_hold_highlight(held)
	var target: Vector3 = positions[_slots[die]]
	if die.reduced_motion or transfer_seconds <= 0.0:
		die.global_position = target
		changed.emit()
		return
	var tween: Tween = create_tween()
	_transfers[die] = tween
	tween.tween_property(die, "global_position", target, transfer_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_transfer_finished.bind(die))
	changed.emit()

## Release the motion guard only once the die reaches its marker.
func _on_transfer_finished(die: ParoliDie) -> void:
	_transfers.erase(die)
	changed.emit()

## Cancel outstanding tweens before controlled dice or their scene are removed.
func _exit_tree() -> void:
	for die: ParoliDie in _transfers:
		_transfers[die].kill()
	_transfers.clear()
