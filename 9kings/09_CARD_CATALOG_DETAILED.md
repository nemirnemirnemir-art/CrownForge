# 09 — Card Catalog (Exact Descriptions + Stats)

> Source: 9kings.wiki.gg + player-provided stat tables (2026-03-29).
> Stats are shown per level: **Lvl 1 → Lvl 2 → Lvl 3**
> Note: King of Time is now implemented and has a full card set.

---

## Notation

| Column | Meaning |
|--------|---------|
| HP | Health per unit |
| DMG | Damage per hit |
| HPS | Hits per second (attack speed) |
| CC | Crit Chance (%) |
| Units | Unit count in the troop |
| ∞ stacks | Enchantment/Tome — no stack limit |

---

## King of Nothing

### Castle — Base
> "Hurls a stone projectile onto your enemies."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| DMG | 10 | 12.5 | 15.63 |

---

### Soldier — Troop
> "Well-balanced melee troop."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 23 | 28.75 | 35.94 |
| DMG | 3 | 3.75 | 4.69 |
| HPS | 0.5 | 0.63 | 0.78 |
| CC | 5% | 5% | 5% |
| Units | 9 | 18 | 27 |

---

### Paladin — Troop
> "Highly defensive melee troop."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 37 | 55.5 | 83.25 |
| DMG | 8 | 12 | 18 |
| HPS | 0.25 | 0.25 | 0.25 |
| CC | 5% | 5% | 5% |
| Units | 3 | 6 | 9 |

*Attack speed does not scale with level — Paladin is always slow.*

---

### Archer — Troop
> "Deals weak but fast ranged damage."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 12 | 15 | 18.75 |
| DMG | 2.3 | 2.88 | 3.59 |
| HPS | 0.58 | 0.73 | 0.91 |
| CC | 5% | 6% | 7% |
| Units | 9 | 18 | 27 |

---

### Scout Tower — Tower
> "Shoots powerful single-target arrows."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| DMG | 25 | 37.5 | 56.25 |
| HPS | 0.5 | 0.63 | 0.78 |
| CC | 20% | 20% | 20% |

*High crit chance (20%) — punchy even at low base damage.*

---

### Farm — Building
> "Every year, adds units to one adjacent troop."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Units/year | +1 | +2 | +3 |

---

### Blacksmith — Building
> "Every year adds attack damage to adjacent troops and buildings."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| DMG/year | +2% | +4% | +6% |

*Cumulative per year. By Year 33 a Lvl 3 Blacksmith grants +198% attack damage total.*

---

### Wildcard — Tome
> "Levels up target plot."

No stats. Levels a chosen plot by 1.

---

### Steel Coat — Enchantment
> "Cancels the first hit the target unit would take every battle."

∞ stacks. Each stack = one blocked hit per battle. Resets every battle.

---

## King of Spells

### Citadel — Base
> "Strikes your opponents with chaining lightning bolts."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| DMG | 15 | 22.5 | 33.75 |

---

### Wizard — Troop
> "Ranged troop. Casts powerful attacks at a slow rate."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 11 | 13.75 | 17.19 |
| DMG | 12 | 21 | 36.75 |
| Units | 9 | 18 | 27 |

*Damage scales faster than HP — high DPS ceiling but fragile.*

---

### Warlock — Troop
> "Sturdy troop that deals melee area damage."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 33 | 49.5 | 74.25 |
| HPS | 0.13 | 0.17 | 0.21 |
| Units | 3 | 6 | 9 |

*DMG not in source data. Deals melee AoE damage on each swing.*

---

### Shaman — Troop
> "Buffs allies' attack damage based on its own damage."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 12 | 15 | 18.75 |
| DMG | 4 | 6 | 9 |
| HPS | 0.2 | 0.25 | 0.31 |
| Units | 6 | 12 | — |

*Ally buff is proportional to Shaman's own DMG stat — stack DMG enchantments on Shaman.*

---

### Spire — Tower
> "Heals your units that are closest to death during battle."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Healing | 10 | 15 | 22.5 |

*Healing tower, not attack tower. Prioritizes lowest-HP allies.*

---

### Library — Building
> "Every year, has a 50% chance of duplicating a stack of one adjacent troop."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Applications/year | 1× | 2× | 3× |

*At Lvl 3: 3 attempts per year each at 50% → expected 1.5 enchantment duplications per year.*

---

### Static — Enchantment
> "Unit's attacks trigger a lightning chain. Deals +1 damage and +1 chain per stack."

