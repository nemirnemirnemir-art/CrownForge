# Implementation Plan: Mine Field Scene - Living Location with Workers

**Branch**: `022-mine-field` | **Date**: 2025-12-04 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/022-mine-field/spec.md`

## Summary

Создать сцену шахты как отдельную «живую» локацию, по логике схожую с охотничьими полями / фермой. Реализовать три типа рабочих (шахтёры, носильщики, тележечники), систему добычи осколков, апгрейды шахты, онлайн/оффлайн симуляцию и интеграцию с существующими системами (EconomyCore, TownCore, SaveCore). Осколки используют существующий ресурс `forge_cores` из `EconomyCore`.

## Technical Context

**Language/Version**: GDScript (Godot 4.3)  
**Primary Dependencies**: Godot Engine 4.3, существующие автолоады (EconomyCore, TownCore, SaveCore, EventBus)  
**Storage**: JSON save file через `SaveCore`, добавление блока `mine_state`  
**Testing**: Manual gameplay testing, проверка переключения между сценами, сохранение/загрузка, производительность с 200 осколками  
**Target Platform**: Godot 4.3 (Windows/Linux/Mac)  
**Project Type**: Existing game project (clickcer)  
**Performance Goals**: 60 FPS stable с 200 осколками на сцене, плавное переключение между сценами (<200ms), поддержка до 10+ рабочих каждого типа  
**Constraints**: Использовать существующую систему движения (как на ферме/охоте), переиспользовать `forge_cores` из EconomyCore  
**Scale/Scope**: 1 новый автолоад (MineCore с модулями), новая сцена MineField, 3 типа рабочих (шахтёр, носильщик, тележечник), система апгрейдов, интеграция с UI города

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Compliance Review

✅ **Documentation Hierarchy**: Spec structure follows project pattern (`specs/022-mine-field/`)

✅ **Godot 4.3 Strict Typing**: All GDScript code will use strict typing (`var miners_count: int`, `var is_on_mine_scene: bool`)

✅ **Code Style & Formatting**: Code will follow Godot 4.3 GDScript style guide (4-space indentation, snake_case)

✅ **Debug Logging System**: Debug prints will use consistent format `[MineCore] message` for key events

✅ **Autoload Architecture**: New autoload `MineCore` follows existing pattern (extends Node, modular structure like HuntingCore)

✅ **Save/Load System**: Integration with existing `SaveCore` using `get_save_data()` / `load_save_data()` pattern

✅ **EventBus Integration**: Use existing EventBus for signals where appropriate, or direct method calls for scene transitions

✅ **Resource Management**: Shards use existing `forge_cores` from `EconomyCore`, accessed via `EconomyCore.get_forge_cores()` / `EconomyCore.add_forge_cores()`

**Result**: ✅ **PASS** - All constitution principles satisfied. Architecture follows established patterns from HuntingCore.

---

## Phase 0: Research & Analysis

**Status**: ✅ Complete (based on spec clarifications)

**Key Findings**:
- `HuntingCore` использует модульную архитектуру с отдельными классами (HuntingRegistry, HuntingMeatDelivery, HuntingOfflineProgress, etc.)
- `EconomyCore` уже имеет методы `get_forge_cores()` и `add_forge_cores(amount)`
- `TownCore` управляет населением и рабочими через `get_building_workers()`
- `SaveCore` имеет структуру для сохранения данных от разных модулей
- Система движения на ферме/охоте использует простую логику без NavMesh
- Механика выпадения мяса с овцы может быть переиспользована для осколков

**Architecture Decisions**:
1. Создать `MineCore` как автолоад синглтон с модульной структурой (аналогично HuntingCore)
2. Модули MineCore:
   - `MineRegistry` - регистрация рабочих и пород
   - `MineShardDelivery` - доставка осколков (аналог HuntingMeatDelivery)
   - `MineOfflineProgress` - оффлайн-симуляция
   - `MineSceneSnapshot` - снапшот сцены для сохранения
   - `MineSceneState` - состояние сцены (is_on_mine_scene, timestamp)
   - `MineScenePersistence` - сохранение/восстановление снапшота
   - `MineSaveLoad` - интеграция с SaveCore
3. Использовать существующую систему движения из фермы/охоты
4. Переиспользовать механику выпадения мяса для осколков (заменить спрайт/ресурс)

**Dependencies Identified**:
- `EconomyCore` — хранение forge_cores, добавление осколков
- `TownCore` — управление населением, проверка доступных рабочих
- `SaveCore` — сохранение/загрузка состояния шахты
- `EventBus` — опционально для сигналов (можно использовать прямые вызовы методов)
- Существующие сцены фермы/охоты — для понимания структуры движения и UI

---

## Phase 1: Design & Architecture

**Status**: ✅ Complete (spec provides detailed API and data model)

### Data Model

**MineCore State**:
```gdscript
# Workers
var miners_count: int = 0
var carriers_count: int = 0
var carts_count: int = 0

