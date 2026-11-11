# Paroli — Deckbuilding design space

Status: Exploration map, not a content catalog or balance specification. Updated: 2026-11-11. Owner: Project creator.

## DB-01 — Start with play, then design content

**Why:** Builds should enhance meaningful choices available with five dice. Starting from visual effects or fourteen upgrade slots risks inventing rewards before identifying the play they serve.

**How:** Map outcomes, selection, rerolling, and commitments first. Choose contrasting playstyles, then derive complementary upgrades, bonuses, and Jokers from their needs.

**What:** Use the map below as the starting point for subsequent content design. [EFFECT_IDEAS.md](EFFECT_IDEAS.md) groups candidate upgrades, bonuses, and Jokers by the dimensions below; it is an exploration bank, not an accepted content catalog. The [GDD](GAME_DESIGN_DOCUMENT.md) remains authoritative for accepted rules. This document exhausts ordinary combination structures and maps independent playstyle dimensions; arbitrary future effects can create additional styles, so there is no finite list of every possible build.

## The five-die foundation

Five independent dice, initially six equally likely faces numbered 1–6. Select any nonempty subset to validate or manually reroll: **31 possible subsets** for either action. The baseline round allows three validations and three manual rerolls. After validation, selected dice reroll for free and unselected dice keep their values. Reaching the target ends the round immediately; unused validations become coins.

Three roles matter: **combination members** supply face points; **validated extras** may activate effects but supply no automatic face points; **held dice** preserve their result and activate only explicitly held effects. Choosing what to exclude is therefore as important as choosing what to score.

## All scoring combinations

Highest rank present in the selected dice wins; it is not necessarily the most profitable category after effects. Base values below are the GDD's provisional values. Counts exhaust all **7,776 ordered outcomes** of one standard five-die roll, when all five are selected, with ordinary matching rules and no modifiers or rerolls.

| Rank | Category | Required members | Example | Base points × Mult | Outcomes / 7,776 |
| ---: | --- | ---: | --- | ---: | ---: |
| 1 | Single die | 1, highest selected value | 6 | 5 × 1 | 240 |
| 2 | Pair | 2 equal | 3–3 | 10 × 2 | 2,880 |
| 3 | Two pairs | 2 + 2, different values | 2–2–5–5 | 15 × 3 | 1,800 |
| 4 | Three of a kind | 3 equal | 4–4–4 | 20 × 4 | 1,200 |
| 5 | Short straight | 4 consecutive distinct values | 1–2–3–4 | 30 × 5 | 960 |
| 6 | Full house | 3 + 2, different values | 2–2–2–5–5 | 40 × 6 | 300 |
| 7 | Four of a kind | 4 equal | 5–5–5–5 | 50 × 7 | 150 |
| 8 | Long straight | 5 consecutive distinct values | 2–3–4–5–6 | 60 × 8 | 240 |
| 9 | Five of a kind | 5 equal | 6–6–6–6–6 | 80 × 10 | 6 |

Short straights are exactly **1234, 2345, 3456**; long straights are **12345, 23456**. A fifth selected die can duplicate a short-straight value, sit outside it, or extend it to a long straight. For Single die on a five-die selection, the only distinct-value sets without a straight are **12356** and **12456**.

Counts describe initial outcomes, not strategy success rates. Selection, retained values, rerolls, and changed faces alter the odds. Face values of members are added to base points before multiplying by final Mult.

### All matching structures, for every selection size

Each number below is the size of a group of equal values; different groups have different values. These integer partitions exhaust the equality patterns. Consecutiveness is a separate property of the distinct values.

| Selected dice | All possible group-size patterns | Additional straight possibilities |
| ---: | --- | --- |
| 1 | 1 | None |
| 2 | 2; 1+1 | None |
| 3 | 3; 2+1; 1+1+1 | None |
| 4 | 4; 3+1; 2+2; 2+1+1; 1+1+1+1 | Four distinct values may be a short straight |
| 5 | 5; 4+1; 3+2; 3+1+1; 2+2+1; 2+1+1+1; 1+1+1+1+1 | Four distinct values may contain a short straight; five may contain a short or long straight |

A table outcome is not a forced play: **2–2–2–5–5** can be selected as Full house, Three of a kind, Two pairs, Pair, or Single die. Selecting a smaller subset trades immediate category strength for retained dice, effect eligibility, or a future plan.

## Playstyle map

Rows are independent dimensions that can be combined, not mutually exclusive classes. “Needs support” identifies behavior that is possible to pursue but has no dedicated reward in the baseline rules.

