extends RefCounted
class_name ValidationConditions
## Named predicates for the complete EFFECTS.md catalog; all read committed snapshots.

# --- Types ---

## Shared translation contract for fixed predicates.
class Predicate:
	extends EffectCondition

	# --- Member variables ---

	## Keyword-owned phrase describing this exact predicate.
	var phrase: StringName

	# --- Member functions ---

	## Bind a semantic phrase without embedding item-specific prose.
	func _init(phrase_: StringName) -> void:
		phrase = phrase_

	## Concrete named subclasses provide their own pure matches implementation.
	func local_errors() -> PackedStringArray:
		return []

	## Translate the predicate independently of the item that uses it.
	func describe(words: KeywordCatalog, locale: String) -> String:
		return words.render(phrase, {}, locale)

	## Validate the semantic translation dependency.
	func keyword_ids() -> Array[StringName]:
		return [phrase]

## At least one distinct validated partner complements the owner's value to seven.
class SevenPartner:
	extends Predicate

	# --- Member functions ---

	## One match is enough; duplicate partners do not multiply activation.
	func _init() -> void:
		super(&"condition.seven_partner")

	## Always compare actual values and distinct identities.
	func matches(context: EffectContext) -> bool:
		var source: DieSnapshot = context.find_die(context.source_die_id)
		if source:
			for die: DieSnapshot in context.dice:
				if die.validated and die.id != source.id and die.value + source.value == 7:
					return true
		return false

## Other validated dice must provide both adjacent actual numeric values.
class Neighbours:
	extends Predicate

	# --- Member functions ---

	## Missing link never changes this numeric adjacency test.
	func _init() -> void:
		super(&"condition.neighbours")

	## Distinct lower and upper values inherently require distinct physical dice.
	func matches(context: EffectContext) -> bool:
		var source: DieSnapshot = context.find_die(context.source_die_id)
		if not source:
			return false
		var lower: bool = false
		var upper: bool = false
		for die: DieSnapshot in context.dice:
			if die.validated and die.id != source.id:
				lower = lower or die.value == source.value - 1
				upper = upper or die.value == source.value + 1
		return lower and upper

## The owner is an endpoint of the actual recognized straight members.
class StraightEndpoint:
	extends Predicate

	# --- Member functions ---

	## Recognition membership, not all selected values, determines the endpoints.
	func _init() -> void:
		super(&"condition.straight_endpoint")

	## Exact recognized categories exclude straights contained in higher categories.
	func matches(context: EffectContext) -> bool:
		var source: DieSnapshot = context.find_die(context.source_die_id)
		if not source or not source.combination_member or context.combination not in [&"short_straight", &"long_straight"]:
			return false
		var lower: bool = false
		var upper: bool = false
		for die: DieSnapshot in context.dice:
			if die.combination_member:
				lower = lower or die.value < source.value
				upper = upper or die.value > source.value
		return not lower or not upper

## Exact sum of current validated values, each counted once.
class SumEquals:
	extends Predicate

	# --- Member variables ---

	## Required numeric total.
	var total: int

	# --- Member functions ---

	## The same number is used for evaluation and localized text.
	func _init(total_: int) -> void:
		super(&"condition.sum")
		total = total_

	## Excluded dice and repeated physical face positions never enter the sum.
	func matches(context: EffectContext) -> bool:
		var sum: int = 0
		for die: DieSnapshot in context.dice:
			if die.validated:
				sum += die.value
		return sum == total

	## Translate the authored total rather than a snapshot-specific payout.
	func describe(words: KeywordCatalog, locale: String) -> String:
		return words.render(phrase, {"total": words.number(total, locale)}, locale)

## No manual reroll of this die at any time in the current round.
class FirstInstinct:
	extends Predicate

	# --- Member functions ---

	## Validation never resets this eligibility.
	func _init() -> void:
		super(&"condition.first_instinct")

	## Absent source dice are ineligible.
	func matches(context: EffectContext) -> bool:
		var source: DieSnapshot = context.find_die(context.source_die_id)
		return source != null and source.manual_rerolls_round == 0

