extends IllustratedDefinition
class_name BonusDefinition
## Die-bound, movable bonus identity; the host enforces one slot and outside-round transfers.
## There is intentionally no permanent face-layout field: bonuses do not rewrite an upgrade.

# --- Member functions ---

## Construct a readable content entry; no property-by-property initialization is required.
func _init(id_: StringName = &"", effects_: Array[EffectDefinition] = []) -> void:
	id = id_
	effects = effects_


## Bonuses must provide behavior; ownership uniqueness is checked by inventory, not this resource.
func local_errors() -> PackedStringArray:
	var errors: PackedStringArray = super.local_errors()
	if effects.is_empty():
		errors.append("A bonus needs at least one effect")
	return errors


## Artwork follows the stable key, independently from translated display names.
func artwork_path() -> String:
	return "res://mechanics/definitions/artwork/bonuses/%s.svg" % id
