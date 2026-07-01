extends RefCounted
class_name GameSceneBuildingDrag

var _selected_building_id: String = ""
var _ghost_building: Sprite2D = null
var _source_slot_index: int = -1
var _game_scene: Node = null
var _map_layout_node: Node = null

func _building_registry() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("BuildingRegistry") if tree and tree.root else null

func _town_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("TownCore") if tree and tree.root else null

func _seal_registry() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("SealRegistry") if tree and tree.root else null

func _resource_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("ResourceCore") if tree and tree.root else null

func initialize(game_scene: Node, map_layout_node: Node) -> void:
	_game_scene = game_scene
	_map_layout_node = map_layout_node

func on_drag_started(building_id: String) -> void:
	_source_slot_index = -1
	_start_drag(building_id)

func on_move_started(slot_index: int, building_id: String) -> void:
	_source_slot_index = slot_index
	_start_drag(building_id)
	if _map_layout_node and slot_index < _map_layout_node.slots.size():
		_map_layout_node.slots[slot_index].sprite.modulate.a = 0.2

func _start_drag(building_id: String) -> void:
	_selected_building_id = building_id
	
	if _ghost_building:
		_ghost_building.queue_free()
	
	_ghost_building = Sprite2D.new()
	var icon_texture: Texture2D = null
	
	var building_registry := _building_registry()
	var town_core := _town_core()
	var seal_registry := _seal_registry()
	if building_registry:
		icon_texture = building_registry.get_building_icon(building_id)
		if icon_texture == null:
			var cfg = building_registry.get_building(building_id)
			if cfg and cfg is BuildingConfig:
				icon_texture = (cfg as BuildingConfig).get_icon_or_placeholder()
	
	if icon_texture == null and town_core:
		var config = town_core.get_building_config(building_id)
		if config and config.icon:
			icon_texture = config.icon
	
	if icon_texture == null and seal_registry:
		var seal = seal_registry.get_seal(building_id)
		if seal and seal.icon:
			icon_texture = seal.icon
	
	if icon_texture == null:
		var gradient = Gradient.new()
		gradient.set_color(0, Color(0.5, 0.5, 0.5, 0.5))
		gradient.set_color(1, Color(0.5, 0.5, 0.5, 0.5))
		var tex = GradientTexture2D.new()
		tex.gradient = gradient
		tex.width = 64
		tex.height = 64
		icon_texture = tex
	
	if icon_texture:
		_ghost_building.texture = icon_texture
	
	_ghost_building.modulate = Color(1, 1, 1, 0.5)
	
	var tex_size = icon_texture.get_size()
	if tex_size.x > 80 or tex_size.y > 80:
		var scale_factor = 64.0 / max(tex_size.x, tex_size.y)
		_ghost_building.scale = Vector2(scale_factor, scale_factor)
	else:
		_ghost_building.scale = Vector2(1.0, 1.0)
	_ghost_building.scale *= 2.0
	
	_ghost_building.z_index = 100
	_game_scene.add_child(_ghost_building)

