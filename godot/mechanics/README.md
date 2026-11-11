# Authoring mechanics

Write gameplay content as typed GDScript classes and constructors, following
ChaosTactics' TriggerSimulation/EffectSimulation pattern. No serialized resource
graph, subresource IDs, JSON, or import step is needed.

[effects_catalog.gd](definitions/effects_catalog.gd) is the playable content catalog:
**14 upgrades, 29 bonuses, and 28 Jokers**, covering all 71 entries in
[docs/EFFECTS.md](../../docs/EFFECTS.md). That document supersedes the older upgrade
proposals. Definitions use explicit named constructors; no generation step is needed.
The `examples/` directory contains smaller authoring fixtures.

## An entire upgrade

~~~gdscript
var odd_master: UpgradeDefinition = UpgradeDefinition.new(
	&"odd_master",
	[1, 1, 3, 3, 5, 5],
	[
		EffectDefinition.OnValidated.new(&"odd_validated",
			null,
			[ScoreAction.MultPercentPerDie.new(20, DieQuery.Validated.new(DieQuery.Parity.ODD))]
		),
	],
	&"Lavender", &"crescents"
)
~~~

Read it in order: identity, physical faces, when the effect runs, the condition,
what it does, then optional palette/VFX IDs.

A bonus or Joker uses the same effect classes:

~~~gdscript
var straight: JokerDefinition = JokerDefinition.new(
	&"example_straight_joker",
	[
		EffectDefinition.OnValidation.new(&"straight_points",
			Conditions.Combination.new([&"short_straight", &"long_straight"]),
			[ScoreAction.Points.new(20)]
		),
	]
)
~~~

The Joker above is a synthetic authoring example. For actual content, use
`EffectsCatalog.new().upgrade(&"odd_master")`, `.bonus(...)`, or `.joker(...)`.
Catalog names are localized keywords; player descriptions are manually authored in English and French.

## Readable rule vocabulary

| What to express | Classes |
| --- | --- |
| When | EffectDefinition.OnValidation, OnHeld, OnReleased, OnRoll, OnInstalled, OnRoundStart, OnRoundEnd, OnRunStart |
| Owning die state | Conditions.Held, NotHeld, Validated, NotValidated, Member, Odd, Even |
| Face value | Conditions.Showing.new(6) |
| Recognized category | Conditions.Combination.new([...]) |
| Event originated from this die | Conditions.ThisDieTriggered |
| Boolean composition | Conditions.All, Any, Not |
| Count condition | Conditions.Exactly, AtLeast |
| Targets/counting | DieQuery.ThisDie, EventDie, AllDice, Validated, Held, Members |
| Score changes | ScoreAction.Points, Mult, MultPercent, PointsPerDie, MultPerDie, MultPercentPerDie, Calculated |
| Validated-owner default | EffectDefinition.OnValidated |
| History and special predicates | ValidationConditions.FirstInstinct, SameDieValue, DifferentDieValue, PreviousCombination, StraightEndpoint, Neighbours |
| History and distinct-value amounts | HistoryAmount.ManualRerolls, Crescendo, DistinctValues, Portfolio, AccumulatedMult |
| Support and matching counts | DieQuery.OtherMatching, HeldMatching, Excluded |
| Economy and allowances | RuntimeAction.Coins, CoinsFromDie, SellValue, AccumulateMult, Validations, Rerolls |
| Recognition and shop events | EffectDefinition.BeforeRecognition, OnShopRefresh; RuntimeAction.MissingLink |
| Replace physical faces | ReplaceFacesAction.new([1, 1, 1, 6, 6, 6]) |

A null condition means unconditional for that event.
Flat and per-die score constructors accept signed integers.

Held and not-held rules are explicit:

~~~gdscript
EffectDefinition.OnValidation.new(&"held_one",
	Conditions.All.new([
		Conditions.Held.new(),
		Conditions.NotValidated.new(),
		Conditions.Showing.new(1),
	]),
	[ScoreAction.Mult.new(6)]
)
~~~

This differs from a hold-event effect:

~~~gdscript
EffectDefinition.OnHeld.new(&"hold_reward",
	Conditions.ThisDieTriggered.new(),
	[ScoreAction.Points.new(5)]
)
~~~

The first triggers during a validation while the owner remains held.
The second triggers when the owner itself causes a hold event.
OnHeld alone means an event in which **a die** was held; its origin restriction
is explicit and therefore usable for global Joker rules too.

Constructor-created rules are the actual evaluable objects, not strings parsed
by a DSL or a separate representation requiring regeneration. Validation and
diagnostic rule descriptions operate on those same objects. Player prose uses separate reviewed templates.

## Player descriptions and keyword tooltips

[description_catalog.gd](localization/description_catalog.gd) owns complete English
and French sentences for all 71 entries. Edit and review the prose whenever a rule
changes structurally. Gameplay never parses descriptions. The old per-rule
`describe()` methods remain useful diagnostics for authoring fixtures.

