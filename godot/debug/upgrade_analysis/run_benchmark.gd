extends SceneTree
## Headless paired-seed experiment. The debug policy proposes actions; game sessions commit them.

# --- Constants ---

## Shared policy script with route-specific shopping and rolling preferences.
const Policy: Script = preload("res://debug/upgrade_analysis/run_policy.gd")
## Controlled experiments build an independent catalog for each worker.
const Trials: Script = preload("res://debug/upgrade_analysis/run_trials.gd")

# --- Member variables ---

## A separate immutable catalog per batch, shared by all games and shops in the batch.
var _catalog: EffectsCatalog = EffectsCatalog.new()
## Explicit test curve, defaulting to the game rules.
var _rules: RunRules = preload("res://game/session/run_rules.tres").duplicate() as RunRules
## Use the same Inspector-authored shop settings as the playable game.
var _shop_rules: ShopRules = preload("res://shop_interface/session/shop_rules.tres")
## Strategy and cached recognition results for this batch.
var _policy: Policy
## Failure must abort the batch even when Godot reports a script error with a zero exit code.
var _failed: bool = false
## Extra information for the current seed. Each record is independently aggregatable.
var _stats: Dictionary[String, int] = {}
## Actual scores by category in biomes four and five, with a denominator even for failed rounds.
var _late: Dictionary[StringName, float] = {}

# --- Member functions ---

## One output record per seed; the Python driver verifies completeness before publishing results.
func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() not in [5, 6] or not args[0] in Policy.BUILDS or not args[1] in ["supplied", "draft"] or not args[3].is_valid_int() or not args[4].is_valid_int() or args[3].to_int() <= 0 or args[4].to_int() <= 0:
		printerr("Expected -- route supplied|draft variant first_positive_seed count [target_growth]")
		quit(1)
		return
	if args.size() == 6:
		if not args[5].is_valid_float() or args[5].to_float() < 1.0:
			quit(1)
			return
		_rules.target_growth = args[5].to_float()
	_policy = Policy.new(args[0])
	if args[2] == "chase-four" and args[0] != "five_of_a_kind":
		printerr("The four-match chase compares Five of a Kind policies")
		quit(1)
		return
	_policy.chase_four = args[2] == "chase-four"
	var error: String = Trials.configure(_catalog, args[2], _policy.core)
	if not error.is_empty():
		printerr(error)
		quit(1)
		return
	for seed_number: int in range(args[3].to_int(), args[3].to_int() + args[4].to_int()):
		_simulate(seed_number, args[1] == "supplied")
		if _failed:
			quit(1)
			return
		print(JSON.stringify({"seed": seed_number, "stats": _stats, "late": _late}))
	quit()

## Paired seeds reuse dice and shop streams. In the supplied fixture only, condition the opening offer on its core upgrade.
func _simulate(seed_number: int, supplied: bool) -> void:
	var session: RunSession = RunSession.new(_rules, _shop_rules, seed_number, _catalog)
	_stats = {}
	_late = {}
	if supplied:
		var retry: int = 0
		while not _catalog.upgrade(_policy.core[0]) in session.upgrade_offers():
			retry += 1
			session = RunSession.new(_rules, _shop_rules, seed_number, _catalog)
			session.rng.seed = seed_number + 2 + 1000003 * retry
		var shop: ShopSession = session.shop
		_require(session.mechanics.equip_bonus(_catalog.bonus(_policy.core[1]), &"die_1", shop.sell_value_for(shop.price_of(ShopSession.BONUS))).is_empty())
		_require(session.mechanics.add_joker(_catalog.joker(_policy.core[2]), shop.sell_value_for(shop.price_of(ShopSession.JOKER))).is_empty())
	while not session.is_over() and not _failed:
		var stop: RunStop = session.stop()
		match stop.kind:
			RunStop.Kind.UPGRADE:
				var offers: Array[UpgradeDefinition] = session.upgrade_offers()
				var best: UpgradeDefinition = offers[0]
				for upgrade: UpgradeDefinition in offers:
					if _policy.priority(upgrade.id) > _policy.priority(best.id):
						best = upgrade
				_require(session.choose_upgrade(best.id).is_empty())
			RunStop.Kind.SHOP:
				_shop(session.shop, stop.biome)
			RunStop.Kind.ROUND:
				_round(session.rounds, stop)
		if not session.is_over() and not _failed:
			_require(session.advance())
	_stats["purse"] = session.mechanics.coins

