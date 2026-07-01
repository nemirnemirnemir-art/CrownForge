extends SceneTree

const HeroAnimationHelperScript := preload("res://scripts/hero/shared/HeroAnimationHelper.gd")
const SmallBonesScene := preload("res://scenes/heroes/small_bones.tscn")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var helper = HeroAnimationHelperScript.new()
	if helper == null:
		push_error("[test_hero_animation_helper] failed to instantiate helper")
		quit(1)
		return

	var frames := SpriteFrames.new()
	frames.add_animation("walk")
	frames.add_frame("walk", ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8)))
	frames.add_animation("idle")
	frames.add_frame("idle", ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8)))

	var walk_sprite := AnimatedSprite2D.new()
	walk_sprite.sprite_frames = frames
	var attack_sprite := AnimatedSprite2D.new()
	attack_sprite.sprite_frames = frames
	attack_sprite.visible = true

	helper.play_sprite_animation(walk_sprite, "missing", "idle")
	if walk_sprite.animation != &"idle":
		push_error("[test_hero_animation_helper] helper must fallback to secondary animation")
		quit(1)
		return

	helper.update_animation("attack", walk_sprite, attack_sprite)
	if attack_sprite.animation != &"walk" or not attack_sprite.visible or walk_sprite.visible:
		push_error("[test_hero_animation_helper] attack update must use fallback animation and switch visible sprite")
		quit(1)
		return

	var empty_sprite := AnimatedSprite2D.new()
	helper.play_sprite_animation(empty_sprite, "attack", "idle")
	if empty_sprite.is_playing():
		push_error("[test_hero_animation_helper] helper must ignore sprites without frames")
		quit(1)
		return

	var small_bones := SmallBonesScene.instantiate()
	var small_bones_walk := small_bones.get_node_or_null("AnimWalk") as AnimatedSprite2D
	var small_bones_attack := small_bones.get_node_or_null("AnimAttack") as AnimatedSprite2D
	if small_bones_walk == null or small_bones_attack == null:
		push_error("[test_hero_animation_helper] small_bones scene must expose AnimWalk and AnimAttack")
		quit(1)
		return
	if small_bones_walk.sprite_frames == null or small_bones_attack.sprite_frames == null:
		push_error("[test_hero_animation_helper] small_bones scene must provide sprite frames for both animation nodes")
		quit(1)
		return
	if not small_bones_walk.sprite_frames.has_animation("default") or not small_bones_attack.sprite_frames.has_animation("default"):
		push_error("[test_hero_animation_helper] small_bones scene must keep default animation on both nodes")
		quit(1)
		return
	if small_bones_walk.sprite_frames.has_animation("walk") or small_bones_walk.sprite_frames.has_animation("idle"):
		push_error("[test_hero_animation_helper] small_bones walk node should rely on default-only fallback")
		quit(1)
		return
	if small_bones_attack.sprite_frames.has_animation("attack") or small_bones_attack.sprite_frames.has_animation("walk"):
		push_error("[test_hero_animation_helper] small_bones attack node should rely on default-only fallback")
		quit(1)
		return

	small_bones_walk.stop()
	small_bones_attack.stop()
	helper.update_animation("walk", small_bones_walk, small_bones_attack)
	if not small_bones_walk.visible or small_bones_attack.visible or small_bones_walk.animation != &"default" or not small_bones_walk.is_playing():
		push_error("[test_hero_animation_helper] walk update must fallback to default for small_bones walk node")
		quit(1)
		return

	small_bones_walk.stop()
	small_bones_attack.stop()
	helper.update_animation("attack", small_bones_walk, small_bones_attack)
	if not small_bones_attack.visible or small_bones_walk.visible or small_bones_attack.animation != &"default" or not small_bones_attack.is_playing():
		push_error("[test_hero_animation_helper] attack update must fallback to default for small_bones attack node")
		quit(1)
		return

	small_bones_walk.stop()
	small_bones_attack.stop()
	helper.update_animation("idle", small_bones_walk, small_bones_attack)
	if not small_bones_walk.visible or small_bones_attack.visible or small_bones_walk.animation != &"default" or not small_bones_walk.is_playing():
		push_error("[test_hero_animation_helper] idle update must fallback to default for small_bones walk node")
		quit(1)
		return

	walk_sprite.free()
	attack_sprite.free()
	empty_sprite.free()
	small_bones.free()

	print("[test_hero_animation_helper] PASS")
	quit(0)
