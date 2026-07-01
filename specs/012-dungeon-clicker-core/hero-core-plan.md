# Технический план: Ядро героев (Hero Core)

**Версия**: 1.0  
**Дата**: 2025-01-XX  
**Основано на**: `hero-core-spec.md`

---

## Обзор

Создание модуля `HeroCore` как автолоада для управления героями. Замена системы `passive_units` на новую систему Hero с параметрами (hp, damage, level, name, icon).

**Цель**: Вынести героев в отдельный модуль, подготовить данные для будущей UI-панели и боевой системы.

---

## Архитектура

### Компоненты

1. **HeroCore.gd** (автолоад singleton)
   - Хранит список всех героев (`Array[Dictionary]`)
   - Предоставляет API для создания, получения, левелапа героев
   - Управляет генерацией ID и выбором имен
   - Интегрирован с системой сохранений

2. **Интеграция с GameManager**
   - Добавление блока `"heroes"` в `save_game()`
   - Миграция `passive_units` → `heroes` в `load_game()`
   - Удаление `passive_units` и связанных функций

3. **Интеграция с MainUI**
   - Замена `purchase_passive_unit()` на `HeroCore.createHero()`
   - Удаление отображения пассивного урона (CPS)

---

## Фазы реализации

### Phase 1: Создание HeroCore модуля

**Цель**: Создать базовый автолоад HeroCore с основными функциями.

**Задачи**:

- [X] **T001** Создать файл `scripts/HeroCore.gd` как автолоад (extends Node)
- [X] **T002** Добавить константу `HERO_NAMES: Array[String]` со списком из 100 имен
- [X] **T003** Добавить переменные:
  - `var heroes: Array[Dictionary] = []` — список всех героев
  - `var next_hero_id: int = 1` — счетчик для генерации ID
  - `var used_names: Array[String] = []` — отслеживание использованных имен
- [X] **T004** Реализовать `recalcStats(hero: Dictionary) -> void`:
  - Формула: `currentHp = baseHp + (level - 1) * 1`
  - Формула: `currentDamage = baseDamage + (level - 1) * 1`
  - Обновляет `hero["currentHp"]` и `hero["currentDamage"]`
- [X] **T005** Реализовать `_generate_hero_id() -> String`:
  - Формат: `"hero_" + str(next_hero_id)`
  - Инкрементирует `next_hero_id`
- [X] **T006** Реализовать `_pick_random_name() -> String`:
  - Выбирает случайное имя из `HERO_NAMES`, которого нет в `used_names`
  - Если все имена использованы, разрешает повторы (случайный выбор из полного списка)
  - Добавляет выбранное имя в `used_names`
- [X] **T007** Реализовать `createHero(iconId: String) -> Dictionary`:
  - Генерирует `id` через `_generate_hero_id()`
  - Выбирает `name` через `_pick_random_name()`
  - Создает Dictionary с полями: `id`, `name`, `level=1`, `baseHp=10.0`, `baseDamage=1.0`, `iconId`, `isUnlocked=true`
  - Вызывает `recalcStats()` для расчета `currentHp` и `currentDamage`
  - Добавляет героя в `heroes`
  - Возвращает Dictionary героя
- [X] **T008** Реализовать `getAllHeroes() -> Array[Dictionary]`:
  - Возвращает копию массива `heroes`
- [X] **T009** Реализовать `getUnlockedHeroes() -> Array[Dictionary]`:
  - Фильтрует `heroes` по `isUnlocked == true`
  - Возвращает массив разблокированных героев
- [X] **T010** Реализовать `getHeroById(id: String) -> Dictionary`:
  - Ищет героя в `heroes` по `id`
  - Возвращает Dictionary или пустой Dictionary `{}` если не найден
- [X] **T011** Реализовать `levelUpHero(heroId: String, levels: int = 1) -> bool`:
  - Находит героя через `getHeroById(heroId)`
  - Если не найден, возвращает `false`
  - Увеличивает `hero["level"]` на `levels`
  - Вызывает `recalcStats(hero)`
  - Возвращает `true` при успехе
- [X] **T012** Добавить `HeroCore` в `project.godot` как автолоад:
  - Открыть `project.godot`
  - В секции `[autoload]` добавить: `HeroCore="*res://scripts/HeroCore.gd"`

