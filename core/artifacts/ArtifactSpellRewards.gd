extends RefCounted
class_name ArtifactSpellRewards

const SPELL_CONFIGS_DIR: String = "res://resources/spells/configs"
const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")

static func add_spell_with_panel_fallback(spell_id: String, amount: int) -> void:
	if spell_id == "" or amount <= 0:
		return
	
	var panel_added := 0
	var spell_panel := _get_spell_panel()
	if spell_panel != null and spell_panel.has_method("add_spell"):
		var config := PathRegistryScript.load_spell_config(spell_id)
		if config != null:
			for _i in range(amount):
				if bool(spell_panel.call("add_spell", config)):
					panel_added += 1
	
	if panel_added >= amount:
		return
	
	var spell_core := _get_spell_core()
	if spell_core != null and spell_core.has_method("add_spell"):
		spell_core.call("add_spell", spell_id, amount - panel_added)

static func add_random_spells(amount: int, include_legendary: bool) -> void:
	if amount <= 0:
		return
	var pool := collect_spell_ids(include_legendary)
	if pool.is_empty():
		return
	for _i in range(amount):
		var spell_id: String = pool[randi() % pool.size()]
		add_spell_with_panel_fallback(spell_id, 1)

static func queue_fixed_spell_rewards(spell_id: String, amount: int) -> void:
	if spell_id == "" or amount <= 0:
		return
	var game_scene := _get_game_scene()
	if game_scene != null and game_scene.has_method("enqueue_spell_grant_reward"):
		game_scene.call("enqueue_spell_grant_reward", spell_id, amount)
		return
	add_spell_with_panel_fallback(spell_id, amount)

static func queue_spell_choice_rewards(pending: int, pending_legendary: int, count: int, legendary_only: bool) -> Dictionary:
	if count <= 0:
		return {"pending": pending, "pending_legendary": pending_legendary}
	if legendary_only:
		return {"pending": pending, "pending_legendary": pending_legendary + count}
	return {"pending": pending + count, "pending_legendary": pending_legendary}

static func process_pending_spell_rewards(pending: int, pending_legendary: int) -> Dictionary:
	if pending <= 0 and pending_legendary <= 0:
		return {"pending": pending, "pending_legendary": pending_legendary, "opened": false}
	
	var game_scene := _get_game_scene()
	if game_scene == null:
		return {"pending": pending, "pending_legendary": pending_legendary, "opened": false}
	if _is_spell_reward_menu_visible(game_scene):
		return {"pending": pending, "pending_legendary": pending_legendary, "opened": false}
	
	if pending > 0:
		if game_scene.has_method("open_reward_menu_spells"):
			game_scene.call("open_reward_menu_spells")
			if _is_spell_reward_menu_visible(game_scene):
				return {"pending": pending - 1, "pending_legendary": pending_legendary, "opened": true}
		return {"pending": pending, "pending_legendary": pending_legendary, "opened": false}
	
	if pending_legendary > 0:
		if game_scene.has_method("open_reward_menu_legendary_spells"):
			game_scene.call("open_reward_menu_legendary_spells")
			if _is_spell_reward_menu_visible(game_scene):
				return {"pending": pending, "pending_legendary": pending_legendary - 1, "opened": true}
	
	return {"pending": pending, "pending_legendary": pending_legendary, "opened": false}

static func collect_spell_ids(include_legendary: bool) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(SPELL_CONFIGS_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if (not dir.current_is_dir()) and file.ends_with(".tres"):
			var spell_id := file.replace(".tres", "")
			if include_legendary or not spell_id.begins_with("legendary_"):
				out.append(spell_id)
		file = dir.get_next()
	dir.list_dir_end()
	return out

static func _get_game_scene() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("game_scene")

static func _is_spell_reward_menu_visible(game_scene: Node) -> bool:
	var regular := game_scene.get_node_or_null("UILayer/RewardMenuSpells")
	if regular != null and regular is CanvasItem and (regular as CanvasItem).visible:
		return true
	var legendary := game_scene.get_node_or_null("UILayer/RewardMenuLegendarySpells")
	if legendary != null and legendary is CanvasItem and (legendary as CanvasItem).visible:
		return true
	return false

static func _get_spell_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("SpellCore")

static func _get_spell_panel() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("spell_panel")
