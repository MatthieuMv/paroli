extends RefCounted
class_name ScoreScript
## Orders a committed play into reveal beats. Scoring is additive, so order is presentation only:
## member faces left to right, then each die's upgrade and bonus, then Jokers in rack order.

# --- Static functions ---

## Build beats whose running totals end exactly at the committed mechanics result.
static func build(outcome: PlayOutcome, run: MechanicsRun) -> Array[ScoreStep]:
	var steps: Array[ScoreStep] = []
	var points: int = outcome.category_points
	var mult: int = outcome.category_mult
	var percent: int = 0
	# Phase 1: automatic face points from recognized members, in run order.
	for die: RunDie in run.dice:
		if not outcome.face_points.has(die.id):
			continue
		var face: ScoreStep = ScoreStep.new()
		face.kind = ScoreStep.Kind.FACE
		face.source = ScoreStep.Source.DIE
		face.die_id = die.id
		face.amount = outcome.face_points[die.id]
		steps.append(face)
	# Phase 2: effect commands, grouped by on-screen reading order.
	for owner_id: StringName in _owner_order(run):
		for command: EffectCommand in outcome.result.commands:
			if command.owner_id != owner_id:
				continue
			var step: ScoreStep = _step_for(command)
			if step:
				steps.append(step)
	# Phase 3: stamp running totals so each beat can update its readout directly.
	for step: ScoreStep in steps:
		match step.kind:
			ScoreStep.Kind.FACE, ScoreStep.Kind.POINTS:
				points += step.amount
			ScoreStep.Kind.MULT:
				mult += step.amount
			ScoreStep.Kind.PERCENT:
				percent += step.amount
		step.points_after = points
		step.mult_after = mult
		step.percent_after = percent
	return steps

## Die-bound owners follow die positions (upgrade, then bonus); Jokers keep acquisition order.
static func _owner_order(run: MechanicsRun) -> Array[StringName]:
	var order: Array[StringName] = []
	for die: RunDie in run.dice:
		order.append(StringName("upgrade:" + String(die.id)))
		order.append(StringName("bonus:" + String(die.id)))
	for item: OwnedDefinition in run.owned:
		if item.definition is JokerDefinition:
			order.append(item.id)
	return order

## Translate one command into a beat; zero amounts and recognition policies stay silent.
static func _step_for(command: EffectCommand) -> ScoreStep:
	var step: ScoreStep = ScoreStep.new()
	step.owner_id = command.owner_id
	step.die_id = command.source_die_id
	step.source = source_of(command.owner_id)
	if command is ScoreDeltaCommand:
		var score: ScoreDeltaCommand = command as ScoreDeltaCommand
		step.amount = score.amount
		match score.channel:
			ScoreDeltaCommand.Channel.POINTS:
				step.kind = ScoreStep.Kind.POINTS
			ScoreDeltaCommand.Channel.MULT:
				step.kind = ScoreStep.Kind.MULT
			ScoreDeltaCommand.Channel.MULT_PERCENT:
				step.kind = ScoreStep.Kind.PERCENT
	elif command is RuntimeDeltaCommand:
		var runtime: RuntimeDeltaCommand = command as RuntimeDeltaCommand
		step.amount = runtime.amount
		match runtime.kind:
			RuntimeDeltaCommand.Kind.COINS:
				step.kind = ScoreStep.Kind.COINS
			RuntimeDeltaCommand.Kind.SELL_VALUE:
				step.kind = ScoreStep.Kind.SELL_VALUE
			RuntimeDeltaCommand.Kind.ACCUMULATED_MULT:
				step.kind = ScoreStep.Kind.STORED_MULT
			RuntimeDeltaCommand.Kind.VALIDATIONS:
				step.kind = ScoreStep.Kind.PLAYS
			RuntimeDeltaCommand.Kind.REROLLS:
				step.kind = ScoreStep.Kind.REROLLS
			_:
				return null
	else:
		return null
	return step if step.amount != 0 else null

## Read the owning family from the runtime identity prefix assigned by MechanicsRun.
static func source_of(owner_id: StringName) -> ScoreStep.Source:
	var text: String = String(owner_id)
	if text.begins_with("upgrade:"):
		return ScoreStep.Source.UPGRADE
	if text.begins_with("bonus:"):
		return ScoreStep.Source.BONUS
	return ScoreStep.Source.JOKER

## Beats for non-scoring events (round start, rolls): runtime rewards only, in reading order.
static func build_runtime(result: MechanicsEventResult, run: MechanicsRun) -> Array[ScoreStep]:
	var steps: Array[ScoreStep] = []
	for owner_id: StringName in _owner_order(run):
		for command: EffectCommand in result.commands:
			if command.owner_id == owner_id and command is RuntimeDeltaCommand:
				var step: ScoreStep = _step_for(command)
				if step:
					steps.append(step)
	return steps
