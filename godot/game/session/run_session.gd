extends RefCounted
class_name RunSession
## Host-side run logic around MechanicsRun: the D-016 route (per biome: an upgrade choice,
## regular rounds each followed by a shop, then a boss with no shop after it), rising
## targets (D-017), and the three upgrade offers of each choice (D-012). It owns the run's
## round and shop sessions, so their event IDs stay unique. No scene or node dependency.
## Bosses are plain rounds for now: the design has not defined their special rules.

# --- Constants ---

## Upgrades offered at each choice (D-012).
const OFFERS: int = 3

# --- Member variables ---

## Route length, purse, and target curve for this run.
var rules: RunRules
## Authoritative rules coordinator: dice, equipment, coins, and round state.
var mechanics: MechanicsRun
## Round logic for every round of the run.
var rounds: RoundSession
## Shop logic for every visit of the run.
var shop: ShopSession
## Seedable sampler for upgrade offers.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## The whole route, in order.
var stops: Array[RunStop] = []
## Content source for upgrade offers.
var _catalog: EffectsCatalog = EffectsCatalog.new()
## Position on the route; equal to `stops.size()` once the run is complete.
var _index: int = 0
## Offers of the current upgrade choice, sampled once so reopening it never rerolls them.
var _offers: Array[UpgradeDefinition] = []
## Whether the current upgrade choice has been committed.
var _upgrade_chosen: bool = false

# --- Static functions ---

## Lay out the D-016 route for a set of rules, with strictly rising round targets (D-017).
static func route(rules_: RunRules) -> Array[RunStop]:
	var result: Array[RunStop] = []
	var round_number: int = 0
	var target: float = 0.0
	for biome: int in range(1, rules_.biomes + 1):
		result.append(RunStop.new(RunStop.Kind.UPGRADE, biome, round_number + 1))
		for step: int in rules_.regular_rounds + 1:
			var boss: bool = step == rules_.regular_rounds
			round_number += 1
			# Rounding or a flat curve must never let a target stall (D-017).
			target = maxf(rules_.target_for(round_number), target + 1.0)
			result.append(RunStop.new(RunStop.Kind.ROUND, biome, round_number, boss, target))
			# A shop follows every regular round, including the one before the boss.
			if not boss:
				result.append(RunStop.new(RunStop.Kind.SHOP, biome, round_number + 1, step + 1 == rules_.regular_rounds))
	return result

# --- Member functions ---

## Start a run at its first stop, the opening upgrade choice. A zero seed keeps each
## generator's own random seed; any other value makes the whole run repeatable.
func _init(rules_: RunRules = null, shop_rules: ShopRules = null, seed_: int = 0) -> void:
	rules = rules_ if rules_ else RunRules.new()
	mechanics = MechanicsRun.new(rules.starting_coins)
	rounds = RoundSession.new(mechanics, seed_)
	rounds.coins_per_unused_play = rules.coins_per_unused_play
	rounds.coins_per_round = rules.coins_per_round
	shop = ShopSession.new(mechanics, shop_rules, seed_ + 1 if seed_ != 0 else 0)
	if seed_ != 0:
		rng.seed = seed_ + 2
	stops = route(rules)

## Where the run stands, or null once it is over.
func stop() -> RunStop:
	return null if is_over() else stops[_index]

## Whether a failed round ended the run (D-007).
func is_failed() -> bool:
	return mechanics.run_failed

## Whether the last boss was cleared.
func is_complete() -> bool:
	return _index >= stops.size()

## Whether nothing is left to play, by defeat or by victory.
func is_over() -> bool:
	return is_failed() or is_complete()

## The round being played, or the next one to play, so a host can present it ahead of
## time (under an upgrade choice, on a shop sign). Null once the run is over.
func coming_round() -> RunStop:
	if is_over():
		return null
	for index: int in range(_index, stops.size()):
		if stops[index].kind == RunStop.Kind.ROUND:
			return stops[index]
	return null

## Whether a stop is the run's last one: the final boss.
func is_last(stop_: RunStop) -> bool:
	return not stops.is_empty() and stop_ == stops[stops.size() - 1]

## The three upgrades of the current choice: distinct, and never one a die already wears.
## Empty anywhere but at an upgrade stop still waiting for its choice.
func upgrade_offers() -> Array[UpgradeDefinition]:
	var here: RunStop = stop()
	if not here or here.kind != RunStop.Kind.UPGRADE or _upgrade_chosen:
		return []
	if _offers.is_empty():
		var pool: Array[UpgradeDefinition] = []
		for upgrade: UpgradeDefinition in _catalog.upgrades:
			if not _wears(upgrade.id):
				pool.append(upgrade)
		for slot: int in mini(OFFERS, pool.size()):
			_offers.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return _offers.duplicate()

## Commit one of the current offers: it installs on the next ordinary die, for the rest of
## the run (D-012). Returns the reasons for a refusal, or nothing once it is installed.
func choose_upgrade(upgrade_id: StringName) -> PackedStringArray:
	for upgrade: UpgradeDefinition in upgrade_offers():
		if upgrade.id != upgrade_id:
			continue
		var errors: PackedStringArray = mechanics.install_upgrade(upgrade)
		if errors.is_empty():
			_upgrade_chosen = true
			_offers.clear()
		return errors
	return ["That upgrade is not on offer"]

## Move to the next stop once this one is done: the upgrade chosen, the round finished, or
## the shop left. Returns false, changing nothing, when the stop is still open or the run
## is over; a failed round awards no further stop (D-016).
func advance() -> bool:
	var here: RunStop = stop()
	if not here:
		return false
	if here.kind == RunStop.Kind.UPGRADE and not _upgrade_chosen:
		return false
	if here.kind == RunStop.Kind.ROUND and mechanics.round_active:
		return false
	_index += 1
	_upgrade_chosen = false
	return true

## Whether a die already wears this upgrade.
func _wears(upgrade_id: StringName) -> bool:
	for item: OwnedDefinition in mechanics.owned:
		if item.definition is UpgradeDefinition and item.definition.id == upgrade_id:
			return true
	return false
