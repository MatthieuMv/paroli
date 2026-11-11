extends RefCounted
class_name UpgradeExamples
## Authoring fixtures: a synthetic support rule and the authoritative Odd master catalog entry.

# --- Member variables ---

## A held support die rewards each face differently on validation.
var patient_bloom: UpgradeDefinition = UpgradeDefinition.new(
	&"example_patient_bloom",
	[1, 1, 2, 2, 3, 3],
	[
		EffectDefinition.OnValidation.new(&"held_one",
			Conditions.All.new([
				Conditions.Held.new(),
				Conditions.NotValidated.new(),
				Conditions.Showing.new(1),
			]),
			[ScoreAction.Mult.new(6)]
		),
		EffectDefinition.OnValidation.new(&"held_two",
			Conditions.All.new([
				Conditions.Held.new(),
				Conditions.NotValidated.new(),
				Conditions.Showing.new(2),
			]),
			[ScoreAction.Mult.new(4)]
		),
		EffectDefinition.OnValidation.new(&"held_three",
			Conditions.All.new([
				Conditions.Held.new(),
				Conditions.NotValidated.new(),
				Conditions.Showing.new(3),
			]),
			[ScoreAction.Mult.new(2)]
		),
	],
	&"Mint", &"flowers"
)

## Use the authoritative catalog so illustrative code cannot drift from EFFECTS.md.
var odd_master: UpgradeDefinition = EffectsCatalog.new().upgrade(&"odd_master")
