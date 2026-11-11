extends RefCounted
class_name MechanicsEventResult
## One committed event result; retries with the same ID never reapply commands.

# --- Member variables ---

## Failed operations contain errors and do not enter the committed-event ledger.
var errors: PackedStringArray = []
## Full provenance-bearing effects for presentation and diagnostics.
var commands: Array[EffectCommand] = []
## Actual recognized category and member identities for this validation.
var combination: CombinationRecognizer.Result
## Points after flat additions.
var points: int = 0
## Mult after flat additions, before percentages.
var flat_mult: int = 0
## Sum of all percentage-point contributions.
var mult_percent: int = 0
## Fractional Mult is retained; no rounding rule is invented.
var final_mult: float = 0.0
## Nonnegative contribution to the round score.
var credited_score: float = 0.0
