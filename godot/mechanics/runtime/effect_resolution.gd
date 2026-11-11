extends RefCounted
class_name EffectResolution
## Atomic evaluation result: invalid inputs return errors and no partial commands.

# --- Member variables ---

## Diagnostic messages must be handled by callers before applying any commands.
var errors: PackedStringArray = []
## All actions read one snapshot; the host applies intents only after successful resolution.
var commands: Array[EffectCommand] = []
