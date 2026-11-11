extends RuleNode
class_name DieQuery
## Select physical dice by intersecting explicit predicates; an empty result remains empty.

# --- Types ---

## SOURCE is the owning die, EVENT is the event subject, POOL considers every die.
enum Scope { SOURCE, EVENT, POOL }
## ANY ignores a flag; YES requires it; NO explicitly requires its absence.
enum State { ANY, YES, NO }
## Optional arithmetic property independent from the accepted value list.
enum Parity { ANY, ODD, EVEN }

## Select thisdie with an optional parity constraint.
class ThisDie:
	extends DieQuery

	# --- Member functions ---

	## Named selector removes tri-state setup from everyday content declarations.
	func _init(parity_: Parity = Parity.ANY) -> void:
		scope = Scope.SOURCE
		parity = parity_

## Select eventdie with an optional parity constraint.
class EventDie:
	extends DieQuery

	# --- Member functions ---

	## Named selector removes tri-state setup from everyday content declarations.
	func _init(parity_: Parity = Parity.ANY) -> void:
		scope = Scope.EVENT
		parity = parity_

## Select alldice with an optional parity constraint.
class AllDice:
	extends DieQuery

	# --- Member functions ---

	## Named selector removes tri-state setup from everyday content declarations.
	func _init(parity_: Parity = Parity.ANY) -> void:
		scope = Scope.POOL
		parity = parity_

## Select validated with an optional parity constraint.
class Validated:
	extends DieQuery

	# --- Member functions ---

	## Named selector removes tri-state setup from everyday content declarations.
	func _init(parity_: Parity = Parity.ANY) -> void:
		scope = Scope.POOL
		parity = parity_
		validated = State.YES

## Select held with an optional parity constraint.
class Held:
	extends DieQuery

	# --- Member functions ---

	## Named selector removes tri-state setup from everyday content declarations.
	func _init(parity_: Parity = Parity.ANY) -> void:
		scope = Scope.POOL
		parity = parity_
		held = State.YES

## Select members with an optional parity constraint.
class Members:
	extends DieQuery

	# --- Member functions ---

	## Named selector removes tri-state setup from everyday content declarations.
	func _init(parity_: Parity = Parity.ANY) -> void:
		scope = Scope.POOL
		parity = parity_
		member = State.YES

## Count dice excluded from the current validation.
class Excluded:
	extends DieQuery

	# --- Member functions ---

	## Excluded dice never include a validated owning die.
	func _init() -> void:
		scope = Scope.POOL
		validated = State.NO

## Select validated dice showing one of the supplied values.
class ValidatedValues:
	extends DieQuery

	# --- Member functions ---

	## Each physical die appears once, even if accepted values repeat.
	func _init(values_: PackedInt32Array) -> void:
		scope = Scope.POOL
		validated = State.YES
		values = values_

## Other validated dice matching the owner's actual current value.
class OtherMatching:
	extends DieQuery

	# --- Member functions ---

	## Relative selectors enumerate the pool, even though their comparison uses the owner.
	func _init() -> void:
		scope = Scope.POOL


	## Explicitly exclude the owner rather than subtracting from a potentially empty count.
	func select(context: EffectContext) -> Array[DieSnapshot]:
		var result: Array[DieSnapshot] = []
		var source: DieSnapshot = context.find_die(context.source_die_id)
		if source:
			for die: DieSnapshot in context.dice:
				if die.validated and die.id != source.id and die.value == source.value:
					result.append(die)
		return result

	## The comparison is relative to the owning die, not a fixed number.
	func describe(words: KeywordCatalog, locale: String) -> String:
		return words.render("query.other_matching", {}, locale)

	## Declare the relative-selector translation.
	func keyword_ids() -> Array[StringName]:
		return [&"query.other_matching"]

## Held dice with at least one matching validated partner, counted once each.
class HeldMatching:
	extends DieQuery

	# --- Member functions ---

	## Relative selectors enumerate the pool, even though their comparison uses the owner.
	func _init() -> void:
		scope = Scope.POOL


	## Break after the first matching partner; extra partners cannot multiply a held die.
	func select(context: EffectContext) -> Array[DieSnapshot]:
		var result: Array[DieSnapshot] = []
		for held_die: DieSnapshot in context.dice:
			if not held_die.held or held_die.validated:
				continue
			for validated_die: DieSnapshot in context.dice:
				if validated_die.validated and validated_die.value == held_die.value:
					result.append(held_die)
					break
		return result

	## Describe the existential matching relationship instead of a pair-product count.
	func describe(words: KeywordCatalog, locale: String) -> String:
		return words.render("query.held_matching", {}, locale)

	## Declare the selector's localized phrase.
	func keyword_ids() -> Array[StringName]:
		return [&"query.held_matching"]

