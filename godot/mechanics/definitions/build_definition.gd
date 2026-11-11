extends RuleNode
class_name BuildDefinition
## Common identity and effect list; subclasses express ownership category without duplicating rules.

# --- Member variables ---

## Optional player-facing prose; low-level rule descriptions remain a diagnostic fallback.
var description: AuthoredDescription

## Stable save/catalog identity, independent of translated display names.
@export var id: StringName
## Optional keyword-owned display name; descriptions never use a per-item translation.
@export var name_keyword: StringName
## Effects are evaluated independently; their order does not change additive scoring.
@export var effects: Array[EffectDefinition] = []

# --- Member functions ---

## Shared graph validation covers every nested condition, query, amount, and action.
func dependencies() -> Array[RuleNode]:
	var result: Array[RuleNode] = []
	for effect: EffectDefinition in effects:
		result.append(effect)
	return result

## Effect identities are unique within this owning definition.
func local_errors() -> PackedStringArray:
	var errors: PackedStringArray = []
	if id == &"":
		errors.append("Definition ID is required")
	var identities: Array[StringName] = []
	for effect: EffectDefinition in effects:
		if effect:
			if effect.id in identities:
				errors.append("Duplicate effect ID: " + String(effect.id))
			identities.append(effect.id)
	return errors

## Prefer reviewed player copy; retain deterministic rule-tree text for authoring fixtures.
func describe(words: KeywordCatalog, locale: String = "") -> String:
	if not validate_keywords(words).is_empty():
		return words.render("invalid", {}, locale)
	if description:
		return description.render(self, words, locale)
	var lines: PackedStringArray = []
	for effect: EffectDefinition in effects:
		lines.append(effect.describe(words, locale))
	return "\n".join(lines)

## Optional item names also resolve through keyword-owned translations.
func keyword_ids() -> Array[StringName]:
	var result: Array[StringName] = [&"invalid"]
	if name_keyword != &"":
		result.append(name_keyword)
	return result

## Render keyword metadata for a presentation-owned rich label without importing UI code.
func describe_rich(words: KeywordCatalog, locale: String = "") -> String:
	if description:
		return description.render(self, words, locale, true)
	return describe(words, locale).replace("[", "[lb]")
