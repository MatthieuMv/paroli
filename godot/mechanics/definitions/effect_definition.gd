extends RuleNode
class_name EffectDefinition
## One event, optional condition, and ordered actions. Shared authored data, never runtime state.

# --- Types ---

## Run when a validation is committed.
class OnValidation:
	extends EffectDefinition

	# --- Member functions ---

	## Declare the rule ID, condition, and actions together in readable gameplay code.
	func _init(id_: StringName, condition_: EffectCondition, actions_: Array[EffectAction]) -> void:
		id = id_
		trigger = &"validation"
		condition = condition_
		actions = actions_

## Run when a die is held; use ThisDieTriggered to restrict event origin.
class OnHeld:
	extends EffectDefinition

	# --- Member functions ---

	## Declare the rule ID, condition, and actions together in readable gameplay code.
	func _init(id_: StringName, condition_: EffectCondition, actions_: Array[EffectAction]) -> void:
		id = id_
		trigger = &"held"
		condition = condition_
		actions = actions_

## Run when a die is released; event origin is an explicit condition.
class OnReleased:
	extends EffectDefinition

	# --- Member functions ---

	## Declare the rule ID, condition, and actions together in readable gameplay code.
	func _init(id_: StringName, condition_: EffectCondition, actions_: Array[EffectAction]) -> void:
		id = id_
		trigger = &"released"
		condition = condition_
		actions = actions_

## Run after a roll event.
class OnRoll:
	extends EffectDefinition

	# --- Member functions ---

	## Declare the rule ID, condition, and actions together in readable gameplay code.
	func _init(id_: StringName, condition_: EffectCondition, actions_: Array[EffectAction]) -> void:
		id = id_
		trigger = &"rolled"
		condition = condition_
		actions = actions_

## Run when the host installs the owning definition.
class OnInstalled:
	extends EffectDefinition

	# --- Member functions ---

	## Declare the rule ID, condition, and actions together in readable gameplay code.
	func _init(id_: StringName, condition_: EffectCondition, actions_: Array[EffectAction]) -> void:
		id = id_
		trigger = &"installed"
		condition = condition_
		actions = actions_

## Run at the round started lifecycle event.
class OnRoundStart:
	extends EffectDefinition

	# --- Member functions ---

	## Lifecycle effects use the same typed conditions and actions as die events.
	func _init(id_: StringName, condition_: EffectCondition, actions_: Array[EffectAction]) -> void:
		id = id_
		trigger = &"round_started"
		condition = condition_
		actions = actions_

## Run at the round ended lifecycle event.
class OnRoundEnd:
	extends EffectDefinition

	# --- Member functions ---

	## Lifecycle effects use the same typed conditions and actions as die events.
	func _init(id_: StringName, condition_: EffectCondition, actions_: Array[EffectAction]) -> void:
		id = id_
		trigger = &"round_ended"
		condition = condition_
		actions = actions_

## Run at the run started lifecycle event.
class OnRunStart:
	extends EffectDefinition

	# --- Member functions ---

	## Lifecycle effects use the same typed conditions and actions as die events.
	func _init(id_: StringName, condition_: EffectCondition, actions_: Array[EffectAction]) -> void:
		id = id_
		trigger = &"run_started"
		condition = condition_
		actions = actions_

## Default attached-die validation trigger from EFFECTS.md.
class OnValidated:
	extends EffectDefinition

	# --- Member functions ---

	## Membership and other conditions are additional to owning-die validation.
	func _init(id_: StringName, condition_: EffectCondition, actions_: Array[EffectAction]) -> void:
		id = id_
		trigger = &"validation"
		condition = Conditions.Validated.new() if not condition_ else Conditions.All.new([Conditions.Validated.new(), condition_])
		actions = actions_

## Recognition modifiers run before the category and member subset are chosen.
class BeforeRecognition:
	extends EffectDefinition

	# --- Member functions ---

	## Only explicit recognition commands affect the recognizer.
	func _init(id_: StringName, actions_: Array[EffectAction]) -> void:
		id = id_
		trigger = &"recognition"
		actions = actions_

## Completed paid whole-shop refresh event.
class OnShopRefresh:
	extends EffectDefinition

	# --- Member functions ---

	## Purchases and shop entry do not dispatch this event.
	func _init(id_: StringName, condition_: EffectCondition, actions_: Array[EffectAction]) -> void:
		id = id_
		trigger = &"shop_refreshed"
		condition = condition_
		actions = actions_

# --- Member variables ---

## Stable identity for diagnostics and the host's event deduplication ledger.
@export var id: StringName
## Event ID is extensible; its keyword is event.<id>.
@export var trigger: StringName = &"validation"
## Null means unconditional for this event; no implicit validated-die scope.
@export var condition: EffectCondition
## Actions all read the same snapshot, even when earlier actions emit face changes.
@export var actions: Array[EffectAction] = []

# --- Member functions ---

## Include all mandatory actions and optional predicate in graph validation.
func dependencies() -> Array[RuleNode]:
	var result: Array[RuleNode] = []
	if condition:
		result.append(condition)
	for action: EffectAction in actions:
		result.append(action)
	return result

## Empty effects and missing IDs are authoring errors.
func local_errors() -> PackedStringArray:
	var errors: PackedStringArray = []
	if id == &"" or trigger == &"":
		errors.append("Effect and event IDs are required")
	if actions.is_empty():
		errors.append("An effect needs at least one action")
	return errors

## Generate one localized sentence from exactly the nodes evaluated by the resolver.
func describe(words: KeywordCatalog, locale: String = "") -> String:
	if not validate_keywords(words).is_empty():
		return words.render("invalid", {}, locale)
	var clauses: PackedStringArray = []
	for action: EffectAction in actions:
		clauses.append(action.describe(words, locale))
	var tokens: Dictionary[String, String] = {
		"event": words.render("event." + String(trigger), {}, locale),
		"actions": words.join(clauses, "list.and", locale)
	}
	if condition:
		tokens["condition"] = condition.describe(words, locale)
	return words.render("effect.conditional" if condition else "effect.unconditional", tokens, locale)

## Custom events require a translated keyword, not a hardcoded description fragment.
func keyword_ids() -> Array[StringName]:
	return [StringName("event." + String(trigger)), &"effect.conditional", &"effect.unconditional", &"list.and", &"invalid"]
