# CODE_VS_SCENE

| Путь | Что создаётся кодом | Паттерн | Серьёзность | Рекомендация (.tscn альтернатива) | Выигрыш |
|------|----------------------|---------|-------------|-----------------------------------|--------|

| `res://scripts/map/MapSlot.gd` | UI элементы на слоте: `UnitCountLabel`, `DurabilityLabel`, `MarketActionBtn` (+ `TextureRect` и т.п.), production popup (`HBoxContainer` + `TextureRect` + `Label`) | `Label.new()`, `Button.new()`, `TextureRect.new()`, `HBoxContainer.new()`, `StyleBoxFlat.new()`, + много ручных свойств и `add_child()` | 🟡 High | Вынести в отдельные сцены: `MapSlotUnitCountLabel.tscn`, `MapSlotDurabilityLabel.tscn`, `MapSlotMarketActionButton.tscn`, `MapSlotProductionPopup.tscn` (инстансить/показывать по необходимости) | проще поддерживать/стилизовать в редакторе; меньше ручной раскладки |

| `res://scripts/ui/hud/MainUI.gd` | Tooltip панели HP (hero/enemy) и GameOver overlay создаются кодом | `PanelContainer.new()`, `VBoxContainer.new()`, `Label.new()`, `ProgressBar.new()`, `ColorRect.new()`, `Button.new()` | 🟡 High | Вынести в сцены: `HeroHpTooltip.tscn`, `EnemyHpTooltip.tscn`, `GameOverOverlay.tscn` с export'ами (цвета/шрифты/иконки) | дизайн/размещение управляемы в editor; меньше багов от ручных offsets |

| `res://scripts/ui/debug/DebugMenu.gd` | Debug overlay UI строится из `Label/Button/HBox/HSlider/CheckBox` в рантайме | множественные `*.new()` + `add_child()` | ⚪ Low | Для debug допустимо, но можно сделать `DebugMenu.tscn` с готовой разметкой (кнопки/слайдеры/контейнеры) | быстрее менять debug UI, меньше кода |

| `res://scripts/ui/debug/DebugSpawnMenu.gd` | Большой debug spawn menu: Panel/Scroll/контейнеры/кнопки/иконки | `PanelContainer.new()`, `ScrollContainer.new()`, `VBoxContainer.new()`, `Button.new()`, `TextureRect.new()`, `StyleBoxFlat.new()` + ручная раскладка | 🟡 High | Создать `DebugSpawnMenu.tscn` со статичной разметкой (шапка, три секции: heroes/mobs/spells), оставить в коде только наполнение списков и обработчики | проще поддерживать/перетаскивать/масштабировать |

| `res://scripts/ui/town/forge/ForgePanelCrafting.gd` | Добавляет/перестраивает UI внутри forge panel (OptionButton, Craft button overlay, crafting slots UI) | `OptionButton.new()`, `Button.new()`, `TextureRect.new()`, `Label.new()`, `PanelContainer.new()` и т.д. | 🟡 High | Вынести “CraftControls” и “CraftingSlot” в сцены (`ForgeCraftControls.tscn`, `ForgeCraftSlot.tscn`) и инстансить их вместо ручной сборки | снижает связность со структурой нод и риск поломок при правке UI |

| `res://scripts/ui/artifacts/ArtifactPanel.gd` | Слоты артефактов (`Control` + фон/рамка) и tooltip создаются кодом | `Control.new()`, `ColorRect.new()`, `ReferenceRect.new()`, `PanelContainer.new()`, `MarginContainer.new()`, `VBoxContainer.new()`, `Label.new()` + `add_child()` | 🟡 High | Перенести layout слота и tooltip в `.tscn` (например: `ArtifactSlot.tscn`, `ArtifactTooltip.tscn`) и только биндить данные из кода | меньше кода, проще править внешний вид |

| `res://scripts/ui/artifacts/ArtifactDebugPanel.gd` | Debug grid + tooltip UI полностью создаются кодом (Panel/Scroll/Grid/slots/tooltip) | `PanelContainer.new()`, `ScrollContainer.new()`, `GridContainer.new()`, `Control.new()`, `ColorRect.new()`, `ReferenceRect.new()`, `Label.new()` + `add_child()` | 🟡 High | Сделать статичную сцену `ArtifactDebugPanel.tscn` с Grid/Tooltip, оставить в коде только наполнение/обновление | проще поддерживать/стилизовать |

