extends RefCounted
class_name ScoreStep
## One beat of the scoring reveal: a single source changing a single readout.
## Steps carry running totals so presentation never recomputes scoring arithmetic.

# --- Types ---

## Readout or resource changed by this beat.
enum Kind { FACE, POINTS, MULT, PERCENT, COINS, SELL_VALUE, STORED_MULT, PLAYS, REROLLS }
## Family of the reacting source; a face beat comes from the die itself.
enum Source { DIE, UPGRADE, BONUS, JOKER }

# --- Member variables ---

## Which readout this beat changes.
var kind: Kind = Kind.FACE
## Which element reacts on screen.
var source: Source = Source.DIE
## Runtime owner identity (`upgrade:die_1`, `bonus:die_2`, `joker:<id>`); empty for face beats.
var owner_id: StringName
## Reacting die for face beats and die-bound effects; empty for Jokers.
var die_id: StringName
## Signed contribution of this beat.
var amount: int = 0
## Points readout after this beat.
var points_after: int = 0
## Flat Mult readout after this beat.
var mult_after: int = 0
## Summed percentage pool after this beat.
var percent_after: int = 0
