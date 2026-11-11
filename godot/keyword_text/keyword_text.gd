extends RichTextLabel
class_name KeywordText
## Reusable glossary text: hover to inspect, click/tap to pin, tap outside to dismiss.
## Receives prose and keyword resources only; never installs effects or mutates game state.

# --- Member variables ---

## Plain copy is exposed for search/accessibility without renderer markup.
var plain_text: String
## Explicit locale and catalog belong to the host view.
var _locale: String = "en"
## Keyword explanations are data, independent of the owning card or scene.
var _words: KeywordCatalog
## Original rich text is retained so highlighting never accumulates tags.
var _rich_text: String
## Currently highlighted semantic identity, empty when dismissed.
var _active: StringName
## Click/tap pins the explanation until another selection or dismissal.
var _pinned: bool = false
## Primary touch candidate; dragging scrolls without activating a keyword.
var _touch_index: int = -1
## Viewport-space press origin used to distinguish a tap from a scroll.
var _touch_origin: Vector2

## Last real or synthesized pointer position locates the activated keyword's text line.
var _pointer_position: Vector2
## Captured line bounds remain stable while rich-text highlighting is rebuilt.
var _keyword_line: Rect2
## Invalidates deferred positioning when another keyword or dismissal takes over.
var _placement_version: int = 0

## Popup lives above scrolling/clipped cards in its own canvas layer.
@onready var _popup: PanelContainer = $TooltipLayer/Popup
## Keyword title and prose are plain labels, not recursive interactive tooltips.
@onready var _title: Label = $TooltipLayer/Popup/Content/Header/Title
## Full explanation wraps within the viewport-safe popup width.
@onready var _body: Label = $TooltipLayer/Popup/Content/Body

# --- Member functions ---

## Native rich-label metadata handles mouse and emulated primary touch clicks.
func _ready() -> void:
	# A small weight increase keeps the host font while avoiding synthetic full bold.
	var keyword_font: FontVariation = get_theme_font("bold_font") as FontVariation
	keyword_font.base_font = get_theme_font("normal_font")
	meta_hover_started.connect(_hover_started)
	meta_hover_ended.connect(_hover_ended)
	meta_clicked.connect(_clicked)
	visibility_changed.connect(dismiss)
	get_viewport().size_changed.connect(dismiss)

## Render player-facing prose; the caller supplies both rich display and searchable plain text.
func configure(rich_text: String, plain: String, words: KeywordCatalog, locale: String) -> void:
	dismiss()
	_rich_text = _color_keywords(rich_text, words)
	plain_text = plain
	_words = words
	_locale = locale
	text = _rich_text

## Clear transient and pinned explanations when content changes or the view is hidden.
func dismiss() -> void:
	_placement_version += 1
	_touch_index = -1
	_active = &""
	_pinned = false
	if is_node_ready():
		_popup.hide()
	text = _rich_text

## Renderer-owned URL metadata is always a string; only known keyword IDs are accepted.
func _hover_started(meta: String) -> void:
	if not _pinned:
		_show(StringName(str(meta)))

## Hover explanations disappear immediately; pinned touch/click explanations remain readable.
func _hover_ended(_meta: String) -> void:
	if not _pinned:
		dismiss()

## A second activation of the same term toggles its pinned explanation off.
func _clicked(meta: String) -> void:
	var id: StringName = StringName(str(meta))
	if _pinned and _active == id:
		dismiss()
	else:
		_show(id)
		_pinned = _active != &""

## Resolve only trusted keyword IDs, highlight the term, then place the authored popup.
func _show(id: StringName) -> void:
	var keyword: KeywordDefinition = _words.find_keyword(id) if _words else null
	if not keyword or keyword.explanation(_locale).is_empty():
		return
	_keyword_line = _keyword_line_rect()
	_placement_version += 1
	_active = id
	_title.text = keyword.template(_locale)
	_body.text = keyword.explanation(_locale)
	_title.add_theme_color_override("font_color", KeywordColors.for_role(keyword.color_role))
	var pattern: RegEx = RegEx.new()
	pattern.compile("(?s)(\\[url=" + String(id).replace(".", "\\.") + "\\])(.*?)(\\[/url\\])")
	text = pattern.sub(_rich_text, "$1[bgcolor=#%s40]$2[/bgcolor]$3" % GameColors.BUTTER.to_html(false), true)
	# Layout offscreen first so a newly opened popup never steals the keyword hover.
	_popup.position = Vector2(-10000, -10000)
	_popup.show()
	_place_popup.call_deferred()