∞ stacks. Each stack: +1 DMG to chain, +1 additional chain jump.

---

### Combustion — Enchantment
> "Unit causes area damage equal to 20% of its attack when it kills an enemy."

∞ stacks. Each stack = additional 20% AoE explosion on kill.

---

### Offering — Tome
> "Destroy target plot to receive 3 random tome cards."

Destroys a plot permanently; rewards 3 Tome cards drawn from pool.

---

## King of Greed

### Palace — Base
> "Casts a ray that insta-kills target. Golden enemies drop gold."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Gold (from golden enemies) | 1 | 2 | 3 |

---

### Beacon — Building
> "Every year, adds +2% attack speed to adjacent troops and buildings."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HPS/year | +2% | +4% | +6% |

---

### Vault — Building
> "Receive gold at the end of every year."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Gold/year | 3 | 6 | 9 |

---

### Dispenser — Tower
> "Single-target tower. Gains +1% attack speed for each 1 gold you receive."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| DMG | 8 | 14 | 24.5 |

*+1% HPS per gold received over entire run (cumulative, permanent).*

---

### Mercenary — Troop
> "Strong but fickle warriors for hire. You always have 1 unit for each 15 gold you own."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 34 | 44.2 | 57.46 |
| DMG | 9 | 11.7 | 15.21 |
| HPS | 0.67 | 0.83 | 1.04 |
| Units | = gold ÷ 15 | = gold ÷ 15 | = gold ÷ 15 |

*Unit count = floor(current gold / 15). Spending gold reduces army size.*

---

### Thief — Troop
> "Assassin troop that jumps to enemy's backline."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 9 | 11.25 | 14.06 |
| DMG | 9 | 11.25 | 14.06 |
| HPS | 0.4 | 0.5 | 0.62 |
| Units | 9 | 18 | 27 |

*HP = DMG at every level — glass cannon.*

---

### Midas Touch — Enchantment
> "When this troop kills, there's a 2% chance to receive 1 gold."

∞ stacks. Each stack = additional 2% kill→gold chance.

---

### Over-Invest — Tome
> "Spend 30 gold to increase every stat of a troop or tower by 15%."

∞ stacks. Permanent buff. Can be used repeatedly on the same target.

---

### Mortgage — Tome
> "Destroy target plot to receive gold for each level it had."

*(Exact gold per level missing from source. wiki.gg states 30g per level.)*

---

## King of Blood

### Pagoda — Base
> "Summons imps onto the battlefield."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Imp HP | 12 | 15 | 18.75 |
| Imp DMG | 1.5 | 3.38 | 7.59 |

---

### Bomber — Troop
> "Runs towards the enemy and explodes, dealing area damage."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 13 | 16.25 | 20.31 |
| DMG (explosion) | 15 | 22.5 | 33.75 |
| Units | 6 | 12 | 18 |

*Suicide AoE — charges and detonates.*

---

### Imp — Troop
> "Fast and aggressive troop with many small units."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 12 | 15 | 18.75 |
| DMG | 1.5 | 2.25 | 3.38 |
| Units | 13 | 26 | 39 |

*High unit count = many deaths = many Demon's Altar stacks.*

---

### Mangler — Tower
> "Area damage turret. Every year, sacrifices an adjacent unit per level to gain +2 damage."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Sacrifices/year | 1 | 2 | 3 |

*+2 flat DMG per sacrifice (permanent). Place adjacent to high-unit-count troops.*

---

### Cemetery — Tower
> "If an adjacent unit dies in battle, summons an imp to fight in its place."

Summoned imp stats:

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Imp HP | 12 | 15 | 18.75 |
| Imp DMG | 1.5 | 2.25 | 3.38 |

*Triggers on adjacent death only. Position next to Imps or Bombers.*

---

### Demon's Altar — Tower
> "Summons one demon per level. For each dead ally, grows permanently 0.5% stronger."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Demons summoned | 1 | 2 | 3 |

*+0.5% to all demon stats per ally death. Permanent, cumulative, cross-battle. No cap.*

---

### Carnage — Enchantment
> "Unit explodes when killed, dealing 10% HP as area damage."

∞ stacks. Each stack = additional 10% HP explosion on death.

---

### Vampirism — Enchantment
> "Unit's attacks heal it for 20% of damage dealt."

∞ stacks. Each stack = additional 20% lifesteal.

---

### Sacrifice — Tome
> "Destroy target plot to level up adjacent plots."

