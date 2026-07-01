extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if animated_sprite:
		# First, check if SpriteFrames is already set in the scene
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("default"):
			animated_sprite.play("default")
			animated_sprite.animation_finished.connect(_on_animation_finished)
			return
		
		# Try to load external SpriteFrames resource, if it exists
		var frames_path = "res://assets/vfx/effects/death/death_frames.tres"
		if ResourceLoader.exists(frames_path):
			var frames = load(frames_path) as SpriteFrames
			if frames and frames.has_animation("default"):
				animated_sprite.sprite_frames = frames
				animated_sprite.play("default")
				animated_sprite.animation_finished.connect(_on_animation_finished)
				return
		
		# Fallback: use static sprite if death.png exists
		var death_texture_path = "res://assets/vfx/effects/death.png"
		if ResourceLoader.exists(death_texture_path):
			var sprite = Sprite2D.new()
			sprite.texture = load(death_texture_path) as Texture2D
			add_child(sprite)
			get_tree().create_timer(0.5).timeout.connect(queue_free)
		else:
			# Final fallback: just wait and free
			get_tree().create_timer(0.5).timeout.connect(queue_free)

func _on_animation_finished() -> void:
	queue_free()
