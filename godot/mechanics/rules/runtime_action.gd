extends EffectAction
class_name RuntimeAction
## Named economy, allowance, and recognition actions; never mutate state during planning.

# --- Types ---

## Earn a fixed coin amount.
class Coins:
	extends RuntimeAction

	# --- Member functions ---

	## Coins are granted once per matching effect activation.
	func _init(value: int) -> void:
		super(RuntimeDeltaCommand.Kind.COINS, &"action.coins", value)

## Earn coins equal to the current die value.
class CoinsFromDie:
	extends RuntimeAction

	# --- Member functions ---

	## Eligibility remains the effect's explicit condition.
	func _init() -> void:
		super(RuntimeDeltaCommand.Kind.COINS, &"action.coins", 0)
		amount = HistoryAmount.DieValue.new()

## Increase this owned Joker's eventual resale value without granting coins.
class SellValue:
	extends RuntimeAction

	# --- Member functions ---

	## Growth stays with the instance until it is sold.
	func _init(value: int) -> void:
		super(RuntimeDeltaCommand.Kind.SELL_VALUE, &"action.sell_value", value)

## Increase the owned Joker's persistent Mult for future validations.
class AccumulateMult:
	extends RuntimeAction

	# --- Member functions ---

	## Selling the instance removes its accumulated value.
	func _init(value: int) -> void:
		super(RuntimeDeltaCommand.Kind.ACCUMULATED_MULT, &"action.accumulate_mult", value)

## Add starting validation allowance.
class Validations:
	extends RuntimeAction

	# --- Member functions ---

	## Use only at round start so uses do not accumulate between rounds.
	func _init(value: int) -> void:
		super(RuntimeDeltaCommand.Kind.VALIDATIONS, &"action.validations", value)

## Add starting manual reroll allowance.
class Rerolls:
	extends RuntimeAction

	# --- Member functions ---

	## Automatic rolls never spend this allowance.
	func _init(value: int) -> void:
		super(RuntimeDeltaCommand.Kind.REROLLS, &"action.rerolls", value)

## Allow one actual internal gap of size two during straight recognition.
class MissingLink:
	extends RuntimeAction

	# --- Member functions ---

	## Recognition combines permissions with max, never by stacking additional gaps.
	func _init() -> void:
		super(RuntimeDeltaCommand.Kind.STRAIGHT_GAPS, &"action.missing_link", 1)

# --- Member variables ---

## Explicit command destination.
var kind: RuntimeDeltaCommand.Kind
## Localized grammar describes the operation, not an item-specific paragraph.
var phrase: StringName
## Flat or snapshot-derived amount.
var amount: EffectAmount

# --- Member functions ---

## Concrete named classes provide readable content constructors.
func _init(kind_: RuntimeDeltaCommand.Kind, phrase_: StringName, value: int) -> void:
	kind = kind_
	phrase = phrase_
	amount = EffectAmount.new()
	amount.constant = value

## Return intent only; the coordinator commits it after the snapshot is fully evaluated.
func commands(context: EffectContext) -> Array[EffectCommand]:
	var command: RuntimeDeltaCommand = RuntimeDeltaCommand.new()
	command.kind = kind
	command.amount = amount.evaluate(context)
	return [command]

## Generate a localized operation from the same amount used by evaluation.
func describe(words: KeywordCatalog, locale: String) -> String:
	return words.render(phrase, {"amount": amount.describe(words, locale)}, locale)

## Amounts participate in cycle and authoring validation.
func dependencies() -> Array[RuleNode]:
	return [amount]

## Reject unknown serialized command destinations.
func local_errors() -> PackedStringArray:
	return [] if kind in RuntimeDeltaCommand.Kind.values() else ["Unknown runtime action"]

## Declare operation grammar dependencies.
func keyword_ids() -> Array[StringName]:
	return [phrase]
