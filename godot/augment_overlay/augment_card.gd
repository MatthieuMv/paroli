extends Button
class_name AugmentCard
## Live die choice with an isolated 3D world and native particle/activation playback. Its
## copy is written like the HUD's explanation card: family eyebrow, name, and the authored
## description with colored keyword links that open their glossary.

# --- Signals ---

## Relays the full native animation completion, including trailing particles.
signal activation_finished

# --- Constants ---

## Vertical space the card's margins add around its contents (top and bottom).
const CONTENT_MARGIN: float = 32.0

# --- Member variables ---

## Identity copied from the host-supplied definition; no gameplay state is owned here.
var upgrade_id: StringName
## Content minimum follows wrapped copy at every viewport size.
@onready var _layout: BoxContainer = $Margin/Layout
## Authored container owns the preview's responsive minimum size.
@onready var _preview: SubViewportContainer = $Margin/Layout/Preview
## Each card owns its die, materials, particles, camera, and viewport.
@onready var _die: ParoliDie = $Margin/Layout/Preview/Viewport/Die
## Family caption, in spaced eyebrow lettering.
@onready var _eyebrow: Label = $Margin/Layout/Copy/Eyebrow
## Upgrade name.
@onready var _title: Label = $Margin/Layout/Copy/Title
## Authored description; its keywords explain themselves on hover or press.
@onready var _description: KeywordText = $Margin/Layout/Copy/Description
## A press that opened a keyword's explanation; the card ignores the click it belongs to.
var _keyword_press: bool = false

# --- Member functions ---

## Connect animation signals without reaching into the die's private hierarchy.
func _ready() -> void:
	_die.activation_finished.connect(_on_activation_finished)
	_die.rolled.connect(_on_preview_settled)
	visibility_changed.connect(_on_visibility_changed)
	_layout.minimum_size_changed.connect(_fit_content)
	_description.meta_clicked.connect(_on_keyword_clicked)
	button_down.connect(_on_button_down)
	disabled = true
	_on_visibility_changed()

## Display a supplied immutable definition after entering the tree; never evaluate its rules.
func configure(upgrade: UpgradeDefinition, words: KeywordCatalog, locale: String) -> void:
	upgrade_id = upgrade.id
	button_pressed = false
	disabled = false
	_die.palette_color = String(upgrade.palette_color)
	_die.effect = String(upgrade.vfx_id)
	_die.effect_enabled = true
	_die.faces = upgrade.faces if not upgrade.faces.is_empty() else ParoliDie.STANDARD_FACES
	_eyebrow.text = " ".join(words.render(&"upgrade", {}, locale).to_upper().split(""))
	_title.text = words.render(String(upgrade.name_keyword), {}, locale)
	_description.configure(upgrade.describe_rich(words, locale), upgrade.describe(words, locale), words, locale)
	_die.reduced_motion = true
	_die.roll(upgrade.faces[0] if not upgrade.faces.is_empty() else 6)

## Keep all three dice visible in portrait while leaving room for their VFX.
func set_compact(compact: bool, short_view: bool = false) -> void:
	_layout.vertical = not compact
	var height: float = 136.0 if compact else (120.0 if short_view else 246.0)
	_preview.custom_minimum_size = Vector2(112 if compact else 100, height)
	_preview.size_flags_horizontal = Control.SIZE_FILL if compact else Control.SIZE_EXPAND_FILL
	_fit_content.call_deferred()

## Buttons do not inherit child minima; include wrapped labels and outer padding.
func _fit_content() -> void:
	custom_minimum_size.y = _layout.get_combined_minimum_size().y + CONTENT_MARGIN

## Plain copy of the description, as the player reads it.
func description_text() -> String:
	return _description.plain_text

## Whether the last press opened a keyword's explanation instead of choosing this card.
## Reading it clears it, so the next press counts again.
func take_keyword_press() -> bool:
	var taken: bool = _keyword_press
	_keyword_press = false
	if taken:
		set_pressed_no_signal(false)
	return taken

## Finish any initial placement, then run the actual die's authored activation.
func play_activation() -> void:
	if _die.is_rolling():
		await _die.rolled
	_die.activate()

## Only the initial placement is immediate; particle previews and activation stay animated.
func _on_preview_settled(_value: int) -> void:
	_die.reduced_motion = false

## Stop hidden preview simulation; visible cards resume their previous idle animation.
func _on_visibility_changed() -> void:
	_die.set_process(is_visible_in_tree())

## A press on a keyword reads its glossary; remember it so the card does not commit.
func _on_keyword_clicked(_meta: String) -> void:
	_keyword_press = true

## A fresh press starts unclaimed by the description.
func _on_button_down() -> void:
	_keyword_press = false

## Tell the overlay when it is safe to dismiss the selected card.
func _on_activation_finished() -> void:
	activation_finished.emit()
