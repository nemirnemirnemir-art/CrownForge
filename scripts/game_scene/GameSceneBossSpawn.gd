extends RefCounted
class_name GameSceneBossSpawn

const HomeseekerBossScene: PackedScene = preload("res://scenes/mobs/HomeseekerBoss.tscn")
const MinotaurBossScene: PackedScene = preload("res://scenes/mobs/MinotaurBoss.tscn")
const MinotaurFaceTex: Texture2D = preload("res://assets/characters/faces/bosses/Minotaur_face.png")

var _spawning_boss: bool = false
var _game_scene: Node = null
var _map_container: Node = null
var _boss_container: Node = null
var _boss_hp_bar: Node = null
var _homeseeker_arrival_overlay: Node = null
var _minotaur_arrival_overlay: Node = null

func initialize(game_scene: Node, map_container: Node, boss_container: Node, boss_hp_bar: Node, homeseeker_overlay: Node, minotaur_overlay: Node) -> void:
	_game_scene = game_scene
	_map_container = map_container
	_boss_container = boss_container
	_boss_hp_bar = boss_hp_bar
	_homeseeker_arrival_overlay = homeseeker_overlay
	_minotaur_arrival_overlay = minotaur_overlay

func spawn_homeseeker() -> void:
	if _spawning_boss:
		return
	for n in _game_scene.get_tree().get_nodes_in_group("boss"):
		if not is_instance_valid(n):
			continue
		if n is Mob and not (n as Mob).is_dead:
			return
	
	_spawning_boss = true
	_game_scene.call_deferred("_spawn_homeseeker_boss_sequence")

func spawn_minotaur() -> void:
	if _spawning_boss:
		return
	for n in _game_scene.get_tree().get_nodes_in_group("boss"):
		if not is_instance_valid(n):
			continue
		if n is Mob and not (n as Mob).is_dead:
			return
	
	_spawning_boss = true
	_game_scene.call_deferred("_spawn_minotaur_boss_sequence")

func spawn_homeseeker_sequence() -> void:
	var marker_service: Variant = _get_singleton("MapMarkerService")
	var battle_core: Variant = _get_singleton("BattleCore")

	if _homeseeker_arrival_overlay:
		_homeseeker_arrival_overlay.play()
		await _homeseeker_arrival_overlay.sequence_finished

	if HomeseekerBossScene == null:
		_spawning_boss = false
		return

	var boss_node := HomeseekerBossScene.instantiate()
	if boss_node == null:
		_spawning_boss = false
		return

	var container: Node = _boss_container
	if container == null:
		container = _map_container
	if container == null:
		container = _game_scene
	container.add_child(boss_node)

	var boss := boss_node as Node2D
	if boss and marker_service:
		boss.global_position = marker_service.get_portal_position() + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		if boss is HomeseekerBoss:
			var hb := boss as HomeseekerBoss
			hb.bridge_position = marker_service.get_bridge_position()
			hb.portal_position = marker_service.get_portal_position()
			hb.center_position = (hb.portal_position + hb.bridge_position) / 2.0
			hb.behavior_target_type = "bridge"

	if battle_core:
		battle_core.register_mob(boss_node)

	if _boss_hp_bar and _boss_hp_bar.has_method("set_boss"):
		_boss_hp_bar.set_boss(boss)

	_spawning_boss = false

func spawn_minotaur_sequence() -> void:
	var marker_service: Variant = _get_singleton("MapMarkerService")
	var battle_core: Variant = _get_singleton("BattleCore")

	if _minotaur_arrival_overlay:
		_minotaur_arrival_overlay.play()
		await _minotaur_arrival_overlay.sequence_finished

	if MinotaurBossScene == null:
		_spawning_boss = false
		return

	var boss_node := MinotaurBossScene.instantiate()
	if boss_node == null:
		_spawning_boss = false
		return

	var container: Node = _boss_container
	if container == null:
		container = _map_container
	if container == null:
		container = _game_scene
	container.add_child(boss_node)

	var boss := boss_node as Node2D
	if boss and marker_service:
		boss.global_position = marker_service.get_portal_position() + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		if "bridge_position" in boss_node:
			boss_node.bridge_position = marker_service.get_bridge_position()
		if "portal_position" in boss_node:
			boss_node.portal_position = marker_service.get_portal_position()
		if "center_position" in boss_node:
			boss_node.center_position = (marker_service.get_portal_position() + marker_service.get_bridge_position()) / 2.0
		if "behavior_target_type" in boss_node:
			boss_node.behavior_target_type = "bridge"

	if battle_core:
		battle_core.register_mob(boss_node)

	if _boss_hp_bar and _boss_hp_bar.has_method("set_boss"):
		_boss_hp_bar.set_boss(boss, "Minotaur", MinotaurFaceTex)

	_spawning_boss = false

func is_spawning() -> bool:
	return _spawning_boss

func _get_singleton(node_name: String) -> Variant:
	var tree := _game_scene.get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)
