extends RefCounted
class_name HeroAnimationHelper


func resolve_animation_name(sprite: AnimatedSprite2D, primary_name: String, fallback_name: String = "") -> StringName:
	if sprite == null or sprite.sprite_frames == null:
		return &""
	if sprite.sprite_frames.has_animation(primary_name):
		return StringName(primary_name)
	if fallback_name != "" and sprite.sprite_frames.has_animation(fallback_name):
		return StringName(fallback_name)
	if sprite.sprite_frames.has_animation("default"):
		return &"default"
	return &""


func play_sprite_animation(sprite: AnimatedSprite2D, primary_name: String, fallback_name: String = "") -> void:
	var resolved_name := resolve_animation_name(sprite, primary_name, fallback_name)
	if resolved_name == &"":
		return
	sprite.play(resolved_name)


func needs_dual_sprite_fallback(anim_name: String, anim_walk: AnimatedSprite2D, anim_attack: AnimatedSprite2D) -> bool:
	var resolved_name := &""
	match anim_name:
		"walk":
			resolved_name = resolve_animation_name(anim_walk, "walk", "idle")
			return resolved_name != &"" and resolved_name != &"walk"
		"attack":
			resolved_name = resolve_animation_name(anim_attack, "attack", "walk")
			return resolved_name != &"" and resolved_name != &"attack"
		"idle":
			resolved_name = resolve_animation_name(anim_walk, "idle", "walk")
			return resolved_name == &"default"
	return false


func update_animation(anim_name: String, anim_walk: AnimatedSprite2D, anim_attack: AnimatedSprite2D) -> void:
	if anim_name == "walk":
		if anim_walk != null:
			anim_walk.visible = true
			play_sprite_animation(anim_walk, "walk", "idle")
		if anim_attack != null:
			anim_attack.visible = false
		return
	if anim_name == "attack":
		if anim_attack != null:
			anim_attack.visible = true
			play_sprite_animation(anim_attack, "attack", "walk")
		if anim_walk != null:
			anim_walk.visible = false
		return
	if anim_name == "idle":
		if anim_walk != null:
			anim_walk.visible = true
			play_sprite_animation(anim_walk, "idle", "walk")
		if anim_attack != null:
			anim_attack.visible = false
