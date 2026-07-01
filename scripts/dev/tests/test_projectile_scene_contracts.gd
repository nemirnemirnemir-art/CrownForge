extends SceneTree

const CONTRACTS := [
	["res://scenes/heroes/ballista.tscn", "res://scenes/projectiles/CannonProjectile.tscn"],
	["res://scenes/heroes/fire_mage.tscn", "res://scenes/projectiles/FireMageProjectile.tscn"],
	["res://scenes/heroes/lightning_mage.tscn", "res://scenes/projectiles/LightMageProjectile.tscn"],
	["res://scenes/heroes/slinger.tscn", "res://scenes/projectiles/StoneProjectile.tscn"],
	["res://scenes/heroes/crossbowman.tscn", "res://scenes/projectiles/CrossbowBoltProjectile.tscn"],
	["res://scenes/heroes/hunter.tscn", "res://scenes/projectiles/ArrowProjectile.tscn"],
	["res://scenes/heroes/musketeer.tscn", "res://scenes/projectiles/CrossbowBoltProjectile.tscn"],
	["res://scenes/heroes/catapult.tscn", "res://scenes/projectiles/CatapultBoulderProjectile.tscn"],
	["res://scenes/heroes/longbowman.tscn", "res://scenes/projectiles/ArrowProjectile.tscn"],
	["res://scenes/mobs/GoblinFireMage.tscn", "res://scenes/projectiles/GoblinFireMageProjectile.tscn"],
	["res://scenes/mobs/GoblinLightningMage.tscn", "res://scenes/projectiles/GoblinLightningMageProjectile.tscn"],
	["res://scenes/mobs/GoblinCrossbowman.tscn", "res://scenes/projectiles/CrossbowBoltProjectile.tscn"],
	["res://scenes/mobs/Gnoll.tscn", "res://scenes/projectiles/GnollBoneProjectile.tscn"]
]


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	for contract: Array in CONTRACTS:
		var scene_path := String(contract[0])
		var expected_projectile_path := String(contract[1])
		var packed := load(scene_path) as PackedScene
		if packed == null:
			push_error("[test_projectile_scene_contracts] failed to load %s" % scene_path)
			quit(1)
			return
		var unit := packed.instantiate()
		if unit == null:
			push_error("[test_projectile_scene_contracts] failed to instantiate %s" % scene_path)
			quit(1)
			return
		var projectile_scene = unit.get("projectile_scene")
		if projectile_scene == null:
			push_error("[test_projectile_scene_contracts] %s missing projectile_scene" % scene_path)
			quit(1)
			return
		if String(projectile_scene.resource_path) != expected_projectile_path:
			push_error("[test_projectile_scene_contracts] %s expected %s got %s" % [scene_path, expected_projectile_path, String(projectile_scene.resource_path)])
			quit(1)
			return

	print("[test_projectile_scene_contracts] PASS")
	quit(0)
