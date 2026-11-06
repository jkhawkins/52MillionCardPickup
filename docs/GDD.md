# 52 Million Card Pickup
## Game Design Document

**Genre:** Single-player incremental / clicker  
**Session target:** Approximately 180 active minutes; no offline progress  
**Structure:** One continuous run, no prestige resets  
**Presentation:** One-screen casino worktable  
**Goal:** Deposit 52,000,000 playing cards  
**Document status:** Approved feature set; initial economy and balance specification  
**Version:** 1.0 — 6 November 2026

---

## 1. High concept

A standard deck of playing cards is manageable. Fifty-two million of them is absurd.

**52 Million Card Pickup** begins with the player picking up one card per click, carrying only one deck, and manually counting every deposit. It ends with a table full of tireless mechanical helpers, enormous inventory racks, targeted card-seeking equipment, foil-rich payouts, and a cascade of active abilities coordinating tens of thousands of pickups and deposits per second.

The game’s central pleasure is turning a repetitive, deliberately modest task into an extravagant card-processing operation while keeping the original fantasy—personally picking up cards—useful throughout the run.

### Design pillars

1. **Every card matters.** Rank determines base income, suit supports specialization, and every deposited identity advances the Deck Ledger.
2. **Small actions become enormous systems.** The player should feel a direct line from the first clicked Ace to the final million-card batch.
3. **Automation empowers active play rather than deleting it.** Helpers provide the baseline; combos, lucky pickups, abilities, and events reward attention.
4. **Deposits are the central bottleneck.** Capacity, counting speed, batch timing, and automation remain as important as raw pickup yield.
5. **A complete three-hour arc.** No prestige wall, offline requirement, endless grind, or post-game purchase is needed to finish.

---

## 2. Approved scope and boundaries

### Included

- One-screen manual card pickup and timed deposits.
- Initial capacity of exactly 52 cards and initial pickup of exactly one card.
- Independently random rank and suit generation, modified later by approved Seeker upgrades.
- Money from card face value and a smaller completed-deck bonus.
- Deck Ledger with automatic deck binding.
- Capacity, manual yield, deposit speed, income, automation, Seeker, foil, suit, combo, lucky-pickup, and active-ability upgrade branches.
- Auto-pickers and configurable auto-deposits.
- Foil cards, lucky pickups, positive random events, cosmetic achievements, and a detailed results screen.
- Local autosave, contextual tutorial, accessibility options, and optional endless continuation.

### Explicitly excluded

- Prestige or multiple required runs.
- Offline progress.
- A duplicate-salvage meter or automatic duplicate-to-wildcard conversion.
- Parallel deposit channels.
- Card-milestone chapter or reward tracks.
- A separate Deck Mastery progression track.
- Contracts or missions.
- Foil-driven deck-bonus bonuses.
- Gameplay bonuses from achievements.
- Bulk-buy buttons.
- Mutually exclusive builds or required respecs.
- Negative random events.

### Visibility rule

Every upgrade is visible from the beginning. Unavailable nodes show their cost and prerequisite path. There are **no lifetime-card milestone locks**. The economy and prerequisites, rather than hidden chapter gates, control the run’s pacing.

---

## 3. Core play loop

1. **Pick up cards.** Click the table or hold the pickup input. At the start, each action adds one independently random card.
2. **Fill the tray.** Carried cards occupy capacity. At 52 cards, ordinary pickup stops.
3. **Start a deposit.** Press the Deposit button. Manual pickup pauses while the current batch counts down.
4. **Receive money and progress.** Each card is deposited individually, adding its value, one lifetime deposited card, and one identity to the Deck Ledger.
5. **Bind decks.** Whenever the ledger contains all 52 unique rank-and-suit identities, one deck is bound automatically and awards its bonus.
6. **Purchase upgrades.** Expand capacity, improve pickup and deposit throughput, increase income, and unlock automation.
7. **Coordinate bursts.** Maintain Combo, activate abilities, and interact with positive events to accelerate the operation.
8. **Finish the run.** Deposit card 52,000,000, view the results sequence, and optionally continue endlessly.

### Early example

A player fills their first 52-card tray, presses Deposit, and watches the cards count into the ledger. The cards’ ranks total 339 money, with duplicates remaining in the ledger for future decks. Several batches later, the final missing identity arrives: the ledger automatically binds one deck and awards another 52 money. The player can then choose between a pickup, capacity, deposit, or income upgrade.

---

## 4. Card, money, and deck rules

### 4.1 Card identities

There are 52 ordinary identities: four suits, each containing Ace through King.

| Card | Base value |
|---|---:|
| Ace | 1 |
| 2–10 | Printed rank |
| Jack | 11 |
| Queen | 12 |
| King | 13 |

A standard deck’s total face value is:

`4 × (1 + 2 + … + 13) = 364 money`

The base completed-deck bonus is **52 money**, making an unmodified complete deck worth **416 money** in total.

### 4.2 Generation

Before Seeker modifiers:

- Rank is independently uniform across all 13 ranks.
- Suit is independently uniform across all four suits.
- Every pickup source uses the same identity-generation rules unless explicitly stated otherwise.
- Foil status is rolled separately and never changes rank, suit, deck credit, or the number of cards deposited.
- Suit Surge changes value only; it does not change generation odds.

