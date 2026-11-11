# Game Design Methodology

## 1. Purpose

This methodology defines how we structure, build, validate, and maintain a game design document (GDD). It is reusable across genres, platforms, business models, and production scales. It describes the questions a design must answer without prescribing the answers.

Our GDD is the shared specification of the intended player experience and the rules, content, presentation, and services that produce it. It must help a reader understand a decision, implement it, test it, and reconsider it when evidence changes.

For this project, the initial concept is a Yahtzee-based game inspired by Balatro. That is a starting hypothesis, not permission to inherit either game's rules, progression, presentation, or business model without examination. Game-specific decisions belong in the GDD, not in this methodology.

### Principles

- Start with the intended player experience and explain how each system supports it.
- Separate intent, mechanism, and specification through **Why / How / What**.
- Make uncertainty visible. An untested assumption must not read like an established fact.
- Specify observable behavior, including failure paths and edge cases.
- Give each fact, rule, and value one authoritative home; link rather than duplicate.
- Scale detail to uncertainty, impact, and production stage. Explore cheaply before specifying exhaustively.
- Treat the GDD as a maintained design model, not a one-time pitch or a transcript of discussions.

## 2. The mandatory Why / How / What contract

Every normative statement—anything asserting what the game should be or do—must belong to an identified decision record with all three answers. Section titles, navigation, glossary entries, and raw observations do not need artificial decision records. However, any design conclusion drawn from them does.

Several closely related rules may share a record when they have the same rationale, mechanism, owner, and validation plan. Split them when they can change independently or require different justifications. Do not create one record per sentence, or hide unrelated choices inside a single broad record.

| Question | Required answer | Insufficient answer |
| --- | --- | --- |
| **Why?** | The player need, intended experience, or production constraint; the expected benefit; the relevant pillar; and the tradeoff being accepted. | “It is fun,” “other games do it,” or a restatement of the feature. |
| **How?** | The causal mechanism: player actions, rules, information, feedback, and system interactions that should produce the intended result. Explain why this mechanism is expected to work. | “Add a progression system” without explaining its effects on play. |
| **What?** | The concrete specification: states, inputs, outputs, conditions, content, values or bounded unknowns, exceptions, and observable acceptance criteria. | “Make progression satisfying” without testable behavior. |

Read decisions in both directions: **Why → How → What** checks that intent becomes behavior; **What → How → Why** checks that each specified feature serves a purpose. A decision without a credible connection in either direction needs revision or removal.

### Supporting evidence and uncertainty

Each record must distinguish:

- **Evidence:** an observation or external constraint, with a source, date, and relevant context.
- **Assumption:** a belief being relied on without sufficient evidence.
- **Hypothesis:** a prediction that can be tested, including what would count against it.
- **Decision:** the selected direction and its rationale, even if provisional.
- **Open question:** an unresolved issue with an owner, next action, and resolution deadline or gate.

References and comparable games are useful evidence of possible mechanisms; they are not proof that a mechanism suits our audience or our game. Numerical claims need units and provenance. Placeholder tuning values must be labeled as such.

### Decision record template

Use this template inside the relevant GDD section. A small decision can answer fields in a few sentences; a complex system can link to supporting specifications.

```markdown
### D-<stable ID>: <decision title>

- Status: Proposed | Accepted | Superseded | Rejected
- Owner: <person or role; one accountable owner>
- Updated: <YYYY-MM-DD>
- Scope: <affected systems, modes, platforms, and player groups>
- Links: <parent goals/pillars, dependencies, related decisions>

#### Why?
- Need or problem:
- Intended player outcome and connection to goals:
- Evidence and assumptions:
- Alternatives considered, including omission or a simpler approach:
- Selected tradeoff, costs, and disadvantages:

#### How?
- Mechanism linking the choice to the intended outcome:
- Player actions, available information, and feedback:
- System interactions and dependencies:
- Likely failure modes and safeguards:

#### What?
- Exact rules, states, inputs, outputs, and transitions:
- Parameters: <value/range, units, source, tunable or fixed>
- Content/data requirements and authoritative references:
- Boundary conditions, exceptions, and recovery behavior:
- Acceptance criteria: <observable Given / When / Then cases>
- Explicit exclusions:

#### Validation and follow-up
- Riskiest hypothesis and evidence that would disprove it:
- Method: <prototype, playtest, simulation, review, etc.>
- Success/failure criteria and why those criteria are appropriate:
- Evidence: <links, dates, build/configuration, participants/context, limits>
- Confidence: Untested | Preliminary | Supported | Contradicted
- Open questions: <owner, next action, due date or gate>
- Revisit trigger:
- History: <change summary; replacement ID if superseded>
```

