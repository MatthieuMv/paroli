extends RefCounted
class_name ShopSession
## Host-side shop logic around MechanicsRun: stocks offers, prices them from ShopRules, and
## performs purchases, sales, bonus moves, and paid refreshes. No scene or node dependency.
## One session lives for the whole run so its event IDs stay unique; `open()` starts a visit.

# --- Constants ---

## Family tag for global Jokers.
const JOKER: StringName = &"joker"
## Family tag for die bonuses.
const BONUS: StringName = &"bonus"
## Joker capacity enforced by MechanicsRun.
const JOKER_SLOTS: int = 4
## Refusal: the purse is too light.
const NO_COINS: String = "Not enough coins"
## Refusal: the Joker rack is full.
const NO_JOKER_SLOT: String = "No free Joker slot"
## Refusal: no die (or not that die) can take a bonus.
const NO_BONUS_SLOT: String = "No free bonus slot"
## Refusal: the offer was already bought this stock.
const SOLD: String = "Already sold"
## Refusal: every identity of that family is owned or already on the shelf.
const EMPTY_POOL: String = "Nothing left to find"
## Refusal: the mechanics rejected the request (invalid die, owner, or transfer).
const INVALID: String = "Not possible"

# --- Member variables ---

## Authoritative run state: coins and equipment.
var run: MechanicsRun
## Prices, stock sizes, and refresh costs for this run.
var rules: ShopRules
## Seedable sampler for stock and random purchases.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Shelf in display order: Jokers, then bonuses.
var offers: Array[ShopOffer] = []
## Paid refreshes so far in the current visit; drives the rising refresh cost.
var refreshes: int = 0
## Content source for stock and random purchases.
var _catalog: EffectsCatalog = EffectsCatalog.new()
## Monotonic suffix keeps every committed event ID unique across the run.
var _event_serial: int = 0

# --- Member functions ---

## Bind to a run between rounds; a zero seed keeps the generator's own random seed.
func _init(run_: MechanicsRun = null, rules_: ShopRules = null, seed_: int = 0) -> void:
	run = run_ if run_ else MechanicsRun.new()
	rules = rules_ if rules_ else ShopRules.new()
	if seed_ != 0:
		rng.seed = seed_

## Start a visit: fresh stock and the refresh cost back at its base.
func open() -> void:
	refreshes = 0
	_stock()

## Known price of a family.
func price_of(family: StringName) -> int:
	return rules.joker_price if family == JOKER else rules.bonus_price

## Discounted price of a random purchase; never free.
func random_price(family: StringName) -> int:
	return maxi(1, int(ceilf(float(price_of(family)) * float(100 - rules.random_discount_percent) / 100.0)))

## Cost of the next paid refresh; rises with each refresh in this visit.
func refresh_cost() -> int:
	return rules.refresh_base_cost + rules.refresh_cost_step * refreshes

## Coins returned when selling something bought for `paid`.
func sell_value_for(paid: int) -> int:
	return int(floorf(float(paid) * float(rules.sell_percent) / 100.0))

## Current sale value of an owned bonus or Joker; zero for unknown or unsellable owners.
func owned_sell_value(owner_id: StringName) -> int:
	var item: OwnedDefinition = run.find_owned(owner_id)
	return item.sell_value() if item and not item.definition is UpgradeDefinition else 0

## Free Joker slots on the rack.
func free_joker_slots() -> int:
	var count: int = 0
	for item: OwnedDefinition in run.owned:
		if item.definition is JokerDefinition:
			count += 1
	return JOKER_SLOTS - count

## Dice whose single bonus slot is free, in run order.
func free_bonus_dice() -> Array[StringName]:
	var result: Array[StringName] = []
	for die: RunDie in run.dice:
		if not run.find_owned(StringName("bonus:" + String(die.id))):
			result.append(die.id)
	return result

## Why a known offer cannot be bought right now, or an empty string when it can.
func buy_block(offer: ShopOffer) -> String:
	if offer.sold:
		return SOLD
	return _family_block(offer.family, offer.price)

## Buy a known offer. Bonuses need the receiving die; Jokers take the next rack slot.
## Returns a refusal, or an empty string once the purchase is committed.
func buy(offer: ShopOffer, die_id: StringName = &"") -> String:
	var block: String = buy_block(offer)
	if not block.is_empty():
		return block
	block = _acquire(offer.definition, offer.price, die_id)
	if block.is_empty():
		offer.sold = true
	return block

