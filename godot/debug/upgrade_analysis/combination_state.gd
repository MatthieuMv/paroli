extends RefCounted
class_name AnalysisPlayState
## One conditional history for a play. Different histories have independent reports.

# --- Member variables ---

## Human-readable conditioning event in both Parquet files.
var label: String = "fresh"
## Number of committed plays in this round before scoring.
var prior_plays: int = 0
## Last played value of the equipped die, or zero for no previous play.
var previous_face: int = 0
## Crescendo growth already earned before the measured play.
var crescendo: int = 0
## Manual rerolls of the equipped die immediately preceding the measured play.
var rerolls: int = 0
## Prior hand category for the two jokers that compare consecutive plays.
var prior_category: StringName = &""
## Number of prior paid shop refreshes for Roulette.
var refreshes: int = 0
## Whether this play clears the target, for the Stonks round-end event.
var clears_round: bool = false

# --- Static functions ---

## Generate only dimensions read by the equipped effect, up to ordinary round limits.
static func for_item(item: BuildDefinition, faces: PackedInt32Array, input_category: StringName, report: String, plays: int, rolls: int, refresh_limit: int) -> Array[AnalysisPlayState]:
	var states: Array[AnalysisPlayState] = [AnalysisPlayState.new()]
	if not item:
		return states
	match item.id:
		&"crescendo", &"deja-vu", &"alternator", &"echo":
			# Expand reachable histories by one play, merging equivalent (last face, growth) pairs.
			var frontier: Array[AnalysisPlayState] = states.duplicate()
			var seen: Dictionary[String, bool] = {}
			for depth: int in range(1, plays):
				var next: Array[AnalysisPlayState] = []
				for prior: AnalysisPlayState in frontier:
					for face: int in faces:
						var state: AnalysisPlayState = AnalysisPlayState.new()
						state.prior_plays = depth
						state.previous_face = face
						state.label = "previous_%d" % face
						if item.id == &"crescendo":
							state.crescendo = prior.crescendo
							if prior.previous_face > 0 and face > prior.previous_face:
								state.crescendo += HistoryAmount.CRESCENDO_STEP
							state.label += "_stack_%d" % state.crescendo
						if not seen.has(state.label):
							seen[state.label] = true
							states.append(state)
							next.append(state)
				frontier = next
		&"opening-act", &"grand-finale", &"snowball":
			for n: int in range(1, plays):
				var state: AnalysisPlayState = AnalysisPlayState.new()
				state.prior_plays = n
				state.label = "prior_plays_%d" % n
				states.append(state)
		&"first-instinct", &"relentless", &"loyalty-card", &"side-hustle", &"last-straw":
			for n: int in range(1, rolls + 1):
				var state: AnalysisPlayState = AnalysisPlayState.new()
				state.rerolls = n
				state.label = "rerolls_used_%d" % n
				states.append(state)
		&"broken-record", &"plot-twist":
			var other: StringName = &"pair" if input_category == &"single" else &"single"
			for category: StringName in [input_category, other]:
				var state: AnalysisPlayState = AnalysisPlayState.new()
				state.prior_plays = 1
				state.prior_category = category
				state.label = "previous_" + report if category == input_category else "previous_other"
				states.append(state)
		&"roulette":
			for n: int in range(1, refresh_limit + 1):
				var state: AnalysisPlayState = AnalysisPlayState.new()
				state.refreshes = n
				state.label = "paid_refreshes_%d" % n
				states.append(state)
		&"stonks":
			var state: AnalysisPlayState = AnalysisPlayState.new()
			state.clears_round = true
			state.label = "clears_round"
			states.append(state)
	return states
