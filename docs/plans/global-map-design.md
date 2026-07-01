# Global Map Hybrid Design

## Scope

This document fixes the current MVP design of the global map layer that connects the existing KOW gameplay, 9 Kings battles, cities, portals, roads, and advisors.

The goal is not to build a full 4X strategy layer. The goal is to create a lightweight strategic map that:

- gives long-term structure between combat sessions
- makes portal captures meaningful
- lets cities become strategic anchors
- keeps KOW relevant over time
- uses 9 Kings as the main resolution for city-vs-city military conflict
- stays realistic for an indie-sized implementation

This document reflects the currently agreed design decisions. Items that are still undecided are called out as `TBD` rather than being invented.

## High-Level Structure

The game has three connected layers:

1. `KOW` real-time portal clearing and defense gameplay
2. `9 Kings` card battle gameplay for major military clashes
3. a turn-based global 2D map that connects both modes

The global map is the strategic layer. It does not try to simulate population, supply chains, or large moving armies.

Instead, it focuses on:

- sparse portals appearing on the world map
- turning cleared portals into cities or immediate gold
- building around cities on real map tiles
- moving a single king unit as the main military piece
- moving envoy units for utility and pressure actions
- creating long-distance mobility through roads and portal travel
- resolving important wars through 9 Kings rather than army stacks

## Design Goals

### Keep the map readable

The map should stay visually clean. Portals are sparse and cities are meaningful nodes. The player should not need to parse hundreds of small active objects.

### Avoid army micro

There are no free-roaming armies, no stacks of units marching across every road, and no full tactical siege mode.

### Preserve both combat modes

KOW stays relevant because portals continue to matter and can reappear over time.

9 Kings stays relevant because it becomes the main resolution layer for major city conflicts once the strategic map matures.

### Keep expansion meaningful

Capturing a portal should force a strategic decision: invest in long-term city growth or take a short-term gold spike.

### Create gold sinks

Gold must matter beyond simple building placement. Roads, road upgrades, portal travel, and city development all create ongoing demand for gold.

## World Map Structure

The world map is a 2D tile map.

Portals do not exist on every tile. The map should feel relatively sparse, with portals as valuable strategic points rather than constant clutter.

Possible world tiles can include terrain flavor such as:

- forest
- mountain
- open land
- empty space or water-like gaps, depending on visual style

At the MVP level, terrain mainly serves readability, pathing, and city building placement. Complex terrain rules are not required yet.

### Sparse portals

Portals appear only on some world tiles.

The intended structure is:

- some portals exist at map generation or campaign start
- more portals can spawn later over time at random valid locations
- special hostile portals can also be created through envoy actions

This keeps KOW alive throughout the campaign rather than limiting it to the opening phase.

## Portal Resolution

When a player clears a portal through KOW, that portal is consumed.

After the victory, the player chooses one of two outcomes.

### Option A: Found a city

The portal disappears and a city is established on that location.

This is the long-term investment option. It gives:

- a new strategic anchor on the global map
- new nearby build slots
- future income and infrastructure potential
- a place for roads, defenses, and a portal network node

### Option B: Take a large gold reward

The portal disappears and no city is created.

This is the short-term economic option. It gives:

- an immediate gold spike
- faster ability to build roads and infrastructure elsewhere
- a greedier, tempo-oriented decision

The exact post-portal tile state after taking gold is still `TBD`, but the current agreed rule is that no city is founded there.

## Cities

Cities exist directly on the global map. They are not hidden inside a separate city screen and they are not treated like a mobile-style internal slot menu.

### City footprint

A city occupies roughly `2 world tiles`.

This is intentional so that a city feels like a real world object and not a single icon.

### Building placement

Buildings are placed on real adjacent world tiles around the city.

This means:

- buildings are not abstract internal sockets
- buildings visibly occupy the world around the city
- city development changes the look of the surrounding map

### First-ring-only MVP

For the MVP version, building is limited to the first ring around the city.

There is no second ring of construction and no fully recursive city sprawl system.

### Initially available build tiles

Not all adjacent tiles need to be available immediately.

Current intended direction:

- a newly founded city starts with a limited set of basic buildable tiles
- additional tiles in the first ring open gradually
- opening farther tiles in the first ring should take more turns and more influence-like pressure than opening the early ones

The exact unlock order and exact numbers are still `TBD`, but the design intent is fixed:

- city growth should feel progressive
- the first few build tiles should open quickly
- further tiles should take longer

## City Building Philosophy

Buildings should support duplicates.

This is a key agreed rule.

Examples:

- a city may build several mines
- a city may build several archives
- a frontline city may build multiple fortifications
- a utility city may mix one of everything

The design should not force every city into a one-of-each pattern.

