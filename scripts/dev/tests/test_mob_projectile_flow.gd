extends SceneTree

const MobProjectileFlowScript := preload("res://scripts/mob/modules/MobProjectileFlow.gd")


class FakeProjectile:
	extends Node2D

	var setup_calls: Array = []
	var speed: float = 333.0
	var spin_speed_deg: float = 9.0

	func setup(dir: Vector2, damage: float, target, owner) -> void:
		setup_calls.append([dir, damage, target, owner])


class FakeParent:
	extends Node2D


class FakeCombat:
	extends RefCounted

	var target = null

	func get_combat_target():
		return target


class FakeRuntime:
	extends RefCounted

	var wall = null

	func get_singleton(_name: String):
		return null


class FakeMob:
	extends Node2D

	var projectile_scene: PackedScene = null
	var combat = FakeCombat.new()
	var runtime_bridge = FakeRuntime.new()
	var projectile_speed: float = 420.0
	var projectile_spin_speed_deg: float = 15.0
	var mob_damage: float = 9.0


class FakeMobWithoutProjectileOverrides:
	extends Node2D

	var projectile_scene: PackedScene = null
	var combat = FakeCombat.new()
	var runtime_bridge = FakeRuntime.new()
	var mob_damage: float = 7.0


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MobProjectileFlowScript.new()
	if flow == null:
		push_error("[test_mob_projectile_flow] failed to instantiate helper")
		quit(1)
		return

	var mob := FakeMob.new()
	var parent := FakeParent.new()
	get_root().add_child(parent)
	parent.add_child(mob)
	var projectile_scene := PackedScene.new()
	var projectile := FakeProjectile.new()
	projectile_scene.pack(projectile)
	mob.projectile_scene = projectile_scene
	mob.combat.target = Node2D.new()

	var spawned = flow.fire_projectile(mob, Vector2(200, 100))
	if spawned == null:
		push_error("[test_mob_projectile_flow] expected projectile instance")
		quit(1)
		return
	if spawned.setup_calls.is_empty():
		push_error("[test_mob_projectile_flow] projectile setup not forwarded")
		quit(1)
		return
	if absf(spawned.speed - 420.0) > 0.01 or absf(spawned.spin_speed_deg - 15.0) > 0.01:
		push_error("[test_mob_projectile_flow] projectile speed/spin mismatch")
		quit(1)
		return

	var fallback_mob := FakeMobWithoutProjectileOverrides.new()
	parent.add_child(fallback_mob)
	fallback_mob.projectile_scene = projectile_scene
	fallback_mob.combat.target = Node2D.new()

	var fallback_spawned = flow.fire_projectile(fallback_mob, Vector2(240, 120))
	if fallback_spawned == null:
		push_error("[test_mob_projectile_flow] expected projectile instance even without optional mob projectile overrides")
		quit(1)
		return
	if fallback_spawned.setup_calls.is_empty():
		push_error("[test_mob_projectile_flow] projectile setup must still run without optional mob projectile overrides")
		quit(1)
		return
	if absf(fallback_spawned.speed - 333.0) > 0.01 or absf(fallback_spawned.spin_speed_deg - 9.0) > 0.01:
		push_error("[test_mob_projectile_flow] projectile defaults must remain unchanged when mob has no projectile override fields")
		quit(1)
		return

	print("[test_mob_projectile_flow] PASS")
	quit(0)
