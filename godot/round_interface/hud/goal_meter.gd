extends Control
class_name GoalMeter
## Round target and banked score with a toy gauge. Displays host-supplied totals only;
## it never decides whether a round is won.

# --- Member variables ---

## Removes springs and count-up travel; values still update.
var reduced_motion: bool = false
## Score currently drawn; tweened so the readout and gauge always agree.
var shown_score: float = 0.0:
	set(value):
		shown_score = value
		_refresh()
## Round target; zero hides the gauge fill.
var _target: float = 0.0
## Whether the cleared treatment is active.
var _cleared: bool = false
## Active count-up, replaced when a new total arrives.
var _count: Tween
## Animated contents. The root keeps the HUD's layout scale, so punches never land on it.
@onready var _body: Control = $Body
## Small spaced caption naming the round.
@onready var _eyebrow: Label = %Eyebrow
## Banked round score.
@onready var _score: Label = %Score
## Target the score must reach.
@onready var _goal: Label = %Target
## Gauge track; its inner width bounds the fill.
@onready var _track: Panel = %Track
## Gauge fill, resized from the score ratio.
@onready var _fill: Panel = %Fill
## Success stamp, hidden until the host celebrates.
@onready var _stamp: Label = %Stamp

# --- Member functions ---

## Ready callback: keep the gauge correct across layout changes.
func _ready() -> void:
	_goal.add_theme_color_override("font_color", KeywordColors.for_role(&"tempo"))
	_goal.add_theme_color_override("font_outline_color", KeywordColors.for_role(&"tempo"))
	_track.resized.connect(_refresh)
	_refresh()

## Localized caption above the target, in spaced eyebrow lettering.
func set_target_caption(caption: String) -> void:
	(%TargetEyebrow as Label).text = caption

## Rename the round in place; the target, gauge, and celebration are left alone.
func set_caption(caption: String) -> void:
	_eyebrow.text = caption

## Establish a new round immediately, cancelling any count-up and celebration.
func set_round(caption: String, target: float, score: float) -> void:
	if _count:
		_count.kill()
	_eyebrow.text = caption
	_target = target
	_goal.text = Juice.number(target)
	_cleared = false
	_stamp.hide()
	(_fill.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = GameColors.BUTTER
	shown_score = score

## Count the banked score up to a new total and punch the readout on arrival.
func add_score(total: float, seconds: float) -> void:
	if _count:
		_count.kill()
	if reduced_motion or seconds <= 0.0:
		shown_score = total
		return
	_count = create_tween()
	_count.tween_property(self, "shown_score", total, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_count.tween_callback(Juice.punch.bind(_score, 0.22, 0.45, 0.0))
	Juice.punch(_track, 0.06, 0.5)

## Stamp the meter once the host has revealed success.
func celebrate(text: String) -> void:
	_cleared = true
	(_fill.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = GameColors.LAGOON
	_stamp.text = text
	_stamp.show()
	_stamp.pivot_offset = _stamp.size * 0.5
	_stamp.rotation = -0.14
	if reduced_motion:
		_stamp.scale = Vector2.ONE
		return
	_stamp.scale = Vector2.ONE * 2.6
	_stamp.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_stamp, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_stamp, "modulate:a", 1.0, 0.1)
	Juice.punch(_body, 0.08, 0.5, 0.03)

## Global center of the score readout, where a flying total should land.
func score_anchor() -> Vector2:
	return _score.get_global_transform() * (Vector2(minf(_score.size.x, 70.0), _score.size.y) * 0.5)

## Redraw the readout and gauge from the shown score.
func _refresh() -> void:
	if not is_node_ready():
		return
	_score.text = Juice.number(roundf(shown_score))
	Juice.fit(_score, 36, 20)
	var ratio: float = clampf(shown_score / _target, 0.0, 1.0) if _target > 0.0 else 0.0
	var inner: float = _track.size.x - 8.0
	_fill.visible = ratio > 0.0
	# A pill needs at least its own height to keep round ends.
	_fill.size.x = maxf(_fill.size.y, inner * ratio)
