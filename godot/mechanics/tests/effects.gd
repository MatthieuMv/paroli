extends SceneTree
## Every EFFECTS.md entry, negative eligibility boundaries, and interacting lifecycle behavior.

# --- Types ---

## Independent specification rows for category fixtures, names, and rewards.
class CategoryCase:
	extends RefCounted

	# --- Member variables ---

	## Exact recognized category.
	var category: StringName
	## Five current logical values.
	var values: PackedInt32Array
	## Bonus and Joker IDs from the document.
	var bonus: StringName
	## Global counterpart.
	var joker: StringName
	## Independent expected contributions.
	var mult: int
	## Points from the corresponding Joker.
	var points: int

	# --- Member functions ---

	## Keep the acceptance table separate from catalog construction.
	func _init(category_: StringName, values_: PackedInt32Array, bonus_: StringName, joker_: StringName, mult_: int, points_: int) -> void:
		category = category_
		values = values_
		bonus = bonus_
		joker = joker_
		mult = mult_
		points = points_

# --- Member variables ---

## Fresh class-authored definitions and translation vocabulary.
var _catalog: EffectsCatalog = EffectsCatalog.new()
## Shared read-only wording for all descriptions.
var _words: KeywordCatalog = GameKeywords.new()
## Track positive behavior coverage, not just resource existence.
var _covered: Dictionary[StringName, bool] = {}

# --- Member functions ---

## Defer until classes and resource references are ready.
func _initialize() -> void:
	_run.call_deferred()

## Run pure rules first, then lifecycle interactions against the public runtime API.
func _run() -> void:
	assert(_catalog.upgrades.size() == 14 and _catalog.bonuses.size() == 29 and _catalog.jokers.size() == 28)
	assert(_words.validate().is_empty())
	var ids: Array[StringName] = []
	for definition: BuildDefinition in _catalog.all_definitions():
		assert(not definition.id in ids)
		ids.append(definition.id)
		assert(definition.validate_keywords(_words).is_empty(), str(definition.validate_keywords(_words)))
		for locale: String in ["en", "fr"]:
			var text: String = definition.describe(_words, locale)
			assert(not text.is_empty() and not "[missing" in text and not "Invalid" in text)
	_categories()
	_matching_and_values()
	_diversity_and_support()
	_selection_and_sequence()
	_economy_and_history_rules()
	_recognition()
	_runtime_history()
	_runtime_support_and_alternator()
	_runtime_economy()
	_runtime_percentages_and_limits()
	_runtime_tempo_and_preview()
	for id: StringName in ids:
		assert(_covered.has(id), "No reward test for " + String(id))
	print("PASS: all 71 EFFECTS.md definitions, recognition, percentage aggregation, lifecycle, economy, ownership and localization.")
	quit()

## Construct a logical event and recognize its real category independently from effects.
func _context(values: PackedInt32Array, source: int = 0, selected: PackedInt32Array = []) -> EffectContext:
	var context: EffectContext = EffectContext.new()
	context.event_id = &"test_validation"
	context.source_die_id = StringName("die_%d" % (source + 1))
	context.validations_remaining = 3
	context.rerolls_remaining = 3
	var selected_dice: Array[DieSnapshot] = []
	for index: int in values.size():
		var die: DieSnapshot = DieSnapshot.new(StringName("die_%d" % (index + 1)), values[index])
		die.validated = selected.is_empty() or index in selected
		die.held = not die.validated
		context.dice.append(die)
		if die.validated:
			selected_dice.append(die)
	var recognized: CombinationRecognizer.Result = CombinationRecognizer.recognize(selected_dice)
	context.combination = recognized.category
	for die: DieSnapshot in context.dice:
		die.combination_member = die.id in recognized.members
	return context

## Find the authored definition without deriving any expected reward from its internals.
func _definition(id: StringName) -> BuildDefinition:
	for definition: BuildDefinition in _catalog.all_definitions():
		if definition.id == id:
			return definition
	assert(false, "Unknown test definition: " + String(id))
	return null

