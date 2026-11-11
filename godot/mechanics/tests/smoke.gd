extends SceneTree
## Human-authored class examples, typed commands, and localized text contract tests.

# --- Member variables ---

## The production authoring path is typed GDScript constructors, not serialized graphs.
var _words: KeywordCatalog = GameKeywords.new()
## Fresh example catalogs prevent tests from sharing mutable resource instances.
var _bloom: UpgradeDefinition = UpgradeExamples.new().patient_bloom
## Count-scaled upgrade fixture.
var _odd: UpgradeDefinition = UpgradeExamples.new().odd_master
## Explicit unheld/validated fixture.
var _bonus: BonusDefinition = BonusExamples.new().unheld_six
## Ownerless combination fixture.
var _joker: JokerDefinition = JokerExamples.new().straight

# --- Member functions ---

## Run deterministic checks without scene rendering, clocks, input, or random outcomes.
func _initialize() -> void:
	_run.call_deferred()

## Keep failures scoped to authoring, evaluation, or text rather than a live game loop.
func _run() -> void:
	assert(_words.validate().is_empty())
	for definition: BuildDefinition in [_bloom, _odd, _bonus, _joker]:
		assert(definition.validate().is_empty(), str(definition.validate()))
		assert(definition.validate_keywords(_words).is_empty())
		for locale: String in ["en", "fr", "fr_CA", "de"]:
			var description: String = definition.describe(_words, locale)
			assert(not description.is_empty() and not "[missing" in description)
			assert(not "{" in description)
	_test_named_classes()
	_test_queries_and_amounts()
	_test_conditions_and_commands()
	_test_invalid_graphs()
	_test_localization()
	print(_bloom.describe(_words, "en"))
	print(_bloom.describe(_words, "fr"))
	print("PASS: class-authored definitions, held/validated/member distinctions, counts, predicates, commands, cycles, localization.")
	quit()

## Supply a fixed logical pool independently from ParoliDie rendering.
func _context() -> EffectContext:
	var context: EffectContext = EffectContext.new()
	context.event_id = &"validation_001"
	context.source_die_id = &"die_1"
	context.event_die_id = &"die_2"
	context.combination = &"pair"
	for index: int in 5:
		var die: DieSnapshot = DieSnapshot.new(StringName("die_%d" % (index + 1)), [1, 3, 3, 5, 6][index])
		die.validated = true
		die.combination_member = index in [1, 2]
		context.dice.append(die)
	return context

## Query flags are orthogonal; amounts count physical snapshots rather than face positions.
func _test_queries_and_amounts() -> void:
	var context: EffectContext = _context()
	var result: EffectResolution = EffectResolver.resolve(_odd, context)
	assert(result.errors.is_empty() and result.commands.size() == 1)
	assert((result.commands[0] as ScoreDeltaCommand).amount == 80)
	assert(result.commands[0].event_id == context.event_id)
	assert(result.commands[0].definition_id == _odd.id)
	assert(result.commands[0].source_die_id == context.source_die_id)
	var affine: EffectAmount = EffectAmount.new()
	affine.constant = 2
	affine.per_die = 3
	affine.query = DieQuery.new()
	affine.query.scope = DieQuery.Scope.POOL
	affine.query.parity = DieQuery.Parity.ODD
	assert(affine.evaluate(context) == 14)
	context.dice[0].validated = false
	context.dice[0].held = true
	assert(EffectResolver.resolve(_odd, context).commands.is_empty())
	result = EffectResolver.resolve(_bloom, context)
	assert(result.commands.size() == 1 and (result.commands[0] as ScoreDeltaCommand).amount == 6)
	context.dice[0].value = 2
	assert((EffectResolver.resolve(_bloom, context).commands[0] as ScoreDeltaCommand).amount == 4)
	context.dice[0].value = 3
	assert((EffectResolver.resolve(_bloom, context).commands[0] as ScoreDeltaCommand).amount == 2)
	context.dice[0].validated = true
	assert(EffectResolver.resolve(_bloom, context).commands.is_empty())
	context.dice[0].held = false
	context.dice[0].value = 6
	assert((EffectResolver.resolve(_bonus, context).commands[0] as ScoreDeltaCommand).amount == 8)
	var query: DieQuery = DieQuery.new()
	query.scope = DieQuery.Scope.POOL
	query.member = DieQuery.State.YES
	assert(query.select(context).size() == 2)
	query.values = [3, 3]
	assert(query.select(context).size() == 2)
	query.scope = DieQuery.Scope.EVENT
	assert(query.select(context)[0].id == &"die_2")
	context.event = &"held"
	assert(EffectResolver.resolve(_bonus, context).commands.is_empty())
	context.source_die_id = &""
	context.event = &"validation"
	context.combination = &"long_straight"
	assert((EffectResolver.resolve(_joker, context).commands[0] as ScoreDeltaCommand).amount == 20)
	context.combination = &"full_house"
	assert(EffectResolver.resolve(_joker, context).commands.is_empty())
	assert(not EffectResolver.resolve(_bonus, context).errors.is_empty())

