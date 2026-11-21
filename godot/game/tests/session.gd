extends SceneTree
## Headless check of run logic: the D-016 route, rising targets (D-017), upgrade offers and
## commitment (D-012), and the end of a run by victory or by a failed round (D-007).

# --- Member functions ---

## Run after the scene tree is ready so script classes are registered.
func _initialize() -> void:
	_run.call_deferred()

## Trace the full route with the default rules, then the edges around it.
func _run() -> void:
	create_timer(20.0).timeout.connect(_abort)
	var rules: RunRules = load("res://game/session/run_rules.tres") as RunRules
	# Route shape: five biomes of upgrade, round, shop, round, shop, boss.
	var route: Array[RunStop] = RunSession.route(rules)
	var kinds: Dictionary[RunStop.Kind, int] = {RunStop.Kind.UPGRADE: 0, RunStop.Kind.ROUND: 0, RunStop.Kind.SHOP: 0}
	var bosses: int = 0
	var last_target: float = 0.0
	for index: int in route.size():
		var here: RunStop = route[index]
		kinds[here.kind] += 1
		if here.kind == RunStop.Kind.ROUND:
			assert(here.target > last_target, "Every round asks for more than the one before (D-017)")
			last_target = here.target
			assert(here.round_number == kinds[RunStop.Kind.ROUND])
			if here.boss:
				bosses += 1
				var after_boss: RunStop = route[index + 1] if index + 1 < route.size() else null
				assert(not after_boss or (after_boss.kind == RunStop.Kind.UPGRADE and after_boss.biome == here.biome + 1), "No shop follows a boss")
			else:
				var after_round: RunStop = route[index + 1]
				assert(after_round.kind == RunStop.Kind.SHOP and after_round.round_number == here.round_number + 1, "A shop follows every regular round")
				assert(after_round.boss == route[index + 2].boss, "The shop knows whether the boss is next")
	assert(kinds[RunStop.Kind.UPGRADE] == 5 and kinds[RunStop.Kind.SHOP] == 10 and kinds[RunStop.Kind.ROUND] == 15 and bosses == 5, "D-016 full-path totals")
	assert(route[0].kind == RunStop.Kind.UPGRADE and route[route.size() - 1].boss, "A run opens on an upgrade and ends on a boss")
	assert(route[1].target == rules.first_target and is_equal_approx(rules.target_for(3), 210.0), "Targets round to two significant digits")
	# A flat curve still rises, one point at a time.
	var flat: RunRules = RunRules.new()
	flat.first_target = 1.0
	flat.target_growth = 1.0
	var flat_route: Array[RunStop] = RunSession.route(flat)
	assert(flat_route[1].target == 1.0 and flat_route[flat_route.size() - 1].target == 15.0)
	# Opening choice: three distinct offers, stable until one is committed.
	var run: RunSession = RunSession.new(flat, null, 7)
	assert(run.mechanics.coins == flat.starting_coins and run.rounds.coins_per_unused_play == flat.coins_per_unused_play and run.rounds.coins_per_round == flat.coins_per_round)
	var offers: Array[UpgradeDefinition] = run.upgrade_offers()
	assert(offers.size() == 3 and offers[0] != offers[1] and offers[1] != offers[2] and offers[0] != offers[2])
	assert(run.upgrade_offers() == offers, "Asking again never rerolls the offers")
	assert(not run.advance(), "The route waits for the upgrade choice")
	assert(not run.choose_upgrade(&"not_an_upgrade").is_empty())
	assert(run.choose_upgrade(offers[1].id).is_empty())
	assert(run.mechanics.find_owned(&"upgrade:die_1").definition == offers[1], "The first choice lands on the first die")
	assert(run.upgrade_offers().is_empty() and not run.choose_upgrade(offers[0].id).is_empty(), "One upgrade per choice")
	# Walk the whole route, clearing every round with a single die.
	var taken: Array[StringName] = [offers[1].id]
	var visited: int = 0
	while not run.is_over():
		var here: RunStop = run.stop()
		visited += 1
		match here.kind:
			RunStop.Kind.UPGRADE:
				if here.biome > 1:
					var choice: Array[UpgradeDefinition] = run.upgrade_offers()
					assert(choice.size() == 3)
					for upgrade: UpgradeDefinition in choice:
						assert(upgrade.id not in taken, "A worn upgrade is never offered again")
					assert(run.choose_upgrade(choice[0].id).is_empty())
					taken.append(choice[0].id)
					assert(run.mechanics.find_owned(StringName("upgrade:die_%d" % here.biome)).definition == choice[0], "Upgrades install in die order")
			RunStop.Kind.ROUND:
				assert(run.rounds.begin(here.target).errors.is_empty() and run.rounds.open().errors.is_empty())
				assert(not run.advance(), "The route waits for the round to end")
				assert(run.mechanics.round_target == here.target)
				# Any play clears a one-point target, whatever the dice show.
				run.mechanics.round_target = 1.0
				var outcome: PlayOutcome = run.rounds.play([&"die_1"])
				assert(outcome.succeeded and not run.mechanics.round_active)
			RunStop.Kind.SHOP:
				run.shop.open()
				assert(run.upgrade_offers().is_empty())
		assert(run.advance())
	assert(visited == route.size() and run.is_complete() and not run.is_failed() and run.stop() == null)
	assert(taken.size() == 5 and not run.advance(), "Nothing follows the last boss")
	# A failed round ends the run on the spot: no shop, no further stop.
	var doomed: RunSession = RunSession.new(rules, null, 3)
	assert(doomed.choose_upgrade(doomed.upgrade_offers()[0].id).is_empty() and doomed.advance())
	assert(doomed.rounds.begin(1000000.0).errors.is_empty() and doomed.rounds.open().errors.is_empty())
	for play: int in 3:
		var outcome: PlayOutcome = doomed.rounds.play([&"die_1"])
		assert(outcome.result.errors.is_empty())
		if not outcome.completed:
			assert(doomed.rounds.automatic_roll([&"die_1"]).errors.is_empty())
	assert(doomed.is_failed() and doomed.is_over() and not doomed.is_complete())
	assert(doomed.stop() == null and not doomed.advance(), "A failed run awards no next stop")
	print("PASS: run route, rising targets, upgrade offers and order, full traversal, failure.")
	quit()

## Watchdog: a failed assertion stops the walk; report it instead of hanging.
func _abort() -> void:
	push_error("Run session check stalled")
	quit(1)
