extends RefCounted
class_name CombinationScores
## Accepted provisional D-022 base values for the nine recognized categories.
## Hosts add member face values to the base points before calling MechanicsRun.validate_dice().

# --- Constants ---

## Base points per category; an empty category scores nothing.
const POINTS: Dictionary[StringName, int] = {
	&"single": 5,
	&"pair": 10,
	&"two_pairs": 15,
	&"three_of_a_kind": 20,
	&"short_straight": 30,
	&"full_house": 40,
	&"four_of_a_kind": 50,
	&"long_straight": 60,
	&"five_of_a_kind": 80,
}
## Base Mult per category, before flat and percentage modifiers.
const MULT: Dictionary[StringName, int] = {
	&"single": 1,
	&"pair": 2,
	&"two_pairs": 3,
	&"three_of_a_kind": 4,
	&"short_straight": 5,
	&"full_house": 6,
	&"four_of_a_kind": 7,
	&"long_straight": 8,
	&"five_of_a_kind": 10,
}

# --- Static functions ---

## Category base points, excluding automatic member face points and every effect.
static func base_points(category: StringName) -> int:
	return POINTS.get(category, 0)

## Category base Mult, excluding every effect.
static func base_mult(category: StringName) -> int:
	return MULT.get(category, 0)