func handle_drop(building_menu: Node) -> void:
	if _selected_building_id == "" or not _ghost_building:
		return
	
	var is_seal := false
	var building_registry := _building_registry()
	var town_core := _town_core()
	var seal_registry := _seal_registry()
	if seal_registry and seal_registry.get_seal(_selected_building_id):
		is_seal = true
	var target_slot = _find_slot_at_mouse(is_seal)
	
	if target_slot:
		var success = false
		if _source_slot_index == -1:
			if seal_registry and seal_registry.get_seal(_selected_building_id):
				success = _handle_seal_placement(target_slot)
			elif building_registry:
				if building_registry.has_method("can_build_from_recipe") and not building_registry.can_build_from_recipe(_selected_building_id):
					success = false
				elif building_registry.pay_for_building(_selected_building_id):
					target_slot.set_building(_selected_building_id)
					success = true
					if building_registry.has_method("is_release_mode_enabled") and building_registry.is_release_mode_enabled() and building_registry.has_method("consume_recipe"):
						building_registry.consume_recipe(_selected_building_id, 1)
			elif town_core and town_core.try_pay_build_cost(_selected_building_id):
				target_slot.set_building(_selected_building_id)
				success = true
		else:
			if _map_layout_node and _source_slot_index < _map_layout_node.slots.size():
				var source_slot = _map_layout_node.slots[_source_slot_index]
				success = move_building_between_slots(source_slot, target_slot)
		
		if success:
			print("[GameScene] Success: %s on slot %d" % [_selected_building_id, target_slot.slot_index])
			if building_menu and building_menu.has_method("_update_affordability"):
				building_menu._update_affordability()
	else:
		if _source_slot_index != -1 and _map_layout_node:
			_map_layout_node.slots[_source_slot_index].sprite.modulate.a = 1.0
	
	_selected_building_id = ""
	_source_slot_index = -1
	if _ghost_building:
		_ghost_building.queue_free()
		_ghost_building = null

func cancel_drag() -> void:
	if _source_slot_index != -1 and _map_layout_node and _source_slot_index < _map_layout_node.slots.size():
		_map_layout_node.slots[_source_slot_index].sprite.modulate.a = 1.0
	_selected_building_id = ""
	_source_slot_index = -1
	if _ghost_building:
		_ghost_building.queue_free()
		_ghost_building = null

func _handle_seal_placement(target_slot: MapSlot) -> bool:
	var seal_registry := _seal_registry()
	var seal_def = seal_registry.get_seal(_selected_building_id) if seal_registry else null
	var current_seal = target_slot.current_seal_id
	
	var can_place = false
	if current_seal == "":
		can_place = true
	else:
		var current_def = seal_registry.get_seal(current_seal) if seal_registry else null
		if current_def:
			if seal_def.tier > current_def.tier:
				can_place = true
			elif seal_def.tier == current_def.tier and current_seal != _selected_building_id:
				can_place = true
			elif current_def.tier == 0 and seal_def.tier > 0:
				can_place = true
	
	if can_place:
		if seal_registry and seal_registry.can_afford_seal(_selected_building_id):
			var resource_core := _resource_core()
			if resource_core:
				for res in seal_def.cost:
					resource_core.consume_resource(res, seal_def.cost[res])
			target_slot.set_seal(_selected_building_id)
			return true
		else:
			print("Cannot afford seal")
	else:
		print("Cannot place seal here (downgrade, or same seal already active)")
	
	return false

func move_building_between_slots(source_slot, target_slot) -> bool:
	if source_slot == null or target_slot == null:
		return false
	if not source_slot.has_method("move_building_to_slot"):
		return false
	source_slot.move_building_to_slot(target_slot)
	if source_slot.sprite:
		source_slot.sprite.modulate.a = 1.0
	return true

func _find_slot_at_mouse(allow_occupied: bool):
	var mouse_pos = _game_scene.get_global_mouse_position()
	if _map_layout_node:
		for slot in _map_layout_node.slots:
			if not slot.is_building_slot:
				continue
			if not allow_occupied and slot.current_building_id != "":
				continue
			var slot_pos = slot.global_position
			var rect = Rect2(slot_pos - Vector2(50, 50), Vector2(100, 100))
			if rect.has_point(mouse_pos):
				return slot
	return null

func update_ghost_position() -> void:
	if _ghost_building:
		_ghost_building.global_position = _game_scene.get_global_mouse_position()
		var target_slot = _find_slot_at_mouse(false)
		if target_slot:
			_ghost_building.modulate = Color(1, 1, 1, 0.8)
		else:
			_ghost_building.modulate = Color(1, 1, 1, 0.5)

func has_ghost() -> bool:
	return _ghost_building != null

func get_selected_building_id() -> String:
	return _selected_building_id

func get_source_slot_index() -> int:
	return _source_slot_index
