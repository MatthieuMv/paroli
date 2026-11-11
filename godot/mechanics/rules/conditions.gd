extends RefCounted
class_name Conditions
## Human-authored condition vocabulary, mirroring ChaosTactics' named nested rule classes.
## These are the actual evaluable rules; there is no separate parser or generated description.

# --- Types ---

## The owning die is held.
class Held:
	extends DiceCountCondition

	# --- Member functions ---

	## Construct a single-die predicate without exposing count machinery to authors.
	func _init() -> void:
		query = DieQuery.ThisDie.new()
		query.held = DieQuery.State.YES

## The owning die is not held.
class NotHeld:
	extends DiceCountCondition

	# --- Member functions ---

	## Construct a single-die predicate without exposing count machinery to authors.
	func _init() -> void:
		query = DieQuery.ThisDie.new()
		query.held = DieQuery.State.NO

## The owning die is included in validation, even outside the combination.
class Validated:
	extends DiceCountCondition

	# --- Member functions ---

	## Construct a single-die predicate without exposing count machinery to authors.
	func _init() -> void:
		query = DieQuery.ThisDie.new()
		query.validated = DieQuery.State.YES

## The owning die is excluded from validation.
class NotValidated:
	extends DiceCountCondition

	# --- Member functions ---

	## Construct a single-die predicate without exposing count machinery to authors.
	func _init() -> void:
		query = DieQuery.ThisDie.new()
		query.validated = DieQuery.State.NO

## The owning die participates in the recognized combination.
class Member:
	extends DiceCountCondition

	# --- Member functions ---

	## Construct a single-die predicate without exposing count machinery to authors.
	func _init() -> void:
		query = DieQuery.ThisDie.new()
		query.member = DieQuery.State.YES

## The owning die shows an odd value.
class Odd:
	extends DiceCountCondition

	# --- Member functions ---

	## Construct a single-die predicate without exposing count machinery to authors.
	func _init() -> void:
		query = DieQuery.ThisDie.new()
		query.parity = DieQuery.Parity.ODD

## The owning die shows an even value.
class Even:
	extends DiceCountCondition

	# --- Member functions ---

	## Construct a single-die predicate without exposing count machinery to authors.
	func _init() -> void:
		query = DieQuery.ThisDie.new()
		query.parity = DieQuery.Parity.EVEN

## The owning die shows one specific value.
class Showing:
	extends DiceCountCondition

	# --- Member functions ---

	## Numeric content is shared by evaluation and localization.
	func _init(value: int) -> void:
		query = DieQuery.ThisDie.new()
		query.values = [value]

## The host recognized one of these scoring categories.
class Combination:
	extends CombinationCondition

	# --- Member functions ---

	## Category IDs refer to keyword-owned names, never translated lookup strings.
	func _init(categories: Array[StringName]) -> void:
		combinations = categories

## Require an exact number of dice matching a named selector.
class Exactly:
	extends DiceCountCondition

	# --- Member functions ---

	## Zero explicitly means no matching dice.
	func _init(count: int, dice: DieQuery) -> void:
		minimum = count
		maximum = count
		query = dice

## Require at least a number of dice matching a named selector.
class AtLeast:
	extends DiceCountCondition

	# --- Member functions ---

	## The default upper bound remains unbounded.
	func _init(count: int, dice: DieQuery) -> void:
		minimum = count
		query = dice

## Restrict a held/released/roll event to this effect's owner.
class ThisDieTriggered:
	extends SourceEventCondition

	# --- Member functions ---

	## A missing event die never qualifies.
	func _init() -> void:
		same_die = true

## Combine conditions with explicit ALL semantics.
class All:
	extends ConditionGroup

	# --- Member functions ---

	## Child order is preserved for readable generated text.
	func _init(conditions_: Array[EffectCondition]) -> void:
		mode = Mode.ALL
		conditions = conditions_

## Combine conditions with explicit ANY semantics.
class Any:
	extends ConditionGroup

	# --- Member functions ---

	## Child order is preserved for readable generated text.
	func _init(conditions_: Array[EffectCondition]) -> void:
		mode = Mode.ANY
		conditions = conditions_

## Negate exactly one condition.
class Not:
	extends ConditionGroup

	# --- Member functions ---

	## Nesting remains explicit in both code and localized text.
	func _init(condition_: EffectCondition) -> void:
		mode = Mode.NOT
		conditions = [condition_]