Destroys 1 plot → all orthogonally adjacent plots level up by 1.

---

## King of Nature

### Treant — Base
> "Creates a healing area on the ground."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Healing/s | 1 | 1.25 | 1.56 |

---

### Boar — Troop
> "Can be mounted by adjacent troops. For each 1 HP it has, increases rider stats by 1%."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 30 | 60 | 120 |
| Units | 6 | 12 | 18 |

*Rider buff = Boar's total HP × 1%. Lvl 3 Boar = +120% to all rider stats.*
*HP doubles each level — exponential scaling with HP enchantments.*

---

### Elf — Troop
> "Ranged sniper troop. Always attacks the most distant target."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 27 | 33.75 | 42.19 |
| DMG | 20 | 25 | 31.25 |
| HPS | 0.11 | 0.14 | 0.17 |
| CC | 10% | 12% | 15% |
| Units | 3 | 6 | 9 |

*Slow but high-damage sniper. Ignores frontline; always hits most distant target.*

---

### Orchard — Tower
> "Creates roots that trap enemies."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Root DMG | 4 | 6 | 9 |
| HPS | 0.1 | 0.13 | 0.16 |
| Roots | 3 | 6 | 9 |

*Roots immobilize. Synergizes with Weakspot decree (+50% dmg vs rooted/stunned).*

---

### Forest — Building
> "Every year, adds +2% HP to adjacent troops."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP/year | +2% | +4% | +6% |

---

### Mycelium — Tower
> "Summons a fighting spore every 5 seconds in battle. Spores accumulate every battle."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Spore DMG | 5 | 7.5 | 11.25 |

*Spores persist and accumulate across every battle in the run. A 33-year run = massive spore army.*
*(wiki.gg listed 9s spawn interval; player data shows 5s.)*

---

### Poison Vial — Enchantment
> "Unit's attacks apply 1 poison stack to the enemy."

∞ stacks. Each stack = +1 poison stack applied per hit.

---

### Clone — Tome
> "Clone the card of the selected plot."

Duplicates the selected card. Useful to create upgrade copies.

---

### Procreate — Tome
> "Adds 9 units to the selected troop."

One-time use. +9 units permanent.

---

## King of Nomads

### Warlord — Base / Troop
> "Shoots banners that add Warlord's stats to target allies."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 12 | 15 | 18.75 |
| DMG | 5 | 6 | 7.2 |
| CC | 10% | 15% | 20% |
| Units | 3 | 6 | 9 |

*Is the base AND a troop. Its death ends the run. Buffs allies via banner throws.*

---

### Mob — Troop
> "Stone-throwing units. Gains a unit for each adjacent unit added."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 13 | 16.25 | 20.31 |
| DMG | 4 | 5 | 6.25 |
| HPS | 0.33 | 0.37 | 0.4 |
| Units | 3 | 6 | 9 |

*Mirrors unit additions from adjacent cards. Synergizes with Farm, Procreate.*

---

### Raptor — Troop
> "Can be mounted by adjacent troops. Sums its stats with rider and pierces through the frontline."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 17 | 25.5 | 38.25 |
| DMG | 4 | 6 | 9 |
| Units | 6 | 12 | 18 |

*When mounted: rider stats + Raptor stats combine. Merged unit pierces through frontline.*

---

### Dragon's Den — Tower
> "Summons powerful single-strike dragons. Gets 20% stronger each time a plot is destroyed."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Dragon DMG | 10 | 15 | 22.5 |

*One attack per dragon per battle. +20% all stats per destroyed plot (permanent).*

---

### Camp — Building
> "When a card is placed on an empty plot, Camp's adjacent plots gain stats."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Stats per placement | +2% | +4% | +6% |

*Triggers during placement. Use Migration repeatedly to proc multiple times.*

---

### Frost — Enchantment
> "Attacks slow the enemy's movement and attack speed by 20%."

∞ stacks. Each stack = additional 20% slow to movement and attack speed.

---

### Migration — Tome
> "Moves target to an empty adjacent plot. Moved card gains +10% damage and HP."

Each use: permanently +10% DMG and +10% HP to moved card.

---

### Swords — Tome
> "Adds 5 damage or +5% damage, whichever's higher."

One-time use. Permanent buff to target.

---

### Shields — Tome
> "Adds 10 HP or +10% HP, whichever's higher."

One-time use. Permanent buff to target.

---

## King of Stone

### Stronghold — Base
> "Summons towers that shoot nearby enemies."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Summoned tower DMG | 5 | 6.25 | 7.81 |

