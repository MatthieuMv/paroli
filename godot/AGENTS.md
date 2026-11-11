# Paroli Godot conventions

These conventions follow the feature-owned scene organization and typed,
comment-heavy GDScript used in `ChaosTactics/Godot`. Apply them to handwritten
code, tests, and code emitted by generators.

## Module and scene ownership

- Organize by feature: `game_colors/` owns shared color constants and palette order;
  `die/` owns the reusable die, `table/` owns the rolling
  table, `dice_hold/` owns selection and marker transfers,
  `augment_overlay/` owns upgrade card presentation; mechanics/ owns immutable rules, localized
  descriptions, pure command planning, and the isolated run coordinator; and `debug/` contains their separate development viewers. Keep a scene, script, shaders, resources, and tests with the feature that owns them. Do not introduce root
  `scripts/`, `assets/`, `shaders/`, or `scenes/` buckets.
- Author stable node hierarchies, layout, themes, and resources in `.tscn` and
  `.tres` files. Use typed `@onready` references to those nodes. Generate nodes
  only for genuinely data-dependent content (palette choices and particle instances), with clear lifetime ownership.
- A reusable scene must work without its debug viewer. Dependencies flow from
  the viewer to the die's public API; the die must never import debug code.
- Communicate across modules through typed methods, properties, and signals.
  Never reach through another module's private members or child paths.
  Feature-local white-box tests may inspect their own feature's internals.
- Author gameplay definitions in readable GDScript using named rule classes and
  typed constructors, following ChaosTactics. Do not serialize content logic into
  hand-wired resource graphs. Visual scene/material authoring remains native.
- Mechanics definitions must not reference scene nodes or visual modules. Keep
  per-run state out of shared Resources. Author player descriptions as complete localized
  sentences with keyword links and named numeric bindings; keep rule-tree descriptions
  as diagnostics. The keyword_text/ feature owns hover/touch glossary presentation.
- Keep presentation state separate from future gameplay rules. Rendering and
  VFX must not pick authoritative game outcomes.

## GDScript style

- Use `extends`, then `class_name` (after `@tool` when applicable).
- Type every constant, member, local, parameter, return value, loop variable,
  and lambda explicitly. Use `var value: float = ...`, not `:=` or an untyped
  declaration. Property setter arguments inherit the declared property type.
- Use typed arrays and dictionaries; do not introduce untyped JSON or Variant
  containers for native visual definitions.
  Godot's heterogeneous mesh-buffer `Array` is a documented API exception;
  immediately convert its elements to packed types.
- Do not hide missing types with dynamic `call()`, `get()`, or `set()` against
  scene objects, or suppress unsafe-access warnings to bypass contracts.
- Use PascalCase classes, snake_case methods/variables, UPPER_CASE constants,
  and `_` prefixes for private state/helpers. Keep public APIs small.
- Use the existing section headings: `# --- Types ---`, `# --- Signals ---`,
  `# --- Constants ---`, `# --- Member variables ---`,
  `# --- Static functions ---`, and `# --- Member functions ---` as relevant.
- Add `##` documentation for classes, members, constants, signals, and methods.
  Explain ownership, units, timing, invariants, and non-obvious intent. Add
  ordinary comments within algorithms to explain significant phases and math.
- Use tabs, space operators and comma-separated arguments, and expand compound
  one-line statements. Split long orchestration methods into named phases.
- Shared geometry is immutable. Materials, clocks, captured poses, and mutable
  buffers belong to individual scene instances.

## Native resources and validation

- Visual native `.tscn` and `.tres` resources are the source of truth. Edit model/effect
  scenes and typed catalog/preset resources directly. There is no art-prototype
  importer or runtime JSON reconstruction step. Preserve material
  `resource_local_to_scene` and transparent billboard origin sorting.
- Move existing `.uid` files with their resources; let Godot create new UIDs.
  Do not edit UID contents or third-party attribution by hand.
- Run `python godot/check_style.py` and both feature smoke checks documented
  in `godot/README.md`. The project treats untyped/inferred declaration warnings
  as errors. For rendering changes, also run the viewer capture check with a
  working display and inspect the image.
- Keep unrelated working-tree changes intact.
