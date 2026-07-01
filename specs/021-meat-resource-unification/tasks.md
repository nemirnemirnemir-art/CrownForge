# Implementation Tasks: Унификация ресурса мяса между сценами

**Feature**: 021-meat-resource-unification  
**Branch**: `021-meat-resource-unification`  
**Created**: 2025-01-XX  
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Overview

Унифицировать ресурс мяса между сценами города, боя и охоты. Создать систему пассивного прироста мяса от охотничьих палаток, которая автоматически останавливается при входе на сцену охоты и возобновляется при выходе. Реализовать систему сохранения/загрузки состояния сцены охоты с визуальным восстановлением "театра" юнитов. Все UI должны читать единый глобальный ресурс мяса из `TownCore`.

**Total Tasks**: 42  
**MVP Scope**: All tasks (complete implementation)

---

## Dependencies

### Implementation Order

1. **Foundation** (MeatProductionCore) → **No dependencies** (новый автолоад)
2. **Scene State Management** (HuntingCore) → **Depends on**: Foundation (нужен MeatProductionCore)
3. **Scene Integration** (Hunting Scene) → **Depends on**: Scene State Management
4. **Scene Theatre** (HuntingSceneTheatre) → **Depends on**: Scene State Management
5. **UI Updates** → **Depends on**: Foundation (можно частично параллельно)
6. **Save/Load Integration** → **Depends on**: Scene State Management, Scene Theatre
7. **Testing** → **Depends on**: All previous phases

### Parallel Execution Opportunities

- **UI Updates** могут быть выполнены параллельно с Scene Theatre (разные файлы)
- **Save/Load Integration** частично может быть выполнено параллельно с UI Updates

---

## Phase 1: Foundation - MeatProductionCore

**Goal**: Создать автолоад для управления пассивным приростом мяса

**Independent Test**: MeatProductionCore доступен как автолоад, пассивный прирост работает когда включён

- [ ] T001 Create `core/meat_production_core.gd` file with basic class structure (extends Node, no class_name)
- [ ] T002 Add MeatProductionCore as autoload singleton in Project Settings → Autoload (name: "MeatProductionCore", path: "res://core/meat_production_core.gd")
- [ ] T003 Add state variables to MeatProductionCore: `var _hunting_passive_enabled: bool = true`
- [ ] T004 Add constant to MeatProductionCore: `const MEAT_PER_WORKER_PER_MINUTE: float = 2.2`
- [ ] T005 Implement `set_hunting_passive_enabled(enabled: bool) -> void` in MeatProductionCore with debug logging `[MeatProductionCore] Hunting passive enabled: %s` % enabled
- [ ] T006 Implement `get_passive_meat_per_minute() -> float` in MeatProductionCore that returns 0 if `_hunting_passive_enabled == false` or `workers_count == 0`, otherwise `workers_count * MEAT_PER_WORKER_PER_MINUTE`
- [ ] T007 Implement `_process(delta: float) -> void` in MeatProductionCore that calculates meat production and calls `TownCore.add_food()` only if `_hunting_passive_enabled == true` and `workers_count > 0`
- [ ] T008 In `_process()`, get workers count from `TownCore.get_building_workers("hunting_tents")` and calculate `meat_per_sec = (workers_count * MEAT_PER_WORKER_PER_MINUTE) / 60.0`
- [ ] T009 In `_process()`, call `TownCore.add_food(delta * meat_per_sec)` when conditions are met
- [ ] T010 Implement `get_save_data() -> Dictionary` in MeatProductionCore returning `{"hunting_passive_enabled": _hunting_passive_enabled}`
- [ ] T011 Implement `load_save_data(data: Dictionary) -> void` in MeatProductionCore to restore `_hunting_passive_enabled` from save data

**Checkpoint**: MeatProductionCore создан, пассивный прирост работает при включённом состоянии

---

## Phase 2: Scene State Management - HuntingCore Extension

**Goal**: Добавить управление состоянием сцены охоты в HuntingCore

**Independent Test**: Методы `on_enter_scene()` и `on_exit_scene()` корректно вызываются и управляют MeatProductionCore