---

### Ballista — Troop
> "Ranged troop that shoots huge bolts with piercing damage."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 12 | 15 | 18.75 |
| DMG | 3 | 3.75 | 4.69 |
| HPS | 0.09 | 0.11 | 0.14 |
| CC | 10% | 12% | 15% |
| Units | 3 | 6 | 9 |

*Extremely slow fire rate. Bolts pierce multiple enemies per shot.*

---

### Trapper — Troop
> "Builds traps that inflict damage. Untriggered traps accumulate between battles."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 3 | 3.75 | 4.69 |
| Trap DMG | 2 | 3 | 4.5 |
| Units | 3 | 6 | — |

*Very fragile unit. Value is entirely in the persistent trap field.*

---

### Flamethrower — Tower
> "A mobile tower that moves onto the battlefield to burn enemies."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Speed | Slow | Average | Fast |

*Unique: physically moves onto battlefield unlike standard towers.*
*(Also referred to as "Flametower" in some sources.)*

---

### Trebuchet — Tower
> "Multi-projectile tower. Shoots one extra projectile per building in your kingdom."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Base projectiles | 2 | 3 | 4 |

*+1 per building. Lvl 3 + 7 buildings = 11 projectiles per shot.*

---

### Cauldron — Building
> "All adjacent plots now deal poison damage."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Poison stacks/hit | 1 | 2 | 3 |

*Applies to all adjacent cards regardless of type.*

---

### Quarry — Building
> "Adds damage to all towers every year."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Tower DMG/year | +2% | +4% | +6% |

*Global buff — ALL towers in your kingdom, not just adjacent.*

---

### Wallmaker — Building
> "Builds defensive walls in your kingdom."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Wall HP | 500 | 1000 | 2000 |

---

### Earthworks — Tome
> "Unlocks target's adjacent plots. Target's cards return to your hand, up to 3 copies."

Destroys adjacent plots of target; returns those cards to hand (max 3 copies).

---

## King of Progress

### Mothership — Base
> "Flies toward enemies like a unit. Can be controlled on the battlefield."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| DMG | 10 | 12.5 | 15.63 |

*Player-controllable during battle. Only controllable base card in the game.*

---

### Defender — Troop
> "Tanker unit that doesn't attack but reflects all taken damage."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 25 | 50 | 100 |
| Units | 3 | 6 | 9 |

*HP doubles per level. Reflects 100% of incoming damage. Never attacks.*

---

### Executioner — Troop
> "Ranged troop. Always attacks the enemy with the lowest health."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 14 | 21 | 31.5 |
| HPS | 1.33 | 2.0 | 3.0 |
| Units | 6 | 12 | 18 |

*Very fast attack speed at Lvl 3 (3 hits/second). DMG not in source data.*

---

### Lab Rat — Troop
> "Disposable melee troop. Levels up whenever adjacent plots level up. Deals damage to bosses instead."

**Base stats (Lvl 1):**

| Stat | Starting value |
|------|---------------|
| HP | 8.8 |
| DMG | 4.2 |
| HPS | 0.3 |
| Move Speed | 1 |
| Units | 2 |

**Per-level scaling (unlimited levels):**

| Stat | Per level |
|------|-----------|
| HP | +4% |
| DMG | +4% |
| HPS | +1% |
| Move Speed | +1% |
| Units | +2 |

*Levels up from ANY adjacent plot upgrade. With Concabulator + Overhaul chains, reaches extreme power.*

---

### Concabulator — Building
> "When this building reaches level 3, it levels up all your plots."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Effect | None | None | All plots +1 level |

*One-time trigger at Lvl 3. Each Lab Rat adjacently levels up when this fires.*

---

### Converter — Tower
> "Turns enemies into rats fighting for you. Rats inherit Converter's stats."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Rat HP | 5 | 5.45 | 5.94 |
| Rat DMG | 2 | 2.18 | 2.38 |
| Rat HPS | 0.28 | 0.29 | 0.3 |

*Buff Converter = stronger rats. Converted rats fight until end of battle.*

---

### Reinforce — Enchantment
> "Unit gains +1% damage whenever any plot levels up."

∞ stacks. Each stack = additional +1% DMG per any plot level-up.

---

### Precision — Enchantment
> "One hit is always critical."

∞ stacks. Each stack = one more guaranteed crit in the attack sequence.

---

### Overhaul — Tome
> "Destroy target plot to level up two random plots. Each use, one more plot is leveled up."

