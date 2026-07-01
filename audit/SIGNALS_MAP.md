# SIGNALS_MAP

Карта сигналов (emit/connect) — заполняется по мере анализа.

| Сигнал | Emit (кто) | Listen (кто) | Примечания |
|---|---|---|---|

| `EventBus.gold_changed(new_amount, delta)` | `res://core/economy_core.gd` | `res://scripts/ui/hud/MainUI.gd` | UI обновляет gold label; также используется при reset progress в `SaveCore` |
| `EventBus.stars_changed(new_amount)` | `res://core/economy_core.gd` | `res://scripts/ui/hud/MainUI.gd` | В `MainUI` обработчик сейчас placeholder |
| `EventBus.forge_cores_changed(new_amount, delta)` | `res://core/economy_core.gd` | `res://scripts/ui/hud/MainUI.gd`, `res://scripts/ui/town/ForgePanelLegacy.gd`, `res://scripts/ui/town/ForgePanel.gd`, `res://scripts/ui/town/TownMenu.gd` | В `MainUI` подключается через `has_signal` guard |
| `EventBus.prestige_triggered()` | `res://core/economy_core.gd` | — | Emitter подтверждён (`EconomyCore.prestige()`); listeners не найдены в этом проходе |
| `EventBus.stage_changed(new_stage)` | `res://core/stage_core.gd` (also reset in `res://core/save_core.gd`) | `res://scripts/ui/hud/MainUI.gd`, `res://scripts/game_scene/GameSceneSignals.gd`, `res://scripts/hero/card/HeroCardSignals.gd` | Используется и для автосейва (`StageCore`), и для UI/логики |
| `EventBus.wave_started(wave_number)` | `res://core/battle_core.gd` | `res://scripts/game_scene/GameSceneSignals.gd`, `res://core/artifacts/artifact_core.gd` | Эмитится в `BattleCore.start_wave()` |
| `EventBus.wave_completed(wave_number)` | `res://core/battle_core.gd` | `res://core/stage_core.gd`, `res://core/hero_core.gd` | Эмитится в `BattleCore.complete_wave()` |
| `EventBus.wave_failed(wave_number)` | presumably `res://core/battle_core.gd` | `res://scripts/hero/card/HeroCardSignals.gd` | Listener подтверждён; emitter не найден в этом проходе |
| `EventBus.enemy_killed(enemy_id)` | `res://core/battle_core.gd` | `res://scripts/game_scene/GameSceneSignals.gd`, `res://core/artifacts/artifact_core.gd` | Эмитится в `BattleCore.unregister_mob()` |
| `EventBus.hero_selected_for_ui(hero_id)` | `res://scripts/ui/hud/HeroBar.gd`, `res://scripts/hero/card/HeroCardButtons.gd` | `res://scripts/ui/overlays/HeroCard.gd` | HeroBar дополнительно эмитит свой `hero_selected` |
| `EventBus.hero_recruited(hero_id)` | `res://core/hero_core.gd` | — | Emitter подтверждён (`hire/recruit`), listeners не найдены в этом проходе |
| `EventBus.hero_died(hero_id)` | `res://core/hero_core.gd` | `res://scripts/game_scene/GameSceneSignals.gd` | В `HeroCore` эмитится перед `remove_hero()` |
| `EventBus.battle_started(hero_ids)` | `res://core/hero_core.gd` | `res://scripts/hero/card/HeroCardSignals.gd` | HeroCard слушает для отображения battle state |
| `EventBus.battle_ended(surviving_ids)` | `res://core/hero_core.gd` | `res://scripts/hero/card/HeroCardSignals.gd` | — |
| `EventBus.hero_auto_replaced(dead_id, new_id)` | `res://core/hero_core.gd` | `res://scripts/game_scene/GameSceneSignals.gd` | — |
| `EventBus.skill1_toggled(active)` | `res://core/skill_core.gd` | — | Listeners не найдены в этом проходе (UI может поллить состояние) |
| `EventBus.hero_healed_by_hospital(hero_id, amount)` | `res://core/town/TownHospital.gd` | `res://scripts/ui/hud/HeroBar.gd` | HeroBar показывает/обновляет UI |
| `EventBus.perk_unlocked(perk_id)` | `res://core/town/TownPerks.gd` | — | Listeners не найдены в этом проходе |
| `EventBus.perk_available(perk_id)` | `res://core/town/TownPerks.gd` | — | Listeners не найдены в этом проходе |
| `EventBus.building_worker_assigned(building_id, person_id)` | `res://core/town/TownPopulation.gd` | — | Listeners не найдены в этом проходе |
| `EventBus.building_worker_removed(building_id, person_id)` | `res://core/town/TownPopulation.gd` | — | Listeners не найдены в этом проходе |
| `EventBus.game_saved()` | `res://core/save_core.gd` | — | Emitter подтверждён; listeners не найдены в этом проходе |
| `EventBus.game_loaded()` | `res://core/save_core.gd` | `res://scripts/ui/hud/MainUI.gd`, `res://core/artifacts/artifact_core.gd` | `MainUI` обновляет дисплей после загрузки |
