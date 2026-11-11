extends RefCounted
class_name EffectsCatalog
## Complete class-authored catalog from docs/EFFECTS.md; numbers are provisional balance.

# --- Member variables ---

## Permanent face-changing definitions, in document order.
var upgrades: Array[UpgradeDefinition] = []
## Unique die-slot bonus definitions.
var bonuses: Array[BonusDefinition] = []
## Unique global definitions; a run owns at most four.
var jokers: Array[JokerDefinition] = []

# --- Member functions ---

## Declare each behavior using named classes; no serialized rule graphs.
func _init() -> void:
	# Upgrades
	upgrades = [
		# All for one
		UpgradeDefinition.new(&"all_for_one", [1, 1, 1, 3, 3, 3], [
			EffectDefinition.OnValidated.new(&"reward", Conditions.AtLeast.new(1, DieQuery.OtherMatching.new()), [ScoreAction.MultPercentPerDie.new(25, DieQuery.OtherMatching.new())]),
		], &"Cherry", &"hearts"),
		# House builder
		UpgradeDefinition.new(&"house_builder", [2, 2, 3, 3, 3, 3], [
			EffectDefinition.OnValidated.new(&"reward", Conditions.All.new([Conditions.Member.new(), Conditions.Combination.new([&"full_house"])]), [ScoreAction.MultPercent.new(50)]),
		], &"Cocoa", &"ribbons"),
		# Jackpot
		UpgradeDefinition.new(&"jackpot", [1, 1, 1, 1, 1, 6], [
			EffectDefinition.OnValidated.new(&"reward", Conditions.Showing.new(6), [ScoreAction.MultPercent.new(100)]),
		], &"Butter", &"starburst"),
		# Odd master
		UpgradeDefinition.new(&"odd_master", [1, 1, 3, 3, 5, 5], [
			EffectDefinition.OnValidated.new(&"reward", null, [ScoreAction.MultPercentPerDie.new(20, DieQuery.Validated.new(DieQuery.Parity.ODD))]),
		], &"Pistachio", &"flowers"),
		# Even master
		UpgradeDefinition.new(&"even_master", [2, 2, 4, 4, 6, 6], [
			EffectDefinition.OnValidated.new(&"reward", null, [ScoreAction.MultPercentPerDie.new(20, DieQuery.Validated.new(DieQuery.Parity.EVEN))]),
		], &"Mint", &"petals"),
		# Rainbow
		UpgradeDefinition.new(&"rainbow", [1, 2, 3, 4, 5, 5], [
			EffectDefinition.OnValidated.new(&"reward", null, [ScoreAction.Calculated.new(ScoreDeltaCommand.Channel.MULT_PERCENT, HistoryAmount.DistinctValues.new(20))]),
		], &"Bubblegum", &"confetti"),
		# Lone wolf
		UpgradeDefinition.new(&"lone_wolf", [1, 1, 1, 6, 6, 6], [
			EffectDefinition.OnValidated.new(&"reward", null, [ScoreAction.MultPercentPerDie.new(25, DieQuery.Excluded.new())]),
		], &"Periwinkle", &"crescents"),
		# Guardian
		UpgradeDefinition.new(&"guardian", [1, 1, 2, 2, 6, 6], [
			EffectDefinition.OnValidation.new(&"reward", Conditions.All.new([Conditions.Held.new(), Conditions.NotValidated.new(), Conditions.AtLeast.new(1, DieQuery.OtherMatching.new())]), [ScoreAction.MultPercent.new(50)]),
		], &"Sky", &"bubbles"),
		# Golden touch
		UpgradeDefinition.new(&"golden_touch", [1, 2, 2, 3, 3, 6], [
			EffectDefinition.OnValidated.new(&"reward", Conditions.Member.new(), [RuntimeAction.CoinsFromDie.new()]),
		], &"Honey", &"diamonds"),
		# Stepping stones
		UpgradeDefinition.new(&"stepping_stones", [2, 3, 3, 4, 4, 5], [
			EffectDefinition.OnValidated.new(&"short_straight", Conditions.All.new([Conditions.Member.new(), Conditions.Combination.new([&"short_straight"])]), [ScoreAction.MultPercent.new(50)]),
			EffectDefinition.OnValidated.new(&"long_straight", Conditions.All.new([Conditions.Member.new(), Conditions.Combination.new([&"long_straight"])]), [ScoreAction.MultPercent.new(75)]),
		], &"Peach", &"feathers"),
		# Relentless
		UpgradeDefinition.new(&"relentless", [1, 3, 3, 3, 3, 6], [
			EffectDefinition.OnValidated.new(&"reward", null, [ScoreAction.Calculated.new(ScoreDeltaCommand.Channel.MULT_PERCENT, HistoryAmount.ManualRerolls.new(25))]),
		], &"Tangerine", &"fire"),
		# Crescendo
		UpgradeDefinition.new(&"crescendo", [2, 2, 3, 3, 4, 4], [
			EffectDefinition.OnValidated.new(&"reward", null, [ScoreAction.Calculated.new(ScoreDeltaCommand.Channel.MULT_PERCENT, HistoryAmount.Crescendo.new())]),
		], &"Lilac", &"notes"),
		# Déjà vu
		UpgradeDefinition.new(&"deja_vu", [2, 2, 2, 5, 5, 5], [
			EffectDefinition.OnValidated.new(&"reward", ValidationConditions.SameDieValue.new(), [ScoreAction.MultPercent.new(50)]),
		], &"Lavender", &"orbit"),
		# Alternator
		UpgradeDefinition.new(&"alternator", [1, 1, 1, 6, 6, 6], [
			EffectDefinition.OnValidated.new(&"reward", ValidationConditions.DifferentDieValue.new(), [ScoreAction.MultPercent.new(50)]),
		], &"Lagoon", &"bolts"),
	]
	# Bonuses
	bonuses = [
		# Top Hat
		BonusDefinition.new(&"solo_talent", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.All.new([Conditions.Member.new(), Conditions.Combination.new([&"single"])]), [ScoreAction.Mult.new(6)]),
		]),
		# Sock Mate
		BonusDefinition.new(&"pair_partner", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.All.new([Conditions.Member.new(), Conditions.Combination.new([&"pair"])]), [ScoreAction.Mult.new(6)]),
		]),
		# Double Vision
		BonusDefinition.new(&"double_partner", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.All.new([Conditions.Member.new(), Conditions.Combination.new([&"two_pairs"])]), [ScoreAction.Mult.new(8)]),
		]),
		# Peas in a Pod
		BonusDefinition.new(&"triple_bond", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.All.new([Conditions.Member.new(), Conditions.Combination.new([&"three_of_a_kind"])]), [ScoreAction.Mult.new(10)]),
		]),
		# Shortcut
		BonusDefinition.new(&"sure_footing", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.All.new([Conditions.Member.new(), Conditions.Combination.new([&"short_straight"])]), [ScoreAction.Mult.new(10)]),
		]),
		# Couch Surfer
		BonusDefinition.new(&"house_guest", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.All.new([Conditions.Member.new(), Conditions.Combination.new([&"full_house"])]), [ScoreAction.Mult.new(12)]),
		]),
		# Finish Line
		BonusDefinition.new(&"last_mile", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.All.new([Conditions.Member.new(), Conditions.Combination.new([&"long_straight"])]), [ScoreAction.Mult.new(14)]),
		]),
		# Four-leaf Clover
		BonusDefinition.new(&"four_together", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.All.new([Conditions.Member.new(), Conditions.Combination.new([&"four_of_a_kind"])]), [ScoreAction.Mult.new(16)]),
		]),
		# High Five
		BonusDefinition.new(&"family_bond", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.All.new([Conditions.Member.new(), Conditions.Combination.new([&"five_of_a_kind"])]), [ScoreAction.Mult.new(20)]),
		]),
		# Copycat
		BonusDefinition.new(&"family_spirit", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.AtLeast.new(1, DieQuery.OtherMatching.new()), [ScoreAction.MultPerDie.new(2, DieQuery.OtherMatching.new())]),
		]),
		# One or Nothing
		BonusDefinition.new(&"one_or_nothing", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.Showing.new(1), [ScoreAction.Mult.new(4)]),
		]),
		# Six Addict
		BonusDefinition.new(&"six_addict", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.Showing.new(6), [ScoreAction.Mult.new(4)]),
		]),
		# Odd Button
		BonusDefinition.new(&"odd_charm", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.Odd.new(), [ScoreAction.Mult.new(2)]),
		]),
		# Even Button
		BonusDefinition.new(&"even_charm", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.Even.new(), [ScoreAction.Mult.new(2)]),
		]),
		# Lucky Seven
		BonusDefinition.new(&"lucky_seven", [
			EffectDefinition.OnValidated.new(&"reward", ValidationConditions.SevenPartner.new(), [ScoreAction.Mult.new(4)]),
		]),
		# Black Sheep
		BonusDefinition.new(&"unique", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.All.new([Conditions.AtLeast.new(3, DieQuery.Validated.new()), Conditions.Exactly.new(0, DieQuery.OtherMatching.new())]), [ScoreAction.Mult.new(4)]),
		]),
		# Me Time
		BonusDefinition.new(&"small_circle", [
			EffectDefinition.OnValidated.new(&"reward", null, [ScoreAction.MultPerDie.new(1, DieQuery.Excluded.new())]),
		]),
		# Four-wheel Drive
		BonusDefinition.new(&"squad", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.All.new([Conditions.Exactly.new(4, DieQuery.Validated.new()), Conditions.Member.new(), Conditions.Combination.new([&"two_pairs", &"four_of_a_kind"])]), [ScoreAction.Mult.new(8)]),
		]),
		# Power Reserve
		BonusDefinition.new(&"quiet_strength", [
			EffectDefinition.OnValidation.new(&"reward", Conditions.All.new([Conditions.Held.new(), Conditions.NotValidated.new()]), [ScoreAction.Mult.new(2)]),
		]),
		# Payday
		BonusDefinition.new(&"pocket_money", [
			EffectDefinition.OnValidated.new(&"reward", Conditions.Member.new(), [RuntimeAction.Coins.new(2)]),
		]),
		# Paid Leave
		BonusDefinition.new(&"paid_leave", [
			EffectDefinition.OnValidation.new(&"reward", Conditions.All.new([Conditions.Held.new(), Conditions.NotValidated.new()]), [RuntimeAction.Coins.new(1)]),
		]),
		# Side Hustle
		BonusDefinition.new(&"rolling_income", [
			EffectDefinition.OnRoll.new(&"reward", ValidationConditions.IncomeReroll.new(), [RuntimeAction.Coins.new(1)]),
		]),
		# Borderline
		BonusDefinition.new(&"extremities", [
			EffectDefinition.OnValidated.new(&"reward", ValidationConditions.StraightEndpoint.new(), [ScoreAction.Mult.new(12)]),
		]),
		# Sandwiched
		BonusDefinition.new(&"neighbours", [
			EffectDefinition.OnValidated.new(&"reward", ValidationConditions.Neighbours.new(), [ScoreAction.Mult.new(4)]),
		]),
		# First Instinct
		BonusDefinition.new(&"first_instinct", [
			EffectDefinition.OnValidated.new(&"reward", ValidationConditions.FirstInstinct.new(), [ScoreAction.Mult.new(4)]),
		]),
		# Loyalty Card
		BonusDefinition.new(&"persistence", [
			EffectDefinition.OnValidated.new(&"reward", null, [ScoreAction.Calculated.new(ScoreDeltaCommand.Channel.MULT, HistoryAmount.ManualRerolls.new(3))]),
		]),
		# Opening Act
		BonusDefinition.new(&"opening_act", [
			EffectDefinition.OnValidated.new(&"reward", ValidationConditions.OpeningAct.new(), [ScoreAction.Mult.new(8)]),
		]),
		# Grand Finale
		BonusDefinition.new(&"grand_finale", [
			EffectDefinition.OnValidated.new(&"reward", ValidationConditions.GrandFinale.new(), [ScoreAction.Mult.new(12)]),
		]),
		# Echo
		BonusDefinition.new(&"echo", [
			EffectDefinition.OnValidated.new(&"reward", ValidationConditions.SameDieValue.new(), [ScoreAction.Mult.new(8)]),
		]),
	]
	# Jokers
	jokers = [
		# One-man Band
		JokerDefinition.new(&"solo_act", [
			EffectDefinition.OnValidation.new(&"reward", Conditions.Combination.new([&"single"]), [ScoreAction.Points.new(30)]),
		]),
		# Lovebirds
		JokerDefinition.new(&"better_together", [
			EffectDefinition.OnValidation.new(&"reward", Conditions.Combination.new([&"pair"]), [ScoreAction.Points.new(40)]),
		]),
		# Double Date
		JokerDefinition.new(&"double_date", [
			EffectDefinition.OnValidation.new(&"reward", Conditions.Combination.new([&"two_pairs"]), [ScoreAction.Points.new(60)]),
		]),
		# Trio
		JokerDefinition.new(&"three_company", [
			EffectDefinition.OnValidation.new(&"reward", Conditions.Combination.new([&"three_of_a_kind"]), [ScoreAction.Points.new(80)]),
		]),
		# Conga Line
		JokerDefinition.new(&"short_journey", [
			EffectDefinition.OnValidation.new(&"reward", Conditions.Combination.new([&"short_straight"]), [ScoreAction.Points.new(100)]),
		]),
		# Sardine Tin
		JokerDefinition.new(&"open_house", [
			EffectDefinition.OnValidation.new(&"reward", Conditions.Combination.new([&"full_house"]), [ScoreAction.Points.new(120)]),
		]),
		# Road Trip
		JokerDefinition.new(&"long_journey", [
			EffectDefinition.OnValidation.new(&"reward", Conditions.Combination.new([&"long_straight"]), [ScoreAction.Points.new(140)]),
		]),
		# Four Corners
		JokerDefinition.new(&"four_corners", [
			EffectDefinition.OnValidation.new(&"reward", Conditions.Combination.new([&"four_of_a_kind"]), [ScoreAction.Points.new(160)]),
		]),
		# Family Reunion
		JokerDefinition.new(&"family_reunion", [
			EffectDefinition.OnValidation.new(&"reward", Conditions.Combination.new([&"five_of_a_kind"]), [ScoreAction.Points.new(200)]),
		]),
		# Matchmaker
		JokerDefinition.new(&"match_master", [
			EffectDefinition.OnValidation.new(&"reward", Conditions.Combination.new([&"pair", &"two_pairs", &"three_of_a_kind", &"full_house", &"four_of_a_kind", &"five_of_a_kind"]), [ScoreAction.PointsPerDie.new(15, DieQuery.Members.new())]),
		]),
		# Highs and Lows
		JokerDefinition.new(&"bipolarity", [
			EffectDefinition.OnValidation.new(&"reward", null, [ScoreAction.PointsPerDie.new(15, DieQuery.ValidatedValues.new([1, 6]))]),
		]),
		# Bean Counter
		JokerDefinition.new(&"mathmind", [
			EffectDefinition.OnValidation.new(&"reward", ValidationConditions.SumEquals.new(15), [ScoreAction.Points.new(100)]),
		]),
		# Odd Squad
		JokerDefinition.new(&"odd_squad", [
			EffectDefinition.OnValidation.new(&"reward", null, [ScoreAction.PointsPerDie.new(10, DieQuery.Validated.new(DieQuery.Parity.ODD))]),
		]),
		# Even Squad
		JokerDefinition.new(&"even_squad", [
			EffectDefinition.OnValidation.new(&"reward", null, [ScoreAction.PointsPerDie.new(10, DieQuery.Validated.new(DieQuery.Parity.EVEN))]),
		]),
		# Pick ’n’ Mix
		JokerDefinition.new(&"variety_show", [
			EffectDefinition.OnValidation.new(&"reward", null, [ScoreAction.Calculated.new(ScoreDeltaCommand.Channel.POINTS, HistoryAmount.DistinctValues.new(10))]),
		]),
		# Lazy Bones
		JokerDefinition.new(&"less_is_more", [
			EffectDefinition.OnValidation.new(&"reward", null, [ScoreAction.PointsPerDie.new(5, DieQuery.Excluded.new())]),
		]),
		# Bench Warmers
		JokerDefinition.new(&"backup", [
			EffectDefinition.OnValidation.new(&"reward", null, [ScoreAction.PointsPerDie.new(15, DieQuery.HeldMatching.new())]),
		]),
		# Stonks
		JokerDefinition.new(&"stonks", [
			EffectDefinition.OnRoundEnd.new(&"reward", ValidationConditions.SuccessfulRound.new(), [RuntimeAction.SellValue.new(1)]),
		]),
		# Roulette
		JokerDefinition.new(&"window_shopper", [
			EffectDefinition.OnShopRefresh.new(&"refresh_growth", ValidationConditions.PaidRefresh.new(), [RuntimeAction.AccumulateMult.new(1)]),
			EffectDefinition.OnValidation.new(&"accumulated_mult", null, [ScoreAction.Calculated.new(ScoreDeltaCommand.Channel.MULT, HistoryAmount.AccumulatedMult.new())]),
		]),
		# Nest Egg
		JokerDefinition.new(&"portfolio", [
			EffectDefinition.OnValidation.new(&"reward", null, [ScoreAction.Calculated.new(ScoreDeltaCommand.Channel.MULT, HistoryAmount.Portfolio.new())]),
		]),
		# Ducks in a Row
		JokerDefinition.new(&"alignment", [
			EffectDefinition.OnValidation.new(&"reward", Conditions.Combination.new([&"short_straight", &"long_straight"]), [ScoreAction.PointsPerDie.new(15, DieQuery.Members.new())]),
		]),
		# Missing Link
		JokerDefinition.new(&"missing_link", [
			EffectDefinition.BeforeRecognition.new(&"straight_gap", [RuntimeAction.MissingLink.new()]),
		]),
		# Last Straw
		JokerDefinition.new(&"last_chance", [
			EffectDefinition.OnValidation.new(&"reward", ValidationConditions.LastChance.new(), [ScoreAction.Points.new(60)]),
		]),
		# Overtime
		JokerDefinition.new(&"extra_time", [
			EffectDefinition.OnRoundStart.new(&"reward", null, [RuntimeAction.Validations.new(1)]),
		]),
		# Do-over
		JokerDefinition.new(&"second_chance", [
			EffectDefinition.OnRoundStart.new(&"reward", null, [RuntimeAction.Rerolls.new(1)]),
		]),
		# Snowball
		JokerDefinition.new(&"momentum", [
			EffectDefinition.OnValidation.new(&"reward", null, [ScoreAction.Calculated.new(ScoreDeltaCommand.Channel.POINTS, HistoryAmount.PreviousValidations.new(25))]),
		]),
		# Broken Record
		JokerDefinition.new(&"habit", [
			EffectDefinition.OnValidation.new(&"reward", ValidationConditions.PreviousCombination.new(true), [ScoreAction.Points.new(50)]),
		]),
		# Plot Twist
		JokerDefinition.new(&"variety", [
			EffectDefinition.OnValidation.new(&"reward", ValidationConditions.PreviousCombination.new(false), [ScoreAction.Points.new(50)]),
		]),
	]
	var descriptions: Dictionary[StringName, AuthoredDescription] = DescriptionCatalog.create()
	for definition: BuildDefinition in all_definitions():
		definition.description = descriptions.get(definition.id)
		definition.name_keyword = StringName("name." + String(definition.id))

