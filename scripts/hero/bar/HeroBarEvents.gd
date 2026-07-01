extends Node

## HeroBarEvents module
## Manages event handling and popups

var _hero_bar: Control
var _slots: Array[TextureButton] = []
var _current_page: int = 0
const HEROES_PER_PAGE: int = 5

func _get_hero_core() -> Node:
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return null
	var tree := main_loop as SceneTree
	return tree.root.get_node_or_null("HeroCore")

func initialize(hero_bar: Control, slots: Array[TextureButton]) -> void:
	_hero_bar = hero_bar
	_slots = slots

func set_current_page(page: int) -> void:
	_current_page = page

func handle_slot_clicked(slot_index: int, callback: Callable) -> void:
	var hero_core := _get_hero_core()
	if hero_core == null:
		return
	
	# Filter out dead and unhired heroes
	var all_hero_ids: Array = []
	for hero_id in hero_core.query.get_all_hero_ids():
		if not hero_core.query.is_hero_dead(hero_id) and hero_core.query.is_hero_hired(hero_id):
			all_hero_ids.append(hero_id)
			
	all_hero_ids.sort()
	
	var hero_index: int = _current_page * HEROES_PER_PAGE + slot_index
	if hero_index >= all_hero_ids.size():
		return
	
	var hero_id: String = all_hero_ids[hero_index]
	
	# Check if hero is in battle
	if hero_core.is_battle_active() and hero_id in hero_core.get_heroes_in_battle():
		print("[HeroBarEvents] Cannot select hero %s: currently in battle" % hero_id)
		return
	
	print("[HeroBarEvents] Hero selected: %s" % hero_id)
	callback.call(hero_id)

func handle_hero_healed_by_hospital(hero_id: String, amount: int) -> void:
	var hero_core := _get_hero_core()
	if hero_core == null or _slots.is_empty():
		return
	
	# Get hero index
	var all_hero_ids: Array = []
	for h_id in hero_core.query.get_all_hero_ids():
		if not hero_core.query.is_hero_dead(h_id) and hero_core.query.is_hero_hired(h_id):
			all_hero_ids.append(h_id)
			
	all_hero_ids.sort()
	
	var hero_index: int = all_hero_ids.find(hero_id)
	
	if hero_index == -1:
		return
	
	# Check if hero is on current page
	var start_index: int = _current_page * HEROES_PER_PAGE
	var end_index: int = min(start_index + HEROES_PER_PAGE, all_hero_ids.size())
	
	if hero_index < start_index or hero_index >= end_index:
		return
	
	var slot_index: int = hero_index - start_index
	if slot_index >= 0 and slot_index < _slots.size():
		var slot: TextureButton = _slots[slot_index]
		if slot != null and is_instance_valid(slot):
			_show_heal_popup_on_slot(slot, amount)

func _show_heal_popup_on_slot(slot: TextureButton, amount: int) -> void:
	var popup_scene = load("res://scenes/ui/overlays/HealingPopup.tscn")
	if popup_scene == null:
		return
	
	var popup = popup_scene.instantiate()
	if popup == null:
		return
	
	_hero_bar.add_child(popup)
	
	var slot_pos = slot.position
	var slot_size = slot.size
	popup.position = slot_pos + Vector2(slot_size.x * 0.5, -25)
	
	if popup.has_method("setup"):
		popup.setup(amount)