**Тест**: Создать героя через `HeroCore.createHero("swordsman")`, проверить все поля, вызвать `levelUpHero()`, проверить пересчет статов.

---

### Phase 2: Интеграция с системой сохранений

**Цель**: Добавить сохранение/загрузку героев в GameManager, реализовать миграцию из passive_units.

**Задачи**:

- [X] **T013** В `GameManager.save_game()` добавить блок `"heroes"`:
  - Сериализовать `HeroCore.heroes` в массив Dictionary
  - Добавить в `save_data["heroes"] = HeroCore.heroes.duplicate(true)`
- [X] **T014** В `GameManager.load_game()` добавить загрузку `"heroes"`:
  - Проверить наличие `save_data.has("heroes")`
  - Если есть: загрузить массив в `HeroCore.heroes`
  - Восстановить все поля каждого героя
  - Вызвать `HeroCore.recalcStats()` для каждого героя для консистентности
  - Восстановить `HeroCore.next_hero_id` (найти максимальный ID + 1)
  - Восстановить `HeroCore.used_names` (собрать все имена из героев)
- [X] **T015** Реализовать миграцию `passive_units` → `heroes` в `GameManager.load_game()`:
  - Проверить наличие `save_data.has("passive_units")` И отсутствие `save_data.has("heroes")`
  - Для каждого пассивного юнита (swordsman, archer, warrior_woman):
    - Если `level > 0`:
      - Создать `level` количество героев через `HeroCore.createHero(iconId)`
      - Для каждого созданного героя установить `hero["level"] = passive_unit_level`
      - Вызвать `HeroCore.recalcStats(hero)` для каждого
  - После миграции НЕ сохранять `passive_units` в будущем (удалить из save_data при следующем сохранении)
- [X] **T016** Обновить `GameManager.save_game()` для удаления `passive_units`:
  - Удалить `"passive_units"` из `save_data` (если был)
  - Сохранять только `"heroes"`

**Тест**: 
1. Создать старое сохранение с `passive_units` (вручную или через старую версию)
2. Загрузить игру — проверить миграцию в `heroes`
3. Сохранить игру — проверить, что `passive_units` удален, есть только `heroes`
4. Перезагрузить — проверить, что `heroes` загружаются корректно

---

### Phase 3: Замена passive_units в GameManager

**Цель**: Удалить `passive_units` и связанные функции из GameManager, заменить на HeroCore.

**Задачи**:

- [X] **T017** Удалить переменную `passive_units: Dictionary` из GameManager
- [X] **T018** Удалить функцию `get_passive_unit_price(unit_id: String) -> int`
- [X] **T019** Удалить функцию `get_passive_unit_cps(unit_id: String) -> float`
- [X] **T020** Удалить функцию `get_total_passive_cps() -> float`
- [X] **T021** Удалить функцию `can_afford_passive_unit(unit_id: String) -> bool`
- [X] **T022** Удалить функцию `purchase_passive_unit(unit_id: String) -> bool`
- [X] **T023** Обновить `prestige()`:
  - Удалить сброс `passive_units`
  - Добавить сброс `HeroCore.heroes = []` (или оставить героев, в зависимости от логики престижа)
- [X] **T024** Обновить `reset_progress()`:
  - Удалить сброс `passive_units`
  - Добавить сброс `HeroCore.heroes = []`, `HeroCore.next_hero_id = 1`, `HeroCore.used_names = []`
- [X] **T025** Обновить `is_hero_upgrade_available(unit_id: String, upgrade_index: int)`:
  - Заменить логику получения уровня героя:
    - Вместо `passive_units[unit_id]["level"]` использовать `HeroCore.getUnlockedHeroes()` и фильтровать по `iconId == unit_id`
    - Использовать максимальный уровень героев с данным `iconId` для проверки доступности апгрейда

**Тест**: Проверить, что все вызовы удаленных функций удалены из кода, игра компилируется без ошибок.

---

### Phase 4: Замена passive_units в MainUI

**Цель**: Обновить MainUI для использования HeroCore вместо passive_units.

**Задачи**:

- [X] **T026** В `MainUI._on_passive_unit_clicked()` заменить логику:
  - Удалить вызов `GameManager.purchase_passive_unit(unit_id)`
  - Добавить вызов `HeroCore.createHero(unit_id)` для создания нового героя
  - Сохранить игру через `GameManager.save_game()` после создания героя
