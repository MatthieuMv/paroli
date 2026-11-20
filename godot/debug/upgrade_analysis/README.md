# Combination balance reports

## Start a balance pass

Open [the current balance report](effect_balance.md). It covers 29 bonuses, 14 upgrades and 28 jokers, each equipped alone, across all 461 unordered plain hands of one to five dice. The tuning goal is comparable **expected extra score per play** for scoring bonuses, accounting for how often each can help. The report measures a single committed play. Projecting an entire round or a multi-effect build requires assumptions about player choices and synergies.

- **Compare like effects first.** Within the Bonuses table, use **Net/play** for the frequency-weighted gain over plain dice, **Gain %** for the chance of scoring extra points, and the style columns for the average reward when that style is rolled. Net/play already includes the frequency of the hand. For example, Family Reunion gives +2,000 on Five of a Kind but averages +0.31 per fresh play under the default mix.
- **Check the context before changing a value.** For Echo, Crescendo, First Instinct and other history-dependent effects, read **Score changes with history** and inspect the relevant scenarios separately. To combine those results into a single estimate, specify how often the strategy reaches each state. For coin, reroll and extra-play effects, use **Economy and round allowances**.
- **Compare a tuning change against a saved baseline.** Save a copy of `effect_balance.md` or `effect_balance.parquet` before editing. Find the effect by its report ID in the [game catalog](../../mechanics/definitions/effects_catalog.gd). It defines the die faces and reward rules and refers to shared mechanics for some amounts. The [effect design notes](../../../docs/EFFECTS.md) describe the intended roles, and the [base combination scores](../../mechanics/definitions/combination_scores.gd) set the plain baseline. Rebuild all nine categories after a gameplay change and compare the same hand mix and history before and after.

### Rebuild after changing the game

From the repository root, with Godot and the DuckDB CLI on the path, run the following in a shell. On a fresh checkout, first run `godot --headless --path godot --editor --import` to import the project. The category Parquet files are generated locally and ignored by Git.

```sh
(
  set -e
  for style in high_die pair two_pairs three_of_a_kind short_straight full_house long_straight four_of_a_kind five_of_a_kind
  do
    godot --headless --path godot --script res://debug/upgrade_analysis/combination_analysis.gd -- "$style"
  done
  cd godot/debug/upgrade_analysis
  duckdb -bail -f tests/pair_weights.sql
  duckdb -markdown -bail -f render_balance.duckdb
)
```

## Cross-style effect balance

Open [the balance report](effect_balance.md) for the style leaders and one comparison row per catalog effect. The report also lists history-dependent gains and economy rewards. [The ranked Parquet table](effect_balance.parquet) includes the fresh mean, median, minimum and maximum score. Its nine style columns contain mean direct point gains.

When the nine pairs of category files already reflect the game values you want to compare, rebuild just the Markdown and ranked Parquet from the repository root.

```sh
cd godot/debug/upgrade_analysis
duckdb -markdown -bail -f render_balance.duckdb
```

[The DuckDB query](effect_balance.sql) stacks the nine summaries and joins the selected experiments to their physical outcomes. It identifies input style from the source filename, so a promotion by Missing Link receives credit under the original play style. The plain build supplies the comparison score for each effect's net gain.

The default hand-size frequencies give one through five dice equal weight before rolling. Within each size, exact roll probabilities determine the weight of every outcome. Change the five relative integer frequencies in `balance_hand_mix` to model a different distribution. The three held-support items use their held experiment at sizes one through four and their played experiment at five. Each history has its own result. The headline uses `fresh`.

For a different history, run the SQL in an interactive DuckDB session from this directory:

```sql
.read effect_balance.sql
SELECT scenario, play_style, round(style_gain, 2) AS mean_extra_points
FROM balance_styles
WHERE effect = 'echo' AND play_style IN ('pair', 'full_house')
ORDER BY scenario, play_style;
```

`balance_detail` exposes the original per-size statistics for every state and placement. `balance_scenarios` gives overall scores and rewards for each history. These views are available in the session that reads the query.

## Generate a category report

Run from the repository root with Godot and the DuckDB CLI on the path.

