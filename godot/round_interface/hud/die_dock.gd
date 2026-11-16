extends Control
class_name DieDock
## One die's column below the table: its upgrade name tag and its single bonus slot.
## The HUD aligns each dock with the die's screen column; the dock never moves dice.

# --- Signals ---

## Pointer entered or left the upgrade tag; the HUD owns the tooltip.
signal tag_hover_changed(dock: DieDock, hovered: bool)

# --- Member variables ---

## Permanent die identity this column represents.
var die_id: StringName
## Installed upgrade, or null for an ordinary die.
var upgrade: UpgradeDefinition
## Bonus slot tile; exposed so the HUD can route eligibility and triggers.
@onready var card: BuildCard = $Card
## Name tag tinted with the die's permanent color.
@onready var _tag: PanelContainer = $Tag
## Upgrade name, or the plain die label.
@onready var _name: Label = $Tag/Name

# --- Member functions ---

## Ready callback: relay tag hover for upgrade tooltips.
func _ready() -> void:
	_tag.mouse_entered.connect(_on_tag_pointer.bind(true))
	_tag.mouse_exited.connect(_on_tag_pointer.bind(false))

## Bind the column to a die and show its current equipment.
func show_die(die_id_: StringName, position_in_run: int, upgrade_: UpgradeDefinition, bonus: BonusDefinition, words: KeywordCatalog, locale: String) -> void:
	die_id = die_id_
	upgrade = upgrade_
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
	# Re-center the tag after its text width changes.
	_tag.reset_size()
	_tag.position.x = (size.x - _tag.size.x) * 0.5
	if bonus:
		card.show_definition(bonus, StringName("bonus:" + String(die_id_)))
	else:
		card.clear()

## Global rectangle of the tag, for tooltip placement.
func tag_rect() -> Rect2:
	return _tag.get_global_rect()

## Only upgraded dice have something to explain.
func _on_tag_pointer(entered: bool) -> void:
	if upgrade:
		tag_hover_changed.emit(self, entered)