### 4.3 Deposit income

For each deposited card:

`Card income = (rank value + flat rank/global bonuses) × global income × source income × suit income × foil multiplier × temporary modifiers`

Relevant modifiers of the same type add before their category multiplies; separate categories multiply. This prevents an ambiguous stacking order and makes tooltips predictable.

- Base foil chance: **1%**.
- Base foil value: **5× that card’s income**.
- Foils still deposit as one card and count as their ordinary identity.
- Lucky bonus cards generate their own identities and can independently be foils.

### 4.4 Deck Ledger

The ledger stores deposited counts for all 52 identities.

Whenever every identity has at least one unbound copy:

1. Remove one copy of each identity from the unbound ledger counts.
2. Bind one complete deck.
3. Award the deck bonus:

`Deck income = (52 + flat deck upgrades) × deck-bonus multipliers × applicable global/temporary modifiers`

4. Show the completed-deck total and a brief animation.

Deck binding is automatic. Decks do not occupy inventory and cannot be spent. Extra copies remain in the ledger for future decks. Deck bonuses grant money only; they never add cards to the 52-million counter.

### 4.5 Goal accounting

- Only successfully deposited cards advance the main goal.
- Inventory cards, deposit-queue cards, deck bonuses, and money do not advance it.
- Spending money never reduces card progress.
- The completion requirement is exactly **52,000,000 lifetime deposited cards in the current run**.

---

## 5. Pickup, inventory, and deposit handling

### 5.1 Manual pickup

- Base yield: **1 card per pickup action**.
- Base practical pacing assumption: **3 manual actions per second**, used for balance rather than imposed as a hard click-speed requirement.
- The player can click repeatedly or enable hold-to-pickup.
- Pickup is always available; there is no card-spawn scarcity or travel.
- At capacity, ordinary manual pickup stops and the tray gives clear visual/audio feedback.
- Overflow Tray permits only its stated number of final manual pickup actions above capacity.

### 5.2 Deposit batches

- Base deposit rate: **13 cards per second**.
- A full initial tray therefore takes **4 seconds** to deposit.
- Pressing Deposit queues all currently carried cards as one batch.
- Cards leave capacity as they are individually counted. Money, goal progress, and ledger credit arrive per card, not only at batch completion.
- Deposit duration is dynamic:

`Remaining time = remaining batch cards ÷ current effective deposit rate`

Temporary deposit modifiers therefore affect a running batch immediately.

### 5.3 Pickup during deposits

- Manual pickup pauses during any deposit.
- Auto-pickers continue operating.
- Cards produced during a deposit enter newly freed capacity but do **not** join the current batch; they wait for the next deposit.
- Automation pauses only when no capacity is available.
- A deposit can be cancelled. Already counted cards remain deposited; uncounted cards remain in inventory. No cards are destroyed.
- Starting a manual deposit while auto-deposit is enabled takes priority and resets the automatic trigger check.

### 5.4 Auto-deposit thresholds

Once unlocked, the player can toggle automatic deposits and select 25%, 50%, 75%, or 100% of current capacity. Smart Thresholds can begin earlier when projected pickup during counting would otherwise strand a full tray.

---

## 6. Controls and screen layout

### Default controls

| Input | Action |
|---|---|
| Left click / Space | Pick up cards |
| Hold left click / Space | Accessibility hold-to-pickup |
| D | Start or cancel deposit |
| 1–5 | Activate owned abilities |
| L | Open Deck Ledger |
| U | Focus upgrade tree |
| Escape | Pause/settings |

All gameplay inputs are remappable.

### One-screen composition

- **Center:** Green-felt pickup table, carried-card stack, manual pickup effects, helpers, and event interactions.
- **Top:** Lifetime deposited cards, exact remaining cards, current money, and cards-per-second trend.
- **Left:** Scrollable upgrade tree with visible prerequisites and six major branch roots.
- **Right:** Current inventory/capacity, deposit progress and rate, compact Deck Ledger status, and auto-deposit controls.
- **Bottom:** Five-slot ability hotbar, Combo meter, active event/buff timers, and simple statistics.
- **Ledger view:** A 4×13 grid showing unbound copies, missing identities, bound decks, and current Seeker behavior.

The ledger, simple rates, and total statistics are available during play. The exhaustive output and behavior breakdown is reserved for the results screen.

---

## 7. Upgrade tree architecture

### 7.1 Structure

The tree has six visible roots:

1. **Capacity & Deposit**
2. **Manual, Combo & Luck**
3. **Automation**
4. **Value, Decks & Foils**
5. **Card Seekers**
6. **Suit Specializations**, with four connected sub-branches

Active-ability nodes attach to their relevant parent branches. All upgrades can eventually be owned; there are no exclusions or respec requirements.

### 7.2 Cost notation

The catalog uses cost bands rather than hiding upgrades behind progression chapters.

