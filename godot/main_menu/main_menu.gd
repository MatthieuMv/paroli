extends Node3D
class_name MainMenu
## Title screen: the shared table with five colorful dice tumbling onto it, the game's name,
## and the way into a fresh run. Dice are a toy here: pressing one rerolls it, purely for
## show. Starting the run is the host's job; the menu only reports the request.

# --- Signals ---

## The player asked for a fresh run.
signal new_run_requested

# --- Constants ---

## Body color of each die, in run order; the menu shows off the palette.
const DIE_COLORS: PackedStringArray = ["Peach", "Butter", "Mint", "Lavender", "Sky"]
## Seconds between neighboring dice of the opening throw.
const THROW_STAGGER: float = 0.08
## Smallest pointer target, in HUD units, around each die.
const TOUCH_REACH: float = 56.0

# --- Member variables ---

## Removes springs, staggers, and wallpaper drift; dice settle immediately.
@export var reduced_motion: bool = false:
	set(value):
		reduced_motion = value
		if is_node_ready():
			_apply_motion()
## Silences sound effects; the shared sound preference also silences them.
@export var muted: bool = false:
	set(value):
		muted = value
		if is_node_ready():
			_apply_sound()
## Window pixels per logical pixel, which sizes the HUD for the screen it is on. Zero follows
## the display; checks set it to lay a phone out in an offscreen viewport.
@export_range(0.0, 4.0, 0.125) var display_density: float = 0.0:
	set(value):
		display_density = value
		if is_node_ready():
			_layout()
## Shared table set: wallpaper, camera, table, and dice. Hosts may restyle its wallpaper.
@onready var stage: TableStage = $Stage
## Title, actions, and settings.
@onready var _hud: MainMenuHud = $Interface/Hud
## Sound effects.
@onready var _audio: RoundAudio = $Audio
## Presentation-only randomness for the faces the dice show.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Invalidates a staggered throw when a newer one starts.
var _generation: int = 0

# --- Member functions ---

## Ready callback: paint the dice, connect the HUD, frame the table, and throw the dice.
func _ready() -> void:
	get_viewport().physics_object_picking = true
	_rng.randomize()
	var dice: Array[ParoliDie] = stage.dice()
	for index: int in dice.size():
		var die: ParoliDie = dice[index]
		die.palette_color = DIE_COLORS[index % DIE_COLORS.size()]
		die.interaction_enabled = true
		die.clicked.connect(_on_die_clicked.bind(die))
		die.rolled.connect(_on_die_rolled.bind(die))
	_hud.new_run_pressed.connect(_on_new_run)
	_hud.quit_pressed.connect(_on_quit)
	_hud.hover_ticked.connect(_audio.play.bind(&"hover", 0, 0.0, 0.1))
	GameSettings.shared().changed.connect(_on_settings_changed)
	_apply_motion()
	_apply_sound()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_hud.present()
	throw_dice()

## Tumble every die onto the table, one after another, landing on random faces.
func throw_dice() -> void:
	_generation += 1
	var generation: int = _generation
	_audio.play(&"roll")
	for die: ParoliDie in stage.dice():
		if generation != _generation or not is_inside_tree():
			return
		die.roll(_rng.randi_range(1, 6))
		if not reduced_motion:
			await get_tree().create_timer(THROW_STAGGER).timeout

## Re-entering the tree after being parked: the window may have changed meanwhile.
func _enter_tree() -> void:
	if is_node_ready():
		_layout.call_deferred()

## Fit the HUD and the table to the window.
func _layout() -> void:
	if not is_inside_tree():
		return
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	var free: Rect2 = _hud.arrange(viewport, display_density)
	var pixels_per_unit: float = stage.frame(free, viewport, _hud.layout.table_half_width)
	stage.set_touch_reach(TOUCH_REACH * _hud.layout.ui_scale, pixels_per_unit)
	_hud.fit_around(stage.camera.framed_rect)

## Push the reduced-motion preference into the stage and HUD.
func _apply_motion() -> void:
	stage.reduced_motion = reduced_motion
	_hud.reduced_motion = reduced_motion

## Sound plays only when neither the host nor the player silenced it.
func _apply_sound() -> void:
	_audio.muted = muted or not GameSettings.shared().sound_enabled

## A pressed die rerolls; it shows off the dice and decides nothing.
func _on_die_clicked(die: ParoliDie) -> void:
	if die.is_rolling() or _hud.settings.is_open():
		return
	_audio.play(&"roll", 0, 0.0, 0.1)
	die.roll(_rng.randi_range(1, 6))

## A landing clacks and nudges the title above.
func _on_die_rolled(_value: int, die: ParoliDie) -> void:
	_audio.play_clack(-8.0)
	_hud.nudge_title()
	if not reduced_motion:
		Juice.hop(die, 0.5)

## Report the request; the host builds the run.
func _on_new_run() -> void:
	_audio.play(&"button")
	new_run_requested.emit()

## Close the game.
func _on_quit() -> void:
	_audio.play(&"button")
	get_tree().quit()

## Follow the shared preferences: captions and sound.
func _on_settings_changed() -> void:
	_hud.relabel()
	_apply_sound()
	_layout()
