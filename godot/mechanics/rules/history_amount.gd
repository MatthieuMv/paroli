extends EffectAmount
class_name HistoryAmount
## Typed snapshot formulas for persistent and per-round mechanics.

# --- Types ---

## Named formula source; authors use the concrete subclasses below.
enum Source { DIE_VALUE, MANUAL_REROLLS, PREVIOUS_VALIDATIONS, OWNER_MULT, PORTFOLIO, CRESCENDO, DISTINCT_VALUES }

## Coins equal to the owner's current value.
class DieValue:
	extends HistoryAmount

	# --- Member functions ---

	## No membership is implied; the effect condition specifies eligibility.
	func _init() -> void:
		super(Source.DIE_VALUE, 1, &"amount.die_value")

## A signed contribution per manual reroll since this die's last validation.
class ManualRerolls:
	extends HistoryAmount

	# --- Member functions ---

	## Opening and automatic rolls never enter this counter.
	func _init(coefficient_: int) -> void:
		super(Source.MANUAL_REROLLS, coefficient_, &"amount.manual_rerolls")

## A contribution per prior validation, including zero-score results.
class PreviousValidations:
	extends HistoryAmount

	# --- Member functions ---

	## The current validation is not yet counted.
	func _init(coefficient_: int) -> void:
		super(Source.PREVIOUS_VALIDATIONS, coefficient_, &"amount.previous_validations")

## Window shopper's owned persistent Mult.
class AccumulatedMult:
	extends HistoryAmount

	# --- Member functions ---

	## A newly purchased instance starts at zero.
	func _init() -> void:
		super(Source.OWNER_MULT, 1, &"amount.accumulated_mult")

## Current total sell value of all owned Jokers, including this one.
class Portfolio:
	extends HistoryAmount

	# --- Member functions ---

	## Reading sell values neither sells anything nor grants coins.
	func _init() -> void:
		super(Source.PORTFOLIO, 1, &"amount.portfolio")

## Existing Crescendo stacks plus a qualifying increase on the current validation.
class Crescendo:
	extends HistoryAmount

	# --- Member functions ---

	## Every strictly increasing own value adds fifty percentage points.
	func _init() -> void:
		super(Source.CRESCENDO, 1, &"amount.crescendo")

## Count each distinct validated value once, regardless of duplicate dice or faces.
class DistinctValues:
	extends HistoryAmount

	# --- Member functions ---

	## The coefficient scales the number of distinct values, not physical dice.
	func _init(coefficient_: int) -> void:
		super(Source.DISTINCT_VALUES, coefficient_, &"amount.distinct_values")

# --- Constants ---

## Shared stack increment used by scoring, history commitment, and authored text.
const CRESCENDO_STEP: int = 50

# --- Member variables ---

## Runtime field or formula to read.
var source: Source
## Integer scale, applied without altering history.
var coefficient: int
## Keyword for the full formula.
var phrase: StringName

# --- Member functions ---

## Concrete constructors keep implementation enum choices out of content declarations.
func _init(source_: Source = Source.DIE_VALUE, coefficient_: int = 1, phrase_: StringName = &"amount.die_value") -> void:
	source = source_
	coefficient = coefficient_
	phrase = phrase_

## Calculate against the unchanged pre-commitment snapshot.
func evaluate(context: EffectContext) -> int:
	var die: DieSnapshot = context.find_die(context.source_die_id)
	match source:
		Source.DIE_VALUE:
			return coefficient * die.value if die else 0
		Source.MANUAL_REROLLS:
			return coefficient * die.rerolls_since_validation if die else 0
		Source.PREVIOUS_VALIDATIONS:
			return coefficient * context.previous_validations
		Source.OWNER_MULT:
			return coefficient * context.owner_mult
		Source.PORTFOLIO:
			return coefficient * context.joker_sell_total
		Source.DISTINCT_VALUES:
			var values: Array[int] = []
			for selected: DieSnapshot in context.dice:
				if selected.validated and not selected.value in values:
					values.append(selected.value)
			return coefficient * values.size()
		Source.CRESCENDO:
			if not die:
				return 0
			return die.crescendo_percent + (CRESCENDO_STEP if die.previous_validated_value > 0 and die.value > die.previous_validated_value else 0)
	return 0

## Formula descriptions do not leak the current validation's resolved payout.
func describe(words: KeywordCatalog, locale: String) -> String:
	return words.render(phrase, {"amount": words.number(coefficient, locale)}, locale)

## History formulas do not use the base affine query fields.
func local_errors() -> PackedStringArray:
	return [] if source in Source.values() else ["Unknown history source"]

## Each formula owns one translated semantic phrase.
func keyword_ids() -> Array[StringName]:
	return [phrase]