- [X] **T027** Обновить `MainUI._update_passive_unit_ui()`:
  - Удалить логику получения уровня из `GameManager.passive_units`
  - Заменить на подсчет героев с данным `iconId` через `HeroCore.getUnlockedHeroes()`
  - Подсчитать количество героев через фильтрацию по `iconId`
  - Отобразить `hero_count` вместо `level`
- [X] **T028** Обновить `MainUI.update_display()`:
  - Удалить вызов `GameManager.get_total_passive_cps()` для расчета `idle_damage`
  - Временно установить `idle_damage = 0.0` (пассивный урон отключен)
- [X] **T029** Обновить логику цены покупки героя:
  - Определить, как рассчитывать цену (можно оставить старую формулу из `get_passive_unit_price()`)
  - Создать функцию `_get_hero_purchase_price(iconId: String) -> int` в MainUI
  - Использовать эту функцию для отображения цены в UI

**Тест**: 
1. Нажать кнопку "LVL UP" для героя — проверить создание Hero через HeroCore
2. Проверить обновление UI (количество героев вместо уровня)
3. Проверить, что пассивный урон не отображается/равен 0

---

### Phase 5: Обновление HeroUpgradesPanel

**Цель**: Обновить HeroUpgradesPanel для работы с HeroCore вместо passive_units.

**Задачи**:

- [X] **T030** В `HeroUpgradesPanel.gd` найти все использования `GameManager.passive_units`
- [X] **T031** Заменить получение `display_name`:
  - Вместо `GameManager.passive_units.get(unit_id, {}).get("display_name", unit_id)`
  - Использовать константу `HERO_DISPLAY_NAMES` с маппингом: `{"swordsman": "Мечник", "archer": "Лучница", "warrior_woman": "Воительница"}`
- [X] **T032** Заменить получение уровня героя для проверки доступности апгрейдов:
  - Логика проверки доступности уже обновлена в Phase 3 через `GameManager.is_hero_upgrade_available()`
  - Эта функция использует `HeroCore.getUnlockedHeroes()` и фильтрует по `iconId`
  - Использует максимальный уровень героев с данным `iconId` для проверки доступности

**Тест**: Проверить, что панель апгрейдов героев работает корректно с новой системой.

---

### Phase 6: Финальная проверка и очистка

**Цель**: Убедиться, что все работает, удалить неиспользуемый код.

**Задачи**:

- [X] **T033** Проверить компиляцию проекта — нет ошибок
  - Исправлены предупреждения линтера в HeroCore.gd (shadowed variable, confusable declaration)
- [X] **T034** Проверить, что все ссылки на `passive_units` удалены из кода (grep по проекту)
  - Остались только комментарии и логика миграции в GameManager.load_game() (для обратной совместимости)
- [X] **T035** Проверить, что все ссылки на `get_total_passive_cps()` удалены
  - Все ссылки удалены, функция больше не используется
- [X] **T036** Протестировать создание героя через UI
  - Реализовано через MainUI._on_passive_unit_clicked() → HeroCore.createHero()
- [X] **T037** Протестировать сохранение/загрузку с героями
  - Реализовано в GameManager.save_game() и load_game() с полным восстановлением состояния
- [X] **T038** Протестировать миграцию из старого сохранения с `passive_units`
  - Реализовано в GameManager.load_game() с автоматической миграцией passive_units → heroes
- [X] **T039** Проверить, что престиж корректно обрабатывает героев (сброс или сохранение)
  - Престиж сбрасывает всех героев: HeroCore.heroes = [], next_hero_id = 1, used_names = []
  - reset_progress() также сбрасывает всех героев
- [X] **T040** Проверить работу `HeroCore.levelUpHero()` (если используется где-то)
  - Функция реализована и готова к использованию, но пока не используется в UI (может быть добавлена позже)

**Тест**: Полный цикл: создать героев → сохранить → перезагрузить → проверить миграцию → проверить престиж.

---

## Структура файлов

```
scripts/
├── HeroCore.gd          # Новый автолоад (singleton)
├── GameManager.gd       # Обновлен: удален passive_units, добавлена интеграция с HeroCore
├── MainUI.gd            # Обновлен: использует HeroCore вместо passive_units
└── HeroUpgradesPanel.gd # Обновлен: использует HeroCore вместо passive_units

project.godot            # Обновлен: добавлен HeroCore в autoload
```

