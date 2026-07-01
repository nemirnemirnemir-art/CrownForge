# Research: Building System Expansion

**Feature**: 018-building-population-system  
**Date**: 2025-11-28

---

## Research Decisions

### Decision 1: Хранение разблокированных перков

**Question**: Где хранить `unlocked_perks: Set[perk_id]` - в TownCore или HeroCore?

**Decision**: Хранить в TownCore, так как разблокировка происходит при апгрейде зданий.

**Rationale**:
- TownCore управляет зданиями и их апгрейдами
- Разблокировка перков - это следствие апгрейда здания
- HeroCore только читает список разблокированных перков через API TownCore
- Соответствует принципу разделения ответственности

**Alternatives considered**:
- HeroCore: не подходит, так как HeroCore не знает о зданиях
- Отдельный модуль PerkCore: избыточно для текущего масштаба

---

### Decision 2: Структура хранения рабочих в зданиях

**Question**: Как хранить информацию о рабочих в структуре зданий?

**Decision**: Расширить существующую структуру `_buildings` в TownCore:
```gdscript
{
  "level": int,
  "workers": int,  # количество назначенных рабочих
  "slots": {}  # существующие слоты улучшений
}
```

**Rationale**:
- Минимальные изменения существующей структуры
- Рабочие - это состояние здания, логично хранить вместе с уровнем
- Простое сохранение/загрузка

**Alternatives considered**:
- Отдельный Dictionary `_building_workers`: усложняет синхронизацию
- WorkerCore модуль: избыточно для v1

---

### Decision 3: Интеграция плоской защиты в BattleCore

**Question**: Как интегрировать плоскую защиту в существующую систему расчёта урона?

**Decision**: Модифицировать формулу урона в BattleCore или DamageCalculator:
```gdscript
# До: final_damage = raw_damage * (1 - defense_percent)
# После: final_damage = max(1, raw_damage - effective_defense)
```

**Rationale**:
- Плоская защита более понятна игрокам
- Минимальный урон = 1 предотвращает полную неуязвимость
- Легко интегрируется с существующей системой

**Alternatives considered**:
- Гибридная система (процентная + плоская): сложнее для баланса
- Только процентная: менее интуитивна для игроков

---

### Decision 4: Порядок применения бонусов урона

**Question**: Как правильно применять бонусы урона от Training Grounds, перков и предметов?

**Decision**: Аддитивная формула: `base * (1 + sum_of_all_bonuses)`

**Rationale**:
- Проще для понимания и баланса
- Линейный рост предсказуем
- Все бонусы суммируются в скобках

**Implementation**:
```gdscript
var training_bonus = TownCore.get_global_damage_bonus()  # 0.15 для 3 уровня
var perk_bonus = HeroCore.get_hero_damage_bonus_from_perks(hero_id)  # 0.10
var item_bonus = HeroCore.get_hero_damage_bonus_from_items(hero_id)  # 0.05
var final_damage = base_damage * (1.0 + training_bonus + perk_bonus + item_bonus)
```

**Alternatives considered**:
- Мультипликативная: слишком сильный рост на высоких уровнях
- Смешанная: сложнее для понимания

---

### Decision 5: Система статусов населения

**Question**: Как отслеживать статусы людей (FREE, WORKER, HERO)?

**Decision**: Хранить в TownCore:
```gdscript
var _population_status: Dictionary = {}  # person_id -> "FREE" | "WORKER" | "HERO"
var _worker_assignments: Dictionary = {}  # building_id -> Array[person_id]
```

**Rationale**:
- TownCore уже управляет населением
- Простая структура для v1
- Легко расширять в будущем

**Alternatives considered**:
- Отдельный PopulationCore: избыточно для текущего масштаба
- Хранение в HeroCore: нарушает разделение ответственности

---

### Decision 6: Интеграция глобальных бонусов в HeroCore

**Question**: Как HeroCore получает глобальные бонусы от зданий?

**Decision**: HeroCore запрашивает бонусы через TownCore API:
```gdscript
# В HeroCore при расчёте урона:
var global_damage_bonus = TownCore.get_global_damage_bonus()
var global_defense_bonus = TownCore.get_global_defense_bonus()
var global_xp_bonus = TownCore.get_global_xp_bonus()
```

**Rationale**:
- TownCore - единственный источник правды о зданиях
- HeroCore не зависит от деталей реализации зданий
- Соответствует архитектурным принципам

**Alternatives considered**:
- EventBus сигналы при каждом расчёте: избыточно
- Кэширование в HeroCore: усложняет синхронизацию

---

## Best Practices Applied

### 1. Расширение существующих структур
- Не ломаем существующую структуру `_buildings`
- Добавляем новые поля, сохраняя обратную совместимость
- Используем значения по умолчанию для новых полей

### 2. Минимизация изменений в BattleCore
- Изменяем только формулу урона
- Сохраняем существующие интерфейсы
- Добавляем новые методы, не удаляя старые

### 3. Сохранение/загрузка
- Расширяем существующие методы SaveCore
- Сохраняем новые данные в той же структуре
- Обеспечиваем обратную совместимость при загрузке

---

## Technical Constraints

### Godot 4.3 Specifics
- Использовать `@export` для полей в Resource
- Использовать сигналы для уведомлений между модулями
- Автолоады доступны глобально по имени класса

### Performance Considerations
- Глобальные бонусы вычисляются один раз при изменении зданий
- Кэширование результатов расчёта бонусов
- Минимизация обращений к TownCore в циклах

---

## Integration Points

### TownCore → HeroCore
- HeroCore запрашивает глобальные бонусы через `TownCore.get_global_*()` методы
- HeroCore получает список разблокированных перков через `TownCore.get_unlocked_perks()`

### TownCore → BattleCore
- BattleCore получает глобальную защиту через `TownCore.get_global_defense_bonus()`
- BattleCore использует новую формулу урона с плоской защитой

### TownCore → SaveCore
- TownCore сохраняет состояние рабочих и разблокированных перков
- SaveCore загружает данные обратно в TownCore

---

## Open Questions (Resolved)

Все вопросы из спецификации разрешены через clarifications:
- ✅ Mine/Workshop: создаётся новое здание
- ✅ Пороги разблокировки: 5/10/15 для всех зданий
- ✅ Формула урона: аддитивная

