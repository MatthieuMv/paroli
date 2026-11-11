@tool
extends RefCounted
class_name DieEffectPoses
## Native analytic effect motion; edit alongside each preset's .tres recipe.

# --- Static functions ---

## Smooth a normalized transition without overshoot.
static func smooth(v: float) -> float:
	var t: float = clampf(v, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

## Critically damp the initial expansion into sustained motion.
static func settle(v: float) -> float:
	return 1.0 - (1.0 + v) * exp(-v)

## Integrate decaying launch speed analytically.
static func phase_at(t: float, launch: float, cruise: float, decay: float) -> float:
	return cruise * t + (launch - cruise) * decay * (1.0 - exp(-t / decay))

## Shared landing impulse used by billboard presets.
static func launch_pose(seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	var t: float = maxf(0.0, seconds)
	var lift: float = 1.0 - exp(-t / recipe.rise)
	var spread: float = 1.0 - exp(-t / recipe.expansion)
	var phase: float = phase_at(t, recipe.launch, recipe.speed, recipe.braking)
	var angle: float = (index + 0.25) * TAU / recipe.count + phase
	var radius: float = 1.05 + (recipe.radius - 1.05) * spread
	return {"x": cos(angle) * radius, "y": (0.1 - center_height) * (1.0 - lift) + lift * recipe.height, "z": sin(angle) * radius, "phase": phase, "angle": angle, "lift": lift, "energy": 1.0 - lift, "opacity": smooth(t / 0.06)}

## Sample orbit from absolute seconds; no frame-dependent integration.
static func orbit(seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	var t: float = max(0, seconds)
	var expansion: float = t / recipe.expansionSeconds
	var spread: float = 1 - (1 + expansion) * exp(-expansion)
	var decay: float = exp(-t / recipe.brakingSeconds)
	var result: Dictionary[String, float] = {}
	result["scale"] = recipe.initialScale + (1 - recipe.initialScale) * spread
	result["angle"] = recipe.cruiseSpeed * t + (recipe.launchSpeed - recipe.cruiseSpeed) * recipe.brakingSeconds * (1 - decay)
	result["opacity"] = smooth(t / recipe.revealSeconds)
	return result

## Sample bubbles from absolute seconds; no frame-dependent integration.
static func bubbles(seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	var t: float = max(0, seconds)
	var spread: float = 1 - exp(-t / recipe.expansionSeconds)
	var lift: float = 1 - exp(-t / recipe.riseSeconds)
	var drift: float = settle(t / recipe.riseSeconds)
	var phase: float = recipe.cruiseSpeed * t + (recipe.launchSpeed - recipe.cruiseSpeed) * recipe.brakingSeconds * (1 - exp(-t / recipe.brakingSeconds))
	var angle: float = (index * TAU) / recipe.count + phase
	var radius: float = recipe.initialRadius + (recipe.radius - recipe.initialRadius) * spread + 0.13 * drift * sin(angle * 2 + index)
	var result: Dictionary[String, float] = {}
	result["x"] = cos(angle) * radius
	result["y"] = (recipe.spawnHeight - center_height) * (1 - lift) + lift * (0.3 + 0.7 * drift * sin(angle + index * 0.8))
	result["z"] = sin(angle) * radius
	result["size"] = (0.18 + (index % 4) * 0.035) * (0.25 + 0.75 * spread)
	result["opacity"] = smooth(t / recipe.revealSeconds)
	return result

## Sample starburst from absolute seconds; no frame-dependent integration.
static func starburst(seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	var t: float = max(0, seconds)
	var spread: float = 1 - exp(-t / recipe.expansionSeconds)
	var lift: float = 1 - exp(-t / recipe.riseSeconds)
	var energy: float = exp(-t / recipe.riseSeconds)
	var phase: float = recipe.cruiseSpeed * t + (recipe.launchSpeed - recipe.cruiseSpeed) * recipe.brakingSeconds * (1 - exp(-t / recipe.brakingSeconds))
	var angle: float = ((index + 0.25) * TAU) / recipe.count + phase
	var radius: float = recipe.initialRadius + (recipe.radius - recipe.initialRadius) * spread
	var size: float = (0.12 + (index % 3) * 0.025) * (0.92 + 0.08 * sin(phase * 2 + index))
	var result: Dictionary[String, float] = {}
	result["x"] = cos(angle) * radius
	result["y"] = (recipe.spawnHeight - center_height) * (1 - lift) + lift * (0.1 + (index % 3) * 0.5 + 0.18 * sin(angle * 2))
	result["z"] = sin(angle) * radius
	result["size"] = size
	result["stretch"] = 1 + 1.5 * energy
	result["rotation"] = angle + PI / 4
	result["opacity"] = smooth(t / recipe.revealSeconds)
	return result

## Sample petals from absolute seconds; no frame-dependent integration.
static func petals(seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	var t: float = max(0, seconds)
	var spread: float = 1 - exp(-t / recipe.expansionSeconds)
	var lift: float = 1 - exp(-t / recipe.riseSeconds)
	var energy: float = exp(-t / recipe.riseSeconds)
	var phase: float = recipe.cruiseSpeed * t + (recipe.launchSpeed - recipe.cruiseSpeed) * recipe.brakingSeconds * (1 - exp(-t / recipe.brakingSeconds))
	var angle: float = ((index + 0.25) * TAU) / recipe.count + phase
	var radius: float = recipe.initialRadius + (recipe.radius - recipe.initialRadius) * spread
	var size: float = 0.2 + (index % 3) * 0.025
	var flutter: float = sin(phase * 2 + index)
	var result: Dictionary[String, float] = {}
	result["x"] = cos(angle) * (radius + 0.12 * lift * sin(angle * 2))
	result["y"] = (recipe.spawnHeight - center_height) * (1 - lift) + lift * (0.25 + 0.65 * sin(angle + index * 0.3))
	result["z"] = sin(angle) * (radius + 0.12 * lift * sin(angle * 2))
	result["size"] = size
	result["width"] = 0.85 + 0.15 * flutter
	result["stretch"] = 1 + 0.45 * energy
	result["rotation"] = -angle + PI / 4 + 0.35 * flutter
	result["opacity"] = smooth(t / recipe.revealSeconds)
	return result

## Sample confetti from absolute seconds; no frame-dependent integration.
static func confetti(seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	var t: float = max(0, seconds)
	var spread: float = 1 - exp(-t / recipe.expansionSeconds)
	var lift: float = 1 - exp(-t / recipe.riseSeconds)
	var phase: float = phase_at( t, recipe.launchSpeed, recipe.cruiseSpeed, recipe.brakingSeconds, )
	var angle: float = ((index + 0.3) * TAU) / recipe.count + phase
	var radius: float = recipe.initialRadius + (recipe.radius - recipe.initialRadius) * spread
	var rise: float = t / recipe.riseSeconds
	var loft: float = 0.55 * rise * exp(1 - rise)
	var tumble: float = phase_at( t, recipe.tumbleLaunchSpeed, recipe.tumbleCruiseSpeed, recipe.tumbleBrakingSeconds, )
	var result: Dictionary[String, float] = {}
	result["x"] = cos(angle) * radius + 0.1 * lift * sin(angle * 3 + index)
	result["y"] = (recipe.spawnHeight - center_height) * (1 - lift) + lift * (0.3 + 0.65 * sin(angle + index * 0.4)) + loft
	result["z"] = sin(angle) * radius
	result["width"] = 0.12 + (index % 3) * 0.025
	result["height"] = 0.22 + (index % 4) * 0.025
	result["rotation"] = index + (-1 if index % 2 else 1) * tumble
	result["tilt"] = 0.85 * sin(tumble + index * 0.7)
	result["opacity"] = smooth(t / recipe.revealSeconds)
	return result

## Sample bolts from absolute seconds; no frame-dependent integration.
static func bolts(seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	var t: float = max(0, seconds)
	var spread: float = 1 - exp(-t / recipe.expansionSeconds)
	var lift: float = 1 - exp(-t / recipe.riseSeconds)
	var energy: float = exp(-t / recipe.riseSeconds)
	var phase: float = recipe.cruiseSpeed * t + (recipe.launchSpeed - recipe.cruiseSpeed) * recipe.brakingSeconds * (1 - exp(-t / recipe.brakingSeconds))
	var angle: float = ((index + 0.25) * TAU) / recipe.count + phase
	var radius: float = recipe.initialRadius + (recipe.radius - recipe.initialRadius) * spread
	var pulse: float = sin(phase * 2 + index)
	var tremor: float = lift * 0.025 * sin(phase * 6 + index)
	var result: Dictionary[String, float] = {}
	result["x"] = cos(angle) * radius + tremor
	result["y"] = (recipe.spawnHeight - center_height) * (1 - lift) + lift * (0.15 + (index % 2) * 0.55 + 0.22 * sin(angle * 2))
	result["z"] = sin(angle) * radius
	result["size"] = (0.21 + (index % 3) * 0.025) * (0.94 + 0.06 * pulse)
	result["stretch"] = 1 + 0.6 * energy
	result["rotation"] = -0.35 * cos(angle) + 0.1 * pulse
	result["opacity"] = smooth(t / recipe.revealSeconds)
	return result

## Sample ribbons from absolute seconds; no frame-dependent integration.
static func ribbons(seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	var t: float = max(0, seconds)
	var spread: float = 1 - exp(-t / recipe.expansionSeconds)
	var lift: float = 1 - exp(-t / recipe.riseSeconds)
	var energy: float = exp(-t / recipe.riseSeconds)
	var phase: float = recipe.cruiseSpeed * t + (recipe.launchSpeed - recipe.cruiseSpeed) * recipe.brakingSeconds * (1 - exp(-t / recipe.brakingSeconds))
	var angle: float = ((index + 0.25) * TAU) / recipe.count + phase
	var radius: float = recipe.initialRadius + (recipe.radius - recipe.initialRadius) * spread
	var size: float = 0.44 + (index % 3) * 0.035
	var flutter: float = sin(phase * 2 + index)
	var result: Dictionary[String, float] = {}
	result["x"] = cos(angle) * (radius + 0.12 * lift * sin(angle * 2))
	result["y"] = (recipe.spawnHeight - center_height) * (1 - lift) + lift * (0.3 + 0.25 * sin(angle + index * 0.3))
	result["z"] = sin(angle) * (radius + 0.12 * lift * sin(angle * 2))
	result["size"] = size
	result["width"] = 0.85 + 0.15 * flutter
	result["stretch"] = 1 + 0.45 * energy
	result["rotation"] = (PI / 2) * lift + 0.12 * sin(angle) + 0.08 * flutter
	result["opacity"] = smooth(t / recipe.revealSeconds)
	return result

## Sample hearts from absolute seconds; no frame-dependent integration.
static func hearts(seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	var t: float = max(0, seconds)
	var spread: float = 1 - exp(-t / recipe.expansionSeconds)
	var lift: float = 1 - exp(-t / recipe.riseSeconds)
	var energy: float = exp(-t / recipe.riseSeconds)
	var phase: float = recipe.cruiseSpeed * t + (recipe.launchSpeed - recipe.cruiseSpeed) * recipe.brakingSeconds * (1 - exp(-t / recipe.brakingSeconds))
	var angle: float = ((index + 0.25) * TAU) / recipe.count + phase
	var radius: float = recipe.initialRadius + (recipe.radius - recipe.initialRadius) * spread
	var size: float = (0.23 + (index % 3) * 0.025) * (1 + 0.07 * sin(phase * 3 + index))
	var flutter: float = sin(phase * 2 + index)
	var result: Dictionary[String, float] = {}
	result["x"] = cos(angle) * (radius + 0.12 * lift * sin(angle * 2))
	result["y"] = (recipe.spawnHeight - center_height) * (1 - lift) + lift * (0.35 + 0.55 * sin(angle + index * 0.3))
	result["z"] = sin(angle) * (radius + 0.12 * lift * sin(angle * 2))
	result["size"] = size
	result["width"] = 1
	result["stretch"] = 1 + 0.3 * energy
	result["rotation"] = 0.18 * flutter
	result["opacity"] = smooth(t / recipe.revealSeconds)
	return result

## Sample crescents from absolute seconds; no frame-dependent integration.
static func crescents(seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	var t: float = max(0, seconds)
	var spread: float = 1 - exp(-t / recipe.expansionSeconds)
	var lift: float = 1 - exp(-t / recipe.riseSeconds)
	var energy: float = exp(-t / recipe.riseSeconds)
	var phase: float = recipe.cruiseSpeed * t + (recipe.launchSpeed - recipe.cruiseSpeed) * recipe.brakingSeconds * (1 - exp(-t / recipe.brakingSeconds))
	var angle: float = ((index + 0.25) * TAU) / recipe.count + phase
	var radius: float = recipe.initialRadius + (recipe.radius - recipe.initialRadius) * spread
	var size: float = 0.28 + (index % 3) * 0.025
	var flutter: float = sin(phase * 2 + index)
	var result: Dictionary[String, float] = {}
	result["x"] = cos(angle) * (radius + 0.12 * lift * sin(angle * 2))
	result["y"] = (recipe.spawnHeight - center_height) * (1 - lift) + lift * (0.4 + 0.65 * sin(angle + index * 0.3))
	result["z"] = sin(angle) * (radius + 0.12 * lift * sin(angle * 2))
	result["size"] = size
	result["width"] = 1
	result["stretch"] = 1 + 0.3 * energy
	result["rotation"] = -0.35 + 0.45 * flutter
	result["opacity"] = smooth(t / recipe.revealSeconds)
	return result

## Sample diamonds from absolute seconds; no frame-dependent integration.
static func diamonds(seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	var p: Dictionary[String, float] = launch_pose(seconds, index, center_height, recipe)
	p.y += p.lift * 0.35 * sin(p.angle * 2)
	var result: Dictionary[String, float] = p.duplicate()
	result["size"] = 0.26 + (index % 3) * 0.025
	result["width"] = 0.9 + 0.1 * cos(p.phase * 2 + index)
	result["stretch"] = 1 + 0.4 * p.energy
	result["rotation"] = 0.18 * sin(p.phase + index)
	return result

## Sample flowers from absolute seconds; no frame-dependent integration.
static func flowers(seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	var p: Dictionary[String, float] = launch_pose(seconds, index, center_height, recipe)
	p.y += p.lift * 0.5 * sin(p.angle + index * 0.4)
	var result: Dictionary[String, float] = p.duplicate()
	result["size"] = 0.26 + (index % 3) * 0.025
	result["width"] = 1
	result["stretch"] = 1 + 0.25 * p.energy
	result["rotation"] = p.phase * 0.5 + index * 0.3
	return result

## Sample feathers from absolute seconds; no frame-dependent integration.
static func feathers(seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	var p: Dictionary[String, float] = launch_pose(seconds, index, center_height, recipe)
	p.x += p.lift * 0.16 * sin(p.phase * 2 + index)
	p.y += p.lift * 0.55 * sin(p.angle + index * 0.5)
	var result: Dictionary[String, float] = p.duplicate()
	result["size"] = 0.32 + (index % 3) * 0.025
	result["width"] = 0.9 + 0.1 * sin(p.phase * 2 + index)
	result["stretch"] = 1 + 0.3 * p.energy
	result["rotation"] = -0.5 + 0.55 * sin(p.phase + index)
	return result

## Sample notes from absolute seconds; no frame-dependent integration.
static func notes(seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	var p: Dictionary[String, float] = launch_pose(seconds, index, center_height, recipe)
	var beat: float = 0.5 - 0.5 * cos(p.phase * 4 + index * 0.65)
	p.y += p.lift * (0.15 * sin(p.angle) + 0.45 * beat)
	var result: Dictionary[String, float] = p.duplicate()
	result["size"] = 0.29 + (index % 3) * 0.02
	result["width"] = 1
	result["stretch"] = 1 + 0.25 * p.energy
	result["rotation"] = 0.16 * sin(p.phase * 4 + index * 0.65)
	return result

## Sample fire from absolute seconds; no frame-dependent integration.
static func fire(seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	var p: Dictionary[String, float] = launch_pose(seconds, index, center_height, recipe)
	var flicker: float = sin(p.phase * 5 + index * 1.7)
	p.y = 0.035 - center_height
	var result: Dictionary[String, float] = p.duplicate()
	result["size"] = 0.38 + (index % 3) * 0.028
	result["width"] = 0.95 - 0.1 * p.lift * flicker
	result["stretch"] = (0.18 + 0.82 * p.lift) * (1 + 0.8 * p.energy) + 0.12 * p.lift * flicker
	result["rotation"] = 0.07 * p.lift * sin(p.phase * 4 + index)
	return result

## Dispatch through typed calls so unknown presets fail at the module boundary.
static func sample(id: String, seconds: float, index: int, center_height: float, recipe: Dictionary[String, float]) -> Dictionary[String, float]:
	match id:
		"orbit":
			return orbit(seconds, index, center_height, recipe)
		"bubbles":
			return bubbles(seconds, index, center_height, recipe)
		"starburst":
			return starburst(seconds, index, center_height, recipe)
		"petals":
			return petals(seconds, index, center_height, recipe)
		"confetti":
			return confetti(seconds, index, center_height, recipe)
		"bolts":
			return bolts(seconds, index, center_height, recipe)
		"ribbons":
			return ribbons(seconds, index, center_height, recipe)
		"hearts":
			return hearts(seconds, index, center_height, recipe)
		"crescents":
			return crescents(seconds, index, center_height, recipe)
		"diamonds":
			return diamonds(seconds, index, center_height, recipe)
		"flowers":
			return flowers(seconds, index, center_height, recipe)
		"feathers":
			return feathers(seconds, index, center_height, recipe)
		"notes":
			return notes(seconds, index, center_height, recipe)
		"fire":
			return fire(seconds, index, center_height, recipe)
	assert(false, "Unknown die effect: " + id)
	return {}