Do not leave required fields blank. Use “Not applicable — <reason>” where justified. Use “Unresolved — <owner, action, gate>” for real unknowns; this makes a record incomplete rather than silently complete. Acceptance requires a coherent Why / How / What and explicit handling of remaining uncertainty. It does not imply that the design has been validated.

### Example of the reasoning standard

This example illustrates the format only; it does not establish a feature for this project.

- **Why:** Players should be able to compare consequential options without relying on short-term memory. We accept some additional screen space to support deliberate choices.
- **How:** Keep selected options visible together until the player commits, so comparing them does not require remembering a previous screen.
- **What:** A comparison view displays the same labeled attributes for each selected option. Closing the view preserves the current selection and does not commit a choice. Define limits, input bindings, overflow behavior, and missing-value treatment in the UI specification.
- **Validation:** Test representative comparison tasks for mistaken commitments and comprehension. Set the task, participant profile, and success criteria before testing; revise if the view creates more confusion than it resolves.

## 3. Document architecture

Begin with `docs/GAME_DESIGN_DOCUMENT.md` as the index and working GDD. Keep this methodology in `docs/GAME_DESIGN_METHODOLOGY.md`. Split the GDD into linked files under `docs/gdd/` when sections become difficult to navigate or maintain independently. File splitting must not change decision IDs or create competing sources of truth.

The index must contain:

- The current game summary, production stage, document owner, and last substantive review date.
- Navigation covering every section in the universal outline below.
- A register of decisions, their owners, statuses, and authoritative locations.
- The highest-impact assumptions, unresolved questions, and design risks.
- Links to current prototypes, specifications, playtest evidence, and change history.
- A glossary defining terms, units, and distinctions used throughout the design.

Each outline section uses this wrapper:

```markdown
## <section number and title>

- Applicability: Applicable | Undecided | Not applicable
- Rationale: <decision link explaining inclusion, uncertainty, or exclusion>
- Owner:
- Maturity: Unexplored | Exploring | Specified | Implemented | Verified
- Summary and boundaries:
- Decision records: <embedded records or links>
- Supporting specifications and evidence:
- Dependencies and open questions:
```

All sections must be accounted for, but not every game needs every feature. For example, an offline game may exclude networking while still needing a reasoned decision about local social play and save behavior. Marking a section not applicable requires a Why / How / What decision explaining why it is unnecessary, how the design works without it, and what boundary or future change would reopen it.

Use “Undecided” when applicability is unknown. Do not use “Not applicable” to defer difficult questions. Review optional features for their value, not merely because the outline names them.

## 4. Universal GDD outline

The following sections are a coverage map, not an implementation checklist. Add genre-specific subsections beneath the appropriate section. Each subsection inherits the decision contract; the prompts below are subjects to investigate, not substitutes for Why / How / What.

### 01 — Vision, audience, and intended experience

- Concept, player fantasy, premise, and concise description of play.
- Intended emotions, cognitive demands, social experience, and experiential arc.
- Audience motivations, prior knowledge, access needs, and play context.
- Design pillars, their priority when they conflict, and explicit anti-goals.
- Differentiation, relevant references, and what we intend to learn from them.
- Definition of success for players and for the project; evidence needed to assess both.

### 02 — Product boundaries and constraints

- Platforms, devices, distribution channels, input methods, and supported configurations.
- Modes, player counts, connectivity assumptions, and typical session lengths.
- Scope, exclusions, intended content volume, and release boundaries.
- Team, budget, schedule, technology, and external constraints affecting design.
- Business model, audience age assumptions, territories, and relevant obligations.
- Explicit distinction between required constraints and preferences we can change.

