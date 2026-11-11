extends Control
class_name ScoreOverdrive
## Continuous, instance-local victory particles driven only by the score/target ratio.

# --- Constants ---

## Rounded gold star also supplies a static reduced-motion victory cue.
const STAR: Texture2D = preload("res://score_widget/overdrive/star.svg")
## Full celebration at three times target; exactly meeting target has zero intensity.
const FULL_POWER_RATIO: float = 3.0

# --- Member variables ---

## Smoothed interpolation weight shared by all particle parameters, in [0, 1].
var intensity: float = 0.0
## Accessibility state removes moving particles, retaining static gold glints.
var reduced_motion: bool = false
## Target interpolation weight and prior visibility for clean restarts.
var _desired: float = 0.0
var _running: bool = false
## Authored star emitter owns its clock, random seed, and live particles.
@onready var _stars: CPUParticles2D = $Stars

# --- Member functions ---

## Keep the emitter centered as its parent UI changes width.
func _ready() -> void:
	resized.connect(_layout)
	_layout()
	_apply_particles()
	set_process(false)

## Map the ratio linearly: 1× = off, 2× = half intensity, 3× and higher = full.
func set_ratio(ratio: float, immediate: bool = false) -> void:
	assert(is_finite(ratio))
	_desired = clampf((ratio - 1.0) / (FULL_POWER_RATIO - 1.0), 0.0, 1.0)
	if immediate or reduced_motion:
		intensity = _desired
	if is_node_ready():
		_apply_particles()
	set_process(not reduced_motion and not is_equal_approx(intensity, _desired))
	queue_redraw()

## Smooth rising and falling intensity with a frame-rate-independent lerp.
func _process(delta: float) -> void:
	intensity = _desired if reduced_motion else lerpf(intensity, _desired, 1.0 - exp(-delta * 8.0))
	if absf(intensity - _desired) < 0.0001:
		intensity = _desired
		set_process(false)
	_apply_particles()
	queue_redraw()

## Interpolate size, speed, opacity, and spread without resetting particle populations.
func _apply_particles() -> void:
	var enabled: bool = intensity > 0.001 and not reduced_motion
	_stars.visible = enabled
	_stars.emitting = enabled
	if enabled and not _running:
		_stars.restart()
	_stars.speed_scale = lerpf(0.65, 1.4, intensity)
	_stars.color = Color(1.0, 1.0, 1.0, intensity)
	_stars.scale_amount_min = lerpf(0.12, 0.35, intensity)
	_stars.scale_amount_max = lerpf(0.22, 0.78, intensity)
	_stars.initial_velocity_min = lerpf(18.0, 36.0, intensity)
	_stars.initial_velocity_max = lerpf(30.0, 68.0, intensity)
	_stars.spread = lerpf(12.0, 30.0, intensity)
	_running = enabled

## Cover 130% of the widget width; stars rise behind the readouts and fan outward.
func _layout() -> void:
	_stars.position = Vector2(size.x * 0.5, 100.0)
	_stars.emission_rect_extents = Vector2(size.x * 0.65, 24.0)

## A still trio of gold glints communicates over-target strength with reduced motion.
func _draw() -> void:
	if not reduced_motion or intensity <= 0.001:
		return
	var extent: float = lerpf(10.0, 24.0, intensity)
	for fraction: float in [0.2, 0.5, 0.8]:
		var center: Vector2 = Vector2(size.x * fraction, 42.0)
		draw_texture_rect(STAR, Rect2(center - Vector2.ONE * extent * 0.5, Vector2.ONE * extent), false, Color(1, 1, 1, intensity))
