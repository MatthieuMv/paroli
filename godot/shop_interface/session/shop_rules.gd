extends Resource
class_name ShopRules
## Tunable shop fixture: stock sizes, prices, and refresh costs. The design has deliberately
## left every number here undecided (D-015), so these are test inputs to iterate on, not balance.

# --- Member variables ---

## Jokers offered at a known price each time the shop stocks.
@export_range(0, 3) var joker_offers: int = 2
## Bonuses offered at a known price each time the shop stocks.
@export_range(0, 4) var bonus_offers: int = 3
## Price of a known Joker, in coins.
@export_range(1, 99) var joker_price: int = 6
## Price of a known bonus, in coins.
@export_range(1, 99) var bonus_price: int = 4
## Share of the price actually paid that selling returns, rounded down.
@export_range(0, 100) var sell_percent: int = 50
## Cost of the first paid refresh in a visit.
@export_range(1, 99) var refresh_base_cost: int = 2
## Added to the refresh cost after each paid refresh in the same visit (must stay positive:
## each refresh costs more than the last).
@export_range(1, 99) var refresh_cost_step: int = 1
## Offer a random Joker at a discount.
@export var random_joker: bool = true
## Offer a random bonus at a discount.
@export var random_bonus: bool = true
## Discount of a random purchase relative to the known price of its family.
@export_range(0, 90) var random_discount_percent: int = 40
