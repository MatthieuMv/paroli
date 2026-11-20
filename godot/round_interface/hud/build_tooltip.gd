extends PanelContainer
class_name BuildTooltip
## Explanation card for owned content: one section for a Joker, or a die sheet with its
## upgrade and bonus. Read-only: it renders authored text and never evaluates rules.

# --- Constants ---

## Card width where the window has room for it.
const WIDTH: float = 300.0
## Narrowest card on a small window.
const NARROWEST: float = 240.0
## Smallest scale a card takes when no side of its source has room for it; below it the
## text is hard to read.
const SMALLEST_FIT: float = 0.75
## Clear space between the card and its source.
const GAP: float = 10.0
## Clear space between the card and the window's edges.
const MARGIN: float = 8.0

# --- Member variables ---

## Removes the pop-in.
var reduced_motion: bool = false
## Invalidates deferred placement when another source takes over or the pointer leaves.
var _version: int = 0
## Up to two authored sections; unused ones are hidden.
@onready var _sections: Array[VBoxContainer] = [%Section1 as VBoxContainer, %Section2 as VBoxContainer]
## Hairline between the two sections of a die sheet.
@onready var _divider: Panel = %Divider

# --- Member functions ---

## Ready callback: start hidden.
func _ready() -> void:
	hide()

## Show one or two definitions next to `anchor` (parent-local), inside `bounds` (parent-local
## size), so the explanation always opens beside what asked for it. `eyebrows` supplies each
## section's family caption, in the same order as `definitions`. `above_first` tries the
## space above the source before the space below it: on a touch screen the finger that
## asked covers what lies under it.
func present(anchor: Rect2, bounds: Vector2, eyebrows: PackedStringArray, definitions: Array[BuildDefinition], words: KeywordCatalog, locale: String, above_first: bool = false) -> void:
	var width: float = clampf(bounds.x - MARGIN * 2.0, NARROWEST, WIDTH)
	var version: int = await _fill(width, eyebrows, definitions, words, locale)
	if version != _version or not is_inside_tree():
		return
	var above: float = anchor.position.y - GAP - MARGIN
	var below: float = bounds.y - MARGIN - anchor.end.y - GAP
	var left: float = anchor.position.x - GAP - MARGIN
	var right: float = bounds.x - MARGIN - anchor.end.x - GAP
	var shown: Vector2 = size
	var place: Vector2
	var first: float = above if above_first else below
	var second: float = below if above_first else above
	if first >= size.y or second >= size.y:
		var go_up: bool = (above_first and above >= size.y) or (not above_first and below < size.y)
		place = _vertical(anchor, shown, go_up)
	elif maxf(left, right) >= size.x and size.y <= bounds.y - MARGIN * 2.0:
		# A source in a tall column (a phone's side rail) explains itself sideways.
		var x: float = anchor.position.x - GAP - size.x if left >= size.x else anchor.end.x + GAP
		place = Vector2(x, anchor.get_center().y - size.y * 0.5)
	else:
		# No side has room: shrink a little into the roomier of above and below.
		var go_up: bool = above > below
		shown = size * clampf(maxf(above, below) / maxf(size.y, 1.0), SMALLEST_FIT, 1.0)
		place = _vertical(anchor, shown, go_up)
	place.x = clampf(place.x, MARGIN, maxf(MARGIN, bounds.x - shown.x - MARGIN))
	place.y = clampf(place.y, MARGIN, maxf(MARGIN, bounds.y - shown.y - MARGIN))
	# The card scales about its center, so its unscaled corner sits half the difference out.
	_settle(place - (size - shown) * 0.5, shown.x / maxf(size.x, 1.0))

## Hide and cancel any pending placement.
func dismiss() -> void:
	_version += 1
	hide()

## Write the sections and lay the card out offscreen at `width`, so wrapped text has its
## final height before placement. Returns the request's version; a newer request or a
## dismissal changes `_version` and makes the caller stand down.
func _fill(width: float, eyebrows: PackedStringArray, definitions: Array[BuildDefinition], words: KeywordCatalog, locale: String) -> int:
	_version += 1
	var version: int = _version
	for index: int in _sections.size():
		var section: VBoxContainer = _sections[index]
		section.visible = index < definitions.size()
		if not section.visible:
			continue
		var definition: BuildDefinition = definitions[index]
		(section.get_node("Eyebrow") as Label).text = eyebrows[index]
		(section.get_node("Title") as Label).text = words.render(definition.name_keyword, {}, locale)
		(section.get_node("Description") as KeywordText).configure(definition.describe_rich(words, locale), definition.describe(words, locale), words, locale)
	_divider.visible = definitions.size() > 1
	custom_minimum_size.x = width
	position = Vector2(-10000.0, -10000.0)
	size = Vector2(width, 0.0)
	show()
	await get_tree().process_frame
	if version == _version and is_inside_tree():
		reset_size()
	return version

## Top-left corner of a card of `shown` size centered over or under `anchor`.
func _vertical(anchor: Rect2, shown: Vector2, up: bool) -> Vector2:
	var y: float = anchor.position.y - GAP - shown.y if up else anchor.end.y + GAP
	return Vector2(anchor.get_center().x - shown.x * 0.5, y)

## Move the laid-out card into place at `fit` scale, with a small pop.
func _settle(place: Vector2, fit: float) -> void:
	position = place
	pivot_offset = size * 0.5
	scale = Vector2.ONE * fit
	if not reduced_motion:
		scale = Vector2.ONE * fit * 0.9
		create_tween().tween_property(self, "scale", Vector2.ONE * fit, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
