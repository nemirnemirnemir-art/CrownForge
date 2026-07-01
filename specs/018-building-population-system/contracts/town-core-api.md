# TownCore API Contract - Building System Expansion

**Feature**: 018-building-population-system  
**Module**: `core/town_core.gd`  
**Version**: 2.0 (расширение существующего API)

---

## Overview

Расширение TownCore для поддержки новых зданий (Barracks, Training Grounds, Academy, Mine/Workshop), системы рабочих и разблокировки перков.

---

## New Public API Methods

### Global Bonuses

#### `get_global_defense_bonus() -> int`
Возвращает глобальную защиту от всех Barracks.

**Returns**: `int` - суммарная защита (+1 за каждый уровень всех Barracks)

**Example**:
```gdscript
var defense = TownCore.get_global_defense_bonus()  # 5 если Barracks lvl 5
```

**Preconditions**:
- TownCore инициализирован
- BuildingData для Barracks загружены

**Postconditions**:
- Возвращает неотрицательное число
- Результат кэшируется до изменения уровня Barracks

---

#### `get_global_damage_bonus() -> float`
Возвращает глобальный бонус урона от всех Training Grounds.

**Returns**: `float` - суммарный процент урона (например, 0.15 для 3 уровня = +15%)

**Example**:
```gdscript
var damage_bonus = TownCore.get_global_damage_bonus()  # 0.15 для 3 уровня
```

**Preconditions**:
- TownCore инициализирован
- BuildingData для Training Grounds загружены

**Postconditions**:
- Возвращает число >= 0.0
- Результат кэшируется до изменения уровня Training Grounds

---

#### `get_global_xp_bonus() -> float`
Возвращает глобальный бонус XP от всех Academy.

**Returns**: `float` - суммарный процент XP (например, 0.20 для 2 уровня = +20%)

**Example**:
```gdscript
var xp_bonus = TownCore.get_global_xp_bonus()  # 0.20 для 2 уровня
```

**Preconditions**:
- TownCore инициализирован
- BuildingData для Academy загружены

**Postconditions**:
- Возвращает число >= 0.0
- Результат кэшируется до изменения уровня Academy

---

### Unlocked Perks

#### `get_unlocked_perks() -> Array[String]`
Возвращает список ID всех разблокированных перков.

**Returns**: `Array[String]` - массив ID перков, разблокированных зданиями

**Example**:
```gdscript
var unlocked = TownCore.get_unlocked_perks()  # ["shield_wall", "vanguard"]
```

**Preconditions**:
- TownCore инициализирован

**Postconditions**:
- Возвращает массив строк (может быть пустым)
- Все ID существуют в HeroCore._perk_registry

---

#### `is_perk_unlocked(perk_id: String) -> bool`
Проверяет, разблокирован ли перк.

**Parameters**:
- `perk_id: String` - ID перка для проверки

**Returns**: `bool` - true если перк разблокирован

**Example**:
```gdscript
if TownCore.is_perk_unlocked("shield_wall"):
    # Перк доступен
```

**Preconditions**:
- `perk_id` не пустой
- TownCore инициализирован

**Postconditions**:
- Возвращает true или false
- Не изменяет состояние

---

### Worker Management

#### `assign_worker(building_id: String, person_id: String) -> bool`
Назначает свободного человека в здание как рабочего.

**Parameters**:
- `building_id: String` - ID здания
- `person_id: String` - ID человека

**Returns**: `bool` - true если назначение успешно

**Example**:
```gdscript
if TownCore.assign_worker("farm", "person_1"):
    print("Worker assigned")
```

**Preconditions**:
- `building_id` существует в `_buildings`
- `person_id` существует в `_population_status`
- `_population_status[person_id] == "FREE"`
- Количество рабочих в здании < max_workers

**Postconditions**:
- `_population_status[person_id] == "WORKER"`
- `person_id` добавлен в `_worker_assignments[building_id]`
- Производство здания пересчитано
- EventBus.building_worker_assigned.emit(building_id, person_id)

**Errors**:
- Возвращает false если предconditions не выполнены

---

#### `remove_worker(building_id: String, person_id: String) -> bool`
Снимает рабочего с здания, возвращает в статус FREE.

**Parameters**:
- `building_id: String` - ID здания
- `person_id: String` - ID рабочего

**Returns**: `bool` - true если снятие успешно

**Example**:
```gdscript
if TownCore.remove_worker("farm", "person_1"):
    print("Worker removed")
```

**Preconditions**:
- `building_id` существует в `_buildings`
- `person_id` существует в `_population_status`
- `_population_status[person_id] == "WORKER"`
- `person_id` в `_worker_assignments[building_id]`

**Postconditions**:
- `_population_status[person_id] == "FREE"`
- `person_id` удалён из `_worker_assignments[building_id]`
- Производство здания пересчитано
- EventBus.building_worker_removed.emit(building_id, person_id)

**Errors**:
- Возвращает false если предconditions не выполнены

---

#### `get_building_workers(building_id: String) -> Array[String]`
Возвращает список ID рабочих, назначенных в здание.

**Parameters**:
- `building_id: String` - ID здания

**Returns**: `Array[String]` - массив ID рабочих

**Example**:
```gdscript
var workers = TownCore.get_building_workers("farm")  # ["person_1", "person_2"]
```

**Preconditions**:
- `building_id` существует в `_buildings`

**Postconditions**:
- Возвращает массив строк (может быть пустым)
- Не изменяет состояние

