extends RefCounted
class_name RunFixtures
## Named test builds shared by the debug hosts. Targets, coins, and sell values here are
## fixtures for trying the interfaces, not balance.

# --- Types ---

## One named fixture: equipment plus a first-round target sized to its strength.
class Build:
	extends RefCounted

	# --- Member variables ---

	## Label shown on debug controls.
	var title: String
	## Upgrades installed onto dice 1, 2, 3… in order.
	var upgrades: Array[StringName] = []
	## Bonus per die identity.
	var bonuses: Dictionary[StringName, StringName] = {}
	## Jokers in rack order.
	var jokers: Array[StringName] = []
	## First-round target; later rounds grow from it.
	var target: float = 100.0

	# --- Member functions ---

	## Declare a fixture in one readable expression.
	func _init(title_: String, upgrades_: Array[StringName], bonuses_: Dictionary[StringName, StringName], jokers_: Array[StringName], target_: float) -> void:
		title = title_
		upgrades = upgrades_
		bonuses = bonuses_
		jokers = jokers_
		target = target_

# --- Static functions ---

## Fixture builds, from a full chain showcase down to bare dice.
static func builds() -> Array[Build]:
	return [
		Build.new("Showcase", [&"all_for_one", &"odd_master", &"golden_touch"], {&"die_1": &"family_spirit", &"die_2": &"odd_charm", &"die_4": &"pair_partner", &"die_5": &"first_instinct"}, [&"match_master", &"odd_squad", &"momentum", &"extra_time"], 1500.0),
		Build.new("Starter", [&"jackpot"], {&"die_1": &"six_addict"}, [&"bipolarity"], 200.0),
		Build.new("Bare dice", [], {}, [], 100.0),
	]

## Create a run wearing a fixture build. Equipment errors are reported, never hidden.
static func equip(build: Build, coins: int) -> MechanicsRun:
	var catalog: EffectsCatalog = EffectsCatalog.new()
	var run: MechanicsRun = MechanicsRun.new(coins)
	var errors: PackedStringArray = []
	for id: StringName in build.upgrades:
		errors.append_array(run.install_upgrade(catalog.upgrade(id)))
	for die_id: StringName in build.bonuses:
		errors.append_array(run.equip_bonus(catalog.bonus(build.bonuses[die_id]), die_id, 2))
	for id: StringName in build.jokers:
		errors.append_array(run.add_joker(catalog.joker(id), 3))
	for message: String in errors:
		push_error("Fixture build: " + message)
	return run
