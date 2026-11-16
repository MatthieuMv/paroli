extends Node3D
class_name RoundInterface
## Playable round presentation: table, five dice, HUD, sound, and the scoring reveal.
## A host supplies an equipped RoundSession; this scene turns player intents into session
## calls and presents the committed results. Rules, randomness, and scores stay in the session.

# --- Types ---

## Presentation phase; dice can be selected only while CHOOSING.
enum Phase { IDLE, DEALING, CHOOSING, ROLLING, SCORING, FINISHED }

# --- Signals ---

## The player dismissed the result banner; the host decides what follows.
signal continue_requested(succeeded: bool)
## Input lock changed; hosts gate their own controls with it.
signal busy_changed(busy: bool)
## Private: the current throw has fully settled.
signal _throw_settled

# --- Constants ---

## Seconds between consecutive dice starting a throw, left to right.
const THROW_STAGGER: float = 0.07
## Moments within the die's 620 ms roll when it touches the felt after its first two arcs.
const BOUNCE_TIMES: PackedFloat32Array = [0.256, 0.438]
## Felt-space anchor (table local) for the back row's caption, just inside the left edge.
## Dice moved to the back row are the selection for the next play.
const PLAY_CAPTION: Vector3 = Vector3(-10.25, 0.0, -3.5)
## Front-row caption anchor; dice left there are the ones a manual roll rerolls.
const ROLL_CAPTION: Vector3 = Vector3(-10.25, 0.0, 3.5)

# --- Member variables ---

## Removes shake, springs, travel, and staggered timing everywhere, including the dice.
@export var reduced_motion: bool = false:
	set(value):
		reduced_motion = value
		if is_node_ready():
			_apply_motion()
## Reveal speed multiplier; die rolls keep their authored duration.
@export_range(0.5, 3.0, 0.25) var tempo: float = 1.0:
	set(value):
		tempo = value
		if is_node_ready():
			_sequence.tempo = value
## Silences sound effects.
@export var muted: bool = false:
	set(value):
		muted = value
		if is_node_ready():
			_audio.muted = value
## Explicit locale for names and captions; empty follows the game locale.
@export var locale: String = ""
## Shared table set: wallpaper, camera, table, and dice. Hosts may restyle its wallpaper.
@onready var stage: TableStage = $Stage
## Play selection and marker transfers: a die on its hold marker is selected for the play.
@onready var _hold: DiceHoldController = $HoldController
## Heads-up display.
@onready var _hud: RoundHud = $Interface/Hud
## Sound effects.
@onready var _audio: RoundAudio = $Audio
## Scoring reveal choreography.
@onready var _sequence: ScoreSequence = $Sequence
## Round logic supplied by the host.
var _session: RoundSession
## Native dice by permanent identity.
var _views: Dictionary[StringName, ParoliDie] = {}
## Glossary for names and captions.
var _words: KeywordCatalog = GameKeywords.new()
## Current presentation phase.
var _phase: Phase = Phase.IDLE
## Round number shown in captions; supplied by the host.
var _round_number: int = 1
## Last previewed category, so the plate only celebrates a change.
var _last_category: StringName
## Last known selection per die, to tell which die a controller change refers to.
var _chosen: Dictionary[ParoliDie, bool] = {}
## Dice still in the air for the current throw.
var _airborne: int = 0
## Whether the last finished round reached its target.
var _succeeded: bool = false
## Invalidates coroutines of a superseded round.
var _generation: int = 0

# --- Member functions ---

## Ready callback: place dice, connect modules, and frame the table.
func _ready() -> void:
	get_viewport().physics_object_picking = true
	_views = stage.views
	for die: ParoliDie in _views.values():
		die.rolled.connect(_on_die_rolled)
		die.hover_changed.connect(_on_die_hover.bind(die))
		_chosen[die] = false
	_hold.configure(stage.table, stage.dice())
	_hold.changed.connect(_on_hold_changed)
	_hud.roll_pressed.connect(_on_roll_pressed)
	_hud.play_pressed.connect(_on_play_pressed)
	_hud.continue_pressed.connect(_on_continue_pressed)
	_hud.hover_ticked.connect(_audio.play.bind(&"hover", 0, 0.0, 0.1))
	_sequence.setup(_hud, stage.camera, _audio, _views)
	_sequence.tempo = tempo
	_audio.muted = muted
	stage.backdrop_changed.connect(_on_backdrop_changed)
	_on_backdrop_changed()
	_apply_motion()
	get_viewport().size_changed.connect(_layout)
	_set_phase(Phase.IDLE)
	_layout()

