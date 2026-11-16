# Paroli Godot

Open `project.godot` in Godot 4.7 and press **F5** to run the table preview.
Open `debug/die_viewer/die_viewer.tscn` and press **F6** for the individual die studio.
See [AGENTS.md](AGENTS.md) for typed, documented, feature-owned coding conventions.
See the [design style guide](../docs/DESIGN_STYLE_GUIDE.md) for visual direction,
palette, camera, interface, motion, and interaction rules.

## Local Web export

Install the single-threaded Web debug and release export templates matching your
Godot editor version using **Editor → Manage Export Templates**. The `Web` preset
uses the project's Compatibility renderer with thread and extension support off,
so a plain local HTTP server is sufficient.

Run these commands from the repository root:

```sh
mkdir -p build/web
godot --headless --path godot --export-debug Web
python3 -m http.server 8000 --bind 127.0.0.1 --directory build/web
```

Open <http://127.0.0.1:8000> in Brave or another WebGL 2/WebAssembly-capable
browser. The build opens the table preview, just like F5 in the editor.
Stop the server with Ctrl+C. After edits, repeat the export command and refresh
the browser. Use `--export-release Web` instead for a release build.

The generated HTML, JavaScript, WebAssembly, and game data stay together in
`build/web/`, outside the Godot project and ignored by Git. Serve that directory
over HTTP; opening `index.html` directly as a file will not work. The preset is
also available under **Project → Export** in the editor.

## Local Android export

The `Android` preset builds a debug-signed APK for ARM phones (32-bit and 64-bit)
with package ID `org.paroli.game`. It uses the prebuilt Android templates; Android
Studio, Gradle, the NDK, and an emulator are not needed for this workflow.

Use Android export templates matching the editor exactly (currently 4.7.2).
In **Editor → Editor Settings → Export → Android**, configure these local paths:

- **Java SDK Path:** `~/.local/share/java/jdk-17` (expand `~` to your home directory).
- **Android SDK Path:** `~/Android/Sdk`.
- **Debug Keystore:** `~/.local/share/godot/keystores/debug.keystore`.

The local SDK includes command-line tools, platform-tools, Android platform 36,
and build-tools 36.1.0, matching the installed templates. The debug key uses alias
`androiddebugkey` and password `android`. Keep signing keys outside the repository.
The project enables ETC2/ASTC texture imports required by the Android exporter.

From the repository root:

```sh
mkdir -p build/android
godot --headless --path godot --export-debug Android
```

On the phone, enable Developer options (usually by tapping **Build number** seven
times in Settings), then enable **USB debugging**. Connect a USB data cable, unlock
the phone, and accept its debugging authorization prompt. Then run:

```sh
adb devices -l
adb install -r build/android/paroli.apk
```

The device must show `device`, rather than `unauthorized`, before installation.
If several devices are connected, use `adb -s DEVICE_SERIAL install -r ...`.
Open **Paroli** on the phone after installation. Godot's Android run button can
also deploy to a connected, authorized device because the preset is runnable.

This APK is for local testing. Store publication needs a release signing key and
a separate release/AAB configuration.

## Editing the native resources

The `.tscn` and `.tres` files are the source of truth. There is no JSON import,
JavaScript dependency, or regeneration step.

- [die/die.tscn](die/die.tscn): reusable die scene with its model and effects module.
- [die/model/model.tscn](die/model/model.tscn): body, outline, and numbered pip
  hierarchies. Shared `body_mesh.tres` and `pip_mesh.tres` hold the geometry.
- [game_colors/game_colors.gd](game_colors/game_colors.gd): global `GameColors`
  constants for named object colors, interface neutrals, and palette display order.
- [die/catalog.tres](die/catalog.tres): typed `DieCatalog` resource containing
  model references, shared body geometry, and preset order.
- `die/effects/<preset>/<preset>.tscn`: editable particle nodes, silhouette/detail
  meshes, and shader materials. For example, [fire/fire.tscn](die/effects/fire/fire.tscn)
  owns flames, ink outlines, and light-colored cores.
- `die/effects/<preset>/<preset>.tres`: typed `DieEffectDefinition` containing the
  scene, numeric motion settings, and native `activation.tres` animation.
- `die/effects/effect_poses.gd`: editable, typed analytic landing/sustain motion.
  This is maintained GDScript, not generated output.