| `res://scripts/ui/town/BuildingDetailsPanel.gd` | Внутри панели детали здания часть UI строится кодом (юниты “provides”, upgrades контейнер/заголовок) | `HBoxContainer.new()`, `TextureRect.new()`, `Label.new()`, `VBoxContainer.new()` + `add_child()` | 🟡 High | Вынести “UnitProvidesRow.tscn” и “UpgradesSection.tscn” (с заголовком и контейнером) и инстансить их вместо ручной сборки | меньше риска поломок при правке UI |

| `res://scripts/hero/bar/HeroBarDisplay.gd` | Оверлеи слота героя (StatusContainer + fatigue icon, HP bar из ColorRect’ов, SelectionBorder) создаются кодом | `HBoxContainer.new()`, `TextureRect.new()`, `ColorRect.new()` + `add_child()` | 🟡 High | Добавить эти узлы в `HeroSlot.tscn`/`HeroBar.tscn` как заранее размеченные ноды (или subscene `HeroSlotOverlay.tscn`), а код только обновляет текстуры/проценты | проще поддерживать и дебажить |

| `res://scripts/game/GameScene.gd` | Fallback создание “служебных” нод: `HeroPivot` контейнер и ghost building (`Sprite2D`) и WaveTimerBar (если нет в дереве) | `Node2D.new()`, `Sprite2D.new()`, `.instantiate()` + `add_child()` | 🟡 High | Зафиксировать эти ноды в `GameScene.tscn` (или отдельной subscene `WorldContainers.tscn`/`PlacementOverlay.tscn`) и убрать runtime-fallback (оставить assert/log) | меньше скрытых зависимостей от структуры дерева |

| `res://scripts/systems/DamagePopupPool.gd` | Контейнер для попапов создаётся кодом и цепляется к `current_scene` | `Node2D.new()` + `add_child()` | ⚪ Low | Для стабильности можно завести заранее `DamagePopupContainer` в главной сцене/UILayer и искать его по group/path | уменьшит магию и случаи “контейнер потерялся” |

| `res://scripts/components/AttackComponent.gd` | Debug overlay узла атаки создаётся кодом (ColorRect под хитбокс) | `ColorRect.new()` + `add_child()` | ⚪ Low | Нормально для debug, либо сделать `DebugVisual` нодой в сцене и просто включать/обновлять | меньше веток кода |

| `res://scripts/ui/town/BuildingsTooltip.gd` | Ряды “units/resources” частично создаются кодом (HBox + icon + label), также fallback иконок через Label | `HBoxContainer.new()`, `TextureRect.new()`, `Label.new()` + `add_child()` | 🟡 High | Вынести row-шаблоны в сцены (`UnitRow.tscn`, `ResourceRow.tscn`, `IconFallback.tscn`) и инстансить их; код только заполняет | проще дизайн/локализация/стили |

| `res://scripts/ui/town/SmithCraftPanel.gd` | Ингредиенты/блоки требований для крафта создаются кодом (контейнеры, иконки, множитель, qty) + тик-таймер | `Timer.new()`, `HBoxContainer.new()`, `TextureRect.new()`, `Label.new()` + `add_child()` | 🟡 High | Сделать `SmithIngredientBlock.tscn` (icon × qty) и `SmithIngredientsRow.tscn`; таймер можно держать в сцене как `Timer` node | меньше ручной раскладки |

| `res://scripts/ui/hud/WaveTimerBar.gd` | “Флажки” волн создаются в рантайме (ColorRect + опциональный TextureRect) | `ColorRect.new()`, `TextureRect.new()` + `add_child()` | ⚪ Low | Для предсказуемости можно держать `Flag.tscn` и пулить/переиспользовать (или заранее размеченный контейнер) | меньше кода и магии |

| `res://scripts/ui/town/ForgePanelLegacy.gd` | UI слотов крафта создаётся кодом (PanelContainer + VBox + Label + Icon + Button) | `PanelContainer.new()`, `VBoxContainer.new()`, `Label.new()`, `TextureRect.new()`, `Button.new()` + `add_child()` | 🟡 High | Вынести `ForgeSlot.tscn` (status/icon/action) и инстансить `MAX_CRAFT_SLOTS` | проще менять внешний вид и логику |

