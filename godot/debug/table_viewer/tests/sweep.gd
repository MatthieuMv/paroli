extends SceneTree
## Real viewport input regression for uninterrupted mouse and native touch sweeps.

# --- Constants ---

## Use the live integration so picking and controller guards are exercised together.
const VIEWER: PackedScene = preload("res://debug/table_viewer/table_viewer.tscn")

# --- Member variables ---

## Standalone test viewport owns physics picking and all test scene instances.
var _viewport: SubViewport
## Camera projects actual die positions into input coordinates.
var _camera: Camera3D

# --- Member functions ---

## Defer scene setup until the tree can accept children.
func _initialize() -> void:
	_run.call_deferred()

## Exercise both input devices without lifting between dice, including a moving die.
func _run() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1280, 900)
	root.add_child(_viewport)
	_viewport.notify_mouse_entered()
	var viewer: Node3D = VIEWER.instantiate() as Node3D
	_viewport.add_child(viewer)
	_camera = viewer.get_node("Camera") as Camera3D
	var hold: DiceHoldController = viewer.get_node("HoldController") as DiceHoldController
	var dice: Node3D = viewer.get_node("Dice") as Node3D
	var first: ParoliDie = dice.get_child(0) as ParoliDie
	var second: ParoliDie = dice.get_child(1) as ParoliDie
	for die: ParoliDie in dice.get_children():
		die.reduced_motion = true
	await process_frame
	await process_frame
	await physics_frame

	# Hover is inert; a press followed by held mouse motion selects another die.
	await _mouse_motion(first, 0)
	assert(hold.held_count() == 0)
	await _mouse_button(first, true)
	await _mouse_motion(second, MOUSE_BUTTON_MASK_LEFT)
	assert(hold.is_held(first) and hold.is_held(second))
	# Continue the same gesture over the settled hold positions to unhold them.
	await _mouse_motion(first, MOUSE_BUTTON_MASK_LEFT)
	await _mouse_motion(second, MOUSE_BUTTON_MASK_LEFT)
	assert(hold.held_count() == 0)
	await _mouse_button(second, false)
	assert(hold.held_count() == 0)

	# Native touch does not depend on mouse emulation; dragging reaches a second die.
	await _touch(first, true)
	await _touch_drag(second)
	assert(hold.is_held(first) and hold.is_held(second))
	await _touch_drag(first)
	await _touch_drag(second)
	assert(hold.held_count() == 0)
	await _touch(second, false)
	assert(hold.held_count() == 0)

	# Moving dice ignore both devices; after settling the same gesture may mutate again.
	first.reduced_motion = false
	hold.transfer_seconds = 0.3
	await _touch(first, true)
	assert(hold.is_held(first) and not hold.can_mutate(first))
	await _touch_drag(first)
	await _mouse_motion(first, MOUSE_BUTTON_MASK_LEFT)
	assert(hold.is_held(first), "Input reversed an active transfer")
	await create_timer(0.4).timeout
	assert(hold.can_mutate(first))
	await _touch_drag(first)
	assert(not hold.is_held(first), "Settled die could not be mutated without releasing")
	await _touch(first, false)
	print("PASS: mouse and touch sweeps, hover/release ignored, transfer guard, settled re-entry.")
	quit()

## Project the die body center, including its current transfer position.
func _point(die: ParoliDie) -> Vector2:
	return _camera.unproject_position(die.global_position + Vector3.UP * 1.145)

## Give physics picking time to dispatch queued input.
func _dispatch(event: InputEvent) -> void:
	_viewport.push_input(event, true)
	await physics_frame
	await process_frame

## Send genuine mouse motion with an explicit held-button mask.
func _mouse_motion(die: ParoliDie, buttons: int) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = _point(die)
	event.global_position = event.position
	event.relative = Vector2(1, 1)
	event.button_mask = buttons
	await _dispatch(event)

## Send one mouse press or release without implicitly releasing after a press.
func _mouse_button(die: ParoliDie, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.position = _point(die)
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	await _dispatch(event)

## Send a native finger press or release with a stable contact index.
func _touch(die: ParoliDie, pressed: bool) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = 0
	event.position = _point(die)
	event.pressed = pressed
	await _dispatch(event)

## Move the same finger to another die without ending the contact.
func _touch_drag(die: ParoliDie) -> void:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = 0
	event.position = _point(die)
	event.relative = Vector2(1, 1)
	await _dispatch(event)
