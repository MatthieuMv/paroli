# Paroli — Game Design Document

- Production stage: Concept exploration; framing and coverage established in part, now exploring the smallest complete experience (methodology steps 1–3).
- Document owner: Project creator (design owner); Codex assists with drafting.
- Last substantive review: 2026-11-01.
- Current summary: Paroli is a game inspired by Balatro for a similar audience, aiming for fewer things to manage, easier comprehension, and a softer UI without reducing punishment. Dice are confirmed as the core objects: select dice to validate or reroll, with a provisional baseline of 3 validations and 3 rerolls per round, modifiable by upgrades or the starter (D-005). Each round starts at zero score with restored action allowances; unused validations convert to bonus coins and unused rerolls are discarded (D-021). Only manual rerolls consume the reroll allowance; the initial roll and automatic post-validation rerolls are free. Other Yahtzee rules remain unselected. The central pleasure is building combinations that create anticipation, then pushing luck to experience the payoff of a planned strategy (D-003). Builds are intended to influence both the value of desired outcomes and the chance of reaching them (D-004). After validation, validated dice are rerolled and other dice are kept (D-005). Validations add to a cumulative round score; reaching or exceeding the target immediately ends the round successfully (D-006). Failing a round immediately ends the run and loses the current build (D-007). The baseline pool contains five dice (D-008). Proposed build families are die upgrades, die bonuses, and Jokers (D-009–D-011). Major upgrades are chosen from three offers at run start and biome starts, applied automatically in die order, and permanently committed (D-012). The opening choice is biome 1’s upgrade; the next choice occurs on entering biome 2. Upgraded dice can still receive bonuses without changing their major upgrade or upgraded faces. Bonuses are unique across the dice set; owned bonuses and Jokers are excluded from offers. Each die has one permanent upgrade slot and one movable bonus slot (D-012–D-014). The baseline has four movable Joker slots (D-011). Bonuses are player-placed and movable into free bonus slots only outside rounds; placement is fixed during a round; bonuses and Jokers can be bought or sold in shops between non-boss rounds, with repeatable whole-shop rerolls at increasing coin costs and discounted random purchases (D-014–D-015). A full run has five biomes, each with an upgrade choice, two regular rounds with a shop after each, and a boss: five upgrades, ten shops, and fifteen rounds total (D-016). No shops follow bosses. Economy tuning is deferred. Score targets increase every round, including regular rounds, and bosses add a special rule challenging the build, revealed at biome start after the upgrade choice and before the first regular round (D-017). Validation scores the highest-ranked recognized combination by default; explicit Joker effects may allow combinations to score together (D-018). D-018 defines nine ranked categories from Single die through Five of a kind. Validation score is final points × final Mult, starting from the recognized combination’s base values, adding face points only from dice forming that combination, and applying eligible effects; die bonuses and upgrades apply to validated dice by default, with combination membership required only when stated and held-die effects explicitly labeled (D-019). Scoring effects add independently to points and flat Mult; percentage Mult increases sum into one factor applied after flat Mult, so evaluation order does not change the score. High-risk effects may yield zero or negative results; the signed result is visible, but only max(0, result) is credited to the round total. Detailed recognition, effect timing, remaining numeric bounds and values, specific boss rules, completion presentation, and between-run persistence remain open.
- Presentation priority: Selection shows the recognized combination and its unmodified base values, plus visual activation cues; no final-score or target-clear preview. The final result is revealed only after commitment and completion of the scoring animation (D-023).
- Readiness: Not an implementation specification. No playable design or validated player-experience claims yet.

## Sources and working method

- [Game design methodology](GAME_DESIGN_METHODOLOGY.md): authoritative document process and Why / How / What contract.
- [Balatro analysis](BALATRO_ANALYSIS.md): supplied reference, scoped to its stated ruleset; a source of mechanisms to examine, not Paroli requirements. Its linked external sources have not been independently verified during this drafting session.
- [Repository README](../README.md): existing dice deck-builder / Yahtzee concept.
- Creator brief, 2026-10-30: Balatro inspiration, similar audience, softer UI, simplified mechanics, explicit rejection of a clone or automatic one-to-one inheritance.
- Creator clarification, 2026-10-30: “More accessible” means fewer things to manage and easier to understand, but not less punishing.

- Creator clarification, 2026-10-30: The main pleasure comes first from building combinations to create anticipation, then pushing luck for the excitement of a planned strategy paying off.

- Creator clarification, 2026-10-30: Builds should influence both payoff and odds: make a desired outcome valuable, then improve the chances of reaching it.

- Creator clarification, 2026-10-30: Select dice to either validate them or roll them, inspired by Balatro’s in-round actions; validation and rolling have fixed allowances that upgrades or the starter can change.

- Creator clarification, 2026-10-30: After validation, validated dice are rerolled; the other dice are kept.

- Creator clarification, 2026-10-30: Each validation adds to cumulative score; the round objective is to reach a target before validations run out.

- Creator clarification, 2026-10-30: Failing a round immediately ends the run and loses the current build.

- Creator proposal, 2026-10-30: Five total dice; three build families with distinct power, stacking, and face-editing rules, plus nine illustrative effects. The comparison to per-card effects in a 52-card deck is a design rationale to investigate, not balance evidence.

- Creator instruction, 2026-10-30: Choose a first major upgrade at game start to guide strategy, then a new upgrade at each biome start until all five dice are upgraded. Choose between three upgrades; apply automatically to the next non-upgraded die in order. An upgraded die cannot be replaced or changed through the end of the game. This document interprets “game” here as the current run, consistent with D-007; persistent unlocks remain separate.

- Creator clarification, 2026-10-30: The opening choice counts as biome 1’s upgrade; the next upgrade choice occurs upon entering biome 2.

- Creator clarification, 2026-10-30: An upgraded die can still receive bonuses while its upgraded faces remain unchanged.

- Creator clarification, 2026-10-30: Each bonus is unique across the set; an already-applied bonus or Joker cannot appear in choices. Stackable means multiple different bonuses on one die alongside its upgrade. Proposed limit: three bonuses per die.

- Creator revision, 2026-10-30: Players choose bonus targets and may move bonuses to another die with a free slot. Only major die upgrades are non-removable. Shops between non-boss rounds of a biome allow buying/selling bonuses and Jokers, a paid whole-shop reroll mechanism (later clarified as repeatable), and discounted random Joker or bonus purchases. Economy balance is explicitly deferred.

- Creator clarification, 2026-10-30: Bonuses can be rearranged outside rounds. In-round relocation is not allowed; this timing clarification retains the previously stated free-slot rule.

- Creator clarification, 2026-10-30: Whole-shop rerolls are repeatable, with each successive reroll costing more coins. Exact economy values remain deferred.

- Creator instruction, 2026-11-01: Five biomes for five die upgrades; each biome contains two regular rounds and a boss round. A shop follows each regular round; after a non-final boss, proceed to the next die upgrade instead. Full-path totals: five upgrades and ten shops.

- Creator instruction, 2026-11-01: Targets increase from every round to the next, including regular rounds. Bosses combine a higher target with a special rule challenging the build.

- Creator clarification, 2026-11-01: Reveal the biome’s boss rule at biome start, after the player chooses its permanent die upgrade.

- Creator confirmation, 2026-11-01: By default a validation scores one combination; the highest combination takes precedence over the others, as in the supplied Balatro reference. Explicit Joker effects may permit combination stacking.

- Creator confirmation, 2026-11-01: Accepted the proposed nine-category order, from Single die through Five of a kind, recorded authoritatively in D-018. Straight lengths and score values were explicitly left open.

- Creator clarification, 2026-11-01: A short straight requires four consecutive values. Remove the proposed Straight with pair Joker example; the creator no longer wants it in the catalog.

- Creator confirmation, 2026-11-01: Validation uses points × Mult; the recognized combination provides base values modified by dice and effects. Die bonuses may also work independently of the combination, with a “lone wolf” concept as an illustration rather than a complete trigger specification.

- Creator clarification, 2026-11-01: Participation requirements depend on the individual die bonus or upgrade effect. “6: +X points if part of a combination” requires combination membership; “6: +X points” does not impose that membership requirement. Validated-versus-held scope remains to be defined.

- Creator confirmation, 2026-11-01: Validated dice are the implied scope of die effects. Held-die activation must be stated explicitly, for example “+X points if in hand.”

- Creator proposal, 2026-11-01: Face-conditioned bonuses should tend toward points for higher faces and Mult for lower faces, to add depth and help distribute effects. This is a proposed design tendency, not evidence of balance or a decision about automatic face-value scoring.

- Creator confirmation, 2026-11-01: Only dice forming the validated combination add their face values to points. Validating 4–4–6 as Pair adds 8 face points (4 + 4) to the combination’s base points; the 6 adds no automatic face points.

- Creator clarification, 2026-11-01: Scoring effects add to points and Mult separately, then the final score is their product; order should not matter. The supplied Balatro analysis also describes multiplicative Mult effects, so this additive-only rule is a Paroli choice, not identical Balatro behavior.

- Creator decision, 2026-11-01: High-risk/high-reward effects may reduce Mult to zero. Zero Mult produces zero validation score; behavior when the additive Mult total is negative remains unresolved.

- Creator decision, 2026-11-01: Show a negative scoring outcome to the player, but do not subtract it from previously earned round score. Preserve the signed calculation and floor only the credited round contribution at zero.

- Creator decision, 2026-11-01: Begin with three validations and three rerolls per round for the baseline starter. Treat both counts as provisional and balance them later alongside round score targets.

- Creator confirmation, 2026-11-01: Only manual rerolls decrement the reroll counter. The initial roll and automatic rerolls after validation do not consume reroll uses.

- Creator confirmation, 2026-11-01: Each round starts with zero score and restored action allowances; unused actions do not carry over. Unused validations convert to bonus coins for shopping. Conversion values are deferred with economy balancing.

- Creator confirmation, 2026-11-01: The round ends immediately when a validation reaches or exceeds its target; unused validations then convert to bonus coins under D-021.

- Creator confirmation, 2026-11-01: Short straight requires four consecutive values; Long straight requires five consecutive values; Single die uses the highest-valued validated die.

- Creator acceptance, 2026-11-01: Use the D-022 combination balance table as the starting values for now. All nine base-point and base-Mult pairs are accepted for prototype exploration, remain tunable, and are not playtest-validated.

- Creator revision, 2026-11-01: Reverse All or nothing’s signs: a 1 adds Mult and a 6 subtracts Mult. In Paper round 01, the temporary magnitude remains 3. The creator liked the walkthrough; this is design feedback, not a balance playtest.

- Creator decision, 2026-11-01: Preserve anticipation by withholding the final score until commitment and completion of the scoring animation. Preview only the recognized combination and its base score, with shine sweeps on eligible bonuses/Jokers and bespoke themed activation effects for die upgrades. Manual calculation remains possible but is not encouraged through computed previews.

Decision status, section maturity, and evidence confidence follow the methodology and are independent. Review changed decisions each design conversation and after relevant prototype evidence; calendar cadence remains unresolved until production planning.

## Decision register

