extends SceneTree

const HeroOnFieldScript := preload("res://scripts/hero/HeroOnField.gd")
const HeroAnimationHelperScript := preload("res://scripts/hero/shared/HeroAnimationHelper.gd")
const HeroFieldAnimationsScript := preload("res://scripts/hero/components/HeroFieldAnimations.gd")


class FakeAnimations:
	extends HeroFieldAnimationsScript

	var calls: Array[String] = []
	var attack_locked: bool = false

	func update_animation(anim_name: String) -> void:
		calls.append(anim_name)

	func is_attack_animation_playing() -> bool:
		return attack_locked


func _init() -> void:
	call_deferred("_run_test")


func _build_default_only_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_frame("default", ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8)))
	return frames


func _run_test() -> void:
	var hero := HeroOnFieldScript.new()
	var walk_sprite := AnimatedSprite2D.new()
	walk_sprite.name = "AnimWalk"
	walk_sprite.sprite_frames = _build_default_only_frames()
	walk_sprite.visible = false
	hero.add_child(walk_sprite)

	var attack_sprite := AnimatedSprite2D.new()
	attack_sprite.name = "AnimAttack"
	attack_sprite.sprite_frames = _build_default_only_frames()
	attack_sprite.visible = true
	hero.add_child(attack_sprite)

	var animations := FakeAnimations.new()
	hero._animations = animations
	hero._animation_helper = HeroAnimationHelperScript.new()

	hero._update_animation("attack")
	if animations.calls != ["attack"]:
		push_error("[test_hero_on_field_shared_animation_path] HeroOnField must still delegate attack updates to its animation component")
		quit(1)
		return
	if not attack_sprite.visible or walk_sprite.visible or attack_sprite.animation != &"default" or not attack_sprite.is_playing():
		push_error("[test_hero_on_field_shared_animation_path] HeroOnField must normalize attack playback through shared helper fallback")
		quit(1)
		return

	walk_sprite.stop()
	attack_sprite.stop()
	hero._update_animation("idle")
	if animations.calls != ["attack", "idle"]:
		push_error("[test_hero_on_field_shared_animation_path] HeroOnField must delegate idle updates to its animation component")
		quit(1)
		return
	if not walk_sprite.visible or attack_sprite.visible or walk_sprite.animation != &"default" or not walk_sprite.is_playing():
		push_error("[test_hero_on_field_shared_animation_path] HeroOnField must normalize idle playback through shared helper fallback")
		quit(1)
		return

	hero.free()
	print("[test_hero_on_field_shared_animation_path] PASS")
	quit(0)