| Band | Base cost | Cost growth per owned rank | Intended economy |
|---|---:|---:|---|
| A | 25 | ×1.65 | Opening minutes |
| B | 2,500 | ×1.80 | Early automation |
| C | 100,000 | ×1.90 | Established operation |
| D | 2,000,000 | ×2.00 | Midgame scaling |
| E | 50,000,000 | ×2.10 | Late scaling |
| F | 1,000,000,000 | ×2.25 | Final build completion |

For rank `r` of a multi-rank node:

`Cost(r) = band base cost × band growth^(r - 1)`

Single-rank nodes use their band’s base cost unless their description assigns a multiplier. These values are the **first playable tuning pass**, not promises of final balance.

### 7.3 Catalog summary

The tree contains **104 named upgrade entries**, many with multiple ranks. Repeated ranks provide granular purchases without requiring bulk-buy controls.

---

## 8. Upgrade catalog — Capacity & Deposit (14)

| ID | Upgrade | Ranks | Effect per rank unless stated | Prerequisite | Band |
|---|---|---:|---|---|---|
| C01 | Deep Pockets | 10 | +52 capacity | None | A |
| C02 | Deck Racks | 5 | +208 capacity | C01 II | A |
| C03 | Casino Shelves | 3 | +520 capacity | C02 II | B |
| C04 | Bigger Table | 4 | ×1.50 total capacity | C03 I | C |
| C05 | Overflow Tray | 3 | Allows one additional final manual pickup action above capacity | C01 IV | B |
| C06 | Quick Count | 6 | +25% base deposit rate | None | A |
| C07 | Sorted Stacks | 5 | +20% deposit rate for batches of at least 10 decks | C02 I | B |
| C08 | Clean Transfer | 4 | ×1.35 deposit rate | C06 IV | C |
| C09 | Full-Batch Bonus | 3 | +30% deposit rate when starting with at least 90% capacity filled | C07 II | C |
| C10 | Deposit Momentum | 4 | +5% rate per continuous second, with the cap increased by 25 percentage points | C06 II | B |
| C11 | Felt Rollers | 3 | ×1.60 deposit rate | C08 II | D |
| C12 | Industrial Counting | 8 | ×2.00 deposit rate | C11 II | E |
| C13 | Buffer Logistics | 4 | +10% capacity per owned auto-picker, up to the displayed cap | A03 I, C04 I | D |
| C14 | Master Counting Room | 1 | ×3 deposit rate and ×2 capacity; single purchase costs 3× band base | C12 VI, C04 IV | F |

**Design note:** Deposit Momentum has a base cap of 25%; each rank adds 5% per second and raises the cap by 25 points. The UI shows the current bonus directly on the deposit bar.

---

## 9. Upgrade catalog — Manual, Combo & Luck (20)

| ID | Upgrade | Ranks | Effect per rank unless stated | Prerequisite | Band |
|---|---|---:|---|---|---|
| M01 | Wide Grip | 10 | +1 card per manual pickup | None | A |
| M02 | Two-Handed | 5 | +25% manual pickup yield | M01 II | A |
| M03 | Sweeping Motion | 4 | ×1.50 manual pickup yield | M02 III | C |
| M04 | Fast Fingers | 5 | +10% hold-to-pickup rate and animation speed | M01 I | A |
| M05 | Sweep Burst | 1 | Manual pickups gain a 3% chance to resolve as a burst | M02 II | B |
| M06 | Burst Chance | 5 | +2 percentage points Sweep Burst chance | M05 | B |
| M07 | Burst Power | 4 | +100% of normal manual yield to each burst; base burst is ×2 | M05 | C |
| M08 | Manual Momentum | 4 | After 12 manual pickups in 3 seconds, gain +20% manual yield for 3 seconds | M02 I | B |
| M09 | Momentum Duration | 4 | +1 second to Manual Momentum | M08 | B |
| M10 | Pickup Combo | 1 | Unlocks Combo: manual pickups add stacks; each stack grants +1% manual yield and +0.5% card income | M04 II, M08 I | B |
| M11 | Combo Ceiling | 5 | +25 maximum Combo; base maximum is 50 | M10 | C |
| M12 | Combo Memory | 4 | +0.5 seconds before decay and -15% decay rate | M10 | B |
| M13 | Combo Yield | 4 | +0.25 percentage points manual yield per stack | M11 I | C |
| M14 | Combo Value | 4 | +0.125 percentage points card income per stack | M11 I | C |
| M15 | Combo Starter | 3 | After Combo fully decays, the next manual pickup starts with 10 additional Combo | M12 II | D |
| M16 | Shared Rhythm | 1 | Auto-pickers inherit 25% of Combo’s current yield and income bonuses | M13 II, M14 II, A05 I | E |
| M17 | Lucky Pickup | 1 | Manual pickups gain a 5% Lucky chance for +100% cards and +50% money | M05 I | B |
| M18 | Lucky Chance | 5 | +1.5 percentage points Lucky chance | M17 | C |
| M19 | Lucky Cards | 4 | +50% additional cards on Lucky pickups | M17 | C |
| M20 | Lucky Money | 4 | +25% additional money on Lucky pickups | M17 | C |

### Combo behavior

