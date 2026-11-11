extends RefCounted
class_name MechanicsRun
## Effects coordinator: stable snapshots, recognition, ownership, history, and event deduplication.
## Rendering, random face sampling, shop offers, and base combination scores remain host responsibilities.

# --- Member variables ---

## Five physical dice in permanent run order.
var dice: Array[RunDie] = []
## Owned instances carry persistent growth; shared definitions never do.
var owned: Array[OwnedDefinition] = []
## Economy state; initial funds and sell prices are explicit inputs.
var coins: int = 0
## Remaining current-round allowances.
var validations_remaining: int = 0
## Only manual roll actions spend this allowance.
var rerolls_remaining: int = 0
## Includes every committed validation, even a zero score.
var previous_validations: int = 0
## Last recognized category this round, empty before the first validation.
var previous_combination: StringName
## Current cumulative score.
var round_score: float = 0.0
## The host supplies the target; reaching it immediately completes the round.
var round_target: float = 0.0
## Completed rounds reject additional scoring or manual rolls.
var round_active: bool = false
## Failure prevents another round within this run.
var run_failed: bool = false
## Committed IDs are unique across the run, including shop and round events.
var _events: Dictionary[StringName, MechanicsEventResult] = {}
## The initial roll must happen before gameplay actions.
var _opening_pending: bool = false
## Exactly the last validation's dice receive the free automatic reroll.
var _automatic_pending: Array[StringName] = []

# --- Member functions ---

## Construct physical identities and accept explicitly configured starting currency.
func _init(starting_coins: int = 0) -> void:
	coins = starting_coins
	for index: int in 5:
		dice.append(RunDie.new(StringName("die_%d" % (index + 1))))

## Locate a physical die without exposing scene nodes or array-position assumptions.
func find_die(id: StringName) -> RunDie:
	for die: RunDie in dice:
		if die.id == id:
			return die
	return null

## Read current owned state by stable runtime identity.
func find_owned(id: StringName) -> OwnedDefinition:
	for item: OwnedDefinition in owned:
		if item.id == id:
			return item
	return null

## Install a permanent upgrade into the next ordinary die, outside an active round.
func install_upgrade(definition: UpgradeDefinition) -> PackedStringArray:
	if round_active or run_failed:
		return ["Upgrades install between rounds in a live run"]
	if not definition:
		return ["Missing upgrade"]
	var errors: PackedStringArray = definition.validate()
	if not errors.is_empty():
		return errors
	for die: RunDie in dice:
		var slot: StringName = StringName("upgrade:" + String(die.id))
		if not find_owned(slot):
			_add_owned(slot, definition, die.id, 0)
			if not definition.faces.is_empty():
				die.faces = definition.faces.duplicate()
				die.value = die.faces[0]
			return []
	return ["All dice already have permanent upgrades"]

## Equip one unique bonus in a free die slot without altering permanent faces.
func equip_bonus(definition: BonusDefinition, die_id: StringName, sell_value: int) -> PackedStringArray:
	if round_active or run_failed or not find_die(die_id):
		return ["Bonus placement requires a valid die outside a round"]
	if not definition or sell_value < 0:
		return ["Invalid bonus or sell value"]
	var errors: PackedStringArray = definition.validate()
	if not errors.is_empty():
		return errors
	var slot: StringName = StringName("bonus:" + String(die_id))
	if find_owned(slot) or _owns_definition(definition.id):
		return ["Bonus slot occupied or bonus already owned"]
	_add_owned(slot, definition, die_id, sell_value)
	return []

## Add one unique Joker, enforcing the four-slot limit and explicit sell value.
func add_joker(definition: JokerDefinition, sell_value: int) -> PackedStringArray:
	if round_active or run_failed or not definition or sell_value < 0:
		return ["Jokers require a valid definition and price outside a round"]
	var errors: PackedStringArray = definition.validate()
	if not errors.is_empty():
		return errors
	var count: int = 0
	for item: OwnedDefinition in owned:
		if item.definition is JokerDefinition:
			count += 1
	if count >= 4 or _owns_definition(definition.id):
		return ["Joker slots full or Joker already owned"]
	_add_owned(StringName("joker:" + String(definition.id)), definition, &"", sell_value)
	return []

