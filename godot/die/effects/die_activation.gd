@tool
extends RefCounted
class_name DieActivation
## Activation modifies captured particles, never a previous frame's pose.

# --- Types ---

## Result of sampling a captured particle during activation.
class ParticlePose:
	## Absolute local transform; callers must not accumulate it across frames.
	var transform: Transform3D
	## Individual visibility supports staggered bubble pops.
	var visible: bool

	## Store a typed pose rather than returning a heterogeneous dictionary.
	func _init(transform_: Transform3D, visible_: bool) -> void:
		transform = transform_
		visible = visible_

# --- Static functions ---

## Clamp and ease an activation phase.
static func smooth(t: float) -> float:
	return smoothstep(0.0, 1.0, t)
## Ease an outward impulse without simulation state.
static func out(t: float) -> float:
	return 1 - pow(1 - clampf(t, 0, 1), 3)

## Sample the preset's native activation animation at absolute seconds.
static func die_pose(id: String, seconds: float) -> Dictionary[String, float]:
	return DieLibrary.activation_pose(id, seconds)

## Sample a particle from its captured transform, preserving preset-specific exits.
static func particle(id: String, p: float, seconds: float, index: int, start: Transform3D) -> ParticlePose:
	var position: Vector3 = start.origin
	var scale: Vector3 = Vector3.ONE
	var spin: float = 0.0
	var visible: bool = true
	var angle: float = atan2(position.z, position.x)
	var radius: float = Vector2(position.x, position.z).length()
	var turn: float = 0.0
	var radial: float = 1.0
	match id:
		"orbit":
			var pull: float = smooth((p - 0.12) / 0.88)
			scale *= 1 - 0.94 * pull
			position.y += 0.45 * pull
			spin = p * PI * 4
		"bubbles":
			var pop_at: float = 0.14 + index * 0.035
			var swell: float = smooth(seconds / pop_at)
			scale *= 1 + 0.65 * swell
			position.y += 0.18 * swell
			visible = seconds < pop_at
		"starburst", "diamonds":
			var charge: float = smooth(p / 0.24)
			var burst: float = out((p - 0.24) / 0.76)
			radial = 1 - (0.42 if id=="starburst" else 0.36) * charge + (1.83 if id=="starburst" else 1.8) * burst
			position.y += (1.2 if id=="starburst" else 0.8) * burst
			scale *= (1 + 0.35 * charge) * (1 - 0.85 * burst) if id=="starburst" else (1 + 0.2 * charge) * (1 - smooth((p - 0.3) / 0.7))
			spin = 2.3 * burst if id=="starburst" else (-1 if index % 2 else 1) * PI * burst
		"flowers":
			var bloom: float = smooth(p / 0.35)
			var drift: float = smooth((p - 0.2) / 0.8)
			radial = 1 + 0.45 * drift
			position.y += 1.5 * drift
			scale *= (1 + 0.45 * bloom) * (1 - smooth((p - 0.4) / 0.6))
			spin = -TAU * p
		"feathers":
			position.x += 2.2 * out(p)
			position.y += 1.6 * smooth(p) + 0.2 * sin(PI * p)
			position.z += 0.35 * sin(angle) * out(p)
			scale *= 1 - smooth((p - 0.4) / 0.6)
			spin = -1.5 * out(p)
		"notes":
			var jump: float = out((p - index * 0.025) / 0.7)
			position += Vector3(cos(angle) * 0.55 * jump, 2 * jump, sin(angle) * 0.55 * jump)
			scale *= (1 + 0.2 * sin(PI * jump)) * (1 - smooth((p - 0.45) / 0.55))
			spin = (-1 if index % 2 else 1) * 0.35 * sin(PI * jump)
		"fire":
			var flare: float = out(p / 0.5)
			var rise: float = smooth((p - 0.18) / 0.82)
			radial = 1 - 0.2 * rise
			position.y += 2.5 * rise
			var vanish: float = 1 - smooth((p - 0.45) / 0.55)
			scale.x *= (1 + 0.18 * flare) * vanish
			scale.y *= (1 + 1.1 * flare) * vanish
		"crescents":
			turn = 1.5 * PI * p
			radial = 1 - 0.75 * smooth(p)
			position.y += 2 * smooth(p)
			scale *= 1 - smooth((p - 0.3) / 0.7)
			spin = -0.75 * PI * p
		"hearts":
			var gather: float = smooth(p / 0.26)
			var pop: float = out((p - 0.26) / 0.74)
			radial = 1 - 0.4 * gather + 1.2 * pop
			position.y += 1.7 * pop
			scale *= (1 + 0.25 * gather) * (1 - smooth((p - 0.4) / 0.6))
			spin = (-1 if index % 2 else 1) * 0.45 * pop
		"ribbons", "petals":
			turn = TAU * p
			radial = 1 + 0.35 * sin(PI * p) if id=="ribbons" else 1 - 0.7 * smooth(p)
			position.y += (2.4 if id=="ribbons" else 2.0) * out(p)
			scale *= 1 - smooth((p - 0.35) / 0.65) if id=="ribbons" else 1 - 0.75 * smooth((p - 0.3) / 0.7)
			spin = -turn
		"confetti":
			radial = 1 + 1.3 * out(p)
			position.y += 1.4 * sin(PI * p)
			scale *= 1 - 0.7 * smooth((p - 0.35) / 0.65)
			spin = (-1 if index % 2 else 1) * out(p) * PI * 4
		"bolts":
			var charge: float = smooth(seconds / 0.18)
			var strike: float = smooth((seconds - 0.24) / 0.14)
			var overhead: float = 2.6 + (index % 2) * 0.18
			radial = 1 - 0.35 * charge - 0.45 * strike
			position.y += (overhead - position.y) * charge + (1.05 - overhead) * strike
			var release: float = smooth((seconds - 0.38) / 0.2)
			scale.y *= (1 + 0.7 * charge + 0.8 * strike) * (1 - release)
			scale.x *= (1 - 0.35 * strike) * (1 - release)
	if id not in ["feathers", "notes", "orbit", "bubbles"]:
		position.x = cos(angle + turn) * radius * radial
		position.z = sin(angle + turn) * radius * radial
	var basis: Basis = start.basis.orthonormalized() * Basis(Vector3.BACK, spin) * Basis.from_scale(start.basis.get_scale() * scale.max(Vector3.ONE * 0.0001))
	return ParticlePose.new(Transform3D(basis, position), visible)
