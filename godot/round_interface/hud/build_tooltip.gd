extends PanelContainer
class_name BuildTooltip
## Hover card explaining one owned upgrade, bonus, or Joker with its authored description.
## Read-only: it renders definition text and never evaluates rules.

# --- Member variables ---

## Removes the pop-in.
var reduced_motion: bool = false
## Invalidates deferred placement when another card takes over or the pointer leaves.
var _version: int = 0
## Family caption, tinted by keyword role.
@onready var _eyebrow: Label = %Eyebrow
## Localized definition name.
@onready var _title: Label = %Title
## Authored rule text with colored keywords; nested glossary popups stay disabled here.
@onready var _description: KeywordText = %Description

# --- Member functions ---

## Ready callback: start hidden.
func _ready() -> void:
	hide()

## Show a definition beside `anchor` (parent-local rectangle), inside `bounds` (parent-local size).
func present(anchor: Rect2, bounds: Vector2, eyebrow: String, definition: BuildDefinition, words: KeywordCatalog, locale: String) -> void:
	_version += 1
	var version: int = _version
	_eyebrow.text = eyebrow
	_title.text = words.render(definition.name_keyword, {}, locale)
	_description.configure(definition.describe_rich(words, locale), definition.describe(words, locale), words, locale)
	# Lay out offscreen first so wrapped text has its final height before placement.
	position = Vector2(-10000.0, -10000.0)
	size = Vector2(custom_minimum_size.x, 0.0)
	show()
	await get_tree().process_frame
	if version != _version or not is_inside_tree():
		return
	reset_size()
	var place: Vector2 = Vector2(anchor.get_center().x - size.x * 0.5, anchor.end.y + 12.0)
	if place.y + size.y > bounds.y - 10.0:
		place.y = anchor.position.y - size.y - 12.0
	place.x = clampf(place.x, 10.0, maxf(10.0, bounds.x - size.x - 10.0))
	position = place
	if not reduced_motion:
		pivot_offset = size * 0.5
		scale = Vector2.ONE * 0.9
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Hide and cancel any pending placement.
func dismiss() -> void:
	_version += 1
	hide()
