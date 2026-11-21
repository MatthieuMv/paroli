extends RefCounted
## Choices for the seeded benchmark. The policy sees current faces, equipment and allowances.

# --- Constants ---

## Three lists per route in preference order: permanent upgrades, die bonuses, jokers.
const BUILDS: Dictionary[String, String] = {
	"flexible": "rainbow even-master odd-master|opening-act first-instinct lucky-seven|pick-n-mix matchmaker nest-egg",
	"single": "lone-wolf guardian alternator|top-hat power-reserve me-time|one-man-band lazy-bones broken-record",
	"pair": "all-for-one guardian deja-vu|sock-mate copycat power-reserve|lovebirds matchmaker broken-record",
	"two_pairs": "house-builder all-for-one even-master|double-vision four-wheel-drive copycat|double-date matchmaker bench-warmers",
	"three_of_a_kind": "all-for-one relentless house-builder|peas-in-a-pod copycat loyalty-card|trio matchmaker lovebirds",
	"short_straight": "stepping-stones rainbow odd-master|shortcut borderline sandwiched|conga-line ducks-in-a-row missing-link",
	"full_house": "house-builder all-for-one relentless|couch-surfer copycat double-vision|sardine-tin matchmaker double-date",
	"long_straight": "stepping-stones rainbow even-master|finish-line borderline shortcut|road-trip missing-link ducks-in-a-row",
	"four_of_a_kind": "all-for-one relentless house-builder|four-leaf-clover copycat peas-in-a-pod|four-corners matchmaker trio",
	"five_of_a_kind": "all-for-one house-builder relentless|high-five copycat peas-in-a-pod|family-reunion matchmaker four-corners",
	"held": "guardian lone-wolf deja-vu|power-reserve me-time paid-leave|bench-warmers lazy-bones broken-record",
	"odd": "odd-master all-for-one relentless|odd-button lucky-seven copycat|odd-squad matchmaker bean-counter",
	"even": "even-master guardian house-builder|even-button lucky-seven copycat|even-squad matchmaker bean-counter",
	"ones": "jackpot lone-wolf all-for-one|one-or-nothing copycat odd-button|highs-and-lows matchmaker odd-squad",
	"sixes": "jackpot lone-wolf even-master|six-addict lucky-seven even-button|highs-and-lows even-squad matchmaker",
	"diversity": "rainbow stepping-stones odd-master|black-sheep sandwiched lucky-seven|pick-n-mix ducks-in-a-row missing-link",
	"sum15": "crescendo rainbow house-builder|lucky-seven sandwiched black-sheep|bean-counter pick-n-mix matchmaker",
	"save_rolls": "deja-vu alternator lone-wolf|first-instinct echo opening-act|broken-record snowball pick-n-mix",
	"spend_rolls": "relentless house-builder all-for-one|loyalty-card side-hustle copycat|last-straw do-over matchmaker",
	"repeat": "deja-vu lone-wolf all-for-one|echo copycat first-instinct|broken-record matchmaker snowball",
	"switch": "alternator crescendo rainbow|opening-act grand-finale lucky-seven|plot-twist pick-n-mix snowball",
	"tempo": "crescendo alternator relentless|grand-finale opening-act loyalty-card|snowball overtime last-straw",
	"economy": "golden-touch relentless guardian|payday paid-leave side-hustle|stonks nest-egg roulette",
	"refresh": "golden-touch relentless house-builder|side-hustle payday paid-leave|roulette nest-egg stonks",
	"portfolio": "golden-touch guardian lone-wolf|paid-leave payday side-hustle|nest-egg stonks roulette",
}
## Broadly useful alternatives when no theme piece is on offer.
const GENERAL: String = "rainbow even-master odd-master golden-touch stepping-stones opening-act first-instinct grand-finale lucky-seven black-sheep even-button odd-button nest-egg pick-n-mix matchmaker overtime even-squad odd-squad missing-link"

# --- Member variables ---

