extends SceneTree
## Shop interface integration check: every purchase path through real pointer input.
## Pass `-- --capture` with a display to save reference frames under /tmp.

# --- Constants ---

## Reusable scene under test; the debug host is not required.
const SHOP: PackedScene = preload("res://shop_interface/shop_interface.tscn")

# --- Member variables ---

## Offscreen viewport standing in for the game window.
var _viewport: SubViewport
## Refusals reported by the HUD, in order.
var _refusals: PackedStringArray = []

# --- Member functions ---

## Wait for the scene tree before building the viewport.
func _initialize() -> void:
	_run.call_deferred()

## Drag to buy, place, move, sell, and gamble; refresh and leave; check the run after each.
func _run() -> void:
	var capture: bool = "--capture" in OS.get_cmdline_user_args()
	create_timer(70.0).timeout.connect(_abort)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1280, 900)
	_viewport.msaa_3d = root.msaa_3d
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	_viewport.notify_mouse_entered()
	var shop_view: ShopInterface = SHOP.instantiate() as ShopInterface
	_viewport.add_child(shop_view)
	shop_view.muted = true
	shop_view.reduced_motion = not capture
	var hud: ShopHud = shop_view.get_node("Interface/Hud") as ShopHud
	hud.refused.connect(func(reason: String, _at: Vector2) -> void: _refusals.append(reason))
	var catalog: EffectsCatalog = EffectsCatalog.new()
	var run: MechanicsRun = MechanicsRun.new(60)
	assert(run.install_upgrade(catalog.upgrade(&"jackpot")).is_empty())
	assert(run.add_joker(catalog.joker(&"window_shopper"), 3).is_empty())
	assert(run.equip_bonus(catalog.bonus(&"six_addict"), &"die_1", 2).is_empty())
	var rules: ShopRules = ShopRules.new()
	var session: ShopSession = ShopSession.new(run, rules, 2026)
	shop_view.open_shop(session, "Before round 2")
	await _frames(3)
	if capture:
		await create_timer(1.2).timeout
		await _save("/tmp/paroli-shop-open.png")
	# Shelf: five known offers and two random purchases, all inside the felt.
	assert(hud._slots.size() == 7)
	var docks: Node = hud.get_node("Docks")
	var stage: TableStage = shop_view.stage
	for index: int in 5:
		var column: float = stage.columns()[index]
		assert(absf((docks.get_child(index) as Control).get_global_rect().get_center().x - column) < 2.0)
	assert(stage.views[&"die_1"].faces == PackedInt32Array([1, 1, 1, 1, 1, 6]), "Dice wear their upgrade in the shop")
	# A press without a drag only inspects: the tile lifts, destinations light, nothing is bought.
	var joker_slot: OfferCard = hud._slots[0]
	var rack_slot: Control = hud.get_node("Jokers/Joker2") as Control
	_move(_center(joker_slot))
	_button(_center(joker_slot), true)
	await _frames(2)
	assert(hud._held == ShopHud.Held.OFFER and (rack_slot.get_node("Target") as Control).visible)
	assert((hud.get_node("Tooltip") as Control).visible, "A held item explains itself")
	_button(_center(joker_slot), false)
	await _frames(2)
	assert(hud._held == ShopHud.Held.NONE and run.coins == 60 and joker_slot.stocked, "A click alone buys nothing")
	assert(not (rack_slot.get_node("Target") as Control).visible)
	# Known Joker: drag it onto the rack. The destination under the pointer brightens.
	_button(_center(joker_slot), true)
	await process_frame
	for step: int in range(1, 6):
		_move(_center(joker_slot).lerp(_center(rack_slot), float(step) / 5.0))
		await process_frame
	assert(hud._dragging and (hud.get_node("Ghost") as Control).visible and hud._hot == rack_slot)
	if capture:
		await create_timer(0.3).timeout
		await _save("/tmp/paroli-shop-held.png")
	_button(_center(rack_slot), false)
	await _frames(2)
	assert(run.coins == 54 and not joker_slot.stocked and hud._held == ShopHud.Held.NONE)
	assert((hud.get_node("Jokers/Joker2") as BuildCard).definition == session.offers[0].definition)
	# Known bonus: an occupied die refuses the drop, a free column accepts it.
	await _drag(_center(hud._slots[2]), _center(docks.get_child(0) as Control))
	assert(_refusals[_refusals.size() - 1] == ShopSession.NO_BONUS_SLOT and run.coins == 54 and hud._held == ShopHud.Held.NONE)
	assert(hud._slots[2].stocked, "A refused drop sends the item back")
	await _drag(_center(hud._slots[2]), _center(docks.get_child(2) as Control))
	assert(run.find_owned(&"bonus:die_3").definition == session.offers[2].definition and run.coins == 50)
	# The die itself is a destination too.
	await _drag(_center(hud._slots[3]), stage.die_rect(&"die_4").get_center())
	assert(run.find_owned(&"bonus:die_4").definition == session.offers[3].definition and run.coins == 46)
	await _drag(_center(hud._slots[4]), _center(docks.get_child(4) as Control))
	assert(run.find_owned(&"bonus:die_5").definition == session.offers[4].definition and run.coins == 42)
	# A Joker dropped on a die, or anything dropped on nothing, goes back.
	await _drag(_center(hud._slots[1]), _center(docks.get_child(1) as Control))
	assert(run.coins == 42 and hud._slots[1].stocked and hud._held == ShopHud.Held.NONE)
	await _drag(_center(docks.get_child(4) as Control), Vector2(640.0, 20.0))
	assert(run.find_owned(&"bonus:die_5") != null and hud._held == ShopHud.Held.NONE)
	# Owned bonus: picking it up shows its sale value; dropping it on a free die moves it.
	var source: Vector2 = _center(docks.get_child(2) as Control)
	_move(source)
	_button(source, true)
	await _frames(2)
	assert(hud._held == ShopHud.Held.BONUS and (hud.get_node("SellBadge") as Control).visible)
	for step: int in range(1, 6):
		_move(source.lerp(_center(docks.get_child(1) as Control), float(step) / 5.0))
		await process_frame
	_button(_center(docks.get_child(1) as Control), false)
	await _frames(2)
	assert(run.find_owned(&"bonus:die_2").definition == session.offers[2].definition and not run.find_owned(&"bonus:die_3"))
	# Owned Joker: drop it on the purse to sell it.
	await _drag(_center(hud.get_node("Jokers/Joker1") as Control), _center(hud.get_node("Coins") as Control))
	assert(not run.find_owned(&"joker:window_shopper") and run.coins == 45 and session.free_joker_slots() == 3)
	# Random Joker: dropped on the rack, revealed, and racked at a discount.
	await _drag(_center(hud._slots[5]), _center(hud.get_node("Jokers/Joker3") as Control))
	assert(shop_view.is_busy() or shop_view.reduced_motion, "The reveal locks the shop for a beat")
	await _until_settled(shop_view)
	assert(session.free_joker_slots() == 2 and run.coins == 45 - session.random_price(ShopSession.JOKER))
	# Random bonus: the die it is dropped on receives whatever turns up.
	await _drag(_center(hud._slots[6]), _center(docks.get_child(2) as Control))
	await _until_settled(shop_view)
	assert(run.find_owned(&"bonus:die_3") != null and run.coins == 38)
	if capture:
		await create_timer(0.8).timeout
		await _save("/tmp/paroli-shop-bought.png")
	# Every die now has a bonus: bonus goods refuse to be picked up.
	assert(session.free_bonus_dice().is_empty())
	_refusals.clear()
	await _click(_center(hud._slots[6]))
	assert(_refusals == PackedStringArray([ShopSession.NO_BONUS_SLOT]) and hud._held == ShopHud.Held.NONE)
	# Paid refresh: new shelf, dearer next time.
	var refresh: ActionButton = hud.get_node("Refresh") as ActionButton
	await _click(_center(refresh))
	await _frames(2)
	assert(run.coins == 36 and session.refresh_cost() == 3 and hud._slots.size() == 7)
	assert(hud._slots[0].stocked and (refresh.get_node("Content/Cost/Amount") as Label).text == "3")
	# An empty purse refuses purchases and disables the refresh.
	run.coins = 0
	hud.sync()
	await _click(_center(hud._slots[0]))
	assert(_refusals[_refusals.size() - 1] == ShopSession.NO_COINS and hud._held == ShopHud.Held.NONE and refresh.disabled)
	# Leaving reports once.
	var left: Array[bool] = []
	shop_view.leave_requested.connect(func() -> void: left.append(true))
	await _click(_center(hud.get_node("Leave") as Control))
	assert(left.size() == 1)
	# Tablet and phone shapes: columns clear the buttons, the shelf stays on the felt.
	for shape: Vector2i in [Vector2i(1000, 1000), Vector2i(768, 1024), Vector2i(1024, 768), Vector2i(540, 960), Vector2i(1280, 900)]:
		_viewport.size = shape
		await _frames(2)
		for index: int in 5:
			var dock_rect: Rect2 = (docks.get_child(index) as Control).get_global_rect()
			for action: Control in [refresh, hud.get_node("Leave") as Control]:
				assert(not dock_rect.grow(4.0).intersects(action.get_global_rect()), "Dock %d touches %s at %s" % [index, action.name, shape])
		var felt_left: float = stage.project(Vector3(-ParoliTable.PLAY_HALF_EXTENTS.x, 0.0, 0.0)).x
		var felt_right: float = stage.project(Vector3(ParoliTable.PLAY_HALF_EXTENTS.x, 0.0, 0.0)).x
		for slot: OfferCard in hud._slots:
			var slot_rect: Rect2 = slot.get_global_rect()
			assert(slot_rect.position.x >= felt_left and slot_rect.end.x <= felt_right, "Shelf leaves the felt at %s" % shape)
			assert(slot_rect.end.y < stage.die_rect(&"die_1").position.y + 6.0, "Shelf covers the dice at %s" % shape)
		if capture and shape == Vector2i(540, 960):
			run.coins = 30
			hud.sync()
			await create_timer(0.5).timeout
			await _save("/tmp/paroli-shop-portrait.png")
	print("PASS: shop interface drag-and-drop purchases, placement, move, sale, random purchases, refresh, refusals, layouts.")
	quit()

