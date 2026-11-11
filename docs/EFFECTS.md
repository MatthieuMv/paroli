# Paroli — Effects

**Shared rules:** Each effect activates once per validation unless another trigger is specified. Die effects require the attached die to be validated unless explicitly stated otherwise; held dice count only where specified. “Member” means part of the recognized combination. Add flat Mult first, then apply all percentage increases as one sum: `final Mult = (base Mult + sum(flat Mult)) × (1 + sum(percentages)/100)`. Two +100% effects give ×3, not ×4. Eligibility never depends on evaluation order. Upgrades permanently change faces; bonuses do not. One bonus slot per die; four Joker slots. Values below are provisional balance, not playtest results.

## Combination

**Why:** Make each combination a viable build focus, with larger rewards for harder outcomes.

**How:** Pair a dedicated +Mult die bonus with a points Joker for each combination.

**What:** Trigger only for the exact recognized category. Bonuses require the attached die to be a member; Jokers have no attachment requirement. Both may activate together. Higher categories do not also trigger effects for the smaller combinations they contain.

| Combination | Die bonus | Added Mult | Joker | Added points |
| --------------- | -------------- | ---------: | --------------- | -----------: |
| Single die | Top Hat | +6 | One-man Band | +30 |
| Pair | Sock Mate | +6 | Lovebirds | +40 |
| Two pairs | Double Vision | +8 | Double Date | +60 |
| Three of a kind | Peas in a Pod | +10 | Trio | +80 |
| Short straight | Shortcut | +10 | Conga Line | +100 |
| Full house | Couch Surfer | +12 | Sardine Tin | +120 |
| Long straight | Finish Line | +14 | Road Trip | +140 |
| Four of a kind | Four-leaf Clover | +16 | Four Corners | +160 |
| Five of a kind | High Five | +20 | Family Reunion | +200 |

Ordered by provisional difficulty: Single die is always selectable; other categories follow standard five-die roll rarity, not scoring rank. Rerolls and upgrades can change this order. Values need playtesting.

## Matching

**Why:** Reward collecting equal values while preserving the choice to cash a group or chase more matches.

**How:** Use concentrated faces, rewards per matching die, and support for both single and split groups.

**What:** All for one and Copycat count **other validated dice matching the attached die's current value**, without requiring combination membership. House builder requires Full house membership. Matchmaker counts only members of the recognized matching combination, including both groups of Two pairs or Full house.

| Effect | Family | Faces | Reward |
| ------------- | ------- | ----------- | --------------------------------------------------------------------------------------------------------------------------------- |
| All for one | Upgrade | 1,1,1,3,3,3 | +25% Mult per other matching die: +25%, +50%, +75%, +100% for 1–4 matches. |
| House builder | Upgrade | 2,2,3,3,3,3 | +50% Mult when this die belongs to a Full house, in either the pair or triple. |
| Copycat | Bonus | Unchanged | +2 Mult per other matching die; up to +8 Mult. |
| Matchmaker | Joker | — | +15 points per matching member: Pair +30; Three of a kind +45; Two pairs or Four of a kind +60; Full house or Five of a kind +75. |

Zero matches give no reward. Matchmaker gives nothing for Single die or straights. All for one's matches add into one percentage: `Mult × (1 + 0.25 × matches)`; four matches add +100% to the shared percentage pool (doubling Mult if no other percentage effects apply).

**Membership ties:** For equally ranked combinations, prefer the highest face-value sum, then the earliest die positions in run order. Do not optimize membership for effect rewards.

## Target values

**Why:** Make chasing 1 or 6 a distinct build choice.

**How:** Concentrate faces and reward specific validated values, independently of the recognized combination.

**What:** Die effects check the attached die's value when validated; Jokers count qualifying validated dice. Combination membership is not required.

| Effect | Family | Faces | Reward |
| -------------- | ------- | ----------- | ----------------------------------------------------------------------------- |
| Jackpot | Upgrade | 1,1,1,1,1,6 | +100% Mult when this die shows 6; adds +100% to the shared percentage pool. No upgrade reward on 1. |
| One or Nothing | Bonus | Unchanged | +4 Mult when this die shows 1. |
| Six Addict | Bonus | Unchanged | +4 Mult when this die shows 6. |
| Highs and Lows | Joker | — | +15 points per validated die showing 1 or 6; up to +75 points per validation. |