## Nested conditions and signed deltas produce deterministic, non-mutating commands.
func _test_conditions_and_commands() -> void:
	var context: EffectContext = _context()
	var subject: SourceEventCondition = SourceEventCondition.new()
	assert(not subject.matches(context))
	context.event_die_id = context.source_die_id
	assert(subject.matches(context))
	subject.same_die = false
	assert(not subject.matches(context))
	context.event_die_id = &""
	assert(not subject.matches(context))
	var source: DieQuery = DieQuery.new()
	source.validated = DieQuery.State.YES
	var present: DiceCountCondition = DiceCountCondition.new()
	present.query = source
	var combination: CombinationCondition = CombinationCondition.new()
	combination.combinations = [&"pair"]
	var all: ConditionGroup = ConditionGroup.new()
	all.conditions = [present, combination]
	assert(all.matches(context))
	all.conditions = [present, present]
	assert(all.validate().is_empty(), "Shared nodes are not cycles")
	all.conditions = [present, combination]
	all.mode = ConditionGroup.Mode.ANY
	context.dice[0].validated = false
	assert(all.matches(context))
	all.mode = ConditionGroup.Mode.NOT
	all.conditions = [present]
	assert(all.matches(context))
	var amount: EffectAmount = EffectAmount.new()
	amount.constant = -8
	var score: ScoreAction = ScoreAction.new()
	score.channel = ScoreDeltaCommand.Channel.MULT
	score.amount = amount
	var faces: ReplaceFacesAction = ReplaceFacesAction.new()
	faces.targets = DieQuery.new()
	faces.faces = [1, 1, 1, 6, 6, 6]
	var effect: EffectDefinition = EffectDefinition.new()
	effect.id = &"test"
	effect.condition = all
	effect.actions = [score, faces]
	var definition: UpgradeDefinition = UpgradeDefinition.new()
	definition.id = &"test"
	definition.effects = [effect]
	var result: EffectResolution = EffectResolver.resolve(definition, context)
	assert(result.errors.is_empty() and result.commands.size() == 2)
	assert((result.commands[0] as ScoreDeltaCommand).amount == -8)
	assert((result.commands[1] as ReplaceFacesCommand).target_die_id == &"die_1")
	assert(context.dice[0].value == 1)
	(result.commands[1] as ReplaceFacesCommand).faces[0] = 6
	assert(faces.faces[0] == 1)
	var repeated: EffectResolution = EffectResolver.resolve(definition, context)
	assert((repeated.commands[1] as ReplaceFacesCommand).faces[0] == 1)
	assert("-8" in definition.describe(_words, "en"))
	# An absent owner never turns a source query into a pool-wide target.
	context.source_die_id = &""
	assert(faces.commands(context).is_empty())
	context.source_die_id = &"die_1"
	effect.actions = [faces, score]
	assert((EffectResolver.resolve(definition, context).commands[1] as ScoreDeltaCommand).amount == -8)
	var empty: DiceCountCondition = DiceCountCondition.new()
	empty.query = DieQuery.new()
	empty.query.values = [99]
	empty.minimum = 0
	empty.maximum = 0
	assert(empty.matches(context))
	empty.minimum = 1
	empty.maximum = -1
	assert(not empty.matches(context))