```sh
godot --headless --path godot --script res://debug/upgrade_analysis/combination_analysis.gd -- pair
godot --headless --path godot --script res://debug/upgrade_analysis/combination_analysis.gd -- pair --list
```

The first command writes `pair_summary.parquet` and `pair_outcomes.parquet` beside the script. The second prints every plain Pair hand with its scoring members, exact roll probability, and score. Other supported categories are `high_die`, `two_pairs`, `three_of_a_kind` (Triple), `short_straight`, `full_house`, `long_straight`, `four_of_a_kind`, and `five_of_a_kind`. Use the same category argument for listing hands and generating reports. The original `high_die.gd` listing and `high_die_effects.gd` runner also work.

The categories share one multiset generator, game scorer, equipped-die placement calculation, history generator, and DuckDB summary query. GDScript scores through `RoundSession.play()`. DuckDB reads the observations from a temporary file and exports the weighted results.

## Reading the results

Each experiment fixes the number of dice **before rolling** and plays those dice. It measures inputs that ordinary dice recognize as the requested category. There are 55 High Die inputs, 144 Pair inputs, 75 Double Pair inputs, 96 Triple inputs, 17 Short Straight inputs, 30 Full House inputs, 2 Long Straight inputs, 36 Four of a Kind inputs, and 6 Five of a Kind inputs. The output records the actual scored category because Missing Link can promote some of those inputs to a straight. Hands of different sizes, history states, and held/played policies have separate summaries.

- **Mean, median, minimum and maximum score** describe the distribution among the qualifying inputs. Physical outcomes supply the weights. The median averages the two central scores when the count is even.
- **Mean gain** compares the equipped score with the plain score on the same faces. To include the upgrade’s face distribution in a comparison, compare its mean score and input probability with the plain experiment of the same size.
- **Input probability** gives the chance of rolling one of the included hands (`input_probability`). **Chance of best per roll** gives the chance of rolling an included hand that attains the reported maximum. Both use all rolls in the fixed experiment as their denominator.
- **Coins, extra plays, extra rerolls and sell growth** retain their game units. Coins include the specified manual rerolls and the measured play. Extra allowances describe the round-start grant. Sell growth describes the result of the measured play. Nest Egg uses the normal shop sell value of the one equipped joker.
- **State** names the history assumed before the measured play. Crescendo uses all reachable previous-face and stack combinations within the normal round. Roulette compares zero through three paid refreshes, an explicit analysis limit. Probabilities condition on the named state. A full-round probability also needs a policy for reaching that state.

For die-bound items, the equipped die is among the dice played. Guardian, Power Reserve and Paid Leave also have separate experiments with their owner held. The detail table identifies the equipped face. If both assignments are possible, both count with their own physical probabilities. Bench Warmers integrates over all possible values on the held dice by counting how many match a played face.

## Pair hands

| Dice played | Distinct plain Pair hands | Chance per roll |
| ---: | ---: | ---: |
| 2 | 6 | 1/6 |
| 3 | 30 | 5/12 |
| 4 | 60 | 5/9 |
| 5 | 48 | 10/27 |

The category is the strongest combination among the selected dice. For example, `[1,1,2,3,4]` scores as a short straight. In `[1,1,2,3,5]`, the two ones score as the pair, and the other faces can still trigger effects that read all played dice.

The plain hand `[1,1,6]` represents three ordered rolls. With Jackpot equipped, ten physical rolls out of 216 put Jackpot on a 1 (five physical sides, two orders for the ordinary dice). One physical roll puts Jackpot on the 6 (one side, one order for the two ordinary ones). Both placements contribute to the metrics.

## Double Pair hands

| Dice played | Distinct plain Double Pair hands | Chance per roll |
| ---: | ---: | ---: |
| 4 | 15 | 5/72 |
| 5 | 60 | 25/108 |

The four members are two pairs with different values. A fifth die must show a third value for the hand to score as Double Pair. For example, `[1,1,4,4,6]` represents 30 ordered rolls. With Double Vision on a fixed played die, 12 of those rolls put it on a 1, 12 put it on a 4, and 6 put it on the unmatched 6. It grants extra Mult on the first two placements.

## Triple hands

| Dice played | Distinct plain Triple hands | Chance per roll |
| ---: | ---: | ---: |
| 3 | 6 | 1/36 |
| 4 | 30 | 5/54 |
| 5 | 60 | 25/162 |

