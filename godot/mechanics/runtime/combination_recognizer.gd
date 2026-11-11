extends RefCounted
class_name CombinationRecognizer
## Recognize the highest scoring rank, then highest member sum, then earliest run positions.

# --- Types ---

## Explicit member identities keep effect eligibility independent of effect rewards.
class Result:
	extends RefCounted

	# --- Member variables ---

	## Empty means no selected dice.
	var category: StringName
	## Membership is ordered by the input's stable run order.
	var members: Array[StringName] = []
	## Rank is precedence, not rarity or effect payout.
	var rank: int = 0
	## Used only to break equal-rank ties.
	var value_sum: int = 0
	## Original stable positions provide the final tie-break.
	var positions: PackedInt32Array = []

# --- Constants ---

## Accepted scoring precedence; long straight outranks four of a kind.
const CATEGORIES: Array[StringName] = [
	&"", &"single", &"pair", &"two_pairs", &"three_of_a_kind", &"short_straight",
	&"full_house", &"four_of_a_kind", &"long_straight", &"five_of_a_kind",
]

# --- Static functions ---

## Enumerate the small five-die space without optimizing for any effect's payout.
static func recognize(dice: Array[DieSnapshot], allowed_gaps: int = 0) -> Result:
	var best: Result = Result.new()
	for mask: int in range(1, 1 << dice.size()):
		var values: PackedInt32Array = []
		var candidate: Result = Result.new()
		for index: int in dice.size():
			if mask & (1 << index):
				values.append(dice[index].value)
				candidate.value_sum += dice[index].value
				candidate.members.append(dice[index].id)
				candidate.positions.append(index)
		candidate.rank = _rank(values, allowed_gaps)
		if candidate.rank == 0:
			continue
		if _better(candidate, best):
			candidate.category = CATEGORIES[candidate.rank]
			best = candidate
	return best

## A category recognizes exactly its own member subset; contained categories never co-score.
static func _rank(values: PackedInt32Array, allowed_gaps: int) -> int:
	values.sort()
	var counts: Dictionary[int, int] = {}
	for value: int in values:
		counts[value] = counts.get(value, 0) + 1
	match values.size():
		1:
			return 1
		2:
			return 2 if counts.size() == 1 else 0
		3:
			return 4 if counts.size() == 1 else 0
		4:
			if counts.size() == 1:
				return 7
			if counts.size() == 2 and counts.values()[0] == 2:
				return 3
			if _straight(values, allowed_gaps):
				return 5
		5:
			if counts.size() == 1:
				return 9
			if counts.size() == 2 and counts.values()[0] in [2, 3]:
				return 6
			if _straight(values, allowed_gaps):
				return 8
	return 0

## Missing link permits at most one internal gap of two, never duplicates or wrapping.
static func _straight(values: PackedInt32Array, allowed_gaps: int) -> bool:
	var gaps: int = 0
	for index: int in range(1, values.size()):
		var difference: int = values[index] - values[index - 1]
		if difference == 2:
			gaps += 1
		elif difference != 1:
			return false
	return gaps <= mini(1, allowed_gaps)

## Lexicographic stable positions settle equal rank and value sums deterministically.
static func _better(candidate: Result, current: Result) -> bool:
	if candidate.rank != current.rank:
		return candidate.rank > current.rank
	if candidate.value_sum != current.value_sum:
		return candidate.value_sum > current.value_sum
	for index: int in candidate.positions.size():
		if candidate.positions[index] != current.positions[index]:
			return candidate.positions[index] < current.positions[index]
	return false