## Capture the actual text line under the pointer, rather than the bottom of the whole label.
func _keyword_line_rect() -> Rect2:
	var transform_: Transform2D = get_global_transform_with_canvas()
	var local_point: Vector2 = transform_.affine_inverse() * _pointer_position
	for line: int in get_line_count():
		var top: float = get_line_offset(line)
		var height: float = float(get_line_height(line))
		if local_point.y >= top and local_point.y < top + height:
			return transform_ * Rect2(Vector2(local_point.x, top), Vector2(1, height))
	# Programmatic activation has no hit position; keep the popup outside the label.
	return get_global_rect()

## Measure wrapped copy before deciding below versus above; never clamp upward across the trigger.
func _place_popup() -> void:
	if not is_inside_tree() or not _popup.visible:
		return
	var version: int = _placement_version
	var bounds: Vector2 = get_viewport_rect().size
	_popup.custom_minimum_size.x = minf(340.0, bounds.x - 24.0)
	_popup.size = Vector2(_popup.custom_minimum_size.x, 0)
	await get_tree().process_frame
	if not is_inside_tree() or version != _placement_version or not _popup.visible:
		return
	_popup.size.y = _popup.get_combined_minimum_size().y
	var position_: Vector2 = Vector2(_keyword_line.position.x, _keyword_line.end.y + 8.0)
	if position_.y + _popup.size.y > bounds.y - 12.0:
		position_.y = _keyword_line.position.y - _popup.size.y - 8.0
	position_.x = clampf(position_.x, 12.0, maxf(12.0, bounds.x - _popup.size.x - 12.0))
	position_.y = maxf(12.0, position_.y)
	_popup.position = position_

## Outside presses dismiss without consuming the event, preserving scrolling and other controls.
func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_pointer_position = (event as InputEventMouse).position
	if not is_visible_in_tree():
		return
	# Handle physical taps explicitly, including embedded viewports. Ignore the engine's
	# duplicate emulated mouse over this label; real mouse input remains native.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		if get_global_rect().has_point((event as InputEventMouse).position):
			get_viewport().set_input_as_handled()
			return
	if event is InputEventScreenTouch:
		var finger: InputEventScreenTouch = event as InputEventScreenTouch
		if finger.pressed and _touch_index == -1 and get_global_rect().has_point(finger.position) and not (_popup.visible and _popup.get_global_rect().has_point(finger.position)):
			_touch_index = finger.index
			_touch_origin = finger.position
		elif not finger.pressed and finger.index == _touch_index:
			_touch_index = -1
			if finger.position.distance_to(_touch_origin) <= 12.0 and get_global_rect().has_point(finger.position):
				_tap.call_deferred(finger.position)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.index == _touch_index and drag.position.distance_to(_touch_origin) > 12.0:
			_touch_index = -1
	if not _pinned:
		return
	var pressed: bool = false
	var point: Vector2 = Vector2.ZERO
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		pressed = mouse.pressed
		point = mouse.position
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		pressed = touch.pressed
		point = touch.position
	if pressed and not _popup.get_global_rect().has_point(point) and not get_global_rect().has_point(point):
		dismiss()

## Route one completed tap through native rich-text hit testing, avoiding guessed text coordinates.
func _tap(point: Vector2) -> void:
	if not is_inside_tree() or not is_visible_in_tree():
		return
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	get_viewport().push_input(motion)
	# Hover highlighting reparses the rich label; wait for its hit regions to settle.
	await get_tree().process_frame
	if not is_inside_tree() or not is_visible_in_tree():
		return
	for pressed: bool in [true, false]:
		var click: InputEventMouseButton = InputEventMouseButton.new()
		click.position = point
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		get_viewport().push_input(click)

## Add semantic palette colors at the UI boundary; mechanics emits only keyword metadata.
func _color_keywords(source: String, words: KeywordCatalog) -> String:
	var result: String = source
	for keyword: KeywordDefinition in words.keywords:
		var opening: String = "[url=%s]" % keyword.id
		if opening not in result:
			continue
		var pattern: RegEx = RegEx.new()
		pattern.compile("(?s)(\\[url=" + String(keyword.id).replace(".", "\\.") + "\\])(.*?)(\\[/url\\])")
		var color: String = KeywordColors.for_role(keyword.color_role).to_html(false)
		result = pattern.sub(result, "$1[color=#%s][b]$2[/b][/color]$3" % color, true)
	return result