### 03 — Player journey and game loops

- First contact, installation or entry, first launch, onboarding, and first meaningful choice.
- Moment-to-moment actions, encounter/challenge loop, session loop, and long-term loop.
- How each loop starts, develops, resolves, and motivates another cycle.
- Goals, stakes, rewards, pacing, downtime, and stopping points at each timescale.
- Win, loss, draw, completion, abandonment, retry, and post-completion experiences.
- Return after absence, interrupted sessions, and voluntary exit.

### 04 — Core rules, mechanics, and state

- Player verbs, legal actions, prerequisites, costs, targets, and consequences.
- Entities, properties, relationships, resources, and invariant rules.
- State machines, turn or time structure, action ordering, and simultaneous events.
- Resolution formulas, scoring, victory conditions, ties, and failure conditions.
- Randomness, distributions, seeds, hidden information, and player influence over uncertainty.
- Modifier stacking, precedence, caps, rounding, exceptions, and conflicting effects.
- Undo, cancellation, confirmation, invalid inputs, and recovery from impossible states.
- Worked examples, counterexamples, and boundary cases for interacting rules.

### 05 — Challenge, opposition, and skill

- Sources of challenge: strategic, tactical, motor, perceptual, creative, social, or other.
- Opponents, hazards, puzzles, obstacles, and environmental pressures.
- AI behavior, knowledge limits, decision rules, predictability, and feedback.
- Skill expression, learning curve, mastery, and player agency.
- Difficulty settings, adaptation, assistance, fairness, and failure recovery.
- Degenerate strategies, dominant choices, exploits, and intended solutions or freedoms.

### 06 — Progression, rewards, and economy

- Progress within a challenge, session, campaign, account, or community.
- Unlocks, advancement, customization, reward schedules, and reset boundaries.
- Resources, currencies, inventories, ownership, scarcity, sources, sinks, and exchanges.
- Costs, reward formulas, growth curves, caps, inflation, and catch-up mechanisms.
- Relationships between power, variety, collection, mastery, and status.
- Loss and retention rules; whether progression respects different play schedules.
- Economy models and balance targets linked to the choices they are meant to create.

### 07 — Content systems and taxonomy

- Types of playable content: items, abilities, cards, dice, characters, enemies, objectives, or equivalents.
- Shared schemas, required fields, tags, rarity or availability, and compatibility rules.
- Content roles, meaningful variation, combinations, counters, and exclusions.
- Authored versus generated content, generation constraints, and validation rules.
- Content budgets, reuse, expansion boundaries, and discoverability.
- A complete catalog or authoritative data reference, with representative entries and edge cases.

### 08 — World, levels, and spatial structure

- Setting structure, playable spaces, boards, maps, arenas, routes, or abstract layouts.
- Navigation, traversal, spatial rules, scale, visibility, and orientation.
- Encounter placement, pacing, gating, branching, secrets, and environmental storytelling.
- Level templates, authored layouts, procedural generation, and solvability constraints.
- Spatial readability, camera relationships, collision, and out-of-bounds behavior.
- Replay variation and consistency needed for learning.

### 09 — Narrative and expressive systems

- Themes, tone, setting, characters, relationships, and player identity.
- Plot structure, dialogue, exposition, lore, and delivery channels.
- Player choices, branching, consequences, continuity, and narrative state.
- Relationship between authored story and emergent play.
- Skipping, replay, localization context, and accessibility of narrative information.
- Player expression through avatars, builds, role-play, creation, or other choices.

### 10 — Interaction, interface, and information

- Controls, bindings, gestures, remapping, input priority, and device switching.
- Camera behavior, focus, selection, targeting, and navigation.
- Screen flows, HUD, menus, overlays, notifications, and information hierarchy.
- Feedback for available, pending, resolved, denied, and failed actions.
- Visibility of rules, probabilities, costs, consequences, and hidden information boundaries.
- Tutorials, contextual help, reference material, tooltips, and learning without interruption.
- Loading, empty, error, disconnected, paused, and recovery states.
- Wireframes and interaction specifications covering normal and exceptional flows.

