# Paroli — Effect ideas by playstyle dimension

Status: Proposed ideas, not an implementation or balance specification. Updated: 2026-11-11. Owner: Project creator.

## EI-00 — Design from the player's choices

**Why.** Content should make a playstyle more reachable, more rewarding, or more interesting to commit to. The starting point is the [deckbuilding design space](DECKBUILDING_DESIGN.md), with accepted rules owned by the [GDD](GAME_DESIGN_DOCUMENT.md).

**How.** Each group below starts with a player decision, then explores complementary die upgrades, die bonuses, and Jokers. These are alternatives to explore, not mandatory three-item sets. One effect can support several dimensions.

**What.** Upgrades permanently replace all six face positions and establish a role. Bonuses reward the attached die and can move outside rounds. Jokers support a strategy across the pool or its actions. No fixed item count, visual assignment, or final tuning is implied.

### Reading the ideas

- **Member** means part of the highest-ranked recognized combination. **Validated** includes selected extras. **Held** means excluded from that validation. Die effects require validation unless explicitly labeled held.
- Each listed effect activates once per validation unless another timing is stated. “Per die” counts distinct dice, not face positions. Rewards add points or Mult; they do not multiply existing modifiers or score another category.
- **P**, **M**, and **C** mean positive, untuned amounts of points, Mult, and coins, local to each idea. Different effects need not use equal amounts. Face layouts are concrete candidates; repeated values retain the GDD's equal probability per physical face.
- All history and counters reset each round unless stated otherwise. Compare against state before the current validation, then update after it, even when credited score is zero. No scoring trigger occurs merely by holding or rerolling a die.
- Category conditions use the recognized category, not a lower category hidden inside it. Membership ties remain a GDD question. Rule extensions are labeled explicitly.

## EI-01 — Matching: cash a small group or extend it

**Intent and cost:** Make several group sizes worth pursuing. Chasing a larger group spends rerolls and may lose a smaller group's specialized reward.

| Family | Effect ideas |
| --- | --- |
| Upgrade | **Twin anchor:** faces `2,2,2,5,5,5`; +M when this die is a member of Pair or Two pairs. **House foundation:** faces `3,3,3,4,4,4`; +P and +M when this die belongs to the triple of a Full house. |
| Bonus | **Triple specialist:** +P when this die is a member of Three of a kind. **Pair partner:** +M when this die belongs to the pair of a Full house. |
| Joker | **Big family:** +P for Four of a kind; +P and +M for Five of a kind instead. Other categories receive nothing. |

## EI-02 — Sequences: preserve coverage or collect duplicates

**Intent and cost:** Support deliberate gap-filling, with a short-straight fallback. Reliable middle values still leave endpoints to other dice.

| Family | Effect ideas |
| --- | --- |
| Upgrade | **Bridge:** faces `2,3,3,4,4,5`; +M when this die is a member of a Short or Long straight. |
| Bonus | **Bookend:** +P when this die is the lowest or highest member of the recognized straight; activate only once. |
| Joker | **Long road:** +P and +M for Long straight. **Missing step — recognition extension:** four distinct selected values spanning exactly five integers may also qualify as Short straight; ordinary straights remain valid and the normal category hierarchy still applies. |

## EI-03 — Target values: specialize or retain coverage

**Intent and cost:** Let players prefer particular numbers rather than always taking the highest. Concentrating faces closes other matching and straight routes.

| Family | Effect ideas |
| --- | --- |
| Upgrade | **Favorite:** choose a value N when acquired; replace faces with `N,N,N,N,N,N`. +M when this die forms a recognized matching group of at least two dice. This extreme commitment needs testing for excessive reliability. **High ground:** faces `4,4,5,5,6,6`; +P when this die is a member showing 6. |
| Bonus | **Small wonder:** +M when this die shows 1 or 2. **Middle weight:** +P when this die shows 3 or 4. |
| Joker | **Two poles:** +P per validated 1 and +M per validated 6, but only when the selection includes both values. |

## EI-04 — Value properties: choose which values belong together

**Intent and cost:** Reward parity, sum, or spread without making them new scoring categories. A valuable ordinary combination may violate the preferred property.

| Family | Effect ideas |
| --- | --- |
| Upgrade | **Odd engine:** faces `1,1,3,3,5,5`; +M per odd validated die, including itself. **Even engine:** faces `2,2,4,4,6,6`; +P per even validated die, including itself. |
| Bonus | **Counterweight:** +M when this die is validated alongside at least one die of opposite parity. |
| Joker | **Exact total:** +P and +M when validated values sum to 15. **Close company:** +M when at least three dice are validated and their highest and lowest values differ by at most 1. |