- [ ] T012 Add `hunting_state: Dictionary` to HuntingCore in `core/hunting_core.gd` with initial values: `{"is_on_hunting_scene": false, "last_seen_timestamp": 0, "snapshot_units": []}`
- [ ] T013 Implement `on_enter_scene() -> void` in HuntingCore that sets `hunting_state.is_on_hunting_scene = true` and updates `hunting_state.last_seen_timestamp = Time.get_unix_time_from_system()`
- [ ] T014 In `on_enter_scene()`, call `MeatProductionCore.set_hunting_passive_enabled(false)` with debug logging `[HuntingCore] Entered hunting scene, passive disabled`
- [ ] T015 In `on_enter_scene()`, calculate `dt = max(0.0, float(Time.get_unix_time_from_system() - hunting_state.last_seen_timestamp))` for theatre restoration
- [ ] T016 In `on_enter_scene()`, call `restore_scene_snapshot(dt)` (will be implemented in Phase 4, for now add placeholder)
- [ ] T017 Implement `on_exit_scene() -> void` in HuntingCore that sets `hunting_state.is_on_hunting_scene = false` and updates `hunting_state.last_seen_timestamp = Time.get_unix_time_from_system()`
- [ ] T018 In `on_exit_scene()`, call `save_scene_snapshot()` (will be implemented in Phase 4, for now add placeholder)
- [ ] T019 In `on_exit_scene()`, call `MeatProductionCore.set_hunting_passive_enabled(true)` with debug logging `[HuntingCore] Exited hunting scene, passive enabled`
- [ ] T020 Extend `get_save_data() -> Dictionary` in HuntingCore to include `hunting_state` in returned dictionary
- [ ] T021 Extend `load_save_data(data: Dictionary) -> void` in HuntingCore to restore `hunting_state` from save data, handling missing keys gracefully

**Checkpoint**: HuntingCore управляет состоянием сцены и интегрирован с MeatProductionCore

---

## Phase 3: Scene Integration - Hunting Scene

**Goal**: Интегрировать вызовы методов входа/выхода в сцену охоты

**Independent Test**: При входе/выходе со сцены охоты вызываются соответствующие методы HuntingCore

- [ ] T022 Find hunting scene file (search for scenes with "hunting" in name or check MainUI for hunting button target)
- [ ] T023 Locate script attached to hunting scene root node
- [ ] T024 In hunting scene script `_ready()` method, add call to `HuntingCore.on_enter_scene()` with null check: `if HuntingCore: HuntingCore.on_enter_scene()`
- [ ] T025 In hunting scene script `_exit_tree()` method, add call to `HuntingCore.on_exit_scene()` with null check: `if HuntingCore: HuntingCore.on_exit_scene()`
- [ ] T026 Verify that `HuntingCore.deliver_meat()` already calls `EconomyCore.add_food()` which redirects to `TownCore.add_food()` (should already be correct per spec)

**Checkpoint**: Сцена охоты корректно вызывает методы входа/выхода

---

## Phase 4: Scene Theatre - HuntingSceneTheatre

**Goal**: Реализовать сохранение и восстановление снапшотов юнитов

**Independent Test**: Снапшоты сохраняются и восстанавливаются с учётом прошедшего времени

- [ ] T027 Implement `save_scene_snapshot() -> Dictionary` in HuntingCore that collects state of all units (sheep, hunters, workers) on hunting scene
- [ ] T028 In `save_scene_snapshot()`, iterate through all units and create dictionary entries with: `id`, `kind`, `pos`, `velocity`, `state`, `target_id`, `anim_phase`
- [ ] T029 Store snapshot in `hunting_state.snapshot_units` and return it
- [ ] T030 Implement `restore_scene_snapshot(dt_seconds: float) -> void` in HuntingCore with logic for different time ranges
- [ ] T031 In `restore_scene_snapshot()`, handle `dt <= 5 seconds` case: restore units exactly as saved (frozen frame)
- [ ] T032 In `restore_scene_snapshot()`, handle `5 < dt <= 15 seconds` case: apply soft movement based on saved velocity for sheep, advance hunters towards targets
- [ ] T033 In `restore_scene_snapshot()`, handle `dt > 15 seconds` case: regenerate scene naturally with some units from snapshot and some new ones
- [ ] T034 In `restore_scene_snapshot()`, ensure animations don't start synchronously by using saved `anim_phase` values
- [ ] T035 Update `on_exit_scene()` to call `save_scene_snapshot()` and store result in `hunting_state.snapshot_units`
- [ ] T036 Update `on_enter_scene()` to call `restore_scene_snapshot(dt)` with calculated `dt` value

**Checkpoint**: Театр сохраняет и восстанавливает юнитов с учётом времени

---

## Phase 5: UI Updates

**Goal**: Обновить все UI для чтения глобального ресурса мяса

**Independent Test**: Все UI показывают одинаковое значение мяса из TownCore.get_food()