## Return typed base references for validation, glossary/UI enumeration, and coverage tests.
func all_definitions() -> Array[BuildDefinition]:
	var result: Array[BuildDefinition] = []
	for upgrade: UpgradeDefinition in upgrades:
		result.append(upgrade)
	for bonus: BonusDefinition in bonuses:
		result.append(bonus)
	for joker: JokerDefinition in jokers:
		result.append(joker)
	return result

## Typed lookup keeps content callers away from untyped dictionaries.
func upgrade(id: StringName) -> UpgradeDefinition:
	for definition: UpgradeDefinition in upgrades:
		if definition.id == id:
			return definition
	return null

## Look up a unique bonus by its stable untranslated identity.
func bonus(id: StringName) -> BonusDefinition:
	for definition: BonusDefinition in bonuses:
		if definition.id == id:
			return definition
	return null

## Look up a global Joker definition without constructing a runtime owner.
func joker(id: StringName) -> JokerDefinition:
	for definition: JokerDefinition in jokers:
		if definition.id == id:
			return definition
	return null


## Verify production artwork without imposing presentation requirements on standalone rule fixtures.
func artwork_errors() -> PackedStringArray:
	var errors: PackedStringArray = []
	for definition: BuildDefinition in all_definitions():
		if definition is IllustratedDefinition:
			errors.append_array((definition as IllustratedDefinition).artwork_errors())
	return errors
