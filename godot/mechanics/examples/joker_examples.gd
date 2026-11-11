extends RefCounted
class_name JokerExamples
## Global example definitions use the same trigger and effect classes as die-bound content.

# --- Member variables ---

## A recognized straight contributes points independently of any owning die.
var straight: JokerDefinition = JokerDefinition.new(
	&"example_straight_joker",
	[
		EffectDefinition.OnValidation.new(&"straight_points",
			Conditions.Combination.new([&"short_straight", &"long_straight"]),
			[ScoreAction.Points.new(20)]
		),
	]
)
