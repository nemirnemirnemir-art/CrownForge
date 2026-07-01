extends Node2D

## Visual effect for skill 1 activation

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if sprite:
		sprite.scale = Vector2(0.5, 0.5)  # Make it smaller
		sprite.z_index = 100  # Ensure it's visible above other elements

func set_texture(texture: Texture2D) -> void:
	if sprite and texture:
		sprite.texture = texture
		# print("[Skill1Effect] ✅ Texture set: %s" % str(texture != null))
	else:
		# print("[Skill1Effect] ⚠️ Cannot set texture: sprite=%s, texture=%s" % [str(sprite != null), str(texture != null)])
		pass

func play_and_remove() -> void:
	# Animate effect: rotation for 2 seconds
	var tween = create_tween()
	tween.set_loops()  # Бесконечное вращение
	tween.tween_property(self, "rotation", rotation + TAU, 1.0)  # Полный оборот за 1 секунду
	
	# Ждем 2 секунды, затем удаляем
	await get_tree().create_timer(2.0).timeout
	tween.kill()  # Останавливаем вращение
	queue_free()

