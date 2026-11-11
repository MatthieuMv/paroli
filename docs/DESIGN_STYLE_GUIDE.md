# Paroli design style guide

This guide records the visual and interaction direction established by the Godot
dice and table viewers. Use it when adding game objects, effects, controls, or
screens. The aim is a warm, playful tabletop with clear silhouettes, readable
dice, and direct, fluid interaction.

The native Godot scenes and resources are the implementation reference.
The art prototype is the historical visual reference; it is not a runtime
dependency. Values described as **current reference** document the approved
viewer. Guidance for future screens is a design constraint, not a claim that
those screens or features already exist.

## Visual priorities

1. Make the die value and its held state immediately readable.
2. Give objects a tactile, toy-like shape through bevels, outlines, and shading.
3. Keep the table calm enough for colorful dice and animated effects to stand out.
4. Use decoration sparingly: seams, stars, glints, and a few purposeful particles.
5. Keep interaction responsive and predictable throughout animation.

Use broad color fields and intentional geometry. Avoid photorealistic textures,
noisy surface detail, metallic realism, neon glow, and heavy full-screen effects.
A new object should look at home beside an existing die before adding its VFX.

## Color

All hex values below are sRGB authoring colors. Lighting changes their rendered
appearance; do not sample a shaded screenshot to replace a palette value.

### Shared neutrals and interface tokens

| Token | Hex | Use |
| --- | --- | --- |
| Ink | `#30223d` | Plum outlines, pips, text, and borders |
| Background | `#eee9e2` | Warm paper-like backdrop |
| Chalk | `#f4eddc` | Cream trim and pale objects |
| Control surface | `#fffaf0` | Resting button fill |
| Control emphasis | `#e7d9ed` | Hover, focus, and pressed fill |
| Butter | `#edcc63` | Hold ring and restrained gold accents |

Use Ink wherever the design needs a dark structural mark. Keep large backgrounds
warm and quiet. Reserve the brighter colors for objects, state, and small accents.
Pure white is available for effect details; it is not the default page surface.

### Object palette

| Name | Hex | Name | Hex | Name | Hex |
| --- | --- | --- | --- | --- | --- |
| Peach | `#f48665` | Butter | `#edcc63` | Mint | `#93b99b` |
| Lavender | `#b7a3d7` | Chalk | `#f4eddc` | Bubblegum | `#f29fbe` |
| Cherry | `#e77984` | Tangerine | `#efa05b` | Honey | `#dcb34e` |
| Pistachio | `#bed17d` | Lagoon | `#68bbb2` | Sky | `#8bbfdf` |
| Periwinkle | `#929cdd` | Lilac | `#c995d2` | Cocoa | `#bc9683` |

The palette supports variation without changing the object's visual language.
Do not assign gameplay meanings to these colors without an explicit game rule.
Communicate selection through position and shape as well as color.

### Effect tones

Effects inherit the die's body and ink colors. Use the existing tone roles:
`base`, `light`, `deep`, `star`, `ink`, and `white`. The current
`light` tone mixes base toward Background by 48%; `deep` mixes base toward Ink
by 28%; `star` mixes base toward Ink by 45%. These mixes happen in linear RGB,
then return to sRGB. The role name `star` does not mean a fixed yellow color.

Preserve those relationships when recoloring an effect. Outlines must not replace
colored fills, and pale inner details must remain visible.

## Shapes, outlines, and materials

Use chunky, simple forms with deliberate bevels. The dice combine broad flat
faces, cut corners, dark silhouettes, and small faceted pips. Carry that vocabulary
into new tabletop objects: generous corners, a clear primary mass, and details
that remain legible at the gameplay camera distance.

The original die proportions provide a reference: edge 2.15 world units, bevel
0.27, one bevel segment, and outline scale 1.065. Pips use radius 0.205 with eight
segments and spacing 0.45. These are die proportions, not universal dimensions
for all objects; the native model resources remain authoritative.

Keep outlines plum and visually consistent at the intended display size.
Use a stronger silhouette for large objects and finer strokes for internal
decoration. Avoid uniform thick borders around every small detail.

Dice and table share fixed, warm toon lighting, with three shading levels based
on the ramp 75 / 175 / 255 and light direction `(-4, 9, 5)`. Reuse the established
shaders so new objects agree about light direction and color response.
Use restrained translucent contact shadows to anchor objects.

The table's current material arrangement is:

| Part | Color / treatment |
| --- | --- |
| Felt | Mint, broad and quiet |
| Beveled rail | Peach |
| Apron and legs | Cocoa |
| Piping and stitches | Chalk |
| Star inlays and small accents | Butter |
| Structural outlines | Ink |

## Camera and composition

Use an orthographic camera for the table. Preserve visible depth with a tilt:
the current reference is 30° away from straight overhead, or 60° down from
horizontal. Keep the table stable in frame, with enough side-face visibility to
show the dice bevels and rail thickness. Avoid returning to a straight top view
or introducing perspective foreshortening without revisiting the art direction.

The current viewer uses camera size 34 with horizontal size preserved. This is
a framing reference, not a fixed requirement for every viewport.

Separate the roll and hold regions spatially. Keep each die's destination stable,
leave room between dice for their silhouettes and effects, and preserve clearance
from the rail. Keep headers and controls outside the active play area.
For other aspect ratios, adjust framing and layout to preserve this hierarchy.

## Interface and typography

Use a clean, readable sans-serif with plum text on pale surfaces. The current
viewer uses Godot's default font; no custom brand typeface has been selected.

Current reference sizes and spacing, in Godot UI units:

| Element | Reference |
| --- | --- |
| Main title | 32 |
| Small uppercase eyebrow | 13, spaced lettering |
| Instruction text | 15 |
| Default labels and buttons | 16 |
| Outer horizontal margin | 36 |
| Outer top/bottom margin | 28 |
| Button padding | 12 horizontal, 9 vertical |
| Button corner radius | 9 |
| Button border | 1 resting/hover; 2 focused/pressed |
| Button gaps | 10 horizontal, 8 vertical |
| Footer row gap | 14 |

Use short action labels and a brief instruction near the play area. Titles may
carry a little personality; controls should describe their action plainly.
Keep decorative uppercase lettering to small eyebrows.

Buttons have cream fills, plum borders, rounded corners, and pale lavender
emphasis. Preserve a visible focus state. For future screens, make disabled
controls distinguishable and keep text readable at the actual target size.
Adapt spacing and touch targets to the device rather than shrinking the entire
desktop layout.

## Motion and direct interaction

Motion explains state changes. Use a short roll with a clear landing, and a
smooth floor-level slide between roll and hold positions. Keep the camera still
during these actions.

| Action | Current reference |
| --- | --- |
| Roll | 620 ms presentation animation |
| Hold / unhold transfer | 280 ms, cubic ease-in-out |
| Reduced-motion transfer | Immediate placement |

Preserve these input rules:

- A primary mouse press or touch press toggles a settled die.
- Holding the button or finger down and sweeping across another eligible die
  toggles it without requiring a release.
- A die is immutable while transferring between positions. Ignore further
  requests during that transfer; do not queue them or reverse the motion.
- Once settled, that die can be toggled again within the same gesture.
- Rolling and consumed dice are also ineligible.
- Passive hover, release, and right-click do not toggle a die.
- Held dice retain their value and are excluded from subsequent rolls.
- A held die moves to its paired hold marker and displays a Butter ring.
  Unholding returns it to its paired roll marker and removes the ring.
- Disable rolling when no die is available to roll.

The ring, destination, and held count reinforce the same state. Keep feedback
consistent with the input immediately, while the slide completes. Do not require
players to wait for one die before interacting with another eligible die.

Respect reduced motion: preserve the final state and useful feedback while
removing travel and unnecessary animated effects. Future interfaces should
provide an accessible alternative to pointer-only die selection.

## VFX, shine, and cracks

Use graphic silhouettes that share the toy-like world: stylized flames, bolts,
stars, petals, bubbles, ribbons, and similarly simple shapes. Give each effect a
recognizable silhouette before increasing particle count.

Keep the die's value readable throughout an effect. Preserve the existing
top-face protection and test from the gameplay camera as well as the die viewer.
Place effects around the die without turning its face into a wall of particles.

Treat outline, fill, and inner detail as distinct layers. Preserve authored depth
offsets and transparent sorting so the ink outline sits behind the intended fill
and the inner highlight remains visible. Fire, bolts, and starbursts are useful
regression examples because incorrect ordering can turn them into dark blobs.

Shine is a controlled warm highlight sweep with small glints. Cracks are fine,
branching ink marks that develop across the surface. Both should remain readable
alongside the pips without overwhelming them. Test combined finishes and VFX,
not just each effect alone.