- `die/finish/`: surface shader, shine, cracks, and seeded variation.
- `die/palette/die_palette_mesh.gd`: exposes each mesh's palette role and baseline
  opacity in the Inspector. `DieLibrary` binds those roles when a die changes color.
- [debug/die_viewer/die_viewer.tscn](debug/die_viewer/die_viewer.tscn): the independent
  development viewer, with scene-authored layout, theme, camera, and controls.

Keep material **Local To Scene** enabled: geometry is shared but colors and shader
uniforms belong to individual dice. Transparent particle meshes must keep
**Sorting Use AABB Center** disabled; their local depth offsets order outlines,
fills, and details. Palette role and opacity edits affect runtime color updates;
editing a material tint alone is overridden by the owning die's palette.

Activation resources contain linear value tracks named `Pose:<channel>`.
`DieActivation` samples them by time, allowing the die transform and persistent
particles to follow the same consume sequence. Their length defines activation
duration. No AnimationPlayer or external animation controller is required.

## Shared colors

`GameColors` is a globally registered GDScript class, with no autoload or scene
instance. Use `GameColors.SKY`, `GameColors.INK`, or another named constant
instead of repeating palette hex values. `GameColors.PALETTE` and
`GameColors.PALETTE_ORDER` are immutable; `GameColors.palette()` returns an
ordered, caller-owned dictionary. `DieLibrary.palette()` delegates to it and
keeps its existing public contract without loading the die asset catalog.

`KeywordColors` owns semantic mappings (Points → Sky, Mult → Cherry) and the
50% Ink blend used for readable text. It references the shared constants rather
than defining another palette. Die/table defaults, score outlines, keyword
highlights, and viewer color controls use the same constants.

Authored `.tscn`, `.tres`, shader, and SVG colors remain literal visual resources;
they cannot reference GDScript constants directly. Changing a shared color does
not automatically rewrite those files. Keep their authored values in sync when
intentionally changing art direction; this refactor preserves all current values.

```sh
godot --headless --path godot --script res://game_colors/tests/smoke.gd
```

The migration check locks the original 15 colors and order, verifies that callers
cannot mutate shared palette state, and checks die access and keyword text tones.

## Using the die

The die origin is the floor beneath it; its resting center is approximately
1.145 units above that origin. It needs a viewport camera but no scene lights:
toon shading follows the original art direction's fixed lighting.

```gdscript
const DIE_SCENE: PackedScene = preload("res://die/die.tscn")

var die: ParoliDie = DIE_SCENE.instantiate() as ParoliDie
add_child(die)
die.palette_color = "Lavender"
die.effect = "flowers"
die.shine_enabled = true
die.cracks_enabled = true
die.roll(5)
```

The Inspector exposes 15 palette colors, custom body/ink/shine tints, 14 particle
presets plus `none`, finishes, face layout, face value, and reduced motion. `faces` holds
the value printed on each of the six physical faces (ordinary dice use
`ParoliDie.STANDARD_FACES`); setting an upgrade's layout reprints the model, and
`roll(value)` lands on a face printed with that value. Values must be 1–6. `DieLibrary.palette()`
and `DieLibrary.effect_ids()` expose the ordered choices through typed APIs.

`rolled(value)` signals settling; `consumed` signals disappearance. `hover_changed(hovered)`
reports passive pointer enter/exit for feedback only; hovering never mutates a die. Call
`activate()` after settling and `roll()` to restore the die. `is_rolling()` and
`is_consumed()` expose state without child-node access. Omitting the value in
`roll()` cycles faces; rendering does not choose authoritative game outcomes.

## Validation

```sh
python godot/check_style.py
godot --headless --path godot --editor --quit
godot --headless --path godot --script res://die/tests/native_resources.gd
godot --headless --path godot --script res://die/tests/smoke.gd
godot --headless --path godot --script res://debug/die_viewer/tests/smoke.gd
# With a working display:
godot --path godot --script res://debug/die_viewer/tests/smoke.gd -- --capture
godot --path godot --script res://die/tests/particle_render.gd
```

Native-resource checks verify shared meshes, instance-local materials, palette
order, and linear animation tracks. Smoke checks cover colors, presets, all
activations, six landing faces, finishes, reduced motion, replay, and viewer
controls. The render regression checks fire/bolt/starburst colors and layering
across the palette and camera angles, saving `/tmp/paroli-particle-layers.png`.
The viewer capture saves `/tmp/paroli-viewer.png`.

