# Implementation decisions and approved clarifications

Baseline: `GDD.md`, version 1.0, 6 November 2026. The goal, opening capacity/yield, exclusion list, and all 104 named catalog entries are preserved. No additional gameplay features have been added.

## Owner decisions

- **Technology:** Godot 4, native PC application. A web build, if provided, is only a preview.
- **Delivery target:** complete playable implementation of the approved GDD, automated rules tests and six balance agents, original replaceable art/audio, and Steam release documentation.
- **Assets:** original casino-table art and synthesized effects/music are approved. These are production assets, not a claim of externally commissioned final art.
- **Buffer Logistics (C13):** each rank adds 10% capacity per helper, capped at **+200% of pre-Buffer capacity**. Other capacity multipliers apply afterward. The tooltip always displays the effective and maximum bonus.
- **Surge Potency (X03):** each rank adds 0.5 of one normal pickup action's output. Resolve the whole repeated actions normally, then add the fractional output as cards without another Combo refresh, Lucky roll, or Burst roll. Total action equivalents are 3 / 3.5 / 4 / 4.5 / 5.
- **Express Overclock (X07):** each rank adds 100% of the original Express multiplier: ×5/×10/×15/×20/×25. Cooldown still reduces by 5% per rank (multiplicative).
- **Steam:** no App ID has been supplied. Local cosmetic achievements work independently. Steamworks initialization and achievement mapping are optional release configuration; no credentials belong in the repository or chat.

## Explicit interpretations of underspecified math

These are implementation conventions, not newly approved features. They are centralized in the rules layer and tested.

1. **Capacity:** additive capacity is summed first, then Bigger Table, Master Counting Room, Diamond Pockets, Diamond Logistics, and the approved Buffer bonus multiply it. Round down once. Overflow actions are counted separately from capacity and are never multiplied by capacity upgrades.
2. **Overflow Tray:** an overflow *action* grants the complete current manual yield, including Lucky/Burst/Surge output. Only the stated number of final actions may begin above capacity; the resulting cards are not clipped. Auto-pickers and abilities never initiate overflow actions.
3. **Deposit Momentum:** +5 percentage points per rank per continuous deposit second, capped at 25% + 25 percentage points per rank. Reset on completion or cancellation. Full-batch status is snapshotted when the batch starts; rate upgrades and temporary effects remain live.
4. **Income categories:** additive bonuses within a category, multiplicative categories. Global additive = Premium Stock + Heart Appraisal (non-Hearts) + Full-Batch Appraisal; Compound Value and Master Appraiser are separate multipliers; rank = Ace Appreciation / Low Card Floor / Face Card Premium as applicable; source = Manual Appraisal or both automation appraisal upgrades; suit = Heart Values or the temporary Suit Surge; foil = (5 + Foil Value ranks) × Foil Polish × (1 + 25% × Heart Foil ranks for Hearts). Temporary category contains Combo card-income, Lucky money, Foil Frenzy income and Dealer income, added together. Royal Court is a separate rank-category multiplier. No foil modifier changes the deck bonus.
5. **Lucky Pickup:** +100% cards plus 50 percentage points per Lucky Cards rank, applied to the whole repeated action output. The extra money is +50% plus 25 percentage points per Lucky Money rank; it is a temporary income modifier on every independently generated card in that action, not retrospective repricing.
6. **Fractional yield:** whole cards plus a persistent fractional remainder. This makes percentage upgrades exact over repeated actions without random rounding. Only actual generated cards occupy capacity or count toward the goal.
7. **Combo:** yield multiplier = 1 + stacks × (1% + 0.25 percentage points per Combo Yield rank) × Club Combo multiplier. Card income = 1 + stacks × (0.5% + 0.125 percentage points per Combo Value rank). Club Performance multiplies manual yield only while a timed ability is active. Decay starts after 1.5 + 0.5 × Combo Memory seconds; rate is 10 × 0.85^Memory stacks/second. Combo Starter adds 10 stacks per rank on the first pickup after complete decay.
8. **Seeker cap:** ordinary permanent bias is min(5% + 7% × Focus + 25% × Master, 75% + 15% × Master). Pulse uses the stronger bias, never adds, and obeys the same current cap. High-Value Priority chooses uniformly among identities whose rank equals the highest missing rank. Pulse guarantees are spread through the sequence; only actually generated cards consume charges, so a full tray never spends upcoming Pulse cards.
9. **Smart Thresholds:** start at the selected threshold, or predict fullness at the end of counting using current pickup throughput. Each rank improves the prediction horizon (50% / 75% / 100% of estimated count duration) and reduces the safety margin. It never changes the selected threshold itself.
10. **Events:** a new event waits until its interaction is resolved or its offer expires; waiting offers do not consume cards or money. Active effects may overlap. Dealer choices replace only the previous Dealer buff. No offline time is simulated.
11. **Completion:** process the exact 52,000,000th card normally, then stop the batch and helpers. The remaining inventory and uncounted batch are retained for Endless. Completion time excludes pauses and closed time. Results are snapshotted at the threshold; Endless does not overwrite them.
12. **Large batches:** simulation accounts for every identity, foil and source, but uses count aggregation and bounded work slices for rendering/statistics. It never creates one scene node per card. Card counts and ledger entries use 64-bit integers; money/rates use double precision with a documented exact integer-cent accounting boundary where applicable.

## Balance policy

The GDD labels costs an initial tuning pass and explicitly authorizes economy tuning. Any departure from band defaults will be recorded in `docs/BALANCE.md` with agent results. The 52-million goal and opening rules are not tuning variables. Acceptance is measured, not assumed; a passing unit test is not a claim that a human playtest has occurred.

## Steam boundary

A Steam App ID, partner account, accepted distribution agreement, store assets, depot upload, and Steamworks review are external release steps. The repository includes an optional integration boundary and reproducible desktop export configuration; it does not pretend to publish or approve a Steam store page.
