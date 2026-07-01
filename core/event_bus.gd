extends Node

## Global Event Bus
## Central hub for communication between modules
## Loaded first in Autoloads

const API_VERSION: int = 1

## === HEROES ===
@warning_ignore("UNUSED_SIGNAL")
signal hero_recruited(hero_id: String)
@warning_ignore("UNUSED_SIGNAL")
signal hero_leveled_up(hero_id: String, new_level: int)
@warning_ignore("UNUSED_SIGNAL")
signal hero_died(hero_id: String)
@warning_ignore("UNUSED_SIGNAL")
signal squad_changed()
@warning_ignore("UNUSED_SIGNAL")
signal hero_selected_for_ui(hero_id: String)  # ✅ Hero clicked for UI

## === BATTLE SYSTEM ===
@warning_ignore("UNUSED_SIGNAL")
signal battle_started(hero_ids: Array)  # ✅ Battle start with heroes
@warning_ignore("UNUSED_SIGNAL")
signal battle_ended(surviving_ids: Array)  # ✅ Battle end
@warning_ignore("UNUSED_SIGNAL")
signal hero_auto_replaced(dead_id: String, new_id: String)  # ✅ Auto-replace

## === ECONOMY ===
@warning_ignore("UNUSED_SIGNAL")
signal gold_changed(new_amount: float, delta: float)
@warning_ignore("UNUSED_SIGNAL")
signal stars_changed(new_amount: int)
@warning_ignore("UNUSED_SIGNAL")
signal purchase_completed(item_id: String, cost: float)
@warning_ignore("UNUSED_SIGNAL")
signal prestige_triggered()
@warning_ignore("UNUSED_SIGNAL")
signal forge_cores_changed(new_amount: int, delta: int)

## === WAVES ===
@warning_ignore("UNUSED_SIGNAL")
signal wave_started(wave_number: int)
@warning_ignore("UNUSED_SIGNAL")
signal wave_completed(wave_number: int)
@warning_ignore("UNUSED_SIGNAL")
signal wave_started_with_mobs(wave_number: int, mob_counts: Dictionary)
@warning_ignore("UNUSED_SIGNAL")
signal wave_failed(wave_number: int) # ✅ Wave failed signal (timeout)
@warning_ignore("UNUSED_SIGNAL")
signal enemy_killed(enemy_id: String)
@warning_ignore("UNUSED_SIGNAL")
signal mob_spawned(mob_id: String)

## === PROGRESS ===
@warning_ignore("UNUSED_SIGNAL")
signal stage_changed(new_stage: int)
@warning_ignore("UNUSED_SIGNAL")
signal biome_changed(biome_name: String)

## === SKILLS ===
@warning_ignore("UNUSED_SIGNAL")
signal skill1_toggled(active: bool)
@warning_ignore("UNUSED_SIGNAL")
signal skill2_activated()
@warning_ignore("UNUSED_SIGNAL")
signal skill2_ended()

## === INVENTORY ===
@warning_ignore("UNUSED_SIGNAL")
signal item_added(item: Dictionary)
@warning_ignore("UNUSED_SIGNAL")
signal item_removed(item: Dictionary)
@warning_ignore("UNUSED_SIGNAL")
signal item_equipped(hero_id: String, item: Dictionary)

## === SYSTEM ===
@warning_ignore("UNUSED_SIGNAL")
signal game_ready()
@warning_ignore("UNUSED_SIGNAL")
signal game_saved()
@warning_ignore("UNUSED_SIGNAL")
signal game_loaded()

## === TOWN ===
@warning_ignore("UNUSED_SIGNAL")
signal hero_healed_by_hospital(hero_id: String, amount: int)
@warning_ignore("UNUSED_SIGNAL")
signal perk_unlocked(perk_id: String)
@warning_ignore("UNUSED_SIGNAL")
signal perk_available(perk_id: String)

## === HUNTING ===
@warning_ignore("UNUSED_SIGNAL")
signal animal_killed(animal_id: String, animal_name: String)
@warning_ignore("UNUSED_SIGNAL")
signal meat_collected(amount: int)
@warning_ignore("UNUSED_SIGNAL")
signal meat_delivered(amount: int)
