extends Resource
class_name KeywordCatalog
## Native keyword dictionary shared by generated descriptions, UI labels, and glossary tooltips.

# --- Member variables ---

## Resources own their translations; adding an item does not require another description translation.
@export var keywords: Array[KeywordDefinition] = []

# --- Member functions ---

## Return a keyword without exposing an untyped translation or mechanics dictionary.
func find_keyword(id: StringName) -> KeywordDefinition:
	for keyword: KeywordDefinition in keywords:
		if keyword and keyword.id == id:
			return keyword
	return null

## Missing keywords or tokens produce visible diagnostics instead of misleading partial prose.
func render(id: StringName, tokens: Dictionary[String, String] = {}, locale: String = "") -> String:
	var keyword: KeywordDefinition = find_keyword(id)
	if not keyword:
		return "[missing keyword: %s]" % id
	var template: String = keyword.template(locale)
	for name: String in KeywordDefinition.placeholders(template):
		if not tokens.has(name):
			return "[missing token: %s.%s]" % [id, name]
	return template.format(tokens)

## Join clauses using translated templates, allowing conjunction and order changes per locale.
func join(parts: PackedStringArray, keyword: StringName, locale: String) -> String:
	if parts.is_empty():
		return ""
	var result: String = parts[0]
	for index: int in range(1, parts.size()):
		result = render(keyword, {"left": result, "right": parts[index]}, locale)
	return result

## Use the text server's locale-aware digit formatting, independently of the current UI language.
func number(value: int, locale: String) -> String:
	var requested: String = locale if not locale.is_empty() else TranslationServer.get_locale()
	return TextServerManager.get_primary_interface().format_number(str(value), requested)

## Reject duplicate IDs and mismatched placeholders before publishing a catalog.
func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	var ids: Array[StringName] = []
	for keyword: KeywordDefinition in keywords:
		if not keyword:
			errors.append("Missing keyword resource")
			continue
		errors.append_array(keyword.validate())
		if keyword.id in ids:
			errors.append("Duplicate keyword: " + String(keyword.id))
		ids.append(keyword.id)
	return errors