- Base maximum: 50 stacks.
- Decay begins after 1.5 seconds without a manual pickup.
- Base decay: 10 stacks per second.
- Depositing does not clear Combo, but the deposit duration usually causes decay unless Combo Memory is purchased.
- Automated pickups neither build nor refresh Combo.
- Shared Rhythm only copies the current bonus; it does not let automation maintain it.

---

## 10. Upgrade catalog — Automation (14)

| ID | Upgrade | Ranks | Effect per rank unless stated | Prerequisite | Band |
|---|---|---:|---|---|---|
| A01 | Auto-Picker | 1 | Adds one helper picking 1 card once per second | C01 I, M01 I | B |
| A02 | Picker Speed | 8 | +20% base auto-pick rate | A01 | B |
| A03 | Additional Picker | 7 | +1 auto-picker | A01, A02 II | C |
| A04 | Worker Grips | 5 | +1 card per automatic pickup | A03 I | C |
| A05 | Mechanical Rhythm | 4 | ×1.50 automatic pickup rate | A02 IV | D |
| A06 | Shared Tools | 3 | Helpers inherit 5% of flat Wide Grip and Worker Grips bonuses | A04 I, M01 V | D |
| A07 | Continuous Motion | 3 | +15% auto-pick rate while a deposit is active | A02 II, C06 II | C |
| A08 | Overclocked Workers | 4 | ×1.60 automatic pickup rate | A05 II | E |
| A09 | Auto-Depositor | 1 | Enables automatic deposits at 100% capacity | A01, C06 II | B |
| A10 | Threshold Controls | 1 | Enables 25%, 50%, 75%, and 100% auto-deposit thresholds | A09 | C |
| A11 | Smart Thresholds | 3 | Improves predictive early deposits and reduces idle full-tray time | A10, A07 I | D |
| A12 | Automation Value | 4 | +15% income from automatically picked cards | A03 I | C |
| A13 | Seeker Integration | 3 | +15% of the player’s Seeker bias applies to each helper | S02 I, A03 I | D |
| A14 | Master Automation | 1 | ×2 helper rate, ×2 helper yield, and +25% Continuous Motion effect; costs 3× band base | A08 III, A03 VII | F |

### Automation rules

- Every helper uses current card-value and Seeker rules unless a node states otherwise.
- Helpers stop at capacity and resume automatically when space opens.
- Helper count, picks per second, effective yield, and current blockage are shown in simple statistics.
- No offline automation is calculated.

---

## 11. Upgrade catalog — Value, Decks & Foils (16)

| ID | Upgrade | Ranks | Effect per rank unless stated | Prerequisite | Band |
|---|---|---:|---|---|---|
| V01 | Premium Stock | 10 | +15% card income | None | A |
| V02 | Compound Value | 5 | ×1.35 card income | V01 V | C |
| V03 | Card Lamination | 5 | +1 flat value to every card | V01 II | B |
| V04 | Ace Appreciation | 4 | +100% Ace income | V03 I | B |
| V05 | Low Card Floor | 4 | +20% income for ranks 2–10 | V03 I | B |
| V06 | Face Card Premium | 5 | +20% Jack, Queen, and King income | V01 III | B |
| V07 | Royal Court | 3 | ×1.50 Jack, Queen, and King income | V06 III | D |
| V08 | Deck Bonus | 5 | +52 money to every bound deck | V01 II | B |
| V09 | Complete Deck Multiplier | 4 | ×1.50 deck-bonus income | V08 II | D |
| V10 | Foil Chance | 5 | +0.5 percentage points foil chance | V01 III | C |
| V11 | Foil Value | 5 | +1× to the foil income multiplier | V10 I | C |
| V12 | Foil Polish | 3 | ×1.50 foil income | V11 III | E |
| V13 | Manual Appraisal | 4 | +20% income from manually picked cards | V01 IV, M01 III | C |
| V14 | Automated Appraisal | 4 | +20% income from automatically picked cards | V01 IV, A01 | C |
| V15 | Full-Batch Appraisal | 3 | +25% card income when the originating batch started at least 90% full | C09 I, V01 V | D |
| V16 | Master Appraiser | 1 | ×3 card income and ×2 deck-bonus income; costs 3× band base | V02 V, V09 III | F |

Card-income tracking follows the card’s source and originating batch. Recalculating old cards when upgrades are purchased is unnecessary; the income snapshot is taken when each card deposits.

---

## 12. Upgrade catalog — Card Seekers (8)

| ID | Upgrade | Ranks | Effect per rank unless stated | Prerequisite | Band |
|---|---|---:|---|---|---|
| S01 | Card Seeker | 1 | 5% of generated identities are replaced with a uniformly random missing identity | V08 I | C |
| S02 | Seeker Focus | 5 | +7 percentage points replacement chance | S01 | C |
| S03 | Auto-Seeker | 1 | Automatically collects one missing card every 60 seconds when capacity permits | S02 II, A01 | D |
| S04 | Seeker Speed | 4 | -15% Auto-Seeker interval, multiplicatively | S03 | D |
| S05 | Seeker Quantity | 3 | +1 missing card per Auto-Seeker activation | S03 | E |
| S06 | Guaranteed Find | 3 | Every 100 generated cards guarantees one missing card; each rank reduces the interval by 20 | S02 III | E |
| S07 | High-Value Priority | 3 | 20% of Seeker replacements choose uniformly from the highest-value missing ranks | S02 I | D |
| S08 | Master Seeker | 1 | +25 percentage points Seeker bias; Auto-Seeker produces two independent activations; costs 3× band base | S05 II, S06 II | F |

