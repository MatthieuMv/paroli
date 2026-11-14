extends Button
class_name AugmentCard
## Live die choice with an isolated 3D world and native particle/activation playback.

# --- Signals ---

## Relays the full native animation completion, including trailing particles.
signal activation_finished

# --- Member variables ---

## Identity copied from the host-supplied definition; no gameplay state is owned here.
var upgrade_id: StringName
## Content minimum follows wrapped copy at every viewport size.
@onready var _layout: BoxContainer = $Margin/Layout
## Authored container owns the preview's responsive minimum size.
@onready var _preview: SubViewportContainer = $Margin/Layout/Preview
## Each card owns its die, materials, particles, camera, and viewport.
@onready var _die: ParoliDie = $Margin/Layout/Preview/Viewport/Die

# --- Member functions ---

## Connect animation signals without reaching into the die's private hierarchy.
func _ready() -> void:
	_die.activation_finished.connect(_on_activation_finished)
	_die.rolled.connect(_on_preview_settled)
	visibility_changed.connect(_on_visibility_changed)
	_layout.minimum_size_changed.connect(_fit_content)
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
	($Margin/Layout/Copy/Title as Label).text = words.render(String(upgrade.name_keyword), {}, locale)
	($Margin/Layout/Copy/Description as Label).text = upgrade.describe(words, locale)
	_die.reduced_motion = true
	_die.roll(upgrade.faces[0] if not upgrade.faces.is_empty() else 6)

## Keep all three dice visible in portrait while leaving room for their VFX.
func set_compact(compact: bool, short_view: bool = false) -> void:
	_layout.vertical = not compact
	var height: float = 136.0 if compact else (120.0 if short_view else 246.0)
	_preview.custom_minimum_size = Vector2(112 if compact else 100, height)
	_preview.size_flags_horizontal = Control.SIZE_FILL if compact else Control.SIZE_EXPAND_FILL
	($Margin/Layout/Copy/Title as Label).add_theme_font_size_override("font_size", 21 if compact else 25)
	_fit_content.call_deferred()

## Buttons do not inherit child minima; include wrapped labels and outer padding.
func _fit_content() -> void:
	custom_minimum_size.y = _layout.get_combined_minimum_size().y + 44.0

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

## Tell the overlay when it is safe to dismiss the selected card.
func _on_activation_finished() -> void:
	activation_finished.emit()
