extends EffectAction
class_name ScoreAction
## Additive points or Mult contribution; no order-dependent score multiplication.

# --- Types ---

## Add a flat signed points contribution.
class Points:
	extends ScoreAction

	# --- Member functions ---

	## Declare the contribution directly without constructing an amount resource.
	func _init(value: int) -> void:
		channel = ScoreDeltaCommand.Channel.POINTS
		amount = EffectAmount.new()
		amount.constant = value

## Add points once per selected physical die.
class PointsPerDie:
	extends ScoreAction

	# --- Member functions ---

	## The selector and coefficient are the complete count-scaled rule.
	func _init(value: int, dice: DieQuery) -> void:
		channel = ScoreDeltaCommand.Channel.POINTS
		amount = EffectAmount.new()
		amount.per_die = value
		amount.query = dice

## Add a flat signed mult contribution.
class Mult:
	extends ScoreAction

	# --- Member functions ---

	## Declare the contribution directly without constructing an amount resource.
	func _init(value: int) -> void:
		channel = ScoreDeltaCommand.Channel.MULT
		amount = EffectAmount.new()
		amount.constant = value

## Add mult once per selected physical die.
class MultPerDie:
	extends ScoreAction

	# --- Member functions ---

	## The selector and coefficient are the complete count-scaled rule.
	func _init(value: int, dice: DieQuery) -> void:
		channel = ScoreDeltaCommand.Channel.MULT
		amount = EffectAmount.new()
		amount.per_die = value
		amount.query = dice

## Add a percentage to the shared pool; percentages never compound.
class MultPercent:
	extends ScoreAction

	# --- Member functions ---

	## The value is in percentage points: 100 means a +100% increase.
	func _init(value: int) -> void:
		channel = ScoreDeltaCommand.Channel.MULT_PERCENT
		amount = EffectAmount.new()
		amount.constant = value

## Add a percentage per qualifying physical die.
class MultPercentPerDie:
	extends ScoreAction

	# --- Member functions ---

	## Matching dice contribute to one shared percentage pool.
	func _init(value: int, dice: DieQuery) -> void:
		channel = ScoreDeltaCommand.Channel.MULT_PERCENT
		amount = EffectAmount.new()
		amount.per_die = value
		amount.query = dice

## Use a named snapshot-derived amount for an additive score channel.
class Calculated:
	extends ScoreAction

	# --- Member functions ---

	## Amount classes describe the same formula they evaluate.
	func _init(channel_: ScoreDeltaCommand.Channel, amount_: EffectAmount) -> void:
		channel = channel_
		amount = amount_

# --- Member variables ---

## Which accumulator receives the signed delta.
@export var channel: ScoreDeltaCommand.Channel = ScoreDeltaCommand.Channel.POINTS
## Flat or count-scaled amount.
@export var amount: EffectAmount

# --- Member functions ---

## Emit a delta without clamping penalties or touching the current score.
func commands(context: EffectContext) -> Array[EffectCommand]:
	var command: ScoreDeltaCommand = ScoreDeltaCommand.new()
	command.channel = channel
	command.amount = amount.evaluate(context)
	return [command]

## Localize the complete operation so languages may reorder amount and score channel.
func describe(words: KeywordCatalog, locale: String) -> String:
	var keys: PackedStringArray = ["action.points", "action.mult", "action.mult_percent"]
	return words.render(keys[channel], {"amount": amount.describe(words, locale)}, locale)

## Ensure amount validation cannot be bypassed by a valid action enum.
func dependencies() -> Array[RuleNode]:
	return [amount]

## Serialized enum values must remain recognized.
func local_errors() -> PackedStringArray:
	return [] if channel in ScoreDeltaCommand.Channel.values() else ["Unknown score channel"]

## Declare grammar dependencies so missing translations fail content validation.
func keyword_ids() -> Array[StringName]:
	return [&"action.points", &"action.mult", &"action.mult_percent"]