| `res://scripts/hero/card/HeroCardPerks.gd` | Контейнер перков создаётся как fallback и панели/иконки перков генерятся кодом | `GridContainer.new()`, `Panel.new()`, `StyleBoxFlat.new()`, `TextureRect.new()` + `add_child()` | ⚪ Low | Лучше иметь `PerksContainer` в `.tscn` и использовать `PerkIcon.tscn` для единообразия | меньше “если нет — создай” веток |

| `res://scripts/hero/card/HeroCardBuffs.gd` | Иконки бафов создаются кодом при отсутствии нод | `TextureRect.new()` + `add_child()` | ⚪ Low | Добавить placeholder-ноды в сцену и только обновлять texture/visible | меньше runtime-ветвлений |

| `res://scripts/hero/card/HeroCardPotions.gd` | UI кнопки зелья дополняется кодом: `PotionIcon` + контейнер цифр + `Sprite2D` цифры | `TextureRect.new()`, `Node2D.new()`, `Sprite2D.new()` + `add_child()` | 🟡 High | Вынести в под-сцену `PotionButtonOverlay.tscn` (иконка + digits) | легче править/анимировать |

| `res://scripts/ui/inventory/InventorySlot.gd` | Рисует количество как `QuantityLabel` и создаёт drag preview ноду | `Label.new()`, `TextureRect.new()` + `add_child()` | ⚪ Low | В сцене `InventorySlot.tscn` держать `QuantityLabel` изначально (скрытым) и обновлять; drag preview допустимо оставить кодом | меньше условий и пересозданий |

| `res://scripts/ui/inventory/ItemTooltip.gd` | Tooltip сцена грузится и инстансится динамически (саму себя) | `load("res://scenes/ui/inventory/ItemTooltip.tscn")` + `.instantiate()` | ⚪ Low | Если tooltip всегда нужен — можно держать один инстанс в UI (пул/синглтон), а не грузить каждый раз | меньше аллокаций и путей |

| `res://scripts/ui/town/MarketUI.gd` | Полностью создаёт UI торговли из кода (контейнеры, кнопки, иконки, стили) + динамически инстансит tooltip | `Control.new()`, `Button.new()`, `TextureRect.new()`, `StyleBoxFlat.new()` + `add_child()` | 🟡 High | Вынести trade button row в `MarketTradeButton.tscn` и собрать `MarketUI.tscn` статично, кодом только заполнять список `TRADES` | проще поддерживать и масштабировать |

| `res://scripts/map/MapLayout.gd` | Создаёт runtime-узлы карты: `NavigationRegion2D`/`NavigationPolygon`, debug rect на слотах, `MapMarker` (bridge/portal/spawn/defense/wall), а также `Node2D` визуальные заглушки (`Bridge`, `Portal`) | `NavigationRegion2D.new()`, `NavigationPolygon.new()`, `ColorRect.new()`, `MapMarker.new()`, `Node2D.new()` + `add_child()` | 🟡 High | Зафиксировать структуру через сцены/подсцены: `MapMarkers.tscn` / `PortalMarker.tscn` / `BridgeMarker.tscn` / `SlotDebugRect.tscn`; код оставлять для позиционирования и данных | меньше скрытых зависимостей и проще дебажить |

| `res://scripts/ui/hud/GameSpeedUI.gd` | Кнопки скорости создаются кодом | `TextureButton.new()` + `add_child()` | ⚪ Low | Можно держать 4 кнопки в `.tscn` и только присваивать текстуры/обработчики | меньше runtime-сборки |

| `res://scripts/hero/HeroHealth.gd` | Докручивает HealthBar: создаёт `HPLabel` если отсутствует; также спавнит `HealingPopup` сценой | `Label.new()` + `add_child()` (+ `load(...).instantiate()`) | ⚪ Low | Держать `HPLabel` в сцене (`HealthBar.tscn`/hero scene) и только обновлять | меньше ветвлений |

| `res://scripts/ui/hud/PopulationBar.gd` | Tooltip для популяции создаётся/инстансится и цепляется к `MainUI`/root | `.instantiate()` + `add_child()` | ⚪ Low | Держать один tooltip инстанс под `MainUI` и только показывать/позиционировать | меньше аллокаций |

| `res://scripts/ui/inventory/InventoryBar.gd` | UI инвентаря частично создаётся кодом (кнопки, иконки, контейнеры) | `Button.new()`, `TextureRect.new()`, `HBoxContainer.new()` + `add_child()` | ⚪ Low | Вынести в под-сцену `InventoryButton.tscn` (иконка + текст) и инстансить | проще поддерживать и масштабировать |
