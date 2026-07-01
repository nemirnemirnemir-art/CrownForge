# HeroCore API Contract - Building System Expansion

**Feature**: 018-building-population-system  
**Module**: `core/hero_core.gd`  
**Version**: 2.0 (расширение существующего API)

---

## Overview

Расширение HeroCore для интеграции с глобальными бонусами от зданий и разблокированными перками.

---

## Extended Existing Methods

### `get_hero_damage(hero_id: String) -> float`
**Extension**: Учитывает глобальный бонус урона от Training Grounds.

**New Formula**:
```gdscript
base_damage = calculate_base_damage(hero_id)
perk_bonus = get_damage_bonus_from_perks(hero_id)
item_bonus = get_damage_bonus_from_items(hero_id)  # если есть система предметов
global_bonus = TownCore.get_global_damage_bonus()  # NEW
final_damage = base_damage * (1.0 + global_bonus + perk_bonus + item_bonus)
```

**Preconditions**:
- `hero_id` существует в `heroes`
- TownCore инициализирован

**Postconditions**:
- Возвращает урон с учётом всех бонусов (глобальных, перков, предметов)
- Результат >= base_damage

---

### `get_hero_defense(hero_id: String) -> int`
**Extension**: Учитывает глобальный бонус защиты от Barracks.

**New Formula**:
```gdscript
base_defense = get_base_defense(hero_id)  # из данных героя
perk_defense = get_defense_bonus_from_perks(hero_id)
global_defense = TownCore.get_global_defense_bonus()  # NEW
final_defense = base_defense + perk_defense + global_defense
```

**Preconditions**:
- `hero_id` существует в `heroes`
- TownCore инициализирован

**Postconditions**:
- Возвращает защиту с учётом всех бонусов
- Результат >= base_defense

---

### `get_hero_xp_gain_multiplier(hero_id: String) -> float`
**NEW**: Возвращает множитель XP gain для героя.

**Formula**:
```gdscript
perk_xp_bonus = get_xp_bonus_from_perks(hero_id)
global_xp_bonus = TownCore.get_global_xp_bonus()  # Academy
final_multiplier = 1.0 + global_xp_bonus + perk_xp_bonus
```

**Returns**: `float` - множитель XP (например, 1.20 для +20%)

**Example**:
```gdscript
var multiplier = HeroCore.get_hero_xp_gain_multiplier(hero_id)
var xp_gained = base_xp * multiplier
```

**Preconditions**:
- `hero_id` существует в `heroes`
- TownCore инициализирован

**Postconditions**:
- Возвращает число >= 1.0
- Учитывает глобальный бонус от Academy и перки героя

---

### `get_available_perks_for_hero(hero_id: String) -> Array[String]`
**Extension**: Включает разблокированные перки от зданий.

**New Behavior**:
1. Получает базовый пул перков (существующая логика)
2. Получает разблокированные перки: `TownCore.get_unlocked_perks()`
3. Объединяет: `available = base_perks + unlocked_perks`
4. Исключает перки, которые уже есть у героя
5. Возвращает объединённый список

**Returns**: `Array[String]` - массив ID доступных перков

**Example**:
```gdscript
var available = HeroCore.get_available_perks_for_hero(hero_id)
# ["deep_pockets", "drinker", "shield_wall", "vanguard"]  # базовые + разблокированные
```

**Preconditions**:
- `hero_id` существует в `heroes`
- TownCore инициализирован

**Postconditions**:
- Возвращает массив уникальных ID перков
- Все ID существуют в `_perk_registry`
- Не включает перки, уже имеющиеся у героя

---

### `try_recruit_hero(type: String) -> bool`
**Extension**: Проверяет доступность населения перед созданием героя.

**New Behavior**:
1. Выполняет существующие проверки (золото, стоимость)
2. **NEW**: Проверяет `TownCore.get_population_used() < TownCore.get_population_max()`
3. Если проверка пройдена, создаёт героя
4. **NEW**: Уменьшает `current_population` через TownCore API (если такой метод будет)

**Preconditions**:
- Все существующие предconditions
- **NEW**: `TownCore.get_population_used() < TownCore.get_population_max()`

**Postconditions**:
- Все существующие postconditions
- **NEW**: `current_population` увеличивается на 1 (герой создан)

**Errors**:
- Возвращает `false` если недостаточно населения
- Логирует сообщение: "Недостаточно населения для создания героя"

---

## New Helper Methods

### `get_damage_bonus_from_perks(hero_id: String) -> float`
Возвращает суммарный бонус урона от всех перков героя.

**Parameters**:
- `hero_id: String` - ID героя

**Returns**: `float` - суммарный процент урона от перков

**Example**:
```gdscript
var bonus = HeroCore.get_damage_bonus_from_perks(hero_id)  # 0.10 для +10%
```

**Implementation**:
```gdscript
var total = 0.0
for perk_id in hero.perks:
    var perk = _perk_registry.get(perk_id)
    if perk:
        total += perk.damage_bonus_percent
return total
```

---

### `get_defense_bonus_from_perks(hero_id: String) -> int`
Возвращает суммарный бонус защиты от всех перков героя.

**Parameters**:
- `hero_id: String` - ID героя

**Returns**: `int` - суммарная защита от перков

**Example**:
```gdscript
var bonus = HeroCore.get_defense_bonus_from_perks(hero_id)  # 2 для +2 armor
```

**Implementation**:
```gdscript
var total = 0
for perk_id in hero.perks:
    var perk = _perk_registry.get(perk_id)
    if perk:
        total += perk.armor_bonus
return total
```

---

### `get_xp_bonus_from_perks(hero_id: String) -> float`
Возвращает суммарный бонус XP от всех перков героя.

**Parameters**:
- `hero_id: String` - ID героя

**Returns**: `float` - суммарный процент XP от перков

**Note**: Требует добавления поля `xp_bonus_percent` в PerkData или использования существующего механизма.

---

## Integration with TownCore

### Dependency
HeroCore зависит от TownCore для получения:
- Глобальных бонусов (defense, damage, XP)
- Списка разблокированных перков

### Access Pattern
```gdscript
# В методах HeroCore:
var global_defense = TownCore.get_global_defense_bonus()
var global_damage = TownCore.get_global_damage_bonus()
var global_xp = TownCore.get_global_xp_bonus()
var unlocked_perks = TownCore.get_unlocked_perks()
```

### Event Subscriptions
HeroCore подписывается на события TownCore:
```gdscript
EventBus.perk_unlocked.connect(_on_perk_unlocked)
EventBus.building_upgraded.connect(_on_building_upgraded)  # для пересчёта бонусов
```

---

## Error Handling

### TownCore Not Available
- Если TownCore не инициализирован, методы возвращают значения без глобальных бонусов
- Логируется предупреждение в консоль

### Invalid Perk ID
- При обработке разблокированных перков проверяется существование в `_perk_registry`
- Несуществующие перки игнорируются с предупреждением

---

## Performance Considerations

### Caching
- Глобальные бонусы запрашиваются один раз при расчёте статов героя
- Результаты можно кэшировать до изменения зданий

### Optimization
- Минимизировать обращения к TownCore в циклах
- Использовать локальные переменные для глобальных бонусов