## This die matches its own previous validation, not the previous global validation.
class SameDieValue:
	extends Predicate

	# --- Member functions ---

	## A first validation has no prior value and gives no reward.
	func _init() -> void:
		super(&"condition.same_die_value")

	## History is updated only after every effect has evaluated.
	func matches(context: EffectContext) -> bool:
		var source: DieSnapshot = context.find_die(context.source_die_id)
		return source != null and source.previous_validated_value > 0 and source.value == source.previous_validated_value

## Compare the recognized category with the immediately previous validation.
class PreviousCombination:
	extends Predicate

	# --- Member variables ---

	## True repeats; false changes. Neither matches absent history.
	var same: bool

	# --- Member functions ---

	## Habit and Variety differ only in this explicit comparison.
	func _init(same_: bool) -> void:
		super(&"condition.same_combination" if same_ else &"condition.different_combination")
		same = same_

	## A zero-point previous validation still supplies history.
	func matches(context: EffectContext) -> bool:
		return context.previous_combination != &"" and (context.previous_combination == context.combination) == same

## A rolled batch includes this die and is a qualifying reroll.
class IncomeReroll:
	extends Predicate

	# --- Member functions ---

	## Income is earned only when the player manually rolls this die.
	func _init() -> void:
		super(&"condition.income_reroll")

	## Opening, automatic post-play, and cosmetic rolls never pay.
	func matches(context: EffectContext) -> bool:
		return context.source_die_id in context.rolled_ids and context.roll_kind == EffectContext.RollKind.MANUAL

## No manual rerolls remain before the current validation.
class LastChance:
	extends Predicate

	# --- Member functions ---

	## Extra reroll allowances are already reflected in the context.
	func _init() -> void:
		super(&"condition.last_chance")

	## This is an allowance test, not the number of rerolls performed.
	func matches(context: EffectContext) -> bool:
		return context.rerolls_remaining == 0

## The first committed validation this round.
class OpeningAct:
	extends Predicate

	# --- Member functions ---

	## Count prior validations including zero-point results.
	func _init() -> void:
		super(&"condition.opening_act")

	## Starting a new round resets the count.
	func matches(context: EffectContext) -> bool:
		return context.previous_validations == 0

## Exactly one validation remains before commitment.
class GrandFinale:
	extends Predicate

	# --- Member functions ---

	## Extra time naturally delays this condition.
	func _init() -> void:
		super(&"condition.grand_finale")

	## Do not inspect the allowance after it has been decremented.
	func matches(context: EffectContext) -> bool:
		return context.validations_remaining == 1

## Round completion succeeded, including a boss round.
class SuccessfulRound:
	extends Predicate

	# --- Member functions ---

	## Failed rounds never grant sell-value growth.
	func _init() -> void:
		super(&"condition.successful_round")

	## Runtime event identity prevents duplicate success processing.
	func matches(context: EffectContext) -> bool:
		return context.round_succeeded

## One completed paid whole-shop refresh.
class PaidRefresh:
	extends Predicate

	# --- Member functions ---

	## Growth counts refreshes, not coins spent.
	func _init() -> void:
		super(&"condition.paid_refresh")

	## Free entry, purchases, and failed refreshes are not this event.
	func matches(context: EffectContext) -> bool:
		return context.refresh_cost > 0

## The owning die differs from its own previous validated value this round.
class DifferentDieValue:
	extends Predicate

	# --- Member functions ---

	## The first validation is ineligible rather than treating absence as a different value.
	func _init() -> void:
		super(&"condition.different_die_value")

	## Other dice's intervening validations never replace this die's history.
	func matches(context: EffectContext) -> bool:
		var source: DieSnapshot = context.find_die(context.source_die_id)
		return source != null and source.previous_validated_value > 0 and source.value != source.previous_validated_value
