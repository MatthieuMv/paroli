extends RefCounted
class_name EffectCommand
## Evaluated intent with provenance; concrete command types own their distinct payloads.
## A future game-state reducer applies commands, never these authoring resources.

# --- Member variables ---

## Event identity supports a host-owned once-per-event application ledger.
var event_id: StringName
## Runtime-owned instance targeted by persistent changes.
var owner_id: StringName
## Owning build identity disambiguates same-named effects in different definitions.
var definition_id: StringName
## Rule identity plus runtime owner identify one activation within the event.
var effect_id: StringName
## Empty for global Joker contributions.
var source_die_id: StringName
