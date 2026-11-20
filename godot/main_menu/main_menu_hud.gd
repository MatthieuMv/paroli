extends Control
class_name MainMenuHud
## Main menu overlay: the game's title above the table, the actions under it, and the
## settings button. It lays itself out with the table screens' `HudLayout`, so the table
## stays where it is when a run replaces the menu. It reports intents; the host acts on them.

# --- Signals ---

## The player pressed New run.
signal new_run_pressed
## The player pressed Quit.
signal quit_pressed
## The pointer reached an available action; hosts may tick a sound.
signal hover_ticked

# --- Constants ---

## Largest title font size; it shrinks to fit narrow rails.
const TITLE_SIZE: int = 112
## Smallest title font size.
const SMALLEST_TITLE_SIZE: int = 40
## Share of the title's area height the title may take.
const TITLE_HEIGHT_SHARE: float = 0.78
## Width of the New run button where there is room for it.
const PRIMARY_WIDTH: float = 260.0
## Width of the Quit button where there is room for it.
const SECONDARY_WIDTH: float = 170.0
## Clear space kept between the actions and the edge of their area.
const ACTION_MARGIN: float = 14.0
## Outer margin of the settings button on desktop windows.
const WIDE_MARGIN: float = 28.0
## Outer margin of the settings button on phones.
const PHONE_MARGIN: float = 14.0

# --- Member variables ---

## Removes the title's pop-in and the buttons' springs.
var reduced_motion: bool = false:
	set(value):
		reduced_motion = value
		if is_node_ready():
			settings.reduced_motion = value
## Arrangement solved by the last `arrange()`.
var layout: HudLayout
## Settings button and card; hosts may listen to it.
@onready var settings: SettingsMenu = $Settings
## The game's name.
@onready var _title: Label = $Title
## Row (or column, on side rails) holding the actions.
@onready var _actions: BoxContainer = $Actions
## Starts a fresh run.
@onready var _new_run: Button = %NewRun
## Leaves the game; only offered where an app can close itself.
@onready var _quit: Button = %Quit
## Glossary for the captions.
var _words: KeywordCatalog = GameKeywords.new()

# --- Member functions ---

## Ready callback: connect the actions and write the captions.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Browsers and phones close apps themselves; a Quit button there would do nothing useful.
	_quit.visible = not (OS.has_feature("web") or OS.has_feature("mobile"))
	for button: Button in [_new_run, _quit]:
		button.mouse_entered.connect(_on_hover.bind(button))
		button.button_up.connect(_on_release.bind(button))
	_new_run.pressed.connect(new_run_pressed.emit)
	_quit.pressed.connect(quit_pressed.emit)
	settings.reduced_motion = reduced_motion
	relabel()

## Lay out for a window size and return the rectangle (window pixels) kept for the table.
## `density` is window pixels per logical pixel; zero asks the display. The table is the one
## the round frames, so it stays put when a run replaces the menu. Call `fit_around()` once
## the stage has framed it.
func arrange(viewport: Vector2, density: float = 0.0) -> Rect2:
	layout = HudLayout.solve(viewport, density)
	scale = Vector2.ONE * layout.ui_scale
	position = Vector2.ZERO
	size = layout.size
	# The settings button keeps the top-right corner on every shape; portrait already
	# solves it clear of cutouts.
	var margin: float = WIDE_MARGIN if layout.shape == HudLayout.Shape.WIDE else PHONE_MARGIN
	var gear: Rect2 = Rect2(size.x - margin - HudLayout.GEAR, margin, HudLayout.GEAR, HudLayout.GEAR)
	if layout.shape == HudLayout.Shape.TALL:
		gear = layout.settings
	settings.arrange(size, gear)
	return Rect2(layout.table.position * layout.ui_scale, layout.table.size * layout.ui_scale)

