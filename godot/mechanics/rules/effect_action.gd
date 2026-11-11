extends RuleNode
class_name EffectAction
## Extension point for command creation; actions never mutate resources or scene nodes.

# --- Member functions ---

## Build zero or more typed intents from one immutable event snapshot.
func commands(_context: EffectContext) -> Array[EffectCommand]:
	return []

## Describe the authored operation independently of an evaluated payout.
func describe(_words: KeywordCatalog, _locale: String) -> String:
	return ""

## Require a concrete operation rather than silently doing nothing.
func local_errors() -> PackedStringArray:
	return ["EffectAction requires a concrete subtype"]
