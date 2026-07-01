extends SceneTree

const FIRE_MAGE_SCENE := preload("res://scenes/heroes/fire_mage.tscn")
const LIGHTNING_MAGE_SCENE := preload("res://scenes/heroes/lightning_mage.tscn")
const RAM_SCENE := preload("res://scenes/heroes/ram.tscn")
const FIRE_MAGE_PROJECTILE := preload("res://scenes/projectiles/FireMageProjectile.tscn")
const LIGHTNING_MAGE_PROJECTILE := preload("res://scenes/projectiles/LightMageProjectile.tscn")
const RAM_PROJECTILE := preload("res://scenes/projectiles/RamProjectile.tscn")


func _init() -> void:
	call_deferred("_run_test")


func _assert_projectile(scene: PackedScene, expected: PackedScene, label: String) -> bool:
	var unit := scene.instantiate()
	if unit == null:
		push_error("[test_existing_custom_projectile_bindings] failed to instantiate %s" % label)
		return false
	if unit.get("projectile_scene") != expected:
		push_error("[test_existing_custom_projectile_bindings] %s lost its explicit projectile binding" % label)
		return false
	return true


func _run_test() -> void:
	if not _assert_projectile(FIRE_MAGE_SCENE, FIRE_MAGE_PROJECTILE, "fire_mage"):
		quit(1)
		return
	if not _assert_projectile(LIGHTNING_MAGE_SCENE, LIGHTNING_MAGE_PROJECTILE, "lightning_mage"):
		quit(1)
		return
	if not _assert_projectile(RAM_SCENE, RAM_PROJECTILE, "ram"):
		quit(1)
		return

	print("[test_existing_custom_projectile_bindings] PASS")
	quit(0)
