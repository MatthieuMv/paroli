extends SceneTree
## Shop interface integration check: every purchase path through real pointer input.
## Pass `-- --capture` with a display to save reference frames under /tmp.

# --- Constants ---

## Reusable scene under test; the debug host is not required.
const SHOP: PackedScene = preload("res://shop_interface/shop_interface.tscn")

## Window pixels per logical pixel of the phone the layout checks stand in for.
const PHONE_DENSITY: float = 2.625
## Smallest side, in logical pixels, of anything the player presses.
const TOUCH_TARGET: float = 44.0

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
	assert(run.add_joker(catalog.joker(&"roulette"), 3).is_empty())
	assert(run.equip_bonus(catalog.bonus(&"six-addict"), &"die_1", 2).is_empty())
	var rules: ShopRules = ShopRules.new()
	var session: ShopSession = ShopSession.new(run, rules, 2026)
	shop_view.open_shop(session, "Before round 2")
	await _frames(3)
	if capture:
		await create_timer(1.2).timeout
		await _save("/tmp/paroli-shop-open.png")
	# Shelf: five known offers, all inside the felt.
	assert(hud._slots.size() == 5)
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
	assert(not run.find_owned(&"joker:roulette") and run.coins == 45 and session.free_joker_slots() == 3)
	# The other known Joker takes the next free rack slot.
	await _drag(_center(hud._slots[1]), _center(hud.get_node("Jokers/Joker3") as Control))
	await _until_settled(shop_view)
	assert(session.free_joker_slots() == 2 and run.coins == 39)
	# Paid refresh: new shelf, dearer next time.
	var refresh: ActionButton = hud.get_node("Refresh") as ActionButton
	await _click(_center(refresh))
	await _frames(2)
	assert(run.coins == 37 and session.refresh_cost() == 3 and hud._slots.size() == 5)
	assert(hud._slots[0].stocked and (refresh.get_node("Content/Cost/Amount") as Label).text == "3")
	# The last free die takes a bonus from the new stock.
	await _drag(_center(hud._slots[2]), _center(docks.get_child(2) as Control))
	await _until_settled(shop_view)
	assert(run.find_owned(&"bonus:die_3") != null and run.coins == 33)
	if capture:
		await create_timer(0.8).timeout
		await _save("/tmp/paroli-shop-bought.png")
	# Every die now has a bonus: bonus goods refuse to be picked up.
	assert(session.free_bonus_dice().is_empty())
	_refusals.clear()
	await _click(_center(hud._slots[3]))
	assert(_refusals == PackedStringArray([ShopSession.NO_BONUS_SLOT]) and hud._held == ShopHud.Held.NONE)
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
	# Window shapes: columns clear the buttons and the stock never covers the dice. On
	# desktop the whole shelf lies on the felt; narrow windows may keep part of it elsewhere.
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
			if hud.layout.shape == HudLayout.Shape.WIDE:
				assert(slot_rect.position.x >= felt_left and slot_rect.end.x <= felt_right, "Shelf leaves the felt at %s" % shape)
			assert(Rect2(Vector2.ZERO, Vector2(shape)).encloses(slot_rect), "Shelf leaves the window at %s" % shape)
			assert(slot_rect.end.y < stage.die_rect(&"die_1").position.y + 6.0, "Shelf covers the dice at %s" % shape)
		if capture and shape == Vector2i(540, 960):
			run.coins = 30
			hud.sync()
			await create_timer(0.5).timeout
			await _save("/tmp/paroli-shop-portrait.png")
	# Phones: a dense screen gets finger-sized goods, all of them inside one counter card,
	# and the same tile size for what is sold and what is owned.
	shop_view.display_density = PHONE_DENSITY
	run.coins = 60
	for phone: Vector2i in [Vector2i(1080, 2378), Vector2i(2378, 1080)]:
		_viewport.size = phone
		shop_view.open_shop(session, "Before round 3")
		await _frames(3)
		if capture:
			# With motion on, freshly dealt goods pop in; measure them at rest.
			await create_timer(1.0).timeout
		var window: Rect2 = Rect2(Vector2.ZERO, Vector2(phone))
		var tall: bool = phone.x < phone.y
		assert(hud.layout.shape == (HudLayout.Shape.TALL if tall else HudLayout.Shape.SIDE), "Wrong arrangement at %s" % phone)
		var rack_tile: Rect2 = (hud.get_node("Jokers/Joker1") as Control).get_global_rect()
		var counter: Rect2 = (hud.get_node("Sign") as Control).get_global_rect()
		var tiles: Array[Rect2] = []
		for slot: OfferCard in hud._slots:
			var tile: Rect2 = slot.card.get_global_rect()
			assert(tile.size.x / PHONE_DENSITY >= TOUCH_TARGET, "Goods too small to pick up at %s" % phone)
			assert(window.encloses(slot.get_global_rect()), "Goods leave the window at %s" % phone)
			for die_id: StringName in stage.views:
				assert(not tile.intersects(stage.die_rect(die_id).grow(-4.0)), "Goods cover %s at %s" % [die_id, phone])
			for other: Rect2 in tiles:
				assert(not tile.intersects(other), "Goods overlap at %s" % phone)
			tiles.append(tile)
			# Everything for sale sits on the counter, at about the size of an owned tile.
			assert(counter.encloses(slot.get_global_rect()), "Goods leave the counter at %s" % phone)
			assert(absf(tile.size.x / rack_tile.size.x - 1.0) < 0.15, "Goods and owned tiles differ in size at %s" % phone)
		for index: int in 4:
			var owned: Rect2 = (hud.get_node("Jokers").get_child(index) as Control).get_global_rect()
			assert(not counter.intersects(owned), "The rack hides under the counter at %s" % phone)
			# In portrait the rack lies on the felt, above the dice it shares the table with.
			assert(not tall or (stage.camera.framed_rect.encloses(owned) and owned.end.y <= stage.die_rect(&"die_1").position.y + 6.0), "The rack is off the felt at %s" % phone)
		for index: int in 5:
			var dock: DieDock = docks.get_child(index) as DieDock
			assert(absf(dock.get_global_rect().get_center().x - stage.columns()[index]) < 2.0, "Dock %d is off its die column at %s" % [index, phone])
			assert(dock.card.get_global_rect().size.x / PHONE_DENSITY >= TOUCH_TARGET, "Bonus slot too small at %s" % phone)
			assert(absf(dock.card.get_global_rect().size.x - rack_tile.size.x) < 1.0, "Joker and bonus tiles differ in size at %s" % phone)
		for action: Control in [refresh, hud.get_node("Leave") as Control, hud.get_node("Coins") as Control]:
			assert(window.encloses(action.get_global_rect()), "%s leaves the window at %s" % [action.name, phone])
		# The same gestures work at this scale: a held item explains itself clear of the
		# goods, and a drag buys it.
		var goods: OfferCard = hud._slots[0]
		var jokers_before: int = run.owned.filter(func(item: OwnedDefinition) -> bool: return item.definition is JokerDefinition).size()
		_move(_center(goods.card))
		_button(_center(goods.card), true)
		await _frames(3)
		var sheet: Rect2 = (hud.get_node("Tooltip") as Control).get_global_rect()
		assert((hud.get_node("Tooltip") as Control).visible and window.grow(1.0).encloses(sheet), "A held item explains itself on screen at %s" % phone)
		assert(not sheet.intersects(goods.card.get_global_rect()), "The explanation covers the held item at %s" % phone)
		_button(_center(goods.card), false)
		await _frames(2)
		await _drag(_center(goods.card), _center(hud.get_node("Jokers/Joker4") as Control))
		await _until_settled(shop_view)
		assert(run.owned.filter(func(item: OwnedDefinition) -> bool: return item.definition is JokerDefinition).size() == jokers_before + 1, "A drag buys a Joker at %s" % phone)
		if capture:
			await create_timer(0.5).timeout
			await _save("/tmp/paroli-shop-phone-%dx%d.png" % [phone.x, phone.y])
	print("PASS: shop interface drag-and-drop purchases, placement, move, sale, refresh, refusals, layouts, phones.")
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
