extends Resource
class_name RunRules
## Tunable run fixture: route length, starting purse, coin rewards, and the target curve. The
## design fixes the route's shape (D-016) and that targets rise every round (D-017), but no
## number here is balanced: these are placeholders to iterate on in the Inspector.

# --- Member variables ---

## Biomes in a full run; each opens with an upgrade choice and ends with a boss (D-016).
@export_range(1, 5) var biomes: int = 5
## Regular rounds per biome, each followed by a shop, before the biome's boss (D-016).
@export_range(0, 4) var regular_rounds: int = 2
## Coins in the purse when a run starts.
@export_range(0, 99) var starting_coins: int = 0
## Coins paid for clearing a round, however many plays it took.
@export_range(0, 99) var coins_per_round: int = 4
## Coins paid for each play left unused when a round is cleared (D-021).
@export_range(0, 9) var coins_per_unused_play: int = 1
## Target of the run's first round, in points.
@export_range(1.0, 10000.0, 1.0) var first_target: float = 100.0
## Each round's target is the previous one times this factor, before rounding.
@export_range(1.0, 3.0, 0.05) var target_growth: float = 1.6

# --- Member functions ---

## Target of a round counted from 1 across the whole run, rounded to two significant digits
## so the goal reads as a clean number. `RunSession` keeps the sequence strictly rising.
func target_for(round_number: int) -> float:
	var raw: float = first_target * pow(target_growth, float(maxi(round_number, 1) - 1))
	var step: float = 1.0
	while raw >= step * 100.0:
		step *= 10.0
	return maxf(1.0, roundf(raw / step) * step)
