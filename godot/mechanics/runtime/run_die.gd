extends DieSnapshot
class_name RunDie
## Authoritative mutable die state, independent from rendering and shared upgrade resources.

# --- Member variables ---

## Ordered equiprobable positions; only permanent upgrade installation replaces them.
var faces: PackedInt32Array = [1, 2, 3, 4, 5, 6]

# --- Member functions ---

## Create a stable physical die in run order.
func _init(id_: StringName = &"") -> void:
	super(id_, 1)

## Copy current and historical values into an event snapshot.
func snapshot(is_validated: bool, is_member: bool) -> DieSnapshot:
	var result: DieSnapshot = DieSnapshot.new(id, value)
	result.validated = is_validated
	result.held = not is_validated
	result.combination_member = is_member
	result.manual_rerolls_round = manual_rerolls_round
	result.rerolls_since_validation = rerolls_since_validation
	result.previous_validated_value = previous_validated_value
	result.crescendo_percent = crescendo_percent
	return result

## Every round starts with fresh history, while physical faces remain permanent.
func reset_history() -> void:
	manual_rerolls_round = 0
	rerolls_since_validation = 0
	previous_validated_value = 0
	crescendo_percent = 0
