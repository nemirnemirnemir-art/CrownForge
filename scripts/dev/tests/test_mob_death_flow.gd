extends SceneTree

const MobDeathFlowScript := preload("res://scripts/mob/modules/MobDeathFlow.gd")


class FakeAnim:
	extends Node2D

	var sprite_frames := SpriteFrames.new()
	var played: Array[String] = []

	func _init() -> void:
		if not sprite_frames.has_animation("default"):
			sprite_frames.add_animation("default")
		sprite_frames.add_frame("default", AtlasTexture.new())

	func play_anim(name: String) -> void:
		played.append(name)


class FakeShadow:
	extends Node2D


class FakeCorpseSpawner:
	extends RefCounted

	var calls: Array = []

	func spawn(parent_node: Node, position: Vector2) -> Variant:
		calls.append([parent_node, position])
		return null


class FakeHealth:
	extends RefCounted

	var is_dead: bool = false
	var die_calls: int = 0

	func die() -> void:
		is_dead = true
		die_calls += 1


class FakeAttackComponent:
	extends RefCounted

	var cancel_calls: int = 0

	func cancel_attack() -> void:
		cancel_calls += 1


class FakeRuntimeBridge:
	extends RefCounted

	var unregister_calls: int = 0

	func unregister_from_battle_core() -> void:
		unregister_calls += 1


class FakeMob:
	extends Node2D

	var queued: bool = false
	var health: FakeHealth = FakeHealth.new()
	var play_death_calls: int = 0
	var cleanup_calls: int = 0

	func _init() -> void:
		add_to_group("enemy")

	func _exit_tree() -> void:
		queued = true

	func play_death() -> void:
		play_death_calls += 1

	func _on_death_cleanup() -> void:
		cleanup_calls += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MobDeathFlowScript.new()
	if flow == null:
		push_error("[test_mob_death_flow] failed to instantiate helper")
		quit(1)
		return

	var mob := FakeMob.new()
	var parent_node := Node2D.new()
	get_root().add_child(parent_node)
	parent_node.add_child(mob)
	mob.global_position = Vector2(123.0, 456.0)
	var shadow := FakeShadow.new()
	mob.add_child(shadow)
	var walk := FakeAnim.new()
	mob.add_child(walk)
	var dead := FakeAnim.new()
	dead.name = "AnimDead"
	mob.add_child(dead)
	var aggro_area := Area2D.new()
	aggro_area.monitoring = true
	var hurtbox := Area2D.new()
	hurtbox.monitoring = true
	var hitbox := Area2D.new()
	hitbox.monitoring = true
	var attack_component := FakeAttackComponent.new()
	var runtime_bridge := FakeRuntimeBridge.new()

	flow.setup(mob)
	flow.on_died(shadow, walk, null, null, dead, null)
	if shadow.visible:
		push_error("[test_mob_death_flow] shadow must hide on death")
		quit(1)
		return
	if not dead.visible or dead.played.is_empty():
		push_error("[test_mob_death_flow] death animation not started")
		quit(1)
		return
	if not flow.has_method("set_corpse_spawn_callable") or not flow.has_method("try_spawn_corpse"):
		push_error("[test_mob_death_flow] death flow must own corpse spawn helper contract")
		quit(1)
		return
	var spawner := FakeCorpseSpawner.new()
	flow.set_corpse_spawn_callable(Callable(spawner, "spawn"))
	flow.execute_die(mob, aggro_area, hurtbox, hitbox, attack_component, runtime_bridge)
	if spawner.calls.size() != 1 or spawner.calls[0][0] != parent_node or Vector2(spawner.calls[0][1]).distance_to(mob.global_position) > 0.01:
		push_error("[test_mob_death_flow] corpse spawn via execute_die mismatch")
		quit(1)
		return
	if mob.health.die_calls != 1 or mob.play_death_calls != 1:
		push_error("[test_mob_death_flow] execute_die must trigger health death and death animation")
		quit(1)
		return
	if aggro_area.monitoring or hurtbox.monitoring or hitbox.monitoring or attack_component.cancel_calls != 1:
		push_error("[test_mob_death_flow] execute_die must disable combat components")
		quit(1)
		return
	if mob.is_in_group("enemy") or runtime_bridge.unregister_calls != 1:
		push_error("[test_mob_death_flow] execute_die cleanup mismatch")
		quit(1)
		return
	var mob_ref: WeakRef = weakref(mob)
	flow.on_death_animation_finished()
	await process_frame
	if mob_ref.get_ref() != null:
		push_error("[test_mob_death_flow] death finish must queue free")
		quit(1)
		return

	print("[test_mob_death_flow] PASS")
	quit(0)
