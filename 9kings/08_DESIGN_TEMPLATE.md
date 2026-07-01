# 08 — Design Template

> This file abstracts the core systems of 9 Kings into reusable design patterns
> for building an original game. Use this as a starting point, not a blueprint to copy.

---

## Core Loop Template

```
RUN
  ├─ Player selects a CHARACTER (replaces King)
  │    └─ Each character has a unique starting card + unique card pool
  │
  ├─ YEAR LOOP (N rounds per run)
  │    ├─ SETUP PHASE: arrange cards on grid
  │    ├─ COMBAT PHASE: auto-resolved based on placement
  │    ├─ REWARD PHASE:
  │    │    WIN  → draft 1 of 3 cards from opponent's pool
  │    │    LOSE → draft 1 of 3 cards from own pool (consolation)
  │    │    LOSE → -1 life
  │    └─ EVENT (at scheduled rounds)
  │
  └─ FINAL BOSS (at round N)
       WIN  → run complete / endless loop
       LOSE → all lives gone → run over
```

**Key design decisions to make:**
- How many rounds per standard run? (9 Kings: 33)
- How many lives does the player start with?
- Is the loss-card-from-own-pool mechanic preserved? (It's a strong tension driver)

---

## Character Design Template

Each playable character should have:

| Element | Description | 9 Kings Example |
|---------|-------------|-----------------|
| **Identity** | 1-sentence theme | "King who scales gold into power" |
| **Base card** | Starting card that can't be removed | Palace, Treant, Warlord |
| **Card pool** | 8 additional unique cards | 8 cards per king |
| **Win condition** | How this character wins in late game | Gold stacking, altar growth, tower spam |
| **Weakness** | What this character struggles with early | Greed: weak vs swarm early |
| **Unique mechanic** | 1 signature system only this character has | Dragon's Den grows on destroyed plots |
| **Difficulty rating** | Beginner / Medium / Hard | |

### Asymmetry Design Axis
Consider placing characters along these axes:

```
Offense ←————————————————→ Defense
Scaling ←————————————————→ Board Control  
Economy ←————————————————→ Combat
Swarm   ←————————————————→ Single Unit
```

---

## Card Type Template

Minimum recommended card types for a 9Kings-style game:

| Type | Role | Key Constraint |
|------|------|----------------|
| **Troop** | Active fighters | Mobile; can be destroyed |
| **Building** | Passive support | Stationary; enhanceable |
| **Tower** | Passive attacker | Indestructible; not enhanceable |
| **Enchantment** | Modifier | Stacks on cards; not on towers |
| **Utility** (Tome) | One-shot or repositioning | Flexible; limited use |
| **Base** | Core anchor | Cannot be removed; upgradeable |

**Design note on Towers:** Making towers indestructible is a strong design choice — it creates a safe "floor" for the player's offense and allows tower builds to feel reliable without being boring. Consider keeping this.

**Design note on Enchantment stacking:** No stack limit creates extreme late-game scaling. This is intentional in 9 Kings but requires careful balancing. Consider whether you want a cap or not.

---

## Grid Template

```
Base grid size: N×M slots
Expansion: unlock additional slots via events or gold
Max slots: base + expansion cap
```

**Key decisions:**
- Starting size: smaller = more constrained early decisions (3×3 is tight and good)
- Expansion: tying expansion to specific events (not just gold) creates memorable moments
- Adjacency: define what "adjacent" means (orthogonal only? diagonal? radius?)

**Adjacency effects to consider:**
- Adjacent troop gets buff from building
- Adjacent troop can mount a mount unit
- Adjacent upgrade triggers scaling effect on another card
- Enchantment affect area (single slot vs adjacent)

---

## Scaling Systems Template

9 Kings has several distinct scaling patterns. Use as needed:

| Pattern | Example | Design Effect |
|---------|---------|---------------|
| **Permanent growth** | Demon's Altar (+0.5% per death) | Exponential power; punishes early losses |
| **Upgrade-triggered** | Lab Rat (levels up when neighbors do) | Rewards efficient leveling |
| **Resource-scaled** | Mercenary (damage = gold held) | Economy-combat coupling |
| **Destruction-scaled** | Dragon's Den (+20% per destroyed plot) | Sacrificial strategy; unique risk/reward |
| **Stack-scaled** | Enchantment stacking | Simple multiplicative; easy to understand |
| **Conditional** | Weakspot (+50% vs debuffed) | Rewards combo setup |

---

## Event Schedule Template

Design your events around tension and decision points:

| Timing | Event Type | Purpose |
|--------|-----------|---------|
| Early (round 3–5) | **Decree/Upgrade choice** | Run-defining early direction |
| Early-mid (round 5–8) | **Foreseeing/Delayed** | Introduce future planning element |
| Mid (round 8–10) | **Faction choice** | Shape card pool for rest of run |
| Mid (round 10–14) | **Shop** | Gold sink; catch-up mechanic |
| Mid-delayed | **Payoff** | Reward of earlier foreseeing event |
| Variable | **Grid expansion** | New strategic possibilities |
| Final | **Boss fight** | Requires complete functioning build |

---

## Meta-Progression Template

Between-run progression should:
- Unlock gradually (don't front-load all power)
- Feel character-specific (rewards exploring different characters)
- Not make the game trivially easy (perks should be quality-of-life, not win-buttons)

**Perk categories to consider:**
- Universal perks (apply to all characters)
- Character-specific perks (deepen one character's unique mechanic)
- Wildcard/multiplicative perks (interact with other perks — risky but fun)

**Slot economy:** Limiting active perks (9 slots) forces choices even at max unlock.

---

## Key Design Lessons from 9 Kings

1. **Post-loss reward is critical** — getting a consolation card on loss keeps players engaged and reduces frustration. Never let a loss feel purely punishing.

2. **Asymmetric characters carry replay value** — each king feels like a different game. Target 6–9 deeply asymmetric characters rather than 20 similar ones.

3. **Indestructible permanent elements** — towers that can't die create reliable "foundations." Players can plan around them. Reduces swing/frustration.

4. **One run-defining choice early** — Decree at Year 4 makes every run feel distinct. A single meaningful early choice beats many minor choices.

5. **Stacking without limit enables self-expression** — players find creative power peaks when there's no hard ceiling. Plan for this to create memorable "I did that" moments.

6. **Base card = identity anchor** — every character has one card that's always there. This gives the player something to build around from turn 1.

7. **Combat automation removes micromanagement fatigue** — the city-building and deck-building ARE the game. Combat is the consequence, not the action. Keep it fast and automatic.

8. **Scale the consolation prize correctly** — if losing gives too-good cards, players may prefer losing. If too weak, it's just a loss. Tune carefully.
