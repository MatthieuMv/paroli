extends Control
class_name DieDock
## One die's column below the table: its upgrade name and its single bonus slot.
## The whole column is one hover and tap target, so a die's equipment is easy to inspect
## with a pointer or a finger. The HUD aligns each dock with the die's screen column.
##
## Columns narrower than the authored footprint (phones) keep the name at a readable size
## instead of shrinking it: the tile follows the column width, and names alternate between
## two lanes so each may span two columns.

# --- Signals ---

## Pointer entered or left a column that has something to explain.
signal hover_changed(dock: DieDock, hovered: bool)
## Primary press or tap on the column, with or without equipment. Round screens pin its
## explanation; shop screens also treat the column as a destination.
signal pressed(dock: DieDock)

# --- Constants ---

## Largest and smallest font sizes tried for the upgrade name.
const NAME_SIZES: PackedInt32Array = [14, 13, 12, 11, 10]
## Sizes tried on narrow columns: every name starts at the same modest size.
const NARROW_NAME_SIZES: PackedInt32Array = [12, 11, 10]
## Width the name tag may take before its font shrinks, on a full-size column.
const NAME_WIDTH: float = 112.0
## Authored footprint, used whenever die columns are at least this far apart.
const FULL_SIZE: Vector2 = Vector2(104.0, 126.0)
## Authored bonus tile side; narrow columns scale the tile down from it.
const TILE: float = 88.0
## Smallest bonus tile side: still a comfortable touch target.
const SMALLEST_TILE: float = 44.0
## Height of one name lane on a narrow column.
const LANE: float = 24.0

# --- Static functions ---

## Footprint of a dock for die columns `spacing` HUD units apart.
static func footprint(spacing: float) -> Vector2:
	if spacing >= FULL_SIZE.x:
		return FULL_SIZE
	# Two units narrower than the column, so neighboring docks never share an edge.
	return Vector2(spacing - 2.0, LANE * 2.0 + 4.0 + tile_side(spacing) + 2.0)

## Bonus tile side for die columns `spacing` HUD units apart.
static func tile_side(spacing: float) -> float:
	return clampf(spacing - 4.0, SMALLEST_TILE, TILE)

# --- Member variables ---

## Permanent die identity this column represents.
var die_id: StringName
## Installed upgrade, or null for an ordinary die.
var upgrade: UpgradeDefinition
## Equipped bonus, or null for a free slot.
var bonus: BonusDefinition
## Bonus slot tile; exposed so the HUD can route eligibility and triggers.
@onready var card: BuildCard = $Card
## Name tag tinted with the die's permanent color.
@onready var _tag: PanelContainer = $Tag
## Upgrade name, or the plain die label.
@onready var _name: Label = $Tag/Name
## Width the name tag may take; a longer name shrinks, then ends in an ellipsis.
var _name_limit: float = NAME_WIDTH
## Top of the name tag inside the dock: zero, or one lane down on a narrow column.
var _tag_top: float = 0.0
## Font sizes tried for the name, largest first.
var _name_sizes: PackedInt32Array = NAME_SIZES
## Smallest name tag, so short names still read as tags.
var _tag_floor: Vector2 = Vector2(72.0, 28.0)

# --- Member functions ---

## Ready callback: the column, not its parts, answers the pointer.
func _ready() -> void:
	mouse_entered.connect(_on_pointer.bind(true))
	mouse_exited.connect(_on_pointer.bind(false))

## Bind the column to a die and show its current equipment.
func show_die(die_id_: StringName, position_in_run: int, upgrade_: UpgradeDefinition, bonus_: BonusDefinition, words: KeywordCatalog, locale: String) -> void:
	die_id = die_id_
	upgrade = upgrade_
	bonus = bonus_
	var style: StyleBoxFlat = _tag.get_theme_stylebox("panel") as StyleBoxFlat
	if upgrade_:
		_name.text = words.render(upgrade_.name_keyword, {}, locale)
		var body: Color = GameColors.PALETTE.get(String(upgrade_.palette_color), GameColors.CHALK)
		style.bg_color = body.lerp(GameColors.CONTROL_SURFACE, 0.25)
		_tag.modulate.a = 1.0
	else:
		_name.text = "%s %d" % [words.render(&"die", {}, locale), position_in_run]
		style.bg_color = GameColors.CONTROL_SURFACE
		_tag.modulate.a = 0.6
	_place_tag()
	mouse_default_cursor_shape = Control.CURSOR_HELP if has_details() else Control.CURSOR_ARROW
	if bonus_:
		card.show_definition(bonus_, StringName("bonus:" + String(die_id_)))
	else:
		card.clear()

## Size the dock for die columns `spacing` HUD units apart. `lane` (0 or 1) picks the name
## lane on narrow columns; neighbors take different lanes so their names never collide.
func fit(spacing: float, lane: int) -> void:
	var narrow: bool = spacing < FULL_SIZE.x
	var foot: Vector2 = footprint(spacing)
	var side: float = tile_side(spacing)
	custom_minimum_size = foot
	size = foot
	card.scale = Vector2.ONE * side / TILE
	card.position = Vector2((foot.x - side) * 0.5, foot.y - side - 2.0)
	# Names in one lane sit two columns apart; each may take nearly all of that.
	_name_limit = spacing * 2.0 - 6.0 if narrow else maxf(NAME_WIDTH, spacing - 6.0)
	_name_sizes = NARROW_NAME_SIZES if narrow else NAME_SIZES
	_tag_top = LANE * float(lane) if narrow else 0.0
	# Narrow tags trade padding and height for text.
	var style: StyleBoxFlat = _tag.get_theme_stylebox("panel") as StyleBoxFlat
	style.content_margin_left = 7.0 if narrow else 11.0
	style.content_margin_right = style.content_margin_left
	style.content_margin_top = 2.0 if narrow else 3.0
	style.content_margin_bottom = 3.0 if narrow else 4.0
	_tag_floor = Vector2(40.0, 23.0) if narrow else Vector2(72.0, 28.0)
	_place_tag()

## Whether this die has an upgrade or a bonus to explain.
func has_details() -> bool:
	return upgrade != null or bonus != null

## Fit the name into its lane: long names shrink a little, then end in an ellipsis, rather
## than spilling into the neighboring column's tag.
func _place_tag() -> void:
	var style: StyleBoxFlat = _tag.get_theme_stylebox("panel") as StyleBoxFlat
	var padding: float = style.content_margin_left + style.content_margin_right
	var font: Font = _name.get_theme_font("font")
	var width: float = 0.0
	for font_size: int in _name_sizes:
		_name.add_theme_font_size_override("font_size", font_size)
		width = font.get_string_size(_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if width + padding <= _name_limit:
			break
	# The label trims with an ellipsis, so the tag's own width decides how much text shows.
	_tag.custom_minimum_size = Vector2(minf(maxf(_tag_floor.x, ceilf(width + padding) + 2.0), _name_limit), _tag_floor.y)
	_tag.reset_size()
	_tag.position = Vector2((size.x - _tag.size.x) * 0.5, _tag_top)

## Hover lifts the bonus tile and nudges the name tag.
func _on_pointer(entered: bool) -> void:
	if not has_details():
		return
	card.set_hovered(entered)
	hover_changed.emit(self, entered)

## A primary press or tap asks the HUD to pin this die's explanation.
func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(self)
		accept_event()