## Transfer a bonus outside rounds while retaining its identity and leaving faces untouched.
func move_bonus(from_die: StringName, to_die: StringName) -> PackedStringArray:
	var item: OwnedDefinition = find_owned(StringName("bonus:" + String(from_die)))
	var target: StringName = StringName("bonus:" + String(to_die))
	if round_active or run_failed or not item or not find_die(to_die) or find_owned(target):
		return ["Invalid bonus transfer"]
	item.id = target
	item.die_id = to_die
	return []

## Sell only bonuses/Jokers; removing the instance removes accumulated growth.
func sell(event_id: StringName, owner_id: StringName) -> MechanicsEventResult:
	if _events.has(event_id):
		return _events[event_id]
	var item: OwnedDefinition = find_owned(owner_id)
	if event_id == &"" or round_active or run_failed or not item or item.definition is UpgradeDefinition:
		return _error("Invalid sale")
	coins += item.sell_value()
	owned.erase(item)
	return _remember(event_id, MechanicsEventResult.new())

## Reset round history and apply currently owned allowance Jokers once.
func start_round(event_id: StringName, target: float, base_validations: int = 3, base_rerolls: int = 3) -> MechanicsEventResult:
	if _events.has(event_id):
		return _events[event_id]
	if event_id == &"" or round_active or run_failed or target <= 0 or base_validations <= 0 or base_rerolls < 0:
		return _error("Invalid round start")
	var preflight: PackedStringArray = _preflight()
	if not preflight.is_empty():
		return _error("; ".join(preflight))
	round_score = 0
	round_target = target
	previous_validations = 0
	previous_combination = &""
	validations_remaining = base_validations
	rerolls_remaining = base_rerolls
	_automatic_pending.clear()
	_opening_pending = true
	for die: RunDie in dice:
		die.reset_history()
	var plan: EffectResolution = _plan(&"round_started", event_id)
	if not plan.errors.is_empty():
		return _plan_error(plan)
	_commit(plan.commands)
	round_active = true
	return _remember_plan(event_id, plan)

## Commit supplied physical face indices; this coordinator never invents random outcomes.
func roll(event_id: StringName, face_indices: Dictionary[StringName, int], kind: EffectContext.RollKind) -> MechanicsEventResult:
	if _events.has(event_id):
		return _events[event_id]
	if event_id == &"" or face_indices.is_empty() or kind not in EffectContext.RollKind.values() or kind == EffectContext.RollKind.NONE:
		return _error("Invalid roll")
	if kind != EffectContext.RollKind.COSMETIC and not round_active:
		return _error("The round has ended")
	var ids: Array[StringName] = []
	for die_id: StringName in face_indices:
		if not find_die(die_id) or face_indices[die_id] < 0 or face_indices[die_id] >= 6:
			return _error("Invalid die or physical face position")
		ids.append(die_id)
	if kind == EffectContext.RollKind.OPENING and (not _opening_pending or ids.size() != dice.size()):
		return _error("Opening rolls occur once and include every die")
	if kind == EffectContext.RollKind.MANUAL and (_opening_pending or not _automatic_pending.is_empty() or rerolls_remaining <= 0):
		return _error("Manual reroll is unavailable")
	if kind == EffectContext.RollKind.AUTOMATIC and (_opening_pending or not _same_ids(ids, _automatic_pending)):
		return _error("Automatic rolls must match the pending validated dice")
	if kind == EffectContext.RollKind.COSMETIC:
		return _remember(event_id, MechanicsEventResult.new())
	var preflight: PackedStringArray = _preflight()
	if not preflight.is_empty():
		return _error("; ".join(preflight))
	for die_id: StringName in ids:
		var die: RunDie = find_die(die_id)
		die.value = die.faces[face_indices[die_id]]
		if kind == EffectContext.RollKind.MANUAL:
			die.manual_rerolls_round += 1
			die.rerolls_since_validation += 1
	if kind == EffectContext.RollKind.MANUAL:
		rerolls_remaining -= 1
	if kind == EffectContext.RollKind.OPENING:
		_opening_pending = false
	if kind == EffectContext.RollKind.AUTOMATIC:
		_automatic_pending.clear()
	var plan: EffectResolution = _plan(&"rolled", event_id, [], null, ids, kind)
	if not plan.errors.is_empty():
		return _plan_error(plan)
	_commit(plan.commands)
	return _remember_plan(event_id, plan)

