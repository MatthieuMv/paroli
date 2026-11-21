extends SceneTree
## Replay every plain hand in one combination category through the game with one catalog item equipped.

# --- Constants ---

## Report names and their categories in the gameplay recognizer.
const CATEGORIES: Dictionary[String, StringName] = {
	"high_die": &"single",
	"pair": &"pair",
	"two_pairs": &"two_pairs",
	"three_of_a_kind": &"three_of_a_kind",
	"short_straight": &"short_straight",
	"full_house": &"full_house",
	"long_straight": &"long_straight",
	"four_of_a_kind": &"four_of_a_kind",
	"five_of_a_kind": &"five_of_a_kind",
}
## Keep generated reports beside the runner; only the two named Parquet files are replaced.
const FOLDER: String = "res://debug/upgrade_analysis/"
## Roulette growth has no round cap. This experiment compares zero to three paid refreshes.
const REFRESH_LIMIT: int = 3

# --- Member variables ---

## Selected report family, also used to name history states and output files.
var _report: String
## Transient tab-separated input is automatically removed when this file handle is released.
var _rows: FileAccess
## Ordinary physical die and its six equiprobable face positions.
var _plain: PackedInt32Array = RunDie.new().faces
## Ordinary play and reroll limits are read from a fresh session.
var _defaults: RoundSession = RoundSession.new()
## Normal shop price of a single Joker when sold, relevant to Nest Egg.
var _joker_sell: int = 0

# --- Member functions ---

## Choose a category and optionally print its plain hands without running any effect replays.
func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty() or not CATEGORIES.has(args[0]) or args.size() > 2 or (args.size() == 2 and args[1] != "--list"):
		push_error("Expected -- <%s> [--list]" % "|".join(CATEGORIES.keys()))
		quit(1)
		return
	analyze(args[0], args.size() == 2)

## Both the generic CLI and historical entry points use the same baselines and replay machinery.
func analyze(report: String, list_only: bool) -> void:
	_report = report
	var hands: Array[AnalysisHand] = AnalysisHand.generate(CATEGORIES[report])
	if hands.is_empty():
		push_error("No baseline hands for " + report)
		quit(1)
		return
	if list_only:
		_list_hands(hands)
		quit()
		return
	var shop: ShopSession = ShopSession.new()
	_joker_sell = shop.sell_value_for(shop.price_of(ShopSession.JOKER))
	_rows = FileAccess.create_temp(FileAccess.READ_WRITE, "paroli_" + report, "tsv")
	if not _defaults.begin(INF).errors.is_empty() or not _rows:
		push_error("Cannot initialize analysis for " + report)
		quit(1)
		return
	var ok: bool = true
	var items: Array[BuildDefinition] = EffectsCatalog.new().all_definitions()
	items.push_front(null)
	for item: BuildDefinition in items:
		if not ok:
			break
		ok = _test_item(item, hands)
	if ok:
		ok = _export()
	_rows = null
	if ok:
		print("Wrote %s_outcomes.parquet and %s_summary.parquet to %s" % [report, report, FOLDER])
	quit(0 if ok else 1)

## Print the scoring members, exact probability and plain score of each qualifying input.
func _list_hands(hands: Array[AnalysisHand]) -> void:
	var is_high_die: bool = _report == "high_die"
	var member_column: String = "high_die" if is_high_die else "scoring_faces"
	print("played_faces\t%s\tcategory\tprobability_for_this_many_dice\tscore" % member_column)
	for hand: AnalysisHand in hands:
		var members: String = str(hand.scoring_faces[0]) if is_high_die else str(hand.scoring_faces)
		print("%s\t%s\t%s\t%d/%d\t%s" % [hand.faces, members, CATEGORIES[_report], hand.ways, int(pow(_plain.size(), hand.faces.size())), hand.plain_score])

