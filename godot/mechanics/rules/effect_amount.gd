extends RuleNode
class_name EffectAmount
## Integer affine amount: constant + per_die × query count. Negative deltas are retained.

# --- Member variables ---

## Flat contribution; integer arithmetic matches the initial points/Mult foundation.
@export var constant: int = 0
## Contribution per matching physical die; zero disables counting.
@export var per_die: int = 0
## Required only when per_die is nonzero; no implicit owner or pool fallback.
@export var query: DieQuery

# --- Member functions ---

## Read all counts before any commands are applied by the host.
func evaluate(context: EffectContext) -> int:
	return constant + (per_die * query.select(context).size() if query else 0)

## Describe the formula, not a snapshot-specific payout that may reveal hidden scoring.
func describe(words: KeywordCatalog, locale: String) -> String:
	if per_die == 0:
		return words.number(constant, locale)
	var counted: String = words.render("amount.per_die", {"amount": words.number(per_die, locale), "dice": query.describe(words, locale)}, locale)
	if constant == 0:
		return counted
	return words.render("amount.sum", {"constant": words.number(constant, locale), "counted": counted}, locale)

## Amount queries participate in graph validation.
func dependencies() -> Array[RuleNode]:
	var result: Array[RuleNode] = []
	if query:
		result.append(query)
	return result

## Avoid ignored query data or a count formula without its selector.
func local_errors() -> PackedStringArray:
	if (per_die != 0) != (query != null):
		return ["Counting requires both a nonzero coefficient and a query"]
	return []

## Declare grammar dependencies so missing translations fail content validation.
func keyword_ids() -> Array[StringName]:
	return [&"amount.per_die", &"amount.sum"]
