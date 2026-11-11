extends RefCounted
class_name OwnedDefinition
## Mutable ownership instance, separate from shared authored definitions.

# --- Member variables ---

## Runtime identity: upgrades/bonuses use a die slot; Jokers use their unique definition ID.
var id: StringName
## Shared immutable rule data.
var definition: BuildDefinition
## Empty for Jokers.
var die_id: StringName
## Supplied by the economy; no base sell price is invented here.
var base_sell_value: int = 0
## Stonks growth survives round resets but disappears on sale.
var sell_growth: int = 0
## Window shopper growth survives round resets but disappears on sale.
var accumulated_mult: int = 0

# --- Member functions ---

## Current owned value, used by Portfolio without selling.
func sell_value() -> int:
	return base_sell_value + sell_growth
