extends EffectCondition
class_name SourceEventCondition
## Restrict a global die event to the owning die, or explicitly to another die.

# --- Member variables ---

## True means "this die caused the event"; false requires a different existing event die.
@export var same_die: bool = true

# --- Member functions ---

## Missing subjects never satisfy either branch, including the "another die" case.
func matches(context: EffectContext) -> bool:
	if context.source_die_id == &"" or context.event_die_id == &"":
		return false
	return (context.source_die_id == context.event_die_id) == same_die

## Event origin is distinct from held state and has its own localized phrase.
func describe(words: KeywordCatalog, locale: String) -> String:
	return words.render("condition.source_event" if same_die else "condition.other_event", {}, locale)

## Both boolean choices are valid; event existence is checked against the snapshot.
func local_errors() -> PackedStringArray:
	return []

## Declare grammar dependencies so missing translations fail content validation.
func keyword_ids() -> Array[StringName]:
	return [&"condition.source_event", &"condition.other_event"]