## Name of this hand or theme.
var route: String
## Preferred order across all three disjoint families.
var favorites: PackedStringArray
## One primary piece from each family in supplied runs.
var core: PackedStringArray
## In the five-match risk experiment, spend a remaining roll to complete an attainable fifth match.
var chase_four: bool = false
## Current choice and the best same-board alternative to the signature category.
var choice: Array[StringName] = []
var score: float = 0.0
var fallback_score: float = 0.0
## Base-hand score forgone by the chosen selection, under current recognition rules.
var plain_score_forgone: float = 0.0
## Individually recognized selections, cached by ordered faces, positions and gap permission.
var _hands: Dictionary[int, CombinationRecognizer.Result] = {}
## All nonempty selections of the five permanent dice, in stable run order.
var _selections: Array[PackedInt32Array] = []
## Stable IDs for the corresponding selections.
var _ids: Array[PackedStringArray] = []
## Used by all policies when their preferred purchases are unavailable.
var _general: PackedStringArray = GENERAL.split(" ")

# --- Member functions ---

## Prepare the route's fixed preferences and 31 legal choices once per batch.
func _init(route_: String) -> void:
	route = route_
	for family: String in BUILDS[route].split("|"):
		var items: PackedStringArray = family.split(" ")
		core.append(items[0])
		favorites.append_array(items)
	for mask: int in range(1, 32):
		var selection: PackedInt32Array = []
		var ids: PackedStringArray = []
		for index: int in 5:
			if mask & (1 << index):
				selection.append(index)
				ids.append("die_%d" % (index + 1))
		_selections.append(selection)
		_ids.append(ids)

## Buy for the chosen route first. Preserve some cash for future stocks over off-theme filler.
func priority(id: StringName) -> int:
	var rank: int = favorites.find(id)
	if rank >= 0:
		return 100 - rank
	rank = _general.find(id)
	return 50 - rank if rank >= 0 else 1

## Evaluate an authored condition and amount on the visible board; the committed play is checked against it.
func choose(run: MechanicsRun) -> void:
	var context: EffectContext = EffectContext.new()
	context.previous_validations = run.previous_validations
	context.previous_combination = run.previous_combination
	context.validations_remaining = run.validations_remaining
	context.rerolls_remaining = run.rerolls_remaining
	var gaps: int = 0
	for item: OwnedDefinition in run.owned:
		if item.definition is JokerDefinition:
			context.joker_sell_total += item.sell_value()
		for effect: EffectDefinition in item.definition.effects:
			if effect.trigger == &"recognition":
				for action: EffectAction in effect.actions:
					if action is RuntimeAction.MissingLink:
						gaps = 1
	for die: RunDie in run.dice:
		context.dice.append(die.snapshot(false, false))
	var best: float = -1.0
	var best_plain: float = 0.0
	var chosen_plain: float = 0.0
	fallback_score = 0.0
	var remaining: float = run.round_target - run.round_score
	for index: int in _selections.size():
		var selection: PackedInt32Array = _selections[index]
		var key: int = (index + 1) * 2 + gaps
		for position: int in selection:
			key = (key << 3) + run.dice[position].value
		# Position masks have different lengths. Reserve a separate low-bit mask for their identity.
		key = (key << 5) + index
		var hand: CombinationRecognizer.Result = _hands.get(key)
		if not hand:
			var selected_dice: Array[DieSnapshot] = []
			for position: int in selection:
				selected_dice.append(context.dice[position])
			hand = CombinationRecognizer.recognize(selected_dice, gaps)
			_hands[key] = hand
		for position: int in run.dice.size():
			var die: DieSnapshot = context.dice[position]
			die.validated = position in selection
			die.held = not die.validated
			die.combination_member = die.id in hand.members
		context.combination = hand.category
		var values: Vector3 = Vector3(CombinationScores.base_points(hand.category) + hand.value_sum, CombinationScores.base_mult(hand.category), 0)
		var plain: float = values.x * values.y
		best_plain = maxf(best_plain, plain)
		var income: int = 0
		for item: OwnedDefinition in run.owned:
			context.source_die_id = item.die_id
			context.owner_points = item.accumulated_points
			context.owner_mult = item.accumulated_mult
			for effect: EffectDefinition in item.definition.effects:
				if effect.trigger != &"validation" or (effect.condition and not effect.condition.matches(context)):
					continue
				for action: EffectAction in effect.actions:
					if action is ScoreAction:
						var delta: ScoreAction = action as ScoreAction
						values[delta.channel] += delta.amount.evaluate(context)
					elif action is RuntimeAction and (action as RuntimeAction).kind == RuntimeDeltaCommand.Kind.COINS:
						income += (action as RuntimeAction).amount.evaluate(context)
		var points: float = values.x * values.y * (1.0 + values.z / 100.0)
		var focus: bool = String(hand.category) == route
		if not focus:
			fallback_score = maxf(fallback_score, points)
		var utility: float = minf(points, remaining) * (1.2 if focus else 1.0)
		# Give a clearing play a premium worth twice the remaining target.
		utility += remaining * 2.0 if points >= remaining else 0.0
		utility += income * (4.0 if route in ["economy", "refresh", "portfolio"] else 0.1)
		if utility > best:
			best = utility
			chosen_plain = plain
			score = points
			choice.assign(_ids[index])
	plain_score_forgone = best_plain - chosen_plain

