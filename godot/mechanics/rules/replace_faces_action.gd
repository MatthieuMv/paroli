extends EffectAction
class_name ReplaceFacesAction
## Request a complete six-position face layout; application policy belongs to game logic.

# --- Member variables ---

## Select affected runtime dice explicitly.
@export var targets: DieQuery
## Repeated values represent equally likely physical positions, never weighted values.
@export var faces: PackedInt32Array = [1, 2, 3, 4, 5, 6]

# --- Member functions ---

## Replace the owning die by default, or provide an explicit named die selector.
func _init(faces_: PackedInt32Array = [1, 2, 3, 4, 5, 6], targets_: DieQuery = null) -> void:
	faces = faces_
	targets = targets_ if targets_ else DieQuery.ThisDie.new()


## Copy the layout into each command so applying it cannot modify the authored resource.
func commands(context: EffectContext) -> Array[EffectCommand]:
	var result: Array[EffectCommand] = []
	for die: DieSnapshot in targets.select(context):
		var command: ReplaceFacesCommand = ReplaceFacesCommand.new()
		command.target_die_id = die.id
		command.faces = faces.duplicate()
		result.append(command)
	return result

## Describe all physical positions, preserving repeated values and their order.
func describe(words: KeywordCatalog, locale: String) -> String:
	var values: PackedStringArray = []
	for value: int in faces:
		values.append(words.number(value, locale))
	return words.render("action.faces", {"dice": targets.describe(words, locale), "faces": words.join(values, "list.sequence", locale)}, locale)

## Target selectors share the same validation and matching contract as conditions.
func dependencies() -> Array[RuleNode]:
	return [targets]

## The initial model supports six positive numeric faces.
func local_errors() -> PackedStringArray:
	if faces.size() != 6:
		return ["A die needs six physical face positions"]
	for value: int in faces:
		if value < 1:
			return ["Face values must be positive"]
	return []

## Declare grammar dependencies so missing translations fail content validation.
func keyword_ids() -> Array[StringName]:
	return [&"action.faces", &"list.sequence"]
