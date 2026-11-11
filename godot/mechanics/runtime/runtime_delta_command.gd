extends EffectCommand
class_name RuntimeDeltaCommand
## Explicit non-scoring payload applied after all event eligibility is evaluated.

# --- Types ---

## Persistent growth targets an owned instance; allowances target the current round.
enum Kind { COINS, SELL_VALUE, ACCUMULATED_MULT, VALIDATIONS, REROLLS, STRAIGHT_GAPS }

# --- Member variables ---

## Destination accumulator or recognition policy.
var kind: Kind
## Signed delta, except STRAIGHT_GAPS which is an allowed maximum, combined with max().
var amount: int