## Each placement policy and history is its own experiment with its own denominator.
func _test_item(item: BuildDefinition, hands: Array[AnalysisHand]) -> bool:
	var faces: PackedInt32Array = _plain
	var family: String = "plain"
	var placement: String = "global"
	if item is UpgradeDefinition:
		faces = (item as UpgradeDefinition).faces
		family = "upgrade"
		placement = "played"
	elif item is BonusDefinition:
		family = "bonus"
		placement = "played"
	elif item is JokerDefinition:
		family = "joker"
	var states: Array[AnalysisPlayState] = AnalysisPlayState.for_item(item, faces, CATEGORIES[_report], _report, _defaults.plays_granted, _defaults.rerolls_granted, REFRESH_LIMIT)
	for state: AnalysisPlayState in states:
		for hand: AnalysisHand in hands:
			if not _placements(item, family, state, hand, faces, placement):
				return false
			if item and item.id in [&"guardian", &"power-reserve", &"paid-leave"] and hand.faces.size() < _defaults.run.dice.size():
				if not _placements(item, family, state, hand, faces, "held"):
					return false
	return true

## Distinguish the owner, but collapse permutations of ordinary dice and identical face positions.
func _placements(item: BuildDefinition, family: String, state: AnalysisPlayState, hand: AnalysisHand, faces: PackedInt32Array, placement: String) -> bool:
	var size: int = hand.faces.size()
	var ways: int = hand.ways
	var possible: int = int(pow(_plain.size(), size))
	if placement == "global":
		if item and item.id == &"bench-warmers":
			return _held_matches(item, family, state, hand, ways, possible)
		return _replay(item, family, state, hand, placement, 0, -1, ways, possible)
	var candidates: Array[int] = hand.counts.keys()
	if placement == "held":
		candidates.assign(_plain)
		possible *= faces.size()
	for face: int in candidates:
		if placement == "played":
			ways = hand.ways_with_owner(face)
		var frequency: int = faces.count(face)
		if frequency > 0 and not _replay(item, family, state, hand, placement, face, -1, ways * frequency, possible):
			return false
	return true

## Bench Warmers reads only the number of matching held dice. Only distinct played values can match a held face.
func _held_matches(item: BuildDefinition, family: String, state: AnalysisPlayState, hand: AnalysisHand, ways: int, possible: int) -> bool:
	var distinct: int = hand.counts.size()
	var held: int = _defaults.run.dice.size() - hand.faces.size()
	possible *= int(pow(_plain.size(), held))
	for count: int in range(held + 1):
		@warning_ignore("integer_division")
		var orders: int = AnalysisHand.factorial(held) / (AnalysisHand.factorial(count) * AnalysisHand.factorial(held - count))
		var weight: int = orders * int(pow(distinct, count)) * int(pow(_plain.size() - distinct, held - count))
		if not _replay(item, family, state, hand, "global", 0, count, ways * weight, possible):
			return false
	return true

