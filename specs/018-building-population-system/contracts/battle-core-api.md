# BattleCore API Contract - Building System Expansion

**Feature**: 018-building-population-system  
**Module**: `core/battle_core.gd` или `utils/damage_calculator.gd`  
**Version**: 2.0 (расширение существующего API)

---

## Overview

Изменение формулы расчёта урона для поддержки плоской защиты от Barracks.

---

## Modified Damage Calculation

### Formula Change

**Old Formula** (если была процентная защита):
```gdscript
final_damage = raw_damage * (1.0 - defense_percent)
```

**New Formula** (плоская защита):
```gdscript
raw_damage = base_damage * multipliers
effective_defense = hero_defense + global_defense_from_barracks + perk_defense
final_damage = max(1, raw_damage - effective_defense)
```

**Components**:
- `raw_damage`: базовый урон с учётом всех мультипликаторов (урон от Training Grounds уже включён)
- `hero_defense`: базовая защита героя
- `global_defense_from_barracks`: глобальная защита от TownCore.get_global_defense_bonus()
- `perk_defense`: защита от перков героя
- `max(1, ...)`: минимальный урон всегда 1

---

## Integration Points

### Hero Stats
BattleCore использует финальные статы героев из HeroCore:
- `HeroCore.get_hero_damage(hero_id)` - уже включает глобальный бонус от Training Grounds
- `HeroCore.get_hero_defense(hero_id)` - уже включает глобальный бонус от Barracks

### Damage Calculation Flow
```
Enemy attacks Hero
  → Get hero defense: HeroCore.get_hero_defense(hero_id)
    → HeroCore internally calls: TownCore.get_global_defense_bonus()
  → Calculate: final_damage = max(1, raw_damage - effective_defense)
  → Apply damage to hero
```

---

## API Methods (if using DamageCalculator)

### `calculate_damage_to_hero(raw_damage: float, hero_id: String) -> float`
Вычисляет финальный урон с учётом защиты героя.

**Parameters**:
- `raw_damage: float` - исходный урон атаки
- `hero_id: String` - ID героя-цели

**Returns**: `float` - финальный урон после применения защиты

**Implementation**:
```gdscript
var hero_defense = HeroCore.get_hero_defense(hero_id)  # уже включает глобальный бонус
var final_damage = max(1.0, raw_damage - float(hero_defense))
return final_damage
```

**Preconditions**:
- `raw_damage >= 0.0`
- `hero_id` существует в HeroCore

**Postconditions**:
- Возвращает число >= 1.0
- Учитывает все источники защиты (базовая, глобальная, перки)

---

## Edge Cases

### Very High Defense
- Если `effective_defense >= raw_damage`, урон = 1 (минимальный)
- Предотвращает полную неуязвимость

### Zero Defense
- Если `effective_defense = 0`, урон = `raw_damage`
- Нормальное поведение для героев без защиты

### Negative Raw Damage
- Если `raw_damage < 0` (не должно происходить), возвращается 1
- Логируется предупреждение

---

## Performance Considerations

### Caching
- Защита героя запрашивается один раз за атаку
- Не нужно кэшировать, так как значения могут меняться редко

### Optimization
- Использовать `max()` вместо `if` для минимального урона
- Избегать повторных запросов к HeroCore в цикле атак

---

## Backward Compatibility

### Existing Code
- Если существующий код использует процентную защиту, нужно мигрировать
- Старые сохранения должны загружаться корректно (защита = 0 если не было)

### Migration
- При загрузке старых сохранений защита инициализируется как 0
- Новые герои получают защиту из данных героя

