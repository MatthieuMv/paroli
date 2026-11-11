extends EffectCommand
class_name ScoreDeltaCommand
## Signed additive score intent; all deltas accumulate before the final points × Mult product.

# --- Types ---

## Score channels are separate; percentage increases sum before a single final multiplication.
enum Channel { POINTS, MULT, MULT_PERCENT }

# --- Member variables ---

## Accumulator that receives this contribution.
var channel: Channel = Channel.POINTS
## Negative values remain negative; the final credited score is clamped by game logic.
var amount: int = 0