| Use | Plots leveled |
|-----|--------------|
| 1st | 2 |
| 2nd | 3 |
| Nth | N+1 |

---

## King of Time

*King of Time is now implemented. Previous documentation had this as empty.*

### Bastion — Base
> "Cast rifts that warp each enemy to the backlines once. Rifts deal damage when cast."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Rift DMG | 10 | 12.5 | 15.6 |

*Warps enemies to backline when they enter combat — disrupts enemy formation.*

---

### Warper — Troop
> "Summons melee units that inherit half its stats."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 12 | 14.4 | 17.3 |
| DMG | 4 | 4.8 | 5.8 |
| HPS | 0.1 | 0.1 | 0.1 |
| CC | 0% | 0% | 0% |
| Units | 5 | 10 | 15 |

*Spawns melee units with 50% of Warper's stats. Very slow attack speed.*

---

### Orbiter — Troop
> "Magnetic spellcaster. When an adjacent plot gets an enhancement, it gets it too."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 26 | 31.2 | 37.4 |
| DMG | 3 | 3.6 | 4.3 |
| HPS | 0.3 | 0.4 | 0.4 |
| CC | 10% | 15% | 20% |
| Units | 6 | 12 | 18 |

*"Enhancement" = enchantment stack. Any enchantment applied to an adjacent card also applies to Orbiter.*
*Synergizes with Library (Spells), Static, Combustion, any enchantment stacker.*

---

### Portal — Building
> "When this building reaches level 3, your kingdom travels back 2 years in time."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Effect | None | None | Rewind 2 years |

*Rewinds run by 2 years — fight those battles again, pick different cards.*

---

### Hourglass — Tower
> "Extremely slow tower. Releases a massive explosion when fully charged."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| DMG | 10 | 19.2 | 23 |
| HPS | 0.3 | 0.1 | 0.1 |
| CC | 0% | 0% | 0% |

*Charges slowly; fires a large AoE explosion. Attack speed gets slower as it levels (charges more power).*

---

### Amplifier — Building
> "Gives every buff it gains to one adjacent plot. Amplifies one extra plot per level."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Plots buffed | 1 | 2 | 3 |

*Any buff applied to Amplifier (Blacksmith, Quarry, Decrees, Enchantments, etc.) copies to N adjacent plots.*

---

### Rewind — Tome
> "Throw this into the pit to replace your current hand with copies of your last played cards."

Discards current draft hand; replaces with copies of previously played cards.

---

### Adrenaline — Enchantment
> "During battle troop gains +1% attack speed per second."

∞ stacks. Each stack = additional +1% HPS per second elapsed in battle.
*In a long battle (e.g. 60 seconds): base = +60% HPS from 1 stack; 5 stacks = +300% HPS.*

---

### Regression — Tome
> "Brings plot back 1 level but retains all its current stats and effects."

Reduces plot level by 1 while keeping all stat accumulation and enchantments.
*Use case: reset a card to re-trigger level-up effects (Lab Rat levels, Concabulator, Reinforce, Portal).*

---

### Temp Null — ???
> "You broke space-time continuum. This card does nothing."

No mechanical effect. Joke/easter egg card representing a temporal paradox.

---

## Merchant / Universal Cards

### Echoform — Tome
> "Duplicates target plot and all its stats to one empty adjacent plot."

Copies card + all accumulated stat multipliers + all enchantments. Extremely powerful.

---

### Gigantify — Tome
> "Doubles the size, damage, and HP of target troop."

×2 DMG and ×2 HP. Unit visually becomes larger in battle.

---

### Haste — Tome
> "Increases target's movement speed by 200%."

Permanent +200% move speed to target.

---

### Ogre — Troop
> "Lonely unit. Every year, increases 5% of all stats for each adjacent empty plot."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 20 | 24 | 28.8 |
| DMG | 4 | 4.8 | 5.76 |
| HPS | 0.25 | 0.28 | 0.3 |
| CC | 5% | 5% | 5% |
| Units | 3 | 6 | 9 |

*+5% all stats per adjacent empty plot per year. Prefers isolation.*

---

### Golem — Troop
> "Magic tanker. Any tome used on it has double its effect."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 30 | 37.5 | 46.9 |
| DMG | 9 | 15.8 | 27.6 |
| HPS | 0.2 | 0.2 | 0.2 |
| CC | 0% | 0% | 0% |
| Units | 3 | 6 | 9 |

