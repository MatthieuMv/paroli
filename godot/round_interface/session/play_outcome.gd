extends RefCounted
class_name PlayOutcome
## Committed result of one play, with the before/after facts the scoring reveal needs.
## Created by RoundSession after the mechanics commit; presentation treats it as read-only.

# --- Member variables ---

## Played dice in permanent run order.
var selected: Array[StringName] = []
## Committed mechanics result, including provenance-bearing commands.
var result: MechanicsEventResult
## Category base points before member face points.
var category_points: int = 0
## Category base Mult before effects.
var category_mult: int = 0
## Automatic face points contributed by each recognized member.
var face_points: Dictionary[StringName, int] = {}
## Round score before this play was credited.
var score_before: float = 0.0
## Round score after crediting max(0, raw score).
var score_after: float = 0.0
## Signed points × final Mult, shown even when negative.
var raw_score: float = 0.0
## Round target, repeated here so the reveal needs no run access.
var target: float = 0.0
## True when this play ended the round by success or exhaustion.
var completed: bool = false
## True only when the target was reached.
var succeeded: bool = false
## Coins before any effect of this play paid out.
var coins_before: int = 0
## Plays left after this one; converted to coins on success.
var unused_plays: int = 0
## Host-policy coins granted for unused plays; zero unless the round succeeded.
var unused_play_coins: int = 0
## Host-policy coins every cleared round pays, however many plays it took; zero unless the
## round succeeded.
var round_coins: int = 0