## Resolve recognition and all effects before committing any history or rewards.
func validate_dice(event_id: StringName, selected: Array[StringName], base_points: int, base_mult: int) -> MechanicsEventResult:
	if _events.has(event_id):
		return _events[event_id]
	if event_id == &"" or not round_active or _opening_pending or not _automatic_pending.is_empty() or validations_remaining <= 0 or selected.is_empty():
		return _error("Validation is unavailable")
	var seen: Array[StringName] = []
	for die_id: StringName in selected:
		if not find_die(die_id) or die_id in seen:
			return _error("Invalid or duplicate validated die")
		seen.append(die_id)
	var recognition_plan: EffectResolution = _plan(&"recognition", event_id, selected)
	if not recognition_plan.errors.is_empty():
		return _plan_error(recognition_plan)
	var gaps: int = 0
	for command: EffectCommand in recognition_plan.commands:
		if command is RuntimeDeltaCommand:
			var delta: RuntimeDeltaCommand = command as RuntimeDeltaCommand
			if delta.kind == RuntimeDeltaCommand.Kind.STRAIGHT_GAPS:
				gaps = maxi(gaps, delta.amount)
	var selected_dice: Array[DieSnapshot] = []
	for die: RunDie in dice:
		if die.id in selected:
			selected_dice.append(die.snapshot(true, false))
	var combination: CombinationRecognizer.Result = CombinationRecognizer.recognize(selected_dice, gaps)
	var plan: EffectResolution = _plan(&"validation", event_id, selected, combination)
	if not plan.errors.is_empty():
		return _plan_error(plan)
	var result: MechanicsEventResult = MechanicsEventResult.new()
	result.combination = combination
	result.commands = plan.commands
	result.points = base_points
	result.flat_mult = base_mult
	for command: EffectCommand in plan.commands:
		if command is ScoreDeltaCommand:
			var delta: ScoreDeltaCommand = command as ScoreDeltaCommand
			match delta.channel:
				ScoreDeltaCommand.Channel.POINTS:
					result.points += delta.amount
				ScoreDeltaCommand.Channel.MULT:
					result.flat_mult += delta.amount
				ScoreDeltaCommand.Channel.MULT_PERCENT:
					result.mult_percent += delta.amount
	result.final_mult = float(result.flat_mult) * (1.0 + float(result.mult_percent) / 100.0)
	result.credited_score = maxf(0, float(result.points) * result.final_mult)
	var success: bool = round_score + result.credited_score >= round_target
	var completed: bool = success or validations_remaining == 1
	if completed:
		var ending: EffectResolution = _plan(&"round_ended", event_id, selected, combination, [], EffectContext.RollKind.NONE, success)
		if not ending.errors.is_empty():
			return _plan_error(ending)
		result.commands.append_array(ending.commands)
	_commit(result.commands)
	# Only now may histories change; every rule above observed the same prior state.
	for die: RunDie in dice:
		if die.id in selected:
			if die.previous_validated_value > 0 and die.value > die.previous_validated_value:
				die.crescendo_percent += HistoryAmount.CRESCENDO_STEP
			die.previous_validated_value = die.value
			die.rerolls_since_validation = 0
	previous_validations += 1
	previous_combination = combination.category
	validations_remaining -= 1
	round_score += result.credited_score
	if completed:
		round_active = false
		run_failed = not success
		_automatic_pending.clear()
	else:
		_automatic_pending = selected.duplicate()
	return _remember(event_id, result)