# Upgrades
var powerful_pickaxe_level: int = 0  # 0-5
var sturdy_cart_level: int = 0       # 0-6
var comfortable_boots_level: int = 0 # 0-10

# Scene state
var is_on_mine_scene: bool = false
```

**MineSceneState Structure**:
```gdscript
var mine_state: Dictionary = {
    "is_on_mine_scene": false,
    "last_seen_timestamp": 0,
    "snapshot_units": []
}
```

**MineSceneSnapshot Structure**:
```gdscript
Array[Dictionary] = [
    {
        "id": "miner_1",
        "type": "miner",
        "pos": Vector2(100, 200),
        "state": "mine_hits",
        "ore_id": "ore_1",
        "slot_index": 0
    },
    {
        "id": "carrier_1",
        "type": "carrier",
        "pos": Vector2(150, 250),
        "state": "carry_to_cart",
        "target_id": "cart_1"
    },
    {
        "id": "cart_1",
        "type": "cart",
        "pos": Vector2(200, 300),
        "state": "idle_near_ore",
        "load": 3,
        "capacity": 6,
        "ore_id": "ore_2"
    }
]
```

**Ore Data Structure**:
```gdscript
var ore_data: Dictionary = {
    "id": "ore_1",
    "position": Vector2(100, 100),
    "work_radius": 32.0,
    "slots": [
        {"position": Vector2(100, 68), "occupied_by": null},
        {"position": Vector2(132, 100), "occupied_by": null},
        {"position": Vector2(100, 132), "occupied_by": null},
        {"position": Vector2(68, 100), "occupied_by": null}
    ]
}
```

### Module Structure

**MineCore** (main autoload):
- Координирует все модули
- Публичный API для сцены и UI
- Методы `start_tracking()`, `stop_tracking()`

**MineRegistry**:
- Регистрация пород (4 фиксированные точки)
- Регистрация рабочих (шахтёры, носильщики, тележечники)
- Управление слотами пород

**MineShardDelivery**:
- Отслеживание доставки осколков
- Статистика "за сессию" / "за минуту"
- Вызов `EconomyCore.add_forge_cores()` при выгрузке тележек

**MineOfflineProgress**:
- Расчёт оффлайн-прогресса (формулы на основе рабочих, апгрейдов)
- Сохранение состояния для расчёта
- Вычисление forge_cores за время отсутствия

**MineSceneSnapshot**:
- Сохранение снапшота сцены (позиции, состояния рабочих)
- Восстановление снапшота при загрузке

**MineSceneState**:
- Управление флагом `is_on_mine_scene`
- Хранение timestamp последнего выхода
- Управление состоянием сцены

**MineScenePersistence**:
- Сохранение снапшота для состояния
- Восстановление снапшота с учётом времени (dt)

**MineSaveLoad**:
- Интеграция с SaveCore
- Сохранение/загрузка состояния шахты

### Scene Structure

**MineField.tscn** (main scene):
- Node2D root
- Background layer
- WorldYSort для правильного отображения
- OreContainer (4 породы)
- WorkersContainer (шахтёры, носильщики, тележечники)
- ShardsContainer (осколки на земле)
- UI layer (forge_cores display, statistics, limit message)

**Ore.tscn** (порода):
- StaticBody2D или Area2D
- Sprite2D (PNG 128×128)
- 4 Marker2D для слотов (по кругу, ~32px от центра)

**Miner.tscn** (шахтёр):
- CharacterBody2D или Area2D
- Sprite2D (placeholder)
- State machine: rest_after_work → scan_for_ore → move_to_ore_slot → mine_hits

**Carrier.tscn** (носильщик):
- CharacterBody2D или Area2D
- Sprite2D (placeholder)
- State machine: rest_after_work → scan_for_stones → move_to_stone → carry_to_cart_or_warehouse

**Cart.tscn** (тележка):
- CharacterBody2D или Area2D
- Sprite2D (placeholder)
- State machine: move_to_ore → idle_near_ore → move_to_warehouse → unload

**Shard.tscn** (осколок):
- Area2D
- Sprite2D (чёрный кирпич PNG, placeholder)
- CollisionShape2D для подбора

### API Design

**MineCore Public API**:
```gdscript
# Workers management
func set_miners_count(count: int) -> bool
func set_carriers_count(count: int) -> bool
func set_carts_count(count: int) -> bool
func get_max_workers_for_level(mine_level: int) -> Dictionary  # Returns {miners, carriers, carts}

