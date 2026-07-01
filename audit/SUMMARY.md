# SUMMARY

## Status

- Completed

## Top risks (draft)

| Путь | Проблема | Серьёзность | Рекомендация |
|------|----------|-------------|--------------|
| `res://scripts/ui/hud/MainUI.gd` | 921 lines (monolith risk: UI + business logic mixed) | 🔴 Critical | Split into sub-controllers / components; keep `MainUI` as thin orchestrator |
| `res://scripts/hero/HeroOnField.gd` | 718 lines (likely mixed movement/AI/combat/state) | 🔴 Critical | Split into focused components (movement/targeting/combat/AI) |
| `res://scripts/map/MapSlot.gd` | 765 lines (slot/building placement logic likely overloaded) | 🔴 Critical | Split into interaction/state/visuals submodules |
| `res://core/skill_core.gd` | 747 lines (global singleton becoming god-object) | 🔴 Critical | Split into catalog/state/effects; keep minimal public API |
| `res://core/town_core.gd` | 602 lines (town system orchestration too wide) | 🔴 Critical | Enforce module architecture consistently |
| `res://scripts/ui/town/SmithCraftPanel.gd` | 674 lines (UI monolith) | 🔴 Critical | Split into sub-panels (recipes list, craft action, inventory view) |
| `res://scripts/ui/town/BuildingsTooltip.gd` | 598 lines (UI formatting + data extraction mixed) | 🔴 Critical | Split into data provider + renderer + layout |
| `res://scripts/ui/debug/DebugSpawnMenu.gd` | 472 lines (debug UI + spawning logic) | 🟡 High | Split debug providers vs commands vs UI |
| `res://scripts/ui/gaze/VzorZone.gd` | 341 lines | 🟡 High | Split zone logic vs visuals/animation |
| `res://scripts/ui/town/TownInventoryPanel.gd` | 353 lines | 🟡 High | Split layout vs behavior; reuse existing helper classes |

## Potential points of failure (draft)

| Путь | Проблема | Серьёзность | Рекомендация |
|------|----------|-------------|--------------|
| `res://scenes/heroes/HeroOnField.tscn` | Сцена ссылается на удалённые скрипты: `res://scripts/hero/states/HeroMovingState.gd` и `res://scripts/hero/states/HeroSimpleAttackState.gd` (эти пути упоминаются в `cleanup_legacy_heroes.bat`, который их удаляет). Если эта сцена будет инстанситься — возможен load error. | 🔴 Critical | Либо обновить сцену на актуальные state scripts (`HeroMovingToCombatState`, `HeroAttackingState`, ...), либо пометить/удалить (после ручной проверки использования). |
