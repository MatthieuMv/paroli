extends PanelContainer
class_name BuildTooltip
## Explanation card for owned content: one section for a Joker, or a die sheet with its
## upgrade and bonus. Read-only: it renders authored text and never evaluates rules.

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

## Show one or two definitions beside `anchor` (parent-local), inside `bounds` (parent-local size).
## `eyebrows` supplies each section's family caption, in the same order as `definitions`.
func present(anchor: Rect2, bounds: Vector2, eyebrows: PackedStringArray, definitions: Array[BuildDefinition], words: KeywordCatalog, locale: String) -> void:
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
	place.y = maxf(10.0, place.y)
	position = place
	if not reduced_motion:
		pivot_offset = size * 0.5
		scale = Vector2.ONE * 0.9
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Hide and cancel any pending placement.
func dismiss() -> void:
	_version += 1
	hide()
