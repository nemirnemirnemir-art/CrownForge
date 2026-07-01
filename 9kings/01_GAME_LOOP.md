# 01 — Game Loop

## High-Level Structure

```
RUN START
  └─ Choose King
  └─ Start with King's Base card placed + [MISSING: starting hand details]
       │
       ▼
  ┌─── YEAR LOOP ─────────────────────────────────────────────────────────┐
  │                                                                       │
  │  1. PLACEMENT PHASE                                                   │
  │     - Place/rearrange cards on the grid (before battle)              │
  │     - [MISSING: exact time limit or free placement rules]             │
  │                                                                       │
  │  2. BATTLE PHASE (Auto)                                               │
  │     - Kingdoms fight automatically                                    │
  │     - Player can use King's active ability (manually or auto)         │
  │     - Battle ends when one side is eliminated                         │
  │                                                                       │
  │  3. CARD PICK PHASE                                                   │
  │     WIN  → choose 1 of 3 cards from defeated king's deck             │
  │     LOSE → choose 1 of 3 cards from your OWN deck (consolation)      │
  │     Losing also costs 1 life                                          │
  │                                                                       │
  │  4. EVENT (if scheduled for this year — see Event Table below)        │
  │                                                                       │
  └───────────────────────────────────────────────────────────────────────┘
       │
       ▼
  YEAR 33: FINAL BATTLE (Boss Fight)
  - Defeat = ALL lives lost (run over)
  - Win = run complete; endless mode continues cycling every 33 years
```

---

## Event Table (Confirmed Years)

| Year | Event | Description |
|------|-------|-------------|
| 4 | Royal Council | Pick one Royal Decree from a selection |
| 6 | Prophet | Foresees a blessing; effect triggers at Year 16 |
| 8 | Diplomat | Choose war or peace with neighboring kings; controls which card pools appear |
| 12 | Merchant | Shop: buy cards for gold (30g first, +15g each; reroll 10g, +10g each) |
| 16 | Prophet's Blessing | [CONFIRMED] Delayed effect from Year 6 Prophet |
| 33 | Final Battle | Boss fight; losing removes ALL lives |
| Tower event | [MISSING year] | Unlocks 2 new grid plots; additional plots cost 30g each after Year 33 |

> Note: Events repeat in endless mode. Exact year schedule for non-listed years is [MISSING].

---

## Year-by-Year Breakdown (Approximate)

### Early Game (Years 1–12)
- Year 1–3: Build initial kingdom; limited cards, figure out your strategy
- Year 4: First Royal Council — often the most impactful decision of the run
- Year 6: Prophet visit — plan around the Year 16 blessing
- Year 8: Diplomat — decide which kings to war/trade with; shapes card pool
- Year 12: Merchant — first shop; gold economy matters here

### Mid Game (Years 13–28)
- Accumulate cards and upgrades
- Synergies start to compound
- [MISSING: are there events in this range?]

### Late Game (Years 29–33)
- Finalize kingdom build
- Year 33: Final Battle — requires a complete functioning build

---

## Card Pick Rules (Detail)

- [CONFIRMED] Win: see 3 cards randomly drawn from the defeated king's 9-card deck
- [CONFIRMED] Lose: see 3 cards randomly drawn from your OWN deck
- [CONFIRMED] Each battle is against a specific king (determines which card pool you draw from on win)
- [INFERRED] You face all 8 other kings at some point during a run; exact order [MISSING]
- [CONFIRMED] Rainbow King appears once per standard run; cards available in all shops

---

## Lives System

- [CONFIRMED] Losing a battle = -1 life
- [CONFIRMED] Losing Year 33 Final Battle = ALL lives lost (immediate run end)
- [MISSING] Starting number of lives
- [CONFIRMED] "Rebirth" Decree restores all lives (one of the 18 Universal Basic Decrees)

---

## Endless Mode

- [CONFIRMED] After surviving Year 33, run continues in endless mode
- [INFERRED] Cycle repeats every 33 years (enemies scale harder each cycle)
- [MISSING] Exact scaling formula per cycle
- [CONFIRMED] Tower event plots cost 30g each after Year 33 (suggests economy continues)