## Record an externally completed round, including bosses, without awarding twice.
func finish_round(event_id: StringName, succeeded: bool) -> MechanicsEventResult:
	if _events.has(event_id):
		return _events[event_id]
	if event_id == &"" or not round_active:
		return _error("No active round to complete")
	var plan: EffectResolution = _plan(&"round_ended", event_id, [], null, [], EffectContext.RollKind.NONE, succeeded)
	if not plan.errors.is_empty():
		return _plan_error(plan)
	_commit(plan.commands)
	round_active = false
	run_failed = not succeeded
	_automatic_pending.clear()
	return _remember_plan(event_id, plan)

## Paid whole-shop refreshes count once regardless of price; entry/purchases never call this.
func paid_refresh(event_id: StringName, cost: int) -> MechanicsEventResult:
	if _events.has(event_id):
		return _events[event_id]
	if event_id == &"" or round_active or run_failed or cost <= 0 or coins < cost:
		return _error("Paid refresh is unavailable")
	var plan: EffectResolution = _plan(&"shop_refreshed", event_id, [], null, [], EffectContext.RollKind.NONE, false, cost)
	if not plan.errors.is_empty():
		return _plan_error(plan)
	coins -= cost
	_commit(plan.commands)
	return _remember_plan(event_id, plan)

## Evaluate each owned instance against separately constructed but identical event facts.
func _plan(event: StringName, event_id: StringName, selected: Array[StringName] = [], combination: CombinationRecognizer.Result = null, rolled: Array[StringName] = [], kind: EffectContext.RollKind = EffectContext.RollKind.NONE, succeeded: bool = false, refresh_cost: int = 0) -> EffectResolution:
	var result: EffectResolution = EffectResolution.new()
	var sell_total: int = 0
	for item: OwnedDefinition in owned:
		if item.definition is JokerDefinition:
			sell_total += item.sell_value()
	for item: OwnedDefinition in owned:
		var context: EffectContext = EffectContext.new()
		context.event = event
		context.event_id = event_id
		context.source_die_id = item.die_id
		context.owner_id = item.id
		context.rolled_ids = rolled.duplicate()
		context.roll_kind = kind
		context.validations_remaining = validations_remaining
		context.rerolls_remaining = rerolls_remaining
		context.previous_validations = previous_validations
		context.previous_combination = previous_combination
		context.owner_mult = item.accumulated_mult
		context.joker_sell_total = sell_total
		context.round_succeeded = succeeded
		context.refresh_cost = refresh_cost
		if combination:
			context.combination = combination.category
		for die: RunDie in dice:
			context.dice.append(die.snapshot(die.id in selected, combination != null and die.id in combination.members))
		var planned: EffectResolution = EffectResolver.resolve(item.definition, context)
		result.errors.append_array(planned.errors)
		result.commands.append_array(planned.commands)
	if not result.errors.is_empty():
		result.commands.clear()
	return result

## Apply only state deltas; scoring was combined independently and recognition is a read policy.
func _commit(commands: Array[EffectCommand]) -> void:
	for command: EffectCommand in commands:
		if command is RuntimeDeltaCommand:
			var delta: RuntimeDeltaCommand = command as RuntimeDeltaCommand
			match delta.kind:
				RuntimeDeltaCommand.Kind.COINS:
					coins += delta.amount
				RuntimeDeltaCommand.Kind.SELL_VALUE:
					find_owned(delta.owner_id).sell_growth += delta.amount
				RuntimeDeltaCommand.Kind.ACCUMULATED_MULT:
					find_owned(delta.owner_id).accumulated_mult += delta.amount
				RuntimeDeltaCommand.Kind.VALIDATIONS:
					validations_remaining += delta.amount
				RuntimeDeltaCommand.Kind.REROLLS:
					rerolls_remaining += delta.amount

## Create one mutable ownership instance after all admission checks pass.
func _add_owned(id: StringName, definition: BuildDefinition, die_id: StringName, sell_value: int) -> void:
	var item: OwnedDefinition = OwnedDefinition.new()
	item.id = id
	item.definition = definition
	item.die_id = die_id
	item.base_sell_value = sell_value
	owned.append(item)

