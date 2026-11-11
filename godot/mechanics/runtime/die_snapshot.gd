extends RefCounted
class_name DieSnapshot
## Read-only input to effect evaluation, separate from ParoliDie rendering and input state.

# --- Member variables ---

## Stable runtime identity; two physical dice must never share it.
var id: StringName
## Current logical face value, not a mesh orientation or a physical face index.
var value: int = 1
## These flags are independent facts supplied by the host's committed event.
var held: bool = false
## Selected for this validation, including dice outside its recognized combination.
var validated: bool = false
## Used by the recognized scoring combination.
var combination_member: bool = false

## Manual reroll history resets at round start.
var manual_rerolls_round: int = 0
## This counter also resets immediately after the die is validated.
var rerolls_since_validation: int = 0
## Zero is the absence sentinel, since logical face values are positive.
var previous_validated_value: int = 0
## Crescendo's accumulated percentage before the current validation.
var crescendo_percent: int = 0

# --- Member functions ---

## Construct a logical snapshot without retaining a scene node.
func _init(id_: StringName = &"", value_: int = 1) -> void:
	id = id_
	value = value_
