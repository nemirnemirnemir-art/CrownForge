extends SpellEffect

## Meteorite spell - single impact dealing 110 damage

@onready var meteor_anim: AnimatedSprite2D = $MeteorAnim
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D

const METEOR_DAMAGE: float = 110.0

var _damaged_enemies: Dictionary = {}

signal damage_dealt(position: Vector2, damage: float)

func execute_effect() -> void:
	if not damage_area or not damage_shape:
		push_error("[MeteoriteEffect] Missing required nodes")
		queue_free()
		return
	
	if config:
		var shape := CircleShape2D.new()
		var base_radius := config.target_radius if config.target_radius > 0 else 50.0
		shape.radius = get_scaled_radius(base_radius)
		damage_shape.shape = shape
	
	# Play impact animation
	if meteor_anim and meteor_anim.sprite_frames:
		if meteor_anim.sprite_frames.has_animation("impact"):
			meteor_anim.play("impact")
		elif meteor_anim.sprite_frames.has_animation("default"):
			meteor_anim.play("default")
	
	# Wait one frame for physics
	await get_tree().process_frame
	
	# Deal damage
	_deal_damage()
	
	# Wait for animation then cleanup
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _deal_damage() -> void:
	if not damage_area:
		return

	var base_damage := METEOR_DAMAGE
	if config and config.damage > 0.0:
		base_damage = float(config.damage)
	var damage := get_scaled_damage(base_damage)
	
	var bodies: Array[Node2D] = damage_area.get_overlapping_bodies()
	
	for body in bodies:
		if _damaged_enemies.has(body):
			continue
		
		if not body.is_in_group("enemy") and not body.is_in_group("mobs"):
			continue
		
		var hurtbox = body.get_node_or_null("Hurtbox")
		if hurtbox and hurtbox.has_method("apply_hit"):
			var attack_id: int = Time.get_ticks_msec()
			hurtbox.apply_hit(damage, self, attack_id)
			_damaged_enemies[body] = true
			damage_dealt.emit(body.global_position, damage)
			continue
		
		if body.has_method("take_damage"):
			body.take_damage(damage)
			_damaged_enemies[body] = true
			damage_dealt.emit(body.global_position, damage)
