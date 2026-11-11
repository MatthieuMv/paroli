extends EffectCondition
class_name DiceCountCondition
## Inclusive count bounds over a die query; supports presence, absence, and exact counts.

# --- Member variables ---

## The same selector drives both evaluation and generated text.
@export var query: DieQuery
## Minimum qualifying physical dice; zero explicitly permits an empty result.
@export var minimum: int = 1
## -1 has no upper bound; otherwise inclusive and at least minimum.
@export var maximum: int = -1

# --- Member functions ---

## Compare one count, avoiding vacuous "all dice" logic on empty selections.
func matches(context: EffectContext) -> bool:
	var count: int = query.select(context).size()
	return count >= minimum and (maximum == -1 or count <= maximum)

## Preserve exact, lower-bound, and bounded-range semantics in the description.
func describe(words: KeywordCatalog, locale: String) -> String:
	if query.scope != DieQuery.Scope.POOL and minimum == 1 and maximum in [-1, 1]:
		return query.describe_presence(words, locale)
	var key: String = "condition.at_least"
	if maximum == minimum:
		key = "condition.exactly"
	elif maximum != -1:
		key = "condition.between"
	return words.render(key, {"dice": query.describe(words, locale), "min": words.number(minimum, locale), "max": words.number(maximum, locale)}, locale)

## Query ownership is shared immutably and validated with the parent graph.
func dependencies() -> Array[RuleNode]:
	return [query]

## Bounds cannot silently invert the authored condition.
func local_errors() -> PackedStringArray:
	if minimum < 0 or maximum < -1 or (maximum != -1 and maximum < minimum):
		return ["Invalid dice-count bounds"]
	return []

## Declare grammar dependencies so missing translations fail content validation.
func keyword_ids() -> Array[StringName]:
	return [&"condition.at_least", &"condition.exactly", &"condition.between"]