## Maths

**Why:** Make parity and exact sums worth pursuing beyond matching combinations.

**How:** Concentrate upgraded faces on odd or even values, reward individual parity, and offer a payoff for reaching an exact total.

**What:** Die effects require the attached die to be validated. Count only validated dice, including the upgraded die itself for parity upgrades; combination membership is not required. Sum each validated die's value once. Percentage contributions add into one increase per upgrade, rather than compounding per die.

| Effect | Family | Faces | Reward |
| ----------- | ------- | ----------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Odd master | Upgrade | 1,1,3,3,5,5 | +20% Mult per odd validated die, including itself; up to +100%. |
| Even master | Upgrade | 2,2,4,4,6,6 | +20% Mult per even validated die, including itself; up to +100%. |
| Odd Button | Bonus | Unchanged | +2 Mult when this die shows an odd value. |
| Even Button | Bonus | Unchanged | +2 Mult when this die shows an even value. |
| Lucky Seven | Bonus | Unchanged | +4 Mult if this die and at least one other validated die sum to 7 (1+6, 2+5, or 3+4). Activate once, regardless of how many partners qualify. |
| Bean Counter | Joker | — | +100 points when validated values sum to exactly 15. |
| Odd Squad | Joker | — | +10 points per odd validated die; up to +50 points. |
| Even Squad | Joker | — | +10 points per even validated die; up to +50 points. |

## Diversity

**Why:** Reward collecting different values without requiring a straight.

**How:** Scale the upgrade reward with distinct values in the selection.

**What:** Die effects require validation, without combination membership. Rainbow and Pick ’n’ Mix count each distinct validated value once; held dice do not count. Black Sheep compares its value with the other validated dice.

| Effect | Family | Faces | Reward |
| --- | --- | --- | --- |
| Rainbow | Upgrade | 1,2,3,4,5,5 | +20% Mult per distinct validated value; up to +100%. |
| Black Sheep | Bonus | Unchanged | +4 Mult when this die is validated with at least two others and no other validated die matches its value. |
| Pick ’n’ Mix | Joker | — | +10 points per distinct validated value; up to +50 points. |

## Selection size

**Why:** Reward deliberate selection sizes while preserving other dice for later plays.

**How:** Reward either leaving dice unvalidated or choosing an exact group size. Lone wolf's 1 and 6 faces support One or Nothing or Six Addict.

**What:** Count dice excluded from the current validation (0–4), or the exact number of other validated dice as specified. Die effects require the attached die to be validated, without a combination-membership requirement. Lone wolf adds the percentages into one increase, rather than compounding per excluded die.

| Effect | Family | Faces | Reward |
| ------------ | ------- | ----------- | ------------------------------------------------------------------------------------------------------------- |
| Lone wolf | Upgrade | 1,1,1,6,6,6 | +25% Mult per non-validated die; up to +100%. |
| Me Time | Bonus | Unchanged | +1 Mult per non-validated die; up to +4 Mult. |
| Four-wheel Drive | Bonus | Unchanged | +8 Mult when exactly 4 dice are validated and this die belongs to the recognized Two pairs or Four of a kind. |
| Lazy Bones | Joker | — | +5 points per non-validated die; up to +20 points. |

## Held support

**Why:** Give a die a supporting role outside the scoring selection.

**How:** Preserve a useful face while other dice score, sacrificing that die's combination participation.

**What:** Guardian and Power Reserve activate only while their die is held, once per validation. Bench Warmers counts qualifying held dice once each. Validated matches need not be combination members; additional matching partners do not multiply rewards. Validating a supporting die disables its held effects.

