extends SceneTree
## Verify visual identity, real rule eligibility, preview purity, and independent particle gating.

# --- Constants ---

## Production die scene is used to catch material/pose regressions in the bridge.
const DIE: PackedScene = preload("res://die/die.tscn")

# --- Member functions ---

## Defer scene construction until the tree is ready.
func _initialize() -> void:
	_run.call_deferred()

## Compare previews to committed commands across every upgrade and several selections/histories.
func _run() -> void:
	var catalog: EffectsCatalog = EffectsCatalog.new()
	var colors: Array[StringName] = []
	var effects: Array[StringName] = []
	for upgrade: UpgradeDefinition in catalog.upgrades:
		assert(String(upgrade.palette_color) in GameColors.PALETTE_ORDER)
		assert(upgrade.palette_color != &"Chalk" and upgrade.palette_color not in colors)
		assert(String(upgrade.vfx_id) in DieLibrary.effect_ids() and upgrade.vfx_id not in effects)
		colors.append(upgrade.palette_color)
		effects.append(upgrade.vfx_id)
		for scenario: int in 8:
			_check_prediction(upgrade, scenario)
	assert(colors.size() == GameColors.PALETTE_ORDER.size() - 1)
	_check_guardian(catalog)
	_check_zero_reward(catalog)
	print("PASS: all upgrade identities, 112 preview/commit comparisons, Guardian support, zero rewards, preview purity, VFX gating.")
	quit()

## Construct a live sandbox with a completed opening roll and no rewards applied yet.
func _make_run(upgrade: UpgradeDefinition, bonus: BonusDefinition = null) -> MechanicsRun:
	var run: MechanicsRun = MechanicsRun.new()
	assert(run.install_upgrade(upgrade).is_empty())
	if bonus:
		assert(run.equip_bonus(bonus, &"die_1", 0).is_empty())
	assert(run.start_round(&"start", 1000000.0).errors.is_empty())
	assert(run.roll(&"opening", {&"die_1": 0, &"die_2": 0, &"die_3": 0, &"die_4": 0, &"die_5": 0}, EffectContext.RollKind.OPENING).errors.is_empty())
	return run

## Synthetic snapshots cover matching, straights, parity, sixes, and accumulated histories.
func _check_prediction(upgrade: UpgradeDefinition, scenario: int) -> void:
	var run: MechanicsRun = _make_run(upgrade)
	var selected: Array[StringName] = []
	for index: int in run.dice.size():
		var die: RunDie = run.dice[index]
		die.value = (index + scenario) % 6 + 1 if scenario % 2 == 0 else scenario % 6 + 1
		if scenario == 3:
			die.value = 2 if index < 2 else 3
		if scenario == 5 or index < 4:
			selected.append(die.id)
	run.dice[0].previous_validated_value = scenario % 7
	run.dice[0].rerolls_since_validation = scenario % 3
	run.dice[0].crescendo_percent = 50 if scenario > 3 else 0
	var before: int = run.dice[0].crescendo_percent
	var preview: Array[StringName] = run.preview_active_upgrades(selected)
	assert(run.preview_active_upgrades(selected) == preview)
	assert(run.coins == 0 and run.previous_validations == 0 and run.round_score == 0.0)
	assert(run.dice[0].crescendo_percent == before)
	assert(run.validations_remaining == 3)
	var committed: MechanicsEventResult = run.validate_dice(&"play", selected, 10, 1)
	assert(committed.errors.is_empty())
	var contributes: bool = false
	for command: EffectCommand in committed.commands:
		if command is ScoreDeltaCommand:
			contributes = contributes or (command as ScoreDeltaCommand).amount != 0
		elif command is RuntimeDeltaCommand:
			contributes = contributes or (command as RuntimeDeltaCommand).amount != 0
	assert((&"die_1" in preview) == contributes)
	assert(run.preview_active_upgrades(selected).is_empty(), "Pending automatic rolls must suppress the next preview")

## Guardian intentionally lights up while held, and never while selected for play.
func _check_guardian(catalog: EffectsCatalog) -> void:
	var run: MechanicsRun = _make_run(catalog.upgrade(&"guardian"))
	var die: ParoliDie = DIE.instantiate() as ParoliDie
	root.add_child(die)
	var views: Dictionary[StringName, ParoliDie] = {&"die_1": die}
	UpgradePresentation.refresh(run, [&"die_2"], views)
	assert(die.palette_color == "Sky" and die.effect == "bubbles" and die.effect_enabled)
	var position_before: Vector3 = die.position
	UpgradePresentation.refresh(run, [&"die_1", &"die_2"], views)
	assert(not die.effect_enabled and die.effect == "bubbles" and die.palette_color == "Sky")
	assert(die.position == position_before and not die.is_consumed())
	UpgradePresentation.refresh(run, [], views)
	assert(not die.effect_enabled)
	run.dice[1].value = 6
	assert(run.preview_active_upgrades([&"die_2"]).is_empty())
	die.free()

## A matching rule can emit a zero amount; this must not advertise a reward.
func _check_zero_reward(catalog: EffectsCatalog) -> void:
	var run: MechanicsRun = _make_run(catalog.upgrade(&"relentless"), catalog.bonus(&"one_or_nothing"))
	assert(run.preview_active_upgrades([&"die_1"]).is_empty())
	run.dice[0].rerolls_since_validation = 1
	assert(run.preview_active_upgrades([&"die_1"]) == [&"die_1"])
	assert(run.preview_active_upgrades([&"unknown"]).is_empty())
	assert(run.preview_active_upgrades([&"die_1", &"die_1"]).is_empty())