Godot rejects untyped/inferred declarations. The conventions workflow runs the
additional structural/style checker; engine and rendering checks require Godot.

## Migration verification

The one-time native conversion used Godot's own ResourceSaver and PackedScene
serialization. Before removing the old loader, verification compared 374 nodes,
340 mesh instances (25 unique meshes), exact palette/recipe values, and 18,150
activation scalar samples. Mesh buffers were equal; native animation interpolation
had a maximum scalar difference of approximately `3.72e-7`.

All 130 before/after OpenGL captures were pixel-identical: 15 palette previews,
60 preset/time combinations, 45 activation samples, six faces, and four combined
finish samples. This validates the sampled scenarios, not every possible future
resource edit. The reference captures were temporary migration artifacts.

The previously documented rendering choices remain: top-face protection uses a
projected convex hull, and activation die curves interpolate sampled tracks.
Original Three.js geometry attribution is retained in `die/model/THREE-LICENSE.txt`.

## Rolling table

[table/table.tscn](table/table.tscn) is an independent, native 3D table with a mint
felt inset, peach beveled rail, cocoa apron and tapered legs, cream piping and
stitches, and butter-colored star inlays. Plum outlines and the fixed toon-light
ramp match the dice. All geometry and materials live in `table/`; no dice or
viewer dependency is built into the reusable scene.

The local `Y = 0` plane is the felt surface. Inspector colors control the felt,
rail, wood, trim, accents, and ink independently, with instance-local materials.
`get_roll_positions()` returns five suggested die origins in world space.
`get_hold_positions()` returns their matching hold markers, paired by name.
`contains_roll_position(local_point, clearance)` validates placement against the
rounded felt boundary. The scene includes a simple rectangular floor/rail
collision approximation; use the placement helper for rounded-corner clearance.
The existing dice still use presentation animation, not rigid-body simulation.

[debug/table_viewer/table_viewer.tscn](debug/table_viewer/table_viewer.tscn) presents
five dice on the table. **Press a die** to hold it at its matching hold marker;
press it again to return it. Keep the left mouse button or a finger down and sweep
across other dice to toggle them without releasing. A die ignores input while
sliding, and becomes mutable again once it settles; hover and release are inert. Held dice retain their face and show a gold ring.
**Space** or **Roll dice** rolls only available, unheld dice. **Upgrade VFX** previews five real upgrades with permanent colors and particles
only when their rewards apply to the current selection. Guardian contributes while
held; other upgrades contribute when played. The felt buttons compare Mint,
Lavender, and Chalk. See [upgrade presentation](upgrade_presentation/README.md)
for all 14 color/VFX assignments and the reusable mechanics bridge.

```sh
godot --headless --path godot --script res://debug/table_viewer/tests/hold.gd
godot --headless --path godot --script res://debug/table_viewer/tests/sweep.gd
godot --headless --path godot --script res://table/tests/smoke.gd
godot --headless --path godot --script res://debug/table_viewer/tests/smoke.gd
godot --path godot --script res://debug/table_viewer/tests/smoke.gd -- --capture
```

[dice_hold/dice_hold_controller.tscn](dice_hold/dice_hold_controller.tscn) owns
selection and movement separately from the reusable die and table. `return_to_roll(die)`
puts a held die back on its roll marker without a slide, including a consumed one.
`show_highlight = false` hides the gold ring for hosts that mark selection another way. Configure it
with a table and a typed dice array in roll-slot order. The die emits `clicked`
on a press or held-pointer sweep when interaction is enabled; the controller
exposes `is_held()`, `can_mutate()`, `can_roll()`,
`held_count()`, and `changed`. Clicks during rolls or transfers are ignored.
Reduced-motion dice move immediately. This is presentation state, not scoring
or turn logic. Enable viewport physics picking when integrating it elsewhere.

The capture is written to `/tmp/paroli-table.png`. Checks cover independent
materials, transformed placement anchors, rounded bounds, roll controls, felt
palette changes, and the VFX toggle.

## Antialiasing

The live window uses 8× MSAA (`rendering/anti_aliasing/quality/msaa_3d = 3`),
and the die studio's separate SubViewport also uses 8× MSAA. The table capture
helper copies the live window's setting so screenshots reflect runtime quality.
This smooths mesh silhouettes, pip boundaries, and table details without a
full-screen blur pass. Actual sample support depends on the rendering device.

## Upgrade card overlay

