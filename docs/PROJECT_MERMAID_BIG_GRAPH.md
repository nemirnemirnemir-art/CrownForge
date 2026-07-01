# Project Big Graph (Mermaid)

Last updated: 26.03.2026

This page provides one large Mermaid graph for the current project architecture.

## Usage contract

1. This diagram is an entry map for orientation and navigation.
2. This diagram is not the canonical source of gameplay or architecture behavior.
3. Canonical behavior and file ownership remain in:
   - `docs/PROJECT_NAVIGATOR.md`
   - `docs/ARCHITECTURE.md`
   - focused subsystem docs that actually exist in the repository

## Maintenance rules

1. Update this graph in the same task when runtime topology changes (new/removed modules, autoloads, key scene flows, canonical path moves).
2. Keep only high-value nodes and key edges. Do not expand every helper script into the graph.
3. Prefer labeled edges for non-obvious links (for example `cast`, `fallback`, `spell_add`).
4. Before closing a task that touched this graph, verify Mermaid rendering and cross-check that node paths/names match current code.

```mermaid
flowchart LR

  subgraph RT["Runtime Orchestrator"]
    GS["GameScene.tscn / GameScene.gd"]
    GSW["GameSceneWaves"]
    GSH["GameSceneHeroes"]
    GST["GameSceneStages"]
    GSI["GameSceneSignals"]
    GSP["GameSceneSpells"]

    GS --> GSW
    GS --> GSH
    GS --> GST
    GS --> GSI
    GS --> GSP
  end

  subgraph CORE["Autoload / Core"]
    EB["EventBus"]
    TM["TickManager"]
    BC["BattleCore"]
    TC["TownCore"]
    EC["EconomyCore"]
    RC["ResourceCore"]
    BR["BuildingRegistry"]
    HC["HeroCore"]
    SC["SpellCore"]
    MMS["MapMarkerService"]
    STC["StageCore"]
  end

  subgraph UI["UI Layer"]
    MUI["MainUI"]
    WTB["WaveTimerBar"]
    WRM["WaveRewardMenu"]
    PRM["ProphecyMenu"]
    ENM["EncounterMenu"]
    SPP["SpellPanel"]
    SPS["SpellSlot"]
    DBG["DebugSpawnMenu"]
    BLM["BuildingMenu"]

    MUI --> WTB
    MUI --> WRM
    MUI --> PRM
    MUI --> ENM
    MUI --> SPP
    SPP --> SPS
    MUI --> DBG
    MUI --> BLM
  end

  subgraph SPELL["Spells"]
    SPCFG["SpellConfig.gd"]
    MCFG["meteorite.tres"]
    SFX["SpellEffect.gd (base)"]
    FBFX["FireballEffect.gd (meteorite runtime)"]
    FBSC["FireballEffect.tscn"]
    EX2["assets/effects/Explosion2/*"]

    MCFG --> SPCFG
    MCFG --> FBSC
    FBSC --> FBFX
    FBFX -.extends.-> SFX
    FBFX --> EX2
  end

  subgraph COMBAT["Combat Entities"]
    HREG["HeroSceneRegistry.gd"]
    HOF["HeroOnField.gd"]
    HCB["HeroCombat.gd"]
    PRJ["Projectile.gd / Projectile.tscn"]
    MOB["Mob.gd"]
    WALL["Wall.gd"]
    HST["hero_states/*"]
    MST["mob_states/*"]

    HREG --> HOF
    HOF --> HST
    MOB --> MST
    HOF --> HCB --> PRJ
  end

  subgraph FLOW["Waves / Prophecy / Encounters"]
    WGEN["Wave generation"]
    PGEN["ProphecyWaveGenerator"]
    EDEF["EncounterDefs.gd"]
    ESVC["EncounterService.gd"]

    GSW --> WGEN --> MOB
    WRM --> PRM --> ENM
    PRM --> PGEN
    ENM --> ESVC --> EDEF
  end

  subgraph TOWN["Town / Economy / Buildings"]
    MS["MapSlot.gd"]
    BTIP["BuildingsTooltip / Details"]
    TCN["Town systems"]

    BLM --> BR
    MS --> TC
    BR --> TC
    TC --> RC
    TC --> EC
    BTIP --> BR
    TCN --> TC
  end

  subgraph TESTS["Regression Tests"]
    T_MET["test_meteorite_travel_and_impact"]
    T_SH["test_shields_up_effect"]
    T_INF["test_summon_infernals_spawn_flow"]
    T_ICON["test_spell_slot_uses_resolved_icon"]

    T_MET --> FBFX
    T_SH --> SFX
    T_INF --> SFX
    T_ICON --> SPCFG
  end

  GSI --> EB
  GSW --> TM
  GSW --> MMS
  GST --> STC
  GSH --> HC
  GSP --> SC
  GSP --> FBFX
  SPP -- cast --> GSP
  DBG -- add spell --> SPP
  ESVC -- spell_add --> SPP
  ESVC -- fallback --> SC
  GS --> BC
```