## Why a random purchase of a family is unavailable, or an empty string when it is possible.
func random_block(family: StringName) -> String:
	if not (rules.random_joker if family == JOKER else rules.random_bonus):
		return INVALID
	if _pool(family).is_empty():
		return EMPTY_POOL
	return _family_block(family, random_price(family))

## Pay the discounted price for an unknown item of a family and acquire it immediately.
## Returns the item, or null when the purchase was refused.
func buy_random(family: StringName, die_id: StringName = &"") -> IllustratedDefinition:
	if not random_block(family).is_empty():
		return null
	var pool: Array[IllustratedDefinition] = _pool(family)
	var pick: IllustratedDefinition = pool[rng.randi_range(0, pool.size() - 1)]
	return pick if _acquire(pick, random_price(family), die_id).is_empty() else null

## Sell an owned bonus or Joker. Returns the coins gained, or -1 when refused.
func sell(owner_id: StringName) -> int:
	var before: int = run.coins
	var result: MechanicsEventResult = run.sell(_next_id("sell"), owner_id)
	return run.coins - before if result.errors.is_empty() else -1

## Move a bonus to another die's free slot. Returns a refusal or an empty string.
func move_bonus(from_die: StringName, to_die: StringName) -> String:
	return "" if run.move_bonus(from_die, to_die).is_empty() else NO_BONUS_SLOT

## Pay for a whole-shop refresh: new stock, and the next refresh costs more.
## Returns the committed result (Roulette-style effects ride on it), with errors when refused.
func refresh() -> MechanicsEventResult:
	var result: MechanicsEventResult = run.paid_refresh(_next_id("refresh"), refresh_cost())
	if result.errors.is_empty():
		refreshes += 1
		_stock()
	return result

## Shared affordability and capacity check for a family at a price.
func _family_block(family: StringName, price: int) -> String:
	if family == JOKER and free_joker_slots() <= 0:
		return NO_JOKER_SLOT
	if family == BONUS and free_bonus_dice().is_empty():
		return NO_BONUS_SLOT
	if run.coins < price:
		return NO_COINS
	return ""

## Equip first, charge second, so a rejected placement never costs coins.
func _acquire(definition: IllustratedDefinition, price: int, die_id: StringName) -> String:
	var errors: PackedStringArray = []
	if definition is JokerDefinition:
		errors = run.add_joker(definition as JokerDefinition, sell_value_for(price))
	elif die_id in free_bonus_dice():
		errors = run.equip_bonus(definition as BonusDefinition, die_id, sell_value_for(price))
	else:
		return NO_BONUS_SLOT
	if not errors.is_empty():
		return INVALID
	run.coins -= price
	return ""

## Identities of a family that are neither owned nor waiting unsold on the shelf.
func _pool(family: StringName) -> Array[IllustratedDefinition]:
	var taken: Array[StringName] = []
	for item: OwnedDefinition in run.owned:
		taken.append(item.definition.id)
	for offer: ShopOffer in offers:
		if not offer.sold:
			taken.append(offer.definition.id)
	var result: Array[IllustratedDefinition] = []
	if family == JOKER:
		for joker: JokerDefinition in _catalog.jokers:
			if joker.id not in taken:
				result.append(joker)
	else:
		for bonus: BonusDefinition in _catalog.bonuses:
			if bonus.id not in taken:
				result.append(bonus)
	return result

## Replace the whole shelf with distinct, unowned identities; a short pool leaves gaps.
func _stock() -> void:
	offers.clear()
	for family: StringName in [JOKER, BONUS]:
		var pool: Array[IllustratedDefinition] = _pool(family)
		var wanted: int = rules.joker_offers if family == JOKER else rules.bonus_offers
		for slot: int in mini(wanted, pool.size()):
			var offer: ShopOffer = ShopOffer.new()
			offer.family = family
			offer.definition = pool.pop_at(rng.randi_range(0, pool.size() - 1))
			offer.price = price_of(family)
			offers.append(offer)

## Fresh IDs keep sales and refreshes unambiguous in the run's event ledger.
func _next_id(prefix: String) -> StringName:
	_event_serial += 1
	return StringName("shop_%s_%d" % [prefix, _event_serial])