### Seeker safeguards

- “Missing” means needed for the next possible bound deck, based on unbound ledger counts.
- If no identity is missing, Seeker generation behaves as ordinary random generation.
- Seeker-created cards still occupy capacity and must deposit normally.
- Bias applies before foil rolls.
- Maximum ordinary Seeker replacement chance is capped at 75% before temporary abilities; Master Seeker can reach but not exceed 90%.
- High-Value Priority affects deck completion less than pure uniform seeking and is therefore a deliberate economy-versus-consistency choice, not a permanent branch lock.

---

## 13. Upgrade catalog — Suit Specializations (16)

All four branches are fully purchasable in one run.

### Hearts — Income

| ID | Upgrade | Ranks | Effect per rank unless stated | Prerequisite | Band |
|---|---|---:|---|---|---|
| H01 | Heart Values | 5 | +25% Heart card income | V01 II | B |
| H02 | Heart Appraisal | 4 | +8% income to every non-Heart card | H01 II | C |
| H03 | Heart Foils | 3 | +1 percentage point Heart foil chance and +25% Heart foil income | V10 I, H01 I | D |
| H04 | Heart of the Deck | 1 | Heart income bonuses also apply at 25% strength to deck bonuses | H01 V, H02 III, V09 I | E |

### Diamonds — Capacity and deposits

| ID | Upgrade | Ranks | Effect per rank unless stated | Prerequisite | Band |
|---|---|---:|---|---|---|
| D01 | Diamond Pockets | 4 | +20% total capacity | C02 I | B |
| D02 | Diamond Counting | 4 | +25% deposit rate | C06 II | C |
| D03 | Diamond Full Batch | 3 | +20% to Full-Batch Bonus and Full-Batch Appraisal effects | C09 I, D02 I | D |
| D04 | Diamond Logistics | 1 | ×2 capacity and ×2 deposit rate | D01 IV, D02 IV, C11 I | E |

### Spades — Automation

| ID | Upgrade | Ranks | Effect per rank unless stated | Prerequisite | Band |
|---|---|---:|---|---|---|
| P01 | Spade Tempo | 4 | +20% automatic pickup rate | A02 I | C |
| P02 | Spade Grips | 4 | +15% automatic pickup yield | A04 I | C |
| P03 | Spade Workforce | 3 | +1 helper and +10% rate to all helpers | A03 II, P01 II | D |
| P04 | Spade Overdrive | 1 | Card Surge’s automation effect is 50% stronger; otherwise +25% helper rate | P01 IV, P02 III, X04 | E |

### Clubs — Manual and active play

| ID | Upgrade | Ranks | Effect per rank unless stated | Prerequisite | Band |
|---|---|---:|---|---|---|
| B01 | Club Grip | 4 | +25% manual pickup yield | M02 II | C |
| B02 | Club Combo | 3 | +10 maximum Combo and +10% Combo yield effect | M10 | D |
| B03 | Club Luck | 3 | +1 percentage point Lucky and Sweep Burst chance | M17, M05 | D |
| B04 | Club Performance | 1 | +25% timed active-ability duration and +50% manual yield while any timed ability is active | B01 IV, B02 II | E |

Suit nodes are investments in themed systems, not changes to the probability of drawing that suit.

---

## 14. Active abilities and their upgrades (16)

Abilities have no charges, mana, or failure state. Their cooldowns begin on activation. Manual activation remains useful in the late game, especially when aligned with full trays, events, and high Combo.

| ID | Upgrade | Ranks | Effect per rank unless stated | Prerequisite | Band |
|---|---|---:|---|---|---|
| X01 | Card Surge | 1 | For 10 seconds, manual inputs resolve ×3 pickup actions; 60-second cooldown | M03 I | C |
| X02 | Surge Duration | 4 | +2 seconds Card Surge duration | X01 | C |
| X03 | Surge Potency | 4 | +50% of base manual output to Card Surge | X01 | D |
| X04 | Surge Automation | 1 | Card Surge also grants ×2 automatic pickup rate | X02 II, A05 I | E |
| X05 | Express Deposit | 1 | ×5 deposit rate for 8 seconds; 75-second cooldown | C08 I | C |
| X06 | Express Duration | 4 | +2 seconds Express Deposit duration | X05 | D |
| X07 | Express Overclock | 4 | +100% Express speed and -5% cooldown | X05 | D |
| X08 | Foil Frenzy | 1 | For 12 seconds: +4 percentage points foil chance, +100% Lucky chance, +50% card income; 120-second cooldown | V10 I, M17 | D |
| X09 | Frenzy Duration | 3 | +3 seconds Foil Frenzy duration | X08 | D |
| X10 | Frenzy Potency | 4 | +1 percentage point foil chance and +15% card income during Frenzy | X08 | E |
| X11 | Seeker Pulse | 1 | Next 52 generated cards have 65% Seeker replacement chance; 150-second cooldown | S02 I | D |
| X12 | Pulse Charges | 3 | +26 affected cards | X11 | D |
| X13 | Pulse Focus | 3 | +5 percentage points Pulse bias and +2 guaranteed missing cards | X11 | E |
| X14 | Card Cyclone | 1 | Instantly collect cards equal to 10% of current capacity, limited by free space; 90-second cooldown | M03 II, C04 I | D |
| X15 | Cyclone Size | 4 | +5 percentage points of capacity collected | X14 | E |
| X16 | Cyclone Cooldown | 4 | -10% Card Cyclone cooldown, multiplicatively | X14 | E |