## Sum actual commands and compare with independently specified expected values.
func _expect(id: StringName, context: EffectContext, points: int = 0, mult: int = 0, percent: int = 0, coins: int = 0, extra_kind: int = -1, extra_amount: int = 0) -> void:
	var definition: BuildDefinition = _definition(id)
	if definition is JokerDefinition:
		context.source_die_id = &""
	context.owner_id = StringName("owner:" + String(id))
	var resolution: EffectResolution = EffectResolver.resolve(definition, context)
	assert(resolution.errors.is_empty(), str(resolution.errors))
	var actual: PackedInt64Array = [0, 0, 0, 0, 0]
	for command: EffectCommand in resolution.commands:
		if command is ScoreDeltaCommand:
			var score: ScoreDeltaCommand = command as ScoreDeltaCommand
			actual[score.channel] += score.amount
		elif command is RuntimeDeltaCommand:
			var delta: RuntimeDeltaCommand = command as RuntimeDeltaCommand
			if delta.kind == RuntimeDeltaCommand.Kind.COINS:
				actual[3] += delta.amount
			else:
				assert(delta.kind == extra_kind, "Unexpected runtime destination for " + String(id))
				actual[4] += delta.amount
	assert(actual == PackedInt64Array([points, mult, percent, coins, extra_amount]), "%s: expected %s, got %s" % [id, [points, mult, percent, coins, extra_amount], actual])
	_covered[id] = true

## Every category pair has exact-category and member-only negative cases.
func _categories() -> void:
	var rows: Array[CategoryCase] = [
		CategoryCase.new(&"single", [6, 1, 2, 4, 5], &"solo_talent", &"solo_act", 6, 30),
		CategoryCase.new(&"pair", [2, 2, 1, 4, 6], &"pair_partner", &"better_together", 6, 40),
		CategoryCase.new(&"two_pairs", [2, 2, 5, 5, 6], &"double_partner", &"double_date", 8, 60),
		CategoryCase.new(&"three_of_a_kind", [2, 2, 2, 4, 6], &"triple_bond", &"three_company", 10, 80),
		CategoryCase.new(&"short_straight", [1, 2, 3, 4, 6], &"sure_footing", &"short_journey", 10, 100),
		CategoryCase.new(&"full_house", [2, 2, 3, 3, 3], &"house_guest", &"open_house", 12, 120),
		CategoryCase.new(&"long_straight", [1, 2, 3, 4, 5], &"last_mile", &"long_journey", 14, 140),
		CategoryCase.new(&"four_of_a_kind", [2, 2, 2, 2, 6], &"four_together", &"four_corners", 16, 160),
		CategoryCase.new(&"five_of_a_kind", [2, 2, 2, 2, 2], &"family_bond", &"family_reunion", 20, 200),
	]
	for row: CategoryCase in rows:
		var context: EffectContext = _context(row.values)
		assert(context.combination == row.category)
		_expect(row.bonus, context, 0, row.mult)
		context.dice[0].combination_member = false
		_expect(row.bonus, context)
		_expect(row.joker, _context(row.values), row.points)
		context = _context(row.values)
		context.combination = &"five_of_a_kind" if row.category != &"five_of_a_kind" else &"single"
		_expect(row.joker, context)
		_expect(row.bonus, _with_source(context, &"die_1"))
		var matching: bool = row.category in [&"pair", &"two_pairs", &"three_of_a_kind", &"full_house", &"four_of_a_kind", &"five_of_a_kind"]
		var members: int = 0
		context = _context(row.values)
		for die: DieSnapshot in context.dice:
			members += int(die.combination_member)
		_expect(&"match_master", context, members * 15 if matching else 0)

## Restore an attached source after a global Joker assertion.
func _with_source(context: EffectContext, source: StringName) -> EffectContext:
	context.source_die_id = source
	return context

