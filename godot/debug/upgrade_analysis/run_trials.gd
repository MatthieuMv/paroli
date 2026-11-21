extends RefCounted
## Isolate experimental catalogs from the playable game. Prices, face distributions and slot costs are fixed.

# --- Types ---

## Floor the whole owned portfolio after including Stonks' growth.
class HalfPortfolio:
	extends HistoryAmount.Portfolio

	## Only the half-value Nest Egg experiment uses this formula.
	func evaluate(context: EffectContext) -> int:
		return floori(context.joker_sell_total / 2.0)

# --- Constants ---

## Core catalog changes, historical controls and the two proposed broad-item reductions.
const VARIANTS: PackedStringArray = ["current", "first-pass", "baseline", "double-date", "one-man-band", "house-builder", "opening-act", "nest-egg", "swap-opening-act", "swap-nest-egg", "chase-four", "reduce-nest-egg", "reduce-opening-act"]
## Individually trialled values for routes that missed the floor on the lower target curves.
const TRIAL_VALUES: Dictionary[String, int] = {
	"bench-warmers": 45, "power-reserve": 6, "guardian": 125, "lovebirds": 70, "lazy-bones": 25,
}

# --- Static functions ---

## Configure the batch's private catalog once. Empty text means a known experiment.
static func configure(catalog: EffectsCatalog, variant: String, core: PackedStringArray) -> String:
	if variant.begins_with("without-"):
		var omitted: String = variant.trim_prefix("without-")
		for item: BuildDefinition in catalog.all_definitions():
			if String(item.id) == omitted:
				item.effects.assign([EffectDefinition.OnValidation.new(&"control", null, [ScoreAction.Points.new(0)])])
				return ""
		return "Unknown omitted effect: " + omitted
	if variant.begins_with("trial-"):
		_first_pass(catalog)
		var trial: String = variant.trim_prefix("trial-")
		var items: PackedStringArray = [trial]
		if trial == "held-package":
			items = ["bench-warmers", "power-reserve"]
		elif trial == "held-support":
			items = ["bench-warmers", "lazy-bones"]
		for id: String in items:
			if not TRIAL_VALUES.has(id):
				return "Unknown item value trial: " + id
		for definition: BuildDefinition in catalog.all_definitions():
			if String(definition.id) in items:
				_set_reward(definition, TRIAL_VALUES[String(definition.id)])
		return ""
	if not variant in VARIANTS:
		return "Unknown balance rules: " + variant
	match variant:
		"current", "chase-four":
			return ""
		"reduce-opening-act":
			_set_reward(catalog.bonus(&"opening-act"), 6)
			return ""
		"reduce-nest-egg":
			var nest: ScoreAction = catalog.joker(&"nest-egg").effects[0].actions[0] as ScoreAction
			nest.amount = HalfPortfolio.new()
			return ""
		"swap-opening-act":
			core[1] = "opening-act"
			return ""
		"swap-nest-egg":
			core[2] = "nest-egg"
			return ""
	_first_pass(catalog)
	if variant == "first-pass":
		return ""
	# Each initial candidate is compared with the same original, pre-pass catalog.
	if variant != "double-date":
		_set_reward(catalog.joker(&"double-date"), 60)
	if variant != "house-builder":
		catalog.upgrade(&"house-builder").effects.resize(1)
	if variant != "one-man-band":
		catalog.joker(&"one-man-band").effects.resize(1)
	if variant == "opening-act":
		_set_reward(catalog.bonus(&"opening-act"), 6)
	if variant == "nest-egg":
		var action: ScoreAction = catalog.joker(&"nest-egg").effects[0].actions[0] as ScoreAction
		action.amount = HalfPortfolio.new()
	return ""

## Undo the later support and Pair tuning when replaying historical controls.
static func _first_pass(catalog: EffectsCatalog) -> void:
	_set_reward(catalog.joker(&"lovebirds"), 40)
	_set_reward(catalog.joker(&"bench-warmers"), 15)
	_set_reward(catalog.bonus(&"power-reserve"), 2)

## These trials vary the value of a single authored scoring action and preserve its eligibility.
static func _set_reward(definition: BuildDefinition, value: int) -> void:
	var reward: ScoreAction = definition.effects[0].actions[0] as ScoreAction
	if reward.amount.query:
		reward.amount.per_die = value
	else:
		reward.amount.constant = value
