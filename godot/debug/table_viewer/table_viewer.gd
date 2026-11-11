extends Node3D
class_name TableViewer
## Independent staging scene for checking table proportions, rolls, and VFX clearance.

# --- Member variables ---

## Scene-authored table; the viewer uses only its public palette and anchor API.
@onready var _table: ParoliTable = $Table
## Five native die instances let colors and silhouettes be compared on the felt.
@onready var _dice_root: Node3D = $Dice
## Independent interaction module owns the held selection and marker transfers.
@onready var _hold: DiceHoldController = $HoldController
## Readable feedback after rolling without introducing gameplay state.
@onready var _status: Label = %Status
## Presentation-only choice overlay; no upgrade model is connected.
@onready var _augments: AugmentOverlay = %AugmentOverlay
## Incremented only to cycle deterministic preview faces.
var _roll_index: int = 0

## Optional sandbox run demonstrates real eligibility without introducing a game loop.
var _preview_run: MechanicsRun
## Stable mechanics identities mapped to native die instances.
var _views: Dictionary[StringName, ParoliDie] = {}

# --- Member functions ---

## Ready callback: place dice through the table API and connect preview controls.
func _ready() -> void:
	get_viewport().physics_object_picking = true
	var dice: Array[ParoliDie] = []
	var positions: PackedVector3Array = _table.get_roll_positions()
	for index: int in _dice_root.get_child_count():
		var die: ParoliDie = _dice_root.get_child(index) as ParoliDie
		die.global_position = positions[index]
		die.palette_color = "Chalk"
		die.rolled.connect(_on_die_rolled)
		dice.append(die)
		_views[StringName("die_%d" % (index + 1))] = die
	_hold.configure(_table, dice)
	_hold.changed.connect(_update_status)
	(%Roll as Button).pressed.connect(_roll_all)
	(%Effects as Button).toggled.connect(_on_effects_toggled)
	(%Mint as Button).pressed.connect(_set_felt.bind(GameColors.MINT))
	(%Lavender as Button).pressed.connect(_set_felt.bind(GameColors.LAVENDER))
	(%Chalk as Button).pressed.connect(_set_felt.bind(GameColors.CHALK))
	(%Upgrades as Button).pressed.connect(_augments.open)
	_augments.presentation_changed.connect(_on_augment_presentation_changed)
	_roll_all()

## Space provides the same deterministic visual roll as the preview button.
func _unhandled_key_input(event: InputEvent) -> void:
	if _augments.is_blocking():
		return
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_SPACE:
			_roll_all()
			get_viewport().set_input_as_handled()

## Roll only available dice; held values and transfers are preserved.
func _roll_all() -> void:
	var available: Array[ParoliDie] = []
	for die: ParoliDie in _dice_root.get_children():
		if _hold.can_roll(die):
			available.append(die)
	if available.is_empty():
		_update_status()
		return
	_roll_index += 1
	if _preview_run:
		var faces: Dictionary[StringName, int] = {}
		for id: StringName in _views:
			if _views[id] in available:
				faces[id] = (_roll_index + _views[id].get_index() * 2) % 6
		var result: MechanicsEventResult = _preview_run.roll(StringName("roll_%d" % _roll_index), faces, EffectContext.RollKind.MANUAL)
		assert(result.errors.is_empty())
	for die: ParoliDie in available:
		var value: int = (_roll_index + die.get_index() * 2) % 6 + 1
		if _preview_run:
			value = _preview_run.dice[die.get_index()].value
		die.roll(value)
	_update_status()

## Refresh button availability when a roll finishes.
func _on_die_rolled(_value: int) -> void:
	_update_status()

## Expose selection and readiness without letting the UI inspect module internals.
func _update_status() -> void:
	_refresh_upgrade_preview()
	var ready: bool = false
	for die: ParoliDie in _dice_root.get_children():
		ready = ready or _hold.can_roll(die)
	(%Roll as Button).disabled = not ready
	_status.text = "Roll %02d  ·  %d / %d held  ·  Press and sweep to hold or release" % [
		_roll_index, _hold.held_count(), _dice_root.get_child_count()
	]

## Exercise five complementary upgrades with the same rules used by the run coordinator.
func _on_effects_toggled(enabled: bool) -> void:
	_preview_run = MechanicsRun.new() if enabled else null
	if enabled:
		var catalog: EffectsCatalog = EffectsCatalog.new()
		for id: StringName in [&"all_for_one", &"guardian", &"jackpot", &"golden_touch", &"lone_wolf"]:
			var errors: PackedStringArray = _preview_run.install_upgrade(catalog.upgrade(id))
			assert(errors.is_empty())
		# Large allowances keep this visual sandbox usable without round controls.
		var started: MechanicsEventResult = _preview_run.start_round(&"start", 1000000.0, 10000, 10000)
		assert(started.errors.is_empty())
		var faces: Dictionary[StringName, int] = {&"die_1": 0, &"die_2": 0, &"die_3": 5, &"die_4": 0, &"die_5": 0}
		var rolled: MechanicsEventResult = _preview_run.roll(&"opening", faces, EffectContext.RollKind.OPENING)
		assert(rolled.errors.is_empty())
		for id: StringName in _views:
			_views[id].face_value = _preview_run.find_die(id).value
	else:
		for die: ParoliDie in _views.values():
			die.effect_enabled = false
			die.effect = "none"
			die.palette_color = "Chalk"
	_update_status()

## A play selects unheld dice. Wait for the whole selection to settle before predicting it.
func _refresh_upgrade_preview() -> void:
	if not _preview_run:
		return
	var selected: Array[StringName] = []
	var settled: bool = true
	for id: StringName in _views:
		var die: ParoliDie = _views[id]
		settled = settled and _hold.can_mutate(die)
		if not _hold.is_held(die):
			selected.append(id)
	UpgradePresentation.refresh(_preview_run, selected if settled else [], _views)

## Recolor only the table surface; the die palette stays independently editable.
func _set_felt(color: Color) -> void:
	_table.surface_color = color


## Keep debug controls out of the card composition, restoring them for inspection.
func _on_augment_presentation_changed(blocking: bool) -> void:
	($Interface/Header as Control).visible = not blocking
	($Interface/Footer as Control).visible = not blocking