## EI-05 — Diversity: keep distinct results or collapse into groups

**Intent and cost:** Give scattered results a purpose without requiring a straight. Keeping diversity reduces matching opportunities.

| Family | Effect ideas |
| --- | --- |
| Upgrade | **Outlier:** faces `1,1,1,6,6,6`; +P when at least three dice are validated and no other validated die matches this die's value. |
| Bonus | **Unique voice:** +M when this die is validated with at least two others and its value occurs exactly once in that selection. |
| Joker | **Rainbow:** +P per distinct validated value, only when at least four distinct values are present. **Two camps:** +M when at least four dice are validated and exactly two distinct values are present. |

## EI-06 — Selection size: preserve dice or commit the table

**Intent and cost:** Make exact selection sizes change the best action. Small selections preserve results but consume the same validation allowance.

| Family | Effect ideas |
| --- | --- |
| Upgrade | **Soloist:** faces `1,1,1,1,2,3`; +P and +M when this is the only validated die. |
| Bonus | **Duet:** +M when this die is one of exactly two validated dice. **Trio:** +P when it is one of exactly three. |
| Joker | **Quartet:** +M when exactly four dice are validated. **Full table:** +P and +M when all five are validated. These are alternative ideas, not one combined effect. |

## EI-07 — Die roles: carry, support, or useful extra

**Intent and cost:** Make a die valuable in different positions within a scoring action. Held support gives up that die's combination participation; extras must reroll after validation.

| Family | Effect ideas |
| --- | --- |
| Upgrade | **Low beacon:** faces `1,1,2,2,3,3`; explicitly **while held**, +M on each validation if showing 1. Validating it disables this reward. |
| Bonus | **Lead:** +P when this die is the unique highest-valued member. **Backing:** +M when this die is validated but is not a member. |
| Joker | **Whole cast:** +P and +M when a validation has at least one member, at least one validated extra, and at least one held die. |

## EI-08 — Reroll policy: take the roll or spend for precision

**Intent and cost:** Create competing reasons to avoid rerolls, fish for one result, or reset the table. Only manual rerolls consume the reroll allowance.

| Family | Effect ideas |
| --- | --- |
| Upgrade | **Prospector:** faces `1,1,1,1,1,6`; +P and +M when validated showing 6 after this die has been manually rerolled at least once since its previous validation or round start. |
| Bonus | **Untouched:** +M if this die has not been manually rerolled this round. Automatic rolls do not invalidate it. |
| Joker | **Precision budget — action extension:** once per round, manually rerolling exactly one die consumes no reroll use; this action is allowed even at zero uses. **Clean slate:** after manually rerolling all five, the next validation gains +P; one pending reward maximum, consumed on that validation. |

## EI-09 — Risk: dependable payoff or dangerous upside

**Intent and cost:** Let players choose variance and decide when a penalty is worth accepting. Bad results should allow rerolling, exclusion, or deliberate inclusion.

| Family | Effect ideas |
| --- | --- |
| Upgrade | **All or nothing:** faces `1,1,1,6,6,6`; validated 1 adds M to Mult, validated 6 subtracts the same M, whether or not this die is a member. |
| Bonus | **Wager:** +P when this die belongs to a recognized matching group of at least three; −P when validated without meeting that condition. |
| Joker | **Safety net:** +P on the next validation after one credited zero points; one pending reward, with consecutive zero results renewing rather than stacking it. Spending a validation to enable this must remain costly. |

## EI-10 — Validation tempo: win early or prepare a finish

**Intent and cost:** Support early bursts and late rescue plans. Delaying a clear sacrifices safety and unused-validation coins.

| Family | Effect ideas |
| --- | --- |
| Upgrade | **Closer:** faces `1,1,2,2,3,3`; +P and +M when validated with exactly one validation remaining before commitment. Extra action allowances delay this condition. |
| Bonus | **Opening act:** +P when this die is validated on the first validation of the round. |
| Joker | **Momentum:** +M for each earlier validation this round. **Quick start:** +P and +M only on the first validation instead. These support opposite tempo choices. |

## EI-11 — Continuity: repeat, alternate, or climb

**Intent and cost:** Make a previous action influence the next plan. A better immediate category may break the desired sequence; history needs a visible, simple indicator.

