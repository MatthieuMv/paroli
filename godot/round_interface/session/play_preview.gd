extends RefCounted
class_name PlayPreview
## Pre-commit facts for the pending play. Carries base values and eligibility only (D-023):
## never face points, effect totals, or a projected score.

# --- Member variables ---

## Recognized category and members; null when no die is selected.
var combination: CombinationRecognizer.Result
## Category base points, excluding automatic member face points.
var base_points: int = 0
## Category base Mult, excluding every effect.
var base_mult: int = 0
## Runtime owners whose effects would contribute a nonzero amount to this play.
var eligible_owners: Array[StringName] = []
## Dice whose own upgrade or bonus would apply a negative amount; shown with the crack cue.
var penalized_dice: Array[StringName] = []