### 11 — Accessibility, inclusion, and player comfort

- Visual, auditory, motor, cognitive, language, and other relevant access needs.
- Readability, contrast, text sizing, color-independent cues, captions, and screen-reader support.
- Input alternatives, timing flexibility, complexity options, and assist features.
- Motion, flashing, camera effects, intensity, and sensory comfort controls.
- Representation, sensitive content, content notices, and respectful language.
- How equivalent information and meaningful play are preserved across options.
- Validation with relevant players and interactions with difficulty or competitive integrity.

### 12 — Visual direction and motion

- Art pillars, style references, composition, shape language, palette, and typography.
- Character, environment, object, icon, interface, and visual-effects direction.
- Animation grammar, transitions, timing, anticipation, impact, and state readability.
- Visual priority when effects overlap; distinguish functional cues from decoration.
- Asset formats, scale, resolution, variants, and performance-related visual limits.
- Consistency rules and examples sufficient for creating and reviewing new assets.

### 13 — Audio, music, voice, and haptics

- Sonic identity, music structure, ambience, effects, voice, and silence.
- Event-to-cue mapping, priorities, concurrency, repetition, and dynamic mixing.
- Adaptive music, transitions, emotional pacing, and feedback timing.
- Haptic patterns, device support, intensity, and opt-out behavior.
- Volume controls, alternate cues, captions, and essential information parity.
- Recording, licensing, localization, and asset delivery requirements.

### 14 — Social, multiplayer, and community

- Cooperative, competitive, asynchronous, local, and shared-device experiences.
- Roles, teams, matchmaking, lobbies, invitations, spectators, and communication.
- Shared rules, fairness, ranking, rewards, and conflict resolution between players.
- Latency, disconnections, reconnection, drop-in/out, and host departure behavior.
- Abuse prevention, reporting, blocking, moderation, and player-generated content.
- Community features, sharing, creator tools, mods, and user content ownership boundaries.

### 15 — Persistence, runtime, and technical requirements

- Save scope, checkpoints, autosave, manual save, profiles, cloud sync, and migration.
- Crash recovery, corrupted data, conflicting saves, deletion, and offline behavior.
- Required frame rate, response times, loading budgets, memory/storage limits, and scale.
- Simulation determinism, replays, time handling, and platform-specific behavior.
- Networking authority, security, cheating resistance, and service failure behavior where relevant.
- Data collection, privacy, retention, account lifecycle, and external dependencies.
- Links to engineering specifications; keep player-visible requirements authoritative in the GDD.

### 16 — Commercial model and player commitments

- Purchase, subscription, advertising, downloadable content, or other funding model.
- Entitlements, offers, price structure assumptions, and access to paid/free content.
- Store and purchase flows, cancellation, restore, refunds, and service outages where relevant.
- Effects of monetization on fairness, progression, pacing, and player trust.
- Promises about ownership, availability, updates, and ongoing service.
- Distribution, ratings, licensing, intellectual property, and applicable platform requirements.

### 17 — Release, live operation, and end of service

- Launch scope, demos, early access, rollout, and compatibility commitments.
- Events, seasons, content cadence, balance patches, and version transitions.
- Player support, incident communication, maintenance, and recovery expectations.
- Metrics and feedback used to assess the experience without substituting them for design goals.
- Rollback, migration, retired content, and effects on existing player investment.
- Archival, offline preservation, shutdown, and end-of-support plans where applicable.

### 18 — Production, validation, and design governance

- Milestones, deliverables, ownership, dependencies, scope priorities, and cut criteria.
- Prototype sequence ordered by uncertainty and cost of being wrong.
- Content authoring tools, pipelines, review standards, and localization workflows.
- Test strategy: rule correctness, usability, accessibility, balance, experience, and compatibility.
- Playtest recruitment, protocols, evidence storage, analysis, and decision review.
- Design risk register, outstanding questions, change control, and completion criteria.
- Links to production plans and test plans instead of duplicating their operational detail.

### Cross-cutting coverage