## Begin a round on an equipped session. Returns false, changing nothing, when a throw or
## reveal is still playing or the session rejects the start. The opening throw then plays
## on its own; watch `busy_changed` or `is_busy()` for the moment input opens.
func start_round(session: RoundSession, round_number: int, target: float) -> bool:
	if is_busy():
		return false
	var started: MechanicsEventResult = session.begin(target)
	if not started.errors.is_empty():
		push_error("Round start rejected: " + "; ".join(started.errors))
		return false
	var opened: MechanicsEventResult = session.open()
	if not opened.errors.is_empty():
		push_error("Opening roll rejected: " + "; ".join(opened.errors))
		return false
	_generation += 1
	_session = session
	_round_number = round_number
	_last_category = &""
	_set_phase(Phase.DEALING)
	# Dice played last round are still consumed on the play row; bring every die back down.
	for die: ParoliDie in _views.values():
		_hold.return_to_roll(die)
	var run: MechanicsRun = session.run
	_hud.banner.dismiss()
	_hud.show_build(run, _words, locale)
	_hud.show_round(round_number, target, 0.0)
	_hud.show_allowances(run.validations_remaining, session.plays_granted, run.rerolls_remaining, session.rerolls_granted, false)
	_hud.show_coins(run.coins, false)
	UpgradePresentation.refresh(run, [], _views)
	_deal(started)
	return true

## Opening throw of all five dice, then round-start rewards, then the first choice.
func _deal(started: MechanicsEventResult) -> void:
	var generation: int = _generation
	await _throw(_session.all_ids())
	if generation != _generation:
		return
	_sequence.present_rewards(ScoreScript.build_runtime(started, _session.run))
	_set_phase(Phase.CHOOSING)

## Whether a throw or reveal currently locks player input.
func is_busy() -> bool:
	return _phase in [Phase.DEALING, Phase.ROLLING, Phase.SCORING]

## Space rolls, Enter plays or continues; the buttons remain the primary controls.
func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if not key or not key.pressed or key.echo:
		return
	if key.keycode == KEY_SPACE:
		_on_roll_pressed()
	elif key.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		if _phase == Phase.FINISHED:
			_hud.banner.dismiss()
			_on_continue_pressed()
		else:
			_on_play_pressed()
	else:
		return
	get_viewport().set_input_as_handled()

## Fit the HUD to the window, frame the table in the space it leaves, then align the docks.
## A host may park this scene outside the tree (during a shop visit); it lays out on return.
func _layout() -> void:
	if not is_inside_tree():
		return
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	var free: Rect2 = _hud.arrange(viewport)
	var pixels_per_unit: float = stage.frame(free, viewport)
	_hud.align_table(stage.columns(), pixels_per_unit, stage.camera.framed_rect.end.y, stage.project(PLAY_CAPTION), stage.project(ROLL_CAPTION))

## Re-entering the tree after being parked: the window may have changed meanwhile.
func _enter_tree() -> void:
	if is_node_ready():
		_layout.call_deferred()

## Manual roll of every die left on the roll row; spends one roll. Selected dice keep their value.
func _on_roll_pressed() -> void:
	var ids: Array[StringName] = _row_ids(false)
	if _phase != Phase.CHOOSING or ids.is_empty() or not _settled() or _session.run.rerolls_remaining <= 0:
		return
	var generation: int = _generation
	var result: MechanicsEventResult = _session.reroll(ids)
	if not result.errors.is_empty():
		push_warning("Roll rejected: " + "; ".join(result.errors))
		return
	_audio.play(&"button")
	_set_phase(Phase.ROLLING)
	_show_allowances(true)
	await _throw(ids)
	if generation != _generation:
		return
	_sequence.present_rewards(ScoreScript.build_runtime(result, _session.run))
	_hud.show_coins(_session.run.coins, false)
	_set_phase(Phase.CHOOSING)

