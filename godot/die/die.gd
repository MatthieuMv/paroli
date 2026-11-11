@tool
extends Node3D
class_name ParoliDie
## Origin is the floor below the die. Each instance owns its finish and VFX state.

# --- Signals ---

## Emitted after the requested face finishes settling.
signal rolled(value: int)
## Emitted once when activation hides the die.
signal consumed
## Emitted once after the entire activation, including trailing particles, finishes.
signal activation_finished
## Pointer press or held-pointer sweep intent; the controller decides whether mutation is allowed.
signal clicked

# --- Constants ---

## Face normals in numeric order, matching the art prototype.
const NORMALS: Array[Vector3] = [Vector3.UP, Vector3.BACK, Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.DOWN]

# --- Member variables ---

## Named palette selection; setting it also updates the custom body color.
@export_enum("Peach", "Butter", "Mint", "Lavender", "Chalk", "Bubblegum", "Cherry", "Tangerine", "Honey", "Pistachio", "Lagoon", "Sky", "Periwinkle", "Lilac", "Cocoa") var palette_color: String = "Peach":
	set(v):
		palette_color = v
		body_color = DieLibrary.palette().get(v, GameColors.PEACH)

## Custom body tint; particle accents derive from it.
@export var body_color: Color = GameColors.PEACH:
	set(v):
		body_color = v
		_paint()

## Neutral tint used by pips, outline, and cracks.
@export var ink_color: Color = GameColors.INK:
	set(v):
		ink_color = v
		_paint()

## Tint of the independent surface highlight.
@export var shine_color: Color = GameColors.SHINE:
	set(v):
		shine_color = v
		_paint()

## Enable the sweeping highlight without changing particle selection.
@export var shine_enabled: bool = false

## Enable seeded, growing crack lines on the body.
@export var cracks_enabled: bool = false

## Show settled effects and hide consumed dice without animated travel.
@export var reduced_motion: bool = false

## Selected particle preset; replacing it restores the resting presentation.
@export_enum("none", "orbit", "bubbles", "starburst", "petals", "confetti", "bolts", "ribbons", "hearts", "crescents", "diamonds", "flowers", "feathers", "notes", "fire") var effect: String = "none":
	set(v):
		effect = v
		if is_instance_valid(_vfx):
			_activation_time = -1.0
			_rig.show()
			_rig.basis = Basis.IDENTITY
			_rig.position = Vector3(0, 1.145, 0)
			_vfx.select(v)
			_effect_time = 0.0

## Gate the selected preset without rebuilding particles or resetting the die pose.
## Selection previews toggle this; activate() remains the separate consume animation.
@export var effect_enabled: bool = true:
	set(v):
		if effect_enabled == v:
			return
		effect_enabled = v
		if v:
			_effect_time = 0.0
		if is_instance_valid(_vfx):
			_vfx.visible = v
		if not v and is_instance_valid(_impact):
			_impact.hide()

## Requested upward face, independent of gameplay randomness.
@export_range(1, 6) var face_value: int = 1:
	set(v):
		face_value = clampi(v, 1, 6)
		if is_instance_valid(_body) and _roll_time < 0:
			_body.quaternion = landing_rotation(face_value)

## Opt-in pointer interaction keeps standalone art previews non-interactive by default.
@export var interaction_enabled: bool = false:
	set(value):
		interaction_enabled = value
		if is_instance_valid(_pick_area):
			_pick_area.input_ray_pickable = value

## Picking volume follows the visual rig but never participates in gameplay physics.
@onready var _pick_area: Area3D = $DieRig/PickArea
## Presentation-only selection cue; hold ownership belongs to the containing controller.
@onready var _hold_highlight: MeshInstance3D = $HoldHighlight

## Scene-owned squash, stretch, and activation transform.
@onready var _rig: Node3D = $DieRig

## Scene-authored solid body, outline, and pips beneath the rig.
@onready var _body: Node3D = $DieRig/Model

## Scene-owned particle module; its hierarchy remains private.
@onready var _vfx: DieEffects = $Effects

## Instance-owned shader and seeded finish sampler.
var _finish: DieFinish = DieFinish.new()

## Palette bindings for the native model meshes.
var _bindings: Array[DieLibrary.MaterialBinding] = []

## Elapsed presentation seconds used by deterministic surface samplers.
var _clock: float = 0.0

## Effect clock; negative values delay landing VFX until the final settle.
var _effect_time: float = 0.0

## Roll clock; a negative value means the die is resting.
var _roll_time: float = -1.0

## Whether this instance has completed its initial reveal.
var _has_rolled: bool = false

## Whether this roll needs a short appearance-scale transition.
var _reveal: bool = false