| ID | Decision | Owner | Status | Authoritative location |
| --- | --- | --- | --- | --- |
| D-001 | Accessibility and independent design direction | Project creator | Accepted | [Section 01](#d-001-accessibility-and-independent-design-direction) |
| D-002 | Explore the dice / Yahtzee premise (superseded by D-005) | Project creator | Superseded | [Section 04](#d-002-explore-the-dice--yahtzee-premise) |
| D-003 | Build anticipation, then risk for a planned payoff | Project creator | Accepted | [Section 01](#d-003-build-anticipation-then-risk-for-a-planned-payoff) |
| D-004 | Builds influence payoff and odds | Project creator | Accepted | [Section 04](#d-004-builds-influence-payoff-and-odds) |
| D-005 | Select dice to validate or reroll with limited allowances | Project creator | Accepted | [Section 04](#d-005-select-dice-to-validate-or-reroll-with-limited-allowances) |
| D-006 | Reach a cumulative round score target within limited validations | Project creator | Accepted | [Section 04](#d-006-reach-a-cumulative-round-score-target-within-limited-validations) |
| D-007 | Round failure ends the run and loses the build | Project creator | Accepted | [Section 05](#d-007-round-failure-ends-the-run-and-loses-the-build) |
| D-008 | Five-die baseline pool | Project creator | Accepted | [Section 04](#d-008-five-die-baseline-pool) |
| D-009 | Powerful committed die upgrades | Project creator | Proposed | [Section 07](#d-009-powerful-committed-die-upgrades) |
| D-010 | Smaller accumulating die bonuses | Project creator | Proposed | [Section 07](#d-010-smaller-accumulating-die-bonuses) |
| D-011 | Slot-limited Jokers | Project creator | Proposed | [Section 07](#d-011-slot-limited-jokers) |
| D-012 | Permanent ordered upgrade choices at run and biome starts | Project creator | Accepted | [Section 06](#d-012-permanent-ordered-upgrade-choices-at-run-and-biome-starts) |
| D-013 | Unique owned bonuses and Jokers; bounded bonus accumulation | Project creator | Accepted | [Section 07](#d-013-unique-owned-bonuses-and-jokers-bounded-bonus-accumulation) |
| D-014 | Player placement and relocation of bonuses | Project creator | Accepted | [Section 07](#d-014-player-placement-and-relocation-of-bonuses) |
| D-015 | Between-round shops and acquisition options | Project creator | Accepted | [Section 06](#d-015-between-round-shops-and-acquisition-options) |
| D-016 | Five-biome run with two regular rounds and a boss per biome | Project creator | Accepted | [Section 03](#d-016-five-biome-run-with-two-regular-rounds-and-a-boss-per-biome) |
| D-017 | Rising round targets and boss-specific challenge rules | Project creator | Accepted | [Section 05](#d-017-rising-round-targets-and-boss-specific-challenge-rules) |
| D-018 | Highest-ranked recognized combination takes precedence | Project creator | Accepted | [Section 04](#d-018-highest-ranked-recognized-combination-takes-precedence) |
| D-019 | Combination-based points × Mult with independent die-bonus conditions | Project creator | Accepted | [Section 04](#d-019-combination-based-points--mult-with-independent-die-bonus-conditions) |
| D-020 | Higher-face point bonuses and lower-face Mult bonuses | Project creator | Proposed | [Section 07](#d-020-higher-face-point-bonuses-and-lower-face-mult-bonuses) |
| D-021 | Fresh round state and coins for unused validations | Project creator | Accepted | [Section 06](#d-021-fresh-round-state-and-coins-for-unused-validations) |
| D-022 | First-pass combination base values | Project creator | Accepted | [Section 04](#d-022-first-pass-combination-base-value-proposal) |

| D-023 | Base-only combination preview and animated score reveal | Project creator | Accepted | [Section 10](#d-023-base-only-combination-preview-and-animated-score-reveal) |

| D-024 | Equally likely die faces and independent rolls | Project creator | Accepted | [Section 04](#d-024-equally-likely-die-faces-and-independent-rolls) |

## Highest-impact unknowns and risks

Ordered by current dependency impact; this is a qualitative initial assessment, not measured evidence. Project creator owns each question; Codex prepares alternatives and records answers.

| ID | Question or assumption | Risk if wrong | Next action | Resolution gate |
| --- | --- | --- | --- | --- |
| Q-01 | Central pleasure resolved in D-003; payoff and odds influence resolved in D-004. Three build families proposed in D-009–D-011; how do they interact, and how do remaining pillars rank? | Simplification removes strategic preparation, or optimization removes uncertainty. | D-012 resolves upgrade commitment and allocation; D-013 resolves unique ownership and different-bonus stacking; D-014 resolves player targeting and relocation; movement is restricted to outside rounds; resolve trigger semantics; resolve remaining pillar priorities. | Before defining the core loop. |
| Q-02 | Dice selection and two limited actions confirmed in D-005. Post-validation rerolling of validated dice and retention of other dice are confirmed. Baseline counts are provisionally 3 validations and 3 rerolls per round. Only manual rerolls consume the reroll allowance. D-021 resolves score/action resets. What remaining selection and round-transition edge cases apply? | Copying card circulation or Yahtzee scoring adds unjustified complexity. | Define legal combinations, allowance accounting, and remaining lifecycle edge cases; examine familiar rules individually. | Before a complete paper-loop walkthrough. |
| Q-03 | What makes Paroli distinct beyond replacing cards with dice? | Balatro's structure is copied through renamed features. | Compare candidate loops against D-001. | Before selecting a prototype loop. |
| Q-04 | Can three build families and accumulating bonuses stay easy to manage? | Permanent effects can accumulate reading burden even without inventory manipulation. | Compare a developed five-die build with a simpler alternative; inspect effect visibility and trigger comprehension. | Before prototype scope is accepted. |
| Q-05 | D-006 defines round success/failure; D-007 establishes immediate run end and build loss on failure. What follows success, and what persists between runs? | Undefined reset boundaries accidentally preserve lost build power or erase unrelated progress. | D-016 resolves biome structure and shop/upgrade transitions. D-017 establishes boss differentiation; define specific boss rules, final completion flow, and persistence scope. | Before a complete session walkthrough. |
| Q-06 | Who specifically is the audience, and what must they already know? | Familiarity with poker or Yahtzee is mistaken for broad comprehension. | Define player motivations, knowledge, and play context. | Before recruiting concept playtests. |
| Q-07 | What does a softer UI mean visually and behaviorally? | Pleasant styling conceals poor readability or rule complexity. | Select presentation references and describe information priorities. | Before interface prototyping. |
| Q-08 | What are the platform, session, team, and commercial constraints? | The concept exceeds feasible scope or mismatches use context. | Establish constraints with the creator. | Before committing to a playable prototype. |

| Q-09 | D-018 selects highest-ranked recognition by default. The nine-category hierarchy is accepted. D-019 establishes points × Mult. Validated dice are the default effect scope, with explicit held exceptions. Scoring modifiers are additive and order-independent; zero and negative raw results are displayed, with nonnegative round credit. What are the remaining recognition, numeric representation, and overlap rules? | Examples imply a scoring system that has not been specified; negative Mult and overlap can produce unintended results. | Define remaining recognition details and participating-subset ties, scoring stages, trigger scope, exception overlap rules, and bounds before tuning X values. | Before scoring walkthroughs or balance claims. |

## Coverage and navigation

All 18 methodology areas are accounted for below. Unexplored entries are questions, not feature commitments. Their inclusion follows the methodology's coverage requirement; D-001 supplies the shared design context. No optional feature is considered accepted merely because its section exists.

## 01 — Vision, audience, and intended experience

- Applicability: Applicable.
- Rationale: Methodology coverage requirement; [D-001](#d-001-accessibility-and-independent-design-direction) establishes the shared frame. Specific applicability remains open where marked Undecided.
- Owner: Project creator.
- Maturity: Exploring.
- Summary and boundaries: D-001 records accessibility and independence; D-003 establishes building combinations before pushing luck as the central pleasure. Audience detail and remaining pillar priorities are open.
- Decision records: D-001 and D-003 below.
- Supporting specifications and evidence: Creator brief and clarification above.
- Dependencies and open questions: Q-01, Q-03, Q-06; resolve the frame before core-loop selection.

### D-001: Accessibility and independent design direction

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-10-30.
- Scope: Intended audience, cognitive burden, challenge, presentation, and evaluation of borrowed mechanisms.
- Links: Q-01, Q-03–Q-07; sections 03–07 and 10–12.

#### Why?
- Need or problem: The creator wants Balatro-inspired appeal with fewer things to manage and easier comprehension, while retaining punishment and an independent identity.
- Intended player outcome and connection to goals: Players can understand consequential decisions without managing an unnecessarily large collection of systems. D-003 establishes the central pleasure; remaining pillar priorities are unresolved under Q-01.
- Evidence and assumptions: The creator's brief and clarification on 2026-10-30 establish intent, not evidence of audience response. “Similar audience” remains an audience hypothesis; simplifying management without flattening depth is untested.
- Alternatives considered: Directly translate Balatro's systems; reduce difficulty to ease entry; or independently choose mechanisms around the intended experience. The brief rejects the first two as definitions of accessibility.
- Selected tradeoff, costs, and disadvantages: Reducing management may reduce combinatorial variety. Clearer presentation may reveal complexity that needs actual rule redesign. Retaining punishment may still deter some players.

#### How?
- Mechanism linking the choice to the intended outcome: Evaluate each candidate system by the meaningful choice it adds and the tracking or explanation it requires. Explore removing or combining low-value management tasks, and making the remaining choices understandable.
- Player actions, available information, and feedback: Unresolved — creator to identify essential decisions and the information needed to explain them before core-loop selection. Softer UI remains an intent, not an assumed palette or interaction model.
- System interactions and dependencies: Core rules, build systems, progression, UI, and challenge require joint review. Comprehension and punishment are separate design dimensions.
- Likely failure modes and safeguards: Shallow choices, friendly visuals masking opaque rules, or a renamed clone. Compare each proposal with simpler alternatives and omission; examine both comprehension and meaningful tradeoffs.

#### What?
- Exact scope: Adopt the creator's direction as a concept constraint. Every proposed borrowed system needs its own rationale under the methodology; Balatro's presence of a feature is not sufficient justification.
- Parameters: No quantitative complexity, difficulty, or session targets selected. Creator to set contextual criteria before testing a candidate loop.
- Content/data requirements and authoritative references: This record owns the accessibility intent; the supplied analysis describes Balatro only.
- Boundary conditions, exceptions, and recovery behavior: This decision does not select Balatro's exact punishment, loss rules, or difficulty curve. D-006 and D-007 separately establish round failure and its run-ending consequence; remaining session and persistence rules are tracked under Q-05. Broader disability access needs are not answered by reducing cognitive burden alone.
- Acceptance criteria: Given a candidate design, when reviewed against this brief, then its management demands and comprehension demands are identified separately from its challenge and loss consequences. Given a borrowed mechanic, when proposed, then its Why / How / What explains its value to Paroli and considers a simpler alternative or omission.
- Explicit exclusions: Automatic one-to-one inheritance of Balatro's systems; treating reduced punishment as the meaning of “more accessible.”

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: Fewer managed systems can preserve satisfying consequential choices. A candidate dominated by obvious choices, or still requiring substantial rule memorization, would count against that candidate's mechanism.
- Method: Compare candidate loops on paper, then test comprehension and decisions with players matching the defined audience.
- Success/failure criteria and why: Before testing, creator to define decision tasks and expected explanations. Assess whether players can explain options and consequences, and whether credible competing choices remain; numeric thresholds remain unresolved until the task and audience are defined.
- Evidence: Creator brief and clarification, 2026-10-30; no prototype or player evidence.
- Confidence: Untested.
- Open questions: Q-01, Q-03–Q-07; creator owns their next actions and gates in the index.
- Revisit trigger: Candidate simplification removes meaningful decisions, comprehension remains poor, or creator changes the intended audience or challenge direction.
- History: 2026-10-30 — recorded the brief and clarified accessibility without accepting specific mechanics.

### D-003: Build anticipation, then risk for a planned payoff

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-10-30.
- Scope: Central player experience and evaluation of future combination-building and risk mechanics; not a selected turn structure.
- Links: D-001, D-002; Q-01–Q-05; sections 03–07 and 10.

#### Why?
- Need or problem: The creator identifies building combinations as the primary pleasure, creating anticipation that pushing luck subsequently pays off.
- Intended player outcome and connection to goals: “I put this plan together; now I want to see it work.” Preparation gives the uncertain outcome personal meaning. Building combinations leads the experience; pushing luck serves its realization.
- Evidence and assumptions: Creator clarification on 2026-10-30 establishes intent. Whether players experience anticipation and attribute success to preparation is untested. The creator's “dopamine rush” describes desired excitement, not a measured physiological claim.
- Alternatives considered: Luck-pushing as the primary attraction; adaptation as the primary attraction; or combination-building followed by risk. The creator selected the third. Adaptation's supporting role remains unresolved.
- Selected tradeoff, costs, and disadvantages: Preparation takes attention and may delay the exciting moment. Strong combinations may remove uncertainty; excessive randomness may make preparation feel irrelevant. Both can undermine the intended relationship.

#### How?
- Mechanism linking the choice to the intended outcome: Players assemble interacting elements, anticipate a desirable result, and make decisions under uncertainty to pursue it. A successful resolution makes the contribution of their preparation understandable. This is an experiential sequence, not a commitment to separate build and roll phases.
- Player actions, available information, and feedback: At concept level, assemble a combination, recognize what would make it work, and choose whether or how to pursue that outcome. Exact actions, visible probabilities, and feedback remain unresolved — creator to define them with the core loop.
- System interactions and dependencies: Combinations need a meaningful relationship to outcomes, risk decisions, and feedback. D-001 constrains how much state players must manage and understand. No shop, item family, scoring formula, or economy is implied.
- Likely failure modes and safeguards: Automatic success removes tension; arbitrary outcomes obscure preparation; intricate interactions exceed the accessibility intent. Evaluate candidate turns for understandable causal links, consequential choices, and remaining uncertainty.

#### What?
- Exact scope: Use “build combinations → anticipate their payoff → push luck to realize the plan → experience the result” as the central experience criterion for candidate loops. This does not prescribe when combinations are acquired or how often the sequence repeats.
- Parameters: No combination count, success probability, risk cost, or payoff magnitude selected. Creator to define candidate values and their rationale before a paper-loop test.
- Content/data requirements and authoritative references: This record owns the experience priority. Concrete combination types and their interactions require later decision records.
- Boundary conditions, exceptions, and recovery behavior: A planned payoff is not guaranteed. Failed attempts must be included in exploration; D-007 establishes run termination and build loss on round failure; other persistence boundaries remain Q-05. This direction does not require every outcome to activate a combination.
- Acceptance criteria: Given a candidate loop, when walked through, then the reviewer can identify preparation, the anticipated result, the consequential risk choice, and how preparation affects resolution. Given an unsuccessful attempt, when reviewed, then its consequences can be traced through the candidate rules. Given a successful attempt, then the combination's contribution is explainable. These are design-review checks, not evidence that players feel excitement.
- Explicit exclusions: Claiming a validated emotional or physiological effect; automatically adopting Balatro's build systems; equating this sequence with fixed gameplay phases.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: Players will connect anticipation and excitement to their own combination-building. Players unable to name the result they hoped for or explain how their preparation helped would count against the candidate mechanism.
- Method: Start with a concrete paper scenario; later observe representative players describing their intended outcome before a risk decision and reflecting on the result afterward, including failed attempts.
- Success/failure criteria and why: Seek understandable preparation-to-payoff connections and consequential risk choices, alongside player reports of anticipation and satisfaction. Creator to define the scenario, participant profile, and contextual thresholds before playtests; these are needed to distinguish design intent from evidence.
- Evidence: Creator clarification, 2026-10-30; no prototype or playtest evidence.
- Confidence: Untested.
- Open questions: Q-01 — D-004 resolves payoff and odds influence; creator to define concrete build elements before core-loop selection; Q-02 — D-005 confirms dice; resolve selection and allowance rules before a complete loop; Q-05 — D-007 establishes failure stakes; define success transitions and persistence before a complete session walkthrough.
- Revisit trigger: Combinations feel incidental to outcomes, preparation removes meaningful risk, or players cannot understand the connection within D-001's management constraints.
- History: 2026-10-30 — established the creator's experience priority without selecting its mechanics.

## 02 — Product boundaries and constraints

- Applicability: Applicable.
- Rationale: Methodology coverage requirement; [D-001](#d-001-accessibility-and-independent-design-direction) establishes the shared frame. Specific applicability remains open where marked Undecided.
- Owner: Project creator.
- Maturity: Unexplored.
- Summary and boundaries: Platforms, input, session duration, production scope, and constraints.
- Decision records: None yet.
- Supporting specifications and evidence: Repository README is context, not a platform specification.
- Dependencies and open questions: Q-08; creator to establish boundaries before prototype commitment.

## 03 — Player journey and game loops

- Applicability: Applicable.
- Rationale: D-016 establishes the full run route; D-005–D-007 govern round actions and outcomes.
- Owner: Project creator.
- Maturity: Exploring.
- Summary and boundaries: Five biomes with an opening upgrade, two regular rounds with shops, then a boss. Scoring, boss mechanics, onboarding, interruption, and completion presentation still require specification.
- Decision records: D-016 below; D-005–D-007 for round behavior; D-012 for upgrade choice; D-015 for shop actions.
- Supporting specifications and evidence: Creator instruction, 2026-11-01; no playable or playtest evidence yet.
- Dependencies and open questions: Q-02, Q-05, Q-09; resolve boss mechanics, round rules, and session transitions before a complete playable specification.

### D-016: Five-biome run with two regular rounds and a boss per biome

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Run length in encounters, ordered biome progression, shop placement, and upgrade-event count.
- Links: D-003, D-005–D-008, D-012, D-015; Q-05; sections 05, 06, 08, and 10.

#### Why?
- Need or problem: The creator wants five biomes corresponding to the five permanent die upgrades, with two regular rounds and a boss in each.
- Intended player outcome and connection to goals: A new upgrade develops the planned strategy at each biome entry; regular rounds and shops provide opportunities to use and support it before the biome's concluding boss. This supports D-003's preparation and anticipated payoff.
- Evidence and assumptions: Creator instruction, 2026-11-01, establishes the structure and totals. Whether this cadence provides satisfying pacing or adequate time with a fully upgraded set is untested.
- Alternatives considered: Different biome counts, more/fewer regular rounds, and shops after bosses. The creator selects five three-round biomes and shops only after regular rounds; alternatives have not been tested.
- Selected tradeoff, costs, and disadvantages: Predictable pacing simplifies navigation and gives a clear upgrade cadence, but may feel repetitive. All five upgrades are available only in the final biome, leaving three rounds to use the fully upgraded set. Shop access before bosses allows preparation; there is no post-boss shop.

#### How?
- Mechanism linking the choice to the intended outcome: For each biome, choose its die upgrade, reveal its boss rule under D-017, clear regular round 1, visit a shop, clear regular round 2, visit a shop, then face the boss. Clearing bosses 1–4 advances to the next biome's upgrade choice. Clearing boss 5 completes the specified run route.
- Player actions, available information, and feedback: Choose the upgrade under D-012, play rounds under D-005–D-006, and use shops under D-015. D-017 reveals the boss rule after the biome upgrade choice and before its first regular round. Exact route display, preview presentation, transition controls, and completion screen remain unresolved before UI specification.
- System interactions and dependencies: Any round failure ends the run under D-007, so later shops and upgrades are not reached. The first upgrade is biome 1's opening event; entering biome 2 supplies the second, with no duplicate opening choice.
- Likely failure modes and safeguards: An accidental post-boss shop creates extra shopping visits; an upgrade after the final boss creates a sixth upgrade. Verify full-route counts and explicitly terminate the route after boss 5.

#### What?
- Selected rules: Exactly 5 biomes in the specified run route. Each biome contains 2 regular rounds followed by 1 boss round. A shop follows each successfully completed regular round, including the one immediately before the boss. No shop follows a boss. Before biomes 1–5, perform that biome's upgrade choice under D-012. After bosses 1–4, transition to the next biome's upgrade; after boss 5, the specified route is complete, with no further upgrade or shop.
- Parameters: 5 biomes × 2 regular rounds = 10 regular rounds; 5 bosses; 15 total rounds; 10 shop visits; 5 upgrade choices/applications. These are full-path totals, conditional on reaching each event, not guaranteed rewards for a failed run. Counts are creator-specified or directly derived; no economic or score tuning is introduced.
- Content/data requirements: Ordered biome and round identifiers, round type, next transition, and associated boss content. D-017 establishes increasing targets and special boss rules. Biome themes, specific boss effects, target values, and the growth curve remain unresolved.
- Boundary conditions, exceptions, and recovery: Failure takes D-007's run-ending transition rather than the next shop or upgrade. The fifth upgrade occurs before biome 5's first regular round, not after the final boss. Restart, interruption/resume, terminal animation order, and final result presentation remain unresolved. No optional skips, branches, or endless continuation are selected.
- Acceptance criteria: Given success in either regular round, then the next phase is that biome's shop. Given success against boss 1–4, then the next phase is the following biome's upgrade choice, with no intervening shop. Given success against boss 5, then no sixth biome upgrade or eleventh shop is generated. Given a complete traversal, then counts are exactly 5 upgrades, 10 shops, 10 regular rounds, and 5 bosses. Given failure in any round, then no next route event is awarded.
- Explicit exclusions: Post-boss shops, a sixth upgrade, inferred boss modifiers, round skips, endless mode, or economy balancing.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: This cadence supports satisfying build growth and payoff within an acceptable session length. Repetitive pacing or insufficient play with late upgrades would count against it.
- Method: Trace the complete route and early failures, verify event totals, then playtest pacing once scoring and boss behavior exist.
- Success/failure criteria and why: Route traces must satisfy every count and transition case. Creator to define session-duration and experiential criteria before player tests; encounter counts alone do not establish good pacing.
- Evidence: Creator instruction, 2026-11-01; no prototype or playtest evidence.
- Confidence: Untested.
- Open questions: D-017 resolves boss differentiation. Boss reveal timing is also resolved in D-017. Creator to define specific rules, final completion presentation, and interruption behavior before a complete session specification. Economy balancing remains deferred.
- Revisit trigger: Session duration, repetitive pacing, or late-upgrade payoff conflicts with the intended experience.
- History: 2026-11-01 — established five biomes, three rounds per biome, shops after regular rounds only, and a total of five upgrade choices.

## 04 — Core rules, mechanics, and state

- Applicability: Applicable.
- Rationale: Methodology coverage requirement; [D-001](#d-001-accessibility-and-independent-design-direction) establishes the shared frame. Specific applicability remains open where marked Undecided.
- Owner: Project creator.
- Maturity: Exploring.
- Summary and boundaries: D-005 establishes selected-dice validation and rerolling with limited allowances. Validated dice reroll while other dice are kept. D-006 establishes cumulative scoring toward a round target. D-008 fixes the baseline pool at five dice. D-018 selects the highest-ranked recognized combination by default. D-018 also defines the nine-category hierarchy. D-019 defines combination-based points × Mult. Scoring effects add independently before the final product. The provisional baseline is three validations and three rerolls per round. Detailed recognition, effect timing, allowance-accounting edge cases, and lifecycle details remain open.
- Decision records: D-004, D-005, D-006, D-008, D-018, D-019, and D-022 below; D-002 retained as superseded history.
- Supporting specifications and evidence: README; methodology purpose; supplied Balatro analysis as comparison.
- Dependencies and open questions: Q-02; creator to resolve remaining dice lifecycle details and combination rules before a complete paper-loop walkthrough.

### D-002: Explore the dice / Yahtzee premise

- Status: Superseded.
- Replacement: D-005 confirms dice and selects the action model; other Yahtzee rules remain unselected. Historical proposal retained below.
- Owner: Project creator.
- Updated: 2026-10-30.
- Scope: Core activity and relationship to familiar dice rules.
- Links: D-001; Q-01–Q-03; sections 03 and 05.

#### Why?
- Need or problem: The README describes a dice deck-builder roguelike based on Yahtzee; the methodology explicitly calls this a starting hypothesis.
- Intended player outcome and connection to goals: Potentially offer understandable manipulation of chance and recognizable patterns in support of D-001. This is a candidate benefit, not a confirmed pillar.
- Evidence and assumptions: Repository documents inspected 2026-10-30. Familiarity, enjoyment, and reduced cognitive burden for the target audience are untested assumptions.
- Alternatives considered: Retain a familiar dice loop; borrow only selected dice-pattern ideas; or reconsider the premise if it does not serve the intended experience.
- Selected tradeoff, costs, and disadvantages: Propose exploring the existing premise first, without fixing it. Familiar rules may bring unwanted bookkeeping or encourage a cosmetic Balatro translation.

#### How?
- Mechanism linking the choice to the intended outcome: Explore choices about keeping outcomes versus pursuing alternatives, then examine whether changing those choices over time offers depth with limited management.
- Player actions, available information, and feedback: Candidate actions only: roll, keep, reroll, and choose an outcome. No action, count, scoring category, or information display is yet a game rule.
- System interactions and dependencies: Intended experience precedes loop choice; progression, scoring, and content depend on that loop.
- Likely failure modes and safeguards: Familiarity is assumed, conventional rules are copied uncritically, or dice feel incidental. Compare alternatives through concrete turns once the premise is confirmed.

#### What?
- Exact scope: An exploration proposal only; no playable rules selected.
- Parameters: Unresolved — creator to choose whether dice counts, reroll limits, categories, and session structure are relevant after resolving Q-02, before a paper loop.
- Content/data requirements and authoritative references: README and methodology purpose establish provenance; this record owns the proposal's status.
- Boundary conditions, exceptions, and recovery behavior: No inherited Yahtzee score sheet, category-use restriction, bonus, or Balatro round structure. Invalid moves, failure, and interruption remain unresolved until a loop exists.
- Acceptance criteria: Given creator confirmation of the premise, when a paper loop is proposed, then every retained familiar rule has a player-experience rationale and the loop can be walked through to an ending. Given rejection of the premise, then dependent proposals are reviewed rather than treating dice as mandatory.
- Explicit exclusions: Treating the README as a complete rules specification or acceptance of standard Yahtzee rules.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: Dice-pattern decisions can supply the intended experience with low management burden. Inability to explain a concrete turn without many exceptions, or uninteresting choices, counts against a candidate loop.
- Method: Creator concept discussion followed by a paper walkthrough; audience comprehension testing only after Q-06 is resolved.
- Success/failure criteria and why: First establish conceptual fit with the creator; then specify observable tasks before testing. No audience conclusion follows from creator preference alone.
- Evidence: README and methodology inspected 2026-10-30; no prototype or player evidence.
- Confidence: Untested.
- Open questions: Q-02 — creator to identify essential versus optional aspects before core rules; Q-01 — D-003 and D-004 establish intent; concrete build elements remain open.
- Revisit trigger: Creator rejects the premise, or paper exploration fails D-001.
- History: 2026-10-30 — captured the repository premise as proposed, not accepted.

### D-004: Builds influence payoff and odds

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-10-30.
- Scope: Purpose of combination-building; specific content and probability mechanisms remain unresolved.
- Links: D-001, D-003; Q-01, Q-02, Q-04; sections 05–07 and 10.

#### Why?
- Need or problem: The creator wants players both to make a desired outcome valuable and to improve their chances of reaching it.
- Intended player outcome and connection to goals: Players can pursue a plan by shaping its reward and its likelihood, supporting D-003's preparation, anticipation, and payoff.
- Evidence and assumptions: Creator selection on 2026-10-30 establishes the direction. The belief that these two forms of influence create understandable, satisfying strategy remains untested.
- Alternatives considered: Influence payoff only; influence odds only; influence both. The creator selected both.
- Selected tradeoff, costs, and disadvantages: Two forms of influence offer more planning possibilities but may increase management and explanation demands. Their interaction may produce dominant strategies or remove suspense.

#### How?
- Mechanism linking the choice to the intended outcome: A build makes certain outcomes desirable and provides ways to improve their likelihood. The player can connect preparation to both the result being pursued and the chance of attaining it.
- Player actions, available information, and feedback: Concrete build actions and displays are unresolved — creator to explore them alongside the D-005 dice lifecycle. Players need to understand how their choices affect payoff and likelihood; exact numerical probability display is not selected.
- System interactions and dependencies: Core randomness, outcome evaluation, content, and UI must support the relationship. D-001 constrains management burden; D-003 calls for consequential uncertainty.
- Likely failure modes and safeguards: Odds improvements guarantee every desired result, reward growth makes alternatives irrelevant, or opaque interactions obscure agency. Examine competing plans and both successful and unsuccessful outcomes in candidate walkthroughs.

#### What?
- Exact scope: The eventual build system supports influence over both payoff and odds. This does not require every build element to affect both, separate item families for each, or a mandatory acquisition order.
- Parameters: No odds, reward values, caps, costs, or guaranteed-outcome policy selected. Creator to specify candidate parameters before a paper-loop test.
- Content/data requirements and authoritative references: This record owns the dual purpose. Concrete mechanisms and content belong in later decisions; no dice modification, reroll resource, shop, or modifier inventory is accepted here.
- Boundary conditions, exceptions, and recovery behavior: Improvement is not a promise of success. Effects at probability limits and failed-attempt consequences require explicit rules once a mechanism is chosen. Whether payoff and reliability compete for resources remains unresolved.
- Acceptance criteria: Given a candidate build system, when reviewed, then at least one supported choice changes the value of an outcome and at least one changes its likelihood. Given an illustrative plan, then the reviewer can explain how those influences work together and identify where meaningful uncertainty remains. These are specification checks, not player validation.
- Explicit exclusions: Automatic adoption of Balatro's scoring or content structure; assuming both dimensions require separate management systems; fixing all outcomes as probabilistic or forbidding occasional certainty.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: Players can understand and enjoy influencing both dimensions within D-001's simplicity constraint. Confusion about whether a choice affects reward or likelihood, or an obvious dominant plan, would count against a candidate implementation.
- Method: Compare concrete build alternatives on paper, then ask representative players to explain their desired outcome, preparation, and remaining uncertainty.
- Success/failure criteria and why: Require traceable effects on both dimensions and understandable alternatives. Creator to set test scenarios and contextual thresholds before player testing; no audience evidence exists yet.
- Evidence: Creator clarification, 2026-10-30; no prototype or playtests.
- Confidence: Untested.
- Open questions: Q-02 — creator to resolve remaining D-005 lifecycle and allowance details before a complete loop; Q-01 and Q-04 — choose concrete build elements and examine management demands before core-loop selection. Compare reliability-versus-payoff tradeoffs at that gate.
- Revisit trigger: Dual influence causes excessive complexity, removes meaningful uncertainty, or fails to make preparation feel consequential.
- History: 2026-10-30 — accepted both payoff and odds influence as build purposes, leaving mechanisms open.

### D-005: Select dice to validate or reroll with limited allowances

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Core in-round action model and post-validation dice behavior; accepted direction with unresolved rules explicitly listed below. Not yet implementable.
- Links: Replaces D-002; supports D-001, D-003, D-004; Q-02, Q-04, Q-05; sections 03, 05, 06, and 10.

#### Why?
- Need or problem: The creator values Balatro's selection followed by play-or-discard decision and chooses a corresponding validate-or-reroll interaction for dice.
- Intended player outcome and connection to goals: A compact set of actions supports choosing when to commit an outcome and when to spend opportunities pursuing the prepared payoff (D-003). Retaining unvalidated dice allows preparation to persist across validations while rerolling validated dice refreshes the committed part of the pool. Limited allowances create opportunity costs; changing allowances offers one candidate means of influencing outcome likelihood (D-004).
- Evidence and assumptions: Creator instructions, 2026-10-30, establish the action model and post-validation behavior. The supplied Balatro analysis describes its reference. Comprehensibility and meaningful tension in Paroli are untested assumptions.
- Alternatives considered: A conventional keep-and-reroll sequence followed by one submission; unlimited rerolls; the selected model with limited validations and rerolls. The creator selected the latter. For post-validation behavior, alternatives were rerolling validated dice only, rerolling all dice, or setting validated dice aside; the creator selected rerolling validated dice only. Detailed comparisons remain for paper exploration.
- Selected tradeoff, costs, and disadvantages: Two action allowances require tracking, but can support different uses of remaining opportunities. Keeping unvalidated dice preserves planning continuity, but may encourage repeatedly holding the same strong partial combination. They may create obvious sequencing or confusing exhaustion states. The borrowed interaction needs validation within Paroli's own dice rules.

#### How?
- Mechanism linking the choice to the intended outcome: Select dice, then choose to validate the selection or reroll it. After validation resolves, validated dice are rerolled and other dice are kept. Limited uses make further pursuit costly in opportunities. Upgrades or the starter can change the allowances.
- Player actions, available information, and feedback: Selection targets the intended dice; validation commits the selection for outcome resolution, while rolling rerolls the selection. Exact scoring, selection bounds, previews, and presentation of remaining uses remain unresolved — creator to define before a paper walkthrough.
- System interactions and dependencies: The post-validation rule preserves the unvalidated dice and refreshes the validated dice; any special effects that alter this baseline need their own specification. Combination recognition determines what may be validated. Allowance rules interact with round endings, upgrades, and starter effects.
- Likely failure modes and safeguards: Dominant strategies built around indefinitely retained dice, automatic reroll-until-empty behavior, or inconsistent counter resets. Resolve remaining lifecycle and budget semantics with worked normal, exhausted-budget, and interruption cases before implementation.

#### What?
- Selected rules: Players select dice and invoke either Validate or Roll. Each action has a limited allowance; upgrades or the starter can modify the allowed number of uses. After validation resolves, reroll the validated dice and keep the other dice unchanged under the baseline rule. In this document, Roll means the player-selected reroll action, which consumes one reroll use per action, distinct from the free initial roll and free automatic post-validation reroll.
- Parameters: Baseline starter allowances are 3 validations per round and 3 rerolls per round (units: action uses; creator decision, 2026-11-01). Both are provisional tuning values, to be balanced later with round target calculation; upgrades and starter effects can modify them. There is a separate allowance for each action. Only a completed legal manual Roll action spends one reroll use; the initial roll and automatic post-validation rerolls spend none. D-021 resets allowances each round without action carryover and converts unused validations into coins. Caps and modifier arithmetic remain unresolved before the paper loop.
- Content/data requirements and authoritative references: This record owns the action model. Upgrade types and the meaning of a starter require future specifications; no shop, starter deck, or inventory structure is implied.
- Boundary conditions, exceptions, and recovery behavior: Unresolved — creator to define empty/invalid selections, exhausted Roll allowance behavior, action cancellation, interruption, and automatic-reroll ordering at round end before the complete paper loop. D-006 owns success/failure precedence. Score calculation and rewards are not yet specified.
- Acceptance criteria: Given the baseline starter and no allowance modifiers, then the configured round allowances are 3 validations and 3 rerolls; they are not one shared pool. Given a legal selection and an available action allowance, when Validate is chosen, then that selection is committed for resolution and subsequently rerolled, while unvalidated dice retain their current values. When a legal manual Roll is completed, then the selection is rerolled and the reroll counter decreases by one. Given the initial roll or an automatic post-validation reroll, then the reroll counter is unchanged. Given zero manual rerolls remaining and a legal validation with a validation use available, then its automatic reroll still occurs without requiring or consuming a reroll use. Given a starter or upgrade that changes an allowance, then the effective allowed uses reflect that change. Given an automatic reroll, its result may equal the previous face; rerolling does not guarantee a changed value. D-021 owns reset and conversion behavior; modifier arithmetic and terminal-round ordering still require specification.
- Explicit exclusions: Importing Balatro's action counts, draw/discard piles, refill behavior, blind structure, score formula, or run-loss consequences; D-006 separately selects the round objective; assuming ordinary Yahtzee categories or score-sheet rules.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: Limited validation and reroll opportunities create understandable choices between committing and pursuing a better outcome. A walkthrough revealing an always-best sequence, unlimited reuse exploit, or ambiguous resource use counts against a candidate rule set. Evaluate the provisional 3/3 allowances together with targets, rather than claiming the counts alone establish balance.
- Method: After resolving remaining lifecycle and budget rules, walk through successful, failed, and exhausted-budget rounds; then observe players explaining their action choices.
- Success/failure criteria and why: A paper round must resolve without invented rules, include consequential choices, and account for every allowance change. Creator to define player-comprehension tasks and contextual thresholds before playtesting.
- Evidence: Creator instruction, 2026-10-30; no playable prototype or audience evidence.
- Confidence: Untested.
- Open questions: Q-02 — post-validation behavior resolved; manual-only reroll consumption is resolved. Creator to define selection limits, remaining combination recognition, remaining round-transition edge cases and initial-roll details beyond its confirmed zero cost; D-021 owns score/action resets. Q-05 — D-006 and D-007 establish round outcome and run-ending failure; define subsequent success flow and new-run setup. Resolve these before a complete paper-loop walkthrough; resolve starter/upgrade timing before adding those effects to the prototype.
- Revisit trigger: Two allowances add excessive management, fail to create meaningful choices, or clash with the intended preparation-and-risk experience.
- History: 2026-10-30 — accepted the creator's dice action model and modifiable allowances; superseded the open premise in D-002 without accepting other reference-game rules. Later clarification the same day: validated dice reroll after resolution; other dice are kept. 2026-11-01: set provisional baseline allowances to 3 validations and 3 rerolls per round, with later tuning alongside target scores. Subsequent confirmation: only manual Roll actions decrement the reroll counter; opening and post-validation rolls are free.

### D-006: Reach a cumulative round score target within limited validations

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-10-30.
- Scope: Round objective and success/failure condition; D-007 owns failure consequences. D-019 owns the score formula; detailed arithmetic and success transitions remain open.
- Links: D-001, D-003–D-005; Q-02, Q-05; sections 03, 05, 06, and 10.

#### Why?
- Need or problem: The creator selected a cumulative score target pursued through limited validations as the round objective.
- Intended player outcome and connection to goals: Each validation contributes toward a clear goal, making progress and remaining opportunities relevant to the choice between committing and pursuing a stronger outcome. This supports D-003's anticipation and D-004's payoff planning.
- Evidence and assumptions: Creator confirmation, 2026-10-30, establishes intent. Whether the target creates satisfying tension with Paroli's dice and builds is untested.
- Alternatives considered: A cumulative target versus a different round goal, such as one qualifying combination or maximizing score without a pass/fail target. The creator confirmed the cumulative-target direction; alternatives have not been prototyped.
- Selected tradeoff, costs, and disadvantages: One target gives a compact goal, but may overemphasize score efficiency, produce repetitive pacing, or make remaining attempts feel hopeless. Target tuning depends on the still-undefined scoring and build systems.

#### How?
- Mechanism linking the choice to the intended outcome: Add each validation's score to the round total, then compare the total to the target. Remaining validations limit scoring opportunities; rerolls support pursuit of better outcomes under D-005.
- Player actions, available information, and feedback: Validate selected dice to contribute score or use Roll to pursue a different selection outcome. Presentation of total, target, remaining allowances, and score breakdown is unresolved — creator to define before the interface prototype.
- System interactions and dependencies: Score calculation determines each contribution; upgrades and starter affect available actions. D-005 owns the post-validation dice behavior. Round transitions and rewards require later decisions.
- Likely failure modes and safeguards: Checking exhaustion before adding the final score incorrectly rejects a last-validation win. Resolve the score and check target attainment before checking validation exhaustion. Examine both attainable and unattainable target scenarios when tuning.

#### What?
- Selected rules: Each validation adds its resolved score to the cumulative round score. A total at or above the target immediately ends the round successfully; no further manual rolls or validations may be taken in that round. If the total remains below target after the last available validation resolves, the round fails. Reaching the target on the last validation succeeds.
- Parameters: Score and target use points; remaining validations use action counts. D-019 establishes the formula; target values, bounds, and rounding are unresolved; D-021 sets starting round score to zero with no score carryover. Remaining numerical details require specification — creator to specify before a complete paper-loop walkthrough. No numeric tuning values selected.
- Content/data requirements and authoritative references: This record owns the target comparison and final-validation success precedence. D-005 owns action allowances; D-017 owns the increasing-target requirement; D-019 owns points × Mult; effect resolution details and the target growth formula remain unresolved.
- Boundary conditions, exceptions, and recovery behavior: A result equal to the target succeeds; exceeding the target also succeeds. D-007 owns immediate run termination and build loss on round failure. D-021 resets score to zero next round with no carryover. Post-success extra play is prohibited: proceed to D-021 settlement immediately after the successful validation resolves. Terminal automatic-reroll animation/state handling remains to be specified; it cannot create another opportunity to play. Running out of Roll uses is not the selected failure condition; remaining legal actions at zero Roll uses require D-005's budget specification.
- Acceptance criteria: Given any validation that brings the total to or above target, then the round immediately succeeds and proceeds to settlement with its remaining validation count. Given the last available validation, when its contribution brings the total to or above target, then the round succeeds. Given the last available validation, when its contribution leaves the total below target, then the round fails. Given a total below target with validations remaining, then this condition alone does not fail the round.
- Explicit exclusions: Inheriting Balatro's target values, scaling, blind sequence, payout rules, or run-ending consequence. This decision does not select a score formula.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: A cumulative target makes preparation and risk consequential across several validations. Routine automatic wins or rounds whose remaining decisions cannot plausibly matter would count against a candidate tuning or mechanism.
- Method: Walk through partial progress, exact-target success, over-target success, last-validation success, and exhaustion below target; then test decision-making with representative players.
- Success/failure criteria and why: All paper cases must resolve consistently without inventing score or allowance rules. Once values exist, creator to set scenarios and contextual criteria for tension and comprehension before playtesting.
- Evidence: Creator confirmation, 2026-10-30; no prototype or audience evidence.
- Confidence: Untested.
- Open questions: Q-05 — D-007 resolves round-failure consequences; creator to determine success transitions and new-run setup; Q-02 — define score calculation and allowance semantics. Resolve these before a complete paper-loop walkthrough.
- Revisit trigger: Target pursuit overwhelms combination-building, repeated validations become rote, or meaningful decisions disappear too early in the round.
- History: 2026-10-30 — accepted cumulative score toward a round target within limited validations, with success evaluated after the final contribution. Subsequent confirmation: any target-reaching validation immediately ends the round and begins settlement.

### D-008: Five-die baseline pool

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-10-30.
- Scope: Baseline total dice pool.
- Links: D-001, D-005, D-009–D-011; Q-02, Q-04.

#### Why?
- Need or problem: The creator specifies only five dice in total and asks that permanent effects be balanced for this small pool.
- Intended player outcome and connection to goals: A small set of persistent objects supports readable preparation and recognizable individual dice (D-001, D-003).
- Evidence and assumptions: Five is a creator constraint, not an empirically optimal count. The claim that per-object effects have greater exposure than in a large drawn deck is a balance hypothesis dependent on selection and trigger rules.
- Alternatives considered: A larger reserve with draws, or a variable pool; neither is selected.
- Selected tradeoff, costs, and disadvantages: Limited objects reduce tracking but concentrate upgrades and repeated effect exposure.

#### How?
- Mechanism linking the choice to the intended outcome: Apply D-005's selection and reroll actions to a total pool of five dice; inspect build effects on those objects.
- Player actions, available information, and feedback: Pool and selected dice must be distinguishable; presentation remains unresolved before UI prototyping.
- System interactions and dependencies: Effect frequency depends on which dice are validated or held, not just the pool count.
- Likely failure modes and safeguards: Treating a small per-trigger bonus as weak despite frequent reuse; test complete rounds and developed builds.

#### What?
- Selected rule and parameters: Baseline total pool = 5 dice, creator-specified, fixed for initial design exploration. This is not five drawn from an assumed reserve.
- Content/data requirements: D-009–D-011 own proposed effects; die identity and base-face specification remain open.
- Boundary conditions and exceptions: Effects changing pool size are not selected; D-024 establishes six equally likely faces and the standard 1–6 values. Selection bounds remain Q-02.
- Acceptance criteria: Given baseline play, then the total pool contains five dice; ordinary validation and reroll do not consume dice under D-005.
- Explicit exclusions: An inferred reserve, draw pile, or permission to add dice.

#### Validation and follow-up
- Riskiest hypothesis: Five persistent dice support readable but varied builds; repetitive dominant allocations or unreadable accumulated effects would challenge that expectation.
- Method and success/failure criteria: Walk through contrasting builds and tally effect exposure per validation and round before tuning. Creator to define experience-test criteria once scoring exists.
- Evidence: Creator statement, 2026-10-30; no playtest evidence.
- Confidence: Untested.
- Open questions: D-024 resolves default faces and probabilities; creator to resolve remaining selection bounds under Q-02 before prototype implementation.
- Revisit trigger: Pool size prevents intended variety or clarity.
- History: 2026-10-30 — recorded five total dice as the baseline.

### D-018: Highest-ranked recognized combination takes precedence

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Default combination precedence, the nine-category hierarchy, and explicit exceptions; not a complete scoring specification.
- Links: D-001, D-003–D-006, D-011, D-017; Q-02, Q-09; sections 05, 07, and 10.

#### Why?
- Need or problem: The creator confirms that a validation normally scores one combination, with the highest combination taking precedence over other recognized combinations.
- Intended player outcome and connection to goals: A single default result makes validation easier to interpret (D-001), while named exceptions can create build-dependent opportunities (D-003, D-004).
- Evidence and assumptions: Creator confirmations, 2026-11-01, establish the precedence model and nine-category order; the supplied Balatro analysis is the reference for the precedence mechanism. Its clarity and strategic quality with Paroli's dice remain untested.
- Alternatives considered: Score every recognized combination, let the player choose a category, or automatically choose whichever yields the most final points. The selected default is highest-ranked recognition. The creator subsequently accepted the nine-category order below; no probability-based ranking or score values were inferred.
- Selected tradeoff, costs, and disadvantages: A stable hierarchy avoids another category-selection step, but a recognized higher category may override a lower category that would yield more points under the current build. Exceptions add explanation and overlap rules.

#### How?
- Mechanism linking the choice to the intended outcome: Recognize valid combinations in the dice selected for validation, then use the highest-ranked recognized category as the default scoring combination. Explicit effects may authorize additional combination contributions.
- Player actions, available information, and feedback: Players control the dice selection; no separate category choice is selected. Recognition preview and explanations of overrides remain to be specified before UI prototyping.
- System interactions and dependencies: Recognition uses the hierarchy below; per-category matching details remain to be specified. Score resolution requires points/Mult rules and effect triggers. Odd straight remains a proposed recognition-changing effect requiring exact matching rules. The removed combination-stacking example no longer defines any content behavior; the previously accepted possibility of explicit exceptions does not itself select an exception.
- Likely failure modes and safeguards: Assuming highest rank means highest final score, counting lower combinations without an exception, or allowing overlapping-dice effects to double-count unexpectedly. Define worked cases using the accepted hierarchy once recognition requirements and relevant modifiers are selected.

#### What?
- Selected rules: By default, one recognized combination scores per validation: the highest-ranked category present in the selected dice. Lower recognized categories do not also contribute their combination scores by default. An explicit Joker effect may allow combinations to score together. Rank precedence is distinct from maximizing final points; category order is not recalculated from the current build's potential payout.
- Parameters: Default scoring-category count = 1. The nine-category order below is accepted; ranks are precedence positions, not point values or probability estimates. A short straight requires 4 consecutive distinct face values; a long straight requires 5. When no higher-ranked combination is recognized, Single die uses the highest-valued validated die, whose face value supplies the automatic face points. These are creator-specified rules. Remaining matching details and ties between qualifying subsets remain unresolved. D-022 supplies accepted provisional category base values. No score values are imported automatically from Balatro or Yahtzee.

| Rank (lowest to highest) | Category |
| --- | --- |
| 1 | Single die (highest-valued validated die) |
| 2 | Pair |
| 3 | Two pairs |
| 4 | Three of a kind |
| 5 | Short straight (4 consecutive values) |
| 6 | Full house |
| 7 | Four of a kind |
| 8 | Long straight (5 consecutive values) |
| 9 | Five of a kind |

- Content/data requirements: The table above is the authoritative category order. Per-category recognition rules and definitions for exceptions remain required. Each stacking exception must state which combination scores or bonuses combine and whether the same die may serve both.
- Boundary conditions, exceptions, and recovery: What happens when no category is recognized, which selected dice contribute face points or effects, and how unused selected dice are treated for scoring remain unresolved. This rule suppresses lower category scoring, not all die bonuses or Jokers whose conditions may be met; their trigger rules still need specification. Conflicting recognition and stacking modifiers require precedence rules.
- Acceptance criteria: Given a selection recognizing categories A and B, with A ranked above B in the table and no exception, then A supplies the default combination score and B does not add its own category score. Given selected values 1, 2, 3, 4 without recognition-changing effects, then they satisfy the short-straight length/consecutiveness requirement; selected values 1, 2, 3 alone do not. Given selected values 1–2–3–4–5 or 2–3–4–5–6 without recognition-changing effects, then Long straight is recognized and overrides Short straight. Given validated values 1–3–6 and no recognition-changing effects, then Single die uses the 6 and adds 6 automatic face points; the 1 and 3 contribute no automatic face points but may activate eligible explicit effects under D-019. Given the same multi-category selection and a build making B potentially more lucrative, then A still takes precedence. Given an explicit stacking effect, then only the combinations and contributions it authorizes are added; its overlap semantics must be specified before implementation.
- Explicit exclusions: Automatic maximum-score optimization, player category selection, automatic scoring of every subset, or acceptance of a complete recognition specification; D-019 separately establishes the points × Mult formula.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: Highest-category precedence is understandable even when build bonuses favor another category. Players consistently expecting an automatic higher payout rather than rank precedence would challenge the recognition feedback or rule.
- Method: Once recognition requirements exist, walk through multi-category recognition against the accepted order, a lower-ranked but more lucrative alternative, no-match selections, four-value short-straight recognition, and any separately specified recognition exceptions.
- Success/failure criteria and why: Recognition must follow the defined hierarchy and explicit exceptions consistently. Creator to define player prediction tasks and comprehension criteria before testing; no player evidence yet.
- Evidence: Creator confirmation, 2026-11-01; supplied Balatro analysis as a reference mechanism, not Paroli validation.
- Confidence: Untested.
- Open questions: Category catalog and ranking are resolved. Straight lengths and Single die selection are resolved. Creator to define remaining recognition details, participating-subset tie handling, empty/invalid-selection behavior, D-019 effect resolution, and exception overlap before a complete scoring walkthrough.
- Revisit trigger: Category precedence creates unexplained outcomes, suppresses intended build variety, or requires too many exceptions.
- History: 2026-11-01 — accepted highest-ranked single-combination scoring by default, with explicit Joker exceptions; subsequent confirmation accepted the nine-category hierarchy above. Subsequent clarification set short straights to four consecutive values and removed the Straight with pair example. Latest confirmation sets Long straight to five consecutive values and Single die to the highest-valued validated die. Other recognition details and scoring arithmetic remain open.

### D-019: Combination-based points × Mult with independent die-bonus conditions

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Validation score formula, combination base values, automatic face contributions, and effect-specific combination-membership requirements for die bonuses and upgrades. Not yet an executable resolution specification.
- Links: D-001, D-003–D-006, D-009–D-011, D-018; Q-02, Q-09; sections 05, 07, and 10.

#### Why?
- Need or problem: The creator wants points × Mult scoring based on the recognized combination, while allowing individual die bonuses to contribute independently of that combination's type.
- Intended player outcome and connection to goals: A recognized pattern anchors the score; prepared dice and effects can amplify it or provide additional ways to make a validation valuable (D-003, D-004). Independent bonuses permit meaningful effects beyond matching one preferred category. Counting only combination members makes the recognized pattern determine ordinary face points while explicit effects can give other validated dice a role.
- Evidence and assumptions: Creator confirmation, 2026-11-01, establishes the formula and bonus flexibility. The clarity and balance of interacting points/Mult modifiers remain untested.
- Alternatives considered: Combination-only scoring, one additive score quantity, or bonuses requiring a specific combination in every case. The creator selected two-factor scoring with both combination-dependent and independent bonus conditions. For low Mult outcomes, a minimum of 1 versus allowing 0 was considered; the creator chose to allow 0 for high-risk/high-reward effects. For automatic face points, alternatives were all validated dice, only combination members, or none; the creator selected combination members only.
- Selected tradeoff, costs, and disadvantages: Two factors support synergy but increase arithmetic and may produce rapid growth. Allowing zero Mult gives risk-bearing effects the potential to yield no score for a validation. Summing flat modifiers and percentage increases in separate stages removes ordering as a management task, while allowing percentage-based upgrades without multiplicative chains. Effect-specific participation supports variety but increases wording demands; unclear eligibility could undermine D-001’s comprehension goal.

#### How?
- Mechanism linking the choice to the intended outcome: Recognize the category under D-018; initialize points and Mult from that category’s base values; add the face values of dice forming that combination to points; sum eligible point contributions, flat Mult contributions, and percentage Mult increases independently; apply the combined percentage to the flat Mult subtotal; multiply the resulting points by the resulting Mult and show the signed result and add only its nonnegative contribution to round score under D-006.
- Player actions, available information, and feedback: Select dice and validate. The player needs to distinguish category contribution from active dice/effects; show a negative raw outcome when one occurs and distinguish it from the zero credited to the round. Exact preview and breakdown presentation remain unresolved before UI prototyping.
- System interactions and dependencies: D-018 chooses the base category, not necessarily every die eligible for an effect. Each die bonus or upgrade effect specifies whether combination membership is required; a separate condition may require a particular category. Examples include the proposed Full-house-conditioned bonus and a face-conditioned bonus; the creator's lone-wolf concept needs its own exact trigger before implementation.
- Likely failure modes and safeguards: Treating category independence as permission for held dice to trigger, suppressing valid bonuses because they do not name a category, or accidentally making additive modifiers order-dependent through running-total conditions or intermediate clamping. Use validated dice as the default scope, require explicit held-die wording, and express combination membership when required. Determine scoring eligibility from the validation context rather than intermediate accumulated totals. Preserve additive order independence; define non-scoring event timing and numeric boundaries before implementation.

#### What?
- Selected formula: For recognized category C, participating dice S, and eligible scoring effects E:
  - P_total = base_points(C) + sum(face_value(d) for d in S) + sum(point_delta(e) for e in E).
  - M_flat = base_mult(C) + sum(mult_delta(e) for e in E).
  - M_total = M_flat × (1 + sum(mult_percent(e) for e in E) / 100). Percentage effects contribute numbers such as 25 or 100; missing contributions are zero.
  - Raw validation score = P_total × M_total; preserve its sign for player feedback.
  - Credited score = max(0, raw validation score). Round score after validation = prior round score + credited score. Do not clamp Mult to zero before calculating and showing a negative outcome.
  - Effects may contribute to points, Mult, or both. Negative deltas represent penalties such as All or nothing. Each participating die supplies its current face value once under the baseline rule.
- Selected ordering rule: Sum points, flat Mult, and percentage Mult independently. Apply the percentage sum once to the flat Mult subtotal; two +100% effects produce ×3, not ×4. Reordering evaluation or display cannot change the score. No percentage-point effects or sequential running-total scoring modifiers are selected. Recognition changes resolve before scoring eligibility. Current effect definitions and provisional tuning are in [Effects](EFFECTS.md).
- Selected zero-Mult rule: Final Mult may equal 0; there is no mandatory floor of 1. A valid validation with final Mult 0 contributes 0 points to the round total, regardless of its point total, and remains a used validation under D-005. Mult may also be negative; retain that value in the signed calculation. The zero floor applies to credited score, not to the displayed raw score or to each individual effect.
- Illustrative boundary case (arithmetic only, not tuning values): With 20 final points, −2 Mult, and prior round score 100, show raw score −40 and credited score +0; round score stays 100.
- Selected membership tie rule: Among equally ranked qualifying subsets, use the highest sum of member face values, then the earliest die positions in run order. Do not maximize effect rewards when choosing members.
- Selected face-contribution rule: Only dice forming the recognized scoring combination contribute automatic face points. Other validated dice and held dice add no automatic face points. This is separate from effect eligibility: a validated die outside the combination may still trigger an explicit effect that does not require combination membership.
- Worked baseline case (no upgrades, bonuses, or Jokers affecting scoring): Validate 4–4–6 as Pair. Participating dice are the two 4s, so face points = 4 + 4 = 8. Validation score = (base_points(Pair) + 8) × base_mult(Pair). The 6 contributes no automatic points, but remains a validated die and is rerolled with the selected 4s under D-005. This example does not assign category base values or effect amounts.
- Selected effect rule: Combination membership is effect-specific for both die bonuses and upgrades. “6: +X points if part of a combination” requires a face value of 6 and participation in the recognized scoring combination. “6: +X points” requires a face value of 6 but imposes no combination-membership condition. An effect may additionally name a required category. Default scope is validated dice; removing the membership condition does not enable a held-die trigger. An effect must explicitly state held eligibility, such as “+X points if in hand.” Here, in hand means kept outside the selected validation, not every die visible in the pool. A lone-wolf-like bonus remains a concept, not a complete item specification.

Illustrative eligibility cases under this rule, with all other activation requirements satisfied:

| Validated values and recognized category | Effect on the 6 | Membership result |
| --- | --- | --- |
| 4–4–6; Pair formed by the two 4s | 6: +X points if part of a combination | Does not trigger: the 6 does not form the recognized pair. |
| 4–4–6; Pair formed by the two 4s | 6: +X points | Triggers: the face condition is met and membership is not required. |
| 6–6; Pair formed by the two 6s | 6: +X points if part of a combination | Triggers on the effect-bearing die: its face and membership conditions are met. |

These are alternative effect wordings, not two new catalog items. An unvalidated held 6 does not activate either wording above by default.

| Effect wording | Eligible dice during validation |
| --- | --- |
| 6: +X points | Validated dice showing 6, whether or not they form the recognized combination. |
| 6: +X points if part of a combination | Validated dice showing 6 that participate in the recognized scoring combination. |
| +X points if in hand | The effect-bearing die when kept out of the validation; this explicit held condition replaces the validated-die default. |

The held-bonus wording is a creator-proposed example with an untuned X, not a finalized named catalog entry.


- Parameters: Points and final score are scoring quantities; Mult is a multiplier. Category base values are accepted provisionally in D-022. Modifier amounts, numeric representation, rounding, upper bounds, and whether negative point totals are permitted remain unresolved. Negative raw outcomes are visible and credited score is floored at zero. Example effect amounts X remain untuned; D-022 supplies provisional category bases. The symbolic worked case above isolates the confirmed face contribution.
- Content/data requirements: Each category needs base points and base Mult. Effects need a trigger event, eligible dice/context, explicit combination-membership requirement when applicable, face/category conditions, signed point/Mult contributions and activation conditions. Contributions must not depend on accumulation order; non-scoring state changes need separately specified timing. Combination-independent is a trigger property, not a new fourth content family.
- Boundary conditions, exceptions, and recovery: Automatic face points require membership in the recognized combination; effect membership requirements are defined individually. D-018 resolves Single die as the highest-valued validated die. Choosing participating dice when multiple subsets satisfy the same recognized category remains unresolved, including duplicate-valued dice that differ in their effects. Validated-versus-held eligibility follows the default and explicit exceptions above. Timing, repeated triggers, and conditions such as being validated alone remain separate rules. Simply displaying, selecting, or rearranging dice does not establish a scoring event; this record defines eligibility in validation scoring, not automatic score accumulation while idle. Zero Mult is valid and produces zero score. Negative Mult is retained in the raw calculation; a negative raw score contributes zero to the round. Zero/negative point policies, invalid/no-category selections, rule-changing effect conflicts, and bonus eligibility under boss restrictions require specification. Apply the credited-score floor only after the complete product. Any other eventual boundary or rounding policy must preserve order independence; do not clamp individual deltas in a way that changes results when positive and negative effects are reordered. The recognized category's base values remain part of a validation with an independent bonus unless an explicit future effect says otherwise.
- Acceptance criteria: Given recognized category C with participating dice S and no scoring modifiers, then validation score is (base_points(C) + sum of participating face values) × base_mult(C). Given unmodified validated values 4–4–6 recognized as Pair, then exactly 8 face points are added, not 14. Given final Mult 0 and a finite point total, then the validation adds 0 to the round total and is not refunded. If it is the final validation and the target remains unmet, D-006 and D-007 still determine failure. Given a nonnegative raw product, then that value is credited. Given a negative raw product, then display the negative result, credit zero, and preserve the prior round score. The validation is still used; a negative result does not refund it or erase previously earned score. Given the same validation context and eligible deltas in another evaluation order, then point total, Mult total, and final score are unchanged. Given an independent bonus whose specified conditions are satisfied, then the absence of a particular combination-type match does not by itself suppress it. Given a category-dependent bonus whose required category condition is false, then it does not trigger under that condition. Given the 4–4–6 Pair example, then the membership-conditioned effect on 6 is inactive while the face-only effect is eligible, assuming its other activation conditions are met. Given validation of 4–4 while a 6 is held, then “6: +X points” on the 6 does not activate. Given “+X points if in hand” on a die kept out of that validation, then its held condition is met; validating that die instead does not meet this condition.
- Explicit exclusions: Automatically adding every selected face value, automatically activating held-die effects, multiplicative scoring modifiers or player-managed scoring order, treating lone wolf as a fully defined item, or choosing numeric scoring/economy values.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: Players can connect the recognized combination and eligible effects to the product they receive. Repeated confusion about which dice contributed or why a bonus fired would count against the resolution or feedback design.
- Method: Using the confirmed eligibility and additive rules, walk through an unmodified validation, a category-dependent bonus, an independent bonus, overlapping effects, a zero-Mult validation, and a negative-Mult validation that displays its signed result and credits zero. Compare player predictions to results once a prototype exists.
- Success/failure criteria and why: Every included effect must have an explicit eligibility and additive-contribution justification; permutations must preserve totals; raw score must equal resolved points × resolved Mult and credited score must equal max(0, raw score). Creator to set comprehension tasks and numeric expectations after the unresolved rules are chosen, before testing.
- Evidence: Creator confirmation, 2026-11-01; no prototype, numerical model, or player evidence.
- Confidence: Untested.
- Open questions: Combination participation is now effect-specific. Validated-versus-held scope is resolved. Default face contributions are resolved as combination members only. Scoring accumulation is additive and order-independent. Zero Mult is allowed. Negative raw outcomes remain visible and round credit is floored at zero. Creator to define remaining numeric bounds, non-scoring trigger timing, participating-subset tie rules, and category base values before a complete scoring walkthrough. D-018 now defines both straight lengths and the Single die participant.
- Revisit trigger: Score arithmetic or effect eligibility obscures the link between preparation and payoff, or multiplicative growth prevents useful balance.
- History: 2026-11-01 — accepted combination-sourced base points and Mult, modified by dice and effects; allowed independent die-bonus conditions. Subsequent clarification establishes effect-specific combination-membership requirements for bonuses and upgrades, with explicit conditional versus face-only examples; subsequent confirmation sets validated dice as the default scope and requires explicit held-die wording, such as “+X points if in hand.” Further clarifications add automatic face points only from combination members and establish separate additive point/Mult totals with order-independent scoring. The creator subsequently allowed final Mult to reach 0, then clarified that negative raw outcomes remain visible but cannot subtract previously earned round score.

### D-022: First-pass combination base-value proposal

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Accepted provisional starting values for all nine combinations; tunable prototype balance, not playtest-validated balance.
- Links: D-003–D-005, D-017–D-021; Q-09; sections 05 and 07.

#### Why?
- Need or problem: The creator requested a complete proposed balance table to review together. A numerical starting point enables paper scoring cases before target and economy tuning.
- Intended player outcome and connection to goals: Ordinary patterns provide a baseline while more demanding patterns offer larger payoffs; build effects can change which pursuits are attractive (D-003, D-004).
- Evidence and assumptions: Values were proposed by Codex and accepted by the creator as the starting table on 2026-11-01; they are design choices, not measurements. Range calculations assume numeric faces 1–6, standard matching groups, two distinct values for Two pairs, and a triple plus a different-valued pair for Full house. Those matching/default-die assumptions do not silently become accepted rules. Effects are omitted to isolate category values; real runs have a major upgrade from the outset.
- Alternatives considered: A flatter payout ladder, a steeper jackpot ladder, or fixed Mult with all growth in points. This candidate increases both factors, with larger steps at the top; alternatives still need comparison.
- Selected tradeoff, costs, and disadvantages: Rising Mult makes point bonuses more valuable on higher categories; small base Mult makes added Mult proportionally stronger on lower categories. That creates different build incentives but may overreward reliable high-category builds. The table does not price categories by assumed natural rarity.

#### How?
- Mechanism linking the choice to the intended outcome: Apply D-019 with these provisional base values, then compare the player's current scoring plan against alternatives. Use ranges to expose face-value influence and overlaps rather than assuming category rank guarantees a larger final score.
- Player actions, available information, and feedback: Existing select/validate/reroll actions remain unchanged. Use this as the prototype starting table; game-facing score display remains part of the later UI specification.
- System interactions and dependencies: D-018 keeps rank precedence independent of payout. D-020's proposed low-face Mult/high-face point bonuses interact with both factors. The 3/3 allowance, altered die faces, effect frequency, target growth, and unused-validation income must all be considered in later tuning.
- Likely failure modes and safeguards: Five of a kind becomes routine with face upgrades; low categories require too much bonus investment; or target tuning pushes every build into the same patterns. Test altered-face builds and competing plans before accepting values.

#### What?
- Provisional accepted values: The table below is authoritative for initial prototype scoring. All base values remain tunable. Source: assistant proposal accepted by the creator on 2026-11-01; no Balatro or Yahtzee score values were inherited.
- Range definition: (base points + participating face-value sum) × base Mult, with no scoring modifiers. These are arithmetic extrema under the stated assumptions, not expected scores, probabilities, or target recommendations.

| Combination | Base points | Base Mult | Unmodified score range |
| --- | ---: | ---: | ---: |
| Single die | 5 | 1 | 6–11 |
| Pair | 10 | 2 | 24–44 |
| Two pairs | 15 | 3 | 63–111 |
| Three of a kind | 20 | 4 | 92–152 |
| Short straight | 30 | 5 | 200–240 |
| Full house | 40 | 6 | 282–408 |
| Four of a kind | 50 | 7 | 378–518 |
| Long straight | 60 | 8 | 600–640 |
| Five of a kind | 80 | 10 | 850–1100 |

- Worked cases: Pair 4–4 with an extra validated 6 has score (10 + 8) × 2 = 36 before effects. Short straight 2–3–4–5 has score (30 + 14) × 5 = 220. Five sixes have score (80 + 30) × 10 = 1,100.
- Boundary conditions and exceptions: Rank precedence still follows D-018, even where payout ranges overlap: two pairs of 5s and 6s score 111, while three 1s score 92. These are different selections, illustrating that rank is not a guarantee of higher score for every face assignment. Upgrades, bonuses, and Jokers can create much larger overlaps. Values for nonstandard face ranges require the same formula, not the displayed range limits.
- Acceptance criteria for this proposal: Each of the nine categories uses its accepted provisional base points and base Mult. Range endpoints and worked cases match D-019 under the stated assumptions. No targets, prices, reward rates, or new recognition rules are accepted through this proposal.
- Explicit exclusions: Claiming balanced difficulty, assuming effect-free opening play, assigning probability or rarity from rank, or choosing a round target/economy curve.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: This ladder leaves useful alternatives once builds change both odds and payoff. One category reliably dominating plausible builds and action budgets would count against the values or relevant effects.
- Method: Arithmetic range checks and initial creator review completed; next, paper rounds using representative upgraded dice and explicit placeholder effect values. Compare lower-category specialization, straight pursuit, and repeated-value builds before selecting targets.
- Success/failure criteria and why: Arithmetic must be correct. Balance criteria require selected effect values, die probabilities, and targets; until then, assess readability, relative payout intent, and concerning jumps rather than declaring success.
- Evidence: Candidate values and enumerated arithmetic ranges calculated 2026-11-01. No strategy simulation, probability model, playtest, or target calibration.
- Confidence: Untested.
- Open questions: Creator has accepted the starting table. Next, define a representative upgrade configuration and a clearly labeled test target for the paper walkthrough; these are not final tuning. Finalize matching and dice assumptions before treating these ranges as game guarantees; tune targets and economy later.
- Revisit trigger: Creator feedback, a dominant altered-face build, poor payoff comprehension, or new effect values that invalidate the intended incentives.
- History: 2026-11-01 — drafted nine candidate base values and verified unmodified ranges for joint review. The creator subsequently accepted the table as the provisional starting configuration; confidence remains Untested.

### D-024: Equally likely die faces and independent rolls

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Default dice, opening rolls, manual rerolls, and automatic post-validation rerolls.
- Links: D-003–D-005, D-008, D-009, D-012.

#### Why?
- Need or problem: Players need a consistent way to understand how changed faces affect their chance of reaching a desired combination.
- Intended player outcome: Build reliability through visible face composition while accepting uncertain individual outcomes.
- Evidence and assumptions: Creator confirmed equal face probabilities in response to the proposed standard six-face, independent-roll model. Comprehension and balance remain untested.
- Alternatives considered: Unequal face weights or hidden adjustments after good/bad rolls. Neither is selected.
- Tradeoff: Simple probabilities remain capable of producing repeated unfavorable outcomes; no hidden streak correction is provided.

#### How?
- Each roll independently chooses one of the die's six equally likely face positions. Upgrades can replace their values, so repeated values become more likely without weighting individual positions.
- The same distribution applies to all roll sources. A reroll may return the same value.
- Players can reason from face composition; exact probability display remains an interface question, not a requirement of this rule.

#### What?
- A standard die has faces 1, 2, 3, 4, 5, 6.
- Each face position has probability 1/6 per roll, independently of previous results and other dice.
- For a value appearing on n faces, its probability is n/6.
- All or nothing's 1, 1, 1, 6, 6, 6 yields 1 and 6 with probability 1/2 each.
- Odd master's 1, 1, 3, 3, 5, 5 yields each of 1, 3, and 5 with probability 1/3.
- Holding a die preserves its value under D-005; it does not draw another outcome.
- No hidden outcome adjustment based on streaks, round score, or proximity to the target.
- Acceptance criteria: Every face index is equally weighted by roll resolution; duplicated values retain separate face positions; prior outcomes do not change the distribution. Opening, manual, and automatic rolls all use this rule.
- Explicit exclusions: Guaranteed changed values on reroll, equal probability per distinct value regardless of duplicates, and automatic selection of RNG implementation or seed behavior.

#### Validation and follow-up
- Riskiest hypothesis: Visible face replacement is enough for players to understand probability changes.
- Method: Review face-index sampling when implemented and test player comparisons of ordinary and upgraded dice.
- Success/failure criteria: Distribution logic matches the specified face counts; creator to set comprehension-test criteria before playtesting. A finite sample need not contain equal outcome counts.
- Evidence: Creator confirmation, 2026-11-01; probabilities above follow from counting face positions, not gameplay simulation.
- Confidence: Untested.
- Open questions: Creator to define face-inspection/probability presentation before UI prototyping; implementation owner to specify RNG, seeding, and save/resume behavior before implementation.
- Revisit trigger: Future content proposes weighted faces, face-count changes, or reroll guarantees; these would require explicit new rules.
- History: 2026-11-01 — accepted equal face probabilities following the proposed standard-die and independent-roll model.

## 05 — Challenge, opposition, and skill

- Applicability: Applicable.
- Rationale: Methodology coverage requirement; [D-001](#d-001-accessibility-and-independent-design-direction) establishes the shared frame. Specific applicability remains open where marked Undecided.
- Owner: Project creator.
- Maturity: Exploring.
- Summary and boundaries: D-006 establishes score-target challenge; D-007 establishes immediate run termination and build loss on round failure. D-017 requires rising targets and a special boss rule. Difficulty tuning, specific boss effects, and broader persistence remain open.
- Decision records: D-007 and D-017 below; D-001 constrains accessibility; D-006 owns the round objective.
- Supporting specifications and evidence: Creator clarification above.
- Dependencies and open questions: Q-01, Q-05; creator to specify stakes before session endings.

### D-007: Round failure ends the run and loses the build

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-10-30.
- Scope: Consequence of round failure; not a complete persistence policy.
- Links: D-001, D-003, D-006; Q-05; sections 03, 06, 10, and 15.

#### Why?
- Need or problem: The creator wants round failure to immediately end the run and lose its current build.
- Intended player outcome and connection to goals: The combination the player has assembled is at stake, giving target pursuit consequential risk (D-003) while preserving D-001's distinction between clarity and reduced punishment.
- Evidence and assumptions: Creator instruction, 2026-10-30, establishes intent. The expectation that build loss strengthens tension without undermining enjoyment remains untested.
- Alternatives considered: Immediate run loss versus recovery after a failed round. The creator selected immediate run loss.
- Selected tradeoff, costs, and disadvantages: Losing an invested build creates stakes but can cause frustration, especially if failure feels arbitrary or poorly explained. Session length affects the amount of investment lost.

#### How?
- Mechanism linking the choice to the intended outcome: When D-006 determines round failure, transition the active run to ended and make its build unavailable for continued play. Future play begins a new run rather than recovering the failed one.
- Player actions, available information, and feedback: Failure feedback and new-run controls remain unresolved — creator to define before a session walkthrough. Any result inspection is informational, not continued play with the lost build.
- System interactions and dependencies: Requires D-006's final-score evaluation before declaring failure. Build ownership, save state, results, and new-run initialization must agree on the run's ended state.
- Likely failure modes and safeguards: Premature failure on a successful final validation; restoring an ended run as active; confusing build loss with deletion of unrelated profile progress. Trace these boundaries explicitly in the eventual persistence specification.

#### What?
- Selected rules: Round failure immediately ends the current run and loses its current build. There is no post-failure continuation or retry of the failed round retaining that build under this rule.
- Parameters: No lives, retries, or recovery currency selected; numeric parameters are not applicable to this binary transition.
- Content/data requirements and authoritative references: This record owns the failure consequence. Concrete build components and their reset data remain unresolved until the build system is specified.
- Boundary conditions, exceptions, and recovery behavior: A final validation that reaches the target succeeds under D-006 and does not trigger this rule. “Immediately” describes the gameplay transition, not a prohibition on a results screen or animation. Profile unlocks, records, cosmetics, crash recovery, and abandonment behavior remain unresolved; build loss does not decide those policies.
- Acceptance criteria: Given round failure under D-006, then the run ends and its current build cannot continue into another round. Given a new run after failure, then the lost run's build is not restored as active progression. Given final-validation success, then no failure-driven build loss occurs.
- Explicit exclusions: Post-failure revival or same-build retry; automatically deleting all profile data; assuming a particular metaprogression system exists.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: Losing the build makes risk engaging rather than making preparation feel wasted. Player reports of arbitrary loss or reluctance to build again would challenge the implementation and tuning.
- Method: Trace failure, final-validation success, and new-run initialization; later observe failed runs and players' understanding of their loss.
- Success/failure criteria and why: State transitions must satisfy the acceptance cases. Creator to define player-experience criteria after session duration and build investment are concrete; no audience claim is validated yet.
- Evidence: Creator instruction, 2026-10-30; no prototype or playtests.
- Confidence: Untested.
- Open questions: Q-05 — creator to define success flow, run victory, new-run setup, and between-run persistence before a complete session walkthrough. Build reset fields depend on the future content specification.
- Revisit trigger: Failure is hard to understand, loss undermines the intended build-and-risk experience, or session length materially changes the investment at stake.
- History: 2026-10-30 — accepted immediate run termination and current-build loss on round failure.

### D-017: Rising round targets and boss-specific challenge rules

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Challenge progression, regular/boss distinction, and boss-rule reveal timing.
- Links: D-001, D-003–D-007, D-012, D-014–D-016; Q-05, Q-09; sections 03, 06, 07, and 10.

#### Why?
- Need or problem: The creator wants targets to increase every round, with bosses also imposing a special rule that challenges the build.
- Intended player outcome and connection to goals: Increasing targets create pressure to develop and realize the planned strategy; boss rules ask players to adapt its use instead of facing only a larger number. This supports D-003's consequential preparation and risk.
- Evidence and assumptions: Creator instruction, 2026-11-01, establishes the direction. Balatro is the stated inspiration, not evidence that its curves or restrictions fit five persistent dice.
- Alternatives considered: Fixed regular-round targets; bosses distinguished only by target size; or special-rule bosses without target growth. The creator selected increasing targets for all rounds and both forms of challenge for bosses. For reveal timing, alternatives were before the upgrade, just after it at biome start, or just before the boss; the creator selected after the upgrade at biome start.
- Selected tradeoff, costs, and disadvantages: Rising numerical demands can force narrow power choices; special rules add exceptions to learn and may invalidate an irreversible upgrade strategy. Revealing the rule after upgrade commitment preserves uncertainty in that choice, but prevents tailoring it to the disclosed boss. Players have two shop visits and outside-round bonus rearrangement to prepare afterward. Fairness and comprehension need evaluation with representative builds, not just average scores.

#### How?
- Mechanism linking the choice to the intended outcome: Assign a higher target to each successive round on D-016's route. In a boss round, apply an additional special rule that changes how the player must approach the score target with the current build.
- Player actions, available information, and feedback: Players continue selecting, validating, and rerolling dice under D-005 while accounting for the boss rule. At biome start, reveal the upcoming boss rule after the permanent upgrade choice resolves and before the first regular round. Wording, preview presentation, later reference access, and affected-action feedback remain unresolved before an interaction prototype.
- System interactions and dependencies: Target growth depends on the scoring system, upgrade cadence, and shop opportunities. Boss rules interact with permanent upgrades and outside-round bonus rearrangement; D-012's permanent upgrade identities are not silently rewritten by this broad decision.
- Likely failure modes and safeguards: A boss leaves no viable route for a committed build, obscures why a score changed, or combines too many unfamiliar exceptions. Define each rule's scope and trace contrasting builds, including constrained and failed cases, before accepting boss content.

#### What?
- Selected rules: Each successive round has a higher score target than the preceding round, including regular-to-regular, regular-to-boss, and boss-to-next-biome transitions. Each boss round also adds a special rule challenging the build. Regular rounds do not receive a boss rule by virtue of target growth. Each biome entry follows upgrade choice and application → boss-rule reveal → first regular round. This includes the opening choice in biome 1; the boss rule is not disclosed by this flow before upgrade commitment.
- Parameters: For the 15 ordered rounds in D-016, target(r + 1) > target(r), in points, for r = 1 through 14. Initial target, growth function, increments, and any boss-specific increase are unresolved. A boss target is higher than the preceding regular target; no larger-than-normal increment is selected. Numerical tuning is deferred.
- Content/data requirements: Per-round targets or a generating rule; a boss-rule definition with trigger, affected actions/effects, duration, resolution order, and readable explanation. Boss catalog, selection method, and uniqueness across biomes remain unresolved.
- Boundary conditions, exceptions, and recovery: D-006 still determines round success/failure, and D-007 still ends the run on failure. Exact boss-rule activation and cleanup, invalid-action handling, interactions with allowance modifiers, and interruption recovery require specifications. Revealing the rule does not activate it in the regular rounds. Reveal timing does not determine when the boss is generated or selected, or imply adaptive selection against the chosen upgrade. No permission to replace permanent upgrades, carry boss penalties into later rounds, or lower targets between biomes is implied.
- Acceptance criteria: Given any adjacent rounds in the specified route, then the later target is strictly higher. Given a boss round, then its target is higher than the preceding regular round and its declared special rule changes the relevant gameplay as specified. Given a regular round, then no boss rule is implicitly added. Given entry to any biome, then its upgrade is committed before boss-rule disclosure, and disclosure occurs before the first regular round. Given the reveal, then the upgrade remains permanent and the player still has the two regular-round shop opportunities before the boss. Specific effect checks require a selected boss rule.
- Explicit exclusions: Copying Balatro's target values, scaling formulas, or boss catalog; assuming every boss rule is unique, randomly selected, or chosen in response to the upgrade; choosing economy values.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: Boss restrictions challenge a prepared strategy without routinely making permanent upgrade choices futile. Unavoidable failure for otherwise viable builds, or players unable to explain the restriction, would count against the selected rule or its disclosure.
- Method: First check the target sequence, upgrade-before-reveal ordering, and representative boss-rule walkthroughs. Later simulate or playtest contrasting builds once scoring and target values exist; compare strategic alternatives and observed comprehension.
- Success/failure criteria and why: All 14 adjacent target comparisons must increase; all 5 boss rounds must have a specified additional rule. Experiential criteria and viable-build coverage must be defined by the creator before boss playtests; no numerical balance claim is made now.
- Evidence: Creator instruction, 2026-11-01; no prototype, tuning model, or player evidence.
- Confidence: Untested.
- Open questions: Reveal timing is resolved. Creator to define representative boss rules, their lifecycle, and access to the revealed rule during later preparation before a complete round walkthrough. Scoring and growth values follow in the later tuning pass.
- Revisit trigger: Challenge removes meaningful alternatives, creates excessive rule burden, or conflicts with irreversible upgrades and the intended accessibility direction.
- History: 2026-11-01 — accepted increasing targets every round and an additional build-challenging rule for each boss; left exact growth and rule content open. Subsequent clarification: disclose each biome’s boss rule after upgrade commitment and before its first regular round.

## 06 — Progression, rewards, and economy

- Applicability: Applicable.
- Rationale: D-012 establishes upgrade progression within a run; D-015 establishes shops; economy values are deferred and between-run progression remains undecided.
- Owner: Project creator.
- Maturity: Exploring.
- Summary and boundaries: D-012 owns permanent upgrade selection and allocation. D-007 owns build loss; D-015 establishes shops. D-016 owns biome structure and shop placement; D-021 owns fresh round state and unused-validation coins. Other rewards, economy values, and between-run persistence remain open.
- Decision records: D-012, D-015, and D-021 below; D-007 for failure reset.
- Supporting specifications and evidence: Creator instruction, 2026-10-30.
- Dependencies and open questions: Q-05; initial upgrade timing is resolved in D-012; D-016 resolves biome structure; define remaining transition and persistence details before a full session walkthrough. D-012 allows bonuses on upgraded dice while preserving the major upgrade and its faces; D-013 owns bonus uniqueness and stacking.

### D-012: Permanent ordered upgrade choices at run and biome starts

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Major die-upgrade acquisition cadence, automatic target allocation, and permanent commitment during a run.
- Links: D-001, D-003, D-007–D-010; Q-01, Q-04, Q-05; sections 03, 07, 08, 10, and 15.

#### Why?
- Need or problem: The creator wants an initial major upgrade to guide strategy immediately, followed by additional commitments as the player enters biomes.
- Intended player outcome and connection to goals: Begin with a concrete direction for combination-building (D-003), then develop it across the run. Automatic targeting removes a placement decision and supports D-001's reduced management intent.
- Evidence and assumptions: Creator instruction, 2026-10-30, establishes direction. Whether irreversible choices encourage satisfying commitment rather than frustration is untested; automatic placement may reduce desirable agency.
- Alternatives considered: Replaceable upgrades, player-selected target dice, and upgrades acquired through an unspecified general reward flow. The creator selects irreversible upgrades with ordered automatic allocation and a biome-based cadence.
- Selected tradeoff, costs, and disadvantages: Commitment gives a build identity but limits later pivots. Automatic targeting simplifies choice but can matter strongly if dice already carry bonuses. Three offers may contain no appealing continuation; offer quality rules remain undefined.

#### How?
- Mechanism linking the choice to the intended outcome: At an eligible upgrade event, present three upgrades; the player chooses one. Apply it automatically to the next unupgraded die in order, preserving all earlier upgrade commitments. Repeat at biome starts until all five dice are upgraded.
- Player actions, available information, and feedback: Choose an upgrade rather than a target die. The display of the automatic target, effect, and permanence remains to be specified before an interaction prototype. Offer inspection and commitment feedback must be evaluated for comprehension.
- System interactions and dependencies: D-008 supplies five dice; D-009 owns upgrade effects; D-007 ends ownership with the run. D-010 bonuses may be added to upgraded dice without changing their upgrade or upgraded faces. D-016 defines biome transitions; die ordering and offer generation still need explicit rules.
- Likely failure modes and safeguards: Granting two unintended choices at initial entry; applying an upgrade twice on resume; target order changing through UI sorting; trapping a build with unsuitable offers. Treat opening selection and biome 1 entry as one upgrade event; resolve stable die-order semantics before the session walkthrough, and persistence behavior before implementation.

#### What?
- Selected rules: Choose the first major upgrade at run start; this is biome 1’s upgrade event, not an additional event. The next choice occurs on entering biome 2. At each subsequent biome start, choose a new upgrade while any of the five dice remain unupgraded. Each choice presents three upgrades and automatically applies the selected one to the next non-upgraded die in order. An applied upgrade cannot be removed, overwritten, or changed for the remainder of the run. No player-selected target is part of this flow. Once all five dice are upgraded, no further major upgrade choices occur under this cadence.
- Parameters: 3 offered upgrades per choice; 1 applied upgrade per choice; at most 5 successful applications across the five-die pool. These are creator-specified design values, not tuning evidence. Initial entry has exactly 1 upgrade choice with 3 offers. D-016 establishes five biomes and one upgrade choice at each biome entry.
- Content/data requirements: A stable allocation order and per-die upgrade state are required. Offer selection method, eligibility, duplicate offers, repeat upgrade types across different dice, and content exhaustion rules remain unresolved — creator to define before a complete progression walkthrough.
- Boundary conditions, exceptions, and recovery: The run-start choice also serves as the first-biome choice; entering biome 1 does not grant a second upgrade. Permanence applies to the major upgrade and its upgraded faces; an upgraded die may still receive bonuses. Applying a bonus does not remove, replace, or alter that upgrade or its face list. Physical ordering versus UI ordering, skipping an offer, and save/resume during selection require specification. D-016 establishes five biomes; a run that fails early does not reach all five upgrades.
- Acceptance criteria: Given an eligible event with fewer than five upgraded dice and valid offers, when the player chooses one of three, then exactly the next unupgraded die receives that upgrade and earlier upgrades remain unchanged. Given five upgraded dice, then a subsequent biome start grants no further upgrade choice. Given an occupied upgrade slot, then the selected upgrade cannot be replaced or edited. Given an upgraded die receiving a legal bonus, then the bonus is added while the major upgrade and upgraded face list remain unchanged. Given a new run, completing the opening choice upgrades only die 1; entering biome 1 grants no extra choice. Given progression into biome 2 with only die 1 upgraded, its choice upgrades die 2.
- Explicit exclusions: Replacing earlier upgrades, selecting a different target die, silently creating a sixth upgrade event, or inferring offer rerolls or prices; D-016 separately governs biome counts, bosses, and shop placement.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: Three irreversible options on an automatically assigned die create understandable, satisfying strategic commitment. Players unable to predict the target or finding that early choices routinely invalidate later offers would count against the mechanism or offer rules.
- Method: Walk through initial entry, successive upgrade events, the fifth application, and final-boss completion without a sixth application. Compare contrasting offer sets and include a bonus applied after an upgrade, checking that the upgraded faces remain unchanged. Separately resolve preservation of pre-existing bonuses when a die first receives its major upgrade.
- Success/failure criteria and why: Each eligible event applies exactly one upgrade to the intended die; no established upgrade changes and no sixth application occurs. Creator to set comprehension and offer-quality criteria before player tests.
- Evidence: Creator instruction, 2026-10-30; no prototype or audience evidence.
- Confidence: Untested.
- Open questions: Initial-entry overlap is resolved. Bonus application after upgrading is confirmed. Creator to resolve stable die order and offer eligibility before the complete progression walkthrough; D-016 resolves biome structure. Save/resume behavior must be defined before implementation.
- Revisit trigger: Automatic targeting undermines intended combinations, permanent choices create unwanted dead ends, or cadence conflicts with run length and biome structure.
- History: 2026-10-30 — established three-option upgrade choices, ordered automatic application, and permanent commitments. Subsequent clarifications: opening selection is biome 1’s choice, with the next choice at biome 2; upgraded dice may receive bonuses while their major upgrade and faces remain unchanged.

### D-015: Between-round shops and acquisition options

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Shop functions and broad placement within biomes; economy values intentionally deferred.
- Links: D-005, D-007, D-010–D-014; Q-04, Q-05; sections 03, 07, and 10.

#### Why?
- Need or problem: The creator wants shops between non-boss rounds to acquire, sell, and search for build effects.
- Intended player outcome and connection to goals: Develop the strategy established by permanent upgrades through adjustable bonuses and Jokers; trade certainty and money for different acquisition opportunities (D-003, D-004).
- Evidence and assumptions: Creator instruction, 2026-10-30. Whether this shop provides sufficient choice without excessive management is untested.
- Alternatives considered: Direct reward picks, shops without sales, or only known purchases. The creator selected buying/selling, whole-shop refresh, and discounted random purchases; alternatives are not tested.
- Selected tradeoff, costs, and disadvantages: Flexible acquisition supports adaptation but adds an economy and shopping decisions. Increasing refresh costs make continued searching progressively more expensive while allowing further attempts. Random discounts may encourage indiscriminate purchases if improperly tuned.

#### How?
- Mechanism linking the choice to the intended outcome: At a shop, buy or sell bonuses and Jokers, pay coins to reroll the whole shop repeatedly at increasing costs, or buy a random Joker or bonus at a discount. D-014 lets players place and rearrange bonuses; upgrades remain committed under D-012.
- Player actions, available information, and feedback: Purchase, sell, refresh, and choose a random acquisition option. Exact stock presentation, random-item disclosure, prices, and navigation remain open before an interaction walkthrough.
- System interactions and dependencies: D-013 filters owned bonus/Joker identities from offers. Purchases interact with bonus and Joker capacity; sales can change allowance or slot-granting effects. D-007 prevents a failed run from continuing into a shop.
- Likely failure modes and safeguards: Random purchases produce unusable or duplicate items, sales leave inventory over capacity, or a refresh fails to update part of the stock. Define these cases before implementation; do not solve them through invented economic values.

#### What?
- Selected rules: D-016 places a shop after each of the two regular rounds in each biome, including before the boss, and none after bosses (10 visits on the complete route). Players may buy or sell Jokers and bonuses. Whole-shop rerolls are repeatable; each successive reroll in the shop costs more coins than the previous one. Random Joker and random bonus purchases are available at a discount. Major die upgrades are not sellable.
- Parameters: Coins are the shop currency. There is no one-reroll-per-visit limit. For successive paid refreshes within a visit, cost(n + 1) > cost(n), measured in coins. The base price, increase formula, and reset policy on entering a new shop are not yet specified; no Balatro values are inherited. All starting money, income, prices, sale returns, reroll cost, discount amounts, and balance curves are deliberately deferred at the creator’s request.
- Content/data requirements: Eligible stock pools, ownership filtering, offer identities, and capacities. The comparison price underlying a random-purchase discount and whether random purchases are separate offers or a shop action remain unresolved.
- Boundary conditions, exceptions, and recovery: D-016 confirms a shop immediately before each boss and no shop after bosses. Sold-item reappearance, same-batch duplicates, exhausted offer pools, insufficient funds, full capacity, random-result placement, and removal of capacity/allowance effects require explicit handling. Shop stock counts and refresh behavior of purchased slots are not selected.
- Acceptance criteria: Given a legal funded purchase with capacity, then the selected bonus or Joker is acquired and can be used under its rules. Given a legal sale, then the owned effect is removed and the eventual specified sale return is applied. Given sufficient coins for a paid refresh, then the whole shop refreshes using eligible content and the next refresh costs more. Given a completed refresh and sufficient coins for the next one, then another refresh is allowed rather than blocked by a one-use limit. Given a random purchase, then its cost uses the eventual defined discount relative to its comparison price; no numeric discount is assumed.
- Explicit exclusions: Economy balancing in this design pass; buying/selling major upgrades; assuming a Balatro shop layout, income model, interest, or booster-pack structure.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: Known purchases, increasingly expensive repeatable refreshes, and discounted random purchases produce meaningful alternatives. A consistently dominant option or lengthy repetitive shopping would challenge the design.
- Method: Trace buy, sell, refresh, random acquisition, capacity limits, and stock filtering with symbolic costs first. Numeric economy modeling follows later when requested.
- Success/failure criteria and why: The acquisition walkthrough must preserve uniqueness, capacity, and upgrade permanence without inventing prices or recovery rules. Set balance targets separately in the later economy pass.
- Evidence: Creator instruction, 2026-10-30; no prototype or economic model.
- Confidence: Untested.
- Open questions: D-016 resolves boss-adjacent shop placement. Creator to define random purchase flow, sold-item eligibility, and capacity failure handling before a complete shop walkthrough. Refresh prices, increase formula, and new-shop cost reset policy remain deferred with economy tuning; this does not block recording the repeatable-refresh rule.
- Revisit trigger: Shop management undermines accessibility or random acquisition dominates deliberate build planning.
- History: 2026-10-30 — introduced shops, buying/selling, paid whole-shop refresh, and discounted random acquisition; deferred economic balancing. Subsequent clarification replaces the one-use interpretation with repeatable rerolls at increasing costs.

### D-021: Fresh round state and coins for unused validations

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Round score/action reset and the unused-validation reward source; no economy tuning.
- Links: D-003, D-005–D-007, D-015, D-016, D-019; Q-02, Q-05; sections 03 and 10.

#### Why?
- Need or problem: The creator confirms fresh round score and allowances, with unused validations converted into bonus coins for the shop.
- Intended player outcome and connection to goals: Efficient use of the prepared build earns resources for further development. Resetting score and action budgets gives each round a clear starting challenge rather than accumulated unused actions.
- Evidence and assumptions: Creator confirmation, 2026-11-01. Whether the reward encourages satisfying efficiency without excessive snowballing is untested.
- Alternatives considered: Carry unused actions into later rounds, discard all unused actions without reward, or convert unused validations to coins. The creator selects conversion plus fresh round budgets.
- Selected tradeoff, costs, and disadvantages: Early success strengthens future purchasing power but may widen the gap between strong and struggling builds. No conversion rate is justified until target and economy tuning.

#### How?
- Mechanism linking the choice to the intended outcome: At successful round settlement, measure unused validations and convert them into bonus coins. Discard unused rerolls. When the next round starts, initialize score to zero and restore that round's configured action allowances.
- Player actions, available information, and feedback: Play toward the target, then receive the unused-validation coin reward before later shopping. Settlement presentation and exact transition controls remain unresolved before UI specification.
- System interactions and dependencies: D-005 supplies provisional 3/3 baseline allowances and modifiers; D-006 determines success; D-007 ends failed runs. D-016 still places shops only after regular rounds; rewarding a cleared boss does not create an extra shop.
- Likely failure modes and safeguards: Counting the winning validation as unused, carrying leftover actions into restored budgets, converting after resetting the counter, or double-paying on resume. Determine unused count before reset and specify one settlement per completed round.

#### What?
- Selected rules: Every new round starts with score 0 and restored configured validation/reroll allowances: baseline 3 validations and 3 manual rerolls, subject to applicable modifiers. Neither excess round score nor unused actions carry over into the next round. Unused validations at successful round end become bonus coins; unused rerolls are discarded without an unused-reroll reward under this rule.
- Parameters: Coin conversion amount/formula, minimum payouts, other income, and balance targets remain deferred. Do not assume one coin per unused validation or a particular linear rate. The 3/3 baseline remains provisional under D-005.
- Content/data requirements: Round outcome, remaining validation count at settlement, a later-defined conversion function, coin balance, and next-round allowance configuration. Retained build effects are not erased by the round reset.
- Boundary conditions, exceptions, and recovery: The successful validation is consumed before calculating unused validations. No unused validations means no reward from this particular source; other rewards remain open. D-007 failure prevents further shopping. Cleared non-final bosses still transition to the next upgrade choice, not a shop; final-run settlement presentation and any purpose of final-boss coins remain unresolved. D-006 ends the round immediately on reaching the target; convert the remaining validations into coins without allowing another scoring or manual-reroll action.
- Acceptance criteria: Given a baseline round cleared on its first validation, then 2 unused validations feed the eventual coin conversion. Given a clear on the third validation, then 0 remain and this reward contributes no coins. Given the next unmodified round, then score is 0 and allowances are 3/3 regardless of prior unused counts or over-target score. Given repeated presentation/resume of a settled round, then the reward must not be awarded twice.
- Explicit exclusions: Carrying unused actions or over-target score into later rounds, a reward for unused rerolls, assuming a numeric exchange rate, or adding post-boss shops.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: Unused-validation rewards create meaningful efficiency goals without making early success compound too strongly. Economy trajectories dominated by initial luck would challenge the eventual values or reward mechanism.
- Method: Trace clears on first, second, and final validations; check reset and settlement behavior symbolically. Model coin outcomes only in the later economy pass.
- Success/failure criteria and why: Unused counts and reset states must match the cases above, with no duplicate payment or action carryover. Economic success criteria await that later pass.
- Evidence: Creator confirmation, 2026-11-01; no prototype or economic model.
- Confidence: Untested.
- Open questions: Immediate target-clear termination is resolved. Creator to define terminal reroll presentation/state handling, modifier initialization, and final-run presentation before a complete round walkthrough. Coin conversion is deliberately deferred.
- Revisit trigger: Reward snowballing, unclear settlement, or reset behavior undermines the intended challenge.
- History: 2026-11-01 — confirmed fresh score and action budgets; introduced bonus coins for unused validations with no conversion values selected.

## 07 — Content systems and taxonomy

- Applicability: Applicable.
- Rationale: D-004 requires build influence over payoff and odds; D-009–D-011 explore the creator's concrete content proposal.
- Owner: Project creator.
- Maturity: Exploring.
- Summary and boundaries: Three proposed families with different commitment, stacking, and power roles. Examples are design candidates, not executable effects.
- Decision records: D-009–D-011, D-013, D-014, and D-020 below; D-015 in section 06; D-008 owns the five-die pool.
- Supporting specifications and evidence: Creator proposal, 2026-10-30; examples below preserve its intended effects.
- Dependencies and open questions: Q-01, Q-02, Q-04, Q-09; creator to resolve effect semantics before a complete build/scoring walkthrough.

### Proposed family comparison

This table summarizes D-009–D-011; power labels express intended relative roles, not measured balance.

| Family | Intended power | Removal | Stacking | Capacity | Can replace die faces? |
| --- | --- | --- | --- | --- | --- |
| Die upgrade (D-009; commitment D-012) | High | Permanent: no removal, replacement, or alteration | Non-stackable | One per die | Yes |
| Die bonus (D-010; D-013–D-014) | Low | Movable into free slots outside rounds; sellable in shops | Different bonuses coexist; each bonus unique across the set | Proposed: 3 per die, separate from upgrade | No |
| Joker (D-011; D-013) | Medium | Sellable in shops (D-015) | Owned identities excluded from offers; distinct-effect interactions unresolved | Fixed base slot count, value unresolved; example can add a slot | Not specified |

### D-009: Powerful committed die upgrades

- Status: Proposed.
- Owner: Project creator.
- Updated: 2026-10-30.
- Scope: Proposed upgrade effects and power role; D-012 separately accepts acquisition and permanent commitment. Not ready for implementation.
- Links: D-001, D-003, D-004, D-008; Q-01, Q-04, Q-09; example catalog below.

#### Why?
- Need or problem and intended outcome: Give individual dice high-impact identities that can shape both desired outcomes and their likelihood (D-004).
- Evidence and assumptions: Creator proposal, 2026-10-30. Relative power and contribution to readable strategy are untested intentions.
- Alternatives considered: Omit upgrades, allow reversible upgrades, or use generic global modifiers. Alternatives have not been tested; the selected proposal is exploratory.
- Selected tradeoff, costs, and disadvantages: Permanent choices create commitment but can trap a player in a poor early choice; five dice constrain opportunities to change direction.

#### How?
- Mechanism, player actions, and feedback: For a risky All or nothing outcome, the intended responses are to spend a manual reroll, hold the die out of validation, or include it to form a useful combination despite its penalty. Creator feedback confirms this decision space; effectiveness remains to be tested. D-012 supplies the upgrade choice and automatic target allocation. The upgrade may replace that die’s faces and modify payoff; after application, the upgrade is permanent. Effect presentation remains unresolved before the paper build walkthrough.
- System interactions and dependencies: D-008's small pool increases the importance of repeated exposure; D-007 loses the build on run failure. Scoring, timing, and combination recognition depend on Q-09.
- Likely failure modes and safeguards: Hidden triggers or dominant effects undermine D-001 and D-003; walk through effects individually and together, including failed and repeated validations.

#### What?
- Proposed rules: High power; non-removable; non-stackable; one upgrade per die; may replace target-die faces.
- Parameters and content: Power labels are qualitative. Each example's X is an independent unresolved tuning value, not a shared constant. The catalog below preserves proposed content; values require scoring context before tuning.
- Boundary conditions, exceptions, and recovery: D-012 prohibits removing, replacing, or altering an applied upgrade. D-012 permits new bonuses without changing the upgrade or its faces. Default faces, face weighting, and detailed effect timing still require specification. D-019 retains negative Mult in the displayed calculation but floors credited round score at zero.
- Acceptance criteria for this proposal: Given an upgraded die, it has no more than one active upgrade. A face-replacing upgrade produces the specified face list. An occupied die cannot receive a replacement upgrade; D-012 automatically targets the next unupgraded die.
- Explicit exclusions: No assumed rarity, price, trigger order, or Balatro-equivalent implementation; acquisition is governed by D-012.

#### Validation and follow-up
- Riskiest hypothesis: This family adds meaningful build choices without excessive tracking; consistently dominant selections or misunderstood triggers would count against it.
- Method and success/failure criteria: Compare omission and simpler variants in paper builds; tally repeated effects before balance testing. The creator must set measurable power and comprehension criteria after Q-09 is resolved, before playtesting.
- Evidence: Creator proposal, 2026-10-30; creator feedback on the three risky-die responses, 2026-11-01; [Paper round 01](gdd/PAPER_ROUND_01.md) includes negative-face exclusion and penalty-acceptance cases. Scripted checks only; no random simulation or player playtest evidence.
- Confidence: Untested.
- Open questions: Creator owns the boundary questions above; resolve before the first complete build/scoring walkthrough and before accepting this family as specified.
- Revisit trigger: Failure of intended power role, unreadable effects, or dominant strategies under repeated use.
- History: 2026-10-30 — captured the creator's proposal and examples. Subsequent instruction resolved permanent commitment and acquisition in D-012; effect semantics remain proposed.

### D-010: Smaller accumulating die bonuses

- Status: Proposed.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Proposed bonus effects and power role; D-013 owns uniqueness and stacking; D-012 separately confirms compatibility with already-upgraded dice. Not ready for implementation.
- Links: D-001, D-003, D-004, D-008; Q-01, Q-04, Q-09; example catalog below.

#### Why?
- Need or problem and intended outcome: Provide lower-impact additions that let a die gain supporting synergies over time.
- Evidence and assumptions: Creator proposal, 2026-10-30. Relative power and contribution to readable strategy are untested intentions.
- Alternatives considered: Omit bonuses or allow multiple per die. The creator now selects one movable bonus per die; relative power remains exploratory.
- Selected tradeoff, costs, and disadvantages: Accumulation can create steady growth but also a growing reading burden; D-013 selects one bonus per die to bound the number of bonuses; low individual power does not establish low total power.

#### How?
- Mechanism, player actions, and feedback: Attach bonuses to individual dice; bonuses on different dice can contribute when their specified conditions apply. D-015 establishes shop acquisition and sales; detailed purchase flow and effect presentation remain unresolved before the paper build walkthrough.
- System interactions and dependencies: D-008's small pool increases the importance of repeated exposure; D-007 loses the build on run failure. Scoring, timing, and combination recognition depend on Q-09.
- Likely failure modes and safeguards: Hidden triggers or dominant effects undermine D-001 and D-003; walk through effects individually and together, including failed and repeated validations.

#### What?
- Proposed rules: Low power; cannot replace the target die’s faces. The original non-removable proposal is replaced by D-014: player-chosen placement and movement to another die’s free bonus slot; D-015 permits selling. D-013 now permits one bonus per die with no duplicate bonus anywhere in the set, superseding the earlier stacking proposal.
- Parameters and content: Power labels are qualitative. Each example's X is an independent unresolved tuning value, not a shared constant. The catalog below preserves proposed content; values require scoring context before tuning.
- Boundary conditions, exceptions, and recovery: D-012 confirms bonuses may be added after a permanent upgrade without changing its faces. D-013 resolves unique ownership and one bonus per die. Arithmetic, preservation of existing bonuses when a major upgrade is applied, and whether a die must be validated for a face-based bonus to trigger remain unresolved.
- Acceptance criteria for this proposal: Given a die bonus application, its face list is unchanged, including faces established by a major upgrade; an existing major upgrade also remains unchanged. One bonus is supported per die alongside its upgrade; duplicate ownership is prohibited by D-013.
- Explicit exclusions: No assumed rarity, price, trigger order, or Balatro-equivalent implementation; D-015 governs shop acquisition.

#### Validation and follow-up
- Riskiest hypothesis: This family adds meaningful build choices without excessive tracking; consistently dominant selections or misunderstood triggers would count against it.
- Method and success/failure criteria: Compare omission and simpler variants in paper builds; tally repeated effects before balance testing. The creator must set measurable power and comprehension criteria after Q-09 is resolved, before playtesting.
- Evidence: Creator proposal, 2026-10-30; no simulation or player evidence.
- Confidence: Untested.
- Open questions: Creator owns the boundary questions above; resolve before the first complete build/scoring walkthrough and before accepting this family as specified.
- Revisit trigger: Failure of intended power role, unreadable effects, or dominant strategies under repeated use.
- History: 2026-10-30 — captured the creator's proposal and examples without silently resolving ambiguities.

### D-011: Slot-limited Jokers

- Status: Proposed.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Proposed content family; not ready for implementation.
- Links: D-001, D-003, D-004, D-008; Q-01, Q-04, Q-09; example catalog below.

#### Why?
- Need or problem and intended outcome: Provide medium-power effects that can alter allowances, payoff, and combination rules without requiring each effect to be a die upgrade.
- Evidence and assumptions: Creator proposal, 2026-10-30. Relative power and contribution to readable strategy are untested intentions.
- Alternatives considered: Omit Jokers, restrict them to numerical effects, or place all effects on dice. Alternatives have not been tested; the selected proposal is exploratory.
- Selected tradeoff, costs, and disadvantages: A separate slot inventory adds management; rule-changing effects increase exceptions, while slot effects may undermine the intended capacity limit.

#### How?
- Mechanism, player actions, and feedback: Acquire Jokers within a limited inventory; effects can modify action allowance, Mult, or valid combination scoring. D-015 establishes shop acquisition and sales; detailed purchase flow and effect presentation remain unresolved before the paper build walkthrough.
- System interactions and dependencies: D-008's small pool increases the importance of repeated exposure; D-007 loses the build on run failure. Scoring, timing, and combination recognition depend on Q-09.
- Likely failure modes and safeguards: Hidden triggers or dominant effects undermine D-001 and D-003; walk through effects individually and together, including failed and repeated validations.

#### What?
- Proposed rules: Medium power; non-stackable; four base slots containing movable Jokers, selected by the creator as the starting configuration on 2026-11-01. The Invisible joker example explicitly proposes adding one slot, so effective capacity may differ from base capacity.
- Parameters and content: Power labels are qualitative. Each example's X is an independent unresolved tuning value, not a shared constant. The catalog below preserves proposed content; values require scoring context before tuning.
- Boundary conditions, exceptions, and recovery: D-013 excludes already-owned Joker identities from choices. Whether distinct Jokers with overlapping effects combine requires scoring rules; identity uniqueness does not settle effect arithmetic. D-015 permits shop sales. Joker movement is accepted; movement timing, replacement/swap flow, added-slot timing, overflow on sale, self-counting, and combination overlap rules remain unresolved.
- Acceptance criteria for this proposal: Given a Joker effect, its declared rule change is observable. D-013 governs duplicate exclusion; the baseline accommodates four Jokers. Rearrangement does not alter additive scoring under D-019. Extra-slot occupancy rules remain unresolved; no implicit unlimited acquisition.
- Explicit exclusions: No assumed rarity, price, trigger order, or Balatro-equivalent implementation; D-015 governs shop acquisition.

#### Validation and follow-up
- Riskiest hypothesis: This family adds meaningful build choices without excessive tracking; consistently dominant selections or misunderstood triggers would count against it.
- Method and success/failure criteria: Compare omission and simpler variants in paper builds; tally repeated effects before balance testing. The creator must set measurable power and comprehension criteria after Q-09 is resolved, before playtesting.
- Evidence: Creator proposal, 2026-10-30; no simulation or player evidence.
- Confidence: Untested.
- Open questions: Creator owns the boundary questions above; resolve before the first complete build/scoring walkthrough and before accepting this family as specified.
- Revisit trigger: Failure of intended power role, unreadable effects, or dominant strategies under repeated use.
- History: 2026-10-30 — captured the creator's proposal and examples without silently resolving ambiguities.

### D-013: Unique owned bonuses and Jokers; bounded bonus accumulation

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Bonus capacity, uniqueness, and owned-content offer exclusion.
- Links: D-001, D-008, D-010–D-012, D-014–D-015.

#### Why?
- Need and intended outcome: Keep the starting build easy to manage through one permanent upgrade and one movable bonus per die, while encouraging distinct effects across the set.
- Evidence and assumptions: Creator revision, 2026-11-01, replaces the earlier proposed three-bonus cap. Readability and balance remain untested.
- Alternatives considered: Multiple different bonuses per die, repeated copies, and uncapped accumulation.
- Tradeoff: Fewer effects reduce tracking but restrict local synergies and make bonus allocation more consequential.

#### How?
- Give each die one bonus slot separate from its permanent upgrade slot. D-014 permits relocating a bonus to another die’s empty slot outside rounds.
- Track owned bonus and Joker identities and exclude them from subsequent choices.
- Show occupied/free slots; D-023 governs activation feedback. D-015 owns purchases and sales.
- Failure modes: Duplicate ownership, full-capacity purchases, and exhausted offer pools require handling before implementation.

#### What?
- Starting capacity: one movable bonus per die, alongside one permanent upgrade. Five dice therefore support at most five applied bonuses.
- A bonus identity can occur at most once across the dice set. An already-applied bonus or owned Joker cannot appear in choices.
- Multiple bonuses on one die are no longer permitted. This supersedes the earlier stacking rule and proposed cap of three.
- Different identities with similar arithmetic are not automatically duplicates.
- Content requirements: Stable identities, ownership, bonus host die, and slot occupancy.
- A die with a bonus cannot receive a second simultaneously. Direct occupied-slot swaps/replacement flows remain unresolved; existing free-slot relocation is unchanged.
- Acceptance criteria: An empty bonus slot accepts one eligible bonus without changing the upgrade or faces; an occupied slot cannot hold a second. Six addict on any die excludes another Six addict from subsequent choices. Moving it preserves ownership and exclusion.
- Explicit exclusions: Applying identity uniqueness to major upgrades; assuming full-slot purchase handling or an unequipped inventory.
- D-011 separately owns four base Joker slots.

#### Validation and follow-up
- Riskiest hypothesis: One bonus per die preserves meaningful customization with less tracking.
- Method: Walk through acquisition, relocation, duplicate exclusion, and a fully occupied build; then test comprehension.
- Success/failure criteria: Capacity and ownership invariants hold; creator to define player-comprehension thresholds before testing.
- Evidence: Creator instructions only.
- Confidence: Untested.
- Open questions: Creator to resolve full-capacity purchases, direct swaps, exhausted offers, same-batch duplicates, and sold-item reappearance before an acquisition walkthrough.
- Revisit trigger: Insufficient build variety, unreadable developed builds, or frequent unusable offers.
- History: 2026-10-30 — accepted uniqueness and proposed three different bonuses per die. 2026-11-01 — replaced multiple-bonus stacking with one movable bonus per die as the simpler starting configuration.

### D-014: Player placement and relocation of bonuses

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Bonus assignment, relocation, and reversal of the original non-removable bonus proposal.
- Links: D-001, D-008, D-010, D-012, D-013, D-015; Q-04; sections 06 and 10.

#### Why?
- Need or problem: The creator wants players to choose the receiving die and move bonuses between dice with free slots. Only die upgrades remain non-removable.
- Intended player outcome and connection to goals: Reconfigure supporting synergies around permanent dice identities, preserving build experimentation while retaining upgrade commitment.
- Evidence and assumptions: Creator revision, 2026-10-30. The benefit of flexible placement versus its added management burden is untested.
- Alternatives considered: Automatic allocation or permanent attachment; both are replaced by player targeting and relocation.
- Selected tradeoff, costs, and disadvantages: More agency also creates more placement decisions. Restricting rearrangement to outside rounds prevents repeatedly relocating bonuses before each validation, at the cost of committing to the chosen placement for the round.

#### How?
- Mechanism linking the choice to the intended outcome: On acquisition, choose a die with room. Move an owned bonus from its current die to another die with a free bonus slot, keeping that bonus unique in the set.
- Player actions, available information, and feedback: Choose target, select bonus, and move to an eligible die. Relocation is available outside rounds, including shops, and unavailable during rounds. Exact controls and presentation remain unresolved before an interaction prototype.
- System interactions and dependencies: D-013 owns uniqueness and the one-bonus cap; D-012 protects major upgrades and faces; D-015 permits sale. Movement changes which die can trigger the effect.
- Likely failure modes and safeguards: Duplication on transfer, loss on invalid placement, or repeated relocation that overwhelms play. Treat movement as a transfer, enforce the outside-round restriction, and specify invalid-input behavior before implementation.

#### What?
- Selected rules: The player chooses which eligible die receives a bonus. Outside rounds, a bonus can move to another die with a free bonus slot. Bonus placement is fixed during a round; no relocation is permitted between rolls or validations or while resolution is in progress. The source no longer holds it after transfer; the destination does. Major upgrades cannot move, change, or be sold; bonuses and Jokers are sellable through D-015.
- Parameters: Slot means a bonus slot, separate from the upgrade slot. Capacity follows D-013’s starting cap of one per die. “Free slot” means unoccupied; no zero-cost movement rule is inferred. Movement timing is outside rounds only. Any movement cost remains unresolved and is deferred with economy decisions.
- Content/data requirements: Bonus identity, current owner die, and destination capacity. Ownership filtering remains unchanged by a move because the player still owns the bonus.
- Boundary conditions, exceptions, and recovery: An occupied destination slot does not qualify. The creator’s “swapped outside rounds” resolves timing; direct exchange between two occupied slots is not yet specified beyond the earlier free-slot transfer rule. Temporary storage, off-die unequipping, and drag cancellation remain unresolved. Pausing an active round does not place it outside the round for this restriction. Selling is distinct from moving and follows D-015. Applying or moving bonuses leaves upgrades and faces unchanged.
- Acceptance criteria: Given a bonus on die A and room on die B, then a legal move transfers exactly that bonus to B without duplication or changing either die’s upgrade or face list. Given no room on B, then that destination is ineligible for this transfer rule. Given an active round, including between validations or while paused, then bonus relocation is unavailable and attempted relocation leaves placement unchanged. Given an outside-round state and an eligible destination, then the round-timing restriction permits relocation. Given acquisition with eligible dice, then the player chooses the receiving die rather than automatic upgrade-order allocation.
- Explicit exclusions: Moving a major upgrade; interpreting a free slot as a price; granting occupied-slot exchanges or storage by implication; permitting relocation during rounds.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: Relocation makes planning more satisfying without becoming routine busywork. Players feeling compelled to rearrange repeatedly without meaningful choices would challenge the movement rules.
- Method: Walk through placement, outside-round transfer, full destinations, sale, and blocked relocation during an active or paused round.
- Success/failure criteria and why: Each transfer preserves uniqueness, capacity, upgrades, and faces. Creator to set comprehension and management-burden criteria before playtests.
- Evidence: Creator instruction, 2026-10-30; no prototype or player evidence.
- Confidence: Untested.
- Open questions: Outside-round timing is resolved. Creator to resolve occupied-slot exchanges, storage, and invalid-input behavior before an acquisition/relocation walkthrough; movement cost remains deferred with economy decisions.
- Revisit trigger: Relocation creates excessive management or undermines intended risk decisions.
- History: 2026-10-30 — superseded the non-removable bonus clause in D-010; accepted player placement and transfer into another die’s free slot. Subsequent clarification restricts rearrangement to outside rounds.

### D-020: Higher-face point bonuses and lower-face Mult bonuses

- Status: Proposed.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Content-design tendency for face-conditioned die bonuses; not a scoring rule or finalized balance allocation.
- Links: D-001, D-003, D-004, D-010, D-019; Q-01, Q-09.

#### Why?
- Need or problem: The creator proposes differentiating bonus roles by face value to add strategic depth and help distribute effects.
- Intended player outcome and connection to goals: Higher and lower outcomes can support different parts of a points × Mult build, giving players reasons to value more than the largest face number (D-003, D-004).
- Evidence and assumptions: Creator proposal, 2026-11-01. Whether this tendency creates useful depth, intuitive roles, or balanced choices is untested.
- Alternatives considered: Distribute points and Mult bonuses without face-value tendencies, or enforce rigid face-specific roles. The selected proposal is a flexible tendency rather than a universal restriction.
- Selected tradeoff, costs, and disadvantages: A recognizable pattern can aid comprehension but may make content predictable. Depending on base values and other effects, either point or Mult bonuses could dominate; assigning different roles alone does not establish balance.

#### How?
- Mechanism linking the choice to the intended outcome: When designing face-conditioned bonuses, favor point contributions on higher faces and Mult contributions on lower faces. The resulting build can invest in either or combine complementary contributions.
- Player actions, available information, and feedback: Choose, place, and pursue bonuses under the existing acquisition, placement, and dice-action rules. Effect wording still states the actual contribution and eligibility; players need not infer an effect from face value alone.
- System interactions and dependencies: D-019 supplies the points × Mult formula and effect scope. Face distributions, combinations, upgrade effects, trigger frequency, and other bonuses all influence the value of a contribution.
- Likely failure modes and safeguards: One side is consistently more valuable, mixing becomes mandatory, or the tendency is mistaken for an implicit face rule. Compare representative builds after the scoring foundations are specified; retain explicit effect descriptions.

#### What?
- Proposed guideline: Higher-face bonuses tend to contribute more to points; lower-face bonuses tend to contribute more to Mult. Exceptions are permitted. This does not require every high-face bonus to add points, every low-face bonus to add Mult, or every effective build to mix the two.
- Parameters: The meaning of higher/lower, any middle-face treatment, effect distribution, and bonus values remain unresolved. No 1–3 versus 4–6 division, per-face formula, or numeric balance ratio is selected.
- Content/data requirements: Annotate representative bonuses with face condition, points/Mult contribution, activation scope, and intended role. The existing Six addict points example is compatible with the proposed tendency but is not balance evidence. Existing upgrade examples are not rewritten by this bonus-focused guideline.
- Boundary conditions, exceptions, and recovery: D-019 now establishes automatic face points from combination members only: 4–4–6 recognized as Pair adds 8 face points. This proposal concerns bonus distribution, not that baseline rule. Odd/even or other multi-face conditions need individual design rationale rather than forced classification. No numeric economy work is introduced.
- Acceptance criteria for the proposal: Given a reviewed bonus catalog, then the intended higher-face/points and lower-face/Mult tendency is visible in representative content and exceptions are explicit. Given a concrete effect, then its description determines its contribution; the general guideline does not add an unstated modifier. A measurable content-distribution target awaits prototype scope.
- Explicit exclusions: Changing D-019’s face-point rule, rigid low/high partitions, guaranteed balance, mandatory mixed-face builds, or immediate bonus-value tuning.

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it: Differentiating roles produces meaningful build choices. One contribution type consistently dominating across comparable acquisition costs and activation frequencies would count against the selected content or values.
- Method: Once base values and numeric boundaries exist, using D-019’s additive scoring, compare representative high-face, low-face, and mixed builds; assess clarity alongside score contribution and consistency.
- Success/failure criteria and why: Each tested effect must have a defined condition and contribution, and alternatives must be compared in a stated scoring context. Creator to set balance and comprehension criteria before numerical tests; no values are chosen now.
- Evidence: Creator proposal, 2026-11-01; no numerical model or player evidence.
- Confidence: Untested.
- Open questions: Automatic face contributions are resolved under D-019. Creator to define representative bonus roles and distribution before catalog expansion, and numeric values in the later tuning pass.
- Revisit trigger: The tendency creates a dominant strategy, confusing exceptions, or too little meaningful variety.
- History: 2026-11-01 — captured the proposed tendency without treating it as a decision on raw face scoring.

### Proposed example catalog

Names and effects below come from the creator’s proposal on 2026-10-30, with subsequent removals recorded in the change history. Eight examples remain in the active catalog. Each X is untuned; D-019 establishes points × Mult, with combination base values modified by dice and effects. Combination membership is specified per effect under D-019; validated dice are the default scope and held triggers must be explicit. Scoring contributions add independently under D-019; detailed non-scoring timing and numeric boundaries remain open. D-018 defines a short straight as four consecutive values; remaining recognition details for the categories and exceptions still require specification. Power role is owned by the relevant family record.

| Family | Name | Proposed effect | Required clarification before executable specification |
| --- | --- | --- | --- |
| Die upgrade | All or nothing | Replace faces with 1, 1, 1, 6, 6, 6. Mult +X for a 1 and −X for a 6 (creator-revised signs). | D-019 establishes validated-die scope by default; D-024 establishes equal face probabilities. Detailed timing remains open. Under D-019, negative raw outcomes are shown but credit zero; scoring deltas add independently. |
| Die upgrade | Odd master | Replace faces with 1, 1, 3, 3, 5, 5. Mult +X per odd die. | Which dice count: selected, scoring, or all five; whether the upgraded die must trigger; self-counting; interaction between copies on different dice. |
| Die bonus | Fool of full | Add X points if this die is used in a full. | Definition of full; participating-die test; bonus stage and stacking. |
| Die bonus | Six addict | Add X points if this die is 6; no combination-membership condition in this wording (D-019). | Validated-die scope by default; detailed trigger timing and X remain unresolved; points contributions are additive under D-019. |
| Joker | High roller | Can roll one more time. | Allowance timing: initial round budget versus immediate remaining uses; removal behavior; interaction with automatic rerolls. |
| Joker | Joker master | +X Mult per Joker. | Counts itself or not; owned/active Joker definition; trigger timing. |
| Joker | Invisible joker | Add 1 Joker slot. | Whether it occupies a slot itself, capacity validation timing, and overflow on removal. If it occupies one slot and adds one, it creates no net extra room for other Jokers, though it may contribute to Joker-count effects. |
| Joker | Odd straight | Odd dice can now produce a short straight. | Exact qualifying multisets, required length, duplicate handling, and treatment of ordinary straights. Do not silently assume 1–3–5 qualifies without defining the rule. |

### Balance questions to test

These are hypotheses and specification risks, not additional rules:

- Frequent reuse of the same five dice may amplify a modest per-trigger bonus. Compare cumulative contributions across a round, not only one activation.
- Under D-024, All or nothing gives 1 and 6 a probability of 3/6 each; Odd master gives each of 1, 3, and 5 a probability of 2/6.
- Up to five different bonuses under D-013’s current cap could overwhelm the intended upgrade > Joker > bonus power roles in aggregate. Decide whether those roles compare individual effects or total family contribution; a bounded effect count does not establish low cognitive burden or balanced scoring.
- Face replacement may strengthen some combinations and remove others. Test the cost of committing to an upgrade against future offers and targets.
- Joker-count and slot effects interact even when a slot-granting Joker adds no net capacity for other Jokers.

## 08 — World, levels, and spatial structure

- Applicability: Undecided.
- Rationale: Methodology coverage requirement; [D-001](#d-001-accessibility-and-independent-design-direction) establishes the shared frame. Specific applicability remains open where marked Undecided.
- Owner: Project creator.
- Maturity: Unexplored.
- Summary and boundaries: Biomes are confirmed as progression boundaries in D-012. D-016 establishes five biomes and their round sequence. Their content and spatial or thematic meaning remain unresolved.
- Decision records: D-016 governs biome count and route; D-012 governs biome-start upgrade choices.
- Supporting specifications and evidence: Creator instruction, 2026-10-30; no spatial model selected.
- Dependencies and open questions: Core loop; creator to assess applicability before prototype scope.

## 09 — Narrative and expressive systems

- Applicability: Undecided.
- Rationale: Methodology coverage requirement; [D-001](#d-001-accessibility-and-independent-design-direction) establishes the shared frame. Specific applicability remains open where marked Undecided.
- Owner: Project creator.
- Maturity: Unexplored.
- Summary and boundaries: Theme, tone, identity, narrative, and player expression.
- Decision records: None yet.
- Supporting specifications and evidence: No setting or story selected.
- Dependencies and open questions: Q-01; creator to assess expressive role before presentation direction.

## 10 — Interaction, interface, and information

- Applicability: Applicable.
- Rationale: Methodology coverage requirement; [D-001](#d-001-accessibility-and-independent-design-direction) establishes the shared frame. Specific applicability remains open where marked Undecided.
- Owner: Project creator.
- Maturity: Exploring.
- Summary and boundaries: Base-only selection preview and visual trigger cues preserve anticipation; the final score is revealed at the end of scoring animation. Detailed controls remain unresolved.
- Decision records: D-001, D-023.
- Supporting specifications and evidence: Creator brief and clarification above.
- Dependencies and open questions: Q-04, Q-07, Q-08; creator to define interaction tasks before UI prototype.

### D-023: Base-only combination preview and animated score reveal

- Status: Accepted.
- Owner: Project creator.
- Updated: 2026-11-01.
- Scope: Pre-commit selection feedback and post-commit score/outcome presentation.
- Links: D-001, D-003, D-005, D-006, D-018, D-019, D-022; sections 11–13.

#### Why?
- Need or problem: An exact score or target-clear preview would reveal the payoff before the player commits, undermining the intended anticipation.
- Intended player outcome: Recognize a promising combination and active build effects, commit, then discover whether the payoff clears the target through the scoring animation.
- Evidence and assumptions: Explicit creator direction, 2026-11-01. The expected emotional benefit and readability of visual cues remain untested.
- Alternatives considered: Exact final points × Mult, final contribution, and a target-reached indicator before commitment were proposed and rejected by the creator.
- Selected tradeoff: Prioritize anticipation over immediate arithmetic certainty. Manual calculation remains possible from known rules and effects, but the interface does not automate that calculation before commitment.

#### How?
- Selection feedback identifies the recognized combination and its unmodified base values. Activation cues communicate which effects meet their conditions without aggregating their numerical contribution.
- Eligible die bonuses and Jokers receive a shine sweep. Die upgrades use individually designed effects themed to that upgrade, activating when their conditions are met.
- Committing begins the scoring animation; its completion reveals the final score and whether the round target was reached.
- Dependencies: D-018 determines recognition; D-019 determines effect eligibility and arithmetic; D-022 supplies base values. Presentation does not change additive, order-independent scoring.
- Failure modes: An early projected round total, win indicator, or completed score breakdown would disclose the outcome. Visual activity can also be misread as always beneficial: a triggered negative die effect uses the crack VFX cue specified below to signal danger without revealing its numerical impact.

#### What?
- Before commitment, show the recognized combination and base points/base Mult only. Do not include automatic die-face points or effect contributions in those base values.
- Example: selecting four 6s with All or nothing shows Four of a kind with base 50 points × 7 Mult. The upgrade has its themed activation cue; the interface does not show the worked example's final 74 × 4, 296 score, or target-clear result.
- Shine sweeps identify bonuses/Jokers whose activation conditions are met by the current selection/context. Apply actual effect scopes, including explicit held-die conditions; do not equate selected dice with all eligible effects.
- Upgrade activation feedback is bespoke per upgrade rather than using the generic bonus/Joker shine sweep.
- When a die will apply a negative effect under the current selection/context, show a crack VFX animation on that die before commitment. This signals an active negative effect, not a prediction that the full validation will lose points or fail. For example, All or nothing on a validated 6 shows the crack cue; holding it does not trigger its default validated-only penalty. The cue reveals neither the penalty magnitude nor the final score.
- A negative die cue and positive activation cues may coexist when both conditions are met; exact visual composition remains to be designed. Crack VFX is feedback only and does not imply die damage, destruction, or a new gameplay state.
- These pre-commit activation cues give no computed numerical contribution or final-strength number. Existing effect descriptions and rules remain available; this decision does not hide their stated values.
- Withhold the final validation score, projected round total, and explicit target-clear prediction before commitment and until the scoring animation finishes. Intermediate animation stages and their numerical presentation remain to be designed.
- D-006's immediate round-end rule remains logical: a completed validation meeting the target permits no further round action. D-023 governs when the player sees that result; it does not authorize extra play during the reveal.
- Signed negative outcomes and zero round credit still follow D-019; reveal timing does not alter scoring.
- Parameters: No animation duration, sweep frequency, sequencing, or intensity selected.
- Content requirements: A themed activation treatment for every die upgrade; shared bonus/Joker shine treatment; recognition and eligibility feedback tied to current state.
- Acceptance criteria: Given a changed selection, show its recognized category/base values and corresponding activation cues without a computed total. Given a winning committed selection, do not announce success or reveal its final score before the scoring animation completes. Given the paper Four-of-a-kind fixture, show 50 × 7 and a crack cue on the upgraded 6 before commitment and reveal 296 at completion, rather than previewing 74 × 4. Given that same upgraded 6 is held and has no eligible held penalty, do not show an active-penalty crack cue for that upgrade.
- Explicit exclusions: Exact-score previews, pre-commit win guarantees, numerical strength meters derived from the complete score, or claims that players cannot calculate the result themselves.

#### Validation and follow-up
- Riskiest hypothesis: Visual eligibility cues provide enough understanding to make deliberate choices while preserving uncertainty about the payoff. Confusion about why effects trigger, or routinely feeling forced to calculate everything manually, would challenge the presentation.
- Method: Prototype selection changes and scoring reveals for positive, negative, and mixed-effect hands; observe comprehension, anticipation, and calculation behavior.
- Success/failure criteria: All preview/reveal acceptance cases pass; creator to define player-test thresholds before testing. Do not treat creator preference as measured player response.
- Evidence: Creator instruction only; existing paper-round numbers explain rules to designers and are not a player-facing preview specification.
- Confidence: Untested.
- Open questions: Creator to define animation stages, pacing/speed controls, crack styling and composition with other die cues, negative Joker cue treatment, persistent/passive Joker cue semantics, and readable reduced-motion alternatives before the interface prototype. Alternatives must preserve the information boundary; their exact presentation is not selected here.
- Revisit trigger: Cues obscure eligibility, animation pacing becomes tedious, or the interface unintentionally reveals the result early.
- History: 2026-11-01 — rejected assistant's exact-preview proposal; accepted base-only feedback, visual activation cues, and final reveal after scoring animation. Subsequent creator confirmation selected crack VFX to signal an active negative die effect.

## 11 — Accessibility, inclusion, and player comfort

- Applicability: Applicable.
- Rationale: Methodology coverage requirement; [D-001](#d-001-accessibility-and-independent-design-direction) establishes the shared frame. Specific applicability remains open where marked Undecided.
- Owner: Project creator.
- Maturity: Exploring.
- Summary and boundaries: Reduced management and easier understanding; wider access needs still require exploration.
- Decision records: D-001; specific accessibility features remain unresolved.
- Supporting specifications and evidence: Creator clarification above.
- Dependencies and open questions: Q-06–Q-08; creator to define access needs before UI prototype.

## 12 — Visual direction and motion

- Applicability: Applicable.
- Rationale: Methodology coverage requirement; [D-001](#d-001-accessibility-and-independent-design-direction) establishes the shared frame. Specific applicability remains open where marked Undecided.
- Owner: Project creator.
- Maturity: Exploring.
- Summary and boundaries: Softer UI is a brief-level intent; palette, typography, motion, and art style remain open.
- Decision records: D-001, D-023 (activation effects and score-reveal boundary); detailed visual treatments remain open.
- Supporting specifications and evidence: Creator brief above.
- Dependencies and open questions: Q-07; creator to examine references before visual prototype.

## 13 — Audio, music, voice, and haptics

- Applicability: Undecided.
- Rationale: Methodology coverage requirement; [D-001](#d-001-accessibility-and-independent-design-direction) establishes the shared frame. Specific applicability remains open where marked Undecided.
- Owner: Project creator.
- Maturity: Unexplored.
- Summary and boundaries: Role of sound, silence, feedback, and optional haptics.
- Decision records: None yet.
- Supporting specifications and evidence: No sonic direction selected.
- Dependencies and open questions: Intended experience and platforms; creator to assess scope before audiovisual prototype.

## 14 — Social, multiplayer, and community

- Applicability: Undecided.
- Rationale: Methodology coverage requirement; [D-001](#d-001-accessibility-and-independent-design-direction) establishes the shared frame. Specific applicability remains open where marked Undecided.
- Owner: Project creator.
- Maturity: Unexplored.
- Summary and boundaries: Whether social play, sharing, competition, or community features serve the concept.
- Decision records: None yet.
- Supporting specifications and evidence: No player count or connectivity commitment.
- Dependencies and open questions: Q-08; creator to assess inclusion before prototype scope.

## 15 — Persistence, runtime, and technical requirements

- Applicability: Applicable.
- Rationale: Methodology coverage requirement; [D-001](#d-001-accessibility-and-independent-design-direction) establishes the shared frame. Specific applicability remains open where marked Undecided.
- Owner: Project creator.
- Maturity: Unexplored.
- Summary and boundaries: Player-visible interruption, save, recovery, and runtime requirements.
- Decision records: None yet.
- Supporting specifications and evidence: No technical specification or build linked.
- Dependencies and open questions: Platforms and loop; creator to define recovery before playable prototype specification.

## 16 — Commercial model and player commitments

- Applicability: Undecided.
- Rationale: Methodology coverage requirement; [D-001](#d-001-accessibility-and-independent-design-direction) establishes the shared frame. Specific applicability remains open where marked Undecided.
- Owner: Project creator.
- Maturity: Unexplored.
- Summary and boundaries: Funding, distribution, ownership, and player commitments.
- Decision records: None yet.
- Supporting specifications and evidence: No commercial model selected.
- Dependencies and open questions: Q-08; creator to establish constraints before production commitment.

## 17 — Release, live operation, and end of service

- Applicability: Undecided.
- Rationale: Methodology coverage requirement; [D-001](#d-001-accessibility-and-independent-design-direction) establishes the shared frame. Specific applicability remains open where marked Undecided.
- Owner: Project creator.
- Maturity: Unexplored.
- Summary and boundaries: Launch scope and whether ongoing operations are relevant.
- Decision records: None yet.
- Supporting specifications and evidence: No release or service plan selected.
- Dependencies and open questions: Product boundaries; creator to assess applicability before production commitment.

## 18 — Production, validation, and design governance

- Applicability: Applicable.
- Rationale: Methodology coverage requirement; [D-001](#d-001-accessibility-and-independent-design-direction) establishes the shared frame. Specific applicability remains open where marked Undecided.
- Owner: Project creator.
- Maturity: Exploring.
- Summary and boundaries: Apply the methodology; establish frame, then model and test the smallest complete experience.
- Decision records: Methodology governs the process; project-specific production choices remain open.
- Supporting specifications and evidence: Methodology; evidence and change history below.
- Dependencies and open questions: Q-01–Q-08; creator to set prototype criteria and resources before prototype work.

## Prototypes, specifications, and evidence

[Paper round 01 — All or nothing](gdd/PAPER_ROUND_01.md), 2026-11-01: a scripted regular-round walkthrough with a test-only 300-point target and revised upgrade effect (+3 Mult on 1, −3 on 6). Verifies scoring, retention, manual-only reroll consumption, immediate success, symbolic settlement, and negative/final-validation boundary cases. Arithmetic checked; no random simulation, player playtest, or balance validation. The supplied Balatro analysis remains reference material, not validation of Paroli.

## Glossary

| Term | Working meaning |
| --- | --- |
| Accessibility intent | In this brief: fewer things to manage and easier understanding, without reducing punishment. Broader accessibility needs remain to be explored. |
| Management burden | Tracking and maintaining resources, inventories, effects, or other state across decisions. The specific burdens to remove remain unresolved. |
| Comprehension | Understanding available actions, relevant rules, and their consequences. |
| Punishment | Round failure immediately ends the run and loses the current build (D-007); other consequences and persistence boundaries remain open. |
| Softer UI | Creator's presentation intent; visual and interaction meaning not yet specified. |
| Build | Configuration shaping payoff and odds; proposed content is die upgrades, die bonuses, and Jokers (D-009–D-011). |
| Held / in hand | A die kept out of the current validation. Its die effects activate only if they explicitly specify held eligibility (D-019). |
| Mult | Multiplier in D-019: begin with the recognized combination’s base Mult, apply eligible modifiers, then multiply final points by final Mult. Flat modifiers add first; percentage Mult increases sum into one factor applied afterward, independently of effect order. Zero yields zero score; negative Mult remains visible in the raw calculation, while credited score is floored at zero. Other bounds and numeric values remain unresolved. |
| X | Untuned parameter local to an example effect; not one shared value across content. |
| Raw validation score | Signed product of final points and final Mult; shown even when negative (D-019). |
| Credited score | max(0, raw validation score), added to the existing round score without reducing it (D-019). |
| Validate | Commit selected dice, add the credited score to the round total, then reroll those dice while keeping others. D-019 defines points × Mult; effect resolution and terminal-round reroll timing remain open (D-005, D-006). |
| Roll | Manual reroll of selected dice, consuming one reroll use. The opening roll and automatic post-validation rerolls consume none (D-005). |
| Biome | Run segment whose entry can trigger a major upgrade choice under D-012; D-016 fixes five biomes with two regular rounds and a boss each; theme and time duration remain unresolved. |
| Starter | Creator’s term for a starting choice or configuration that may alter action allowances; its form remains unresolved. |
| Round | Score-target challenge with limited validations (D-006); session placement and transitions remain unresolved. |
| Run | Play session that ends on round failure with loss of the current build (D-007); victory, overall structure, and other reset boundaries remain unresolved. |

## Design change history

| Date | Decisions | Change and rationale | Evidence and follow-up |
| --- | --- | --- | --- |
| 2026-10-30 | D-001, D-002 | Created the GDD from the creator's brief; separated confirmed accessibility intent from the proposed dice premise; accounted for all methodology areas. | Creator clarification and repository documents. Establish player experience and prioritized pillars next; no implementation or save migration applies. |
| 2026-10-30 | D-003; D-001 context | Established combination-building as the source of anticipation and pushing luck as the pursuit of a planned payoff. Updated summary and Q-01. | Creator clarification; define what combinations change next. No playable mechanics accepted. |
| 2026-10-30 | D-004; D-003 follow-up | Accepted builds influencing both desired-outcome value and likelihood; updated summary and Q-01. | Creator selection. Confirm dice premise and explore concrete build elements next; no specific mechanic accepted. |
| 2026-10-30 | D-005; D-002 superseded | Accepted selected-dice validation and rerolling with limited allowances modifiable by upgrades or starter; confirmed dice premise. | Creator instruction. Define post-validation behavior and counter semantics next; no implementation migration applies. |
| 2026-10-30 | D-005 | Resolved post-validation behavior: reroll validated dice and keep the others. Updated summary, Q-02, acceptance cases, and glossary. | Creator clarification. Automatic reroll cost and round-end ordering remain open; define round goals next. |
| 2026-10-30 | D-006; D-005 dependencies | Accepted cumulative round scoring toward a target within limited validations, including last-validation success precedence. | Creator confirmation. Define failure consequences, score calculation, and transitions next. |
| 2026-10-30 | D-007; D-006 dependencies | Accepted immediate run termination and current-build loss on round failure; updated failure references and Q-05. | Creator instruction. Define the build, success flow, and broader persistence boundaries next. |
| 2026-10-30 | D-008–D-011 | Established five total dice; captured proposed upgrades, bonuses, Jokers, and nine examples with explicit unresolved semantics. | Creator proposal. Resolve commitment and trigger/scoring rules before balance claims; no implementation migration applies. |
| 2026-10-30 | D-012; D-009–D-010 dependencies | Established three-option major upgrades at run/biome starts, automatic allocation to the next unupgraded die, and permanent commitment until run end. | Creator instruction. Initial-entry overlap and whether upgraded dice may receive bonuses remain open. |
| 2026-10-30 | D-012 | Resolved opening timing: one upgrade choice serves run start and biome 1; the next occurs on entering biome 2. | Creator confirmation. Updated acceptance cases; total biome count and bonus coexistence remain open. |
| 2026-10-30 | D-012; D-009–D-010 dependencies | Confirmed that upgraded dice may receive bonuses without changing their major upgrade or upgraded faces. | Creator confirmation. Duplicate bonus stacking, caps, triggers, and preservation of bonuses applied before an upgrade remain open. |
| 2026-10-30 | D-013; D-010–D-011 dependencies | Clarified unique bonus ownership across the set, exclusion of owned bonuses/Jokers from choices, and different-bonus stacking. Proposed cap: three bonuses per die, additional to its upgrade. | Creator clarification. Resolve bonus targeting and exhausted offer/capacity behavior; cap remains provisional. |
| 2026-10-30 | D-014–D-015; D-010–D-013 revisions | Replaced permanent bonus attachment with player targeting and relocation into free slots. Added shops, buying/selling bonuses and Jokers, whole-shop refresh, and discounted random purchases. | Creator revision. Economy balancing deferred; movement timing, refresh limit, and precise shop transitions remain open. |
| 2026-10-30 | D-014; D-010 and D-013 references | Restricted bonus rearrangement to outside rounds; placement stays fixed through an active round. | Creator clarification. Updated normal and blocked-action acceptance cases; retained the existing free-slot transfer rule. |
| 2026-10-30 | D-015 | Replaced the one-use shop-refresh interpretation with repeatable whole-shop rerolls, each costing more coins than the previous one. | Creator clarification. Prices, increase formula, and new-shop cost reset remain deferred. |
| 2026-11-01 | D-016; D-012 and D-015 dependencies | Fixed the run route at five biomes, each with two regular rounds followed by a boss; shops after regular rounds only. Full totals: five upgrades, ten shops, fifteen rounds. | Creator instruction. Boss mechanics and final completion presentation remain open; economy tuning stays deferred. |
| 2026-11-01 | D-017; D-006 and D-016 dependencies | Established higher targets on every successive round and an additional build-challenging special rule for each boss. | Creator instruction. Define boss visibility and representative rules next; numerical target tuning remains deferred. |
| 2026-11-01 | D-017; D-016 flow | Fixed boss-rule reveal after the biome upgrade choice and before its first regular round, including biome 1. | Creator clarification. Specific rules, selection method, and preview presentation remain open. |
| 2026-11-01 | D-018; Q-09 and example catalog | Established highest-ranked recognized combination precedence by default, with explicit Joker exceptions for combination stacking. | Creator confirmation. Define category catalog, hierarchy, participating dice, and scoring formula next. |
| 2026-11-01 | D-018; Q-09 | Accepted the nine-category hierarchy, from Single die to Five of a kind; added the authoritative rank table. | Creator confirmation. Straight lengths, recognition details, and score values remain open. |
| 2026-11-01 | D-018; D-011 example catalog | Defined short straight as four consecutive values and removed Straight with pair from the active Joker examples. | Creator instruction. Eight examples remain; long-straight length and Odd straight recognition rules remain open. |
| 2026-11-01 | D-019; D-006, D-018, glossary, and example references | Established points × Mult from combination base values modified by dice/effects; allowed die bonuses independent of combination type. | Creator confirmation. Resolve dice participation, trigger timing, modifier order, and numeric boundaries before a scoring walkthrough; lone-wolf concept remains unspecified. |
| 2026-11-01 | D-019; Six addict example | Clarified that each bonus or upgrade effect controls combination-membership eligibility; added conditional and face-only 6 examples. | Creator clarification. Membership-independent does not automatically mean held dice trigger; default scope and timing remain open. |
| 2026-11-01 | D-019; Six addict and glossary | Established validated-die scope by default; held effects must state that condition explicitly, e.g. “+X points if in hand.” Added validated/held eligibility cases. | Creator confirmation. Default face contributions, effect ordering, detailed trigger timing, and numeric bounds remain open. |
| 2026-11-01 | D-020 | Proposed higher-face bonuses favoring points and lower-face bonuses favoring Mult, with exceptions allowed. | Creator proposal. Automatic face-value contribution remains unanswered; no face partition or bonus values selected. |
| 2026-11-01 | D-019; D-020 dependency | Established automatic face points only from dice forming the recognized combination; 4–4–6 as Pair adds 8 points before final points × Mult scoring. | Creator confirmation. Updated formula and acceptance cases; independent-effect eligibility remains unchanged. Modifier order and participating-subset ties remain open. |
| 2026-11-01 | D-019; D-020 and example references | Established separate additive points and Mult totals followed by one final product; scoring effect order does not change the result. | Creator clarification. No multiplicative scoring modifiers selected; negative totals, bounds, and non-scoring rule interactions remain open. |
| 2026-11-01 | D-019; All or nothing and glossary | Allowed final Mult to reach zero for high-risk/high-reward effects; that validation contributes zero score and still uses its validation opportunity. | Creator decision. Negative-total policy remains open; no clamp or negative-score behavior inferred. |
| 2026-11-01 | D-019; scoring glossary and All or nothing references | Preserve and display negative raw outcomes; credit max(0, raw score), leaving previously earned round score intact. | Creator decision. Updated formula, negative-result acceptance cases, and an arithmetic-only example; remaining numeric representation and point-total bounds stay open. |
| 2026-11-01 | D-005 | Set the baseline starter to three validations and three rerolls per round, as separate provisional allowances. | Creator decision. Balance later alongside target scores; initial-roll and automatic-reroll accounting remain open. |
| 2026-11-01 | D-005 | Confirmed that only manual rerolls consume the reroll allowance; initial and automatic post-validation rolls are free, including when manual uses are exhausted. | Creator confirmation. Updated normal and zero-rerolls acceptance cases; round-reset/carryover policy remains open. |
| 2026-11-01 | D-021; D-005 and D-006 dependencies | Confirmed zero starting score and restored per-round allowances without carryover; unused validations convert to bonus coins while unused rerolls are discarded. | Creator confirmation. Conversion rate deferred; exact target-clear termination and settlement ordering remain open. |
| 2026-11-01 | D-006; D-021 | Confirmed immediate round completion when a validation reaches or exceeds the target, followed by unused-validation coin settlement; no further round actions. | Creator confirmation. Terminal reroll presentation remains open without delaying logical round completion. |
| 2026-11-01 | D-018; D-019 dependencies | Confirmed four-value Short straight, five-value Long straight, and highest-valued validated die for Single die. | Creator confirmation. Added long-straight precedence and Single die face-point cases; category base values and participating-subset ties remain open. |
| 2026-11-01 | D-022 | Proposed base points and Mult for all nine categories, with calculated unmodified ranges and worked cases. | User requested joint review. Values remain proposed; no target or economy tuning performed. |
| 2026-11-01 | D-022; D-018 and D-019 references | Accepted the nine-category base-point and base-Mult table as provisional starting balance, with every value unchanged. | Creator approval. Values remain tunable and untested; next step is a representative paper round, not final target/economy balancing. |
| 2026-11-01 | D-005, D-006, D-019, D-021, D-022 evidence | Added Paper round 01 with one All or nothing upgrade, explicit test-only values, a completed regular round, and boundary cases. | Scripted arithmetic walkthrough only. Main path: 90 + 245 = 335 against target 300; one unused validation converts via the unresolved coin formula. No production values changed. |
| 2026-11-01 | D-009 example catalog; Paper round 01 | Reversed All or nothing to +X Mult on 1 and −X Mult on 6; updated the walkthrough with matching D1 outcomes and rechecked scores. | Creator revision. Paper-only X = 3 remains provisional; main-path scores stay 90 + 245 = 335 because the upgraded die is outside each recognized combination. |
| 2026-11-01 | D-009; Paper round 01 feedback | Recorded the intended risky-die responses: reroll, exclude, or include despite the penalty. Added an isolated case where including the penalized die completes Four of a kind and immediately wins. | Creator endorsement of the decision space. Arithmetic checked: 296 with penalty versus 152 without the die; no balance conclusion. |
| 2026-11-01 | D-023; sections 10 and 12 | Accepted base-only combination previews, shine sweeps for eligible bonuses/Jokers, bespoke upgrade cues, and final score reveal only after commitment and completion of scoring animation. | Creator rejected exact-score previews to preserve anticipation. Animation pacing and detailed cue treatments remain open. |
| 2026-11-01 | D-023 | Selected a crack VFX animation on a die to hint an eligible negative effect before commitment. | Creator confirmation. This signals the effect’s negative contribution, not the overall validation outcome; final-score reveal policy is unchanged. |
| 2026-11-01 | D-024; D-008 and content references | Established six equally likely face positions, standard 1–6 dice, and independent rolls across all roll sources. | Creator confirmation of the proposed model. Repeated values increase outcome probability through face counts; no balance validation implied. |
| 2026-11-01 | D-010–D-014 | Set starting capacity to one permanent upgrade and one movable bonus per die, plus four movable Joker slots. | Creator revision supersedes the three-bonus proposal. Bonus movement remains outside rounds; Joker movement timing remains open. Balance remains untested. |

| 2026-11-11 | D-019; Effects catalog | Percentage Mult increases sum additively and apply once after flat Mult; recorded deterministic membership ties and linked the current effect catalog. | Creator requested additive percentages and an autonomous balance pass. Numeric effect tuning remains provisional, without playtest evidence. |
