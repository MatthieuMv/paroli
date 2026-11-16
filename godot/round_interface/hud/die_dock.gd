extends Control
class_name DieDock
## One die's column below the table: its upgrade name and its single bonus slot.
## The whole column is one hover and tap target, so a die's equipment is easy to inspect
## with a pointer or a finger. The HUD aligns each dock with the die's screen column.

# --- Signals ---

## Pointer entered or left a column that has something to explain.
signal hover_changed(dock: DieDock, hovered: bool)
## Primary press or tap on the column, with or without equipment. Round screens pin its
## explanation; shop screens also treat the column as a destination.
signal pressed(dock: DieDock)

# --- Constants ---

## Largest and smallest font sizes tried for the upgrade name.
const NAME_SIZES: PackedInt32Array = [14, 13, 12, 11]
## Width the name tag may take before its font shrinks.
const NAME_WIDTH: float = 112.0

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
	# Long names shrink a little rather than spilling into the neighboring column.
	var font: Font = _name.get_theme_font("font")
	for font_size: int in NAME_SIZES:
		_name.add_theme_font_size_override("font_size", font_size)
		if font.get_string_size(_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 22.0 <= NAME_WIDTH:
			break
	_tag.reset_size()
	_tag.position.x = (size.x - _tag.size.x) * 0.5
	mouse_default_cursor_shape = Control.CURSOR_HELP if has_details() else Control.CURSOR_ARROW
	if bonus_:
		card.show_definition(bonus_, StringName("bonus:" + String(die_id_)))
	else:
		card.clear()

## Whether this die has an upgrade or a bonus to explain.
func has_details() -> bool:
	return upgrade != null or bonus != null

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