### Ability implementation notes

- Card Surge’s repeated manual actions build Combo and can trigger Lucky/Sweep Burst, but each original input can refresh Combo only once.
- Express Deposit is a speed boost, never an instant deposit.
- Seeker Pulse overrides ordinary Seeker bias when stronger; chances do not add beyond the Seeker cap.
- Pulse Focus guarantees are distributed across the affected sequence rather than placed consecutively.
- Card Cyclone cannot be activated with zero free capacity and does not interrupt a deposit.
- Club Performance extends timed abilities only. Instant abilities such as Card Cyclone receive neither its duration bonus nor its manual-yield bonus.

---

## 15. Positive random events

Events begin after the contextual opening tutorial and occur approximately every **90–150 seconds**, with no more than one clickable event waiting at a time. They pause while the game is closed and never remove cards, money, upgrades, or time.

| Event | Behavior | Baseline effect |
|---|---|---|
| Card Shower | Bonus cards rain onto the table for 8 seconds; click them before they fade | Each clicked shower card performs one pickup, limited by capacity |
| Lucky Dealer | Dealer appears and offers three temporary buffs; choose one | 20–30 seconds of income, helper rate, deposit rate, or Seeker support |
| Suit Surge | One suit is featured for 20 seconds | +100% income for that suit; generation odds unchanged |
| Foil Flash | Table lighting changes for 15 seconds | +5 percentage points foil chance |
| Deposit Rush | A clickable bell starts a 12-second effect | +200% deposit rate |
| Second Wind | Rare clickable ability-themed event | Reduces all current ability cooldowns by 30 seconds |

### Event rules

- Card Shower respects capacity and uses ordinary identity generation.
- Dealer buffs do not stack with another Dealer choice; a new choice replaces the old one.
- Different event types can combine, creating intentional burst windows.
- Reduced-motion mode replaces falling or flashing presentation with static buttons and outlines.
- Event timers and clickable availability are saved; closing the game does not advance them.

---

## 16. Pacing and three-hour completion model

### 16.1 Target

- Median first completion: **180 active minutes**.
- Desired normal playtest range: **160–200 minutes**.
- Skilled high-attention play should save roughly 15–25 minutes, not skip entire systems.
- Automation-leaning play remains viable but is expected toward the upper half of the range.
- Endless continuation is excluded from completion-time measurement.

The overall required average is:

`52,000,000 ÷ 10,800 seconds = 4,814.8 deposited cards/second`

That average is not the starting rate. It results from a curve ending near 20,000–25,000 cards per second, with bursts above that baseline.

### 16.2 Cumulative-card pacing targets

These are telemetry targets, **not milestone unlocks**.

| Elapsed active time | Cumulative deposited cards | Cards added in interval | Required interval average |
|---|---:|---:|---:|
| 10 min | 5,000 | 5,000 | 8.3/s |
| 30 min | 100,000 | 95,000 | 79.2/s |
| 60 min | 1,000,000 | 900,000 | 500/s |
| 90 min | 4,000,000 | 3,000,000 | 1,666.7/s |
| 120 min | 12,000,000 | 8,000,000 | 4,444.4/s |
| 150 min | 28,000,000 | 16,000,000 | 8,888.9/s |
| 180 min | 52,000,000 | 24,000,000 | 13,333.3/s |

### 16.3 Intended experience by phase

#### 0–10 minutes — One deck at a time

- Establish click → fill → deposit → buy.
- Early choices between Wide Grip, Deep Pockets, Quick Count, and Premium Stock are all useful.
- First foil and first completed deck receive special presentation.
- The player approaches automation without needing to wait idle for it.

#### 10–30 minutes — Helpers arrive

- Auto-Picker and Auto-Depositor change the game from repetitive clicking to throughput planning.
- Combo, Lucky Pickup, and basic events keep manual attention valuable.
- Card Seeker and suit investments begin to define purchase order.

#### 30–60 minutes — Throughput engineering

- Multi-pickup, multiple helpers, larger racks, and batch deposit bonuses interact.
- The first active abilities create coordinated bursts.
- Deposit speed must keep pace with pickup output; neglected counting produces visible full-tray downtime.

#### 60–120 minutes — Build expression