Exactly three dice share a face. Any extra dice must differ from that face and from each other. For example, `[2,2,2,4,6]` scores as Triple, while `[2,2,2,4,4]` scores as Full House. The Triple hand represents 20 ordered rolls. With Peas in a Pod on one fixed played die, 12 place it on a 2, four on a 4, and four on a 6. The 12 placements on a 2 earn its bonus.

## Short Straight hands

| Dice played | Distinct plain Short Straight hands | Chance per roll |
| ---: | ---: | ---: |
| 4 | 3 | 1/18 |
| 5 | 14 | 10/81 |

Four consecutive values score. Of the 14 five-die hands, 12 repeat a straight value and two have a fifth face outside the run. Five consecutive values score as a Long Straight. Missing Link promotes both outside-face hands to Long Straight by bridging a one-value gap. The report measures these promotions on the plain Short Straight inputs.

A duplicate can affect a die-bound bonus. In `[1,2,2,3,4]` only one 2 scores. The game chooses the earlier die in run order. The experiment equips the first die, so if it shows a 2 it wins that tie.

## Long Straight hands

| Plain hand | Ordered rolls | Chance per five-die roll | Plain score |
| --- | ---: | ---: | ---: |
| `[1,2,3,4,5]` | 120 | 5/324 | 600 |
| `[2,3,4,5,6]` | 120 | 5/324 | 640 |

All five dice score. Together these hands occur on 5/162 of plain rolls. The Long Straight report measures the effects on these two inputs. For Missing Link’s overall chance of scoring a Long Straight, include its promoted hands from the High Die and Short Straight reports as well.

## Full House hands

A Full House uses all five dice. There are six choices for the triple’s face and five choices for the pair’s face, giving 30 distinct hands. Each has 10 orderings, so the chance is 300/7,776 (25/648) on one roll of five ordinary dice.

For `[2,2,2,3,3]`, six orderings put the equipped die in the triple and four put it in the pair. House builder has two physical 2s and four physical 3s, so those placements contribute 12 and 16 physical rolls respectively to the hand’s probability.

## Four of a Kind hands

| Dice played | Distinct plain Four of a Kind hands | Chance per roll |
| ---: | ---: | ---: |
| 4 | 6 | 1/216 |
| 5 | 30 | 25/1296 |

Four dice must show the same face. With five dice played, the fifth must differ because five matching dice score as Five of a Kind. For example, `[2,2,2,2,6]` has five orderings. Four put a bonus attached to a fixed played die on a scoring 2, and one puts it on the 6.

## Five of a Kind hands

All five played dice show the same face, so every die is a scoring member. With five plain dice, each of the six hands occurs once in 7,776 ordered rolls. The total chance per roll is 1/1,296.

With one upgraded die and four plain dice, the four plain dice must match whatever the upgraded die rolls. The total chance is still 1/1,296, but the matching face follows the upgrade’s face distribution. Jackpot makes five ones five times as likely as five sixes.

## Example queries

From this folder, open `duckdb`. Compare all items on a fresh two-die Pair play, including both the size of the reward and how likely the maximum is.

```sql
SELECT effect, placement, round(mean_score, 2) AS mean_score, median_score,
       min_score, max_score, round(mean_gain, 2) AS mean_gain,
       round(100 * chance_of_best_per_roll, 2) AS best_chance_pct
FROM 'pair_summary.parquet'
WHERE dice_played = 2 AND state = 'fresh' AND placement IN ('played', 'global')
ORDER BY mean_score DESC, effect;
```

To check how lucky a player must be to reach a target, sum the probability of the qualifying outcomes in one experiment. For Jackpot, a target of 22 on a two-die High Die play is reached on 5 of 36 rolls.

```sql
SELECT sum(CASE WHEN score >= 22 THEN roll_probability ELSE 0 END) AS chance_per_roll
FROM 'high_die_outcomes.parquet'
WHERE effect = 'jackpot' AND placement = 'played'
  AND state = 'fresh' AND dice_played = 2;
```

After generating the Pair reports, run `duckdb -bail -f tests/pair_weights.sql` from this folder to check repeated-face placements and held-die matching.