## Equip a fresh run, set only relevant history, then let the game recognize and score the play.
func _replay(item: BuildDefinition, family: String, state: AnalysisPlayState, hand: AnalysisHand, placement: String, face: int, matches: int, ways: int, possible: int) -> bool:
	var session: RoundSession = RoundSession.new()
	var run: MechanicsRun = session.run
	var owner: RunDie = run.dice[0]
	var errors: PackedStringArray = []
	if item is UpgradeDefinition:
		errors = run.install_upgrade(item as UpgradeDefinition)
	elif item is BonusDefinition:
		errors = run.equip_bonus(item as BonusDefinition, owner.id, 0)
	elif item is JokerDefinition:
		errors = run.add_joker(item as JokerDefinition, _joker_sell)
	if not errors.is_empty():
		push_error("; ".join(errors))
		return false
	for n: int in state.high_die_clears:
		if not _valid(session.begin(1.0)) or not _valid(session.open()) or not _valid(session.play([owner.id]).result):
			return false
	for n: int in state.refreshes:
		# Give the fixture funds for this paid event; acquisition costs are outside play income.
		run.coins += 1
		if not _valid(run.paid_refresh(StringName("refresh_%d" % n), 1)):
			return false
	if not _valid(session.begin(1.0 if state.clears_round else INF)):
		return false
	var selected: Array[StringName] = []
	var opening: Dictionary[StringName, int] = {}
	var played: Array[int] = []
	played.assign(hand.faces)
	if placement == "played":
		played.erase(face)
		played.push_front(face)
	var first: int = 1 if placement == "held" else 0
	for i: int in run.dice.size():
		var die: RunDie = run.dice[i]
		var value: int = die.faces[0]
		var index: int = i - first
		if index >= 0 and index < played.size():
			selected.append(die.id)
			value = played[index]
		elif placement == "held" and i == 0:
			value = face
		elif matches >= 0:
			value = hand.faces[0]
			if i - played.size() >= matches:
				for side: int in _plain:
					if side not in hand.faces:
						value = side
						break
		opening[die.id] = die.faces.find(value)
	if not _valid(run.roll(&"opening", opening, EffectContext.RollKind.OPENING)):
		return false
	run.previous_validations = state.prior_plays
	run.validations_remaining -= state.prior_plays
	run.previous_combination = state.prior_category
	owner.previous_validated_value = state.previous_face
	owner.crescendo_percent = state.crescendo
	var coins_before: int = run.coins
	for n: int in state.rerolls:
		var rolled: Dictionary[StringName, int] = {owner.id: opening[owner.id]}
		if not _valid(run.roll(StringName("manual_%d" % n), rolled, EffectContext.RollKind.MANUAL)):
			return false
	var outcome: PlayOutcome = session.play(selected)
	if not _valid(outcome.result):
		return false
	var earned_coins: int = run.coins - coins_before - outcome.unused_play_coins - outcome.round_coins
	var growth: int = run.owned[0].sell_growth if item else 0
	var id: String = String(item.id) if item else "plain"
	var fields: PackedStringArray = [
		family, id, state.label, placement, str(played.size()), str(hand.faces),
		str(face) if face else "", str(matches) if matches >= 0 else "", str(ways), str(possible),
		String(outcome.result.combination.category), str(hand.plain_score), str(outcome.result.credited_score), str(earned_coins),
		str(session.plays_granted - _defaults.plays_granted), str(session.rerolls_granted - _defaults.rerolls_granted), str(growth)]
	return _rows.store_csv_line(fields, "\t")

## Surface game errors instead of recording incomplete observations.
func _valid(result: MechanicsEventResult) -> bool:
	if result.errors.is_empty():
		return true
	push_error("; ".join(result.errors))
	return false

## DuckDB imports the typed observations once and computes the exact weighted reports in memory.
func _export() -> bool:
	_rows.flush()
	var folder: String = ProjectSettings.globalize_path(FOLDER).replace("'", "''")
	var summary: String = FileAccess.get_file_as_string(FOLDER + "combination_summary.sql").strip_edges()
	if summary.is_empty():
		push_error("Missing combination summary query")
		return false
	# Retain the two historical column names for existing High Die queries.
	if _report == "high_die":
		summary = "SELECT *, input_probability AS high_die_input_probability, chance_of_gain_given_input AS chance_of_gain_given_high_die FROM (" + summary + ")"
	var sql: String = """CREATE TABLE outcomes (
		family VARCHAR, effect VARCHAR, state VARCHAR, placement VARCHAR, dice_played INTEGER,
		played_faces INTEGER[], equipped_face INTEGER, held_matches INTEGER, ways INTEGER, possible INTEGER,
		category VARCHAR, plain_score DOUBLE, score DOUBLE, coins INTEGER, extra_plays INTEGER,
		extra_rerolls INTEGER, sell_growth INTEGER)""" + ";"
	sql += "COPY outcomes FROM '%s' (FORMAT CSV, HEADER false, DELIMITER '\t');" % _rows.get_path_absolute().replace("'", "''")
	sql += "COPY (SELECT *, ways::DOUBLE / possible AS roll_probability, score - plain_score AS gain FROM outcomes) TO '%s%s_outcomes.parquet' (FORMAT PARQUET);" % [folder, _report]
	sql += "COPY (" + summary + ") TO '" + folder + _report + "_summary.parquet' (FORMAT PARQUET);"
	var output: Array[String] = []
	var status: int = OS.execute("duckdb", ["-batch", "-bail", ":memory:", "-c", sql], output, true)
	if status != 0:
		push_error("DuckDB CLI export failed (%d): %s" % [status, str(output)])
	return status == 0