## Matching counts, exact values, parity, and partner sums do not compound or double-count.
func _matching_and_values() -> void:
	for matches: int in range(5):
		var values: PackedInt32Array = [1, 2, 3, 4, 6]
		for index: int in matches:
			values[index + 1] = 1
		_expect(&"all_for_one", _context(values), 0, 0, matches * 25)
		_expect(&"family_spirit", _context(values), 0, matches * 2)
	_expect(&"house_builder", _context([2, 2, 3, 3, 3]), 0, 0, 50)
	_expect(&"house_builder", _context([2, 2, 3, 3, 3], 2), 0, 0, 50)
	_expect(&"house_builder", _context([2, 2, 2, 2, 3]))
	_expect(&"jackpot", _context([6, 2, 3, 4, 5]), 0, 0, 100)
	_expect(&"jackpot", _context([1, 2, 3, 4, 5]))
	_expect(&"one_or_nothing", _context([1, 2, 3, 4, 5]), 0, 4)
	_expect(&"six_addict", _context([6, 2, 3, 4, 5]), 0, 4)
	_expect(&"bipolarity", _context([1, 6, 1, 6, 1]), 75)
	_expect(&"bipolarity", _context([1, 6, 1, 6, 1], 0, [1, 2]), 30)
	_expect(&"odd_master", _context([1, 3, 5, 3, 1]), 0, 0, 100)
	_expect(&"even_master", _context([2, 4, 6, 2, 4]), 0, 0, 100)
	_expect(&"odd_charm", _context([3, 2, 4, 6, 2]), 0, 2)
	_expect(&"even_charm", _context([4, 1, 3, 5, 1]), 0, 2)
	_expect(&"lucky_seven", _context([1, 6, 6, 6, 6]), 0, 4)
	_expect(&"lucky_seven", _context([1, 2, 3, 4, 5]))
	_expect(&"mathmind", _context([1, 2, 3, 4, 5]), 100)
	_expect(&"mathmind", _context([1, 2, 3, 4, 6]))
	_expect(&"odd_squad", _context([1, 3, 5, 3, 1]), 50)
	_expect(&"even_squad", _context([2, 4, 6, 2, 4]), 50)
	# Every default die effect becomes ineligible when its owner is excluded.
	for id: StringName in [&"all_for_one", &"house_builder", &"jackpot", &"odd_master", &"even_master", &"one_or_nothing", &"six_addict", &"odd_charm", &"even_charm", &"lucky_seven"]:
		_expect(id, _context([6, 1, 1, 6, 6], 0, [1, 2, 3, 4]))

## Selection sizes and actual straight membership use the resolved snapshot.
func _selection_and_sequence() -> void:
	for count: int in range(1, 6):
		var selected: PackedInt32Array = []
		for index: int in count:
			selected.append(index)
		_expect(&"lone_wolf", _context([1, 2, 3, 4, 5], 0, selected), 0, 0, (5 - count) * 25)
		_expect(&"small_circle", _context([1, 2, 3, 4, 5], 0, selected), 0, 5 - count)
		_expect(&"less_is_more", _context([1, 2, 3, 4, 5], 0, selected), (5 - count) * 5)
	_expect(&"squad", _context([2, 2, 5, 5, 6], 0, [0, 1, 2, 3]), 0, 8)
	_expect(&"squad", _context([2, 2, 2, 2, 6], 0, [0, 1, 2, 3]), 0, 8)
	_expect(&"squad", _context([2, 2, 2, 2, 6]))
	_expect(&"stepping_stones", _context([2, 3, 4, 5, 1]), 0, 0, 75)
	_expect(&"stepping_stones", _context([2, 3, 4, 5, 1], 0, [0, 1, 2, 3]), 0, 0, 50)
	_expect(&"extremities", _context([1, 2, 3, 4, 5]), 0, 12)
	_expect(&"extremities", _context([1, 2, 3, 4, 5], 4), 0, 12)
	_expect(&"extremities", _context([1, 2, 3, 4, 5], 2))
	_expect(&"extremities", _context([1, 2, 3, 4, 4], 4))
	_expect(&"neighbours", _context([3, 2, 2, 4, 4]), 0, 4)
	_expect(&"neighbours", _context([3, 2, 2, 2, 6]))
	_expect(&"alignment", _context([1, 2, 3, 4, 5]), 75)
	_expect(&"alignment", _context([1, 2, 3, 4, 6]), 60)
	_expect(&"alignment", _context([2, 2, 2, 2, 2]))
	var context: EffectContext = _context([1, 2, 4, 5, 6])
	context.event = &"recognition"
	_expect(&"missing_link", context, 0, 0, 0, 0, RuntimeDeltaCommand.Kind.STRAIGHT_GAPS, 1)

