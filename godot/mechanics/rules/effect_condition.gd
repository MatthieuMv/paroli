extends RuleNode
class_name EffectCondition
## Extension point for pure predicates; never mutate context from a condition.

# --- Member functions ---

## Concrete conditions supply their own event-snapshot predicate.
func matches(_context: EffectContext) -> bool:
	return false

## Concrete conditions describe the same predicate through localized keywords.
func describe(_words: KeywordCatalog, _locale: String) -> String:
	return ""

## Base resources are intentionally invalid; author a concrete subtype.
func local_errors() -> PackedStringArray:
	return ["EffectCondition requires a concrete subtype"]