## Activation clock; a negative value means no consume sequence is active.
var _activation_time: float = -1.0
## Completion is separate from consumed: particles can outlive the die silhouette.
var _activation_completed: bool = false

## Captured orientation at the start of the current roll.
var _from_rotation: Quaternion = Quaternion.IDENTITY

## Floor shadow mesh owned by this instance.
var _shadow: MeshInstance3D

## Transient landing ring owned by this instance.
var _impact: MeshInstance3D

# --- Member functions ---

## Ready callback: bind the native model beneath the scene-owned rig.
func _ready() -> void:
	_pick_area.input_ray_pickable = interaction_enabled
	_pick_area.input_event.connect(_on_pointer_input)
	DieLibrary.collect_bindings(_body, _bindings)
	(_body.get_child(0) as MeshInstance3D).material_override = _finish.material
	_body.quaternion = landing_rotation(face_value)
	_rig.position.y = 1.145
	_vfx.select(effect)
	_vfx.visible = effect_enabled
	_shadow = _floor_disk(1.5, 0.0)
	_impact = _floor_disk(1.0, 0.925)
	_impact.position.y = 0.015
	_paint()

## Create a floor-aligned procedural disk or ring owned by this die.
func _floor_disk(radius: float, inner: float) -> MeshInstance3D:
	var mesh: ImmediateMesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in 64:
		var a: float = TAU * i / 64.0
		var b: float = TAU * (i + 1) / 64.0
		var points: Array[Vector3] = [Vector3(cos(a) * inner, 0, sin(a) * inner), Vector3(cos(a) * radius, 0, sin(a) * radius), Vector3(cos(b) * radius, 0, sin(b) * radius), Vector3(cos(a) * inner, 0, sin(a) * inner), Vector3(cos(b) * radius, 0, sin(b) * radius), Vector3(cos(b) * inner, 0, sin(b) * inner)]
		for p: Vector3 in points:
			mesh.surface_add_vertex(p)
	mesh.surface_end()
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = mat
	add_child(instance)
	return instance

## Propagate artist colors without exposing child material state.
func _paint() -> void:
	if not is_instance_valid(_vfx):
		return
	_finish.paint(body_color, ink_color, shine_color)
	for binding: DieLibrary.MaterialBinding in _bindings:
		binding.paint(body_color, ink_color)
	_vfx.color = body_color
	_vfx.ink = ink_color
	_vfx.paint()

## Return the orientation that presents the requested face upward.
func landing_rotation(value: int) -> Quaternion:
	return Quaternion(Vector3.UP, 0.25) * Quaternion(NORMALS[value - 1], Vector3.UP)

## Start a visual roll; value zero cycles faces and never chooses a game result.
func roll(value: int = 0) -> void:
	_reveal = not _has_rolled or not _rig.visible
	_has_rolled = true
	_vfx.reset_activation()
	_activation_time = -1.0
	_rig.basis = Basis.IDENTITY
	_rig.position = Vector3(0, 1.145, 0)
	_rig.visible = true
	_vfx.visible = true
	_roll_time = 0.0
	_from_rotation = _body.quaternion
	face_value = value if value > 0 else face_value % 6 + 1
	_effect_time = -0.54

## Capture the current effect and consume it once the die has settled.
func activate() -> void:
	if _roll_time >= 0 or _activation_time >= 0:
		return
	_activation_completed = false
	_activation_time = 0.0
	_vfx.begin_activation()

## Process callback: advance presentation only, never authoritative game state.
func _process(delta: float) -> void:
	if not _body:
		return
	_clock += delta
	_effect_time += delta
	var height: float = _sample_roll(delta)
	if _activation_time < 0:
		_vfx.position.y = _rig.position.y
		_vfx.sample(3.0 if reduced_motion else _effect_time, _rig.position.y)
	_sample_impact()
	var shadow_color: Color = ink_color
	shadow_color.a = 0.16 / (1 + height)
	_shadow.scale = Vector3.ONE * (1 + height * 0.15)
	if _activation_time >= 0:
		shadow_color.a *= _sample_activation(delta)
	(_shadow.material_override as StandardMaterial3D).albedo_color = shadow_color
	_vfx.mask_top(_body)
	_finish.sample(_clock, shine_enabled, cracks_enabled, reduced_motion)


## Report whether another roll is still settling.
func is_rolling() -> bool:
	return _roll_time >= 0.0

## Report whether the presentation has been consumed.
func is_consumed() -> bool:
	return is_instance_valid(_rig) and not _rig.visible

