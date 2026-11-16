extends Node
class_name ScoreSequence
## Plays a committed play as an escalating reveal: each source reacts in turn, readouts step,
## pitch climbs, then the total lands and banks. It only presents values the session committed;
## the final score stays hidden until the last beat (D-023).

# --- Constants ---

## Seconds between the first beats of a chain, before acceleration.
const FIRST_INTERVAL: float = 0.36
## Each beat is this much shorter than the last, so long chains gather speed.
const ACCELERATION: float = 0.93
## Fastest beat, keeping every source readable.
const SHORTEST_INTERVAL: float = 0.15
## World-space height above a die's floor origin where its popup appears.
const DIE_POPUP_HEIGHT: float = 3.3

# --- Member variables ---

## Playback speed multiplier for every beat; die animations keep their own timing.
var tempo: float = 1.0
## Collapses waits and removes shake; order and values are unchanged.
var reduced_motion: bool = false
## Widgets that display the reveal.
var _hud: RoundHud
## Table camera, for shake and die-to-screen projection.
var _camera: StageCamera
## Sound effects.
var _audio: RoundAudio
## Native dice by permanent identity.
var _views: Dictionary[StringName, ParoliDie] = {}

# --- Member functions ---

## Receive collaborators from the owning round interface once its scene is ready.
func setup(hud: RoundHud, camera: StageCamera, audio: RoundAudio, views: Dictionary[StringName, ParoliDie]) -> void:
	_hud = hud
	_camera = camera
	_audio = audio
	_views = views

## Play the whole reveal for one committed play. Await it; input stays locked by the caller.
func play(outcome: PlayOutcome, steps: Array[ScoreStep], title: String) -> void:
	var result: MechanicsEventResult = outcome.result
	# Commit beat: the plate locks in with the base values the player already saw.
	_hud.score.show_combination(title, outcome.category_points, outcome.category_mult, true)
	_audio.play(&"combo", result.combination.rank - 1)
	await _beat(0.42)
	# Chain: one source per beat, accelerating, with pitch climbing the ladder.
	for index: int in steps.size():
		_present(steps[index], index)
		await _beat(_interval(index))
	# Percentages fold into Mult once, after every flat bonus (additive pool).
	if result.mult_percent != 0:
		await _beat(0.12)
		_hud.score.merge_percent(result.final_mult)
		_hud.popup(_hud.score.tile_anchor(true) + Vector2(0.0, 106.0) * _hud.scale, "×" + Juice.number(1.0 + float(result.mult_percent) / 100.0), &"mult", 34, 30.0)
		_audio.play(&"tick_percent", steps.size())
		_camera.add_trauma(0.22)
		await _beat(0.52)
	await _beat(0.2)
	await _reveal_total(outcome)
	await _consume(outcome)
	if outcome.succeeded:
		await _celebrate(outcome)
	elif outcome.completed:
		_audio.play(&"lose")
		await _beat(1.0)
	_hud.score.show_hint("")

## Show rewards from non-scoring events (round start, rolls) without blocking play.
func present_rewards(steps: Array[ScoreStep]) -> void:
	for index: int in steps.size():
		_present(steps[index], index)

## Final product: count up, punch, then bank it or let a zero drop away.
func _reveal_total(outcome: PlayOutcome) -> void:
	var raw: float = outcome.raw_score
	var credited: float = outcome.score_after - outcome.score_before
	# Bigger totals hit harder, on a logarithmic scale so early rounds still land.
	var weight: float = clampf(log(maxf(absf(raw), 1.0)) / log(10.0) / 3.0, 0.3, 1.3)
	_hud.score.reveal_total(raw, 0.5 / tempo)
	if raw > 0.0:
		_audio.play(&"total")
		_camera.add_trauma(0.22 + 0.3 * weight)
		_count_ticks(8, 0.5)
	else:
		_audio.play(&"womp")
	await _beat(0.62)
	_hud.score.punch_total(weight)
	await _beat(0.46)
	if credited > 0.0:
		_audio.play(&"fly")
		_hud.score.fly_total(_hud.goal.score_anchor(), 0.4 / tempo)
		await _beat(0.4)
		_audio.play(&"bank")
		_hud.goal.add_score(outcome.score_after, 0.55 / tempo)
		_count_ticks(7, 0.5)
		await _beat(0.8)
	else:
		_hud.score.drop_total(0.35 / tempo)
		await _beat(0.55)

## Played dice burst with their own activation, left to right.
func _consume(outcome: PlayOutcome) -> void:
	var longest: float = 0.0
	var index: int = 0
	for die_id: StringName in outcome.selected:
		var die: ParoliDie = _views[die_id]
		var delay: float = 0.0 if reduced_motion else float(index) * 0.07
		get_tree().create_timer(delay).timeout.connect(_activate.bind(die, index))
		longest = maxf(longest, delay + DieLibrary.activation_duration(die.effect))
		index += 1
	# Activations run at their authored speed; rolling a die again would cut its particles.
	await get_tree().create_timer(0.05 if reduced_motion else longest + 0.1).timeout

## Start one die's native consume animation with a soft puff. The selection ring leaves
## with the die; the controller clears the selection itself once the die returns.
func _activate(die: ParoliDie, index: int) -> void:
	die.set_hold_highlight(false)
	die.effect_enabled = true
	die.activate()
	_audio.play(&"consume", 0, -float(index), 0.12)

