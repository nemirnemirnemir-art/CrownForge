extends RefCounted
class_name MobAnimations

## Animations module for Mob
## Handles all animation-related logic

var mob: Mob
var animation_sprite: AnimatedSprite2D
var animation_dead: AnimatedSprite2D
var attack_component: Node
var anim_walk: AnimatedSprite2D
var anim_attack: AnimatedSprite2D

func setup(mob_ref: Mob, anim_sprite: AnimatedSprite2D, anim_dead: AnimatedSprite2D = null, attack_comp: Node = null, dual_walk: AnimatedSprite2D = null, dual_attack: AnimatedSprite2D = null) -> void:
	mob = mob_ref
	animation_sprite = anim_sprite
	animation_dead = anim_dead
	attack_component = attack_comp
	anim_walk = dual_walk
	anim_attack = dual_attack
	
	# Connect signals for both primary and dual attack sprite
	if animation_sprite:
		_connect_signals(animation_sprite)
	if anim_attack:
		_connect_signals(anim_attack)
	if anim_walk:
		_connect_signals(anim_walk)

func _connect_signals(sprite: AnimatedSprite2D) -> void:
	if not sprite.frame_changed.is_connected(_on_animation_frame_changed):
		sprite.frame_changed.connect(_on_animation_frame_changed)
	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)

func play_walk() -> void:
	_play_anim("walk")

func play_idle() -> void:
	_play_anim("idle")

func play_attack() -> void:
	_play_anim("attack")

func play_death() -> void:
	if not mob:
		return

	if animation_sprite:
		animation_sprite.visible = false
	if anim_walk:
		anim_walk.visible = false
	if anim_attack:
		anim_attack.visible = false

	var dead_node := mob.get_node_or_null("AnimDead") as AnimatedSprite2D
	if dead_node:
		dead_node.visible = true
		if dead_node.sprite_frames:
			if dead_node.sprite_frames.has_animation("dead"):
				dead_node.play("dead")
			elif dead_node.sprite_frames.has_animation("death"):
				dead_node.play("death")
			elif dead_node.sprite_frames.has_animation("default"):
				dead_node.play("default")
		return
	
	if animation_dead:
		animation_dead.visible = true
		animation_dead.play("default")

func _play_anim(anim_name: String) -> void:
	# Dual sprite logic
	if anim_walk and anim_attack:
		if anim_name == "walk":
			anim_walk.visible = true
			anim_attack.visible = false
			if anim_walk.sprite_frames and anim_walk.sprite_frames.has_animation("walk"):
				anim_walk.play("walk")
			return
		elif anim_name == "attack":
			anim_walk.visible = false
			anim_attack.visible = true
			if anim_attack.sprite_frames and anim_attack.sprite_frames.has_animation("attack"):
				anim_attack.play("attack")
			return

	# Fallback/Legacy logic
	if not animation_sprite:
		return
	
	if animation_sprite.sprite_frames and animation_sprite.sprite_frames.has_animation(anim_name):
		animation_sprite.play(anim_name)

func _on_animation_frame_changed() -> void:
	if not attack_component:
		return
	
	# Handle both legacy and dual sprite
	var active_sprite: AnimatedSprite2D = null
	if anim_attack and anim_attack.visible:
		active_sprite = anim_attack
	elif animation_sprite and animation_sprite.visible:
		active_sprite = animation_sprite
		
	if not active_sprite or active_sprite.animation != "attack":
		return
		
	if not attack_component.has_method("is_attacking") or not attack_component.is_attacking():
		return
	
	var frames_count = active_sprite.sprite_frames.get_frame_count("attack")
	var current_frame = active_sprite.frame
	
	var start_f = int(frames_count * (attack_component.hit_start_time / attack_component.attack_duration))
	var end_f = int(frames_count * (attack_component.hit_end_time / attack_component.attack_duration))
	
	if current_frame == start_f:
		attack_component.begin_hit_window()
	elif current_frame == end_f:
		attack_component.end_hit_window()

func _on_animation_finished() -> void:
	# Handle both legacy and dual sprite
	var active_sprite: AnimatedSprite2D = null
	if anim_attack and anim_attack.visible:
		active_sprite = anim_attack
	elif animation_sprite and animation_sprite.visible:
		active_sprite = animation_sprite
		
	if not active_sprite:
		return
	
	if active_sprite.animation == "attack":
		if attack_component:
			attack_component.finish_from_animation()