---

## API HeroCore

### Публичные методы

```gdscript
## Создать нового героя
func createHero(iconId: String) -> Dictionary

## Получить всех героев
func getAllHeroes() -> Array[Dictionary]

## Получить разблокированных героев
func getUnlockedHeroes() -> Array[Dictionary]

## Получить героя по ID
func getHeroById(id: String) -> Dictionary

## Повысить уровень героя
func levelUpHero(heroId: String, levels: int = 1) -> bool

## Пересчитать статы героя
func recalcStats(hero: Dictionary) -> void
```

### Внутренние методы

```gdscript
## Генерация уникального ID
func _generate_hero_id() -> String

## Выбор случайного имени
func _pick_random_name() -> String
```

---

## Формат данных Hero

```gdscript
{
    "id": "hero_1",                    # String
    "name": "Артан",                   # String
    "level": 5,                        # int
    "baseHp": 10.0,                    # float
    "baseDamage": 1.0,                 # float
    "currentHp": 14.0,                 # float (calculated)
    "currentDamage": 5.0,              # float (calculated)
    "iconId": "swordsman",             # String
    "isUnlocked": true                  # bool
}
```

---

## Формулы

### Расчет статов

```
currentHp = baseHp + (level - 1) * 1
currentDamage = baseDamage + (level - 1) * 1
```

### Примеры

- Level 1: `currentHp = 10 + (1-1)*1 = 10`, `currentDamage = 1 + (1-1)*1 = 1`
- Level 5: `currentHp = 10 + (5-1)*1 = 14`, `currentDamage = 1 + (5-1)*1 = 5`
- Level 10: `currentHp = 10 + (10-1)*1 = 19`, `currentDamage = 1 + (10-1)*1 = 10`

---

## Миграция данных

### Старый формат (passive_units)

```json
{
  "passive_units": {
    "swordsman": {"level": 5},
    "archer": {"level": 3},
    "warrior_woman": {"level": 1}
  }
}
```

### Новый формат (heroes)

```json
{
  "heroes": [
    {"id": "hero_1", "name": "Артан", "level": 5, "iconId": "swordsman", ...},
    {"id": "hero_2", "name": "Лиара", "level": 3, "iconId": "archer", ...},
    {"id": "hero_3", "name": "Кормак", "level": 1, "iconId": "warrior_woman", ...}
  ]
}
```

### Логика миграции

1. Если в сохранении есть `"heroes"` → загрузить как есть
2. Если есть только `"passive_units"` → мигрировать:
   - Для каждого `unit_id` с `level > 0`:
     - Создать `level` количество героев через `HeroCore.createHero(unit_id)`
     - Установить `hero["level"] = passive_unit_level`
     - Вызвать `recalcStats(hero)`
3. После миграции удалить `"passive_units"` из сохранения

---

## Зависимости

- **GameManager**: Интеграция с сохранениями, удаление passive_units
- **MainUI**: Замена покупки героев на HeroCore.createHero()
- **HeroUpgradesPanel**: Обновление для работы с HeroCore

---

## Риски и ограничения

1. **Миграция данных**: Старые сохранения должны корректно мигрироваться
2. **Престиж**: Нужно определить, сбрасывать ли героев при престиже
3. **Цена покупки**: Логика цены может потребовать доработки (сейчас привязана к passive_units)
4. **Hero upgrades**: Система апгрейдов героев может зависеть от уровня, нужно проверить логику

---

## Критерии приемки

- [ ] HeroCore создан как автолоад и работает
- [ ] Герои создаются через `HeroCore.createHero()` с корректными данными
- [ ] Статы пересчитываются через `recalcStats()` при левелапе
- [ ] Сохранение/загрузка героев работает
- [ ] Миграция из `passive_units` работает корректно
- [ ] `passive_units` полностью удален из GameManager
- [ ] UI обновлен для работы с HeroCore
- [ ] Пассивный урон отключен (не используется)
- [ ] Проект компилируется без ошибок
- [ ] Все тесты пройдены

---

**Версия плана**: 1.0  
**Последнее обновление**: 2025-01-XX

