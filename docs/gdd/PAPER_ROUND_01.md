# Paper round 01 — All or nothing

- Date: 2026-11-01.
- Author: Codex; design owner/reviewer: project creator.
- Type: Scripted designer walkthrough with arithmetic verification, not a player playtest, random simulation, or proof of balance.
- Scope: One regular round, from its free opening roll through success and symbolic settlement; counterfactual and boundary cases below.
- References: [Working GDD](../GAME_DESIGN_DOCUMENT.md), especially D-005, D-006, D-007, D-009, D-012, D-019, D-021, and D-022.

## Question and checks defined for the exercise

Can a starting die upgrade influence a meaningful validation/reroll choice while the accepted scoring, retention, allowance, and settlement rules yield an unambiguous result?

Checks: (1) only manual rerolls spend reroll uses; (2) face points count only recognized-combination members; (3) a validated upgraded die outside the combination can trigger an unqualified effect; (4) held dice remain unchanged by validation; (5) the target immediately ends play; (6) unused validations determine the symbolic coin reward; (7) a negative displayed outcome preserves prior round score. Report missing rules instead of treating fixture assumptions as accepted design.

## Fixture assumptions — not new game decisions

| Input | Test value and reason |
| --- | --- |
| Round | First regular round of biome 1, after the accepted opening upgrade/reveal sequence. Upgrade-offer generation and the future boss's rule are outside this regular-round exercise. |
| Dice | Five persistent dice, named D1–D5 for traceability. D2–D5 use ordinary 1–6 faces, subsequently confirmed by D-024 along with equal face probabilities and independent rolls. |
| Starting upgrade | All or nothing on D1, as if selected from its opening offer. Faces: 1, 1, 1, 6, 6, 6, as proposed by the creator. |
| Test effect amount | X = 3 Mult, assistant-selected only to expose both a useful positive effect and a negative Pair result. Validating D1 on 1 adds +3 Mult; on 6 adds −3 Mult (signs revised by the creator after the initial walkthrough). Held D1 does not trigger. No combination-membership requirement is added to its wording. |
| Other effects | No die bonuses or Jokers in this fixture; this does not settle starting inventory rules. |
| Target | 300 points, assistant-selected to require more than the first scripted 90-point validation and permit the later 245-point payoff. Not a proposed final opening target or evidence of appropriate difficulty. |
| Allowances | Accepted provisional baseline: 3 validations and 3 manual rerolls. |
| Base values | Accepted provisional D-022 values; only Pair (10 points, 2 Mult) and Three of a kind (20 points, 4 Mult) occur on the main path. |
| Roll outcomes | Authored explicitly below, all possible on the stated face lists. No random draw was performed; no probability or optimal-strategy claim follows. D1’s scripted 1/6 outcomes were reversed to retain the same decision sequence after the creator reversed the upgrade signs. |
| Selection | Named nonempty subsets are assumed legal for this fixture, consistent with prior examples; full selection/invalid-input specification remains open. |
| Coins | Let F(u) denote the still-undefined unused-validation coin conversion for u unused validations. No exchange rate or other round income is invented. |

## Main path

Counters below are remaining uses after each step. Values are always in D1, D2, D3, D4, D5 order.

| Step | Action and outcome | Dice afterward | Validations | Manual rerolls | Round score |
| --- | --- | --- | ---: | ---: | ---: |
| 0 | Free opening roll | 6, 4, 4, 2, 5 | 3 | 3 | 0 |
| 1 | Manually reroll D1; it lands on 1 | 1, 4, 4, 2, 5 | 3 | 2 | 0 |
| 2 | Validate D1, D2, D3: 1, 4, 4. Pair scores 90. | Values immediately after scoring: 1, 4, 4, 2, 5 | 2 | 2 | 90 |
| 3 | Automatic free reroll of D1, D2, D3 produces 6, 5, 3; D4 and D5 stay held | 6, 5, 3, 2, 5 | 2 | 2 | 90 |
| 4 | Manually reroll D1 and D3 together; results are 1 and 5 | 1, 5, 5, 2, 5 | 2 | 1 | 90 |
| 5 | Validate D1, D2, D3, D5: 1, 5, 5, 5. Three of a kind scores 245. | Terminal scoring values: 1, 5, 5, 2, 5 | 1 | 1 | 335 |
| 6 | Target reached: round ends immediately and settles | No further player action | 1 converted | 1 discarded | 335 |

The winning validation's terminal automatic-reroll presentation/RNG handling is not invented here; those implementation details remain unresolved. They cannot reopen play or change the completed validation's score. D4 was held throughout both validations. The next phase is the shop, as this is a regular round.

### First validation: 1, 4, 4

- Recognized category: Pair; participating dice: D2 and D3 (4, 4).
- Points = 10 base + 4 + 4 = 18. D1's 1 adds no automatic face points.
- Mult = 2 base + 3 from validated D1's upgrade = 5.
- Raw score = 18 × 5 = 90; credited score = 90.
- Remaining validations = 2. The automatic reroll does not spend a manual reroll.

Holding D1 instead and validating just the two 4s would score 18 × 2 = 36. It would preserve the known 1 for a later validation. Validating D1 now gains 54 points but sends it into the automatic reroll, exposing the build to its negative face again. This is an observed tradeoff in the fixture, not a claim that either choice is optimal.

### Second validation: 1, 5, 5, 5

