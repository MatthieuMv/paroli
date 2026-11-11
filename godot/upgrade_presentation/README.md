# Upgrade presentation

Every upgrade keeps its body color even when its reward is inactive. Chalk is
reserved for ordinary dice; the other 14 palette colors are used exactly once.
Ink remains the outline color, and background colors remain UI colors.

| Upgrade | Color | VFX |
| --- | --- | --- |
| All for one | Cherry | Hearts |
| House builder | Cocoa | Ribbons |
| Jackpot | Butter | Starburst |
| Odd master | Pistachio | Flowers |
| Even master | Mint | Petals |
| Rainbow | Bubblegum | Confetti |
| Lone wolf | Periwinkle | Crescents |
| Guardian | Sky | Bubbles |
| Golden touch | Honey | Diamonds |
| Stepping stones | Peach | Feathers |
| Relentless | Tangerine | Fire |
| Crescendo | Lilac | Notes |
| Déjà vu | Lavender | Orbit |
| Alternator | Lagoon | Bolts |

`EffectsCatalog` owns these identifiers. Mechanics never loads visual resources.
`UpgradePresentation.refresh(run, selected_ids, views)` applies identity and
particle visibility through the die's public API. Call it after equipment,
selection, roll, or history changes. Supply an empty selection while rolls or
selection transfers are unsettled. The table viewer's **Upgrade VFX** toggle
provides a five-upgrade sandbox; hold/release dice to inspect eligibility.

`MechanicsRun.preview_active_upgrades()` uses the same combination recognizer
and effect planner as a committed play, without changing history, allowances,
coins, score, or the event ledger. Invalid/unavailable plays return no active
upgrades. Zero-value rewards stay inactive. Bonus and Joker rewards cannot
accidentally activate an upgrade's VFX. Guardian is the intentional exception
to selected-die activation: it contributes while held beside a matching played die.

`ParoliDie.effect_enabled` gates the configured particles and impact ring without
replacing the preset or resetting the die pose. It defaults to true to preserve
standalone art previews. This is separate from `activate()`, which consumes the
die; selecting a die must not consume it. Card/store previews may show VFX freely.

The table sandbox has no play/score controls; the reusable bridge supports real
history from the run coordinator when a gameplay host is connected.

Validation:

```sh
godot --headless --path godot --script res://upgrade_presentation/tests/smoke.gd
godot --headless --path godot --script res://debug/table_viewer/tests/smoke.gd
```
