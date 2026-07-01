extends "res://scripts/mob/states/MobState.gd"

var _time_left: float = 0.2

func enter() -> void:
	if not mob:
		return

	mob.velocity = Vector2.ZERO
	if mob.has_method("play_gnoll_anim"):
		mob.play_gnoll_anim("hit")

	_time_left = 0.2
	var body := mob.get_node_or_null("AnimationSprite2D") as AnimatedSprite2D
	if body and body.sprite_frames and body.sprite_frames.has_animation("hit"):
		var fc := float(body.sprite_frames.get_frame_count("hit"))
		var sp := float(body.sprite_frames.get_animation_speed("hit"))
		if sp > 0.01 and fc > 0.0:
			_time_left = maxf(0.12, fc / sp)

func update(delta: float) -> void:
	if not mob or not state_machine:
		return
	if mob.is_dead:
		state_machine.change_state("MobDeathState")
		return

	mob.velocity = Vector2.ZERO
	_time_left -= delta
	if _time_left <= 0.0:
		state_machine.change_state("GnollWalkState")

func physics_update(_delta: float) -> void:
	if mob:
		mob.velocity = Vector2.ZERO