# --- Member variables ---

## Queries default to the owner so a die-bound effect cannot silently become global.
@export var scope: Scope = Scope.SOURCE
## Holding and validation are separate facts; neither is inferred from the other.
@export var held: State = State.ANY
## Includes validated dice outside the recognized combination.
@export var validated: State = State.ANY
## Restricts automatic combination membership independently of validation.
@export var member: State = State.ANY
## Empty accepts any value; duplicate face positions never duplicate a physical die.
@export var values: PackedInt32Array = []
## ODD/EVEN can combine with all other predicates.
@export var parity: Parity = Parity.ANY

# --- Member functions ---

## Return snapshot references without modifying them or the source collection.
func select(context: EffectContext) -> Array[DieSnapshot]:
	var result: Array[DieSnapshot] = []
	for die: DieSnapshot in context.dice:
		if scope == Scope.SOURCE and die.id != context.source_die_id:
			continue
		if scope == Scope.EVENT and die.id != context.event_die_id:
			continue
		if not _accept_state(held, die.held) or not _accept_state(validated, die.validated) or not _accept_state(member, die.combination_member):
			continue
		if not values.is_empty() and not die.value in values:
			continue
		if parity == Parity.ODD and die.value % 2 == 0:
			continue
		if parity == Parity.EVEN and die.value % 2 != 0:
			continue
		result.append(die)
	return result

## Validate authored enum values as well as numeric filters.
func local_errors() -> PackedStringArray:
	var errors: PackedStringArray = []
	if scope not in Scope.values() or held not in State.values() or validated not in State.values() or member not in State.values() or parity not in Parity.values():
		errors.append("Unknown die-query enum value")
	for value: int in values:
		if value < 1:
			errors.append("Query values must be positive")
	return errors

## Describe a selector as a noun phrase usable inside count and action sentences.
func describe(words: KeywordCatalog, locale: String) -> String:
	var scopes: PackedStringArray = ["query.source", "query.event", "query.pool"]
	var phrase: String = words.render(scopes[scope], {}, locale)
	var filters: PackedStringArray = _filter_labels(words, locale)
	if filters.is_empty():
		return phrase
	return words.render("query.filtered", {"dice": phrase, "filters": words.join(filters, "list.and", locale)}, locale)

## Singular source/event presence can read naturally instead of saying "count >= 1".
func describe_presence(words: KeywordCatalog, locale: String) -> String:
	var subject: String = words.render("query.source" if scope == Scope.SOURCE else "query.event", {}, locale)
	var filters: PackedStringArray = _filter_labels(words, locale)
	if filters.is_empty():
		return words.render("condition.exists", {"dice": subject}, locale)
	return words.render("condition.state", {"dice": subject, "filters": words.join(filters, "list.and", locale)}, locale)

## Translate predicates as grammatical state phrases; the catalog controls conjunctions.
func _filter_labels(words: KeywordCatalog, locale: String) -> PackedStringArray:
	var labels: PackedStringArray = []
	var states: Array[int] = [held, validated, member]
	var names: PackedStringArray = ["held", "validated", "member"]
	for index: int in states.size():
		if states[index] != State.ANY:
			var suffix: String = ".yes" if states[index] == State.YES else ".no"
			labels.append(words.render("filter." + names[index] + suffix, {}, locale))
	if not values.is_empty():
		var numbers: PackedStringArray = []
		for value: int in values:
			numbers.append(words.number(value, locale))
		labels.append(words.render("filter.values", {"values": words.join(numbers, "list.or", locale)}, locale))
	if parity != Parity.ANY:
		labels.append(words.render("filter.odd" if parity == Parity.ODD else "filter.even", {}, locale))
	return labels

## Keep tri-state matching identical for all snapshot flags.
func _accept_state(state: State, actual: bool) -> bool:
	return state == State.ANY or actual == (state == State.YES)

## Declare grammar dependencies so missing translations fail content validation.
func keyword_ids() -> Array[StringName]:
	return [&"query.source", &"query.event", &"query.pool", &"query.filtered", &"condition.exists", &"condition.state", &"filter.held.yes", &"filter.held.no", &"filter.validated.yes", &"filter.validated.no", &"filter.member.yes", &"filter.member.no", &"filter.values", &"filter.odd", &"filter.even", &"list.and", &"list.or"]
