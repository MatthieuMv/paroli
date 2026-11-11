extends EffectCommand
class_name ReplaceFacesCommand
## Replace six ordered physical positions; the host enforces permanent-upgrade protections.

# --- Member variables ---

## Stable runtime identity, independent of rendering node paths.
var target_die_id: StringName
## Command-owned copy; neither applying nor editing it mutates an authored definition.
var faces: PackedInt32Array = []
