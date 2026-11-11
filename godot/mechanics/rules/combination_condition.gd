extends EffectCondition
class_name CombinationCondition
## Tests recognized category identity, never recognizes extra categories from face values.

# --- Member variables ---

## Stable keyword IDs; the caller supplies the already-recognized category.
@export var combinations: Array[StringName] = []

# --- Member functions ---

## Only the resolved category matches; lower categories do not stack implicitly.
func matches(context: EffectContext) -> bool:
	return context.combination in combinations

## Combination labels belong to keywords and translate independently of upgrade identity.
func describe(words: KeywordCatalog, locale: String) -> String:
	var labels: PackedStringArray = []
	for combination: StringName in combinations:
		labels.append(words.render("combination." + String(combination), {}, locale))
	return words.render("condition.combination", {"combinations": words.join(labels, "list.or", locale)}, locale)

## An empty category list is probably an authoring mistake, not an always-false effect.
func local_errors() -> PackedStringArray:
	if combinations.is_empty() or &"" in combinations:
		return ["At least one nonempty combination ID is required"]
	return []

## Validate custom category names before generating their localized descriptions.
func keyword_ids() -> Array[StringName]:
	var result: Array[StringName] = [&"condition.combination", &"list.or"]
	for combination: StringName in combinations:
		result.append(StringName("combination." + String(combination)))
	return result