## Play the selected dice, reveal the score, then continue or finish the round.
func _on_play_pressed() -> void:
	var selected: Array[StringName] = _row_ids(true)
	if _phase != Phase.CHOOSING or selected.is_empty() or not _settled():
		return
	var generation: int = _generation
	var coins_before: int = _session.run.coins
	var outcome: PlayOutcome = _session.play(selected)
	if not outcome.result.errors.is_empty():
		push_warning("Play rejected: " + "; ".join(outcome.result.errors))
		return
	_audio.play(&"button")
	_set_phase(Phase.SCORING)
	_show_allowances(true)
	_hud.show_coins(coins_before, false)
	await _sequence.play(outcome, ScoreScript.build(outcome, _session.run), _category_title(outcome.result.combination.category))
	if generation != _generation:
		return
	_hud.show_coins(_session.run.coins, false)
	if outcome.completed:
		_finish(outcome)
		return
	# The round continues: exactly the played dice reroll for free, re-entering on the roll row.
	for die_id: StringName in selected:
		_hold.return_to_roll(_views[die_id])
	var rolled: MechanicsEventResult = _session.automatic_roll(selected)
	if not rolled.errors.is_empty():
		push_error("Automatic roll rejected: " + "; ".join(rolled.errors))
		return
	_set_phase(Phase.ROLLING)
	await _throw(selected)
	if generation != _generation:
		return
	_sequence.present_rewards(ScoreScript.build_runtime(rolled, _session.run))
	_set_phase(Phase.CHOOSING)

## Present the round result and wait for the player.
func _finish(outcome: PlayOutcome) -> void:
	_succeeded = outcome.succeeded
	_set_phase(Phase.FINISHED)
	var eyebrow: String = " ".join(("%s %d" % [_words.render(&"round", {}, locale), _round_number]).to_upper().split(""))
	var figures: String = "%s / %s" % [Juice.number(roundf(outcome.score_after)), Juice.number(outcome.target)]
	if outcome.succeeded:
		var detail: String = figures
		if outcome.unused_play_coins > 0:
			detail += "\n%d unused → +%d coins" % [outcome.unused_plays, outcome.unused_play_coins]
		_hud.banner.present(true, eyebrow, "Round cleared!", detail, "Next round")
	else:
		_hud.banner.present(false, eyebrow, "Out of plays", figures, "Try again")

## Relay the banner action with the round result.
func _on_continue_pressed() -> void:
	_set_phase(Phase.IDLE)
	continue_requested.emit(_succeeded)

## Throw the given dice to their committed values, left to right, and wait until all settle.
func _throw(ids: Array[StringName]) -> void:
	_audio.play(&"roll")
	_hud.score.show_hint("Rolling…")
	_airborne = 0
	var order: int = 0
	for die_id: StringName in _views:
		if die_id not in ids:
			continue
		_airborne += 1
		var delay: float = 0.0 if reduced_motion else float(order) * THROW_STAGGER
		var value: int = _session.run.find_die(die_id).value
		if delay > 0.0:
			get_tree().create_timer(delay).timeout.connect(_launch.bind(_views[die_id], value))
		else:
			_launch(_views[die_id], value)
		order += 1
	if _airborne > 0:
		await _throw_settled

## Start one die's roll and schedule the knocks of its first two bounces.
func _launch(die: ParoliDie, value: int) -> void:
	die.effect_enabled = false
	die.cracks_enabled = false
	die.shine_enabled = false
	die.roll(value)
	if reduced_motion:
		return
	for index: int in BOUNCE_TIMES.size():
		get_tree().create_timer(BOUNCE_TIMES[index]).timeout.connect(_knock.bind(-5.0 * float(index), 0.07 - 0.04 * float(index)))

## One felt impact: a clack and a touch of shake.
func _knock(gain_db: float, trauma: float) -> void:
	_audio.play_clack(gain_db)
	stage.camera.add_trauma(trauma)

## Count settled dice; the last one releases the waiting throw.
func _on_die_rolled(_value: int) -> void:
	if _airborne <= 0:
		return
	_audio.play_clack(-12.0)
	_airborne -= 1
	if _airborne == 0:
		_throw_settled.emit()

## Select or deselect feedback, then refresh the pending play.
func _on_hold_changed() -> void:
	for die: ParoliDie in _chosen:
		var chosen: bool = _hold.is_held(die)
		if chosen == _chosen[die]:
			continue
		_chosen[die] = chosen
		# Announce only player toggles; automatic returns to the roll row stay quiet.
		if _phase == Phase.CHOOSING:
			_audio.play(&"die_hold" if chosen else &"die_release", die.get_index())
			if not reduced_motion:
				Juice.hop(die, 0.55)
	_refresh_preview()