## Prefer the best affordable route piece; equip it on an upgraded die when possible. Keep at least the cheapest purchase price after a refresh.
func _shop(shop: ShopSession, biome: int) -> void:
	shop.open()
	while not _failed:
		for offer: ShopOffer in shop.offers:
			if offer.definition.id in _policy.favorites:
				_add("offer_b%d" % biome, 1)
				if shop.run.coins >= offer.price:
					_add("afford_b%d" % biome, 1)
		while not _failed:
			var best: ShopOffer = null
			for offer: ShopOffer in shop.offers:
				if offer.sold or _policy.priority(offer.definition.id) <= 1:
					continue
				if not shop.buy_block(offer).is_empty() and not _replacement(shop, offer):
					continue
				if not best or _policy.priority(offer.definition.id) > _policy.priority(best.definition.id):
					best = offer
			if not best:
				break
			if not shop.buy_block(best).is_empty():
				var sold: OwnedDefinition = _replacement(shop, best)
				_require(shop.sell(sold.id) >= 0)
				_add("sales", 1)
			var free: Array[StringName] = shop.free_bonus_dice()
			# Held bonuses go on the last available die to leave the lead upgraded die free to play.
			var target: StringName = &""
			if best.family == ShopSession.BONUS:
				target = free.back() if best.definition.id in [&"paid-leave", &"power-reserve"] else free.front()
			_require(shop.buy(best, target).is_empty())
			var id: String = String(best.definition.id)
			_add("buy_" + id, 1)
			if not _stats.has("first_purchase_" + id):
				_stats["first_purchase_" + id] = biome
			_add("spent", best.price)
		if shop.refreshes >= (3 if _policy.route == "refresh" else 1) or shop.run.coins < shop.refresh_cost() + shop.rules.bonus_price:
			break
		_add("spent", shop.refresh_cost())
		_require(shop.refresh().errors.is_empty())
		_add("refreshes", 1)

## A higher-priority favorite can displace a weaker purchase, including cashing out Stonks.
func _replacement(shop: ShopSession, offer: ShopOffer) -> OwnedDefinition:
	if offer.definition.id not in _policy.favorites:
		return null
	var worst: OwnedDefinition = null
	for item: OwnedDefinition in shop.run.owned:
		if item.definition is UpgradeDefinition or (item.definition is JokerDefinition) != (offer.family == ShopSession.JOKER):
			continue
		if shop.run.coins + item.sell_value() < offer.price or _policy.priority(item.definition.id) >= _policy.priority(offer.definition.id):
			continue
		if not worst or _policy.priority(item.definition.id) < _policy.priority(worst.definition.id):
			worst = item
	return worst

## Respect early clears, actual manual allowances and free post-play rolls of exactly the played dice.
func _round(rounds: RoundSession, stop: RunStop) -> void:
	_require(rounds.begin(stop.target).errors.is_empty())
	_require(rounds.open().errors.is_empty())
	var run: MechanicsRun = rounds.run
	var chased_four: bool = false
	var hit_five: bool = false
	var preserved: Array[StringName] = []
	var rolls_used: int = 0
	while run.round_active and not _failed:
		_policy.choose(run)
		var rolled: Array[StringName] = _policy.reroll(run)
		if not rolled.is_empty():
			if _policy.route == "five_of_a_kind" and rolled.size() == 1:
				chased_four = true
			rolls_used += 1
			for id: StringName in rolled:
				preserved.erase(id)
			var before: int = run.coins
			_require(rounds.reroll(rolled).errors.is_empty())
			_add("income", run.coins - before)
			_add("rerolls", 1)
			continue
		var play: PlayOutcome = rounds.play(_policy.choice)
		_require(play.result.errors.is_empty() and is_equal_approx(play.result.credited_score, _policy.score))
		var category: StringName = play.result.combination.category
		hit_five = hit_five or category == &"five_of_a_kind"
		_add("plays", 1)
		for id: StringName in play.result.combination.members:
			if id in preserved:
				_add("preserved_members_scored", 1)
		preserved.clear()
		for die: RunDie in run.dice:
			if die.id not in _policy.choice:
				preserved.append(die.id)
		if not preserved.is_empty():
			_add("plays_with_held", 1)
			# Store hundredths so fractional scores survive integer aggregation.
			_add("score_with_held_x100", roundi(play.result.credited_score * 100.0))
		_add("plain_score_forgone_x100", roundi(_policy.plain_score_forgone * 100.0))
		_add("income", run.coins - play.coins_before - play.round_coins - play.unused_play_coins)
		if stop.biome >= 4:
			_late[category] = _late.get(category, 0.0) + play.result.credited_score
		for command: EffectCommand in play.result.commands:
			if command is ScoreDeltaCommand and (command as ScoreDeltaCommand).amount != 0:
				_add("active_" + String(command.definition_id), 1)
		if play.succeeded:
			_stats["cleared"] = stop.round_number
			_add("clears_using_extra_play", int(run.previous_validations > 3))
			_add("clears_using_extra_reroll", int(rolls_used > 3))
			if String(category) == _policy.route and play.score_before + _policy.fallback_score < play.target:
				_add("signature_clears", 1)
		elif play.completed and chased_four and not hit_five:
			_add("failed_chase", 1)
		if not play.completed:
			_require(rounds.automatic_roll(_policy.choice).errors.is_empty())
	if run.run_failed and hit_five:
		_add("failed_after_five", 1)

## Add one observation for the current seed.
func _add(key: String, amount: int) -> void:
	_stats[key] = _stats.get(key, 0) + amount

## Invalid actions or a projection mismatch invalidate the entire batch.
func _require(valid: bool) -> void:
	if not valid:
		push_error("Balance benchmark invariant failed")
		_failed = true
