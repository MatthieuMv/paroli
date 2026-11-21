# Standard run balance

The standard run opens at 100 points and uses 1.45 target growth. Its five bosses require 210, 640, 2,000, 6,000, and 18,000 points. The previous last boss required 72,000. The 15-round route, three opening upgrade offers, shop prices, and starting action allowances are the same in both experiments.

The comparison uses 2,000 fresh drafted runs per hand strategy on the live catalog, seeds 10,001–12,000. Every policy sees the same starting seeds and may take fallback hands. The early curve and item candidates were selected using separate development seeds. These are scripted-player results. The procedures and commands are in the [analysis README](README.md).

## Progression by hand

Each boss column is the percentage of all starting runs that reached and cleared that boss. The win interval is a 95% Wilson interval. The last column gives the signature category’s share of score in biomes four and five.

| Strategy | 1.60 win %¹ | Boss 1 % | Boss 2 % | Boss 3 % | Boss 4 % | Live win % | Win 95% CI | Signature % |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Flexible | 0.0 | 99.8 | 99.2 | 98.3 | 94.4 | 63.0 | 60.8–65.0 | — |
| High Die | 0.0 | 99.8 | 99.1 | 96.7 | 87.7 | 29.9 | 28.0–32.0 | 74.7 |
| Pair | 0.0 | 99.8 | 99.2 | 97.2 | 92.7 | 40.0 | 37.9–42.2 | 78.0 |
| Two Pairs | 0.0 | 99.5 | 98.5 | 96.7 | 91.0 | 39.7 | 37.6–41.9 | 57.7 |
| Triple | 0.0 | 99.8 | 99.2 | 97.9 | 93.2 | 46.7 | 44.5–48.9 | 47.7 |
| Short Straight | 0.9 | 98.8 | 95.3 | 89.5 | 79.7 | 50.9 | 48.7–53.1 | 78.6 |
| Full House | 0.0 | 99.3 | 97.0 | 92.8 | 81.2 | 31.2 | 29.3–33.3 | 24.3 |
| Long Straight | 0.8 | 94.7 | 88.0 | 80.8 | 70.7 | 36.2 | 34.1–38.3 | 48.2 |
| Four of a Kind | 0.4 | 99.7 | 98.3 | 94.2 | 83.3 | 39.4 | 37.2–41.5 | 27.8 |
| Five of a Kind | 0.1 | 99.7 | 98.0 | 93.0 | 78.3 | 24.6 | 22.8–26.5 | 6.8 |

¹ The 1.60 column uses seeds 1–2,000 and the first catalog pass, including Double Date, One-man Band, and House Builder. The independent live cohort also includes the subsequent Pair and held-die changes. The isolated comparisons below measure individual item changes on matched seeds.

All nine hand strategies exceed the provisional 10% win floor. Flexible play still wins 63.0% of runs. Even the closest specialist, Short Straight, trails it by 12.1 percentage points (paired 95% interval for the deficit, 8.0–16.1 points). All nine miss the five-point win-rate target and the ten-point target for staying close to flexible play at every boss. Long Straight falls behind by the second boss. Pair stays within ten points through the fourth.

## Catalog decisions

On the 1.60 curve, the first three candidates were each tested alone against the old catalog on 250 paired seeds.

- Raising **Double Date** from +60 to +85 points moved fourth-boss clears from 17.6% to 28.4% for a supplied Two Pairs build. Its direct gain on plain Two Pairs is now 255 score, compared with 180 for Matchmaker.
- **One-man Band** starts at +30 points and gains +10 for each round cleared with High Die while owned. Adding that growth to a supplied High Die build moved fourth-boss clears from 1.6% to 64.0%.
- **House Builder** now gives +25% Mult when its die belongs to Two Pairs and +50% when it belongs to Full House. The new Two Pairs fallback moved third-boss clears from 66.8% to 76.0% for the supplied Full House build. [Individual effect report](effect_balance.md)

The curve sweep tested 1.40, 1.44, and 1.48. At 1.40 the flexible policy won 93 of 100 runs. At 1.48 it won 30, while Pair won two. At 1.44 the held strategy still won only one of 100. At 1.45, **Lovebirds** at +70 increased drafted Pair wins from 20.0% to 32.0% over 150 paired seeds. **Bench Warmers** at +45 per matching held die with **Power Reserve** at +6 Mult increased drafted held wins from 0.7% to 19.3%. Testing the two changes separately gave 9.3% and 2.0%, respectively. The combined build can now earn both points and Mult outside the scoring selection.

**Nest Egg** won more often than the dedicated starting joker on 7 of nine routes in the 100-seed equal-slot comparison. Its half-value trial took the economy, portfolio, and held policies down to 4%, 2%, and 7% wins on 100 drafted seeds. Retain its full sell-value reward in this pass. **Opening Act** stays at +8 Mult. Its +6 trial showed mixed win-rate changes across the nine drafted routes.

## Supplied builds and fallback hands

| Route | Draft win % | Supplied win % | Draft signature % | Supplied signature % | Decisive clears / supplied run |
|---|---:|---:|---:|---:|---:|
| High Die | 28.4 | 95.2 | 78.0 | 99.7 | 9.25 |
| Pair | 42.8 | 50.0 | 77.0 | 92.0 | 7.65 |
| Two Pairs | 40.8 | 44.8 | 55.0 | 67.8 | 4.25 |
| Triple | 46.0 | 52.4 | 46.4 | 65.5 | 3.58 |
| Short Straight | 50.8 | 61.2 | 80.4 | 89.0 | 5.75 |
| Full House | 30.4 | 26.0 | 24.9 | 37.5 | 0.86 |
| Long Straight | 37.2 | 34.8 | 49.3 | 59.1 | 0.66 |
| Four of a Kind | 36.4 | 42.8 | 25.5 | 40.3 | 0.89 |
| Five of a Kind | 24.0 | 14.8 | 3.8 | 8.0 | 0.02 |