## Passive hover: a small hop, a tick, and a pointing cursor on dice that can be toggled.
## Resting on a die also opens its sheet (upgrade and bonus) beside its column.
func _on_die_hover(hovered: bool, die: ParoliDie) -> void:
	_hud.inspect_die(_views.find_key(die), hovered and _phase == Phase.CHOOSING)
	var active: bool = hovered and _phase == Phase.CHOOSING and _hold.can_mutate(die)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if active else Input.CURSOR_ARROW)
	if active:
		_audio.play(&"hover", 0, 0.0, 0.1)
		if not reduced_motion:
			Juice.hop(die, 0.3)

## Change phase, lock or unlock the dice, and refresh everything that depends on it.
func _set_phase(phase: Phase) -> void:
	var was_busy: bool = is_busy()
	_phase = phase
	for die: ParoliDie in _views.values():
		die.interaction_enabled = phase == Phase.CHOOSING
	if phase != Phase.CHOOSING:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		_hud.dismiss_tooltip()
	_refresh_preview()
	if was_busy != is_busy():
		busy_changed.emit(is_busy())

## Show the pending play: combination with base values, eligibility cues, and legal actions.
func _refresh_preview() -> void:
	if _phase != Phase.CHOOSING:
		_hud.set_actions(false, false)
		_hud.mark_eligible([])
		return
	var selected: Array[StringName] = _row_ids(true)
	var to_roll: Array[StringName] = _row_ids(false)
	var settled: bool = _settled()
	var preview: PlayPreview = _session.preview(selected)
	if preview.combination:
		var category: StringName = preview.combination.category
		var changed: bool = category != _last_category
		_hud.score.show_combination(_category_title(category), preview.base_points, preview.base_mult, changed)
		if changed:
			_audio.play(&"combo", preview.combination.rank - 1, -3.0)
		_last_category = category
	else:
		_hud.score.show_hint("Select dice to play")
		_last_category = &""
	# Eligibility cues wait for dice to stop moving, as the upgrade particles do.
	var cue_selection: Array[StringName] = selected if settled else ([] as Array[StringName])
	var newly_eligible: int = _hud.mark_eligible(preview.eligible_owners if settled else ([] as Array[StringName]))
	if newly_eligible > 0:
		_audio.play(&"pip", 1 + newly_eligible, -2.0)
	# Dice forming the recognized combination shine; extra selected dice do not.
	var members: Array[StringName] = preview.combination.members if preview.combination and settled else ([] as Array[StringName])
	UpgradePresentation.refresh(_session.run, cue_selection, _views)
	for die_id: StringName in _views:
		var die: ParoliDie = _views[die_id]
		# Round rule: an upgrade's particles show only on a die selected for the play whose
		# reward will apply. Rewards earned from the roll row stay silent until the reveal.
		if die_id not in cue_selection:
			die.effect_enabled = false
		die.shine_enabled = die_id in members
		# Cracks mark a die that hurts the play or adds nothing to it.
		die.cracks_enabled = settled and (die_id in preview.penalized_dice or die_id in preview.idle_dice)
	_hud.set_actions(settled and not to_roll.is_empty() and _session.run.rerolls_remaining > 0, settled and not selected.is_empty())

## Push the session's allowances to the buttons.
func _show_allowances(animate: bool) -> void:
	var run: MechanicsRun = _session.run
	_hud.show_allowances(run.validations_remaining, _session.plays_granted, run.rerolls_remaining, _session.rerolls_granted, animate)

## Dice on one row, in run order: the play row is the selection, the roll row is the rest.
func _row_ids(play_row: bool) -> Array[StringName]:
	var ids: Array[StringName] = []
	for die_id: StringName in _views:
		if _hold.is_held(_views[die_id]) == play_row:
			ids.append(die_id)
	return ids

## True when no die is rolling or sliding.
func _settled() -> bool:
	for die: ParoliDie in _views.values():
		if die.is_rolling() or (not die.is_consumed() and not _hold.can_mutate(die)):
			return false
	return true

## Localized combination name from the shared glossary.
func _category_title(category: StringName) -> String:
	return _words.render(StringName("combination." + String(category)), {}, locale)

## The wallpaper changed: recolor the marks the HUD draws straight on the wall.
func _on_backdrop_changed() -> void:
	_hud.set_wall_ink(stage.wall_ink())

## Push the reduced-motion preference into dice, camera, HUD, and the reveal.
func _apply_motion() -> void:
	stage.reduced_motion = reduced_motion
	_hud.reduced_motion = reduced_motion
	_sequence.reduced_motion = reduced_motion
