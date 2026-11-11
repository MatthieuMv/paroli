# Balatro — run mechanics and player actions

Scope: unmodded **1.0.1 ruleset**; desktop action names, platform-independent mechanics. Every gameplay action category and run branch; individual card effects grouped by operation, not a full card catalogue. Defaults below change with deck, stake, challenge, vouchers, Jokers and bosses.

## 1. Complete run flow

```text
Profile → Continue saved run OR Configure new run
  → Ante: Small Blind → Big Blind → Boss Blind
      Small/Big: Play OR Skip → receive Tag → next Blind
      Play → draw → [inspect / arrange / manage / discard / play] loop
          target reached → round settlement → Cash Out → Shop
          resources exhausted below target → eligible rescue OR Game Over
      Shop → [buy / use / sell / reroll / open pack] loop → Next Round
      Boss cleared → next Ante; Ante 8 cleared → WIN
  WIN → stop OR Endless → same loop until loss/abandonment
  Any run → pause / save-and-exit / resume / restart / abandon
```

No opponent, betting, folding, combat turns or time limit. “Blind” means score target plus optional restriction. Skipping bypasses both round and its shop. Ante 8 victory permits endless continuation. [Official FAQ](https://www.playbalatro.com/faq), [Skipping](https://teemo.dev/game-design/balatro/wiki/mechanics/skipping/).

## 2. Before starting

| Player action | Consequence / choice |
|---|---|
| Select/manage profile | Separate saves, collection, unlocks, statistics. |
| Inspect collection, records, unlock conditions | Learn available cards, decks, stakes, challenges. |
| Change settings | Speed, audio, display, accessibility, language, card appearance; cosmetics do not change card rules. |
| Continue | Resume saved run; no fresh setup. |
| New Run | Select unlocked deck and stake; inspect modifiers. |
| Enter seed or leave random | Reproduce a random sequence; outcomes still depend on actions, version and available content. Manual seeds disable normal unlock progression. |
| Select Challenge | Prescribed deck/items/rules/bans; separate completion track. |
| Start | Initialize run; initial shuffle/deal occurs on entering first Blind. |

Normal runs unlock content and higher stakes per deck; challenges unlock after wins with five decks. Twenty challenges; challenge/seeded runs do not grant ordinary discoveries or stake progression. Profile progress survives run termination; money/build do not. [Progression](https://teemo.dev/game-design/balatro/systems/unlocks-and-challenges/).

### Setup modifiers

**Baseline:** 52 cards; $4; 4 hands/round; 3 discards/round; hand size 8; 5 Joker slots; 2 consumable slots; poker hands start level 1.

**Decks:** Red +1 discard; Blue +1 hand; Yellow +$10; Green alternate payout/no interest; Black +1 Joker slot/−1 hand; Magic Crystal Ball +2 Fools; Nebula Telescope/−1 consumable slot; Ghost shop Spectrals +Hex; Abandoned no face cards; Checkered Hearts/Spades only; Zodiac Tarot Merchant/Planet Merchant/Overstock; Painted +2 hand size/−1 Joker slot; Anaglyph Double Tag after bosses; Plasma balances Chips/Mult, doubles targets; Erratic random ranks/suits.

**Cumulative stakes:** White baseline → Red no Small Blind reward → Green faster target growth → Black possible Eternal Jokers → Blue −1 discard → Purple faster growth again → Orange possible Perishable Jokers → Gold possible Rental Jokers.

**Stickers:** Eternal cannot sell/destroy; Perishable debuffs after five active rounds; Rental costs $1 upfront, $3/round. [Decks, stakes, stickers](https://teemo.dev/game-design/balatro/systems/stakes-decks-and-stickers-rules/).

## 3. Actions available across phases

At stable decision points, where relevant controls are enabled:

| Action | Mechanical purpose |
|---|---|
| Inspect card/Joker/consumable/voucher/tag/boss | Read effect, price, sell value, counters, restrictions. |
| Open Run Info | Inspect hand levels/use counts, blinds, tags and acquired vouchers. |
| Inspect deck | Compare full composition with remaining cards; hidden draw order remains unknown. |
| Select/deselect cards; clear selection | Prepare play, discard or targeted consumable; selection alone spends nothing. |
| Sort hand by rank/suit; drag cards | Control played/held trigger order and positional targets. |
| Drag Jokers | Control trigger/copy order and positional effects. |
| Reorder consumables | Organize inventory. |
| Use held consumable | Requires valid context/targets and any required space. |
| Sell owned Joker/consumable | Gain money, free slot, trigger sale effects; Eternal Jokers excluded. |
| Pause/options; menu/quit; continue | Suspend/resume saved run. |
| New run/restart | Abandon current build; desktop hold-R quick restart. |

No normal manual save-slot selection, undo, direct deck reorder, standalone “draw” button, or direct sale of playing cards/vouchers/tags. Effects perform deck removal, copying and drawing. Scoring animations resolve automatically. [Controls](https://teemo.dev/game-design/balatro/systems/controls-and-hand-building-interface/).

## 4. Blind selection

1. **Inspect:** current target/reward, upcoming boss, both skip tags; assess money/build.
2. **Manage:** reorder/sell Jokers; use/sell eligible consumables before entry.
3. **Select Blind:** commit; apply entry effects/boss restrictions; shuffle surviving deck; reset round score/hands/discards; draw opening hand.
4. **Skip Small/Big:** accept displayed tag; no play, payout or ordinary shop. Tags may resolve immediately, open a pack, modify a future shop, or wait for a trigger; no manual activation button.
5. **Reroll boss, if enabled:** Director’s Cut $10 once/ante; Retcon $10 repeatedly; Boss Tag replaces automatically. Cannot skip Boss Blind. [Blind rules](https://teemo.dev/game-design/balatro/systems/blind-targets-and-ante-scaling/).

Skipping advances position but is not a played round: round-based scaling, expiry and income generally require playing. Double Tags duplicate eligible future tag rewards; pack tags enter the pack-selection flow. [Tags/skip](https://teemo.dev/game-design/balatro/wiki/mechanics/skipping/).

## 5. Inside a Blind: repeat until resolved

| Player action | Cost → resolution |
|---|---|
| Inspect and plan | Compare accumulated score/target, available hands/discards, current hand and remaining deck. |
| Select 1–5 cards | Preview detected hand and base values; preview is not full final Joker-adjusted score. |
| Rearrange selected/held cards and Jokers | Set scoring order; set copying/leftmost/rightmost targets. |
| Use consumable | Resolve immediately; may change hand, deck, hand level, money or Jokers. |
| Sell Joker/consumable | Fund effects, free space, alter conditions; selling Luchador during boss disables boss ability. |
| Discard selected cards | Spend one discard, regardless of count; resolve discard effects; draw replacements. |
| Play selected cards | Spend one hand; resolve hand/boss/effects/scoring; add score to round total. |
| Play unwanted cards | Uses a hand to cycle cards when conserving/out of discards; may still score or trigger effects. |

Played/discarded cards leave circulation for this round; no ordinary mid-round reshuffle. Surviving cards return next round. Refill normally restores hand size, limited by remaining deck and effects. Unplayed cards stay held. Permanent destruction differs from discard.

After play: target met → round ends immediately; otherwise refill and continue if possible. No choice to keep farming after meeting target. Reaching target on final hand still wins. [Gameplay](https://balatrogame.fandom.com/wiki/Gameplay_rules), [Hands and scoring](https://teemo.dev/game-design/balatro/systems/hands-blinds-and-scoring-reference/).

### Hand recognition and scoring

Highest recognized category wins, regardless of which hand level would score more:

`High Card < Pair < Two Pair < Three of a Kind < Straight < Flush < Full House < Four of a Kind < Straight Flush < Five of a Kind < Flush House < Flush Five`

Royal Flush is a Straight Flush label. Aces allow low/high straights, not wraparound. Jokers can change recognition. Only participating cards normally score; Stone/Splash are exceptions. Non-scoring cards still leave hand and trigger applicable “played” effects.

Simplified automatic order:

1. Detect hand; resolve boss checks and before-scoring effects; obtain level-adjusted base Chips/Mult.
2. Score participating cards left→right: rank chips, modifiers, card-triggered Jokers, retriggers.
3. Resolve held-card effects left→right, including retriggers.
4. Resolve main Joker effects left→right; apply relevant editions/other effects.
5. Finalize Chips × Mult; add to round total; resolve after-play changes/destruction.

Order matters **within trigger stages**; repositioning cannot change stages. Debuffed cards usually retain recognition rank/suit but lose scoring effects. [Scoring order](https://teemo.dev/game-design/balatro/systems/hand-detection-and-scoring-order/).

### Boss-driven decisions

Bosses can force five-card plays, forbid repeated hand types, restrict to one hand type, remove discards, reduce hands/hand size, force selection, hide cards/Jokers, debuff suits/faces/previously played cards, lower hand levels, tax plays, discard held cards, alter draws, halve bases or raise targets. Responses: adapt selection/order, preserve alternatives, reroll beforehand, disable ability, or accept penalty. Invalid boss-constrained plays can consume a hand for zero score.

Verdant Leaf specifically rewards selling a Joker; Amber Acorn makes tracking shuffled Jokers relevant; Cerulean Bell forces a card into selection. Chicot disables boss abilities automatically. [Boss reference](https://teemo.dev/game-design/balatro/systems/blind-targets-and-ante-scaling/).

## 6. Consumables and permanent build changes

| Item / action | Scope |
|---|---|
| Tarot: select targets, then Use | Enhance, change suit/rank, copy, destroy; other Tarots generate money/cards/Jokers or modify Joker editions. |
| Planet: Use | Permanently level associated hand for this run; hidden-hand planets enter pool after that hand is played. |
| Spectral: Use/choose targets where required | Strong transformations: seals, editions, cloning, creation, destruction; often sacrifice money, cards, Jokers or hand size. |
| Generate item | Requires appropriate inventory capacity unless effect explicitly bypasses it; generation may be random. |
| Retain versus use/sell | Preserve future options versus immediate power/money/space. |

Target count/context is card-specific; e.g. Death needs two selected cards and copies **right into left**, so reorder first. Pack consumables normally resolve immediately; held consumables can wait. [Consumables](https://balatrogame.fandom.com/wiki/Consumables), [Consumable reference](https://teemo.dev/game-design/balatro/systems/tarot-planet-and-spectral-cards-reference/).

Playing cards can hold **one enhancement + one edition + one seal**; replacing one layer preserves others:

| Layer | Effects |
|---|---|
| Enhancements | Bonus +Chips; Mult +Mult; Wild all suits; Glass ×Mult/break risk; Steel held ×Mult; Stone rankless/suitless Chips; Gold held end-round money; Lucky chance of Mult/money. |
| Editions | Foil +Chips; Holographic +Mult; Polychrome ×Mult. Negative on eligible inventory items adds a corresponding slot. |
| Seals | Red retriggers; Gold money when scored; Purple Tarot when discarded; Blue last-played-hand Planet when held at round end, if space. |

Rank/suit edits, copying, creation and destruction change future draw probabilities. Debuff suppresses effects without removing modifications. [Card modifiers](https://teemo.dev/game-design/balatro/systems/enhancements-editions-and-seals-rules/).

## 7. Round end and cash-out

**Automatic:** resolve held end-round effects, Joker rewards/scaling/expiry/rental, generated consumables and boss-clear effects; calculate payout. Player then selects **Cash Out**.

Baseline payout: **blind reward + $1 per unused hand + interest + applicable bonuses**. Rewards: Small $3, Big $4, regular Boss $5, showdown Boss $8. Red+ removes Small reward only. Interest: $1 per $5 held, capped $5; $25 bank reaches default cap. Unused discards pay nothing normally; Green Deck replaces interest with $2/unused hand + $1/unused discard. Vouchers/Jokers modify economy; negative balance alone is not defeat. [Money and settlement](https://teemo.dev/game-design/balatro/systems/money-payouts-and-interest/).

## 8. Shop: actions in any legal order

| Player action | Result / constraint |
|---|---|
| Inspect offers/inventory | Assess price, effects, slots and spending budget. |
| Buy Joker | Add if capacity permits; effect may begin immediately. |
| Buy consumable | Store if capacity permits. |
| Buy & Use consumable | Resolve directly when legal; no need to reserve a storage slot. |
| Buy playing card, when offered | Add permanently to deck. |
| Redeem voucher | Permanent run modifier; no inventory slot. |
| Buy/open booster | Pay, then enter pack decision; cannot inspect contents beforehand. |
| Sell/use/reorder inventory | Raise funds, free slots, trigger effects, improve next purchase. |
| Reroll | Replace ordinary card offers; default $5, +$1 per paid reroll this shop; effects alter cost/free rolls. |
| Next Round | Leave; unbought card/pack offers lost; proceed to Blind selection. |

Purchases require sufficient spendable money; Credit Card permits debt to its limit. Purchases are optional; leaving costs nothing.

Default stock: two ordinary cards, two packs, one voucher. Rerolls do not refresh packs/vouchers. Voucher remains until purchased or next ante; buying normally leaves its slot empty until refresh. Ordinary slots contain Jokers/Tarots/Planets; Ghost enables Spectrals, Magic Trick enables playing cards. First shop guarantees a Buffoon Pack. [Shop](https://teemo.dev/game-design/balatro/wiki/mechanics/shop/), [Generation/prices](https://teemo.dev/game-design/balatro/systems/shop-generation-and-prices/).

### Opened booster: nested choice

| Pack | Selection outcome | Normal / Jumbo / Mega |
|---|---|---|
| Standard | Add playing card to deck | Take 1/3; 1/5; 2/5 |
| Buffoon | Add Joker; requires capacity | Take 1/2; 1/4; 2/4 |
| Arcana | Use Tarot immediately; temporary drawn hand supports targets | Use 1/3; 1/5; 2/5 |
| Celestial | Use Planet immediately | Use 1/3; 1/5; 2/5 |
| Spectral | Use Spectral immediately; temporary hand where applicable | Use 1/2; 1/4; 2/4 |

Actions: inspect options → manage eligible inventory/targets → select → resolve → repeat if choices remain; **Skip** forfeits remaining picks, no refund. Mega permits one pick then skipping second. Pack consumables have no ordinary “store for later” action.

Rare Soul/Black Hole can substitute into eligible packs. After completion return to shop, or Blind selection for tag-opened packs. [Booster packs](https://balatrogame.fandom.com/wiki/Booster_Packs).

## 9. Victory, defeat, continuation

| Condition | Outcome / player actions |
|---|---|
| Clear ordinary boss | Advance ante; repeat loop. Ante-reduction vouchers can extend path. |
| Clear Ante 8 boss | Record victory; inspect results/seed; return to menu/start another run, or choose Endless. |
| Endless | Preserve build; rapidly escalating targets; showdown every eighth ante. Later defeat does not revoke recorded win. |
| No hands left below target | Lose, unless eligible Mr. Bones prevents death at ≥25% target and destroys itself; rescued round forfeits blind reward. |
| No usable hand/cards remain below target | Can end run despite remaining hands; zero effective hand size also loses. Mr. Bones is not reliable protection against card exhaustion. |
| Game Over | Inspect results/seed; start new run or return to menu. No standard revive purchase or retry-current-Blind button. |
| Restart/abandon | Discard run state; setup again. |

Win condition: **clear Ante 8**, not merely reach it. Ordinary score is cumulative within a Blind, resets next Blind; overkill does not carry. [Official FAQ](https://www.playbalatro.com/faq), [Endless and targets](https://teemo.dev/game-design/balatro/systems/blind-targets-and-ante-scaling/), [Mr. Bones exhaustion caveat](https://www.reddit.com/r/balatro/comments/1nlsscv/).

## 10. Decision structure

- **Route:** round income/shop/scaling versus skip-tag benefit.
- **Hand:** score now versus cycle cards, grow effects, earn money, preserve held bonuses.
- **Order:** maximize trigger chains; position copying, destruction and transformation targets.
- **Build:** immediate survival versus scaling; specialization versus boss resilience.
- **Economy:** spend versus interest; buy certainty versus reroll/pack uncertainty.
- **Capacity:** retain versus sell/use; temporary power versus permanent slots/stickers.
- **Risk:** known target/resources versus hidden draws, shop rolls and probabilistic effects.
- **Horizon:** Ante 8 victory, unlock objective, or endless score require different investments.
