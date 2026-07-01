# Quickstart: Building System Expansion

**Feature**: 018-building-population-system  
**Date**: 2025-11-28

---

## Быстрый обзор

Эта фича добавляет:
1. **3 новых здания**: Barracks, Training Grounds, Academy
2. **Систему рабочих**: назначение населения в экономические здания
3. **Разблокировку перков**: здания разблокируют новые перки
4. **Глобальные бонусы**: защита, урон, XP для всех героев

---

## Порядок реализации

### Шаг 1: Расширение BuildingData
1. Открыть `core/building_data.gd`
2. Добавить новые поля:
   - `global_defense_per_level: int`
   - `global_damage_percent_per_level: float`
   - `global_xp_percent_per_level: float`
   - `unlocked_perks: Array[Dictionary]`
   - `max_workers: int`
   - `worker_bonus_per_worker: float`

### Шаг 2: Создание данных зданий
1. Создать `data/buildings/barracks.tres`
2. Создать `data/buildings/training_grounds.tres`
3. Создать `data/buildings/academy.tres`
4. Создать `data/buildings/mine.tres`

### Шаг 3: Расширение TownCore
1. Добавить методы для глобальных бонусов:
   - `get_global_defense_bonus() -> int`
   - `get_global_damage_bonus() -> float`
   - `get_global_xp_bonus() -> float`
2. Добавить систему разблокировки перков:
   - `_unlocked_perks: Set[String]`
   - `_check_unlocked_perks(building_id, level)`
3. Добавить систему рабочих:
   - `_population_status: Dictionary`
   - `_worker_assignments: Dictionary`
   - `assign_worker()`, `remove_worker()`

### Шаг 4: Расширение HeroCore
1. Модифицировать `get_hero_damage()` для учёта глобального бонуса
2. Модифицировать `get_hero_defense()` для учёта глобального бонуса
3. Добавить `get_hero_xp_gain_multiplier()`
4. Модифицировать `get_available_perks_for_hero()` для включения разблокированных перков

### Шаг 5: Изменение формулы урона
1. Найти место расчёта урона (BattleCore или DamageCalculator)
2. Изменить формулу на плоскую защиту: `max(1, raw_damage - effective_defense)`

### Шаг 6: Создание новых перков
1. Создать 8 новых перков в `data/perks/`:
   - shield_wall.tres, vanguard.tres, dragonslayer.tres
   - steel_grip.tres, powerful_thrust.tres, duelist.tres
   - fast_learner.tres, mentor.tres

### Шаг 7: Сохранение/загрузка
1. Расширить `TownCore.get_save_data()` для новых полей
2. Расширить `TownCore.apply_save_data()` для загрузки

---

## Тестирование

### Базовые тесты
```gdscript
# Тест глобальной защиты
var defense = TownCore.get_global_defense_bonus()  # должно быть 5 для Barracks lvl 5

# Тест глобального урона
var damage_bonus = TownCore.get_global_damage_bonus()  # должно быть 0.15 для Training Grounds lvl 3

# Тест разблокировки перка
TownCore.try_upgrade_building("barracks")  # до уровня 5
var unlocked = TownCore.get_unlocked_perks()  # должен содержать "shield_wall"

# Тест назначения рабочего
TownCore.assign_worker("farm", "person_1")
var workers = TownCore.get_building_workers("farm")  # должен содержать "person_1"
```

---

## Частые проблемы

### Проблема: Глобальные бонусы не применяются
**Решение**: Убедиться, что HeroCore вызывает `TownCore.get_global_*()` методы

### Проблема: Перки не разблокируются
**Решение**: Проверить, что `unlocked_perks` в BuildingData правильно настроены

### Проблема: Рабочие не влияют на производство
**Решение**: Убедиться, что `get_building_*_production()` учитывает `workers` и `worker_bonus_per_worker`

---

## Следующие шаги

После реализации базовой функциональности:
1. Добавить UI для управления рабочими
2. Добавить визуализацию глобальных бонусов
3. Добавить уведомления о разблокировке перков