## Pure rule checks establish explicit economy/history rewards before lifecycle tests.
func _economy_and_history_rules() -> void:
	_expect(&"pocket_money", _context([2, 2, 1, 4, 6]), 0, 0, 0, 2)
	_expect(&"pocket_money", _context([2, 2, 1, 4, 6], 4))
	_expect(&"paid_leave", _context([2, 2, 1, 4, 6], 4, [0, 1]), 0, 0, 0, 1)
	_expect(&"paid_leave", _context([2, 2, 1, 4, 6]))
	_expect(&"golden_touch", _context([6, 6, 1, 2, 3]), 0, 0, 0, 6)
	var context: EffectContext = _context([1, 2, 3, 4, 5])
	context.event = &"rolled"
	context.rolled_ids = [&"die_1"]
	for kind: EffectContext.RollKind in [EffectContext.RollKind.OPENING, EffectContext.RollKind.COSMETIC, EffectContext.RollKind.MANUAL, EffectContext.RollKind.AUTOMATIC]:
		context.roll_kind = kind
		_expect(&"rolling_income", context, 0, 0, 0, 1 if kind == EffectContext.RollKind.MANUAL else 0)
	context = _context([1, 2, 3, 4, 5])
	context.event = &"round_ended"
	context.round_succeeded = true
	_expect(&"stonks", context, 0, 0, 0, 0, RuntimeDeltaCommand.Kind.SELL_VALUE, 1)
	context.round_succeeded = false
	_expect(&"stonks", context)
	context.event = &"shop_refreshed"
	context.refresh_cost = 7
	_expect(&"window_shopper", context, 0, 0, 0, 0, RuntimeDeltaCommand.Kind.ACCUMULATED_MULT, 1)
	context.event = &"validation"
	context.owner_mult = 4
	_expect(&"window_shopper", context, 0, 4)
	context.joker_sell_total = 13
	_expect(&"portfolio", context, 0, 13)
	context = _context([3, 2, 3, 4, 5])
	context.dice[0].rerolls_since_validation = 4
	context.dice[0].manual_rerolls_round = 4
	_expect(&"relentless", context, 0, 0, 100)
	_expect(&"persistence", context, 0, 12)
	_expect(&"first_instinct", context)
	context.dice[0].manual_rerolls_round = 0
	_expect(&"first_instinct", context, 0, 4)
	context.rerolls_remaining = 0
	_expect(&"last_chance", context, 60)
	context.event = &"round_started"
	_expect(&"extra_time", context, 0, 0, 0, 0, RuntimeDeltaCommand.Kind.VALIDATIONS, 1)
	_expect(&"second_chance", context, 0, 0, 0, 0, RuntimeDeltaCommand.Kind.REROLLS, 1)
	context = _context([3, 2, 3, 4, 5])
	_expect(&"opening_act", context, 0, 8)
	context.previous_validations = 2
	_expect(&"opening_act", context)
	context.validations_remaining = 1
	_expect(&"grand_finale", context, 0, 12)
	_expect(&"momentum", context, 50)
	context = _context([3, 2, 3, 4, 5])
	context.dice[0].previous_validated_value = 2
	context.dice[0].crescendo_percent = 50
	_expect(&"crescendo", context, 0, 0, 100)
	context.dice[0].value = 2
	_expect(&"crescendo", context, 0, 0, 50)
	_expect(&"deja_vu", context, 0, 0, 50)
	_expect(&"echo", context, 0, 8)
	context.dice[0].previous_validated_value = 0
	_expect(&"echo", context)
	_expect(&"deja_vu", context)
	context.previous_combination = context.combination
	_expect(&"habit", context, 50)
	context.previous_combination = &"five_of_a_kind"
	_expect(&"variety", context, 50)
	context.previous_combination = &""
	_expect(&"habit", context)
	_expect(&"variety", context)

## Recognition validates actual distinct values, gap bounds, scoring rank, and stable ties.
func _recognition() -> void:
	var context: EffectContext = _context([1, 2, 4, 5, 6])
	var selected: Array[DieSnapshot] = context.dice
	assert(CombinationRecognizer.recognize(selected, 1).category == &"long_straight")
	context = _context([1, 2, 4, 5])
	assert(CombinationRecognizer.recognize(context.dice, 0).category == &"single")
	assert(CombinationRecognizer.recognize(context.dice, 1).category == &"short_straight")
	context = _context([1, 2, 4, 6])
	assert(CombinationRecognizer.recognize(context.dice, 1).category == &"single")
	context = _context([1, 2, 3, 6])
	assert(CombinationRecognizer.recognize(context.dice, 1).category == &"single")
	context = _context([1, 2, 2, 4, 5])
	assert(CombinationRecognizer.recognize(context.dice, 1).category == &"short_straight")
	context = _context([1, 2, 3, 4, 4])
	var recognized: CombinationRecognizer.Result = CombinationRecognizer.recognize(context.dice)
	assert(recognized.members == [&"die_1", &"die_2", &"die_3", &"die_4"])
	# Every five-distinct-value subset of the standard faces becomes a long straight.
	for missing: int in range(1, 7):
		var values: PackedInt32Array = []
		for value: int in range(1, 7):
			if value != missing:
				values.append(value)
		assert(CombinationRecognizer.recognize(_context(values).dice, 1).category == &"long_straight")