---

#### `get_available_workers() -> Array[String]`
Возвращает список ID свободных людей (FREE).

**Returns**: `Array[String]` - массив ID свободных людей

**Example**:
```gdscript
var free = TownCore.get_available_workers()  # ["person_1", "person_2", "person_3"]
```

**Preconditions**:
- TownCore инициализирован

**Postconditions**:
- Возвращает массив строк (может быть пустым)
- Не изменяет состояние

---

### Building Production with Workers

#### `get_building_food_production(building_id: String) -> float`
Возвращает производство еды зданием с учётом рабочих.

**Parameters**:
- `building_id: String` - ID здания

**Returns**: `float` - производство еды в секунду

**Example**:
```gdscript
var production = TownCore.get_building_food_production("farm")  # 2.0 для 2 рабочих
```

**Formula**:
```gdscript
base_production = base_food_per_sec + (food_per_level * (level - 1))
worker_multiplier = 1.0 + (worker_bonus_per_worker * workers_count)
final_production = base_production * worker_multiplier
```

**Preconditions**:
- `building_id` существует в `_buildings`
- BuildingData для здания загружены

**Postconditions**:
- Возвращает число >= 0.0
- Учитывает уровень здания и количество рабочих

---

#### `get_building_gold_production(building_id: String) -> float`
Возвращает производство золота зданием с учётом рабочих.

**Parameters**:
- `building_id: String` - ID здания

**Returns**: `float` - производство золота в секунду

**Example**:
```gdscript
var production = TownCore.get_building_gold_production("mine")  # 3.0 для 2 рабочих
```

**Formula**: Аналогично `get_building_food_production()`, но для золота

**Preconditions**:
- `building_id` существует в `_buildings`
- BuildingData для здания загружены

**Postconditions**:
- Возвращает число >= 0.0
- Учитывает уровень здания и количество рабочих

---

## Extended Existing Methods

### `try_upgrade_building(building_id: String) -> bool`
**Extension**: После успешного апгрейда проверяет разблокировку перков.

**New Behavior**:
1. Выполняет существующую логику апгрейда
2. Вызывает `_check_unlocked_perks(building_id, new_level)`
3. Если перки разблокированы, добавляет их в `_unlocked_perks`
4. Эмитит `EventBus.perk_unlocked.emit(perk_id)` для каждого нового перка

---

## New Signals (EventBus)

### `perk_unlocked(perk_id: String)`
Эмитится при разблокировке нового перка зданием.

**Parameters**:
- `perk_id: String` - ID разблокированного перка

**Emitted by**: TownCore при апгрейде здания до порогового уровня

**Subscribers**: HeroCore (для обновления пула доступных перков)

---

### `building_worker_assigned(building_id: String, person_id: String)`
Эмитится при назначении рабочего в здание.

**Parameters**:
- `building_id: String` - ID здания
- `person_id: String` - ID рабочего

**Emitted by**: TownCore при успешном `assign_worker()`

**Subscribers**: UI (для обновления отображения)

---

### `building_worker_removed(building_id: String, person_id: String)`
Эмитится при снятии рабочего с здания.

**Parameters**:
- `building_id: String` - ID здания
- `person_id: String` - ID рабочего

**Emitted by**: TownCore при успешном `remove_worker()`

**Subscribers**: UI (для обновления отображения)

---

## Save/Load Contract

### Save Data Structure
```gdscript
{
  "buildings": {
    "barracks": {"level": 5, "workers": 0, "slots": {}},
    "training_grounds": {"level": 3, "workers": 0, "slots": {}},
    "academy": {"level": 2, "workers": 0, "slots": {}},
    "mine": {"level": 1, "workers": 2, "slots": {}}
  },
  "unlocked_perks": ["shield_wall", "vanguard"],
  "population_status": {
    "person_1": "FREE",
    "person_2": "WORKER",
    "person_3": "HERO"
  },
  "worker_assignments": {
    "mine": ["person_2"]
  }
}
```

### `get_save_data() -> Dictionary`
**Extension**: Добавляет новые поля в существующий метод.

**New Fields**:
- `unlocked_perks: Array[String]` - список разблокированных перков
- `population_status: Dictionary` - статусы всех людей
- `worker_assignments: Dictionary` - назначения рабочих

### `apply_save_data(data: Dictionary) -> void`
**Extension**: Загружает новые поля из сохранения.

**New Behavior**:
- Восстанавливает `_unlocked_perks` из `data.unlocked_perks`
- Восстанавливает `_population_status` из `data.population_status`
- Восстанавливает `_worker_assignments` из `data.worker_assignments`
- Валидирует данные перед применением

---

## Error Handling

### Invalid Building ID
- Методы возвращают `false` или `0.0` / `[]` при несуществующем `building_id`
- Логируется предупреждение в консоль

### Invalid Person ID
- `assign_worker()` / `remove_worker()` возвращают `false`
- Логируется предупреждение в консоль

### Worker Limit Exceeded
- `assign_worker()` возвращает `false` если `workers >= max_workers`
- Логируется предупреждение в консоль

---

## Performance Considerations

### Caching
- Глобальные бонусы кэшируются и пересчитываются только при изменении уровней зданий
- Производство зданий пересчитывается только при изменении уровня или количества рабочих

### Optimization
- Использовать Set для `_unlocked_perks` для быстрой проверки наличия
- Минимизировать итерации по словарям в горячих путях