| Dimension | Playstyle possibilities | Decision and sacrifice |
| --- | --- | --- |
| Matching | Solo; exact pair; two pairs; triple; full house; four/five of a kind | Cash a small group or invest in extending it; a larger group may disable a specialized reward |
| Sequences | Short-straight specialist; long-straight chase; flexible straight-or-pair pivot | Keep distinct values and fill gaps instead of collecting duplicates |
| Target values | One chosen number; two complementary numbers; low values; high values; middle values; extremes | Concentration improves matching odds but removes coverage; high faces already give more points, other preferences need support |
| Value properties | Odd; even; mixed parity; chosen subsets; target sums; narrow or wide spread | Decide which values belong together; these are effect conditions, not additional baseline categories |
| Diversity | All matching; two value groups; many distinct values; no duplicates | Specialization in one structure sacrifices access to others; distinct values without a straight need support |
| Selection size | Validate exactly 1, 2, 3, 4, or all 5 | Small selections preserve more of the table; full selections refresh everything and allow five-member categories |
| Die roles | One scoring carry; several equal contributors; held support; useful validated extras | Spend a die on scoring, effect activation, or preservation; support and extras need explicit effects |
| Reroll policy | Accept the opening roll; lock a core and fish; reroll the whole table; chase one rare face | Reliability and saved actions versus upside; an unused reroll has no baseline coin value |
| Risk | Consistent modest payouts; rare jackpots; accept a penalty to complete a pattern; pivot after misses | Protect remaining attempts or commit to a larger uncertain payoff |
| Validation tempo | Clear early; accumulate over several validations; prepare a final-attempt payoff | Early clears earn unused-validation coins; delayed rewards consume safety and need support |
| Continuity | Repeat one category/value; alternate patterns; climb toward larger groups; adapt every validation | Repetition benefits from consistent faces; sequences across actions require explicit memory and rewards |
| Retention cycle | Hold a valuable core; repeatedly score and reroll a small group; alternate two groups; refresh all five | Preserve future opportunities versus reuse the strongest dice now |
| Score construction | Points-heavy; Mult-heavy; balanced; high-base-category scaling | Points and Mult complement one another; adding to the smaller factor may have greater relative impact |
| Build composition | All dice pursue one plan; complementary specialists; carry plus support; flexible fallback plan | Maximum synergy versus resilience to missed rolls and boss restrictions |
| Run economy | Fast clears and coin growth; invest in consistency; spend for immediate power | Current scoring strength versus later purchases; exact economic strategies await prices and conversion values |

A concrete style combines a few dimensions: **high-value matching + locked core + jackpot chase**, **low-value pair + small repeated validations + held support**, or **middle-value coverage + straight pursuit + flexible fallback**. No color or particle effect is needed to define these identities.

## DB-02 — Derive the three content families from playstyles

**Why:** A supported style needs both a way to reach its desired outcomes and a reason to choose them. Three unrelated score bonuses do not necessarily create a new style.

**How:** For each chosen style, identify its desired outcome, action pattern, weakness, and tempting alternative. Give the content families complementary jobs, then test their interaction.

**What:** Use this division as a proposed design lens, consistent with the GDD's permanent upgrade, movable bonus, and global Joker structure:

| Family | Design job | Questions before writing an effect |
| --- | --- | --- |
| Die upgrade | Permanently reshape a die's faces and give it a committed role | Which outcomes become more likely? Which options disappear? How does this change holding, selection, or reroll decisions? |
| Die bonus | Reward a particular die's contribution within a style | Must it be a member, a validated extra, or held? Which die wants it, and why might the player move it between rounds? |
| Joker | Support a pool-wide strategy, action economy, or explicit rule exception | Does it connect several dice or actions? Does it support repeatability, recognition, resources, or payoff? What new choice does it create? |

Recognition changes—wild values, new patterns, relaxed straights, or multiple scoring categories—are **future rule extensions**, not combinations available today. Extra actions and history-dependent rewards likewise require explicit rules. They should follow a demonstrated playstyle need.

For each candidate style, record **target pattern → player choices → odds support → payoff support → cost/failure case → fallback**. Assign named effects, numbers, colors, and VFX only after that chain is convincing. There is no requirement for one item per style or one style per asset.

## Validation gate

The combination counts above were checked by enumerating all 6⁵ standard outcomes. They establish coverage, not balance. Viability of the playstyles remains untested.

Before producing another content catalog, choose a small set of contrasting styles and walk through successful and failed rounds with each. Check that each changes player decisions, has a real opportunity cost, and retains a fallback. Then test supported builds across multiple rounds and boss constraints. Resolve membership ties, recognition exceptions, and economic values in the GDD when those decisions become necessary.