- Hearts, Diamonds, Spades, and Clubs all remain viable investments.
- Shared Tools, Shared Rhythm, Seeker Integration, and advanced income nodes connect branches.
- Full batches, high Combo, and event alignment produce noticeable improvements without becoming mandatory dexterity tests.

#### 120–180 minutes — The absurd final table

- Industrial Counting, Overclocked Workers, Foil Polish, and master nodes provide final exponential scaling.
- All five abilities have clear uses.
- The last several million cards should be fast and celebratory, not an anticlimactic overnight wait.
- The final purchase decisions should still matter; the player should not be economically finished at minute 120.

### 16.4 Economy targets

- Base long-run income before other modifiers is approximately **8 money per card**: average rank value 7 plus approximately 1 per card from the 52-money deck bonus.
- Random deck shortfalls may temporarily reduce that deck contribution; Seekers recover consistency rather than supplying free money directly.
- Money income should remain high enough that a player normally has a meaningful affordable purchase or saving target.
- Target lifetime money earned at completion: approximately **25–60 billion**, depending on build and active play.
- Target money unspent at completion: less than 10% of lifetime earnings.
- No required waiting period without a purchase decision should exceed roughly 45 seconds during active play.

### 16.5 Balance validation requirements

Before content lock, run automated agents using the same upgrade costs and formulas:

1. **Manual-first agent:** prioritizes manual yield and Combo before helpers.
2. **Automation-first agent:** buys helpers and deposits as early as possible.
3. **Value-first agent:** prioritizes income, foils, and deck bonuses.
4. **Balanced agent:** buys the highest estimated progress-per-money upgrade.
5. **Low-attention agent:** uses no events and activates abilities at only 25% of available opportunities.
6. **High-attention agent:** maintains Combo and aligns abilities with events without superhuman clicking.

Acceptance targets:

- Balanced and high-attention agents finish within 160–200 minutes.
- Low-attention finishes within approximately 190–220 minutes without becoming stuck.
- No single branch provides more than 60% of final throughput without cross-branch investment.
- Deposit downtime neither dominates the late game nor becomes irrelevant before minute 60.
- Card Seeker reduces extreme incomplete-deck variance but does not become the best raw-income purchase in every state.

Primary tuning levers are cost growth, helper count/rate, Industrial Counting rank costs, deck-bonus scaling, and active-ability uptime. The 52-million goal and opening rules remain fixed.

---

## 17. Tutorial and quality-of-life behavior

### Contextual tutorial

Prompts appear beside the relevant control and disappear permanently once demonstrated:

1. Pick up a card.
2. Fill or partially fill the tray, then deposit.
3. Read rank income and the Deck Ledger.
4. Buy a first upgrade.
5. Explain capacity and deposit bottlenecks when either first blocks progress.
6. Explain helper behavior and auto-deposit after purchase.
7. Explain Combo and each ability immediately after its unlock.

There are no long modal panels. A static instructions page and tutorial reset remain available.

### Usability

- Every upgrade level is purchased individually; there are no bulk-buy buttons.
- Tooltips show current effect, next-rank effect, cost, and unmet prerequisites.
- Locked nodes can be selected to highlight their prerequisite path.
- Affordable nodes have a restrained glow; a second optional indicator identifies newly affordable nodes.
- The Deposit button shows batch size and estimated completion time.
- The main counter can switch between exact numbers and abbreviated notation.
- Floating numbers can be aggregated or disabled.

### Accessibility

- Full keyboard controls and remapping.
- Hold-to-pickup with no requirement for rapid clicking.
- Reduced motion, no screen shake, and aggregated effects.
- Scalable UI and text.
- High-contrast card faces and redundant suit icons/colors.
- Independent music, ambience, effects, and UI volume controls.
- No critical information communicated by color alone.
- Pause stops gameplay timers and event generation.

---

## 18. Presentation and audio

### Visual direction

A polished green casino worktable gradually becomes crowded with the player’s purchased operation: card racks, counting rollers, small mechanical helpers, Seeker lenses, foil trays, and suit-themed controls. Upgrades themselves provide the visual evolution; there is no separate milestone reward track.

- Cards remain readable even at extreme throughput through representative animated cards plus aggregated counters.
- Manual pickups have a crisp tactile snap.
- Deposits move in ordered stacks toward the ledger.
- Complete decks briefly fan into a 52-card ring before collapsing into the bound-deck counter.
- Foils use restrained iridescence, with a reduced-flash alternative.
- Late-game spectacle communicates output without hiding buttons or timers.

### Audio

- Soft card snaps pitch-stack subtly with Combo.
- Deposit counting forms a rhythmic layer whose tempo follows actual deposit rate.
- Helpers add quiet mechanical percussion.
- Deck completion resolves with a short musical cadence.
- Each suit specialization has a subtle audio motif.
- Music adds layers as the table becomes more complex, driven by owned system categories rather than milestone unlocks.

---

## 19. Achievements

Achievements are cosmetic badges and results-screen annotations only. They provide **no gameplay bonus** and require no play beyond the ordinary completion run.

Examples:

