extends Node2D

class_name GoldDropEffect

## Gold Drop Effect
# Handles the visual animation of gold dropping and adding it to the economy.
# Must be instantiated as a child of the scene root (not the dying mob).

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const GOLD_POPUP_SCENE = preload("res://core/effects/GoldPopup.tscn")

var gold_amount: int = 0
var _has_triggered: bool = false

func setup(amount: int) -> void:
	gold_amount = amount

func _ready() -> void:
	# Ensure we play the default animation
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("default"):
			animated_sprite.play("default")
		else:
			# Fallback: play first available
			var anims = animated_sprite.sprite_frames.get_animation_names()
			if anims.size() > 0:
				animated_sprite.play(anims[0])
	
	# Connect signal to detect when animation finishes
	if animated_sprite:
		if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)
	else:
		# If no sprite, finish immediately (safety)
		call_deferred("_on_animation_finished")

func _on_animation_finished() -> void:
	if _has_triggered:
		return
	_has_triggered = true
	
	# Add gold to economy
	if EconomyCore:
		var mult: float = 1.0
		if SkillCore and SkillCore.has_method("get_gold_gain_multiplier"):
			mult = float(SkillCore.get_gold_gain_multiplier())
		EconomyCore.add_gold(float(gold_amount) * mult)
	
	# Show floating number popup
	if GOLD_POPUP_SCENE:
		var popup = GOLD_POPUP_SCENE.instantiate()
		if popup.has_method("setup"):
			popup.setup(gold_amount)
		
		# Add to parent (world/map)
		if get_parent():
			get_parent().add_child(popup)
			# Position it slightly above the coin
			popup.global_position = global_position + Vector2(0, -20)
	
	# Cleanup
	queue_free()
