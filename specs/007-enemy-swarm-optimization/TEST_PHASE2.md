# Тестирование Phase 2: QualityManager Enhancements

## Что должно быть проверено

Phase 2 добавляет два новых метода в `QualityManager`:
1. `get_culling_distance() -> float` - возвращает расстояние culling для текущего уровня качества
2. `get_max_enemies() -> int` - возвращает максимальное количество врагов для текущего уровня качества

## Тестовые сценарии

### Тест 1: get_culling_distance() для всех уровней качества

**Ожидаемые значения**:
- Level 0 (Critical): 800.0px
- Level 1 (Low): 1000.0px
- Level 2 (Medium): 1200.0px
- Level 3 (High): 1500.0px

**Как проверить**:
1. Запустить игру
2. В консоли Godot выполнить:
```gdscript
QualityManager.set_quality(0)
print("Level 0: ", QualityManager.get_culling_distance())  # Должно быть 800.0

QualityManager.set_quality(1)
print("Level 1: ", QualityManager.get_culling_distance())  # Должно быть 1000.0

QualityManager.set_quality(2)
print("Level 2: ", QualityManager.get_culling_distance())  # Должно быть 1200.0

QualityManager.set_quality(3)
print("Level 3: ", QualityManager.get_culling_distance())  # Должно быть 1500.0
```

### Тест 2: get_max_enemies() для всех уровней качества

**Ожидаемые значения**:
- Level 0 (Critical): 300
- Level 1 (Low): 400
- Level 2 (Medium): 500
- Level 3 (High): 600

**Как проверить**:
```gdscript
QualityManager.set_quality(0)
print("Level 0: ", QualityManager.get_max_enemies())  # Должно быть 300

QualityManager.set_quality(1)
print("Level 1: ", QualityManager.get_max_enemies())  # Должно быть 400

QualityManager.set_quality(2)
print("Level 2: ", QualityManager.get_max_enemies())  # Должно быть 500

QualityManager.set_quality(3)
print("Level 3: ", QualityManager.get_max_enemies())  # Должно быть 600
```

### Тест 3: Обработка ошибок для невалидных уровней

**Ожидаемое поведение**:
- При невалидном уровне (< 0 или > 3) методы должны возвращать значения по умолчанию:
  - `get_culling_distance()` → 800.0px
  - `get_max_enemies()` → 300

**Как проверить**:
```gdscript
# Временно устанавливаем невалидный уровень (только для теста)
var old_quality = QualityManager.current_quality
QualityManager.current_quality = 999  # Невалидный уровень

print("Invalid level culling: ", QualityManager.get_culling_distance())  # Должно быть 800.0
print("Invalid level max_enemies: ", QualityManager.get_max_enemies())  # Должно быть 300

# Восстанавливаем
QualityManager.current_quality = old_quality
```

### Тест 4: Переходы между уровнями качества

**Ожидаемое поведение**:
- При изменении уровня качества через `set_quality()` значения должны обновляться корректно

**Как проверить**:
```gdscript
# Переход 0 -> 1
QualityManager.set_quality(0)
var culling_0 = QualityManager.get_culling_distance()
var max_0 = QualityManager.get_max_enemies()
print("Level 0: culling=", culling_0, " max=", max_0)  # 800.0, 300

QualityManager.set_quality(1)
var culling_1 = QualityManager.get_culling_distance()
var max_1 = QualityManager.get_max_enemies()
print("Level 1: culling=", culling_1, " max=", max_1)  # 1000.0, 400

# Проверяем, что значения изменились
assert(culling_1 > culling_0, "Culling distance should increase")
assert(max_1 > max_0, "Max enemies should increase")
```

## Автоматический тест

Создан скрипт `test-phase2.gd`, который можно добавить в сцену для автоматического тестирования.

**Как использовать**:
1. Открыть `GameScene.tscn` в Godot
2. Добавить новый Node (любой тип) в корень сцены
3. Присвоить скрипт `specs/007-enemy-swarm-optimization/test-phase2.gd`
4. Запустить игру - тест выполнится автоматически

**Или через консоль**:
```gdscript
# В консоли Godot (F8 или View -> Debugger)
var test = load("res://specs/007-enemy-swarm-optimization/test-phase2.gd").new()
get_tree().root.add_child(test)
test.run_tests()
```

## Критерии успеха

✅ **Phase 2 считается успешной, если**:
1. `get_culling_distance()` возвращает правильные значения для всех уровней (0-3)
2. `get_max_enemies()` возвращает правильные значения для всех уровней (0-3)
3. Обработка ошибок работает (невалидные уровни возвращают значения по умолчанию)
4. Переходы между уровнями обновляют значения корректно
5. Нет ошибок компиляции или runtime ошибок

## Что должно выявить тестирование

1. **Правильность значений**: Все методы возвращают ожидаемые значения
2. **Обработка ошибок**: Невалидные входные данные обрабатываются корректно
3. **Интеграция**: Методы работают с существующей системой `QualityManager`
4. **Производительность**: Методы не вызывают задержек (должны быть мгновенными)

## Известные проблемы

Если тесты не проходят, проверьте:
- Правильность значений в `quality_settings` (должны быть `culling_distance` для всех уровней)
- Типизацию методов (должны возвращать `float` и `int` соответственно)
- Обработку ошибок (должны проверять валидность уровня перед доступом к `quality_settings`)

