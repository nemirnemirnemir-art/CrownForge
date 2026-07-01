extends RefCounted
class_name HeroCardBattle

## Battle system
## Fight button, Auto mode, automatic battle start

const PopulationBattlefieldQueryScript := preload("res://core/population/PopulationBattlefieldQuery.gd")

var _fight_button: TextureButton
var _auto_button: TextureButton
var _auto_battle_mode: bool = false
var _battlefield_query: RefCounted = PopulationBattlefieldQueryScript.new()

func _hero_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("HeroCore")

func _population_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("PopulationCore")

func initialize(fight_button: TextureButton, auto_button: TextureButton) -> void:
	_fight_button = fight_button
	_auto_button = auto_button

func on_fight_pressed() -> void:
	var hero_core := _hero_core()
	if hero_core == null:
		return
	# ✅ Block if battle is already active
	if hero_core.is_battle_active():
		# print("[HeroCardBattle] ⚠️ Fight button blocked: battle already active")
		return
	
	# ✅ Get available heroes
	var available = hero_core.get_available_for_battle()
	
	if available.is_empty():
		# print("[HeroCardBattle] ⚠️ No heroes available for battle")
		return
	
	# ✅ Send everyone who is available
	var heroes_to_send = _limit_to_population_cap(available)
	if heroes_to_send.is_empty():
		return
	
	# ✅ Send into battle
	hero_core.start_battle_with_heroes(heroes_to_send)
	# print("[HeroCardBattle] ✅ Sent %d heroes to battle" % heroes_to_send.size())

func on_auto_toggled(button_pressed: bool) -> void:
	# ✅ Toggle auto battle mode
	_auto_battle_mode = button_pressed
	
	# Визуальная индикация
	if _auto_button:
		if _auto_button.has_method("set_active_border"):
			_auto_button.set_active_border(_auto_battle_mode)
		
		# Reset modulate to white if using border, or keep it if you want both
		# User asked for "normal" when inactive, implying no tint.
		# But when active, border is enough.
		_auto_button.modulate = Color.WHITE
	
	# print("[HeroCardBattle] Auto battle mode: %s" % ("ON" if _auto_battle_mode else "OFF"))
	
	# If auto is enabled and no battle is active - try to start
	var hero_core := _hero_core()
	if _auto_battle_mode and hero_core != null and not hero_core.is_battle_active():
		_auto_start_next_battle()

func on_stage_changed_for_auto(_new_stage: int) -> void:
	var hero_core := _hero_core()
	if hero_core == null:
		return
	# ✅ Always return heroes from battle after stage (VICTORY = true)
	hero_core.end_current_battle(true)
	# print("[HeroCardBattle] ✅ Stage completed, heroes returned from battle")
	
	# ✅ If Auto is enabled - automatically start a new battle
	if _auto_battle_mode:
		_auto_start_next_battle()

func on_battle_started(_hero_ids: Array) -> void:
	# ✅ Battle start handler - disable Fight button
	if _fight_button:
		_fight_button.disabled = true

func on_battle_ended(_surviving_ids: Array) -> void:
	# ✅ Battle end handler - enable Fight button
	if _fight_button:
		_fight_button.disabled = false

func on_wave_failed(_wave_number: int) -> void:
	var hero_core := _hero_core()
	if hero_core == null:
		return
	# print("[HeroCardBattle] ⚠️ Wave failed (timeout)!")
	
	# 1. Return heroes from battle (not a victory -> false)
	hero_core.end_current_battle(false)
	
	# 2. Disable Auto mode because the stage was NOT completed
	if _auto_battle_mode:
		_disable_auto_mode()
		# print("[HeroCardBattle] 🛑 Auto mode disabled due to wave failure")

func _disable_auto_mode() -> void:
	_auto_battle_mode = false
	if _auto_button:
		_auto_button.button_pressed = false
		if _auto_button.has_method("set_active_border"):
			_auto_button.set_active_border(false)
		_auto_button.modulate = Color.WHITE

func _auto_start_next_battle() -> void:
	var hero_core := _hero_core()
	if hero_core == null:
		_disable_auto_mode()
		return
	# ✅ Safety check: if battle thinks it's active but squad is empty -> stuck state
	if hero_core.is_battle_active() and hero_core.active_hero_ids.is_empty():
		# print("[HeroCardBattle] ⚠️ Detected stuck battle state (Active but no squad). Forcing reset.")
		hero_core.end_current_battle(false)
		
	var available = hero_core.get_available_for_battle()
	
	# If there are no heroes - disable Auto
	if available.is_empty():
		_disable_auto_mode()
		# print("[HeroCardBattle] ⚠️ Auto mode disabled: no heroes available")
		return

	# ✅ Send everyone who is available
	var heroes_to_send = _limit_to_population_cap(available)
	if heroes_to_send.is_empty():
		_disable_auto_mode()
		return
	
	hero_core.start_battle_with_heroes(heroes_to_send)
	# print("[HeroCardBattle] 🔄 Auto-started battle with %d heroes" % heroes_to_send.size())

func get_auto_battle_mode() -> bool:
	return _auto_battle_mode

func _limit_to_population_cap(hero_ids: Array) -> Array:
	if hero_ids == null or hero_ids.is_empty():
		return []
	var population_core := _population_core()
	var hero_core := _hero_core()
	if population_core == null or not population_core.has_method("get_max_population"):
		return hero_ids.duplicate()
	var active_ids: Array[String] = hero_core.active_hero_ids if hero_core else []
	var active_candidates: Array = []
	var inactive_candidates: Array = []
	for hero_id in hero_ids:
		if String(hero_id) in active_ids:
			active_candidates.append(hero_id)
		else:
			inactive_candidates.append(hero_id)
	if _battlefield_query == null or hero_core == null:
		return hero_ids.duplicate()
	var available_capacity: int = int(_battlefield_query.call("get_available_field_capacity", hero_core, population_core))
	if active_candidates.is_empty():
		if available_capacity <= 0:
			return []
		if inactive_candidates.size() <= available_capacity:
			return inactive_candidates.duplicate()
		return inactive_candidates.slice(0, available_capacity)
	if available_capacity <= 0:
		return active_candidates.duplicate()
	if inactive_candidates.is_empty():
		return active_candidates.duplicate()
	var limited: Array = active_candidates.duplicate()
	limited.append_array(inactive_candidates.slice(0, available_capacity))
	return limited