- [ ] T037 Verify MainUI already reads `TownCore.get_food()` via `food_changed` signal (should be correct, verify in `scripts/MainUI.gd`)
- [ ] T038 Find UI script for hunting scene (search for scripts that display meat/food counter)
- [ ] T039 If hunting scene UI has local meat counter variable, remove it and replace with `TownCore.get_food()` calls
- [ ] T040 Update hunting scene UI to connect to `TownCore.food_changed` signal for automatic updates
- [ ] T041 Verify GameScene (battle scene) UI reads meat from TownCore (check if food is displayed, should already be correct via MainUI)
- [ ] T042 Add debug logging in UI updates: `[HuntingUI] Meat updated: %d` % TownCore.get_food() (if hunting UI exists)

**Checkpoint**: Все UI читают глобальный ресурс мяса

---

## Phase 6: Save/Load Integration

**Goal**: Интегрировать сохранение/загрузку hunting_state в SaveCore

**Independent Test**: Сохранение/загрузка корректно обрабатывает состояние сцены охоты

- [ ] T043 Extend `SaveCore.save_game()` in `core/save_core.gd` to include `hunting` data from `HuntingCore.get_save_data()` if HuntingCore exists
- [ ] T044 Extend `SaveCore.load_save_data()` in `core/save_core.gd` to call `HuntingCore.load_save_data(data.get("hunting", {}))` if HuntingCore exists
- [ ] T045 In SaveCore, also include `meat_production` data from `MeatProductionCore.get_save_data()` if MeatProductionCore exists
- [ ] T046 In SaveCore load, call `MeatProductionCore.load_save_data(data.get("meat_production", {}))` if MeatProductionCore exists
- [ ] T047 Handle case when loading save with `hunting_state.is_on_hunting_scene == true`: ensure passive is disabled and scene is restored correctly
- [ ] T048 Add debug logging in SaveCore: `[SaveCore] Saving hunting state: is_on_scene=%s` % hunting_state.get("is_on_hunting_scene", false)

**Checkpoint**: Сохранение/загрузка корректно работает для hunting_state

---

## Phase 7: Testing & Validation

**Goal**: Протестировать все сценарии из спецификации

**Independent Test**: Все тестовые сценарии из spec.md проходят успешно

- [ ] T049 Test passive meat production: assign workers to hunting tents, verify meat grows in town UI and battle UI, enter hunting scene and verify passive stops
- [ ] T050 Test active meat collection: enter hunting scene, wait for worker to deliver meat, verify meat added to global resource, verify town and battle UI updated
- [ ] T051 Test scene switching: be in town/battle with passive meat growing, enter hunting scene (passive stops), exit hunting scene (passive resumes)
- [ ] T052 Test save/load on hunting scene: save game while on hunting scene, load save, verify passive is disabled, verify units restored from snapshot, verify meat didn't accumulate during offline time
- [ ] T053 Test scene theatre: save game on hunting scene, load after 3 seconds (frozen frame), load after 10 seconds (soft shift), load after 30 seconds (natural scene)
- [ ] T054 Test edge case: no workers assigned to hunting tents, verify passive production = 0
- [ ] T055 Test edge case: rapid scene switching (enter/exit quickly), verify no errors or state corruption
- [ ] T056 Verify all UI show same meat value: check town UI, battle UI, hunting scene UI all display `TownCore.get_food()`

**Checkpoint**: Все тесты пройдены, фича работает корректно

---

## Notes

- **MeatProductionCore** должен быть добавлен в Project Settings → Autoload после создания файла
- **HuntingSceneTheatre** реализуется как часть HuntingCore (не отдельный модуль)
- **Сцена охоты** может иметь другое имя - нужно найти её в процессе реализации (Phase 3)
- **UI сцены охоты** может не существовать или иметь другое имя - нужно найти в процессе реализации (Phase 5)
- Все методы должны иметь null checks для автолоадов перед использованием
- Debug logging должен использовать формат `[ClassName] message` для всех ключевых событий

---

## Completion Checklist

- [ ] All Phase 1 tasks complete (MeatProductionCore)
- [ ] All Phase 2 tasks complete (HuntingCore extension)
- [ ] All Phase 3 tasks complete (Scene integration)
- [ ] All Phase 4 tasks complete (Scene Theatre)
- [ ] All Phase 5 tasks complete (UI Updates)
- [ ] All Phase 6 tasks complete (Save/Load Integration)
- [ ] All Phase 7 tasks complete (Testing)
- [ ] Code follows Godot 4.3 style guide
- [ ] All debug logging uses `[ClassName]` format
- [ ] No linter errors
- [ ] Manual testing completed for all scenarios