## Open a deterministic round; supplied indices avoid randomness in lifecycle tests.
func _start(run: MechanicsRun, id: StringName = &"start", validations: int = 6, rerolls: int = 6) -> void:
	assert(run.start_round(id, 1000000, validations, rerolls).errors.is_empty())
	assert(run.roll(StringName(String(id) + ":opening"), {&"die_1": 0, &"die_2": 0, &"die_3": 0, &"die_4": 0, &"die_5": 0}, EffectContext.RollKind.OPENING).errors.is_empty())

## History updates happen after scoring and reset at the documented boundaries.
func _runtime_history() -> void:
	var run: MechanicsRun = MechanicsRun.new()
	assert(run.install_upgrade(_catalog.upgrade(&"relentless")).is_empty())
	assert(run.equip_bonus(_catalog.bonus(&"persistence"), &"die_1", 2).is_empty())
	assert(run.equip_bonus(_catalog.bonus(&"first_instinct"), &"die_2", 2).is_empty())
	assert(run.add_joker(_catalog.joker(&"momentum"), 3).is_empty())
	_start(run)
	assert(run.roll(&"manual_1", {&"die_1": 1, &"die_2": 0}, EffectContext.RollKind.MANUAL).errors.is_empty())
	assert(run.roll(&"manual_2", {&"die_1": 2}, EffectContext.RollKind.MANUAL).errors.is_empty())
	var result: MechanicsEventResult = run.validate_dice(&"v1", [&"die_1"], 10, 2)
	assert(result.errors.is_empty() and result.flat_mult == 8 and result.mult_percent == 50 and result.credited_score == 120)
	assert(run.find_die(&"die_1").rerolls_since_validation == 0)
	assert(run.find_die(&"die_1").manual_rerolls_round == 2)
	assert(run.roll(&"auto_1", {&"die_1": 0}, EffectContext.RollKind.AUTOMATIC).errors.is_empty())
	result = run.validate_dice(&"v2", [&"die_1", &"die_2"], 0, 0)
	assert(result.errors.is_empty() and result.flat_mult == 0 and result.mult_percent == 0 and result.points == 25)
	assert(run.find_die(&"die_2").manual_rerolls_round == 1)
	assert(run.previous_validations == 2)
	assert(run.finish_round(&"finish", true).errors.is_empty())
	_start(run, &"round_2")
	assert(run.find_die(&"die_1").manual_rerolls_round == 0 and run.find_die(&"die_1").previous_validated_value == 0)
	# Crescendo includes the current strictly increasing result and retains stacks on decreases.
	run = MechanicsRun.new()
	assert(run.install_upgrade(_catalog.upgrade(&"crescendo")).is_empty())
	assert(run.equip_bonus(_catalog.bonus(&"echo"), &"die_1", 2).is_empty())
	assert(run.add_joker(_catalog.joker(&"habit"), 3).is_empty())
	assert(run.add_joker(_catalog.joker(&"variety"), 3).is_empty())
	_start(run)
	result = run.validate_dice(&"c1", [&"die_1"], 0, 1)
	assert(result.mult_percent == 0 and result.points == 0 and result.flat_mult == 1)
	assert(run.roll(&"ca1", {&"die_1": 2}, EffectContext.RollKind.AUTOMATIC).errors.is_empty())
	result = run.validate_dice(&"c2", [&"die_1"], 0, 1)
	assert(result.mult_percent == 50 and result.points == 50 and result.flat_mult == 1)
	assert(run.roll(&"ca2", {&"die_1": 4}, EffectContext.RollKind.AUTOMATIC).errors.is_empty())
	result = run.validate_dice(&"c3", [&"die_1"], 0, 1)
	assert(result.mult_percent == 100)
	assert(run.roll(&"ca3", {&"die_1": 0}, EffectContext.RollKind.AUTOMATIC).errors.is_empty())
	result = run.validate_dice(&"c4", [&"die_1"], 0, 1)
	assert(result.mult_percent == 100)
	assert(run.roll(&"ca4", {&"die_1": 1}, EffectContext.RollKind.AUTOMATIC).errors.is_empty())
	result = run.validate_dice(&"c5", [&"die_1"], 0, 1)
	assert(result.mult_percent == 100 and result.flat_mult == 9)
	assert(run.finish_round(&"cf", true).errors.is_empty())
	_start(run, &"cr2")
	assert(run.find_die(&"die_1").crescendo_percent == 0)

