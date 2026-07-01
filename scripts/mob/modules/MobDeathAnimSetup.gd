extends RefCounted
class_name MobDeathAnimSetup

## Ensures AnimDead node exists on the mob, creating one with a generic death
## animation if the scene does not provide one.

static var _cached_generic_death_frames: SpriteFrames = null


func setup_death_anim(mob: Node) -> void:
	var dead_node := mob.get_node_or_null("AnimDead") as AnimatedSprite2D
	if dead_node:
		return

	var walk_node := mob.get_node_or_null("AnimWalk") as AnimatedSprite2D
	dead_node = AnimatedSprite2D.new()
	dead_node.name = "AnimDead"
	dead_node.visible = false

	if walk_node:
		dead_node.position = walk_node.position
		dead_node.scale = walk_node.scale
		dead_node.offset = walk_node.offset
		dead_node.flip_h = walk_node.flip_h

	if _cached_generic_death_frames == null:
		var eff_scene: PackedScene = preload("res://scenes/effects/DeathEffect.tscn")
		var inst: Node = eff_scene.instantiate()
		var spr: AnimatedSprite2D = inst.get_node_or_null("AnimatedSprite2D")
		if spr and spr.sprite_frames:
			_cached_generic_death_frames = spr.sprite_frames

	if _cached_generic_death_frames:
		dead_node.sprite_frames = _cached_generic_death_frames
		if dead_node.sprite_frames.has_animation("default"):
			dead_node.animation = "default"

	mob.add_child(dead_node)