Player-facing text uses **play / played** and **coup / joué**. Stable internal
`validation` / `validated` identifiers are unchanged. Keep card copy reward-first;
keep tooltip explanations to one short sentence wherever possible.

Two explicit placeholder forms connect prose to data:

- `{kw:mult}` inserts the translated keyword label and a tooltip link.
- `{kw:validated|joués}` uses an authored grammatical form while retaining the
  same semantic tooltip target. French and English can order and inflect freely.
- `{n:reward:constant}` reads the amount of the single action in the named `reward`
  effect. `per_die` reads its counting scale; `coefficient` reads a history formula
  scale; `step` reads Crescendo's shared stack increment. Bindings never use array
  indices. Invalid/missing effect IDs or incompatible fields fail validation.

Reward numbers stay tied to gameplay. Thresholds, examples, plurals, and explanatory
prose still require editorial review when behavior or balance changes. Do not
assume a structurally valid translation is necessarily accurate or understandable.

```gdscript
var definition: UpgradeDefinition = EffectsCatalog.new().upgrade(&"guardian")
var words: KeywordCatalog = GameKeywords.new()
assert(definition.description.validate(definition, words).is_empty())
print(definition.describe(words, "fr")) # Plain copy for search/accessibility.
print(definition.describe_rich(words, "fr")) # Controlled BBCode keyword links.
```

[game_keywords.gd](localization/game_keywords.gd) owns translated names, terminology,
and full tooltip explanations. Every linked keyword requires an explanation in
both locales. Shared scoring rules live in the glossary instead of repeating on
all cards. Descriptions and keywords fall back from regional locale to language,
then English. Explicit locale rendering does not change the global game locale.

[keyword_text.tscn](../keyword_text/keyword_text.tscn) is the reusable presentation
component. Call `configure(rich, plain, words, locale)` after adding it to the tree.
It highlights colored terms and shows an explanation on hover. Click/tap pins
it; tapping the same keyword or pressing outside dismisses it.
Dragging scrolls without opening a tooltip. Its popup uses an unclipped canvas
layer, stays within the viewport, and is destroyed with the owning label. The
catalog viewer integrates this component; the synthetic augment preview remains
independent of the real mechanics catalog.

Validation checks mandatory EN/FR copy, semantic placeholder parity, keyword
explanations, live bindings, locale fallback, literal BBCode escaping, and catalog
coverage. UI tests exercise native link hit testing, actual touch taps, dismissal,
and viewport bounds. Human review remains necessary for meaning and readability.

## Runtime boundary

The authoring layer does not depend on ParoliDie, UI nodes, physics, or randomness.
Use an EffectContext containing the committed event and logical DieSnapshots:

~~~gdscript
var die: DieSnapshot = DieSnapshot.new(&"die_1", 3)
die.validated = true

var context: EffectContext = EffectContext.new()
context.event_id = &"validation_001"
context.event = &"validation"
context.source_die_id = die.id
context.dice = [die]

var result: EffectResolution = EffectResolver.resolve(odd_master, context)
assert(result.errors.is_empty())
~~~

The result contains typed ScoreDeltaCommand, RuntimeDeltaCommand, or
ReplaceFacesCommand objects. Evaluation does not mutate the game. New command
payloads can be introduced as EffectCommand subclasses without modifying a
generic property dictionary.

Important contracts:

- Definitions are immutable by convention. Resource objects are technically
  writable; per-run counters and ownership must live outside them. Construct a
  fresh example catalog when independent instances are needed.
- Die-bound upgrades/bonuses require a source die. Jokers require no source die.
- Held, validated, and combination-member flags are distinct. Validated dice
  outside a recognized combination may still trigger effects.
- Every physical die has one identity. Repeated face values never duplicate it.
- Every action reads the same pre-application snapshot. Commands do not alter
  later conditions or amounts in the same resolution.
- Add flat Mult first, then sum percentage increases: `final_mult =
  flat_mult * (1 + percent / 100)`. Two +100% effects give ×3. Credit
  `max(0, points * final_mult)` without rounding away fractional scores.
- The host applies each activation once per event/definition/owner/effect tuple.
  The stateless resolver deliberately does not track duplicate application.
- Face replacement is a request. The host enforces permanent-upgrade protections
  and conflicts. Installing UpgradeDefinition.faces is an inventory operation.
- Faces contain six positive numeric positions. The current renderer supports
  values 1–6; other values require a rendering extension.

## Extending the vocabulary

For a common new rule, introduce a named class with a typed constructor, like
Conditions.Held or ScoreAction.Mult. Keep its meaning apparent at the call site.

A genuinely new mechanic may require a concrete EffectCondition/EffectAction
with evaluation, description, local validation, dependencies, and keyword IDs,
plus a typed command and host reducer support. No central evaluator switch or
changes to all three build-definition types are required.

