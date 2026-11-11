extends IllustratedDefinition
class_name JokerDefinition
## Global build identity; queries should normally use POOL or EVENT rather than an owner die.
## Slot limits, purchasing, selling, and unique ownership belong to the future inventory.

# --- Member functions ---

## Construct a readable content entry; no property-by-property initialization is required.
func _init(id_: StringName = &"", effects_: Array[EffectDefinition] = []) -> void:
	id = id_
	effects = effects_


## A Joker must provide behavior without carrying per-run counters in shared resources.
func local_errors() -> PackedStringArray:
	var errors: PackedStringArray = super.local_errors()
	if effects.is_empty():
		errors.append("A Joker needs at least one effect")
	return errors


## Artwork follows the stable key, independently from translated display names.
func artwork_path() -> String:
	return "res://mechanics/definitions/artwork/jokers/%s.svg" % id
