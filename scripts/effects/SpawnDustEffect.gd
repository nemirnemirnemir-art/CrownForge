extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    # Ensure it's big enough to be visible and correctly centered
    scale = Vector2(2.0, 2.0)

    if sprite == null:
        print("[SpawnDustEffect] WARNING: AnimatedSprite2D node missing")
        queue_free()
        return

    if sprite.sprite_frames and sprite.sprite_frames.has_animation("default"):
        sprite.animation_finished.connect(_on_animation_finished)
        sprite.play("default")
        print("[SpawnDustEffect] Playing dust animation at %v" % global_position)
    else:
        print("[SpawnDustEffect] WARNING: No sprite frames found!")
        queue_free()

func _on_animation_finished() -> void:
    queue_free()