## Window-pixel center of a control.
func _center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()

## Press and release the primary button at a window position.
func _click(point: Vector2) -> void:
	_move(point)
	for pressed: bool in [true, false]:
		_button(point, pressed)
		await physics_frame
		await process_frame

## Press, travel, and release, as one drag gesture.
func _drag(from: Vector2, to: Vector2) -> void:
	_move(from)
	_button(from, true)
	await process_frame
	for step: int in range(1, 6):
		_move(from.lerp(to, float(step) / 5.0))
		await process_frame
	_button(to, false)
	await physics_frame
	await process_frame

## Send pointer motion.
func _move(point: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	_viewport.push_input(motion, true)

## Send a primary button change.
func _button(point: Vector2, pressed: bool) -> void:
	var button: InputEventMouseButton = InputEventMouseButton.new()
	button.position = point
	button.global_position = point
	button.button_index = MOUSE_BUTTON_LEFT
	button.pressed = pressed
	_viewport.push_input(button, true)

## Wait until a purchase presentation has finished.
func _until_settled(shop_view: ShopInterface) -> void:
	await _frames(2)
	while shop_view.is_busy():
		await process_frame
	await _frames(2)

## Let a few frames pass.
func _frames(count: int) -> void:
	for frame: int in count:
		await process_frame

## Watchdog: report a stalled check instead of hanging.
func _abort() -> void:
	push_error("Shop interface smoke check stalled")
	quit(1)

## Save the offscreen viewport after the frame has been drawn.
func _save(path: String) -> void:
	assert(DisplayServer.get_name() != "headless", "Capture needs a rendering display")
	await RenderingServer.frame_post_draw
	_viewport.get_texture().get_image().save_png(path)
