# Как запустить тест Phase 2 в игре

## Способ 1: Автоматический тест (РЕКОМЕНДУЕТСЯ)

Тестовый узел уже добавлен в `GameScene.tscn`. Тест запустится автоматически при старте игры.

**Шаги**:
1. Откройте проект в Godot
2. Нажмите **F5** (или кнопку Play) для запуска игры
3. Тест выполнится автоматически при загрузке сцены
4. Результаты будут в консоли Godot (вкладка **Output** внизу редактора)

**Где смотреть результаты**:
- В Godot редакторе: вкладка **Output** (внизу, рядом с Debugger)
- Или в файле лога: `logs/editor_run.log`

---

## Способ 2: Ручной запуск через консоль отладчика

Если хотите запустить тест вручную:

**Шаги**:
1. Запустите игру из Godot (**F5**)
2. В Godot редакторе откройте вкладку **Debugger** (внизу)
3. Перейдите на вкладку **Remote** (Remote Inspector)
4. Внизу есть поле для ввода команд - вставьте:

```gdscript
var test = load("res://specs/007-enemy-swarm-optimization/test-phase2.gd").new()
get_tree().root.add_child(test)
test.run_tests()
```

5. Нажмите Enter - тест выполнится
6. Результаты появятся в консоли **Output**

---

## Способ 3: Простая проверка через консоль

Если хотите быстро проверить методы вручную:

**Шаги**:
1. Запустите игру (**F5**)
2. Откройте **Debugger** → **Remote**
3. Введите команды по одной:

```gdscript
# Проверка get_culling_distance()
QualityManager.set_quality(0)
print("Level 0 culling: ", QualityManager.get_culling_distance())  # Должно быть 800.0

QualityManager.set_quality(3)
print("Level 3 culling: ", QualityManager.get_culling_distance())  # Должно быть 1500.0

# Проверка get_max_enemies()
print("Level 0 max_enemies: ", QualityManager.get_max_enemies())  # Должно быть 300
print("Level 3 max_enemies: ", QualityManager.get_max_enemies())  # Должно быть 600
```

---

## Ожидаемый результат

Если все работает правильно, в консоли должно появиться:

```
=== Phase 2 Testing: QualityManager Enhancements ===

Test 1: get_culling_distance() for all quality levels
  ✓ Level 0: 800.0px (expected 800.0px)
  ✓ Level 1: 1000.0px (expected 1000.0px)
  ✓ Level 2: 1200.0px (expected 1200.0px)
  ✓ Level 3: 1500.0px (expected 1500.0px)

Test 2: get_max_enemies() for all quality levels
  ✓ Level 0: 300 (expected 300)
  ✓ Level 1: 400 (expected 400)
  ✓ Level 2: 500 (expected 500)
  ✓ Level 3: 600 (expected 600)

Test 3: Error handling for invalid quality levels
  ✓ Invalid level returns defaults: culling=800.0px, max_enemies=300

Test 4: Quality level transitions update values
  ✓ All transitions work correctly

=== Test Results ===
Passed: 4
Failed: 0
Total: 4

✓ All tests PASSED - Phase 2 is ready!
```

---

## Где находится консоль в Godot?

1. **Output консоль**: Внизу редактора, вкладка **Output** (показывает все `print()`)
2. **Debugger консоль**: Внизу редактора, вкладка **Debugger** → **Remote** (для выполнения команд)
3. **Лог файл**: `logs/editor_run.log` (все логи сохраняются туда)

---

## Если тест не запускается

1. Убедитесь, что `QualityManager` загружен как autoload (проверьте `project.godot`)
2. Проверьте, что файл `test-phase2.gd` существует по пути `specs/007-enemy-swarm-optimization/test-phase2.gd`
3. Убедитесь, что в `GameScene.tscn` есть узел `Phase2Test` с правильным скриптом

---

## Отключить автоматический тест

Если не хотите, чтобы тест запускался автоматически:

1. Откройте `GameScene.tscn` в Godot
2. Найдите узел `Phase2Test`
3. В Inspector установите `auto_run = false`
4. Или удалите узел `Phase2Test` из сцены

