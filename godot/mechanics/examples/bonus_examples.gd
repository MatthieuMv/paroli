extends RefCounted
class_name BonusExamples
## Synthetic bonus declarations demonstrate composition without accepting new balance rules.

# --- Member variables ---

## An unheld six contributes points only when its owning die is validated.
var unheld_six: BonusDefinition = BonusDefinition.new(
	&"example_unheld_six",
	[
		EffectDefinition.OnValidation.new(&"unheld_six",
			Conditions.All.new([
				Conditions.NotHeld.new(),
				Conditions.Validated.new(),
				Conditions.Showing.new(6),
			]),
			[ScoreAction.Points.new(8)]
		),
	]
)
