extends RefCounted
class_name EffectContext
## Immutable event snapshot supplied by game logic; no recognition or random rolling happens here.

# --- Types ---

## Cosmetic and opening rolls never award reroll income or manual-reroll history.
enum RollKind { NONE, OPENING, MANUAL, AUTOMATIC, COSMETIC }

# --- Member variables ---

## Runtime ownership identity for persistent commands.
var owner_id: StringName
## Which physical dice changed in a batch roll.
var rolled_ids: Array[StringName] = []
## Semantic reason for the roll, supplied by the runtime coordinator.
var roll_kind: RollKind = RollKind.NONE
## Snapshot of action allowances before commitment.
var validations_remaining: int = 0
## Only manual rerolls consume this allowance.
var rerolls_remaining: int = 0
## Includes zero-score validations.
var previous_validations: int = 0
## Empty means there is no previous recognized category this round.
var previous_combination: StringName
## Successful round-end events include boss rounds.
var round_succeeded: bool = false
## Paid refresh cost is supplied by the shop, never assumed to equal one coin.
var refresh_cost: int = 0
## Persistent accumulated Mult belonging to the evaluated Joker.
var owner_mult: int = 0
## Snapshot total before any commands from the current event are applied.
var joker_sell_total: int = 0


## Unique committed event identity for a host-owned once-per-event application ledger.
var event_id: StringName
## Event keyword ID, e.g. validation, held, released, rolled, round_started.
var event: StringName = &"validation"
## Runtime die carrying the current upgrade/bonus; empty for a global Joker.
var source_die_id: StringName
## Die that caused the event, if any; distinct from the effect's owner.
var event_die_id: StringName
## Highest-ranked recognized combination ID supplied by the host.
var combination: StringName
## Each physical die appears once; evaluation never mutates these snapshots.
var dice: Array[DieSnapshot] = []

# --- Member functions ---

## Find an optional source or event die by identity without indexing assumptions.
func find_die(id: StringName) -> DieSnapshot:
	for die: DieSnapshot in dice:
		if die.id == id:
			return die
	return null

## Reject ambiguous identities and inconsistent membership before resolving any effect.
func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	var identities: Array[StringName] = []
	for die: DieSnapshot in dice:
		if not die:
			errors.append("Missing die snapshot")
			continue
		if die.id == &"" or die.id in identities:
			errors.append("Die IDs must be nonempty and unique")
		identities.append(die.id)
		if die.value < 1:
			errors.append("Face values must be positive")
		if die.combination_member and not die.validated:
			errors.append("Combination members must be validated")
	if source_die_id != &"" and not find_die(source_die_id):
		errors.append("Source die is absent")
	if event_die_id != &"" and not find_die(event_die_id):
		errors.append("Event die is absent")
	if event_id == &"":
		errors.append("Missing committed event identity")
	if event == &"":
		errors.append("Missing event ID")
	return errors
