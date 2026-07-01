# 03. Ресурсы и экономика

## Обзор ресурсной системы

В игре **14 типов ресурсов**, разделённых на две категории:
- **Базовые ресурсы** — добываются напрямую без входных материалов
- **Продвинутые ресурсы** — производятся из базовых через переработку

---

## Полный список ресурсов

### Базовые ресурсы (Basic Resources)

| Ресурс | Английское название | Источник | Приоритет |
|--------|---------------------|----------|-----------|
| **Вода** | Water | Well (Колодец) | Критический |
| **Пшеница** | Wheat | Wheat Field, Small Wheat Field | Критический |
| **Древесина** | Wood | Sawmill, Tree | Критический |
| **Железная руда** | Iron Ore | Iron Mine | Высокий |
| **Золото** | Gold | Gold Mine, Market (продажа) | Высокий |
| **Глина** | Clay | Clay Mine | Средний |
| **Виноград** | Grapes | Vineyard | Средний |
| **Кристаллы** | Crystal | Crystal Mine | Низкий (поздняя игра) |

### Продвинутые ресурсы (Advanced Resources)

| Ресурс | Английское название | Производство | Входные материалы |
|--------|---------------------|--------------|-------------------|
| **Мука** | Flour | Mill (Мельница) | 1 Wheat → 1 Flour |
| **Сталь** | Steel | Forge (Кузница) | 1 Iron Ore → 1 Steel |
| **Вино** | Wine | Winery (Винодельня) | 3 Grapes → 1 Wine |
| **Мясо** | Meat | Unknown (возможно специальные события/карты) | Unknown |
| **Масло** | Oil | Unknown | Unknown |

---

## Таблица: Ресурс → Источники → Потребители

| Ресурс | Источники | Потребители (примеры) |
|--------|-----------|----------------------|
| **Water** | Well | Строительство большинства зданий, Tree, Small Wheat Field |
| **Wheat** | Wheat Field, Small Wheat Field | Тренировка юнитов, Market, Mill |
| **Wood** | Sawmill, Tree | Строительство, Carpentry, апгрейд армии |
| **Iron Ore** | Iron Mine | Forge, строительство казарм, Market |
| **Gold** | Gold Mine, Market | Апгрейд взгляда, покупки у торговца, строительство |
| **Clay** | Clay Mine | Brick Factory, строительство |
| **Grapes** | Vineyard | Winery, Stables |
| **Crystal** | Crystal Mine | Crystal Castle, Magic College |
| **Flour** | Mill | Dragon Hatchery, Academy of Nature, Market |
| **Steel** | Forge | Ballista/Catapult Factory, Carpentry, Market |
| **Wine** | Winery | Unknown (мораль?, специальные юниты?) |

---

## Цепочки производства

### Базовая цепочка (ранняя игра)

```
Water ──► Wheat Field ──► Wheat ──► Тренировка крестьян
  │                         │
  └──► Sawmill ──► Wood ────┴──► Строительство
```

### Цепочка железа/стали

```
Wheat + Wood ──► Iron Mine ──► Iron Ore ──► Forge ──► Steel
                                  │                      │
                                  └──► Market ──► Gold   └──► Siege weapons
```

### Цепочка еды (продвинутая)

```
Wheat ──► Mill ──► Flour ──► Dragon Hatchery
                      │
                      └──► Market (3 Gold за 1 Flour)
```

### Цепочка кристаллов

```
Gold + Iron Ore + Wood ──► Crystal Mine ──► Crystal ──► Crystal Castle
                                               │              │
                                               └──► Magic College
```

---

## Лимиты и хранение

### Лимиты ресурсов

| Ресурс | Лимит | Примечание |
|--------|-------|------------|
| **Tree (дерево)** | 100 древесины макс. | Затем исчезает |
| **Small Wheat Field** | 100 пшеницы макс. | Затем исчезает |
| **Остальные** | Unknown | Возможно безлимитны |

**Примечание:** Tree и Small Wheat Field — это **исчерпаемые** постройки. После добычи 100 единиц ресурса они исчезают.

### Хранилища

В публичных источниках **не найдено** информации о системе хранилищ или лимитах накопления ресурсов.

---

## Рынок и торговля

### Market (Рынок)

| Операция | Курс |
|----------|------|
| Wheat → Gold | 1:1 |
| Iron Ore → Gold | 1:1 |
| Flour → Gold | 1:3 |
| Steel → Gold | 1:3 |

**Апгрейд "Faster Trading":** +25% к скорости торговли

## Система морали (Morale)

### Уровни морали

| Уровень | Название | Эффект |
|---------|----------|--------|
| 1 | Very Bad (Очень плохо) | Штрафы к характеристикам войск |
| 2 | Bad (Плохо) | Небольшие штрафы |
| 3 | Neutral (Нейтрально) | Без эффектов |
| 4 | Good (Хорошо) | Бонусы к характеристикам |
| 5 | Very Good (Отлично) | Максимальные бонусы |

### Источники морали

| Источник | Эффект |
|----------|--------|
| **Arena** | +20 морали (пока активна, не суммируется) |
| **Arena (апгрейд Morale Boost)** | +30 морали |
| **Hospital (апгрейд Masters of Morale)** | +4 морали за каждый активный госпиталь |
| **Concert** | +4 морали (Music for the Soul) |
| **Пассивка короля** | Зависит от короля |

### Эффекты морали по королям

Каждый король имеет уникальный **"Morale Effect"**, влияющий на определённые аспекты:

| Король | Эффект морали |
|--------|---------------|
| **Baldwin** | Увеличение урона юнитов |
| **Leonid** | Unknown (связано с войсками) |
| **Другие** | Unknown (требует проверки wiki) |

---

## Затраты королевских способностей

Каждый король использует ресурсы для активных способностей:

| Король | Ресурсы для способностей |
|--------|--------------------------|
| **Alucard** | Flour, Gold, Water |
| **Brezhnius** | Crystal, Water |
| **Baldwin** | Gold, Water |
| **Leo** | Wheat, Wood |
| **Leonid** | Meat, Wine |
| **Saladin** | Water, Wheat, Meat |
| **Spellus** | Water, Oil, Gold |

---

## Экономические стратегии

### Ранняя игра (приоритеты)

1. **Well** — бесплатный источник воды
2. **Wheat Field / Small Wheat Field** — пшеница для всего
3. **Sawmill / Tree** — древесина для строительства
4. **Market** — конвертация пшеницы в золото для апгрейда взгляда

### Средняя игра

1. **Iron Mine + Forge** — сталь для осадных орудий
2. **Gold Mine** — прямой источник золота
3. **Mill** — мука для драконов и продажи

### Поздняя игра

1. **Crystal Mine** — кристаллы для элитных юнитов
2. **Magic College** — быстрая генерация заклинаний
3. **Winery + Stables** — продвинутые юниты

---

## Источники

- ((Destructoid - All Resources Guide)) https://www.destructoid.com/all-resources-in-the-king-is-watching-and-how-to-get-them/
- ((Gameplay Tips - Buildings Guide)) https://gameplay.tips/guides/the-king-is-watching-all-buildings-and-upgrades-guide.html
- ((Official Wiki - Morale)) https://thekingiswatching.wiki.gg/wiki/Morale
- ((Steam Store Page)) https://store.steampowered.com/app/2753900/The_King_is_Watching/
- ((GamerBlurb - Upgrades Guide)) https://gamerblurb.com/articles/the-king-is-watching-upgrades-guide