## Uniqueness applies to owned bonuses and Jokers, not transient offers.
func _owns_definition(id: StringName) -> bool:
	for item: OwnedDefinition in owned:
		if item.definition.id == id:
			return true
	return false

## Compare batch identities independently from dictionary insertion order.
func _same_ids(left: Array[StringName], right: Array[StringName]) -> bool:
	if left.size() != right.size():
		return false
	for id: StringName in left:
		if not id in right:
			return false
	return true

## Preserve committed results for idempotent event retries.
func _remember(event_id: StringName, result: MechanicsEventResult) -> MechanicsEventResult:
	_events[event_id] = result
	return result

## Return a non-scoring committed plan.
func _remember_plan(event_id: StringName, plan: EffectResolution) -> MechanicsEventResult:
	var result: MechanicsEventResult = MechanicsEventResult.new()
	result.commands = plan.commands
	return _remember(event_id, result)

## Report a failure without consuming its event ID.
func _error(message: String) -> MechanicsEventResult:
	var result: MechanicsEventResult = MechanicsEventResult.new()
	result.errors.append(message)
	return result

## Preserve detailed authoring errors when planning fails.
func _plan_error(plan: EffectResolution) -> MechanicsEventResult:
	var result: MechanicsEventResult = MechanicsEventResult.new()
	result.errors = plan.errors
	return result


## Reject invalid authoring before round/roll bookkeeping can change.
func _preflight() -> PackedStringArray:
	var errors: PackedStringArray = []
	for item: OwnedDefinition in owned:
		errors.append_array(item.definition.validate())
	for die: RunDie in dice:
		if die.faces.size() != 6 or die.value < 1:
			errors.append("Invalid physical die state")
		for value: int in die.faces:
			if value < 1:
				errors.append("Invalid physical face value")
	return errors

## Read-only recognition lets the host select category base scoring before commitment.
func preview_combination(selected: Array[StringName]) -> CombinationRecognizer.Result:
	if selected.is_empty():
		return null
	var identities: Array[StringName] = []
	for die_id: StringName in selected:
		if not find_die(die_id) or die_id in identities:
			return null
		identities.append(die_id)
	var plan: EffectResolution = _plan(&"recognition", &"preview", selected)
	if not plan.errors.is_empty():
		return null
	var gaps: int = 0
	for command: EffectCommand in plan.commands:
		if command is RuntimeDeltaCommand:
			var delta: RuntimeDeltaCommand = command as RuntimeDeltaCommand
			if delta.kind == RuntimeDeltaCommand.Kind.STRAIGHT_GAPS:
				gaps = maxi(gaps, delta.amount)
	var selected_dice: Array[DieSnapshot] = []
	for die: RunDie in dice:
		if die.id in selected:
			selected_dice.append(die.snapshot(true, false))
	return CombinationRecognizer.recognize(selected_dice, gaps)


## Return upgrades that would contribute to the current play, without committing anything.
## Zero-valued commands do not activate VFX; held support upgrades may still contribute.
## Use the same recognition and rule planner as validation, including history and Jokers.
func preview_active_upgrades(selected: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	if not round_active or _opening_pending or not _automatic_pending.is_empty() or validations_remaining <= 0:
		return result
	var combination: CombinationRecognizer.Result = preview_combination(selected)
	if not combination:
		return result
	var plan: EffectResolution = _plan(&"validation", &"preview", selected, combination)
	if not plan.errors.is_empty():
		return result
	for command: EffectCommand in plan.commands:
		var item: OwnedDefinition = find_owned(command.owner_id)
		if not item or not item.definition is UpgradeDefinition:
			continue
		var contributes: bool = false
		if command is ScoreDeltaCommand:
			contributes = (command as ScoreDeltaCommand).amount != 0
		elif command is RuntimeDeltaCommand:
			contributes = (command as RuntimeDeltaCommand).amount != 0
		if contributes and item.die_id not in result:
			result.append(item.die_id)
	return result