## Upgrade choice overlays

Present choices over the live table with a subtle dark translucent dimmer.
Keep the game visible beneath it; do not wash it out with a white overlay.
Use cream cards, plum borders, rounded corners, and a small offset shadow.
Each card presents a real 3D die with live palette-colored VFX, using the same
native die scene as the game. Do not substitute a static die illustration.

Use the heading **Upgrade a die** above the cards. Keep each upgrade’s name and
concise description beside or below its live die preview. Upgrade cards and
overlay controls use mouse/touch input only, without keyboard focus or focus borders. Keep **Inspect deck**
centered below them. Omit decorative categories, marketing copy, status text,
and cancel/close controls. The player completes the offer by choosing a card.

Arrange choices in a row when width is at least height, and in a column in
portrait. Allow vertical scrolling in constrained windows. Inspection removes
both the cards and dimmer, returning input to the live table; **Show upgrades**
restores the choices.

On selection, emit the chosen upgrade ID once for game logic, lock further
choices, and activate the selected preview die's VFX. Dismiss the overlay only
after the entire animation, including trailing particles, has finished.
The overlay owns presentation and input guards; applying upgrade rules remains
the host game's responsibility.

## Rendering quality and implementation references

Keep mesh silhouettes, pips, seams, and fine cracks smooth. The current reference
uses 8× MSAA in the main viewport and the die viewer's SubViewport. Match capture
settings to the live viewer. Avoid using full-screen blur to disguise jagged
edges. Shader-drawn fine lines also need appropriate edge smoothing.

Use native scene and resource files for authored geometry, materials, themes,
and effects. Keep mutable materials local to each instance so recoloring one die
does not change another. Coding conventions are documented separately.

| Reference | Purpose |
| --- | --- |
| [Game colors](../godot/game_colors/game_colors.gd) | Shared palette constants and display order |
| [Die catalog](../godot/die/catalog.tres) | Native model, mesh, and effect definitions |
| [Die scene](../godot/die/die.tscn) | Model, finishes, VFX, and hold highlight |
| [Die library](../godot/die/die_library.gd) | Palette tone relationships |
| [Table scene](../godot/table/table.tscn) | Geometry and authored position markers |
| [Table viewer](../godot/debug/table_viewer/table_viewer.tscn) | Camera, composition, and UI layout |
| [Viewer theme](../godot/debug/table_viewer/table_viewer_theme.tres) | Current control tokens |
| [Hold controller](../godot/dice_hold/dice_hold_controller.gd) | Transfer timing and eligibility rules |
| [Godot README](../godot/README.md) | Running viewers and validation commands |
| [Godot conventions](../godot/AGENTS.md) | Code style and module ownership |

## Review checklist

Before accepting a visual or interaction change:

- Compare it beside existing dice on the table at gameplay scale.
- Check both pale and darker palette variants.
- Confirm pips, outlines, and held state remain readable with VFX enabled.
- Inspect fire, bolt, and starburst fills and depth order after material changes.
- Check silhouette edges, seams, and cracks for aliasing at the target resolution.
- Sweep across several dice with mouse and touch; confirm no transfer can reverse
  mid-slide and no release toggles an object.
- Confirm held dice retain their value when other dice roll.
- Check reduced motion, focus visibility, and control readability.
- Keep new resources and this guide consistent when intentionally changing a token.

## Effect copy and keyword colors

Lead with the reward and its condition. Use **play / played** in English and
**coup / joué** in French. Omit repeated explanations such as “each die counts
once.” Retain conditions that change decisions, such as held versus played,
combination membership, and when a growing bonus resets. Prefer one short
sentence per tooltip; use a compact example only when it clarifies the rule.

Keywords use lightly emboldened text and color instead of underlining. Their tooltip titles use the same
color. The text itself remains the identifier, so color is not the only cue.

| Meaning | Existing palette source |
| --- | --- |
| Points | Sky |
| Mult / Multi | Cherry |
| Combinations and Jokers | Lavender |
| Coins and shop refresh | Honey |
| Played and held dice | Lagoon |
| Rerolls and rounds | Tangerine |

For cream UI surfaces, mix these colors 50% toward Ink for readable text.
`godot/keyword_text/keyword_colors.gd` owns this mapping and references the shared
`GameColors` constants in `godot/game_colors/game_colors.gd`. Hover/tap explanations
keep the existing pinning, outside-dismissal, and above/below placement behavior.
