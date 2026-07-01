# 02 — Card Types & Full Card Catalog

> Last corrected: 2026-03-29. Card types verified against `09_CARD_CATALOG_DETAILED.md`.
> For exact per-level stats, see `09_CARD_CATALOG_DETAILED.md`.

## The 6 Card Types

### 1. Troop
- [CONFIRMED] Mobile units that enter the battlefield and fight
- [CONFIRMED] Attack enemies directly; move toward targets
- [CONFIRMED] Default targeting: closest enemy (exceptions noted per card)
- [CONFIRMED] Can be mounted by other units if adjacent (Boar, Raptor — King of Nature)
- [INFERRED] Troops die when HP reaches 0; their plot becomes empty

### 2. Building
- [CONFIRMED] Stationary support structures placed on grid slots
- [CONFIRMED] Provide passive buffs, resources (gold), or amplify troops
- [CONFIRMED] Can receive Enchantments
- [INFERRED] Do not participate directly in combat; support role

### 3. Tower
- [CONFIRMED] Stationary ranged attackers placed on grid slots
- [CONFIRMED] CANNOT be attacked or destroyed
- [CONFIRMED] CANNOT receive Enchantments
- [CONFIRMED] Shoot projectiles at enemies automatically
- [CONFIRMED] Indestructible — persist through entire battle

### 4. Enchantment
- [CONFIRMED] Modifiers applied on top of other cards
- [CONFIRMED] No stack limit — can apply the same enchantment multiple times
- [CONFIRMED] CANNOT be applied to Towers
- [INFERRED] Applied during placement phase; enhance the card they're placed on
- [MISSING] Exact interaction rules (does enchanting a Building vs Troop work differently?)

### 5. Tome
- [CONFIRMED] One-time-use effects or persistent utility cards
- [CONFIRMED] King of Nomads has "Migration" — a Tome that moves plots
- [MISSING] General Tome mechanics (are all Tomes one-time? Persistent?)

### 6. Base
- [CONFIRMED] Every king has exactly one Base card
- [CONFIRMED] Base is placed at the start of the run (not drafted)
- [CONFIRMED] Upgrades to level 3 like any card (place duplicate on same slot)
- [CONFIRMED] With "Ingenious" perk: Base can be upgraded beyond level 3 (+5 levels per perk rank)
- [INFERRED] Destroying the Base likely ends the battle (not confirmed in open sources)

---

## Upgrade System

- [CONFIRMED] Cards upgrade by placing a duplicate on the same grid slot
- [CONFIRMED] Max level: 3 (for all cards except Base with Ingenious perk)
- [INFERRED] Level 2 = place one duplicate; Level 3 = place second duplicate
- [MISSING] Exact stat changes per level per card

---

## Full Card Catalog

### King of Nothing

| Card | Type | Notes |
|------|------|-------|
| Castle | Base | [MISSING: exact ability] |
| Soldier | Troop | Unique damage scaling [MISSING: formula] |
| Paladin | Troop | Unique damage scaling [MISSING: formula] |
| Archer | Troop | Ranged attacker |
| Scout Tower | Tower | Basic ranged tower |
| Farm | Building | Gold/resource generation |
| Wildcard | Tome | Levels up target plot by 1 |
| Blacksmith | Building | Buffs adjacent troops [INFERRED from meta: very strong] |
| Steel Coat | Enchantment | Defensive enchantment [MISSING: exact effect] |

### King of Spells

| Card | Type | Notes |
|------|------|-------|
| Citadel | Base | Shoots chain lightning |
| Wizard | Troop | Spell-based attacker |
| Warlock | Troop | Spell-based attacker |
| Static | Enchantment | Lightning chain on attack; +1 DMG +1 chain per stack |
| Offering | Tome | Destroy target plot to receive 3 random Tome cards |
| Combustion | Enchantment | 20% AoE explosion on kill per stack |
| Shaman | Troop | Buffs allies' attack damage based on Shaman's own DMG |
| Library | Building | Duplicates enchantments |
| Spire | Tower | Spell tower [MISSING: exact ability] |

### King of Greed

| Card | Type | Notes |
|------|------|-------|
| Palace | Base | Instantly kills enemies [MISSING: condition] |
| Beacon | Building | [MISSING: ability] |
| Vault | Building | Gold storage/generation |
| Dispenser | Tower | Scales with gold received |
| Midas Touch | Enchantment | Gold-related effect |
| Mortgage | Tome | [MISSING: ability] |
| Over-Invest | Tome | [MISSING: ability] |
| Mercenary | Troop | Damage scales with current gold |
| Thief | Troop | Jumps to enemy backline as targeting |

### King of Blood

| Card | Type | Notes |
|------|------|-------|
| Pagoda | Base | Summons Imps |
| Bomber | Troop | AoE attacker |
| Imp | Troop | Weak unit; summoned by Pagoda and Cemetery |
| Carnage | Enchantment | [MISSING: ability] |
| Sacrifice | Tome | Kill own unit for effect |
| Vampirism | Enchantment | Life steal |
| Mangler | Tower | Area damage turret; sacrifices adjacent units to gain +2 DMG |
| Cemetery | Tower | Summons Imp when adjacent unit dies in battle |
| Demon's Altar | Tower | Grows 0.5% per dead ally (permanent); summons demons |