## Sample anticipation, three diminishing bounces, and the requested landing.
func _sample_roll(delta: float) -> float:
	if _roll_time < 0:
		return 0.0
	var height: float = 0.0
	_roll_time += delta
	var t: float = 1.0 if reduced_motion else minf(_roll_time / 0.62, 1.0)
	var travel: float = maxf(0.0, (t - 0.12) / 0.88)
	var stretch: float = 1.0 - 0.26 * sin(t / 0.12 * PI) if t < 0.12 else 1.0
	if t >= 0.12:
		height = absf(sin(travel * PI * 3)) * pow(1 - travel, 1.35) * 2.45
		stretch = 1 + 0.2 * minf(height, 1) - 0.23 * exp(-pow((travel - 0.69) / 0.045, 2)) - 0.13 * sin(maxf(0, (travel - 0.88) / 0.12) * PI)
	# Preserve volume while squash/stretch follows the three landing arcs.
	var ease: float = 1.0 - pow(1.0 - travel, 3)
	_body.quaternion = _from_rotation.slerp(landing_rotation(face_value), ease) * Quaternion(Basis(Vector3.RIGHT, PI * 4 * (1 - ease)) * Basis(Vector3.UP, TAU * (1 - ease)))
	var appearance: float = smoothstep(0, 0.18, t * 0.62) if _reveal else 1.0
	_rig.scale = Vector3(1 / sqrt(stretch), stretch, 1 / sqrt(stretch)) * maxf(0.0001, appearance)
	_rig.visible = appearance > 0
	# Compute support from rotated bounds so the beveled cube stays above the floor.
	var basis: Basis = _body.basis
	var support: float = (0.805 * (absf(basis.x.y) + absf(basis.y.y) + absf(basis.z.y)) + 0.27) * 1.065
	_rig.position.y = support * stretch * appearance + height
	if t >= 1:
		_roll_time = -1
		if reduced_motion:
			_effect_time = 3
		rolled.emit(face_value)
	return height

## Fade the ground impact independently of the persistent particle set.
func _sample_impact() -> void:
	_impact.visible = effect_enabled and effect!="none" and _effect_time >= 0 and _effect_time < 0.3 and not reduced_motion
	if _impact.visible:
		var t: float = _effect_time / 0.3
		_impact.scale = Vector3.ONE * lerpf(1.26, 1.5, 1 - pow(1 - t, 3))
		var tint: Color = DieLibrary.tone_color("star", body_color, ink_color)
		tint.a = 0.85 * smoothstep(0, 0.015, _effect_time) * pow(1 - t, 2)
		(_impact.material_override as StandardMaterial3D).albedo_color = tint

## Apply a consume sequence and return its remaining shadow coverage.
func _sample_activation(delta: float) -> float:
	_activation_time += delta
	var duration: float = DieLibrary.activation_duration(effect)
	var t: float = duration if reduced_motion else _activation_time
	var pose: Dictionary[String, float] = DieActivation.die_pose(effect, t)
	var was_visible: bool = _rig.visible
	_rig.basis = Basis(Vector3.UP, pose.yaw) * Basis(Vector3.BACK, pose.lean) * Basis.from_scale(Vector3(maxf(0.0001, pose.exit_x / sqrt(pose.squash)), maxf(0.0001, pose.squash * pose.exit_y), maxf(0.0001, pose.exit_z / sqrt(pose.squash))))
	_rig.position = Vector3(pose.shake, 1.145 * pose.squash + pose.lift, 0)
	_rig.visible = not reduced_motion and maxf(pose.exit_x, pose.exit_y) > 0.001
	_vfx.visible = not reduced_motion and t < duration
	_vfx.sample_activation(pose.p, t)
	if was_visible and not _rig.visible:
		consumed.emit()
	if not _activation_completed and t >= duration:
		_activation_completed = true
		activation_finished.emit()
	return minf(1, pose.exit_x * pose.exit_z) if not reduced_motion else 0.0

## Display the controller's held selection without choosing or changing game state.
func set_hold_highlight(enabled: bool) -> void:
	_hold_highlight.visible = enabled

## Accept presses and held-pointer sweeps; release and passive hover never mutate a die.
## Physics picking routes both mouse and native touch events after GUI handling.
func _on_pointer_input(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_index: int) -> void:
	if not interaction_enabled or is_rolling() or is_consumed():
		return
	var requested: bool = false
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		requested = mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		# Ignore synthetic stationary motion generated when picking geometry moves.
		requested = (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 and not motion.relative.is_zero_approx()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		requested = touch.pressed and not touch.canceled
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		requested = not drag.relative.is_zero_approx()
	if requested:
		clicked.emit()
		get_viewport().set_input_as_handled()