- Recognized category: Three of a kind; participating dice: D2, D3, D5 (5, 5, 5).
- Points = 20 base + 5 + 5 + 5 = 35. D1 again contributes no face points.
- Mult = 4 base + 3 from validated D1 = 7.
- Raw score = 35 × 7 = 245; credited score = 245.
- Round total = 90 + 245 = 335, exceeding target 300. Stop immediately.
- One validation remains, so this reward source contributes F(1) coins. The unused manual reroll gives no reward. Other income is not specified.
- If the run reaches the next regular round with no allowance changes from the shop, its initial score is 0 and its action allowances are 3/3. The 35 points above target do not carry over.

## Counterfactual and boundary checks

These are separate fixtures, not extra actions after the successful main path.

| Case | Calculation/state | Expected result |
| --- | --- | --- |
| Bad upgrade face after step 3 | Validate D1, D2, D5 = 6, 5, 5. Pair points = 10 + 10 = 20; Mult = 2 − 3 = −1. | Display −20; credit 0; prior round score stays 90. A validation is consumed, leaving 1. |
| Exclude that bad die instead | From the same step-3 state, validate D2 and D5 only. | Pair scores 20 × 2 = 40. Held D1 contributes no penalty. |
| Zero manual rerolls | A legal validation resolves while reroll counter is 0 and play continues. | Its automatic reroll still occurs; reroll counter stays 0. |
| Last-validation target exceeded | Start at score 90, target 300, with 1 validation. A fixture validation of four 6s with no upgrade modifier has (50 + 24) × 7 = 518, exceeding target. | Success takes precedence over exhaustion; no unused-validation coins. This is an isolated arithmetic fixture, not the All or nothing main path. |
| Last-validation failure | Start at score 90, target 300, with 1 validation. Validate a Pair of 5s without an active upgrade modifier for 40 points. | Total 130; run ends and build is lost. No next shop. |

The final-success case tests at-or-above-target precedence; exact equality is covered separately by arithmetic: prior 210 + credited 90 = target 300, with the last validation consumed, succeeds. No early stopping is assumed inside a partially calculated validation.

## Findings and limits

Observed rule checks: all seven checks above can be satisfied using accepted rules plus the disclosed fixture inputs. Arithmetic was checked with Python. This is preliminary consistency evidence for these cases only; it does not validate difficulty, probability, session pacing, or player comprehension.

The main decision exposed is whether to cash in a known upgraded 1 now or hold it for a later combination. Using it now gives a larger score, but automatic rerolling removes certainty. At the bad-face state, selecting fewer dice avoids the negative effect; alternatively the player can spend a reroll opportunity to pursue a stronger outcome. This provides a concrete candidate for the intended anticipation/risk experience, pending player feedback.

The scripted rerolls deliberately improve the build and end in success. They say nothing about how often these choices succeed. In particular, target 300 and X = 3 are demonstration inputs, not balance recommendations.

Not tested: bonus stacking/movement, held-bonus effects, Jokers, boss restrictions, shop generation or purchase flow, offer quality, coin values, detailed recognition ties, and non-scoring effect timing. A full opening-upgrade selection was not simulated; only the chosen upgrade's in-round behavior was exercised.

## Next review

- Creator feedback: the three responses to a risky die—reroll it, exclude it from validation, or include it for its combination contribution despite the penalty—match the intended decision space. Next assess when each is useful; this feedback is not evidence that the choices are balanced.
- Then compare an unfavorable roll sequence with the same target and upgrade values, and a second upgrade style, before tuning opening targets or accepting X = 3.
- Before a playable prototype: define remaining selection/recognition edge cases and terminal reroll state handling. D-024 now resolves normal die faces/probabilities. The walkthrough must not silently settle them.

## Revision history

- 2026-11-01: Creator approved the example direction and requested reversing All or nothing: 1 gives +3 Mult, 6 gives −3 Mult in this fixture. Reversed only D1's scripted 1/6 outcomes, updated validation selections and the negative counterfactual, and rechecked the arithmetic. Scores remain 90 and 245 (335 total), because D1 does not supply combination face points in these examples. This feedback supports the direction of the example, not numeric balance or observed player behavior.

## Follow-up case — accepting the penalty can win

Creator feedback established three desired responses to an unfavorable upgraded face: reroll it, exclude it, or accept its penalty to use it in a valuable combination. The following is a separate authored decision-state fixture, not a continuation of the completed main path. All or nothing still uses the test-only +3 Mult on 1 / −3 on 6.

- Prior round score: 90; target: 300; remaining validations: 2; manual rerolls: 2.
- Dice D1–D5: 6, 6, 6, 6, 2; D1 carries All or nothing.
- Include D1 and validate the four 6s: Four of a kind scores (50 + 24) × (7 − 3) = 296. Round total becomes 386 and immediately wins, leaving one unused validation for coin conversion.
- Hold D1 and validate the other three 6s: Three of a kind scores (20 + 18) × 4 = 152. Round total becomes 242; another validation is needed. D1's held penalty does not activate.
- Reroll only D1: a 1 permits validating 1, 6, 6, 6 for (20 + 18) × (4 + 3) = 266; another 6 leaves the four-of-a-kind option at 296. Either outcome can clear this fixture's target, but rerolling is unnecessary for the immediate win. Under subsequently accepted D-024, each outcome has probability 1/2.

Finding: accepting the negative modifier is useful here because the category gain outweighs it. This complements the earlier Pair case, where excluding the bad 6 avoids a zero-credit result. The desired three responses need not be equally good in every state. This is a worked counterexample to “always exclude the bad face,” not proof of balanced strategy across random runs.

## Presentation boundary

D-023 establishes that the calculations in this document are designer-facing explanations, not player-facing previews. Before validating the follow-up four-of-a-kind selection, the player sees the combination and base 50 points × 7 Mult, plus a crack VFX cue on the upgraded 6 to signal its active negative effect. The final 296 and resulting target-clear outcome are revealed only after commitment and completion of the scoring animation.