Press **Upgrade preview** in the table viewer to open the
[augment overlay](augment_overlay/augment_overlay.tscn) over the live game.
A light, dark translucent backdrop preserves the table beneath it. The only
heading is **Upgrade a die**. Cards retain their upgrade name and description;
cards and overlay controls accept mouse/touch input without keyboard focus.
Each card contains an actual native die in its own
transparent 3D viewport with 8× MSAA and live VFX. The viewer supplies Jackpot, Guardian, and Crescendo from the real effects catalog.
Cards render each definition’s localized name, description, six-face layout, palette,
and VFX.

Landscape uses one row; portrait uses one column. Small windows scroll
vertically. Window stretching is disabled so responsive UI uses window dimensions
instead of shrinking a fixed desktop canvas.

**Inspect deck**, centered below the cards, hides the cards and dimmer and
restores interaction with the table. **Show upgrades** brings the choices back.
There is no cancel or close action: choosing a card completes the offer.

The host-facing signal is `upgrade_selected(upgrade_id: StringName)`. It fires
exactly once when the choice is committed, before animation begins. The overlay
locks all choices and inspection during the selected die's native activation,
then dismisses itself after `ParoliDie.activation_finished`. This signal marks
the entire effect's completion, including particles that outlive the die;
`consumed` still marks disappearance of the die itself.

The overlay does not implement upgrade rules or mutate the table dice. Connect
`upgrade_selected` to host game logic.
A host instances the overlay inside a CanvasLayer and calls
`open(upgrades: Array[UpgradeDefinition], locale: String = "")` after entering
the tree. Supply exactly three non-null definitions for a fresh offer. The method
returns false for invalid input or during activation, leaving the offer unchanged.
The overlay starts hidden and never generates offers or installs upgrades. Use `presentation_changed` or `is_blocking()` to coordinate host
shortcuts. Reopening during a committed animation is ignored.

```sh
godot --headless --path godot --script res://augment_overlay/tests/smoke.gd
godot --path godot --script res://augment_overlay/tests/smoke.gd -- --capture
```

Checks cover five window sizes, real pointer selection, table input during
inspection, single signal emission, repeat-input guards, and complete playback
of all three native activation effects before dismissal. Captures are saved as
`/tmp/paroli-augments-<width>x<height>.png` and
`/tmp/paroli-augments-inspection.png`.

## Mechanics definitions

[mechanics/README.md](mechanics/README.md) documents all 71 effects in
[docs/EFFECTS.md](../docs/EFFECTS.md): 14 upgrades, 29 bonuses, and 28 Jokers.
The readable class-authored catalog uses typed rules, manually authored English/French descriptions, and keyword glossary text. `MechanicsRun` handles recognition, scoring modifiers, history, ownership,
economy, and round allowances independently of rendering. The host supplies random
face indices, base scores, and prices; the presentation viewers are not wired to
this runtime yet.

~~~sh
python godot/mechanics/tests/check_catalog.py
godot --headless --path godot --script res://mechanics/tests/smoke.gd
godot --headless --path godot --script res://mechanics/tests/effects.gd
~~~

## Debug effect catalog

Open [debug/catalog_viewer/catalog_viewer.tscn](debug/catalog_viewer/catalog_viewer.tscn)
and press **F6** to browse every upgrade, bonus, and Joker. Family tabs select the
catalog section; search matches names, stable IDs, and manually authored descriptions.
The English/French switch renders authored text without changing the game's locale.
Upgrade descriptions include all six physical face values. Cards use a responsive
one-to-three-column grid with vertical scrolling, cream surfaces, and plum outlines.
This is a read-only definition browser, independent of the game and upgrade overlay.

```sh
godot --headless --path godot --script res://debug/catalog_viewer/tests/smoke.gd
# With a working display; captures landscape and portrait in /tmp/paroli-catalog-*.png:
godot --path godot --script res://debug/catalog_viewer/tests/smoke.gd -- --capture
```

The catalog's colored terms open localized keyword explanations. Hover to
inspect; click or tap to pin; tap the same term or outside to dismiss.
Reward numbers are read from named effect fields. Player prose and names are
editable in `mechanics/localization/description_catalog.gd` and `game_keywords.gd`.

```sh
godot --headless --path godot --script res://mechanics/tests/descriptions.gd
godot --headless --path godot --script res://keyword_text/tests/smoke.gd
godot --path godot --script res://keyword_text/tests/smoke.gd -- --capture
```

