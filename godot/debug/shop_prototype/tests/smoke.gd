extends SceneTree
## Shop prototype host check: fixtures, debug coins, restocking, and reopening on exit.
## Pass `-- --capture` with a display to save /tmp/paroli-shop-prototype.png.

# --- Constants ---

## Debug host under test.
const PROTOTYPE: PackedScene = preload("res://debug/shop_prototype/shop_prototype.tscn")

# --- Member functions ---

## Wait for the scene tree before building the viewport.
func _initialize() -> void:
	_run.call_deferred()

## Drive the host's own controls and confirm each reaches the shop.
func _run() -> void:
	create_timer(40.0).timeout.connect(_abort)
	var capture: bool = "--capture" in OS.get_cmdline_user_args()
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1280, 900)
	viewport.msaa_3d = root.msaa_3d
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var prototype: ShopPrototype = PROTOTYPE.instantiate() as ShopPrototype
	viewport.add_child(prototype)
	var shop_view: ShopInterface = prototype.get_node("Shop") as ShopInterface
	var hud: ShopHud = shop_view.get_node("Interface/Hud") as ShopHud
	(prototype.get_node("%Sound") as Button).button_pressed = false
	await process_frame
	if capture:
		await create_timer(1.3).timeout
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/paroli-shop-prototype.png")
	(prototype.get_node("%Motion") as Button).button_pressed = true
	# Starter fixture: one upgrade, one bonus, one Joker, twenty coins, a stocked shelf.
	var session: ShopSession = prototype._session
	assert(session.run.coins == 20 and session.free_joker_slots() == 3 and session.free_bonus_dice().size() == 4)
	assert(hud._slots.size() == 7 and (hud.get_node("%Title") as Label).text == "Before round 2")
	assert((hud.get_node("Docks/Dock1") as DieDock).upgrade.id == &"jackpot")
	# Debug coins reach the purse and the price tags without restocking.
	var first: IllustratedDefinition = session.offers[0].definition
	(prototype.get_node("%Coins") as Button).pressed.emit()
	assert(session.run.coins == 30 and hud._coin_balance == 30 and session.offers[0].definition == first)
	# Leaving reopens the next visit with new stock and the base refresh cost.
	assert(session.refresh().errors.is_empty() and session.refresh_cost() == 3)
	hud.leave_pressed.emit()
	assert((hud.get_node("%Title") as Label).text == "Before round 3" and session.refresh_cost() == 2)
	# Cycling the build starts a fresh run.
	(prototype.get_node("%Build") as Button).pressed.emit()
	assert(prototype._session != session and prototype._session.run.coins == 20)
	assert((prototype.get_node("%Build") as Button).text == "Build: Bare dice")
	assert(prototype._session.free_joker_slots() == 4 and prototype._session.free_bonus_dice().size() == 5)
	print("PASS: shop prototype fixtures, debug coins, reopening, build cycling.")
	quit()

## Watchdog: report a stalled check instead of hanging.
func _abort() -> void:
	push_error("Shop prototype smoke check stalled")
	quit(1)