Instead, cities should be able to specialize through repetition.

## Agreed Building Set

The currently agreed useful building pool is:

1. `Mine`
2. `Archive`
3. `Forge`
4. `Advisor House`
5. `Advisor Sharpening Tower`
6. `Pressure Obelisk`
7. `Fortification` or `Wall Tower`
8. `Portal`

The previously suggested `Monument of Power` or `Center of Influence` has been removed from the design for now.

### Mine

Purpose:

- produces gold

Role:

- basic economy
- supports roads, upgrades, portal travel, and expansion

Supports duplicates:

- yes

### Archive

Purpose:

- produces cards or card-related rewards for 9 Kings

Role:

- strengthens the 9 Kings layer
- lets cities contribute to battle preparation

Supports duplicates:

- yes

### Forge

Purpose:

- produces a selected equipment type for KOW

Role:

- city-driven support for the KOW layer
- not a rare-item casino system
- not an item reroll system

Current intended production model:

- the player chooses a production type
- the forge keeps producing that type over time
- equipment is consumable at scale in KOW rather than a special legendary artifact economy

Supports duplicates:

- yes

### Advisor House

Purpose:

- generates new advisors or advisor candidates over time

Role:

- feeds the advisor layer
- helps cities produce strategic utility pieces

Supports duplicates:

- yes, if desired by balance

The exact spawn cadence and roster rules are still `TBD`.

### Advisor Sharpening Tower

Purpose:

- improves advisors

Role:

- increases the value of advisors already obtained
- creates investment tension between expanding advisor count and improving advisor quality

Supports duplicates:

- likely yes, but exact stacking behavior is `TBD`

### Pressure Obelisk

Purpose:

- applies or resists pressure on a chosen tile

Modes:

- pressure mode toward a chosen tile or direction
- defense mode to protect a chosen owned tile or local zone from hostile pressure

Role:

- enables soft territorial struggle without armies
- helps shape borders around a city

Supports duplicates:

- yes

This building is explicitly considered a good fit for the design.

### Fortification or Wall Tower

Purpose:

- increases how long a city can survive under siege before falling automatically

Role:

- gives the king time to respond
- makes frontline cities distinct from economic rear cities
- supports border defense without requiring a separate siege combat mode

Supports duplicates:

- yes

Visual rule:

- the visual wall presentation does not need to expand one-for-one for every extra building
- multiple fortification buildings can exist mechanically even if the city art only shows a general wall state

### Portal

Purpose:

- enables teleportation between the owner’s own portal-enabled cities

Role:

- strategic mobility for the king
- required because one king alone cannot realistically defend a large multi-front map only through roads

Supports duplicates:

- no
- each city should support at most `1 portal`

This building is considered a core part of the late-map mobility solution.

## Units on the Global Map

The global map should stay minimal in moving pieces.

### King

The king is the single primary military unit.

Agreed rules:

- only the king can attack cities
- only the king can directly initiate major military confrontation on the map
- the king is also the key defensive responder

This creates a strong strategic identity:

- if the king is out of position, cities are vulnerable
- mobility and map planning matter more than unit spam

### Envoy

The current non-combat strategic unit is the envoy.

The envoy is not a city attacker.

Current agreed envoy actions are:

1. carry equipment
2. apply pressure to a tile
3. perform a ritual to spawn a hostile portal
4. initiate negotiations by moving onto an AI envoy

This gives the envoy an important strategic role without turning it into an army.

## Roads

Roads are essential because one king on a large map needs far more mobility than a single flat movement value can provide.

### Road tiers

Current agreed direction is:

1. sand road
2. stone road
3. normal road
4. iron road

These names can still be renamed later for tone or clarity, but the rule of multi-tier roads is fixed.

### Gold cost per tile

Current rough agreed cost progression per tile is:

1. `0.25`
2. `0.50`
3. `0.75`
4. `1.00`

These are design targets and can be rebalanced later.

### Road role

Roads provide:

- better local and regional mobility for the king
- a meaningful long-term use for gold
- infrastructure differentiation between well-developed and neglected regions

The player should choose where to invest rather than upgrading every road instantly.

## Portal Network Travel

Even high-level roads are not enough by themselves once the map is large and multiple AI fronts exist.

Because of that, city portals are the long-distance movement layer.

### Travel rule

Portal travel works only between cities owned by the same faction where both cities have a portal building.

### Cost

Teleporting costs gold.

The intended design is that the cost should depend on distance in some way, so strategic positioning and treasury management matter.

The exact formula is still `TBD`, but the agreed principle is fixed:

- teleporting is not free
- teleporting should be strong but economically meaningful

### Recommended turn rule

The current recommended implementation direction is:

- after teleporting, the king should either end movement for that turn or have strongly limited remaining movement

