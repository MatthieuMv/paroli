extends RefCounted
class_name RoundSession
## Host-side round logic around MechanicsRun: samples faces, supplies D-022 base scores,
## and mints unique event IDs. No scene, node, or rendering dependency.
## The unused-play coin rate is an explicit host fixture; the design has not fixed one yet.

# --- Member variables ---

## Authoritative rules coordinator; the owning host equips it between rounds.
var run: MechanicsRun
## Seedable sampler for the six equally likely physical face positions (D-024).
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Placeholder conversion for unused plays on success; not an accepted economy value.
var coins_per_unused_play: int = 1
## Plays granted at the start of the current round, after allowance Jokers.
var plays_granted: int = 0
## Manual rolls granted at the start of the current round, after allowance Jokers.
var rerolls_granted: int = 0
## Monotonic suffix keeps every committed event ID unique across the run.
var _event_serial: int = 0

# --- Member functions ---

## Wrap an equipped run; a zero seed keeps the generator's own random seed.
func _init(run_: MechanicsRun = null, seed_: int = 0) -> void:
	run = run_ if run_ else MechanicsRun.new()
	if seed_ != 0:
		rng.seed = seed_

## Start a round and record the allowances actually granted for the pip displays.
func begin(target: float, base_plays: int = 3, base_rerolls: int = 3) -> MechanicsEventResult:
	var result: MechanicsEventResult = run.start_round(_next_id("round"), target, base_plays, base_rerolls)
	plays_granted = run.validations_remaining
	rerolls_granted = run.rerolls_remaining
	return result

## Free opening roll of all five dice.
func open() -> MechanicsEventResult:
	return run.roll(_next_id("opening"), _sample(_all_ids()), EffectContext.RollKind.OPENING)

## Manual roll of the given dice; spends one roll regardless of how many dice it includes.
func reroll(ids: Array[StringName]) -> MechanicsEventResult:
	return run.roll(_next_id("reroll"), _sample(ids), EffectContext.RollKind.MANUAL)

## Free automatic roll of exactly the dice played by the previous, non-final play.
func automatic_roll(ids: Array[StringName]) -> MechanicsEventResult:
	return run.roll(_next_id("automatic"), _sample(ids), EffectContext.RollKind.AUTOMATIC)

## Describe the pending play without committing: base values and eligibility cues only.
func preview(selected: Array[StringName]) -> PlayPreview:
	var result: PlayPreview = PlayPreview.new()
	result.combination = run.preview_combination(selected)
	if not result.combination:
		return result
	result.base_points = CombinationScores.base_points(result.combination.category)
	result.base_mult = CombinationScores.base_mult(result.combination.category)
	for command: EffectCommand in run.preview_commands(selected):
		var amount: int = 0
		if command is ScoreDeltaCommand:
			amount = (command as ScoreDeltaCommand).amount
		elif command is RuntimeDeltaCommand:
			amount = (command as RuntimeDeltaCommand).amount
		if amount == 0:
			continue
		if command.owner_id not in result.eligible_owners:
			result.eligible_owners.append(command.owner_id)
		if amount < 0 and command.source_die_id != &"" and command.source_die_id not in result.penalized_dice:
			result.penalized_dice.append(command.source_die_id)
	# A selected die outside the combination is idle when leaving it out would lose nothing.
	# This compares plays internally; the cue it feeds never shows a number.
	var worth: Vector2 = _worth(selected)
	for die_id: StringName in selected:
		if die_id in result.combination.members:
			continue
		var without: Array[StringName] = selected.duplicate()
		without.erase(die_id)
		var other: Vector2 = _worth(without)
		if other.x >= worth.x and other.y >= worth.y:
			result.idle_dice.append(die_id)
	return result

## Value of a pending play for comparing selections: x is the credited score it would
## earn, y the sum of its non-scoring rewards (coins, growth, allowances). Never displayed.
func _worth(selected: Array[StringName]) -> Vector2:
	var combination: CombinationRecognizer.Result = run.preview_combination(selected)
	if not combination:
		return Vector2.ZERO
	var points: float = float(CombinationScores.base_points(combination.category) + combination.value_sum)
	var mult: float = float(CombinationScores.base_mult(combination.category))
	var percent: float = 0.0
	var rewards: float = 0.0
	for command: EffectCommand in run.preview_commands(selected):
		if command is ScoreDeltaCommand:
			var score: ScoreDeltaCommand = command as ScoreDeltaCommand
			match score.channel:
				ScoreDeltaCommand.Channel.POINTS:
					points += float(score.amount)
				ScoreDeltaCommand.Channel.MULT:
					mult += float(score.amount)
				ScoreDeltaCommand.Channel.MULT_PERCENT:
					percent += float(score.amount)
		elif command is RuntimeDeltaCommand:
			var runtime: RuntimeDeltaCommand = command as RuntimeDeltaCommand
			if runtime.kind != RuntimeDeltaCommand.Kind.STRAIGHT_GAPS:
				rewards += float(runtime.amount)
	return Vector2(maxf(0.0, points * mult * (1.0 + percent / 100.0)), rewards)

## Commit a play. Base points include member face values, as D-019 specifies.
func play(selected: Array[StringName]) -> PlayOutcome:
	var outcome: PlayOutcome = PlayOutcome.new()
	outcome.selected = selected.duplicate()
	outcome.score_before = run.round_score
	outcome.target = run.round_target
	outcome.coins_before = run.coins
	var combination: CombinationRecognizer.Result = run.preview_combination(selected)
	var category: StringName = combination.category if combination else &""
	outcome.category_points = CombinationScores.base_points(category)
	outcome.category_mult = CombinationScores.base_mult(category)
	var face_sum: int = combination.value_sum if combination else 0
	outcome.result = run.validate_dice(_next_id("play"), selected, outcome.category_points + face_sum, outcome.category_mult)
	if not outcome.result.errors.is_empty():
		return outcome
	# Member values are read after the commit; validation never changes current faces.
	for die_id: StringName in outcome.result.combination.members:
		outcome.face_points[die_id] = run.find_die(die_id).value
	outcome.raw_score = float(outcome.result.points) * outcome.result.final_mult
	outcome.score_after = run.round_score
	outcome.completed = not run.round_active
	outcome.succeeded = outcome.completed and not run.run_failed
	outcome.unused_plays = run.validations_remaining
	if outcome.succeeded:
		outcome.unused_play_coins = outcome.unused_plays * coins_per_unused_play
		run.coins += outcome.unused_play_coins
	return outcome

## Dice that will reroll automatically after a non-final play.
func all_ids() -> Array[StringName]:
	return _all_ids()

## Collect permanent identities in run order.
func _all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for die: RunDie in run.dice:
		ids.append(die.id)
	return ids

## Sample one physical face position per die; repeated face values keep their odds.
func _sample(ids: Array[StringName]) -> Dictionary[StringName, int]:
	var faces: Dictionary[StringName, int] = {}
	for die_id: StringName in ids:
		faces[die_id] = rng.randi_range(0, 5)
	return faces

## Rejected actions do not consume ledger entries, but fresh IDs keep retries unambiguous.
func _next_id(prefix: String) -> StringName:
	_event_serial += 1
	return StringName("%s_%d" % [prefix, _event_serial])
