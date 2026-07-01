extends SceneTree


const PROJECTILE_SCENE_PATHS := [
	"res://scenes/projectiles/ArrowProjectile.tscn",
	"res://scenes/projectiles/StoneProjectile.tscn",
	"res://scenes/projectiles/CrossbowBoltProjectile.tscn",
	"res://scenes/projectiles/CatapultBoulderProjectile.tscn",
	"res://scenes/projectiles/CannonProjectile.tscn",
	"res://scenes/projectiles/FireMageProjectile.tscn",
	"res://scenes/projectiles/LightMageProjectile.tscn",
	"res://scenes/projectiles/GoblinFireMageProjectile.tscn",
	"res://scenes/projectiles/GoblinLightningMageProjectile.tscn",
	"res://scenes/projectiles/GnollBoneProjectile.tscn",
	"res://scenes/projectiles/RamProjectile.tscn",
	"res://scenes/projectiles/Projectile.tscn"
]


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	for path in PROJECTILE_SCENE_PATHS:
		var packed := load(path) as PackedScene
		if packed == null:
			push_error("[test_projectile_scene_files] failed to load %s" % path)
			quit(1)
			return
		var projectile := packed.instantiate()
		if projectile == null:
			push_error("[test_projectile_scene_files] failed to instantiate %s" % path)
			quit(1)
			return
		if not projectile.has_method("setup"):
			push_error("[test_projectile_scene_files] %s missing setup()" % path)
			quit(1)
			return
		if projectile.get_node_or_null("CollisionShape2D") == null:
			push_error("[test_projectile_scene_files] %s missing CollisionShape2D" % path)
			quit(1)
			return
		var animated := projectile.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		var sprite := projectile.get_node_or_null("Sprite2D") as Sprite2D
		if animated == null and sprite == null:
			push_error("[test_projectile_scene_files] %s missing visual node" % path)
			quit(1)
			return
		if animated != null and animated.sprite_frames == null:
			push_error("[test_projectile_scene_files] %s AnimatedSprite2D missing sprite_frames" % path)
			quit(1)
			return
		if sprite != null and sprite.texture == null:
			push_error("[test_projectile_scene_files] %s Sprite2D missing texture" % path)
			quit(1)
			return

	print("[test_projectile_scene_files] PASS")
	quit(0)
