extends SceneTree

const BALLISTA_SCENE := preload("res://scenes/heroes/ballista.tscn")
const CANNON_PROJECTILE_SCENE := preload("res://scenes/projectiles/CannonProjectile.tscn")
const BALLISTA_CONFIG := preload("res://data/units/ballista.tres")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var ballista := BALLISTA_SCENE.instantiate()
	if ballista == null:
		push_error("[test_ballista_projectile_setup] failed to instantiate ballista scene")
		quit(1)
		return

	if ballista.get("projectile_scene") != CANNON_PROJECTILE_SCENE:
		push_error("[test_ballista_projectile_setup] ballista must use CannonProjectile scene")
		quit(1)
		return

	if String(BALLISTA_CONFIG.get("projectile_type")) == "arrow":
		push_error("[test_ballista_projectile_setup] ballista config must not advertise plain arrow projectile type")
		quit(1)
		return

	print("[test_ballista_projectile_setup] PASS")
	quit(0)