| Family | Effect ideas |
| --- | --- |
| Upgrade | **Refrain:** faces `2,2,3,3,4,4`; +M if validated in the same recognized category as the immediately previous validation. No first-validation reward. |
| Bonus | **Echo:** +P if this die is validated showing the same value as on its own previous validation this round. Being held between those validations preserves the comparison. |
| Joker | **Alternation:** +M when the current category differs from the immediately previous one. **Ascending act:** +P and +M when the current category's rank is strictly higher than the previous one. Neither rewards the first validation. |

## EI-12 — Retention cycle: reuse a core or rotate contributors

**Intent and cost:** Reward patterns of die selection across actions, independently of category. Keeping one group intact reduces the dice available for the current score.

| Family | Effect ideas |
| --- | --- |
| Upgrade | **Reservoir:** faces `2,2,2,5,5,5`; gain one charge whenever held through a validation, to a maximum of two. When validated, add P per charge, then clear charges. Manual rerolls clear charges; all charges expire at round end. |
| Bonus | **Workhorse:** +M if this die was also selected in the immediately previous validation. |
| Joker | **Relay:** +P and +M when the current and immediately previous validation each select at least two dice and their selected die identities do not overlap. No first-validation reward. |

## EI-13 — Score construction: build points, Mult, or both

**Intent and cost:** Encourage complementary score sources. A large additive reward to one factor still needs the other factor to turn it into a strong score.

| Family | Effect ideas |
| --- | --- |
| Upgrade | **Split engine:** faces `1,1,1,6,6,6`; validated 1 adds M to Mult; validated 6 adds P to points. The player seeks whichever factor their build lacks. Unlike All or nothing, its cost is restricted face coverage rather than a penalty. |
| Bonus | **Point specialist:** +P when this die is a member showing 4–6. **Mult specialist:** +M when it is a member showing 1–3. |
| Joker | **Foundation:** add points equal to the recognized category's base points. **Amplifier:** add Mult equal to its base Mult. These use base values, not modified totals, preserving order-independent scoring. |

## EI-14 — Build composition: concentrate or diversify roles

**Intent and cost:** Make later acquisitions develop a coherent pool. Uniformity strengthens one route; specialists and fallbacks help when that route fails.

| Family | Effect ideas |
| --- | --- |
| Upgrade | **Specialist:** choose permanently between `1,1,2,2,3,3` and `4,4,5,5,6,6` when acquired. +M when this die is validated with at least one value from the opposite band. Its layout supplies one role while its reward asks for a complement. |
| Bonus | **Shared craft:** +P when this die and at least one other validated die have identical printed six-face value multisets. This compares layouts, not upgrade names or current results. |
| Joker | **Mixed workshop:** +M per distinct printed face multiset among validated dice, only if at least three different layouts are represented. Ordinary dice all count as the same layout. |

## EI-15 — Run economy: current power or future purchases

**Intent and cost:** Tie economic support to a deliberate play pattern. Rewards paid after a successful round cannot rescue a failed round; their value depends on shop prices.

| Family | Effect ideas |
| --- | --- |
| Upgrade | **Investor:** faces `1,1,1,2,2,2`; whenever validated showing 1, mark C pending coins. Pay the total only on round success; discard it on failure. Low faces and the absence of a scoring reward are its immediate cost. |
| Bonus | **Closing tip:** gain C coins at successful round settlement if this die was a member of the target-clearing combination. |
| Joker | **Thrift:** gain C coins per unused manual reroll at successful round settlement. This explicitly adds a reward that the baseline rules do not provide. |

## EI-16 — Choose experiments before choosing a catalog

**Why.** More ideas do not prove that more playstyles are viable. Overlapping rewards can accidentally make one action correct for every build.

**How.** Start with three contrasting experiments: small matching groups with held support; straights with selective rerolls; and risky high matching groups. Choose only enough ideas to provide each with odds support and payoff support. Keep the other ideas as alternatives.

**What.** For each experiment, walk through a success, a miss, a tempting pivot, and a boss restriction. Record whether the effects change selection or reroll decisions, what the commitment costs, and which fallback remains. Test isolated effects and combined builds before setting numbers or visual identities.

Open questions before implementation: numerical tuning; membership ties; history UI; duplicate ownership and stacking; acquisition/removal behavior for stateful Jokers; economy values; and interactions of recognition extensions with future rules. These ideas have not been playtested. Existing GDD rules are not changed by their inclusion here.