### King of Nature

| Card | Type | Notes |
|------|------|-------|
| Treant | Base | Heals allied units |
| Mycelium | Tower | Spawns spores every 5s in battle; spores accumulate across battles |
| Clone | Tome | Duplicates the card on the selected plot |
| Elf | Troop | Targets most distant enemy (unique targeting) |
| Boar | Troop | Can be mounted by adjacent troop |
| Orchard | Tower | Creates roots that trap and damage enemies |
| Procreate | Tome | Adds 9 units to the selected troop |
| Forest | Building | [CONFIRMED: +2%/+4%/+6% HP/year to adjacent troops] |
| Poison Vial | Enchantment | Poison effect |

### King of Nomads

| Card | Type | Notes |
|------|------|-------|
| Warlord | Base + Troop | Unique: IS both base and troop; moves on battlefield |
| Mob | Troop | [MISSING: ability] |
| Raptor | Troop | Can be mounted by adjacent troop |
| Frost | Enchantment | Freeze/slow effect |
| Dragon's Den | Tower | Grows 20% per destroyed plot |
| Camp | Building | Adjacent plots gain stats when any card is placed on an empty plot |
| Migration | Tome | Moves a plot to an empty adjacent slot; +10% DMG and HP to moved card |
| Swords | Tome | +5 DMG or +5%, whichever is higher |
| Shields | Tome | +10 HP or +10%, whichever is higher |

### King of Stone

| Card | Type | Notes |
|------|------|-------|
| Stronghold | Base | Builds its own towers automatically |
| Cauldron | Building | [MISSING: ability] |
| Trebuchet | Tower | Shoots extra projectiles per building in kingdom |
| Quarry | Building | +2%/+4%/+6% DMG/year to ALL towers globally |
| Earthworks | Tome | Unlocks adjacent plots of target; returns those cards to hand |
| Ballista | Troop | Heavy piercing ranged troop |
| Trapper | Troop | Builds persistent traps; traps accumulate between battles |
| Wallmaker | Building | Builds walls (500/1000/2000 HP per level) |
| Flametower | Tower | Fire tower; physically moves onto battlefield |

### King of Progress

| Card | Type | Notes |
|------|------|-------|
| Mothership | Base | [MISSING: exact ability] |
| Executioner | Troop | Targets lowest-HP enemy |
| Defender | Troop | Reflects damage back to attackers |
| Lab Rat | Troop | Levels up when adjacent plots level up; NO level cap |
| Concabulator | Building | Levels all plots to level 3 when activated |
| Reinforce | Enchantment | +1% DMG to unit whenever any plot levels up |
| Precision | Enchantment | One additional guaranteed crit per stack |
| Converter | Tower | Turns enemies into allied rats; rats inherit Converter's stats |
| Overhaul | Tome | Destroy a plot to level up 2+ random plots; +1 more per subsequent use |

### King of Time

| Card | Type | Notes |
|------|------|-------|
| Bastion | Base | Warps enemies to backline + damage when rifts are cast |
| Warper | Troop | Summons melee units with 50% of its own stats |
| Orbiter | Troop | Copies every enchantment applied to adjacent plots |
| Portal | Building | At Lvl 3: rewinds run 2 years in time |
| Hourglass | Tower | Extremely slow; fires massive AoE explosion when charged |
| Amplifier | Building | Any buff it receives is also applied to N adjacent plots (N = level) |
| Rewind | Tome | Replace current draft hand with copies of last played cards |
| Adrenaline | Enchantment | +1% HPS per second elapsed in battle; ∞ stacks |
| Regression | Tome | Reduce plot by 1 level but retain all accumulated stats/enchantments |
| Temp Null | ??? | Joke card — does nothing |

### Merchant-Only / Special Cards

| Card | Type | Notes |
|------|------|-------|
| Razing | Tome | Destroys a plot (intentional); triggers a Royal Council event |
| Scapegoat | Troop | Passive; generates 3/6/9 gold on death per level |
| Shrine | Building | Spends gold every year to level up a random plot |
| Unify | Tome | Sacrifices all adjacent troops; target gains all their unit counts |
| Temple | Building | +10% to a random stat of a random plot on placement |
| Gigantify | Tome | Doubles DMG and HP of target troop |
| Ogre | Troop | +5% all stats per adjacent empty plot per year |
| Haste | Tome | +200% move speed to target (permanent) |
| Echoform | Tome | Duplicates target plot and all its stats to an adjacent empty plot |
| Slime | Troop | Spreads to one empty adjacent slot per year |
| X-Ray | Tome | Levels up all plots diagonally adjacent to target |
| Patronage | Tome | Levels up your base plot by 3 levels |
| Golem | Troop | Tomes have double effect on it |
| Gacha | Building | Triggers a Rainbow loot event at Lvl 3 |
| Osmosis | Tome | All same-named cards in kingdom get +10% to all stats |

### Rainbow King Cards
- [CONFIRMED] Rainbow King appears once per standard run
- [CONFIRMED] Rainbow King's cards are available in all shops
- [MISSING] Full card list for Rainbow King
- [MISSING] Full card list for Chaos King (enemy-only)
