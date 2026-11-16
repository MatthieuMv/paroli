extends SceneTree
## Headless check of shop logic: stock, purchases, capacity, sales, moves, and refreshes.

# --- Member functions ---

## Run after the scene tree is ready so script classes are registered.
func _initialize() -> void:
	_run.call_deferred()

## Walk the D-015 acceptance cases with the default fixture rules.
func _run() -> void:
	var catalog: EffectsCatalog = EffectsCatalog.new()
	var run: MechanicsRun = MechanicsRun.new(40)
	assert(run.install_upgrade(catalog.upgrade(&"jackpot")).is_empty())
	assert(run.add_joker(catalog.joker(&"window_shopper"), 3).is_empty())
	assert(run.equip_bonus(catalog.bonus(&"six_addict"), &"die_1", 2).is_empty())
	var rules: ShopRules = ShopRules.new()
	var shop: ShopSession = ShopSession.new(run, rules, 11)
	shop.open()
	# Stock: the configured counts, distinct, and never something already owned.
	assert(shop.offers.size() == rules.joker_offers + rules.bonus_offers)
	var seen: Array[StringName] = []
	for offer: ShopOffer in shop.offers:
		assert(offer.definition.id not in seen and offer.definition.id not in [&"window_shopper", &"six_addict"])
		assert(offer.price == shop.price_of(offer.family) and not offer.sold)
		seen.append(offer.definition.id)
	assert(shop.offers[0].family == ShopSession.JOKER and shop.offers[rules.joker_offers].family == ShopSession.BONUS)
	# Known Joker purchase: pays the price, takes a rack slot, and empties the shelf slot.
	var joker_offer: ShopOffer = shop.offers[0]
	assert(shop.buy(joker_offer).is_empty())
	assert(run.coins == 40 - rules.joker_price and joker_offer.sold and shop.free_joker_slots() == 2)
	assert(shop.buy(joker_offer) == ShopSession.SOLD and run.coins == 40 - rules.joker_price)
	var joker_owner: StringName = StringName("joker:" + String(joker_offer.definition.id))
	assert(shop.owned_sell_value(joker_owner) == 3, "Selling returns half the price paid")
	# Known bonus purchase: the player chooses a die with a free slot.
	var bonus_offer: ShopOffer = shop.offers[rules.joker_offers]
	var free_dice: Array[StringName] = [&"die_2", &"die_3", &"die_4", &"die_5"]
	assert(shop.free_bonus_dice() == free_dice)
	assert(shop.buy(bonus_offer, &"die_1") == ShopSession.NO_BONUS_SLOT and not bonus_offer.sold, "An occupied die refuses a second bonus")
	assert(run.coins == 34, "A refused placement costs nothing")
	assert(shop.buy(bonus_offer, &"die_3").is_empty() and run.coins == 30)
	assert(run.find_owned(&"bonus:die_3").definition == bonus_offer.definition)
	assert(run.dice[2].faces == PackedInt32Array([1, 2, 3, 4, 5, 6]), "Bonuses never change faces")
	# Moving a bonus transfers it to a free slot only.
	assert(shop.move_bonus(&"die_3", &"die_1") == ShopSession.NO_BONUS_SLOT)
	assert(shop.move_bonus(&"die_3", &"die_5").is_empty())
	assert(run.find_owned(&"bonus:die_5").definition == bonus_offer.definition and not run.find_owned(&"bonus:die_3"))
	# Selling pays the stored value and frees the identity and the slot.
	assert(shop.sell(&"bonus:die_5") == 2 and run.coins == 32 and not run.find_owned(&"bonus:die_5"))
	assert(shop.sell(&"upgrade:die_1") == -1 and run.coins == 32, "Upgrades are never sellable")
	# Paid refresh: repeatable, each one dearer, restocks everything, feeds Roulette.
	var roulette: OwnedDefinition = run.find_owned(&"joker:window_shopper")
	assert(shop.refresh_cost() == rules.refresh_base_cost)
	assert(shop.refresh().errors.is_empty() and run.coins == 30 and shop.refreshes == 1)
	assert(shop.refresh_cost() == rules.refresh_base_cost + rules.refresh_cost_step)
	assert(shop.refresh().errors.is_empty() and run.coins == 27 and roulette.accumulated_mult == 2)
	assert(shop.offers.size() == 5)
	for offer: ShopOffer in shop.offers:
		assert(not offer.sold and offer.definition.id != joker_offer.definition.id, "Owned identities stay off the shelf")
	# Random purchases: discounted, never owned, never a duplicate of the shelf.
	assert(shop.random_price(ShopSession.JOKER) == 4 and shop.random_price(ShopSession.BONUS) == 3)
	var shelf: Array[StringName] = []
	for offer: ShopOffer in shop.offers:
		shelf.append(offer.definition.id)
	var surprise: IllustratedDefinition = shop.buy_random(ShopSession.JOKER)
	assert(surprise is JokerDefinition and surprise.id not in shelf and run.coins == 23)
	assert(shop.owned_sell_value(StringName("joker:" + String(surprise.id))) == 2, "Sale value follows the discounted price paid")
	var lucky: IllustratedDefinition = shop.buy_random(ShopSession.BONUS, &"die_2")
	assert(lucky is BonusDefinition and run.find_owned(&"bonus:die_2").definition == lucky and run.coins == 20)
	assert(shop.buy_random(ShopSession.BONUS, &"die_2") == null and run.coins == 20, "A random bonus needs a free die too")
	# Capacity and funds refuse cleanly.
	assert(shop.buy(shop.offers[0]).is_empty() and shop.free_joker_slots() == 0)
	assert(shop.buy_block(shop.offers[1]) == ShopSession.NO_JOKER_SLOT and shop.random_block(ShopSession.JOKER) == ShopSession.NO_JOKER_SLOT)
	run.coins = 1
	assert(shop.buy_block(shop.offers[2]) == ShopSession.NO_COINS)
	assert(not shop.refresh().errors.is_empty() and shop.refreshes == 2 and run.coins == 1)
	# A new visit resets the refresh cost; rules can remove random purchases.
	shop.open()
	assert(shop.refresh_cost() == rules.refresh_base_cost)
	rules.random_bonus = false
	assert(shop.random_block(ShopSession.BONUS) == ShopSession.INVALID)
	print("PASS: shop stock, purchases, placement, moves, sales, rising refresh, random purchases, refusals.")
	quit()