## Paid events, ownership growth, retries, sale, and fresh repurchase are integrated.
func _runtime_economy() -> void:
	var run: MechanicsRun = MechanicsRun.new(100)
	assert(run.equip_bonus(_catalog.bonus(&"rolling_income"), &"die_1", 2).is_empty())
	assert(run.equip_bonus(_catalog.bonus(&"paid_leave"), &"die_2", 2).is_empty())
	assert(run.add_joker(_catalog.joker(&"stonks"), 4).is_empty())
	assert(run.add_joker(_catalog.joker(&"window_shopper"), 3).is_empty())
	assert(run.add_joker(_catalog.joker(&"portfolio"), 5).is_empty())
	assert(run.paid_refresh(&"refresh1", 7).errors.is_empty())
	assert(run.paid_refresh(&"refresh1", 7).errors.is_empty())
	assert(run.coins == 93 and run.find_owned(&"joker:window_shopper").accumulated_mult == 1)
	_start(run)
	assert(run.coins == 93)
	assert(run.roll(&"manual", {&"die_1": 1}, EffectContext.RollKind.MANUAL).errors.is_empty())
	assert(run.coins == 94)
	var result: MechanicsEventResult = run.validate_dice(&"money_v", [&"die_1"], 0, 0)
	assert(result.errors.is_empty() and result.flat_mult == 13 and run.coins == 95)
	assert(run.validate_dice(&"money_v", [&"die_1"], 0, 0) == result and run.coins == 95)
	assert(run.roll(&"money_auto", {&"die_1": 0}, EffectContext.RollKind.AUTOMATIC).errors.is_empty())
	assert(run.coins == 95, "Automatic post-play rolls must not grant income")
	assert(run.finish_round(&"money_finish", true).errors.is_empty())
	assert(run.find_owned(&"joker:stonks").sell_value() == 5 and run.coins == 95)
	assert(not run.finish_round(&"finish_again", true).errors.is_empty())
	assert(run.roll(&"cosmetic", {&"die_1": 5}, EffectContext.RollKind.COSMETIC).errors.is_empty() and run.coins == 95)
	_start(run, &"money_round2")
	result = run.validate_dice(&"portfolio_v", [&"die_1"], 0, 0)
	assert(result.flat_mult == 14)
	assert(run.finish_round(&"money_finish2", true).errors.is_empty())
	assert(run.sell(&"sell_stonks", &"joker:stonks").errors.is_empty())
	assert(run.coins == 102)
	assert(run.sell(&"sell_window", &"joker:window_shopper").errors.is_empty())
	assert(run.add_joker(_catalog.joker(&"window_shopper"), 3).is_empty())
	assert(run.find_owned(&"joker:window_shopper").accumulated_mult == 0)
	assert(run.add_joker(_catalog.joker(&"stonks"), 4).is_empty())
	assert(run.find_owned(&"joker:stonks").sell_growth == 0)
	assert(not run.paid_refresh(&"free", 0).errors.is_empty())

