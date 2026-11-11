extends SceneTree
## Ordered scoring impacts, reset safety, semantic palette, and responsive captures.

# --- Constants ---

## Production widget remains independent from its development host.
const WIDGET: PackedScene = preload("res://score_widget/score_widget.tscn")
const VIEWER: PackedScene = preload("res://debug/score_viewer/score_viewer.tscn")

# --- Member variables ---

## Record ordering through the host-facing signals.
var _started: Array[StringName] = []
var _finished: Array[StringName] = []
var _drained: int = 0

# --- Member functions ---

## Start after the root accepts children.
func _initialize() -> void:
	_run.call_deferred()

## Check real sequential animation, then deterministic visual phases.
func _run() -> void:
	var widget: ScoreWidget = WIDGET.instantiate() as ScoreWidget
	var other: ScoreWidget = WIDGET.instantiate() as ScoreWidget
	root.add_child(widget)
	root.add_child(other)
	widget.step_started.connect(_on_started)
	widget.step_finished.connect(_on_finished)
	widget.sequence_finished.connect(_on_drained)
	widget.set_values(10.0, 2.0)
	widget.trigger(&"die", 16.0, 2.0)
	widget.trigger(&"bonus", 16.0, 4.0, 1.2)
	widget.trigger(&"joker", 16.0, 6.0, 1.8)
	await widget.sequence_finished
	assert(_started == [&"die", &"bonus", &"joker"])
	assert(_finished == _started and _drained == 1)
	assert(widget.points == 16.0 and widget.mult == 6.0)
	assert(other.points == 0.0 and other.mult == 1.0)
	assert(not widget.is_playing())
	assert((widget.get_node("%PointsTile") as Control).scale == Vector2.ONE)
	assert((widget.get_node("%Points") as Label).get_theme_color("font_color") == KeywordColors.for_role(&"points"))
	widget.trigger(&"cancelled", 100.0, 10.0)
	await process_frame
	widget.set_values(20.0, -1.5)
	await create_timer(0.75).timeout
	assert(widget.points == 20.0 and widget.mult == -1.5)
	assert(not _finished.has(&"cancelled"))
	widget.reduced_motion = true
	widget.trigger(&"reduced", 25.0, 2.25)
	await widget.sequence_finished
	assert((widget.get_node("%Mult") as Label).text == "2.25")
	assert((widget.get_node("%MultTile") as Control).rotation == 0.0)
	assert(ScoreWidget.format_number(-1234567.5) == "−1 234 567.5")
	_check_overdrive(widget, other)
	widget.queue_free()
	other.queue_free()
	await process_frame
	for dimensions: Vector2i in [Vector2i(1280, 900), Vector2i(360, 800)]:
		await _check_viewer(dimensions)
	print("PASS: ordered impacts, source signals, cancellation, instance isolation, keyword colors, reduced motion, ratio-driven particles, responsive captures.")
	quit()

## Verify the development controls and inspect rest and contact frames.
func _check_viewer(dimensions: Vector2i) -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = dimensions
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var viewer: Control = VIEWER.instantiate() as Control
	viewport.add_child(viewer)
	await process_frame
	await process_frame
	var widget: ScoreWidget = viewer.get_node("%ScoreWidget") as ScoreWidget
	assert(widget.size.x <= dimensions.x - 32.0)
	widget.reduced_motion = true
	(viewer.get_node("%Chain") as Button).pressed.emit()
	await widget.sequence_finished
	assert(widget.points == 30.0 and widget.mult == 9.0)
	(viewer.get_node("%Large") as Button).pressed.emit()
	await widget.sequence_finished
	for label: Label in [widget.get_node("%Points"), widget.get_node("%Mult")]:
		assert(label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x <= label.size.x)
	(viewer.get_node("%Reset") as Button).pressed.emit()
	if "--capture" in OS.get_cmdline_user_args():
		assert(DisplayServer.get_name() != "headless")
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/paroli-score-rest-%dx%d.png" % [dimensions.x, dimensions.y])
		widget.reduced_motion = false
		widget.set_process(false)
		widget.trigger(&"capture", 30.0, 9.0, 1.8)
		widget._process(0.22)
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/paroli-score-hit-%dx%d.png" % [dimensions.x, dimensions.y])
		widget.set_process(true)
		for ratio: float in [1.0, 2.0, 3.0]:
			(viewer.get_node("%Ratio") as HSlider).value = ratio
			await create_timer(1.0).timeout
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png("/tmp/paroli-score-ratio-%d-%dx%d.png" % [int(ratio), dimensions.x, dimensions.y])
		widget.reduced_motion = true
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/paroli-score-reduced-%dx%d.png" % [dimensions.x, dimensions.y])
	viewport.queue_free()
	await process_frame

## Check threshold math, saturation, banked totals, and immediate reset without GPU timing.
func _check_overdrive(widget: ScoreWidget, other: ScoreWidget) -> void:
	var effect: ScoreOverdrive = widget.get_node("%Overdrive") as ScoreOverdrive
	var stars: CPUParticles2D = effect.get_node("Stars") as CPUParticles2D
	assert(stars.emission_shape == CPUParticles2D.EMISSION_SHAPE_RECTANGLE)
	widget.reduced_motion = false
	widget.set_round_context(0.0, 100.0)
	widget.set_values(50.0, 1.0)
	assert(effect.intensity == 0.0 and not stars.emitting)
	widget.set_values(100.0, 1.0)
	assert(widget.score_ratio == 1.0 and effect.intensity == 0.0)
	widget.set_values(200.0, 1.0)
	assert(is_equal_approx(effect.intensity, 0.5) and stars.emitting)
	widget.set_values(300.0, 1.0)
	assert(effect.intensity == 1.0)
	widget.set_values(1000000.0, 1.0)
	assert(effect.intensity == 1.0)
	assert((other.get_node("%Overdrive") as ScoreOverdrive).intensity == 0.0)
	widget.set_values(10.0, -1.0)
	assert(effect.intensity == 0.0 and not stars.visible)
	widget.set_round_context(75.0, 100.0)
	widget.set_values(25.0, 1.0)
	assert(widget.score_ratio == 1.0)
	widget.set_round_context(0.0, 100.0)
	widget.set_values(100.0, 1.0)
	widget.trigger(&"threshold", 300.0, 1.0)
	widget._process(0.16)
	assert(widget.score_ratio > 1.0 and widget.score_ratio < 3.0)
	effect._process(0.05)
	assert(effect.intensity > 0.0 and effect.intensity < 1.0)
	widget.set_values(300.0, 1.0)
	widget.reduced_motion = true
	assert(effect.intensity == 1.0 and not stars.visible)
	widget.reduced_motion = false
	assert(stars.visible)
	widget.set_round_context(0.0, 0.0)
	assert(widget.score_ratio == 0.0 and effect.intensity == 0.0 and not stars.emitting)

## Track each source beginning exactly once.
func _on_started(id: StringName) -> void:
	_started.append(id)

## Track each completed source independently from queue drain.
func _on_finished(id: StringName) -> void:
	_finished.append(id)

## Verify drain signals are not emitted every idle frame.
func _on_drained() -> void:
	_drained += 1
