@tool
extends RefCounted
class_name DieFinish
## Owns surface shader state and seeded variation for exactly one die.

# --- Constants ---

## Toon shading, shine, and cracks share one body-material pass.
const SHADER: Shader = preload("res://die/finish/die.gdshader")

# --- Member variables ---

## Instance-local material applied only to the solid body, never pips or ink.
var material: ShaderMaterial = ShaderMaterial.new()
## Last generated crack cycle; negative means no graph has been uploaded yet.
var _crack_cycle: int = -1
## Last generated shine cycle; glints remain stable throughout one sweep.
var _shine_cycle: int = -1
## Unsigned xorshift state, kept independent of game-result randomness.
var _random_seed: int = 1

# --- Member functions ---

## Create a material without sharing mutable uniforms between dice.
func _init() -> void:
	material.shader = SHADER

## Set the three artist-controlled surface colors.
func paint(body: Color, ink: Color, shine: Color) -> void:
	material.set_shader_parameter("body_color", body)
	material.set_shader_parameter("ink_color", ink)
	material.set_shader_parameter("shine_color", shine)

## Update independent surface finishes from the die presentation clock.
func sample(clock: float, shine_enabled: bool, cracks_enabled: bool, reduced_motion: bool) -> void:
	var cycle: int = int(clock / 1.5)
	if cycle != _shine_cycle:
		_shine_cycle = cycle
		_random_seed = (cycle + 1) * 0x9e3779b1
		var glints: PackedVector4Array = PackedVector4Array()
		for i: int in 3:
			glints.append(Vector4((i - 1) * 0.65 + _random_range(-0.125, 0.125), _random_range(-0.775, 0.775), _random_range(0.18, 0.26), _random_range(-0.325, 0.325)))
		material.set_shader_parameter("glints", glints)
	var phase: float = fmod(clock, 1.5)
	material.set_shader_parameter("shine_cursor", lerpf(-2.2, 3.05, minf(1, phase / 0.72)))
	material.set_shader_parameter("shine_strength", 0.42 if shine_enabled and not reduced_motion and phase < 0.72 else 0.0)
	cycle = 0 if reduced_motion else int(clock / 2.6)
	if cycle != _crack_cycle:
		_crack_cycle = cycle
		material.set_shader_parameter("segments", _crack_segments(cycle))
	phase = fmod(clock, 2.6)
	material.set_shader_parameter("crack_progress", 1.0 if reduced_motion else smoothstep(0, 0.45, phase))
	material.set_shader_parameter("crack_strength", 0.68 * (1.0 if reduced_motion else 1 - smoothstep(1.25, 1.85, phase)) if cracks_enabled else 0.0)

## Build the connected crack graph with the prototype's deterministic seed.
func _crack_segments(cycle: int) -> PackedVector4Array:
	_random_seed = (cycle + 1) * 0x85ebca6b
	var start: float = _random_range(0.25, 0.75)
	var end: float = -_random_range(0.25, 0.75)
	var points: Array[Vector2] = []
	var lines: Array[Vector4] = []
	for i: int in 8:
		points.append(Vector2(-1.1 + 2.2 * i / 7.0, lerpf(start, end, i / 7.0) + (_random_range(-0.2, 0.2) if i > 0 and i < 7 else 0)))
		if i > 0:
			lines.append(Vector4(points[i - 1].x, points[i - 1].y, points[i].x, points[i].y))
	for branch: Vector3i in [Vector3i(2, 1, 1), Vector3i(3, -1, 2), Vector3i(5, -1, 2)]:
		var a: Vector2 = points[branch[0]]
		for j: int in branch[2]:
			var b: Vector2 = Vector2(a.x + _random_range(-0.21, 0.21), clampf(a.y + branch[1] * _random_range(0.2, 0.45), -1.1, 1.1))
			lines.append(Vector4(a.x, a.y, b.x, b.y))
			a = b
	var result: PackedVector4Array = PackedVector4Array()
	var mirror: int = -1 if _random() < 0.5 else 1
	for line: Vector4 in lines:
		var a: Vector2 = (Vector2(line.x, line.y) * Vector2(1, mirror)).rotated(cycle % 4 * PI / 2)
		var b: Vector2 = (Vector2(line.z, line.w) * Vector2(1, mirror)).rotated(cycle % 4 * PI / 2)
		result.append(Vector4(a.x, a.y, b.x, b.y))
	return result

## Exact unsigned xorshift sequence used by the prototype finishes.
func _random() -> float:
	_random_seed &= 0xffffffff
	_random_seed = (_random_seed ^ (_random_seed << 13)) & 0xffffffff
	_random_seed = (_random_seed ^ (_random_seed >> 17)) & 0xffffffff
	_random_seed = (_random_seed ^ (_random_seed << 5)) & 0xffffffff
	return float(_random_seed) / 4294967296.0

## Map the seeded unit sample into an art-directed interval.
func _random_range(low: float, high: float) -> float:
	return lerpf(low, high, _random())
