extends RefCounted
class_name HeroCardSignals

## Обработка сигналов
## Подключение и обработка всех сигналов HeroCard

var _hero_card: Control
var _selected_hero_id: String = ""
var _on_hero_updated_callback: Callable
var _on_display_update_callback: Callable
var _on_stage_changed_callback: Callable
var _on_wave_failed_callback: Callable
var _on_battle_started_callback: Callable
var _on_battle_ended_callback: Callable

func initialize(hero_card: Control, on_hero_updated: Callable, on_display_update: Callable, on_stage_changed: Callable, on_wave_failed: Callable, on_battle_started: Callable, on_battle_ended: Callable) -> void:
	_hero_card = hero_card
	_on_hero_updated_callback = on_hero_updated
	_on_display_update_callback = on_display_update
	_on_stage_changed_callback = on_stage_changed
	_on_wave_failed_callback = on_wave_failed
	_on_battle_started_callback = on_battle_started
	_on_battle_ended_callback = on_battle_ended
	_connect_signals()

func set_selected_hero_id(hero_id: String) -> void:
	_selected_hero_id = hero_id

func _connect_signals() -> void:
	if HeroCore != null:
		HeroCore.hero_updated.connect(_on_hero_updated)
		HeroCore.squad_changed.connect(_on_squad_changed)
		HeroCore.buff_added.connect(_on_buff_added)
		HeroCore.buff_removed.connect(_on_buff_removed)
	
	# ✅ Подписка на сигналы зелий
	if TownCore != null:
		if not TownCore.hero_assigned_potion.is_connected(_on_potion_assigned):
			TownCore.hero_assigned_potion.connect(_on_potion_assigned)
		if not TownCore.potion_produced.is_connected(_on_potion_produced):
			TownCore.potion_produced.connect(_on_potion_produced)
			
	# ✅ Подписка на завершение стадии для Auto-режима и битвы
	if EventBus:
		if not EventBus.stage_changed.is_connected(_on_stage_changed_for_auto):
			EventBus.stage_changed.connect(_on_stage_changed_for_auto)
		if not EventBus.wave_failed.is_connected(_on_wave_failed):
			EventBus.wave_failed.connect(_on_wave_failed)
		if not EventBus.battle_started.is_connected(_on_battle_started):
			EventBus.battle_started.connect(_on_battle_started)
		if not EventBus.battle_ended.is_connected(_on_battle_ended):
			EventBus.battle_ended.connect(_on_battle_ended)

func _on_hero_updated(hero_id: String, _hero_data: Dictionary) -> void:
	if hero_id == _selected_hero_id:
		_on_hero_updated_callback.call()

func _on_squad_changed() -> void:
	_on_display_update_callback.call()

func _on_buff_added(hero_id: String, buff_id: String) -> void:
	if hero_id == _selected_hero_id:
		print("[HeroCardSignals] Buff added: %s to %s" % [buff_id, hero_id])
		_on_display_update_callback.call()

func _on_buff_removed(hero_id: String, buff_id: String) -> void:
	if hero_id == _selected_hero_id:
		print("[HeroCardSignals] Buff removed: %s from %s" % [buff_id, hero_id])
		_on_display_update_callback.call()

func _on_potion_assigned(_hero_id: String, _current_potions: int) -> void:
	# ✅ Обновляем отображение при выдаче зелья
	if _hero_id == _selected_hero_id:
		_on_display_update_callback.call()

func _on_potion_produced(_current_potions: int) -> void:
	# ✅ Обновляем иконку при производстве зелий
	if _selected_hero_id != "":
		_on_display_update_callback.call()

func _on_stage_changed_for_auto(new_stage: int) -> void:
	if _on_stage_changed_callback.is_valid():
		_on_stage_changed_callback.call(new_stage)

func _on_wave_failed(wave_number: int) -> void:
	if _on_wave_failed_callback.is_valid():
		_on_wave_failed_callback.call(wave_number)

func _on_battle_started(hero_ids: Array) -> void:
	if _on_battle_started_callback.is_valid():
		_on_battle_started_callback.call(hero_ids)

func _on_battle_ended(surviving_ids: Array) -> void:
	if _on_battle_ended_callback.is_valid():
		_on_battle_ended_callback.call(surviving_ids)