Both access modes above use seeds 10,001–10,250. Supplying the core gives an opening upgrade, one bonus, and one joker. The draft has to find and afford them. On the first 100 of these seeds, the High Die policy bought One-man Band by the end of biome two in 25 runs and never bought it in 34. Improving access is worth testing before increasing its payout again, given the 95.2% win rate when the core starts assembled.

In 36 of 2,000 drafted Five of a Kind runs, the losing round included a four-match chase and ended without a five. In 5 losses the policy scored a five in the losing round. On 500 paired seeds, spending spare rerolls on a completable four increased the signature share from 3.8% to 7.4% and wins from 26.2% to 26.6%. Keep the rare-hand payouts and defer the free-reroll joker. The low signature share still warrants a player test of the choice to cash Four of a Kind or chase the fifth die.

With five ordinary dice and an optimal choice of which dice to hold, the chance to make Five of a Kind before the first play is 0.08% on the opening roll and 10.06% with three manual rerolls. Four of a Kind reaches 44.80% under the same budget. These are exact probabilities for pursuing each hand separately. Upgrades change the face distribution in an actual run. [Selection odds calculation](selection_odds.py)

## Other ways to build

| Draft policy | Seeds | Boss 4 % | Win % | Win 95% CI | Effect coins / run | Manual rerolls / run |
|---|---:|---:|---:|---:|---:|---:|
| held | 2000 | 88.8 | 22.5 | 20.7–24.4 | 16.6 | 6.3 |
| odd | 250 | 94.0 | 54.0 | 47.8–60.1 | 14.5 | 4.8 |
| even | 250 | 90.0 | 41.6 | 35.7–47.8 | 15.9 | 5.1 |
| ones | 250 | 94.4 | 57.2 | 51.0–63.2 | 10.1 | 4.8 |
| sixes | 250 | 93.6 | 47.6 | 41.5–53.8 | 14.4 | 5.1 |
| diversity | 250 | 85.6 | 52.4 | 46.2–58.5 | 16.0 | 5.7 |
| sum15 | 250 | 95.2 | 51.2 | 45.0–57.3 | 14.4 | 5.0 |
| save rolls | 250 | 83.2 | 36.0 | 30.3–42.1 | 11.1 | 3.9 |
| spend rolls | 250 | 90.0 | 43.2 | 37.2–49.4 | 15.8 | 22.3 |
| repeat | 250 | 88.0 | 28.0 | 22.8–33.9 | 13.9 | 8.4 |
| switch | 250 | 96.4 | 56.8 | 50.6–62.8 | 16.9 | 7.3 |
| tempo | 250 | 94.0 | 59.2 | 53.0–65.1 | 15.8 | 10.0 |
| economy | 2000 | 72.0 | 14.6 | 13.1–16.2 | 53.6 | 7.1 |
| refresh | 250 | 79.2 | 29.2 | 23.9–35.1 | 52.6 | 18.3 |
| portfolio | 2000 | 71.2 | 12.2 | 10.9–13.8 | 51.6 | 6.9 |

These policies include exact-sum selection, repeated or switched hands, history-dependent upgrades, paid refreshes, and portfolio growth. Effect coins count play and manual-reroll income. Sale proceeds and ordinary round rewards are accounted for by the shop and run sessions. Use the individual-effect removal comparisons to inspect the contribution of an allowance, bonus or joker while retaining the same slot and upgrade faces.

On seeds 10,001–10,100, the held policy left at least one die out on 2,443 of 2,712 plays. A preserved die became a scoring member on the next play 389 times, counting each die separately. The tempo policy used a fourth play on 113 round clears. The reroll-spending policy cleared 197 rounds after using more than three manual rerolls. These counts measure when the extra resources were actually spent.

The portfolio policy finished those 100 runs with 68.7 coins on average. It first bought Nest Egg in biome one or two on 25 runs, and went the entire run without buying it on 32. Alongside its 12.2% win rate in the larger cohort, this makes the timing and choice of purchases a higher priority for the next economy test than a larger coin grant.

### What individual items contributed

Each row replays the same 50 seeds with a supplied core on the live curve and disables one item's reward. The item still costs the same, takes up its slot, and keeps its die faces. Results count wins out of 50.

| Build | Effect tested | Wins with effect | Wins with effect disabled |
|---|---|---:|---:|
| Held dice | Bench Warmers | 21 | 1 |
| Held dice | Power Reserve | 21 | 7 |
| Sum 15 | Bean Counter | 26 | 13 |
| Repeated hands | Echo | 9 | 2 |
| Extra plays | Overtime | 37 | 26 |
| Economy | Stonks | 21 | 3 |
| Shop refreshes | Roulette | 29 | 3 |
| Portfolio | Nest Egg | 9 | 0 |

## Human playtest

Use matched opening seeds and compare normal shop access with the supplied core. In biomes three through five, record whether players can recognize and afford a purchase that advances their plan. For High Die, record the biome where One-man Band arrives. For straights and matching hands, record the visible safe hand, remaining rerolls, chosen action and eventual clear. For economy, record which purchase the additional income enabled. These observations distinguish a hard-to-find build from one that lacks scoring power after assembly. Player difficulty and the remaining relative win-rate gaps need this check.