# Upgrades
func upgrade_powerful_pickaxe() -> bool
func upgrade_sturdy_cart() -> bool
func upgrade_comfortable_boots() -> bool
func get_upgrade_levels() -> Dictionary

# Scene tracking
func start_tracking() -> void
func stop_tracking() -> void
func is_on_scene() -> bool

# Shard delivery
func deliver_shards(amount: int) -> void
func get_shards_per_minute() -> float
func get_total_shards_delivered() -> int

# Save/Load
func get_save_data() -> Dictionary
func load_save_data(data: Dictionary) -> void
```

---

## Phase 2: Implementation Phases

### Phase 2.1: Core Infrastructure (MineCore + Modules)

**Goal**: Создать MineCore автолоад и базовые модули

**Tasks**:
1. Создать `core/mine/MineCore.gd` (автолоад синглтон)
2. Создать модули:
   - `core/mine/MineRegistry.gd`
   - `core/mine/MineShardDelivery.gd`
   - `core/mine/MineOfflineProgress.gd`
   - `core/mine/MineSceneSnapshot.gd`
   - `core/mine/MineSceneState.gd`
   - `core/mine/MineScenePersistence.gd`
   - `core/mine/MineSaveLoad.gd`
3. Добавить MineCore в Project Settings → Autoload
4. Реализовать базовую инициализацию модулей

**Dependencies**: None (foundation)

### Phase 2.2: Workers Management & UI Integration

**Goal**: Реализовать управление рабочими и UI в городе

**Tasks**:
1. Реализовать логику расчёта слотов рабочих по уровню шахты (FR-055, FR-056)
2. Реализовать методы `set_miners_count()`, `set_carriers_count()`, `set_carts_count()` с проверкой населения через TownCore
3. Интегрировать UI в здание шахты (3 строки со счётчиками [+ / −])
4. Синхронизация с TownCore для управления населением

**Dependencies**: Phase 2.1, TownCore

### Phase 2.3: Upgrades System

**Goal**: Реализовать систему апгрейдов шахты

**Tasks**:
1. Реализовать хранение уровней апгрейдов в MineCore
2. Реализовать логику разблокировки апгрейдов по уровню шахты
3. Реализовать методы применения апгрейдов:
   - `powerful_pickaxe_level` → шанс второго осколка
   - `sturdy_cart_level` → увеличение capacity тележки
   - `comfortable_boots_level` → увеличение скорости носильщика
4. UI для апгрейдов (опционально, может быть в следующей итерации)

**Dependencies**: Phase 2.1

### Phase 2.4: Scene Structure & Ores

**Goal**: Создать базовую структуру сцены и породы

**Tasks**:
1. Создать сцену `scenes/mine/MineField.tscn`
2. Создать сцену `scenes/mine/Ore.tscn` с 4 слотами
3. Разместить 4 породы в редакторе
4. Реализовать логику слотов пород (FR-012, FR-013)
5. Реализовать регистрацию пород в MineRegistry

**Dependencies**: Phase 2.1

### Phase 2.5: Miner Implementation

**Goal**: Реализовать логику шахтёра

**Tasks**:
1. Создать сцену `scenes/mine/Miner.tscn`
2. Реализовать state machine: rest_after_work → scan_for_ore → move_to_ore_slot → mine_hits
3. Реализовать логику выбора породы и слота (FR-022, FR-023)
4. Реализовать логику ударов (FR-024, FR-025, FR-026, FR-027)
5. Интеграция с апгрейдом "Мощная кирка" (FR-068)

**Dependencies**: Phase 2.4, Phase 2.3

### Phase 2.6: Shard System

**Goal**: Реализовать систему осколков

**Tasks**:
1. Создать сцену `scenes/mine/Shard.tscn`
2. Реализовать механику выпадения осколков (переиспользовать логику мяса)
3. Реализовать лимит 200 осколков на сцене (FR-018, FR-019)
4. Реализовать UI сообщение при лимите (FR-088)
5. Реализовать резервирование осколков для носильщиков (FR-032)

**Dependencies**: Phase 2.5

### Phase 2.7: Carrier Implementation

**Goal**: Реализовать логику носильщика

**Tasks**:
1. Создать сцену `scenes/mine/Carrier.tscn`
2. Реализовать state machine: rest_after_work → scan_for_stones → move_to_stone → carry_to_cart_or_warehouse
3. Реализовать логику поиска осколков (FR-031, FR-032)
4. Реализовать логику доставки к тележке или складу (FR-040, FR-041, FR-042)
5. Интеграция с апгрейдом "Удобные ботинки" (FR-078)

**Dependencies**: Phase 2.6, Phase 2.3

### Phase 2.8: Cart Implementation

**Goal**: Реализовать логику тележечника

**Tasks**:
1. Создать сцену `scenes/mine/Cart.tscn`
2. Реализовать state machine: move_to_ore → idle_near_ore → move_to_warehouse → unload
3. Реализовать логику накопления load от носильщиков (FR-049, FR-050, FR-051)
4. Реализовать логику выгрузки в forge_cores через EconomyCore (FR-053)
5. Интеграция с апгрейдом "Бодрая тележка" (FR-072)

**Dependencies**: Phase 2.7, Phase 2.3

### Phase 2.9: Online/Offline System

**Goal**: Реализовать онлайн/оффлайн симуляцию

**Tasks**:
1. Реализовать `start_tracking()` / `stop_tracking()` в MineCore
2. Реализовать определение состояния сцены через `_ready()` / `_exit_tree()`
3. Реализовать оффлайн-расчёт в MineOfflineProgress (формулы на основе рабочих, апгрейдов)
4. Реализовать вычисление оффлайн-прогресса при входе на сцену (FR-084)
5. Интеграция с MineSceneState для хранения timestamp

**Dependencies**: Phase 2.1, Phase 2.2, Phase 2.3

### Phase 2.10: Save/Load System

**Goal**: Реализовать сохранение/загрузку состояния шахты

**Tasks**:
1. Реализовать `get_save_data()` в MineSaveLoad
2. Реализовать `load_save_data()` в MineSaveLoad
3. Интеграция с SaveCore
4. Реализовать сохранение снапшота сцены (MineSceneSnapshot)
5. Реализовать восстановление снапшота при загрузке с учётом времени (MineScenePersistence)

**Dependencies**: Phase 2.9, SaveCore

### Phase 2.11: UI Integration

**Goal**: Реализовать UI сцены шахты

**Tasks**:
1. Реализовать отображение forge_cores (из EconomyCore.get_forge_cores())
2. Реализовать статистику "за сессию" / "за минуту" (MineShardDelivery)
3. Опционально: отображение числа осколков на земле, числа в тележках
4. Реализовать сообщение при лимите осколков (FR-088)

**Dependencies**: Phase 2.6, Phase 2.9

### Phase 2.12: Scene Integration & Navigation

**Goal**: Интегрировать сцену шахты в систему навигации

**Tasks**:
1. Добавить вход из town (клик по зданию "Шахта")
2. Добавить вход из главного меню
3. Реализовать возврат туда же, откуда пришли (FR-003)
4. Вызов `MineCore.start_tracking()` в `_ready()` сцены
5. Вызов `MineCore.stop_tracking()` в `_exit_tree()` сцены

**Dependencies**: Phase 2.9, существующая система навигации

---

## Complexity Tracking

> **Moderate complexity** - Модульная архитектура (как HuntingCore) упрощает поддержку. Основная сложность в координации трёх типов рабочих и их состояний. Система апгрейдов и онлайн/оффлайн логика требуют тщательной интеграции.

---

## Testing Strategy

1. **Unit Tests**: Методы расчёта слотов рабочих, формул апгрейдов, оффлайн-прогресса
2. **Integration Tests**: Интеграция с EconomyCore, TownCore, SaveCore
3. **Performance Tests**: Проверка производительности с 200 осколками, 10+ рабочими каждого типа
4. **Gameplay Tests**: Полный цикл работы шахты, сохранение/загрузка, переключение между сценами

---

## Risk Assessment

**High Risk**:
- Производительность с 200 осколками на сцене (может потребоваться оптимизация)
- Координация трёх типов рабочих (может быть сложно отладить)

**Medium Risk**:
- Интеграция с существующими системами (EconomyCore, TownCore)
- Оффлайн-расчёт (нужно правильно рассчитать формулы)

**Low Risk**:
- Структура сцены (аналогична ферме/охоте)
- Система апгрейдов (простая логика)

---

## Next Steps

После завершения Phase 2, рекомендуется:
1. Создать tasks.md с детальными задачами
2. Создать quickstart.md для быстрого старта разработки
3. Создать data-model.md с детальной структурой данных
4. Опционально: создать contracts/ для API контрактов

