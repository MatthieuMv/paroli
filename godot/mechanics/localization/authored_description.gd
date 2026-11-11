extends RefCounted
class_name AuthoredDescription
## Complete translated prose with {kw:id|surface} links and {n:effect:field} live values.
## Translators own sentence structure and inflection; gameplay never reads this prose.

# --- Member variables ---

## English and French are mandatory; regional locales fall back to their language.
var translations: Dictionary[String, String] = {}

# --- Member functions ---

## Keep both reviewed sentences beside one another.
func _init(english: String, french: String) -> void:
	translations = {"en": english, "fr": french}

## Expand controlled placeholders only; literal BBCode is escaped before rich rendering.
func render(definition: BuildDefinition, words: KeywordCatalog, locale: String, rich: bool = false) -> String:
	if not validate(definition, words).is_empty():
		return words.render("invalid", {}, locale)
	var requested: String = locale if not locale.is_empty() else TranslationServer.get_locale()
	var source: String = translations.get(requested.replace("-", "_").get_slice("_", 0), translations["en"])
	var result: String = ""
	var cursor: int = 0
	for token: RegExMatch in _pattern().search_all(source):
		result += _literal(source.substr(cursor, token.get_start() - cursor), rich)
		var content: String = token.get_string(1)
		if content.begins_with("kw:"):
			var reference: String = content.substr(3)
			var id: StringName = StringName(reference.get_slice("|", 0))
			var surface: String = reference.substr(reference.find("|") + 1) if "|" in reference else words.render(id, {}, locale)
			result += "[url=%s]%s[/url]" % [id, _literal(surface, true)] if rich else surface
		else:
			result += words.number(_number(definition, content), locale)
		cursor = token.get_end()
	return result + _literal(source.substr(cursor), rich)

## Validate references, live-value bindings, and matching semantic tokens in both locales.
func validate(definition: BuildDefinition, words: KeywordCatalog) -> PackedStringArray:
	var errors: PackedStringArray = []
	var expected: PackedStringArray = []
	for locale: String in ["en", "fr"]:
		var source: String = translations.get(locale, "")
		var identities: PackedStringArray = []
		if source.is_empty():
			errors.append("Missing authored description: " + locale)
		for token: RegExMatch in _pattern().search_all(source):
			var content: String = token.get_string(1)
			var identity: String = content.get_slice("|", 0)
			if not identity in identities:
				identities.append(identity)
			if content.begins_with("kw:"):
				var keyword: KeywordDefinition = words.find_keyword(StringName(identity.substr(3)))
				if not keyword or keyword.explanation(locale).is_empty():
					errors.append("Missing tooltip: " + identity)
			elif not _valid_number(definition, content):
				errors.append("Invalid numeric binding: " + content)
		var remainder: String = _pattern().sub(source, "", true)
		if "{" in remainder or "}" in remainder:
			errors.append("Malformed description placeholder")
		identities.sort()
		if locale == "en":
			expected = identities
		elif identities != expected:
			errors.append("Description locales reference different values or keywords")
	return errors

## Token boundaries are deliberately small; arbitrary BBCode is never interpreted as a keyword.
func _pattern() -> RegEx:
	var result: RegEx = RegEx.new()
	result.compile("\\{([^{}]+)\\}")
	return result

## Find a uniquely named effect with exactly one amount action; never depend on array positions.
func _amount(definition: BuildDefinition, effect_id: StringName) -> EffectAmount:
	for effect: EffectDefinition in definition.effects:
		if effect.id == effect_id and effect.actions.size() == 1:
			for action: EffectAction in effect.actions:
				if action is ScoreAction:
					return (action as ScoreAction).amount
				if action is RuntimeAction:
					return (action as RuntimeAction).amount
	return null

## A named field is explicit: flat amount, per-die scale, or history coefficient.
func _valid_number(definition: BuildDefinition, token: String) -> bool:
	if not token.begins_with("n:") or token.count(":") != 2:
		return false
	var amount: EffectAmount = _amount(definition, StringName(token.get_slice(":", 1)))
	var field: String = token.get_slice(":", 2)
	if not amount:
		return false
	if amount is HistoryAmount:
		return (field == "coefficient" and not amount is HistoryAmount.Crescendo) or (field == "step" and amount is HistoryAmount.Crescendo)
	return field in ["constant", "per_die"]

## Read gameplay values each render so balance edits cannot leave stale reward numbers.
func _number(definition: BuildDefinition, token: String) -> int:
	var amount: EffectAmount = _amount(definition, StringName(token.get_slice(":", 1)))
	match token.get_slice(":", 2):
		"constant":
			return amount.constant
		"per_die":
			return amount.per_die
		"coefficient":
			return (amount as HistoryAmount).coefficient
		"step":
			return HistoryAmount.CRESCENDO_STEP
	return 0

## Escape author text while leaving only renderer-owned tags active.
func _literal(value: String, rich: bool) -> String:
	return value.replace("[", "[lb]") if rich else value