## Percentages sum across owners, early success stops rolls, and slot/allowance rules hold.
func _runtime_percentages_and_limits() -> void:
	var run: MechanicsRun = MechanicsRun.new()
	assert(run.install_upgrade(_catalog.upgrade(&"jackpot")).is_empty())
	assert(run.install_upgrade(_catalog.upgrade(&"jackpot")).is_empty())
	assert(run.equip_bonus(_catalog.bonus(&"six_addict"), &"die_1", 2).is_empty())
	assert(run.add_joker(_catalog.joker(&"extra_time"), 3).is_empty())
	assert(run.add_joker(_catalog.joker(&"second_chance"), 3).is_empty())
	assert(run.add_joker(_catalog.joker(&"stonks"), 4).is_empty())
	assert(run.add_joker(_catalog.joker(&"missing_link"), 4).is_empty())
	assert(not run.add_joker(_catalog.joker(&"portfolio"), 4).is_empty())
	assert(not run.equip_bonus(_catalog.bonus(&"six_addict"), &"die_2", 2).is_empty())
	assert(not run.equip_bonus(_catalog.bonus(&"echo"), &"die_1", 2).is_empty())
	assert(run.start_round(&"percent_start", 100).errors.is_empty())
	assert(run.validations_remaining == 4 and run.rerolls_remaining == 4)
	assert(run.roll(&"percent_open", {&"die_1": 5, &"die_2": 5, &"die_3": 0, &"die_4": 1, &"die_5": 2}, EffectContext.RollKind.OPENING).errors.is_empty())
	var result: MechanicsEventResult = run.validate_dice(&"percent_v", [&"die_1", &"die_2"], 10, 2)
	assert(result.errors.is_empty() and result.mult_percent == 200 and result.flat_mult == 6)
	assert(result.final_mult == 18 and result.credited_score == 180)
	assert(not run.round_active and not run.run_failed)
	assert(run.find_owned(&"joker:stonks").sell_growth == 1)
	assert(not run.roll(&"illegal_auto", {&"die_1": 0, &"die_2": 0}, EffectContext.RollKind.AUTOMATIC).errors.is_empty())
	assert(not run.validate_dice(&"illegal_v", [&"die_1"], 1, 1).errors.is_empty())
	assert(not run.sell(&"illegal_sale", &"upgrade:die_1").errors.is_empty())
	assert(run.move_bonus(&"die_1", &"die_2").is_empty())
	assert(run.find_die(&"die_2").faces == PackedInt32Array([1, 1, 1, 1, 1, 6]))
	assert(run.sell(&"sell_extra", &"joker:extra_time").errors.is_empty())
	_start(run, &"after_sale", 3, 3)
	assert(run.validations_remaining == 3 and run.rerolls_remaining == 4)
	assert(run.finish_round(&"failed", false).errors.is_empty())
	assert(run.find_owned(&"joker:stonks").sell_growth == 1)
	assert(not run.start_round(&"after_failure", 100).errors.is_empty())


## Distinct values and held matches count entities once, never duplicate value/partner products.
func _diversity_and_support() -> void:
	_expect(&"rainbow", _context([1, 2, 3, 4, 5]), 0, 0, 100)
	_expect(&"rainbow", _context([1, 1, 2, 3, 6], 0, [0, 1, 2]), 0, 0, 40)
	_expect(&"rainbow", _context([1, 1, 2, 3, 6], 0, [1, 2]))
	_expect(&"variety_show", _context([1, 2, 3, 4, 5]), 50)
	_expect(&"variety_show", _context([1, 1, 2, 3, 6], 0, [0, 1, 2]), 20)
	_expect(&"unique", _context([1, 2, 2, 4, 6], 0, [0, 1, 2]), 0, 4)
	_expect(&"unique", _context([1, 2, 3, 4, 6], 0, [0, 1]))
	_expect(&"unique", _context([1, 1, 2, 4, 6], 0, [0, 1, 2]))
	_expect(&"guardian", _context([1, 1, 1, 4, 6], 0, [1, 2]), 0, 0, 50)
	_expect(&"guardian", _context([1, 1, 1, 4, 6]))
	_expect(&"guardian", _context([1, 2, 3, 4, 6], 0, [1, 2]))
	_expect(&"quiet_strength", _context([1, 2, 3, 4, 6], 0, [1, 2]), 0, 2)
	_expect(&"quiet_strength", _context([1, 2, 3, 4, 6]))
	_expect(&"backup", _context([1, 1, 1, 1, 1], 0, [0]), 60)
	_expect(&"backup", _context([1, 1, 1, 1, 1], 0, [0, 1]), 45)
	_expect(&"backup", _context([1, 1, 1, 1, 1]), 0)
	_expect(&"backup", _context([1, 2, 3, 4, 5], 0, [0]), 0)
	var context: EffectContext = _context([6, 2, 2, 2, 3])
	_expect(&"alternator", context)
	context.dice[0].previous_validated_value = 1
	_expect(&"alternator", context, 0, 0, 50)
	context.dice[0].previous_validated_value = 6
	_expect(&"alternator", context)

