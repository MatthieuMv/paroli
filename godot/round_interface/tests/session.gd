extends SceneTree
## Headless check of the round session and reveal ordering, with no scene dependency.

# --- Member functions ---

## Run after the scene tree is ready so script classes are registered.
func _initialize() -> void:
	_run.call_deferred()

## Exercise preview boundaries, a committed chain, running totals, and round completion.
func _run() -> void:
	var catalog: EffectsCatalog = EffectsCatalog.new()
	var run: MechanicsRun = MechanicsRun.new(3)
	assert(run.install_upgrade(catalog.upgrade(&"all_for_one")).is_empty())
	assert(run.equip_bonus(catalog.bonus(&"family_spirit"), &"die_1", 2).is_empty())
	assert(run.equip_bonus(catalog.bonus(&"pocket_money"), &"die_2", 2).is_empty())
	assert(run.add_joker(catalog.joker(&"match_master"), 3).is_empty())
	assert(run.add_joker(catalog.joker(&"extra_time"), 3).is_empty())
	var session: RoundSession = RoundSession.new(run, 7)
	session.coins_per_unused_play = 2
	assert(session.begin(100000.0).errors.is_empty())
	assert(session.plays_granted == 4, "Overtime adds a play at round start")
	assert(session.rerolls_granted == 3)
	assert(session.preview([&"die_1"]).eligible_owners.is_empty(), "No preview before the opening roll")
	assert(session.open().errors.is_empty())
	# Force a known table state: die_1 and die_2 show 3, die_3 shows 5.
	run.find_die(&"die_1").value = 3
	run.find_die(&"die_2").value = 3
	run.find_die(&"die_3").value = 5
	var selected: Array[StringName] = [&"die_1", &"die_2", &"die_3"]
	var preview: PlayPreview = session.preview(selected)
	assert(preview.combination.category == &"pair")
	assert(preview.base_points == 10 and preview.base_mult == 2, "Preview shows base values only")
	for owner_id: StringName in [&"upgrade:die_1", &"bonus:die_1", &"bonus:die_2", &"joker:match_master"]:
		assert(owner_id in preview.eligible_owners, "Missing eligibility cue: " + String(owner_id))
	assert(&"joker:extra_time" not in preview.eligible_owners)
	assert(preview.penalized_dice.is_empty())
	var idle: Array[StringName] = [&"die_3"]
	assert(preview.idle_dice == idle, "The extra 5 adds nothing to a Pair of 3s here")
	# Payday needs its die in the combination: as an extra, that die is idle too.
	run.find_die(&"die_2").value = 5
	run.find_die(&"die_3").value = 3
	var benched: Array[StringName] = [&"die_2"]
	assert(session.preview(selected).idle_dice == benched, "Payday pays nothing outside the combination")
	run.find_die(&"die_2").value = 3
	run.find_die(&"die_3").value = 5
	assert(session.preview([&"die_3"]).idle_dice.is_empty(), "A lone die is its own combination")
	assert(run.round_score == 0.0 and run.validations_remaining == 4, "Preview never commits")
	var outcome: PlayOutcome = session.play(selected)
	assert(outcome.result.errors.is_empty())
	assert(outcome.face_points == {&"die_1": 3, &"die_2": 3})
	var steps: Array[ScoreStep] = ScoreScript.build(outcome, run)
	assert(steps[0].kind == ScoreStep.Kind.FACE and steps[1].kind == ScoreStep.Kind.FACE)
	assert(steps[0].points_after == 13 and steps[1].points_after == 16)
	var last: ScoreStep = steps[steps.size() - 1]
	assert(last.source == ScoreStep.Source.JOKER, "Jokers resolve after die-bound effects")
	assert(last.points_after == outcome.result.points)
	assert(last.mult_after == outcome.result.flat_mult)
	assert(last.percent_after == outcome.result.mult_percent)
	# (10 + 6 + 30 Matchmaker) × (2 + 2 Copycat) × 1.25 All for one.
	assert(is_equal_approx(outcome.raw_score, 46.0 * 4.0 * 1.25))
	assert(run.coins == 5, "Payday pays its member die")
	var coin_steps: int = 0
	for step: ScoreStep in steps:
		if step.kind == ScoreStep.Kind.COINS:
			coin_steps += 1
			assert(step.source == ScoreStep.Source.BONUS and step.die_id == &"die_2")
	assert(coin_steps == 1)
	assert(not outcome.completed)
	assert(session.automatic_roll(selected).errors.is_empty())
	# A fresh round with a reachable target converts unused plays into fixture coins.
	var easy: RoundSession = RoundSession.new(MechanicsRun.new(), 3)
	easy.coins_per_unused_play = 2
	assert(easy.begin(5.0).errors.is_empty())
	assert(easy.open().errors.is_empty())
	var win: PlayOutcome = easy.play([&"die_1"])
	assert(win.succeeded and win.completed and win.unused_plays == 2)
	assert(win.unused_play_coins == 4 and easy.run.coins == 4)
	assert(ScoreScript.build(win, easy.run).size() == 1, "A bare single die only scores its face")
	print("PASS: round session preview boundary, reveal order, running totals, completion.")
	quit()
