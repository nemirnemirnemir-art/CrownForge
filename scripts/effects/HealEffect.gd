extends Node2D
## HealEffect - Visual effect spawned when a unit is healed

@onready var anim: AnimatedSprite2D = get_node_or_null("AnimHeal")

func _ready() -> void:
	if anim:
		if anim.sprite_frames:
			var anim_name := ""
			if anim.sprite_frames.has_animation("heal"):
				anim_name = "heal"
			elif anim.sprite_frames.has_animation("default"):
				anim_name = "default"
			if anim_name != "":
				if anim.sprite_frames.has_method("set_animation_loop"):
					anim.sprite_frames.set_animation_loop(anim_name, false)
				anim.play(anim_name)
		get_tree().create_timer(0.5).timeout.connect(_on_timeout)
	else:
		push_warning("[HealEffect] AnimHeal node not found, self-destructing")
		queue_free()

func _on_animation_finished() -> void:
	queue_free()

func _on_timeout() -> void:
	queue_free()