## Held support and distinct scoring observe one snapshot regardless of ownership order.
func _runtime_support_and_alternator() -> void:
	for reversed: bool in [false, true]:
		var run: MechanicsRun = MechanicsRun.new()
		assert(run.install_upgrade(_catalog.upgrade(&"guardian")).is_empty())
		assert(run.install_upgrade(_catalog.upgrade(&"rainbow")).is_empty())
		assert(run.equip_bonus(_catalog.bonus(&"quiet_strength"), &"die_1", 2).is_empty())
		assert(run.equip_bonus(_catalog.bonus(&"unique"), &"die_2", 2).is_empty())
		assert(run.add_joker(_catalog.joker(&"backup"), 3).is_empty())
		assert(run.add_joker(_catalog.joker(&"variety_show"), 3).is_empty())
		if reversed:
			run.owned.reverse()
		assert(run.start_round(&"support_start", 100000).errors.is_empty())
		assert(run.roll(&"support_open", {&"die_1": 0, &"die_2": 0, &"die_3": 1, &"die_4": 1, &"die_5": 0}, EffectContext.RollKind.OPENING).errors.is_empty())
		var result: MechanicsEventResult = run.validate_dice(&"support_v", [&"die_2", &"die_3", &"die_4"], 10, 1)
		assert(result.errors.is_empty())
		assert(result.points == 60 and result.flat_mult == 7 and result.mult_percent == 90)
		assert(is_equal_approx(result.credited_score, 798.0))
		assert(run.find_die(&"die_1").previous_validated_value == 0)
	var run: MechanicsRun = MechanicsRun.new()
	assert(run.install_upgrade(_catalog.upgrade(&"alternator")).is_empty())
	_start(run)
	var first: MechanicsEventResult = run.validate_dice(&"a1", [&"die_1"], 0, 1)
	assert(first.mult_percent == 0)
	assert(run.roll(&"aa1", {&"die_1": 5}, EffectContext.RollKind.AUTOMATIC).errors.is_empty())
	assert(run.validate_dice(&"a2", [&"die_2"], 0, 1).errors.is_empty())
	assert(run.roll(&"aa2", {&"die_2": 0}, EffectContext.RollKind.AUTOMATIC).errors.is_empty())
	assert(run.validate_dice(&"a3", [&"die_1"], 0, 1).mult_percent == 50)
	assert(run.roll(&"aa3", {&"die_1": 5}, EffectContext.RollKind.AUTOMATIC).errors.is_empty())
	assert(run.validate_dice(&"a4", [&"die_1"], 0, 1).mult_percent == 0)
	assert(run.finish_round(&"af", true).errors.is_empty())
	_start(run, &"a_round2")
	assert(run.validate_dice(&"a5", [&"die_1"], 0, 1).mult_percent == 0)


## Extra time delays the last-validation reward; recognition preview includes owned Missing link.
func _runtime_tempo_and_preview() -> void:
	var run: MechanicsRun = MechanicsRun.new()
	assert(run.equip_bonus(_catalog.bonus(&"grand_finale"), &"die_1", 2).is_empty())
	assert(run.add_joker(_catalog.joker(&"extra_time"), 3).is_empty())
	assert(run.add_joker(_catalog.joker(&"momentum"), 3).is_empty())
	_start(run, &"tempo_start", 3, 3)
	assert(run.validations_remaining == 4)
	for index: int in 4:
		var result: MechanicsEventResult = run.validate_dice(StringName("tempo_v%d" % index), [&"die_1"], 0, 0)
		assert(result.errors.is_empty())
		assert(result.points == index * 25)
		assert(result.flat_mult == (12 if index == 3 else 0))
		if index < 3:
			assert(run.roll(StringName("tempo_auto%d" % index), {&"die_1": 0}, EffectContext.RollKind.AUTOMATIC).errors.is_empty())
	assert(not run.round_active and run.run_failed)
	run = MechanicsRun.new()
	assert(run.add_joker(_catalog.joker(&"missing_link"), 3).is_empty())
	assert(run.start_round(&"preview_start", 100000).errors.is_empty())
	assert(run.roll(&"preview_open", {&"die_1": 0, &"die_2": 1, &"die_3": 3, &"die_4": 4, &"die_5": 5}, EffectContext.RollKind.OPENING).errors.is_empty())
	var chosen: Array[StringName] = [&"die_1", &"die_2", &"die_3", &"die_4"]
	assert(run.preview_combination(chosen).category == &"short_straight")
	assert(run.previous_validations == 0 and run.coins == 0)
	var result: MechanicsEventResult = run.validate_dice(&"preview_commit", chosen, 10, 1)
	assert(result.combination.category == &"short_straight")
	assert(result.points == 10 and result.flat_mult == 1)
