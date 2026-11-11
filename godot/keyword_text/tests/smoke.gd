extends SceneTree
## Exercise real rich-label hit testing, pointer pinning, dismissal, localization, and popup bounds.

# --- Constants ---

## Catalog integration supplies a real scrolling layout and the production keyword component.
const VIEWER: PackedScene = preload("res://debug/catalog_viewer/catalog_viewer.tscn")

# --- Member functions ---

## Start after root initialization.
func _initialize() -> void:
	_run.call_deferred()

## Inspect both orientations and languages with native mouse events.
func _run() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1280, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.notify_mouse_entered()
	var viewer: CatalogViewer = VIEWER.instantiate() as CatalogViewer
	viewport.add_child(viewer)
	await _settle()
	for dimensions: Vector2i in [Vector2i(1280, 900), Vector2i(390, 844)]:
		viewport.size = dimensions
		viewer._select_language(0 if dimensions.x > 1000 else 1)
		await _settle()
		var entry: CatalogEntry = viewer._cards.get_child(0) as CatalogEntry
		var label: KeywordText = entry._description
		var point: Vector2 = await _find_keyword(viewport, label)
		assert(point != Vector2.ZERO, "Could not hover a real keyword")
		assert(label._popup.visible)
		assert("[color=#" in label.text and "[u]" not in label.text)
		assert(not label.is_meta_underlined())
		assert("[bgcolor=" in label.text)
		await _mouse(viewport, point, true)
		await _mouse(viewport, point, false)
		assert(label._pinned, "Click did not pin tooltip")
		var motion: InputEventMouseMotion = InputEventMouseMotion.new()
		motion.position = Vector2(2, 2)
		viewport.push_input(motion)
		await _settle()
		assert(label._popup.visible, "Pinned tooltip vanished on pointer exit")
		assert(viewport.get_visible_rect().encloses(label._popup.get_global_rect()), "Tooltip clipped")
		assert(label._body.text == viewer._words.find_keyword(label._active).explanation(label._locale))
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png("/tmp/paroli-keywords-%d.png" % dimensions.x)
		var outside: InputEventScreenTouch = InputEventScreenTouch.new()
		outside.position = Vector2(2, 2)
		outside.pressed = true
		viewport.push_input(outside)
		await _settle()
		assert(not label._popup.visible, "Outside touch did not dismiss")
		outside = InputEventScreenTouch.new()
		outside.position = Vector2(2, 2)
		outside.pressed = false
		viewport.push_input(outside)
		# A real primary touch must activate the same link without requiring hover.
		var tap: InputEventScreenTouch = InputEventScreenTouch.new()
		tap.position = point
		tap.pressed = true
		viewport.push_input(tap)
		tap = InputEventScreenTouch.new()
		tap.position = point
		tap.pressed = false
		viewport.push_input(tap)
		await _settle()
		assert(label._pinned)
		label.meta_clicked.emit(String(label._active))
		assert(not label._popup.visible)
		# A scrolling gesture starting on a keyword must not become a tap on release.
		var start: InputEventScreenTouch = InputEventScreenTouch.new()
		start.position = point
		start.pressed = true
		viewport.push_input(start)
		var drag: InputEventScreenDrag = InputEventScreenDrag.new()
		drag.position = point + Vector2(0, 30)
		viewport.push_input(drag)
		var end: InputEventScreenTouch = InputEventScreenTouch.new()
		end.position = point
		end.pressed = false
		viewport.push_input(end)
		await _settle()
		assert(not label._pinned, "Scrolling activated a keyword")
		label.meta_clicked.emit("mult")
		viewer._select_family(1)
		await _settle()
		assert(not is_instance_valid(label), "Changing tabs retained an orphan tooltip")
		viewer._select_family(0)
	viewer._select_family(2)
	viewer._select_language(0)
	viewport.size = Vector2i(1280, 900)
	await _settle()
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/paroli-colored-jokers.png")
	viewer.queue_free()
	await process_frame
	viewport.size = Vector2i(390, 844)
	var popup_scene: PackedScene = load("res://keyword_text/keyword_text.tscn") as PackedScene
	var bottom: KeywordText = popup_scene.instantiate() as KeywordText
	viewport.add_child(bottom)
	bottom.position = Vector2(24, 720)
	bottom.size.x = 330
	bottom.configure("[url=mult]Mult[/url]", "Mult", GameKeywords.new(), "fr")
	await _settle()
	var anchor: Vector2 = await _find_keyword(viewport, bottom)
	assert(anchor != Vector2.ZERO)
	await _settle()
	assert(bottom._popup.visible, "Popup stole hover from its keyword")
	assert(bottom._popup.get_global_rect().end.y <= bottom._keyword_line.position.y - 8.0, "Bottom popup did not flip above its keyword")
	assert(not bottom._popup.get_global_rect().has_point(anchor), "Popup covers triggering keyword")
	assert(not bottom._popup.has_node("Content/Header/Close"))
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/paroli-keywords-bottom.png")
	viewport.queue_free()
	await process_frame
	print("PASS: keyword hit testing, highlighting, pinning, touch dismissal, locale, bounds, and cleanup")
	quit()

## Locate a real rendered link through hit testing rather than assumptions about font metrics.
func _find_keyword(viewport: SubViewport, label: KeywordText) -> Vector2:
	var rect: Rect2 = label.get_global_rect()
	for y: int in range(int(rect.position.y), int(rect.end.y), 8):
		for x: int in range(int(rect.position.x), int(rect.end.x), 12):
			var point: Vector2 = Vector2(x, y)
			var motion: InputEventMouseMotion = InputEventMouseMotion.new()
			motion.position = point
			viewport.push_input(motion)
			await process_frame
			if label._active != &"":
				return point
	return Vector2.ZERO

## Dispatch primary press/release through the viewport's GUI routing.
func _mouse(viewport: SubViewport, point: Vector2, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	viewport.push_input(event)
	await _settle()

## Wrapped text and popup containers need several layout passes after a resize.
func _settle() -> void:
	for frame: int in 8:
		await process_frame
