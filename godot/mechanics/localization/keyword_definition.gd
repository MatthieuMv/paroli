extends Resource
class_name KeywordDefinition
## Owns one semantic term or grammar template and its translations, not an upgrade paragraph.

# --- Member variables ---

## Semantic presentation role; the UI chooses its palette tone.
@export var color_role: StringName = &"neutral"

## Stable semantic identity, e.g. filter.held.yes or action.mult.
@export var id: StringName
## Full templates may reorder named placeholders independently in each language.
@export var translations: Dictionary[String, String] = {}
## Optional localized glossary explanation for tooltips; never used as a mechanic.
@export var explanations: Dictionary[String, String] = {}

# --- Member functions ---

## Keep each keyword and all of its translations together in readable source code.
func _init(id_: StringName = &"", translations_: Dictionary[String, String] = {}, explanations_: Dictionary[String, String] = {}) -> void:
	id = id_
	translations = translations_
	explanations = explanations_


## Require an English fallback and identical named placeholders across translations.
func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if id == &"" or not translations.has("en") or translations["en"].is_empty():
		errors.append("Keyword requires an ID and nonempty English fallback")
		return errors
	var expected: PackedStringArray = placeholders(translations["en"])
	expected.sort()
	var token_pattern: RegEx = RegEx.new()
	token_pattern.compile("[{]([a-z_]+)[}]")
	for locale: String in translations:
		var literal: String = token_pattern.sub(translations[locale], "", true)
		if "{" in literal or "}" in literal:
			errors.append(String(id) + ": malformed template for " + locale)
		var actual: PackedStringArray = placeholders(translations[locale])
		actual.sort()
		if actual != expected or translations[locale].is_empty():
			errors.append(String(id) + ": inconsistent placeholders or empty text for " + locale)
	return errors

## Resolve exact locale, then language, then English; explicit locale does not change global state.
func template(locale: String) -> String:
	return _localized(translations, locale)

## Return the tooltip in the same locale with deterministic fallback.
func explanation(locale: String) -> String:
	return _localized(explanations, locale)

## Extract distinct named tokens; literal braces are reserved for substitutions.
static func placeholders(text: String) -> PackedStringArray:
	var pattern: RegEx = RegEx.new()
	pattern.compile("[{]([a-z_]+)[}]")
	var result: PackedStringArray = []
	for match_: RegExMatch in pattern.search_all(text):
		var name: String = match_.get_string(1)
		if not name in result:
			result.append(name)
	return result

## Normalize common locale spellings without changing the keyword's authored data.
func _localized(entries: Dictionary[String, String], locale: String) -> String:
	var requested: String = locale if not locale.is_empty() else TranslationServer.get_locale()
	requested = requested.replace("-", "_")
	if entries.has(requested):
		return entries[requested]
	var language: String = requested.get_slice("_", 0)
	return entries.get(language, entries.get("en", ""))
