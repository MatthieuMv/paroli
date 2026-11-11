extends Control
class_name DieViewer
## Development-only presentation controls for an independent ParoliDie scene.
## Static layout, theme, viewport, and world nodes are authored in die_viewer.tscn.

# --- Member variables ---

## The viewer talks only to the die's public properties, methods, and signals.
@onready var _die: ParoliDie = %Die
## Orthographic preview camera; no gameplay camera dependency is required.
@onready var _camera: Camera3D = %Camera
## Container dimensions determine how much room large effects receive.
@onready var _preview_container: SubViewportContainer = %PreviewContainer
## Current face and effect summary beneath the preview.
@onready var _status: Label = %Status
## Dynamic palette buttons are the only color-dependent scene children.
@onready var _palette: GridContainer = %Palette
## Dynamic effect choices mirror the die module's supported identifiers.
@onready var _effects: GridContainer = %Effects
## Direct face-selection controls.
@onready var _faces: HBoxContainer = %Faces
## Custom body tint; selecting a named color updates this picker too.
@onready var _body_color: ColorPickerButton = %BodyColor
## Selected swatches are cleared when a custom tint is chosen.
var _palette_buttons: Array[Button] = []

# --- Member functions ---

## Ready callback: connect controls and populate data-dependent choices.
func _ready() -> void:
	_camera.look_at(Vector3(0, 1.8, 0))
	_build_palette()
	_build_effects()
	_connect_controls()
	_preview_container.resized.connect(_resize_preview)
	_die.rolled.connect(_on_rolled)
	_die.consumed.connect(_on_consumed)
	_resize_preview()
	_die.roll(1)

## Create named swatches from the die's typed public palette.
func _build_palette() -> void:
	var group: ButtonGroup = ButtonGroup.new()
	var palette: Dictionary[String, Color] = DieLibrary.palette()
	for color_name: String in palette:
		var tint: Color = palette[color_name]
		var swatch: Button = _choice_button(_palette, color_name, group)
		swatch.button_pressed = color_name == _die.palette_color
		swatch.tooltip_text = color_name + " · " + tint.to_html(false)
		swatch.add_theme_font_size_override("font_size", 13)
		var icon: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		icon.fill(tint)
		swatch.icon = ImageTexture.create_from_image(icon)
		swatch.pressed.connect(_on_palette_selected.bind(color_name))
		_palette_buttons.append(swatch)

## Create effect choices without depending on the particle module's internals.
func _build_effects() -> void:
	var group: ButtonGroup = ButtonGroup.new()
	for id: String in DieLibrary.effect_ids():
		var button: Button = _choice_button(_effects, id.capitalize(), group)
		button.button_pressed = id == _die.effect
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(_on_effect_selected.bind(id))
	for value: int in range(1, 7):
		var button: Button = Button.new()
		button.text = str(value)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_die.roll.bind(value))
		_faces.add_child(button)

## Wire stable controls to typed callbacks; scene layout stays in the editor.
func _connect_controls() -> void:
	(%Roll as Button).pressed.connect(_die.roll)
	(%Replay as Button).pressed.connect(_on_replay)
	(%Activate as Button).pressed.connect(_die.activate)
	(%Shine as Button).toggled.connect(func(enabled: bool) -> void:
		_die.shine_enabled = enabled
	)
	(%Cracks as Button).toggled.connect(func(enabled: bool) -> void:
		_die.cracks_enabled = enabled
	)
	(%ReducedMotion as Button).toggled.connect(func(enabled: bool) -> void:
		_die.reduced_motion = enabled
	)
	_body_color.color_changed.connect(_on_body_color_changed)
	(%InkColor as ColorPickerButton).color_changed.connect(func(color: Color) -> void:
		_die.ink_color = color
	)
	(%ShineColor as ColorPickerButton).color_changed.connect(func(color: Color) -> void:
		_die.shine_color = color
	)
	(%SizeSlider as HSlider).value_changed.connect(_on_size_changed)

## Add a palette or preset toggle to its mutually exclusive group.
func _choice_button(parent: Container, text: String, group: ButtonGroup) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.toggle_mode = true
	button.button_group = group
	parent.add_child(button)
	return button

## Apply a named palette entry and synchronize its custom-color control.
func _on_palette_selected(color_name: String) -> void:
	_die.palette_color = color_name
	_body_color.color = _die.body_color
	_update_status()

## Replace the selected preset and replay the current face's landing.
func _on_effect_selected(id: String) -> void:
	_die.effect = id
	_die.roll(_die.face_value)
	_update_status()

## Replay preserves the face value, unlike the cycling roll control.
func _on_replay() -> void:
	_die.roll(_die.face_value)

## Reflect a settled face without making the viewer the source of die state.
func _on_rolled(_value: int) -> void:
	_update_status()

## Explain how to restore the consumed preview.
func _on_consumed() -> void:
	_status.text = "Consumed · Roll or replay to restore"

## A custom tint clears named swatches while retaining the active effect.
func _on_body_color_changed(color: Color) -> void:
	_die.body_color = color
	for button: Button in _palette_buttons:
		button.button_pressed = false
	_status.text = "Custom body color · #" + color.to_html(false)

## Scale the complete presentation around the preview's visual center.
func _on_size_changed(value: float) -> void:
	_die.scale = Vector3.ONE * value
	_die.position.y = 1.8 * (1 - value)
	(%SizeLabel as Label).text = "Size · %d%%" % roundi(value * 100)

## Preserve enough orthographic room for effects on narrow viewports.
func _resize_preview() -> void:
	var aspect: float = _preview_container.size.x / maxf(_preview_container.size.y, 1.0)
	_camera.size = maxf(8.2, 8.0 / maxf(aspect, 0.1))

## Show the die's current public configuration.
func _update_status() -> void:
	_status.text = "Face %d · %s · %s" % [
		_die.face_value, _die.palette_color, _die.effect.capitalize()
	]