## Choose which visible dice to reroll. Preserve matches or straight members toward the desired hand.
func reroll(run: MechanicsRun) -> Array[StringName]:
	var remaining: float = run.round_target - run.round_score
	if run.rerolls_remaining == 0 or score >= remaining:
		return []
	if chase_four:
		var matches: PackedInt32Array = [0, 0, 0, 0, 0, 0, 0]
		for die: RunDie in run.dice:
			matches[die.value] += 1
		var fourth: int = matches.find(4)
		if fourth > 0:
			for die: RunDie in run.dice:
				if die.value != fourth and fourth in die.faces:
					return [die.id]
	var spend: bool = route in ["spend_rolls", "refresh"]
	var pace: float = remaining / run.validations_remaining
	if not spend and score >= pace * (0.6 if route == "save_rolls" else 1.0):
		return []
	var counts: PackedInt32Array = [0, 0, 0, 0, 0, 0, 0]
	for die: RunDie in run.dice:
		counts[die.value] += 1
	var faces: Array[int] = [1, 2, 3, 4, 5, 6]
	faces.sort_custom(func(a: int, b: int) -> bool: return counts[a] > counts[b] or (counts[a] == counts[b] and a > b))
	var keep: Array[StringName] = []
	var sequence: bool = route in ["short_straight", "long_straight", "diversity"] or (route == "flexible" and counts[faces[0]] <= 1)
	if sequence:
		var length: int = 4 if route == "short_straight" else 5
		var best_count: int = -1
		for start: int in range(1, 8 - length):
			var kept: Array[StringName] = []
			var seen: Array[int] = []
			for die: RunDie in run.dice:
				if die.value >= start and die.value < start + length and die.value not in seen:
					kept.append(die.id)
					seen.append(die.value)
			if kept.size() > best_count:
				best_count = kept.size()
				keep = kept
	else:
		var anchor: int = 1 if route == "ones" else (6 if route == "sixes" else faces[0])
		var split: bool = route in ["two_pairs", "full_house"]
		var max_matches: int = 2 if route == "two_pairs" else (3 if route == "full_house" else 5)
		var first_count: int = 0
		var second_count: int = 0
		for die: RunDie in run.dice:
			if die.value == anchor and first_count < max_matches:
				first_count += 1
				keep.append(die.id)
			elif split and die.value == faces[1] and second_count < 2:
				second_count += 1
				keep.append(die.id)
	var rolled: Array[StringName] = []
	for die: RunDie in run.dice:
		if die.id not in keep:
			rolled.append(die.id)
	return rolled