## Invalid definitions fail atomically and cyclic descriptions do not recurse forever.
func _test_invalid_graphs() -> void:
	var group: ConditionGroup = ConditionGroup.new()
	group.conditions = [group]
	assert(not group.validate().is_empty())
	group.conditions.clear()
	assert(not group.validate().is_empty())
	var definition: UpgradeDefinition = UpgradeDefinition.new()
	definition.id = &"bad"
	definition.faces = [1, 2]
	assert(not EffectResolver.resolve(definition, _context()).errors.is_empty())
	var effect: EffectDefinition = EffectDefinition.new()
	effect.id = &"bad"
	effect.actions = [null]
	definition.faces = []
	definition.effects = [effect]
	var result: EffectResolution = EffectResolver.resolve(definition, _context())
	assert(not result.errors.is_empty() and result.commands.is_empty())
	assert(definition.describe(_words, "en") == "Invalid rule definition.")
	var context: EffectContext = _context()
	context.dice.append(context.dice[0])
	assert(not context.validate().is_empty())
	context = _context()
	context.dice[1].validated = false
	assert(not context.validate().is_empty())
	var keyword: KeywordDefinition = KeywordDefinition.new()
	keyword.id = &"bad"
	keyword.translations = {"en": "{amount}", "fr": "{number}"}
	assert(not keyword.validate().is_empty())
	keyword.translations = {"en": "{bad syntax}", "fr": "{bad syntax}"}
	assert(not keyword.validate().is_empty())
	var missing_words: KeywordCatalog = KeywordCatalog.new()
	missing_words.keywords = _words.keywords.duplicate()
	missing_words.keywords.erase(_words.find_keyword(&"action.mult"))
	assert(not _bloom.validate_keywords(missing_words).is_empty())
	assert(_bloom.describe(missing_words, "en") == "Invalid rule definition.")
	effect.trigger = &"unknown_event"
	effect.actions.clear()
	assert(not definition.validate_keywords(_words).is_empty())

## Templates own word order and fallback; effect data owns all numeric and rule content.
func _test_localization() -> void:
	var english: String = _bloom.describe(_words, "en")
	var french: String = _bloom.describe(_words, "fr")
	assert("this die is held" in english and "this die is not played" in english and "this die is showing 1" in english)
	assert("ce dé est conservé" in french and "ce dé est non joué" in french and "ce dé est sur 1" in french)
	assert(english != french)
	assert(_bloom.describe(_words, "fr_CA") == french)
	assert(_bloom.describe(_words, "de") == english)
	assert(_words.find_keyword(&"held").explanation("fr") != "")
	assert("[missing keyword:" in _words.render(&"not.registered"))
	assert("[missing token:" in _words.render(&"action.points"))
	var original: String = TranslationServer.get_locale()
	TranslationServer.set_locale("fr")
	assert(_bloom.describe(_words) == french)
	TranslationServer.set_locale(original)
	var keyword: KeywordDefinition = KeywordDefinition.new()
	keyword.id = &"test.order"
	keyword.translations = {"en": "{left} then {right}", "fr": "{right} après {left}"}
	var words: KeywordCatalog = KeywordCatalog.new()
	words.keywords = [keyword]
	assert(words.render(&"test.order", {"left": "A", "right": "B"}, "fr") == "B après A")


## Named constructors must be real rules, preserve isolation, and execute the advertised event.
func _test_named_classes() -> void:
	var context: EffectContext = _context()
	context.event = &"held"
	context.event_die_id = context.source_die_id
	context.dice[0].held = true
	var bonus: BonusDefinition = BonusDefinition.new(&"held_test", [
		EffectDefinition.OnHeld.new(&"own_hold",
			Conditions.All.new([Conditions.ThisDieTriggered.new(), Conditions.Held.new()]),
			[ScoreAction.Points.new(5)]
		),
	])
	assert(bonus.validate_keywords(_words).is_empty())
	assert((EffectResolver.resolve(bonus, context).commands[0] as ScoreDeltaCommand).amount == 5)
	context.event_die_id = &"die_2"
	assert(EffectResolver.resolve(bonus, context).commands.is_empty())
	context.event = &"validation"
	assert(EffectResolver.resolve(bonus, context).commands.is_empty())
	var faces: ReplaceFacesAction = ReplaceFacesAction.new([1, 1, 1, 6, 6, 6])
	assert(faces.validate().is_empty())
	assert((faces.commands(context)[0] as ReplaceFacesCommand).target_die_id == context.source_die_id)
	var first: UpgradeExamples = UpgradeExamples.new()
	var second: UpgradeExamples = UpgradeExamples.new()
	first.patient_bloom.faces[0] = 6
	(first.odd_master.effects[0].actions[0] as ScoreAction).amount.per_die = 99
	assert(second.patient_bloom.faces[0] == 1)
	assert((second.odd_master.effects[0].actions[0] as ScoreAction).amount.per_die == 20)
	assert(GameKeywords.new().keywords[0] != GameKeywords.new().keywords[0])