## Stamp the goal, then turn each unused play into coins.
func _celebrate(outcome: PlayOutcome) -> void:
	_hud.goal.celebrate("CLEARED")
	_audio.play(&"stamp")
	_audio.play(&"win")
	_camera.add_trauma(0.5)
	await _beat(0.8)
	if outcome.unused_play_coins > 0:
		var each: int = outcome.unused_play_coins / maxi(outcome.unused_plays, 1)
		for index: int in outcome.unused_plays:
			var at: Vector2 = _hud.spend_play_pip()
			_hud.popup(at, Juice.signed(float(each)), &"coins", 28, -44.0, true)
			_hud.add_coins(each)
			_audio.play(&"coin", index * 2)
			await _beat(0.3)
	await _beat(0.45)

## One beat: the source reacts, a number pops beside it, and the matching readout steps.
func _present(step: ScoreStep, index: int) -> void:
	var at: Vector2 = _react(step)
	var drift: float = 46.0 if _hud.owner_drops(step.owner_id) else -54.0
	var amount: String = Juice.signed(float(step.amount))
	# Escalation: each beat lands a little harder and prints a little larger.
	var heat: float = minf(1.0 + float(index) * 0.09, 1.9)
	var font_size: int = 28 + mini(index, 8)
	match step.kind:
		ScoreStep.Kind.FACE, ScoreStep.Kind.POINTS:
			_hud.popup(at, amount, &"points", font_size, drift)
			_hud.score.set_points(step.points_after, heat)
			_audio.play(&"tick_points", index)
		ScoreStep.Kind.MULT:
			_hud.popup(at, "%s %s" % [amount, _hud.words.render(&"mult", {}, _hud.locale)], &"mult", font_size, drift)
			_hud.score.set_mult(float(step.mult_after), heat)
			_audio.play(&"tick_mult", index)
			_camera.add_trauma(0.1)
		ScoreStep.Kind.PERCENT:
			_hud.popup(at, amount + "%", &"mult", font_size + 4, drift)
			_hud.score.set_percent(step.percent_after, heat)
			_audio.play(&"tick_percent", index)
			_camera.add_trauma(0.14)
		ScoreStep.Kind.COINS:
			_hud.popup(at, amount, &"coins", 28, drift, true)
			_hud.add_coins(step.amount)
			_audio.play(&"coin", mini(index, 4))
		ScoreStep.Kind.SELL_VALUE:
			_hud.popup(at, amount, &"coins", 24, drift, true)
			_audio.play(&"coin", 0, -4.0)
		ScoreStep.Kind.STORED_MULT:
			_hud.popup(at, "%s %s" % [amount, _hud.words.render(&"mult", {}, _hud.locale)], &"mult", 24, drift)
			_audio.play(&"tick_mult", 0, -4.0)
		ScoreStep.Kind.PLAYS:
			_hud.popup(at, "%s %s" % [amount, _hud.words.render(&"validation", {}, _hud.locale)], &"tempo", 24, drift)
			_audio.play(&"pip", 2)
		ScoreStep.Kind.REROLLS:
			_hud.popup(at, "%s %s" % [amount, _hud.words.render(&"roll", {}, _hud.locale).to_lower()], &"tempo", 24, drift)
			_audio.play(&"pip", 2)

## Animate the reacting element and return the window-pixel point for its popup.
func _react(step: ScoreStep) -> Vector2:
	var die: ParoliDie = _views.get(step.die_id)
	match step.source:
		ScoreStep.Source.DIE:
			return _hop(die, 0.8)
		ScoreStep.Source.UPGRADE:
			return _hop(die, 1.15)
		ScoreStep.Source.BONUS:
			_hud.trigger_owner(step.owner_id, 1.0)
			_hop(die, 0.45)
		ScoreStep.Source.JOKER:
			_hud.trigger_owner(step.owner_id, 1.0)
	return _hud.owner_anchor(step.owner_id)

## Hop a die (unless motion is reduced) and return the point above its head.
func _hop(die: ParoliDie, strength: float) -> Vector2:
	if not die:
		return Vector2.ZERO
	if not reduced_motion and not die.is_consumed():
		Juice.hop(die, strength)
	return _camera.unproject_position(die.global_position + Vector3(0.0, DIE_POPUP_HEIGHT, 0.0))

## Rising run of small ticks under a count-up.
func _count_ticks(count: int, seconds: float) -> void:
	if reduced_motion:
		return
	for index: int in count:
		var delay: float = seconds / tempo * float(index) / float(count)
		get_tree().create_timer(delay).timeout.connect(_audio.play.bind(&"count", index, 0.0, 0.0))

## Interval before the next beat of a chain.
func _interval(index: int) -> float:
	return maxf(SHORTEST_INTERVAL, FIRST_INTERVAL * pow(ACCELERATION, float(index)))

## Wait one tempo-scaled beat; reduced motion keeps a short, even cadence.
func _beat(seconds: float) -> void:
	var wait: float = minf(seconds, 0.12) if reduced_motion else seconds / tempo
	await get_tree().create_timer(maxf(wait, 0.01)).timeout