## Place the title and actions in the space the framed table leaves (`table` in window
## pixels). The felt can run wider than its layout slot, so this follows the drawn table.
func fit_around(table_pixels: Rect2) -> void:
	var table: Rect2 = Rect2(table_pixels.position / layout.ui_scale, table_pixels.size / layout.ui_scale)
	var title_area: Rect2
	var action_area: Rect2
	if layout.shape == HudLayout.Shape.SIDE:
		# Phone landscape: the table fills the height; the title takes the left rail and the
		# actions the right one, under the thumb.
		title_area = Rect2(0.0, 0.0, maxf(table.position.x, 0.0), size.y)
		action_area = Rect2(table.end.x, 0.0, maxf(size.x - table.end.x, 0.0), size.y)
	else:
		# Desktop and portrait: the title fills the space over the table, the actions the
		# tray under it.
		title_area = Rect2(0.0, 0.0, size.x, maxf(table.position.y, 0.0))
		action_area = Rect2(0.0, table.end.y, size.x, maxf(size.y - table.end.y, 0.0))
	_place_title(title_area)
	_place_actions(action_area, layout.shape == HudLayout.Shape.SIDE)

## Write the captions in the current language.
func relabel() -> void:
	_new_run.text = _words.render(&"ui.menu.new_run", {}, "")
	_quit.text = _words.render(&"ui.menu.quit", {}, "")

## Pop the title in, as the dice land under it.
func present() -> void:
	if not reduced_motion:
		Juice.pop_in(_title, 0.42)

## Give the title a small squash, for a die landing nearby.
func nudge_title() -> void:
	if not reduced_motion:
		Juice.punch(_title, 0.06, 0.35)

## Center the title in its area and shrink it until it fits both ways.
func _place_title(area: Rect2) -> void:
	var inner: Rect2 = area.grow(-PHONE_MARGIN)
	var font: Font = _title.get_theme_font("font")
	var largest: int = clampi(int(inner.size.y * TITLE_HEIGHT_SHARE), SMALLEST_TITLE_SIZE, TITLE_SIZE)
	var font_size: int = largest
	var outline: float = float(_title.get_theme_constant("outline_size"))
	while font_size > SMALLEST_TITLE_SIZE and font.get_string_size(_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + outline > inner.size.x:
		font_size -= 2
	# Size the font first: a label never shrinks below the width its current font needs.
	_title.add_theme_font_size_override("font_size", font_size)
	_title.position = inner.position
	_title.size = inner.size
	_title.pivot_offset = _title.size * 0.5

## Size the actions to their area and center them there; side rails stack them.
func _place_actions(area: Rect2, stacked: bool) -> void:
	var room: float = area.size.x - ACTION_MARGIN * 2.0
	_actions.vertical = stacked
	if stacked:
		_new_run.custom_minimum_size.x = minf(PRIMARY_WIDTH, room)
		_quit.custom_minimum_size.x = minf(PRIMARY_WIDTH, room)
	else:
		var both: bool = _quit.visible
		var gap: float = float(_actions.get_theme_constant("separation"))
		var needed: float = PRIMARY_WIDTH + (SECONDARY_WIDTH + gap if both else 0.0)
		var shrink: float = minf(1.0, room / needed)
		_new_run.custom_minimum_size.x = PRIMARY_WIDTH * shrink
		_quit.custom_minimum_size.x = SECONDARY_WIDTH * shrink
	_actions.reset_size()
	var actions_size: Vector2 = _actions.get_combined_minimum_size()
	_actions.size = actions_size
	_actions.position = area.position + (area.size - actions_size) * 0.5
	# Side rails keep the actions low, near the thumb.
	if stacked:
		_actions.position.y = area.end.y - ACTION_MARGIN - actions_size.y

## A small lift acknowledges the pointer.
func _on_hover(button: Button) -> void:
	if button.disabled:
		return
	hover_ticked.emit()
	if not reduced_motion:
		Juice.punch(button, 0.05, 0.3)

## Release springs the button back.
func _on_release(button: Button) -> void:
	if not reduced_motion:
		Juice.punch(button, 0.1, 0.35)