| Effect | Family | Faces | Reward |
| --- | --- | --- | --- |
| Guardian | Upgrade | 1,1,2,2,6,6 | While held, +50% Mult if at least one validated die matches its value. |
| Power Reserve | Bonus | Unchanged | +2 Mult while this die is held, on each validation. |
| Bench Warmers | Joker | — | +15 points per held die whose value matches at least one validated die. Count each held die once; up to +60 points. |

## Economy

**Why:** Trade scoring slots for income that strengthens the build later.

**How:** Earn coins through participation, holding, or rerolling; grow resale value or turn shop investment and owned value into Mult.

**What:** Economy effects use the triggers below, overriding the default validated-die requirement where stated. Side Hustle rewards manual rolls only; opening rolls, automatic rolls after playing a die, and cosmetic rolls do not pay. Round rewards activate once per successfully completed round, including bosses. Payday pays 2 coins. Roulette counts each paid refresh once (not shop entry or purchases); its growth persists across rounds and is lost on sale. Nest Egg reads sell values without selling anything or granting coins. These two Jokers explicitly grant Mult instead of points. Base sell values and shop costs remain to be tuned; do not assume a 1-coin refresh.

| Effect | Family | Faces | Reward |
| -------------- | ------ | --------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Golden touch | Upgrade | 1,2,2,3,3,6 | Earn coins equal to this die's value when it is validated as a member of the recognized combination. |
| Payday | Bonus | Unchanged | Earn 2 coins when this die is a member of the recognized combination. |
| Paid Leave | Bonus | Unchanged | Earn 1 coin on each validation where this die is held (not validated). |
| Side Hustle | Bonus | Unchanged | Earn 1 coin each time this die is manually rolled. Opening, automatic post-play, and cosmetic rolls do not pay. |
| Stonks | Joker | — | Gain +1 coin of sell value after each successful round while owned; accumulated value persists across rounds and is paid only when sold. |
| Roulette | Joker | — | Starts at +0 Mult. Gain permanent +1 Mult per completed paid whole-shop refresh while owned; add the accumulated Mult on every validation. |
| Nest Egg | Joker | — | Add Mult equal to the total current sell value of all owned Jokers, including itself and Stonks' accumulated value, on every validation. |

## Sequence

**Why:** Reward chasing consecutive values instead of matching groups.

**How:** Concentrate faces on middle values, leaving other dice to supply the endpoints.

**What:** Stepping stones and Borderline require the attached die to belong to the recognized straight; Ducks in a Row counts its members. Sandwiched only requires validation and its stated adjacent values. Apply only the reward for the recognized category; Short and Long straight rewards do not stack.

| Effect | Family | Faces | Reward |
| --- | --- | --- | --- |
| Stepping stones | Upgrade | 2,3,3,4,4,5 | +50% Mult when this die belongs to Short straight; +75% Mult for Long straight instead. |
| Borderline | Bonus | Unchanged | +12 Mult when this die is the lowest or highest member of the recognized Short or Long straight. |
| Sandwiched | Bonus | Unchanged | +4 Mult when other validated dice show both this die's value −1 and value +1. Activate once, regardless of duplicates. |
| Ducks in a Row | Joker | — | +15 points per member of the recognized straight: +60 for Short straight, +75 for Long straight. |
| Missing Link | Joker | — | Straights may skip one internal value: 1–2–4–5 qualifies as Short straight; 1–2–3–5–6 as Long straight. |

Missing Link still requires **4 distinct values for Short straight, 5 for Long straight**. At most one gap of size 2 is allowed; all other gaps must be 1. No wrapping or invented dice. Normal straights remain valid and category precedence is unchanged. Any five distinct standard values therefore qualify as Long straight with Missing Link. It costs a Joker slot and grants no points itself; this powerful enabling effect needs particular attention in playtests. Sandwiched always requires actual adjacent numeric values.

## Rerolls

**Why:** Make saving rerolls and investing them in a die competing strategies.

**How:** Reward untouched results, repeated attempts, or scoring after exhausting the reroll allowance.

**What:** Only manual rerolls affect these conditions; opening and automatic post-validation rolls do not. Die bonuses require validation, without combination membership. Track history per die and reset it at round start. Loyalty Card also resets after that die is validated; First Instinct remains ineligible for the rest of the round once its die is manually rerolled.

