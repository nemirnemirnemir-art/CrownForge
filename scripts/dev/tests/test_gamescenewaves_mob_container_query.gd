extends SceneTree

const MobContainerQueryScript := preload("res://scripts/game_scene/modules/MobContainerQuery.gd")
const GoblinSwordsmanScene := preload("res://scenes/mobs/GoblinSwordsman.tscn")


class NonMobNode:
	extends Node2D


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var query = MobContainerQueryScript.new()
	if query == null:
		push_error("[test_gamescenewaves_mob_container_query] failed to instantiate helper")
		quit(1)
		return

	var container := Node2D.new()
	get_root().add_child(container)
	var alive_mob: Mob = GoblinSwordsmanScene.instantiate() as Mob
	var dead_mob: Mob = GoblinSwordsmanScene.instantiate() as Mob
	var other := NonMobNode.new()
	container.add_child(alive_mob)
	container.add_child(dead_mob)
	container.add_child(other)
	await process_frame
	dead_mob.health.is_dead = true

	var alive: Array = query.get_alive_mobs(container)
	if alive.size() != 1 or alive[0] != alive_mob:
		push_error("[test_gamescenewaves_mob_container_query] alive filter mismatch")
		quit(1)
		return

	query.set_wall_attack_stop_distance(container, 120.0)
	if absf(alive_mob.get_wall_attack_stand_off() - (120.0 + alive_mob.get_wall_front_offset_x())) > 0.01:
		push_error("[test_gamescenewaves_mob_container_query] alive mob wall distance propagation mismatch")
		quit(1)
		return
	if absf(dead_mob.get_wall_attack_stand_off() - (120.0 + dead_mob.get_wall_front_offset_x())) > 0.01:
		push_error("[test_gamescenewaves_mob_container_query] wall distance propagation mismatch")
		quit(1)
		return

	query.clear_mobs(container)
	await process_frame
	if is_instance_valid(alive_mob) or is_instance_valid(dead_mob) or not is_instance_valid(other):
		push_error("[test_gamescenewaves_mob_container_query] clear mismatch")
		quit(1)
		return

	print("[test_gamescenewaves_mob_container_query] PASS")
	quit(0)
