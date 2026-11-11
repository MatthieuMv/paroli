extends EffectCondition
class_name ConditionGroup
## Nested boolean composition; grouping is retained in localized descriptions.

# --- Types ---

## NOT requires exactly one child; ALL and ANY require at least one.
enum Mode { ALL, ANY, NOT }

# --- Member variables ---

## Explicit grouping prevents accidental changes to AND/OR precedence.
@export var mode: Mode = Mode.ALL
## Children may be shared, but the complete rule graph must be acyclic.
@export var conditions: Array[EffectCondition] = []

# --- Member functions ---

## Evaluate with short-circuiting against the same immutable snapshot.
func matches(context: EffectContext) -> bool:
	if mode == Mode.NOT:
		return not conditions[0].matches(context)
	for condition: EffectCondition in conditions:
		var matched: bool = condition.matches(context)
		if mode == Mode.ALL and not matched:
			return false
		if mode == Mode.ANY and matched:
			return true
	return mode == Mode.ALL

## Parentheses preserve arbitrary nesting in every locale.
func describe(words: KeywordCatalog, locale: String) -> String:
	var clauses: PackedStringArray = []
	for condition: EffectCondition in conditions:
		clauses.append(condition.describe(words, locale))
	if mode == Mode.NOT:
		return words.render("condition.not", {"condition": clauses[0]}, locale)
	return words.render("condition.group", {"condition": words.join(clauses, "list.and" if mode == Mode.ALL else "list.or", locale)}, locale)

## Return typed base references for cycle-safe graph validation.
func dependencies() -> Array[RuleNode]:
	var result: Array[RuleNode] = []
	for condition: EffectCondition in conditions:
		result.append(condition)
	return result

## Reject empty boolean groups rather than silently choosing identity semantics.
func local_errors() -> PackedStringArray:
	if mode not in Mode.values() or conditions.is_empty() or (mode == Mode.NOT and conditions.size() != 1):
		return ["Invalid boolean group"]
	return []

## Declare grammar dependencies so missing translations fail content validation.
func keyword_ids() -> Array[StringName]:
	return [&"condition.not", &"condition.group", &"list.and", &"list.or"]
