extends SceneTree
## Validate human prose separately from the diagnostic rule-tree serializer.

# --- Member functions ---

## Check every locale, keyword target, live value, and a meaning-critical regression.
func _initialize() -> void:
	var catalog: EffectsCatalog = EffectsCatalog.new()
	var words: KeywordCatalog = GameKeywords.new()
	assert(words.validate().is_empty())
	assert(words.render("combination.single", {}, "en") == "High die")
	assert(words.render("combination.single", {}, "fr") == "Dé haut")
	assert(words.render("combination.full_house", {}, "fr") == "Main pleine")
	for definition: BuildDefinition in catalog.all_definitions():
		assert(definition.description != null, "Missing authored text: " + String(definition.id))
		assert(definition.description.validate(definition, words).is_empty(), String(definition.id))
		for locale: String in ["en", "fr"]:
			var plain: String = definition.describe(words, locale)
			var rich: String = definition.describe_rich(words, locale)
			assert(not "{" in plain and not "Invalid" in plain and not "invalide" in plain)
			assert("[url=" in rich and "[u]" not in rich)
			assert("validat" not in plain.to_lower() and "validé" not in plain.to_lower())
			assert(not words.find_keyword(definition.name_keyword).template(locale).is_empty())
		assert(definition.describe(words, "fr_CA") == definition.describe(words, "fr"))
		assert(definition.describe(words, "de") == definition.describe(words, "en"))
	var jackpot: UpgradeDefinition = catalog.upgrade(&"jackpot")
	for effect: EffectDefinition in jackpot.effects:
		for action: EffectAction in effect.actions:
			(action as ScoreAction).amount.constant = 125
	assert("+125%" in jackpot.describe(words, "en"))
	assert("+125 %" in jackpot.describe(words, "fr"))
	assert("matching die" in catalog.upgrade(&"guardian").describe(words, "en"))
	assert("même valeur" in catalog.upgrade(&"guardian").describe(words, "fr"))
	var invalid: AuthoredDescription = AuthoredDescription.new("{kw:unknown}", "{kw:unknown}")
	assert(not invalid.validate(jackpot, words).is_empty())
	invalid = AuthoredDescription.new("{n:absent:constant}", "{n:absent:constant}")
	assert(not invalid.validate(jackpot, words).is_empty())
	invalid = AuthoredDescription.new("{kw:mult}", "{kw:points}")
	assert(not invalid.validate(jackpot, words).is_empty())
	invalid = AuthoredDescription.new("[url=evil] {kw:mult}", "[url=evil] {kw:mult}")
	assert("[lb]url=evil]" in invalid.render(jackpot, words, "en", true))
	print("PASS: all 71 authored EN/FR descriptions, keyword links, fallback, validation, and live balance values")
	quit()
