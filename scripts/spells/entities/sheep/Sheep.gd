extends Node2D

## Sheep transformation visual - plays walk animation

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("walk"):
		anim.play("walk")
	elif anim and anim.sprite_frames and anim.sprite_frames.has_animation("default"):
		anim.play("default")
