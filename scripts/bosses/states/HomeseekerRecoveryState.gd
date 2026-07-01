extends "res://scripts/mob/states/MobState.gd"

var _sprite: AnimatedSprite2D = null
var _fallback_left: float = 0.0

func enter() -> void:
	if not mob or not state_machine:
		return
	mob.velocity = Vector2.ZERO
	_fallback_left = 1.5
	if mob.has_method("play_boss_anim"):
		mob.play_boss_anim("recovery")
	_sprite = mob.get_node_or_null("AnimationSprite2D") as AnimatedSprite2D
	if _sprite:
		if _sprite.sprite_frames and _sprite.sprite_frames.has_animation("recovery"):
			var fc: int = _sprite.sprite_frames.get_frame_count("recovery")
			var sp: float = float(_sprite.sprite_frames.get_animation_speed("recovery"))
			if sp <= 0.01:
				sp = 10.0
			_fallback_left = maxf(0.4, float(fc) / sp + 0.2)
		if not _sprite.animation_finished.is_connected(_on_animation_finished):
			_sprite.animation_finished.connect(_on_animation_finished)

func update(delta: float) -> void:
	if not mob or not state_machine:
		return
	if mob.is_dead:
		state_machine.change_state("MobDeathState")
		return
	mob.velocity = Vector2.ZERO
	_fallback_left -= delta
	if _fallback_left <= 0.0:
		state_machine.change_state("HomeseekerWalkState")

func physics_update(_delta: float) -> void:
	if mob:
		mob.velocity = Vector2.ZERO

func exit() -> void:
	if _sprite and is_instance_valid(_sprite) and _sprite.animation_finished.is_connected(_on_animation_finished):
		_sprite.animation_finished.disconnect(_on_animation_finished)

func _on_animation_finished() -> void:
	if not mob or not state_machine:
		return
	if _sprite and _sprite.animation != "recovery":
		return
	state_machine.change_state("HomeseekerWalkState")