This is recommended to prevent abusive cross-map teleport-plus-attack chains.

## Pressure and Territorial Contest

The game should not use roaming armies to flip territory.

Instead, local control around cities should be shaped by pressure.

Current agreed forms of pressure interaction:

- envoy action on a tile
- pressure obelisk set to attack or defend a chosen tile or local zone
- city growth gradually unlocking more buildable space in the first ring

Pressure is therefore a soft strategic system for:

- opening new nearby city tiles
- contesting control around borders
- resisting hostile expansion

The exact numerical model is still `TBD`, but the intended behavior is already fixed.

## Siege and City Capture

There is no separate tactical siege mode.

Sieges are modeled as timed strategic events.

### Siege start

A siege begins when an enemy king reaches and attacks a city.

### Base logic

Once a siege starts:

- a siege timer begins
- if the defender does not respond in time, the city is captured automatically when the timer expires
- if the defender reaches the city in time, the important confrontation resolves through a 9 Kings battle
- if the attacker leaves, the siege ends

### Role of fortifications

Fortifications extend the amount of time a city can hold before automatic capture.

This means:

- an undefended city without walls falls relatively quickly
- a defended or heavily fortified city can hold longer
- the system creates meaningful strategic delay without needing a full siege minigame

This is one of the key agreed systems in the current design.

## KOW Relevance Over Time

One major design risk is that the game could shift too hard toward 9 Kings and make KOW irrelevant later.

The current design avoids that in several ways.

### Ongoing portal presence

KOW stays relevant because portals continue to appear on the world map over time.

This includes:

- naturally existing portals
- random future portal spawns
- envoy-created hostile portals

### City-produced KOW support

Cities also keep KOW relevant because they can produce support for that layer through:

- forge output
- advisor development
- economic growth that funds portal operations and infrastructure

This ensures KOW remains part of the long-term campaign instead of only the early game.

## 9 Kings Relevance Over Time

9 Kings becomes more important as the map develops because major city-vs-city confrontations should resolve through that mode.

Cities feed this layer through:

- archive production
- long-term strategic positioning
- the need to defend or recapture cities during sieges

This gives 9 Kings a clear late-strategic role without needing to replace KOW entirely.

## AI Implications

The design should also work for AI at MVP scale.

Because the system is intentionally narrow, AI priorities can stay simple.

### Likely AI priorities

- build mines for economy
- build archives or forges depending on strategic preference
- build fortifications on border cities
- build portals in key strategic cities
- improve road quality on important routes
- save gold for emergency king relocation through the portal network
- use envoys for pressure and special disruptive actions
- attack when the enemy king is too far away to respond in time

This keeps AI goals readable and implementable.

## Systems Explicitly Not Included in This MVP

The following are intentionally outside the current design:

- full 4X population management
- worker assignment simulation
- deep trade economy between factions
- multiple military units beyond the king as the main attacker
- tactical siege battles as a separate game mode
- a second ring of city construction
- internal city-only slot UIs replacing the world map
- market-style item rerolls
- diplomacy buildings that imply systems not yet defined

These are excluded to keep the scope realistic.

## Current Open Questions

The following items are not yet fully specified and should be decided later without changing the agreed backbone.

1. exact city-tile unlock order around a 2-tile city
2. exact numbers for pressure gain and resistance
3. exact gold reward for choosing loot instead of city founding
4. exact random portal spawn rules
5. exact distance cost brackets for portal travel
6. exact movement values granted by each road tier
7. exact advisor generation and sharpening timings
8. exact visual rules for how multi-building city outskirts are displayed
9. exact state of a tile after choosing gold instead of founding a city

These are tuning and implementation-detail questions, not backbone questions.

## Current Agreed Backbone Summary

The current fixed backbone is:

1. sparse portals on a 2D world map
2. portals can appear over time and can also be spawned by envoy action
3. clearing a portal gives a choice between founding a city or taking a large gold reward
4. cities exist directly on the world map and occupy about 2 tiles
5. city buildings are placed on real adjacent world tiles
6. the MVP uses only the first build ring around the city
7. buildings can be duplicated for specialization
8. only the king attacks cities
9. envoys handle utility actions, pressure, gear carrying, portal spawning, and negotiations
10. roads have four upgrade tiers and consume gold per tile
11. city portals enable gold-cost teleport travel between the owner’s own cities
12. each city has at most one portal building
13. sieges are timed events rather than a separate tactical mode
14. fortifications extend siege duration
15. KOW stays relevant through recurring portals and city support systems
16. 9 Kings stays relevant through siege resolution and city conflict

## Next Step

The next recommended document after this design is a concrete implementation plan that breaks the system into phased deliverables for MVP development.