## Score widget

Open [debug/score_viewer/score_viewer.tscn](debug/score_viewer/score_viewer.tscn)
and press **F6**. Trigger a die, bonus, or Joker individually, or **Play chain**
for five dice, two bonuses, and a final Joker impact. Rapid clicks queue every
source. Reset cancels playback; reduced motion preserves source order. The
**Score / target** slider scrubs 0–4× to preview the continuous celebration.
This debug fixture uses a target of 100.

[score_widget/score_widget.tscn](score_widget/score_widget.tscn) displays only
**Points × Mult**. Smoothly rounded, beveled tiles reuse Sky and Cherry keyword palette roles,
plum outlines, and cream highlights. Each changed factor gets anticipation,
rolling digits, squash and spring recoil, a brief brightening, floating numeric
increments, an expanding ring, and outlined pip diamonds. Impact strength lets
hosts emphasize a bonus or Joker. Unchanged factors remain still.

```gdscript
# Previously banked total and round goal (zero goal disables celebration).
score_widget.set_round_context(0.0, 100.0)
score_widget.set_values(10.0, 2.0)
# Supply resolved absolute snapshots in source order, not arithmetic modifiers.
score_widget.trigger(&"die_1", 16.0, 2.0, 0.85)
score_widget.trigger(&"bonus_1", 16.0, 4.0, 1.25)
score_widget.trigger(&"joker_1", 16.0, 6.0, 1.8)
await score_widget.sequence_finished
```

`step_started(source_id)` and `step_finished(source_id)` synchronize external
source VFX. `sequence_finished` fires once after the queue drains; `is_playing()`
reports queued or active playback. `set_values` cancels pending/active visual
steps without emitting completion for cancelled steps. Completed values live in
`points` and `mult`; all scoring rules remain host-owned. Normal hits take 640 ms,
reduced-motion hits take 120 ms. Strength is clamped to 0.5–2. Readouts show up to
two decimals and fit within the tiles. Leave room around the widget for bursts.
Its minimum layout footprint is 320×220 UI units, including animation space.

The [overdrive particle scene](score_widget/overdrive/overdrive.tscn) emits
only rounded gold stars behind the readouts, across 130% of the widget width
with an outward fan. Its presentation ratio
is `(banked_score + max(animated_points × animated_mult, 0)) / target_score`.
Pass the round total **before** the current combination as the banked value;
the effect does not commit or credit any score. `score_ratio` exposes this ratio.
A zero target safely disables the effect. Intensity maps linearly with
`clamp((ratio - 1) / 2, 0, 1)`: off through 1×, half at 2×, capped at 3×.
A frame-rate-independent lerp smooths transitions; particle size, speed, spread,
and opacity follow the same weight. Existing particles finish behind the tiles
as intensity falls. Reset removes stale effects immediately. Reduced motion
replaces moving particles with three static gold glints.


```sh
godot --headless --path godot --script res://score_widget/tests/smoke.gd
godot --path godot --script res://score_widget/tests/smoke.gd -- --capture
```

Checks cover queue ordering, source signals, reset cancellation, isolated
instances, semantic colors, fractional and negative factors, reduced motion,
large-number fit, ratio thresholds, saturation, banked totals, disabled targets,
and desktop/portrait layouts. Captures save resting and impact
frames to `/tmp/paroli-score-{rest,hit}-<width>x<height>.png`.

Ratio captures are `/tmp/paroli-score-ratio-{1,2,3}-<width>x<height>.png`, with
reduced-motion captures at `/tmp/paroli-score-reduced-<width>x<height>.png`.


### Catalog artwork

Bonus and Joker definitions inherit `IllustratedDefinition`. Their `artwork_path()`
resolves `mechanics/definitions/artwork/bonuses/<id>.svg` or
`mechanics/definitions/artwork/jokers/<id>.svg`; `load_artwork()` returns the imported
texture by stable ID, regardless of translated display names. These native project
files are the runtime artwork; the SVG studies in `docs/` remain review originals.

`EffectsCatalog.artwork_errors()` verifies all 57 textures. The catalog viewer pushes
these errors on startup, and `mechanics/tests/check_catalog.py` checks missing SVG
files before import. Artwork verification is separate from pure rule validation,
so synthetic mechanics fixtures do not need placeholder illustrations.

