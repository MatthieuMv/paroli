extends RefCounted
class_name AnalysisHand
## An unordered ordinary-dice input with its recognized category, score and physical roll count.

# --- Member variables ---

## Ascending values of all played dice, including dice outside the scoring combination.
var faces: PackedInt32Array
## Values credited as members by the plain game scorer.
var scoring_faces: PackedInt32Array = []
## Counts of each distinct played value.
var counts: Dictionary[int, int] = {}
## Number of ordered rolls of ordinary dice represented by this hand.
var ways: int
## Score before equipping any effect.
var plain_score: float

# --- Static functions ---

## Visit each multiset once, letting game precedence decide whether it belongs in the experiment.
static func generate(category: StringName) -> Array[AnalysisHand]:
	var hands: Array[AnalysisHand] = []
	var sides: PackedInt32Array = RunDie.new().faces
	for size: int in range(1, MechanicsRun.new().dice.size() + 1):
		var values: PackedInt32Array = []
		values.resize(size)
		if not _enumerate(category, sides, values, size - 1, sides.size() - 1, hands):
			return []
	return hands

## Fill from the right so every prefix stays at or below its neighbour, allowing equal faces.
static func _enumerate(category: StringName, sides: PackedInt32Array, values: PackedInt32Array, index: int, highest_side: int, hands: Array[AnalysisHand]) -> bool:
	if index < 0:
		return _score(category, sides, values, hands)
	for side: int in range(highest_side + 1):
		values[index] = sides[side]
		if not _enumerate(category, sides, values, index - 1, side, hands):
			return false
	return true

## Recognize and score the entire selected play, including any stronger subset it contains.
static func _score(category: StringName, sides: PackedInt32Array, values: PackedInt32Array, hands: Array[AnalysisHand]) -> bool:
	var session: RoundSession = RoundSession.new()
	var selected: Array[StringName] = []
	var opening: Dictionary[StringName, int] = {}
	for i: int in session.run.dice.size():
		var id: StringName = session.run.dice[i].id
		opening[id] = 0
		if i < values.size():
			selected.append(id)
			opening[id] = sides.find(values[i])
	if not session.begin(INF).errors.is_empty() or not session.run.roll(&"opening", opening, EffectContext.RollKind.OPENING).errors.is_empty():
		push_error("Cannot initialize plain baseline for " + str(values))
		return false
	var result: MechanicsEventResult = session.play(selected).result
	if not result.errors.is_empty():
		push_error("; ".join(result.errors))
		return false
	if result.combination.category == category:
		var hand: AnalysisHand = AnalysisHand.new()
		hand.faces = values.duplicate()
		hand.plain_score = result.credited_score
		for id: StringName in result.combination.members:
			hand.scoring_faces.append(session.run.find_die(id).value)
		for face: int in values:
			hand.counts[face] = hand.counts.get(face, 0) + 1
		hand.ways = factorial(values.size())
		for count: int in hand.counts.values():
			@warning_ignore("integer_division")
			hand.ways /= factorial(count)
		hands.append(hand)
	return true

## Small exact factorials for the multinomial and held-dice binomial counts.
static func factorial(count: int) -> int:
	var product: int = 1
	for i: int in range(2, count + 1):
		product *= i
	return product

# --- Member functions ---

## Fraction of ordinary orderings assigning this face to the distinguished first die is count / size.
func ways_with_owner(face: int) -> int:
	@warning_ignore("integer_division")
	return ways * counts[face] / faces.size()