Accessibility, localization, performance, privacy, fairness, and failure recovery must also appear in each affected system's decisions. A dedicated section establishes shared policy; it does not excuse omissions in the actual feature specifications.

For every major system, trace at least one normal journey, one boundary case, and one interruption or failure path. Trace a complete player lifecycle from first entry through repeated play and eventual exit. These checks expose gaps between individually complete sections.

## 5. How we build the GDD

### Step 1 — Establish the frame

Write the concept, audience hypotheses, intended experience, constraints, and anti-goals. Define a small set of prioritized pillars with observable implications. Record uncertain premises rather than presenting them as settled requirements.

**Exit condition:** We can explain whom the game serves, what experience it seeks, how success might be recognized, and what it deliberately excludes.

### Step 2 — Map coverage and unknowns

Create all outline entries, assign applicability and owners, and identify genre-specific subsections. Register dependencies and rank unknowns by their impact, uncertainty, and cost of late discovery.

**Exit condition:** Every area is accounted for, and the next design work targets the most consequential uncertainty.

### Step 3 — Model the smallest complete experience

Describe a complete playable loop, its state transitions, essential content, and first-time learning. Write Why / How / What records for its major choices. Walk through concrete examples manually before expanding catalogs or polishing presentation.

**Exit condition:** Another person can explain and simulate a session, including its ending, without inventing essential rules.

### Step 4 — Prototype and challenge the assumptions

Choose the cheapest adequate method: paper exercise, spreadsheet, simulation, interactive mockup, or playable prototype. State the question and success/failure criteria before testing. Include representative participants when conclusions concern player behavior; designer intuition alone is not audience evidence.

Capture observations separately from interpretations. Record build, configuration, participant context, task, results, and limits. A small or biased sample can inform a decision without establishing a general truth.

**Exit condition:** The highest-risk hypotheses have evidence, an explicit revision, or an acknowledged risk accepted by the accountable owner.

### Step 5 — Expand to an implementable specification

Specify interactions, formulas, data schemas, UI flows, content requirements, failure behavior, and quality targets. Link technical and production documents. Distinguish fixed rules from tunable parameters and establish their authoritative locations.

**Exit condition:** Implementers and testers can derive behavior and acceptance checks without resolving major design questions themselves. Remaining unknowns have owners and resolution gates before the work that depends on them.

### Step 6 — Integrate and verify

Review the complete experience across systems. Compare implemented behavior with the GDD and assess whether the experience supports its Why. Correct implementation drift or deliberately revise the design; do not quietly document accidental behavior as intended.

**Exit condition:** The milestone's implemented scope satisfies its acceptance criteria, supporting evidence is linked, and known limitations are recorded.

These steps repeat as the game develops. A failed hypothesis sends the affected design back to exploration; it does not require rewriting unaffected sections.

## 6. Specification and validation standards

### Rules must be executable in the reader's head

For each rule, define its trigger, preconditions, affected state, resolution order, outputs, and observable feedback. Include the no-op and invalid-action cases. For numeric systems, specify units, bounds, rounding, and overflow or cap behavior. For random systems, specify outcome space, probabilities, conditional changes, and what the player is told.

Tables, diagrams, formulas, pseudocode, and examples can clarify behavior, but they must link to the relevant decision and agree with the normative specification. Examples illustrate rules; they do not silently create exceptions.

### Use the right evidence for the claim

| Claim | Suitable validation |
| --- | --- |
| Rules produce the specified result | Worked cases, automated checks, state-transition tests, invariants. |
| A system permits meaningful alternatives | Strategy analysis, simulation, expert play, and player observation. |
| Players understand a choice | Comprehension tasks, observed errors, interviews tied to actual play. |
| An experience creates an intended feeling | Contextual playtests, observation, participant reports, repeated assessment. |
| An economy has acceptable trajectories | Modeling, distribution analysis, sensitivity checks, and playtests. |
| A feature is accessible or comfortable | Appropriate technical checks and evaluation with affected players. |
| A technical target is met | Measurements on the declared hardware and representative workloads. |

