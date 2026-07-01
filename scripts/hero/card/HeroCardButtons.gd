extends RefCounted
class_name HeroCardButtons

## Кнопки действий
## Обработка нажатий кнопок (potion, XP, kill, info, level up)

var _selected_hero_id: String = ""

func initialize() -> void:
	pass

func set_selected_hero_id(hero_id: String) -> void:
	_selected_hero_id = hero_id

func on_button1_pressed() -> void:
	# ✅ Выдача зелья герою вместо добавления XP
	if _selected_hero_id == "":
		return
	
	if TownCore == null:
		print("[HeroCardButtons] TownCore not found!")
		return
	
	if TownCore.assign_potion_to_hero(_selected_hero_id):
		print("[HeroCardButtons] Potion assigned to hero: %s" % _selected_hero_id)
	else:
		print("[HeroCardButtons] Cannot assign potion (none available or hero's potion slots are full)")

func on_button2_pressed() -> void:
	if _selected_hero_id != "" and HeroCore != null:
		HeroCore.add_xp_to_hero(_selected_hero_id, 5)

func on_button3_pressed() -> void:
	if _selected_hero_id != "" and HeroCore != null:
		HeroCore.mark_hero_dead(_selected_hero_id)

func on_button4_pressed() -> void:
	if _selected_hero_id != "" and HeroCore != null:
		var hero: Dictionary = HeroCore.heroes.get(_selected_hero_id, {})
		print("[HeroCardButtons] Hero Info: ", hero)

func on_level_up_pressed() -> void:
	if _selected_hero_id != "" and HeroCore != null:
		# Add enough XP to level up (or just add a large amount)
		var hero: Dictionary = HeroCore.heroes.get(_selected_hero_id, {})
		var xp_to_next: int = hero.get("xpToNext", 10)
		HeroCore.add_xp_to_hero(_selected_hero_id, xp_to_next)
		print("[HeroCardButtons] Level up button pressed for hero: %s" % _selected_hero_id)

func handle_delete_key() -> void:
	# ✅ Обработка клавиши Del для убийства выбранного героя
	if _selected_hero_id != "" and HeroCore != null:
		HeroCore.mark_hero_dead(_selected_hero_id)
		print("[HeroCardButtons] Hero %s killed via Del key" % _selected_hero_id)

func on_prev_hero_pressed() -> void:
	if _selected_hero_id == "" or HeroCore == null:
		return
	
	var all_ids = _get_sorted_hero_ids()
	if all_ids.is_empty():
		return
		
	var current_index = all_ids.find(_selected_hero_id)
	if current_index == -1:
		# If current hero not found (e.g. dead/removed), select first
		_select_hero_by_index(0, all_ids)
		return
		
	# Previous index with wrap-around
	var new_index = (current_index - 1 + all_ids.size()) % all_ids.size()
	_select_hero_by_index(new_index, all_ids)

func on_next_hero_pressed() -> void:
	if _selected_hero_id == "" or HeroCore == null:
		return
		
	var all_ids = _get_sorted_hero_ids()
	if all_ids.is_empty():
		return
		
	var current_index = all_ids.find(_selected_hero_id)
	if current_index == -1:
		_select_hero_by_index(0, all_ids)
		return
		
	# Next index with wrap-around
	var new_index = (current_index + 1) % all_ids.size()
	_select_hero_by_index(new_index, all_ids)

func _get_sorted_hero_ids() -> Array:
	if HeroCore == null: return []
	var ids = []
	for id in HeroCore.query.get_all_hero_ids():
		if not HeroCore.query.is_hero_dead(id) and HeroCore.query.is_hero_hired(id):
			ids.append(id)
	ids.sort()
	return ids

func _select_hero_by_index(index: int, all_ids: Array) -> void:
	if index >= 0 and index < all_ids.size():
		var new_id = all_ids[index]
		# We need to notify the main controller to switch hero.
		# Since this class doesn't have reference to HeroCard, we can emit signal via EventBus
		# or rely on HeroCard calling this method and then updating itself if we returned the ID.
		# But currently the architecture seems to be HeroCard calls these methods.
		# Let's emit a global event that HeroCard listens to, OR better yet, 
		# since HeroCard holds the reference to this module, it might be cleaner to just trigger the selection event.
		
		EventBus.hero_selected_for_ui.emit(new_id)