The lower-level DieQuery, EffectAmount, ConditionGroup, and other base resources
remain available for implementing those classes. They are implementation tools,
not the primary content-authoring workflow.

## Coordinating a run

[MechanicsRun](runtime/mechanics_run.gd) owns five logical dice, equipped content,
coins, allowances, round progress, and history. It has no scene dependency.
[OwnedDefinition](runtime/owned_definition.gd) stores persistent Joker growth;
[RunDie](runtime/run_die.gd) stores round-local history separately from definitions.

```gdscript
var catalog: EffectsCatalog = EffectsCatalog.new()
var run: MechanicsRun = MechanicsRun.new(20)
assert(run.install_upgrade(catalog.upgrade(&"rainbow")).is_empty())
assert(run.equip_bonus(catalog.bonus(&"unique"), &"die_1", 3).is_empty())
assert(run.add_joker(catalog.joker(&"variety_show"), 5).is_empty())
var started: MechanicsEventResult = run.start_round(&"round_1", 1000.0)
assert(started.errors.is_empty())
var faces: Dictionary[StringName, int] = {
    &"die_1": 0, &"die_2": 1, &"die_3": 2, &"die_4": 3, &"die_5": 4,
}
var rolled: MechanicsEventResult = run.roll(&"opening_1", faces, EffectContext.RollKind.OPENING)
assert(rolled.errors.is_empty())
var selected: Array[StringName] = [&"die_1", &"die_2", &"die_3"]
var combination: CombinationRecognizer.Result = run.preview_combination(selected)
# The host looks up base scoring for combination.category; these numbers are illustrative.
var scored: MechanicsEventResult = run.validate_dice(&"validation_1", selected, 10, 1)
assert(scored.errors.is_empty())
```

The host supplies **physical face indices 0–5**, preserving repeated-face odds.
Random sampling, base category scores, shop offers/prices, and visual animation
remain host responsibilities. The existing table/overlay are presentation previews;
they are not wired to this coordinator yet.

Runtime contracts:

- Use a unique event ID across the entire run for each committed action. Retrying
  an ID returns its prior result without awarding or charging again. Treat returned
  results as read-only. Rejected actions do not consume IDs.
- Open each round with all five dice. Manual batches spend one reroll and update
  only rolled dice's histories. After a non-final validation, automatically reroll
  exactly its validated dice before the next action. Opening, automatic, and cosmetic
  rolls do not build manual-reroll history; cosmetic rolls do not alter logical dice.
- During validation, unselected dice are held. Validated dice and recognized
  members are distinct sets. Membership is selected by category precedence,
  then highest member sum, then earliest permanent run positions, never effect payout.
  Precedence is explicit in `CombinationRecognizer.CATEGORIES`.
- Missing Link changes recognition before effects run. All scoring/economy effects
  then read the same snapshot. Commit rewards and update histories afterward.
- Crescendo includes its newly earned stack in the current validation. Alternator,
  Déjà vu, and Echo compare the die's own previous validation. Habit/Variety compare
  the previous global category. Round start resets all such history.
- Target success ends the round immediately. Exhausting validations without reaching
  it ends the run. Successful completion pays Stonks growth once, including an
  explicit host `finish_round()` for externally completed rounds/bosses.
- Equip, move, and sell between rounds. Upgrades occupy the next ordinary die and
  cannot be sold. Bonuses have one slot per die; Jokers have four total. Bonuses
  and Jokers are unique while owned. Moving a bonus does not change faces.
- `paid_refresh(id, cost)` charges the explicit cost and grows Roulette once.
  Sale pays current value and discards instance growth. Nest Egg reads all owned
  Joker sell values, including itself. Allowance Jokers apply at round start only.
- The coordinator implements the command vocabulary used by the catalog. New action
  types need an explicit commit policy; low-level ReplaceFacesCommand remains a
  host operation, while installing an upgrade copies its permanent faces directly.

## Validation

~~~sh
python godot/check_style.py
python godot/mechanics/tests/check_catalog.py
godot --headless --path godot --editor --quit
godot --headless --path godot --script res://mechanics/tests/smoke.gd
godot --headless --path godot --script res://mechanics/tests/effects.gd
godot --headless --path godot --script res://mechanics/tests/descriptions.gd
godot --headless --path godot --script res://keyword_text/tests/smoke.gd
~~~

Checks cover the class-authored examples, constructor isolation, source/event
distinctions, held and validated conditions, membership, count-scaled and negative
amounts, boolean composition, face commands, provenance, invalid/cyclic graphs,
translation fallback, placeholders, and word order. Check for script errors as
well as PASS: Godot may report errors without a nonzero process exit.

The effects suite exercises every catalog entry, eligibility boundaries, distinct
values, held support, history reset, combination ties, Missing Link, additive
percentages, economy, event retries, ownership limits, and English/French rule
text. The Python catalog check compares documented names, families, and face
layouts directly against the class-authored catalog to catch additions or drift.
