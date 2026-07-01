# Implementation Plan: Унификация ресурса мяса между сценами

**Branch**: `021-meat-resource-unification` | **Date**: 2025-01-XX | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/021-meat-resource-unification/spec.md`

## Summary

Унифицировать ресурс мяса между сценами города, боя и охоты. Создать систему пассивного прироста мяса от охотничьих палаток, которая автоматически останавливается при входе на сцену охоты и возобновляется при выходе. Реализовать систему сохранения/загрузки состояния сцены охоты с визуальным восстановлением "театра" юнитов. Все UI должны читать единый глобальный ресурс мяса из `TownCore`.

## Technical Context

**Language/Version**: GDScript (Godot 4.3)  
**Primary Dependencies**: Godot Engine 4.3, существующие автолоады (TownCore, HuntingCore, EconomyCore, SaveCore, EventBus)  
**Storage**: JSON save file через `SaveCore`, добавление блока `hunting_state`  
**Testing**: Manual gameplay testing, проверка переключения между сценами, сохранение/загрузка  
**Target Platform**: Godot 4.3 (Windows/Linux/Mac)  
**Project Type**: Existing game project (clickcer)  
**Performance Goals**: 60 FPS stable, плавное переключение между сценами (<200ms), восстановление театра без лагов  
**Constraints**: Не изменять баланс (2.2 мяса/мин/рабочий), не добавлять визуальные эффекты доставки мяса  
**Scale/Scope**: 1 новый автолоад (MeatProductionCore), модификация HuntingCore, новый компонент HuntingSceneTheatre, обновление UI компонентов, интеграция с SaveCore

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Compliance Review

✅ **Documentation Hierarchy**: Spec structure follows project pattern (`specs/021-meat-resource-unification/`)

✅ **Godot 4.3 Strict Typing**: All GDScript code will use strict typing (`var food: float`, `var is_on_hunting_scene: bool`)

✅ **Code Style & Formatting**: Code will follow Godot 4.3 GDScript style guide (4-space indentation, snake_case)

✅ **Debug Logging System**: Debug prints will use consistent format `[ClassName] message` for key events

✅ **Autoload Architecture**: New autoload `MeatProductionCore` follows existing pattern (extends Node, no class_name)

✅ **Save/Load System**: Integration with existing `SaveCore` using `get_save_data()` / `load_save_data()` pattern

✅ **EventBus Integration**: Use existing EventBus for signals where appropriate, or direct method calls for scene transitions

✅ **Resource Management**: Meat resource stored in `TownCore._food`, accessed via `TownCore.get_food()` / `TownCore.add_food()`

---

## Phase 0: Research & Analysis

**Status**: ✅ Complete (based on spec clarifications)

**Key Findings**:
- Мясо уже хранится в `TownCore._food` и доступно через `TownCore.get_food()`
- `HuntingCore.deliver_meat()` уже вызывает `EconomyCore.add_food()`, который перенаправляет в `TownCore.add_food()`
- В `HuntingCore` есть константа `MEAT_PER_HUNTER_PER_MINUTE: float = 2.2` для офлайн-прогресса
- `TownCore.get_building_workers("hunting_tents")` возвращает массив назначенных рабочих
- `SaveCore` уже имеет структуру для сохранения данных от разных модулей
- UI города (MainUI) уже читает `TownCore.get_food()` через сигнал `food_changed`
- Нужно найти и обновить UI сцены охоты, если там есть локальный счётчик мяса

**Architecture Decisions**:
1. Создать отдельный автолоад `MeatProductionCore` для управления пассивным приростом
2. `HuntingSceneTheatre` может быть частью `HuntingCore` или отдельным компонентом (решение: часть `HuntingCore`)
3. Использовать сигналы `_ready()` / `_exit_tree()` для определения входа/выхода со сцены
4. Сохранять состояние `hunting_state` в `SaveCore` через `HuntingCore.get_save_data()`

**Dependencies Identified**:
- `TownCore` — хранение ресурса мяса, получение количества рабочих
- `HuntingCore` — управление сценой охоты, доставка мяса
- `SaveCore` — сохранение/загрузка состояния
- `EventBus` — опционально для сигналов (можно использовать прямые вызовы методов)

---

## Phase 1: Design & Architecture

**Status**: ✅ Complete (spec provides detailed API and data model)

### Data Model

**MeatProductionCore State**:
```gdscript
var _hunting_passive_enabled: bool = true  # включён ли пассив охоты
const MEAT_PER_WORKER_PER_MINUTE: float = 2.2
```

**HuntingCore State (расширение)**:
```gdscript
var hunting_state: Dictionary = {
    "is_on_hunting_scene": false,
    "last_seen_timestamp": 0,
    "snapshot_units": []
}
```

**HuntingSceneTheatre Snapshot Structure**:
```gdscript
Array[Dictionary] = [
    {
        "id": "sheep_1",
        "kind": "sheep",
        "pos": Vector2(100, 200),
        "velocity": Vector2(10, 5),
        "state": "WALK",
        "target_id": null,
        "anim_phase": 0.5
    },
    # ...
]
```

### API Contracts

**MeatProductionCore**:
- `set_hunting_passive_enabled(enabled: bool) -> void`
- `get_passive_meat_per_minute() -> float`
- `_process(delta: float) -> void` (private)
- `get_save_data() -> Dictionary`
- `load_save_data(data: Dictionary) -> void`

**HuntingCore (расширение)**:
- `on_enter_scene() -> void` (вызывается из `_ready()` сцены)
- `on_exit_scene() -> void` (вызывается из `_exit_tree()` сцены)
- `save_scene_snapshot() -> Dictionary` (уже существует, расширить)
- `restore_scene_snapshot(dt_seconds: float) -> void` (новый метод)
- `get_save_data() -> Dictionary` (расширить для `hunting_state`)
- `load_save_data(data: Dictionary) -> void` (расширить для `hunting_state`)

**HuntingSceneTheatre (новый компонент в HuntingCore)**:
- `save_snapshot() -> Dictionary`
- `restore_snapshot(dt_seconds: float) -> void`

### Integration Points

1. **MeatProductionCore → TownCore**: Вызов `TownCore.add_food(delta * meat_per_sec)` в `_process()`
2. **HuntingCore → MeatProductionCore**: Вызов `set_hunting_passive_enabled()` при входе/выходе
3. **HuntingCore → SaveCore**: Сохранение `hunting_state` через `get_save_data()`
4. **UI → TownCore**: Чтение `TownCore.get_food()` вместо локальных переменных
5. **SaveCore → HuntingCore**: Загрузка `hunting_state` через `load_save_data()`

---

## Phase 2: Implementation Planning

**Status**: Ready for `/speckit.tasks` command

**Implementation Phases**:

1. **Foundation** (MeatProductionCore)
   - Создать автолоад `MeatProductionCore`
   - Реализовать пассивный прирост мяса
   - Интегрировать с `TownCore`
   - Добавить сохранение/загрузку состояния

2. **Scene State Management** (HuntingCore расширение)
   - Добавить методы `on_enter_scene()` / `on_exit_scene()`
   - Интегрировать с `MeatProductionCore`
   - Добавить сохранение/загрузку `hunting_state`

3. **Scene Theatre** (HuntingSceneTheatre)
   - Реализовать `save_snapshot()` для юнитов
   - Реализовать `restore_snapshot(dt)` с логикой диапазонов времени
   - Интегрировать с `HuntingCore`

4. **UI Updates**
   - Найти и обновить UI сцены охоты (если есть локальный счётчик)
   - Убедиться, что все UI читают `TownCore.get_food()`
   - Проверить UI города и боя (уже должны быть корректными)

5. **Save/Load Integration**
   - Расширить `SaveCore` для сохранения `hunting_state`
   - Реализовать восстановление состояния при загрузке
   - Обработать случай загрузки на сцене охоты

6. **Testing & Validation**
   - Тестирование пассивного прироста
   - Тестирование переключения между сценами
   - Тестирование сохранения/загрузки
   - Тестирование театра (визуальное восстановление)

**Next Steps**:
1. Break plan into implementation tasks using `/speckit.tasks`
2. Create task breakdown for each phase
3. Identify parallel execution opportunities

**Artifacts Generated**:
- ✅ `spec.md` - Complete with clarifications
- ⏳ `plan.md` - Phase 2 (this document)
- ⏳ `tasks.md` - Phase 2 (pending `/speckit.tasks` command)

---

## Implementation Order

**Recommended sequence**:

1. **Foundation** (MeatProductionCore)
   - Создать автолоад `MeatProductionCore`
   - Реализовать базовую логику пассивного прироста
   - Интегрировать с `TownCore`
   - Добавить в Project Settings → Autoload

2. **Scene State Management** (HuntingCore)
   - Добавить `hunting_state` в `HuntingCore`
   - Реализовать `on_enter_scene()` / `on_exit_scene()`
   - Интегрировать с `MeatProductionCore`
   - Добавить сохранение/загрузку `hunting_state`

3. **Scene Integration** (Hunting Scene)
   - Найти сцену охоты и добавить вызовы `on_enter_scene()` / `on_exit_scene()`
   - Убедиться, что `deliver_meat()` уже корректно работает

4. **Scene Theatre** (HuntingSceneTheatre)
   - Реализовать `save_snapshot()` для юнитов
   - Реализовать `restore_snapshot(dt)` с логикой диапазонов
   - Интегрировать с `HuntingCore`

5. **UI Updates**
   - Найти UI сцены охоты и обновить для чтения `TownCore.get_food()`
   - Проверить UI города и боя (должны быть корректными)

6. **Save/Load Integration**
   - Расширить `SaveCore` для `hunting_state`
   - Реализовать восстановление при загрузке
   - Обработать случай загрузки на сцене охоты

7. **Testing**
   - Тестирование всех сценариев из spec
   - Проверка edge cases (нет рабочих, быстрое переключение сцен)

---

## Risk Assessment

**Low Risk**:
- Создание `MeatProductionCore` (простой автолоад)
- Интеграция с `TownCore` (API уже существует)
- Обновление UI (чтение из `TownCore.get_food()`)

**Medium Risk**:
- Реализация `HuntingSceneTheatre.restore_snapshot()` с логикой диапазонов времени
- Интеграция сохранения/загрузки `hunting_state` в `SaveCore`
- Обработка случая загрузки на сцене охоты

**Mitigation**:
- Начать с простой реализации театра (замороженный кадр), затем добавить диапазоны
- Тщательно протестировать сохранение/загрузку на разных сценах
- Добавить debug логирование для отслеживания состояния

---

## Success Criteria

✅ **Functional**:
- Пассивный прирост мяса работает, когда игрок не на сцене охоты
- Пассивный прирост останавливается при входе на сцену охоты
- Пассивный прирост возобновляется при выходе со сцены охоты
- Все UI показывают одинаковое значение мяса из `TownCore.get_food()`
- Доставки мяса на сцене охоты добавляются в глобальный ресурс
- Сохранение/загрузка корректно обрабатывает состояние сцены охоты
- Театр восстанавливает юнитов с учётом прошедшего времени

✅ **Technical**:
- `MeatProductionCore` создан и работает как автолоад
- `HuntingCore` корректно управляет состоянием сцены
- `HuntingSceneTheatre` корректно сохраняет/восстанавливает снапшоты
- Интеграция с `SaveCore` работает без ошибок
- Нет утечек памяти при переключении сцен

✅ **Quality**:
- Код следует стилю проекта (Godot 4.3, strict typing)
- Debug логирование присутствует для ключевых событий
- Edge cases обработаны (нет рабочих, быстрые переключения)

---

## Out of Scope

- Изменение баланса (2.2 мяса/мин/рабочий)
- Визуальные эффекты доставки мяса
- Оптимизация производительности
- Счётчик "+X за эту сессию на полях" в UI (TODO для будущего)