Set criteria in context; there is no universal “fun score” or retention threshold. Quantitative measures and qualitative evidence should answer a design question. Record conflicting evidence and distinguish implementation correctness from experiential success.

## 7. How we maintain the GDD

### Ownership and source of truth

The document owner maintains navigation, terminology, and coverage. Section owners maintain their decisions and evidence. Every accepted decision has one accountable owner; reviewers should include the disciplines and dependent systems affected by it. In a solo project, the same person can fill these roles, but should still perform the reviews explicitly.

Rules belong in their authoritative specification. Tunable values may live in versioned game data; the GDD must link to the exact fields and explain their purpose, constraints, and tuning intent. Playtest notes preserve observations; the GDD records the resulting decisions. Task trackers record execution, not a competing set of design rules.

### Change workflow

1. Identify the problem, evidence, and affected decision IDs.
2. Propose revised Why / How / What answers; compare the existing choice with alternatives.
3. Assess downstream effects on rules, content, UX, accessibility, saves, economy, technical work, schedule, and player commitments as relevant.
4. Review with affected owners and choose acceptance, rejection, or further investigation.
5. Update authoritative records, links, examples, acceptance criteria, and dependent work together. State whether implementation is pending or already aligned.
6. Validate the changed scope and attach the results. Schedule a revisit if evidence remains preliminary.

Use version control for textual history. Maintain a concise design change log for substantive changes: date, decision IDs, previous/new behavior, rationale, evidence, affected systems, and migration or follow-up work. Typographical corrections do not need decision records or change-log entries.

Keep stable IDs. Mark replaced decisions as superseded and link their successors; retain rejected alternatives when they explain an important tradeoff. Accepted decisions may return to proposed status when reopened, with the reason recorded. Never erase contradictory evidence to make a decision look settled.

### Review cadence and triggers

- **During active design:** review changed decisions and blocking questions in each work cycle.
- **After meaningful playtests:** reconcile findings with hypotheses, confidence, and priorities.
- **At each milestone:** audit coverage, dependencies, implementation alignment, and accepted risks.
- **When a pillar, audience, platform, business constraint, or core rule changes:** review every dependent decision.
- **When a revisit trigger fires:** reopen the affected record, even if it was previously verified.

Choose calendar frequency to match the team's pace and record it in the GDD index. “Verified” means checked against a particular build and context; material changes to dependencies require revalidation.

## 8. Review gates and definition of readiness

A section is not complete merely because it contains text. Review it against these questions:

- **Purpose:** Does every normative statement belong to a decision with a meaningful Why?
- **Causality:** Does the How credibly explain how the What serves that Why?
- **Specificity:** Can someone implement and test the specified scope without guessing essential behavior?
- **Coverage:** Are applicable topics, boundaries, exceptions, and failure paths addressed?
- **Coherence:** Do rules, terminology, values, examples, and linked documents agree?
- **Evidence:** Are assumptions visible, claims sourced, and validation limits acknowledged?
- **Tradeoffs:** Were credible alternatives considered, with disadvantages recorded?
- **Feasibility:** Can the design fit its constraints, dependencies, and content budget?
- **Ownership:** Do unresolved issues have accountable owners and resolution gates?
- **Traceability:** Can we follow a player goal through decisions, implementation, and evidence?

Use maturity deliberately:

| Maturity | Minimum meaning |
| --- | --- |
| Unexplored | The area is listed; its questions have not been investigated. |
| Exploring | Alternatives and hypotheses exist; major behavior may remain open. |
| Specified | Accepted decisions define the scoped behavior and checks; blocking unknowns are resolved. |
| Implemented | A referenced build contains the specified behavior, with known deviations listed. |
| Verified | Correctness and intended experience have been evaluated against recorded criteria; failures are resolved or explicitly accepted as limitations. |

Decision status, section maturity, and evidence confidence are separate. An accepted choice can be untested; an implemented feature can be contradicted by playtests. Do not use one label to hide the others.

The GDD is ready for a milestone when its scoped sections meet that milestone's declared maturity, all outline areas are accounted for, critical dependencies are coherent, and unresolved risks are explicitly owned. It remains a living document for as long as the design or its player commitments can change.