Catalog cards show artwork in the top-right corner. Upgrade cards instead display
an independent, transparent 3D viewport with 8× MSAA, the assigned palette color,
and animated native VFX. Descriptions remain full-width below the header; previews
ignore input so keyword tooltips remain usable.


SVG catalog icons import at 448 px (`svg/scale = 0.875`) with mipmaps enabled.
The artwork control uses linear mipmap filtering. Its 112 px display size matches
an exact mip level (448 → 224 → 112), avoiding both undersampled jagged edges and
soft blending between mismatched mip levels. Keep these `.svg.import` settings
with the artwork when adding or regenerating icons.

## Round interface prototype

Open [debug/round_prototype/round_prototype.tscn](debug/round_prototype/round_prototype.tscn)
and press **F6** to play a full round on the table: five dice, a build, a target,
three plays, and three manual rolls. The project's main scene is unchanged.

The felt has two rows. Dice start on the front **Roll** row. **Press a die** (or
sweep across several) to move it to the back **Play** row: that is the selection
for the next play. **Roll** (Space) rerolls the dice still on the Roll row and
spends a roll; selected dice keep their value. **Play** (Enter) scores the
selection; if the round continues, the played dice reroll for free and re-enter on
the Roll row. Reaching the target ends the round at once; running out of plays ends
the run. The corner **Debug** button cycles three fixture builds (Showcase, Starter,
Bare dice), restarts the run, changes reveal speed, and toggles reduced motion and sound.
It also steps through 15 backdrop color schemes (**B** / **Shift+B**) and five patterns
(**P**), so combinations can be compared with the panel closed.
With **Shop between rounds** on (the default), clearing a round opens the
[shop](#shop-interface-prototype) before the next round; coins and purchases carry over.

The scoreboard stays empty until at least one die is on the Play row. It then shows
only the recognized combination and its base points × Mult (D-023). Selection is
shown by position alone: there is no ring. Dice that form the recognized combination
get the die's shine sweep; extra selected dice do not. Bonuses and Jokers that would
trigger get a butter halo, a lift, a gentle pulse, and the shine sweep, with a soft
pop and tick when they become eligible. Cracks mark a selected die that hurts the play
(a negative effect) or adds nothing to it: outside the combination, and the play would
score and reward at least as much without it. An extra die that still feeds a bonus or a
Joker is left whole. An upgrade's particles show only on a die that is selected **and** whose
reward will apply to that play; rewards earned from the Roll row (Guardian, for
example) stay silent until the reveal. No face points, effect totals, or projected
score appear before the reveal.

Upgraded dice print their permanent face layout on the model. Each die's column
below the table is one hover and tap target: it opens a die sheet with the upgrade
and the bonus. Resting the pointer on the die itself opens the same sheet. A press
or tap pins a sheet or a Joker's explanation until the next press elsewhere.

The reveal resolves one source per beat: member dice left to right, each die's
upgrade and bonus, then Jokers in rack order. Each beat hops the die or punches the
card, pops a colored increment beside it (Sky points, Cherry Mult, Butter coins),
steps the matching tile, and plays a tick one rung higher on a pentatonic ladder.
Beats accelerate and hit harder as the chain grows. Percentages then fold into Mult
once, the total counts up over the tiles, flies to the goal meter, and banks. Played
dice burst with their native activation and roll back in. Clearing the target stamps
the meter, converts unused plays into coins, and shows the result card.

Other feedback: staggered throws with three felt knocks per die and a touch of
camera shake, select/deselect pops pitched per die, hover hops and ticks, idle sway and
hover tilt on cards, and chunky press-down buttons whose pips pop when spent.
Reduced motion keeps order, values, and sound but removes shake, springs, travel,
stagger, and confetti, and freezes the backdrop's drift.

### Structure

[round_interface/round_interface.tscn](round_interface/round_interface.tscn) is the
reusable scene; it works without the debug host.

- `session/`: scene-free round logic. `RoundSession` wraps `MechanicsRun`, samples
  face positions from a seedable generator, supplies D-022 base scores, and mints
  event IDs. `PlayPreview` carries pre-commit facts, `PlayOutcome` a committed play,
  and `ScoreScript` orders an outcome into `ScoreStep` beats with running totals.
- `round_interface.gd`: phases, input, and preview refresh. `score_sequence.gd`:
  the reveal choreography.
- `hud/`: `RoundHud` lays out and exposes the widgets (goal meter, scoreboard, Joker
  rack, die docks, coin chip, action buttons, popups, tooltip, result banner). It
  reports intents and animates host-supplied values; no rules live there.
- `juice/`: `Juice` helpers for punches, hops, and number formatting.
- The table, dice, camera, and wallpaper come from the shared
  [table stage](#table-stage), exposed as `RoundInterface.stage`.
- `audio/`: `RoundAudio` voice pool and the WAV cues.

```gdscript
var run: MechanicsRun = MechanicsRun.new(4)
run.install_upgrade(catalog.upgrade(&"jackpot"))  # Equip between rounds.
var session: RoundSession = RoundSession.new(run, seed)
round_interface.start_round(session, 1, 300.0)
# The banner's action reports the result; the host starts the next round or a new run.
round_interface.continue_requested.connect(_on_continue_requested)
```

`start_round` returns false, changing nothing, while a throw or reveal is playing or
when the session rejects the start. `busy_changed` and `is_busy()` expose the input
lock. `reduced_motion`, `tempo`, `muted`, and `locale` are exported. A host may park the
scene outside the tree (the round prototype does during a shop visit); it lays out again
when it returns.

The HUD scales from a 1280×900 landscape or 540×960 portrait reference and frames
the table in the space it leaves; die docks follow the dice columns on screen.

### Placeholders

- Sound effects are original synthesized studies, generated by
  [synth_sfx.py](../docs/audio_explorations/round_sfx/synth_sfx.py) into
  `round_interface/audio/sfx/`. The WAV files are the runtime source; replace them
  freely. Pitched ticks share a C5 root so chains can climb by `pitch_scale`.
- `RoundSession.coins_per_unused_play`, the fixture targets and their 1.6× growth,
  and fixture sell values are test inputs. The design has not fixed these values.
- Interface copy outside the keyword glossary (Target, Keep, hints, result card) is
  English only.

### Validation

```sh
godot --headless --path godot --script res://round_interface/tests/session.gd
godot --headless --path godot --script res://round_interface/tests/smoke.gd
godot --headless --path godot --script res://debug/round_prototype/tests/smoke.gd
# With a working display; saves /tmp/paroli-round-*.png:
godot --disable-vsync --path godot --script res://round_interface/tests/smoke.gd -- --capture
godot --disable-vsync --path godot --script res://debug/round_prototype/tests/smoke.gd -- --capture
```

The session check covers the preview boundary, reveal order, running totals, and
round completion without any scene. The interface check drives real pointer presses
through the HUD, the reveal lock, banking, the result card, and the portrait layout.
The prototype check cycles every fixture and chains rounds. `--disable-vsync` keeps
captures running when the test window is hidden or occluded.

## Table stage

[table_stage/table_stage.tscn](table_stage/table_stage.tscn) is the 3D set shared by the
round and the shop: wallpaper, framed orthographic camera, table, and the run's five dice
on their roll markers. Instancing it keeps the build looking the same on every screen.
It owns presentation only.

- `frame(rect, viewport)` fits the table into the space a HUD leaves and returns pixels
  per world unit. `columns()`, `project(table_point)`, and `die_rect(die_id)` map the
  table to window pixels for HUD alignment and 2D hit tests.
- `views` maps `die_1`…`die_5` to the native dice; `dice()` returns them in run order.
- `StageCamera` (`camera`) adds trauma shake through lens offsets.
- `backdrop/`: `StageBackdrop`, a wallpaper quad parented to the camera. A
  `BackdropPreset` resource (`backdrop/presets/*.tres`) supplies the glow, edge, and
  pattern colors plus the ink for the few HUD marks drawn straight on the wall; `motif`
  picks the pattern (plain, sparkles, dots, stripes, diamonds) independently. The
  authored default is **Plum night** with **sparkles**; change `backdrop_preset` and
  `backdrop_motif` on the stage to restyle every screen. `backdrop_changed` tells
  interfaces to recolor their wall marks (`wall_ink()`).
- `reduced_motion` settles dice immediately and stops shake and wallpaper drift.

## Shop interface prototype

Open [debug/shop_prototype/shop_prototype.tscn](debug/shop_prototype/shop_prototype.tscn)
and press **F6** to try the shop on its own, or play the round prototype: a cleared
round leads here. The shop uses the same table: stock lies on the felt's back half, the
dice rest in front, and the Joker rack and die columns sit where they do in a round.

Everything in the shop is drag and drop. Pressing an item picks it up: it lifts, the
places it can go light up, and its explanation opens. Dragging carries it; the
destination under the pointer brightens. Releasing it anywhere else sends it back, so a
plain press only inspects.

- **Buy a Joker:** drag it onto the rack.
- **Buy a bonus:** drag it onto a die or its column with a free slot. A die that already
  has a bonus refuses and the item goes back.
- **Lucky dip:** the two `?` tiles sell a random Joker or bonus at a discount. Drag them
  like known goods; the tile turns over to show what was found before it flies home.
- **Move a bonus:** drag an owned bonus onto a die with a free slot.
- **Sell:** drag an owned bonus or Joker onto the purse; a **Sell +N** badge shows its
  value while you hold it. Upgrades cannot be sold.
- **Refresh** restocks the whole shelf for coins; each refresh in a visit costs more.
- **Next round** leaves.

Hovering goods, rack Jokers, a die, or its column explains them; the sign's second line
says where the held item can go. Goods the purse or the build cannot take shake and say
why (not enough coins, no free slot) instead of lifting. Feedback follows the round:
deals, lifts, flights to their new place, counting coins, a hop from the die that
receives a bonus, and matching sounds.

### Rules you can tune

[shop_rules.tres](shop_interface/session/shop_rules.tres) holds every number the design
has left open (D-015). Edit it in the Inspector; both prototypes use it.

| Setting | Default | Meaning |
| --- | ---: | --- |
| `joker_offers` / `bonus_offers` | 2 / 3 | Known goods stocked per shelf |
| `joker_price` / `bonus_price` | 6 / 4 | Known prices, in coins |
| `sell_percent` | 50 | Share of the price paid that selling returns, rounded down |
| `refresh_base_cost` / `refresh_cost_step` | 2 / 1 | First refresh in a visit, and how much each next one adds |
| `random_joker` / `random_bonus` | on / on | Whether each lucky dip is offered |
| `random_discount_percent` | 40 | Lucky dip discount off the known price |

Fixture decisions made so the prototype is playable, all easy to change in
[shop_session.gd](shop_interface/session/shop_session.gd): prices are flat per family;
a shelf never repeats an identity and never offers something owned; a lucky dip draws
from what is neither owned nor on the shelf; sold items can reappear in later stock;
a refresh restocks every slot, bought ones included; the refresh cost resets each visit;
sale value follows the price actually paid, so a discounted item sells for less.
Occupied bonus slots never swap (D-014).

### Structure

[shop_interface/shop_interface.tscn](shop_interface/shop_interface.tscn) is the reusable
scene; it works without the debug host.

- `session/`: scene-free logic. `ShopSession` wraps `MechanicsRun`: stock, prices,
  purchases, placement, moves, sales, and paid refreshes (which feed Roulette). One
  session lives for the whole run so event IDs stay unique; `open()` starts a visit.
  `ShopOffer` is a shelf slot; `ShopRules` is the tunable fixture.
- `shop_interface.gd`: turns HUD intents into session calls and presents the results.
- `hud/`: `ShopHud` (layout, shelf, and the drag-and-drop interaction) and `OfferCard`.
  It reuses the round's tiles, die columns, purse, buttons, tooltip, and sounds.

```gdscript
var shop: ShopSession = ShopSession.new(run, rules)  # Once per run.
shop_interface.open_shop(shop, "Before round 2")     # Each visit; restocks the shelf.
shop_interface.leave_requested.connect(_on_shop_left)
```

`debug/fixtures/run_fixtures.gd` holds the fixture builds both debug hosts share. The
shop host's Debug panel cycles builds, restocks, grants coins, and toggles reduced
motion and sound.

### Validation

```sh
godot --headless --path godot --script res://shop_interface/tests/session.gd
godot --headless --path godot --script res://shop_interface/tests/smoke.gd
godot --headless --path godot --script res://debug/shop_prototype/tests/smoke.gd
# With a working display; saves /tmp/paroli-shop-*.png:
godot --disable-vsync --path godot --script res://shop_interface/tests/smoke.gd -- --capture
godot --disable-vsync --path godot --script res://debug/shop_prototype/tests/smoke.gd -- --capture
```

The session check walks the D-015 cases without any scene. The interface check drives
every path with real pointer input: dragged purchases onto the rack, a column, or the
die itself, moves, sales, both lucky dips, refused and abandoned drops, refresh, and
tablet and phone layouts. The round prototype check covers the round → shop → round loop.
