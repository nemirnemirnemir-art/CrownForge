extends RefCounted
class_name BuildingSlotQuery


func has_active_tavern() -> bool:
	for slot in _get_current_scene_slots():
		if not _is_slot_building(slot, "tavern"):
			continue
		if _is_slot_effectively_vzor_active(slot):
			return true
	return false


func get_active_arena_morale_bonus() -> int:
	var total_bonus := 0
	for slot in _get_current_scene_slots():
		if not _is_slot_building(slot, "arena"):
			continue
		var raw_handler: Variant = slot.get("_special_handler")
		if raw_handler == null:
			continue
		if not (raw_handler is RefCounted):
			continue
		var handler := raw_handler as RefCounted
		if not handler.has_method("get_morale_bonus"):
			continue
		total_bonus += int(handler.call("get_morale_bonus"))
	return total_bonus


func get_warrior_count_on_field() -> int:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return 0

	var current_scene := tree.current_scene
	if current_scene == null or not current_scene.is_in_group("game_scene"):
		return 0

	var heroes := tree.get_nodes_in_group("hero")
	var count := 0
	for hero in heroes:
		if not _is_living_hero_on_scene(hero, current_scene):
			continue
		count += 1
	return count


func _get_current_scene_slots() -> Array:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return []
	var game_scene: Node = tree.current_scene
	return _get_scene_slots(game_scene)


func _get_scene_slots(game_scene: Node) -> Array:
	var map_layout: Variant = game_scene.get("map_layout_node")
	if map_layout == null:
		return []
	var slots_value: Variant = map_layout.get("slots")
	if not (slots_value is Array):
		return []
	return slots_value as Array


func _is_slot_building(slot, building_id: String) -> bool:
	if slot == null or not is_instance_valid(slot):
		return false
	var raw_building_id: Variant = slot.get("current_building_id")
	if raw_building_id == null:
		return false
	return String(raw_building_id) == building_id


func _is_slot_effectively_vzor_active(slot) -> bool:
	if slot == null or not is_instance_valid(slot):
		return false
	if not slot.has_method("is_effectively_vzor_active"):
		return false
	return bool(slot.call("is_effectively_vzor_active"))


func _is_living_hero_on_scene(hero, current_scene: Node) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if not (hero is Node):
		return false
	var hero_node := hero as Node
	if hero_node != current_scene and not current_scene.is_ancestor_of(hero_node):
		return false
	var is_dead_value: Variant = hero_node.get("is_dead")
	if typeof(is_dead_value) == TYPE_BOOL and bool(is_dead_value):
		return false
	return true