*DMG scales aggressively per level. Gigantify on Golem = ×4 DMG (double effect of ×2).*

---

### Patronage — Tome
> "Levels up your base plot by 3 levels."

One-time use. Powerful with Ingenious perk (base goes beyond Lvl 3).

---

### Razing — Tome
> "Destroys target plot forever. Automatically triggers a Royal Council event."

Permanent destruction + free Decree pick. Core for Nomads Dragon's Den strategy.

---

### Scapegoat — Troop
> "Passive backline unit. If killed in battle, generates 3 gold per level."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 30 | 30 | 30 |
| DMG | 1 | 1 | 1 |
| HPS | 1 | 1 | 1 |
| CC | 0% | 0% | 0% |
| Units | 9 | 18 | 27 |
| Gold on death | 3 | 6 | 9 |

*Base stats don't scale with level — only unit count and death payout change.*

---

### Shrine — Building
> "Spends gold every year to level up a random plot. Costs 3 less gold per level."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Gold cost/year | 9 | 6 | 3 |

*At Lvl 3: 3g/year for a random plot level-up — very efficient.*

---

### Gacha — Building
> "When it gets to level 3, trigger a Rainbow loot event."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| Effect | None | None | Rainbow Event |

*Rainbow loot event = draw from Rainbow King's card pool.*

---

### Slime — Troop
> "Proliferating troop that multiplies itself to one empty adjacent plot every year."

| | Lvl 1 | Lvl 2 | Lvl 3 |
|--|-------|-------|-------|
| HP | 14 | 17.5 | 21.88 |
| DMG | 1.5 | 2.25 | 3.38 |
| HPS | 0.71 | 0.71 | 0.71 |
| CC | 5% | 5% | 5% |
| Units | 3 | 6 | 9 |

*Spreads to one adjacent empty slot per year. Can fill entire grid over time.*

---

### Temple — Building
> "Increases 10% of a random stat of a random plot."

One-time trigger per placement. Random stat of random plot +10%.

---

### Unify — Tome
> "Sacrifices all troops adjacent to target. Target plot gains the number of units sacrificed."

Destroys all adjacent troops → transfers all their unit counts to target plot.

---

### X-Ray — Tome
> "Levels up all plots diagonal to the target plot."

Affects diagonal neighbors only (not orthogonal). Each gains +1 level.

---

### Osmosis — Tome
> "All plots of the same card as the target plot get 10% to all stats."

Every copy of a specific card in your kingdom simultaneously gets +10% all stats.

---

## New Cards Not in Previous Documentation

| Card | Type | King | Key mechanic |
|------|------|------|-------------|
| Golem | Troop | Merchant | Tomes have double effect on it |
| Gacha | Building | Merchant | Rainbow event at Lvl 3 |
| Osmosis | Tome | Merchant | +10% to all same-named cards |
| Bastion | Base | King of Time | Warps enemies to backline + damage |
| Warper | Troop | King of Time | Summons units with half its stats |
| Orbiter | Troop | King of Time | Copies enchantments from adjacent cards |
| Portal | Building | King of Time | Rewinds run 2 years at Lvl 3 |
| Hourglass | Tower | King of Time | Charges slowly → massive AoE explosion |
| Amplifier | Building | King of Time | Propagates all its buffs to N adjacent plots |
| Rewind | Tome | King of Time | Replace hand with last played cards |
| Adrenaline | Enchantment | King of Time | +1% HPS per second in battle |
| Regression | Tome | King of Time | Down 1 level, keeps all stats |
| Temp Null | ??? | King of Time | Does nothing (joke card) |

---

## Corrections vs Previous Documentation

| Card | Previous value | Correct value |
|------|---------------|---------------|
| Vampirism | 25% lifesteal | **20% lifesteal** |
| Mycelium spawn rate | every 9 seconds | **every 5 seconds** |
| Ogre buff | 10% per empty plot | **5% per empty plot** |
| Shields | 5 HP or +5% | **10 HP or +10%** |
| Mangler type | Building | **Tower** |
| Cemetery type | Building | **Tower** |
| Demon's Altar type | Building | **Tower** |
| Mycelium type | Building | **Tower** |
| Orchard type | Building | **Tower** |
| Ballista type | Tower | **Troop** |
| Trapper type | Building | **Troop** |
| Converter type | Building | **Tower** |
| Swords type | Enchantment | **Tome** |
| Shields type | Enchantment | **Tome** |
| King of Time | Not implemented | **Implemented — 10 cards** |