| Effect | Family | Faces | Reward |
| --- | --- | --- | --- |
| Relentless | Upgrade | 1,3,3,3,3,6 | +25% Mult per manual reroll of this die since its last validation (or round start); reset its count after validation. |
| First Instinct | Bonus | Unchanged | +4 Mult if this die has not been manually rerolled this round. |
| Loyalty Card | Bonus | Unchanged | +3 Mult per manual reroll of this die since its last validation (or round start); reset its count after validation. |
| Last Straw | Joker | — | +60 points on each validation with no manual rerolls remaining. |
| Overtime | Joker | — | +1 validation to the starting allowance of each round while owned. |
| Do-over | Joker | — | +1 manual reroll to the starting allowance of each round while owned. |

Allowance Jokers apply once at round start, not on validation. Their extra uses follow normal action rules and do not carry over; selling the Joker removes its increase from subsequent rounds.

Relentless requires its die to be validated, without combination membership. Only manual rerolls of that die count. Add the percentages into one increase: 1/2/3 rerolls give +25%/+50%/+75% Mult; extra rerolls can increase it further. Its count resets at round start and after validation. Faces are creator-selected: rare 1 and 6 outcomes support One or Nothing and Six Addict while rerolls build the Mult reward. Name and percentage remain provisional.

## Round tempo

**Why:** Make early scoring and saving a payoff for the last attempt distinct strategies.

**How:** Reward the first validation, the final available validation, or progress through the round.

**What:** Die bonuses require validation, without combination membership. Check remaining validations before commitment. Count previous validations this round, even if they credited zero points; reset history at round start. Overtime delays Grand Finale and gives Snowball another step. Reaching the target still ends the round immediately.

| Effect | Family | Faces | Reward |
| --- | --- | --- | --- |
| Crescendo | Upgrade | 2,2,3,3,4,4 | Starts at +0%. Each validation showing a higher value than this die’s previous validated value this round adds +50% Mult to its accumulated bonus, including for the current validation. Equal or lower values retain stacks without adding one. Apply the accumulated bonus whenever this die is validated; update its previous value afterward. Reset stacks and history each round. Example: 2 → 3 → 4 gives +0% → +50% → +100%. |
| Opening Act | Bonus | Unchanged | +8 Mult when this die is validated on the first validation of the round. |
| Grand Finale | Bonus | Unchanged | +12 Mult when this die is validated with exactly one validation remaining. |
| Snowball | Joker | — | +25 points per previous validation this round: +0, +25, +50 on the baseline three attempts. |

## Continuity

**Why:** Reward repeating a plan or adapting between validations.

**How:** Compare a die's value or the recognized combination with its previous result.

**What:** Déjà vu, Alternator, and Echo require their die to be validated, without combination membership, and compare against that die's own previous validation. Broken Record and Plot Twist compare against the immediately previous validation's recognized category. No reward without a prior result to compare; update history after validation even if it credits zero points, and reset it each round.

| Effect | Family | Faces | Reward |
| --- | --- | --- | --- |
| Déjà vu | Upgrade | 2,2,2,5,5,5 | +50% Mult when this die is validated showing the same value as on its previous validation this round. No reward on its first validation; reset history each round. |
| Alternator | Upgrade | 1,1,1,6,6,6 | +50% Mult when this die is validated showing a different value from its own previous validation this round. No reward on its first validation; update its previous value afterward and reset history each round. |
| Echo | Bonus | Unchanged | +8 Mult if this die shows the same value as on its previous validation this round. |
| Broken Record | Joker | — | +50 points when the recognized combination is the same as on the previous validation this round. |
| Plot Twist | Joker | — | +50 points when the recognized combination differs from the previous validation this round. |

**Balance watch:** Broken Record and Plot Twist together buy guaranteed +50 points after the first validation at the cost of two Joker slots. Economy rewards retain their approved triggers; compare Side Hustle against Payday over a complete round. Missing Link and face concentration change category difficulty, so the combination ladder is a starting point rather than an odds-based guarantee.