- **One Down:** Deposit the first card.
- **Full House:** Fill the initial 52-card tray.
- **Worth the Paper:** Bind the first deck.
- **Shiny:** Deposit a foil.
- **Helping Hand:** Hire an auto-picker.
- **Do It Yourself:** Deposit 10,000 manually picked cards.
- **Well-Oiled Table:** Own four helpers.
- **Counting Excellence:** Reach 1,000 deposit cards per second.
- **Combo Artist:** Hold maximum Combo for 20 seconds.
- **Lucky Streak:** Trigger three Lucky pickups in five seconds.
- **Four Suits, One Plan:** Buy at least one node in every suit branch.
- **Found It:** Auto-Seek a missing card.
- **Royal Treatment:** Deposit 1,000 Kings.
- **Foil Collection:** Deposit 52 foils.
- **Event Regular:** Interact with every event type.
- **Millionaire:** Deposit 1,000,000 cards.
- **Eight Figures:** Deposit 10,000,000 cards.
- **The Long Count:** Complete a batch of at least 100,000 cards.
- **Fully Equipped:** Own all five active abilities.
- **52 Million Card Pickup:** Complete the game.

---

## 20. Saving, completion, and endless play

### Saving

- Local autosave every 10 seconds, after purchases, and when the page loses visibility.
- Save card/inventory/ledger state, money, upgrade ranks, helper settings, cooldowns, events, tutorial state, achievements, and active playtime.
- On reopening, resume exactly from the saved state. No elapsed-time production is awarded.

### Completion

Depositing card 52,000,000:

1. Completes the current card’s income and ledger credit.
2. Stops new event generation and pauses helpers.
3. Plays a short final count and deck-ring celebration.
4. Displays the results screen.

### Results breakdown

- Active completion time.
- Lifetime cards and bound decks.
- Lifetime money and money spent.
- Manual versus automatic cards and income.
- Average and peak deposited cards per second.
- Deposit utilization and full-tray blocked time.
- Cards by rank and suit; foil and Lucky totals.
- Ability activations and estimated burst contribution.
- Event participation.
- Final upgrade tree and suit investment.
- Cosmetic achievements.

The player may continue in **Endless Mode**, which removes the goal restriction and retains all systems without adding a new progression layer, or begin a fresh run.

---

## 21. Edge cases and rules clarification

- **Exactly full inventory:** Ordinary pickup stops; approved Overflow Tray actions are the only way to exceed capacity.
- **Cyclone during deposit:** Allowed if there is free capacity; generated cards wait for the next batch.
- **Auto-Seeker with no space:** It waits rather than deleting or banking a card.
- **No missing identities:** Seekers generate ordinary random cards.
- **Multiple decks become complete in one batch:** Bind all eligible decks sequentially and aggregate their presentation.
- **Upgrade purchased mid-deposit:** Deposit-rate upgrades affect remaining cards immediately; income changes apply when each card deposits.
- **Foil and Lucky interaction:** Lucky determines extra cards and money; each generated card then receives its independent foil roll.
- **Cancel during a buff:** The buff continues for its real active duration unless paused; cancelling never rewinds progress.
- **Capacity reduced:** No normal upgrade reduces capacity, so no inventory-overflow destruction rule is needed.
- **Final card within a large batch:** Finish income and ledger processing for that card, celebrate, and leave any unprocessed cards for Endless Mode.
- **Very large numbers:** Use 64-bit-safe or arbitrary-precision number handling; never rely on 32-bit integers for cards, money, rates, or ledger totals.

---

## 22. Minimum viable content and production priorities

### Prototype 1 — Prove the loop

- Pickup, random identities, 52-card capacity, timed deposit, money, goal counter, and Deck Ledger.
- C01, C06, M01, and V01 only.
- Validate that the first five minutes are understandable and satisfying.

### Prototype 2 — Prove the economy

- Add automation, deposit thresholds, Seekers, and the 104-node catalog with placeholder presentation.
- Build the six balancing agents.
- Tune toward the cumulative-card targets before producing final art.

### Prototype 3 — Prove active longevity

- Add Combo, Lucky/Burst behavior, five abilities, and six events.
- Measure whether attention produces useful but non-mandatory gains.

### Content-complete version

- Casino-table presentation, responsive audio, tutorial, accessibility, simple in-run statistics, achievements, save handling, and results/endless screens.

### Final playtest questions

1. Does depositing feel like an interesting bottleneck rather than forced waiting?
2. Are capacity and deposit upgrades competitively valuable beside raw card yield?
3. Can players understand why the Deck Ledger is or is not completing decks?
4. Does each active ability have a distinct, readable use?
5. Is there a meaningful purchase or short saving decision throughout all three hours?
6. Does the game finish at its intended climax rather than several upgrades after the player feels done?

---

## 23. Success criteria

The design succeeds when:

- The opening one-card/52-card rules are immediately legible.
- The player completes one continuous run in roughly three active hours.
- Every deposited card obeys rank income and Deck Ledger rules consistently.
- Automation removes busywork while manual Combo, Lucky play, abilities, and events remain valuable.
- The upgrade tree supports different purchase orders without permanent exclusions.
- The final table feels dramatically different from the opening table.
- Card 52,000,000 arrives as a deliberate, celebratory conclusion rather than an arbitrary grind wall.
