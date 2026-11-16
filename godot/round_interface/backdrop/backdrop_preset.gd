extends Resource
class_name BackdropPreset
## One wallpaper color scheme for the round backdrop. Pure authored colors: no pattern
## choice and no behavior, so schemes and motifs can be mixed freely.

# --- Member variables ---

## Name shown by debug controls.
@export var title: String = ""
## Tone behind the table.
@export var center_color: Color = GameColors.BACKGROUND
## Tone toward the window edges.
@export var edge_color: Color = GameColors.BACKGROUND
## Pattern marks drawn darker than the wall (pips, stripes, alternate cells).
@export var mark_color: Color = GameColors.BACKGROUND
## Pattern marks drawn lighter than the wall (sparkles, alternate dots).
@export var light_color: Color = GameColors.CONTROL_SURFACE
## Color for the few interface marks drawn straight on the wall: hint text, the
## multiplication sign, and free-slot outlines. Plum on light walls, cream on dark ones.
@export var wall_ink: Color = GameColors.INK
