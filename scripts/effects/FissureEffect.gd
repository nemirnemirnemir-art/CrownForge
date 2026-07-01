extends SpellEffect

## Fissure spell - vertical strip 64x640 with delayed damage

@onready var fissure_sprite: Sprite2D = $FissureSprite
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D

const FISSURE_DAMAGE: float = 220.0
const STRIP_WIDTH: float = 64.0
const STRIP_HEIGHT: float = 640.0
const SEGMENT_COUNT: int = 10
const SEGMENT_INTERVAL: float = 0.1
const DAMAGE_DELAY: float = 1.0
const CLEANUP_DELAY: float = 0.35
const FX_FOLDER: String = "res://assets/vfx/spells_visuals/Fissure"
const FX_ANIM_NAME: StringName = &"default"
const FX_FPS: float = 16.0

var _damaged_enemies: Dictionary = {}
static var _cached_frames: SpriteFrames = null

func execute_effect() -> void:
	if not damage_area or not damage_shape:
		push_error("[FissureEffect] Missing required nodes")
		queue_free()
		return

	if fissure_sprite:
		fissure_sprite.visible = false

	var width := STRIP_WIDTH * radius_multiplier
	var height := STRIP_HEIGHT * radius_multiplier
	# Setup collision shape (vertical rectangle)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, height)
	damage_shape.shape = shape

	# Enable collision
	damage_shape.set_deferred("disabled", false)

	var half_h := height * 0.5
	for i in range(SEGMENT_COUNT):
		_spawn_segment(i, half_h, width)
		await get_tree().create_timer(SEGMENT_INTERVAL).timeout
	var elapsed := float(SEGMENT_COUNT) * SEGMENT_INTERVAL
	if elapsed < DAMAGE_DELAY:
		await get_tree().create_timer(DAMAGE_DELAY - elapsed).timeout

	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	_deal_damage()

	await get_tree().create_timer(CLEANUP_DELAY).timeout
	queue_free()

func _spawn_segment(index: int, half_h: float, width: float) -> void:
	var frames := _get_or_create_frames()
	if frames == null:
		return
	var seg := AnimatedSprite2D.new()
	seg.sprite_frames = frames
	seg.animation = FX_ANIM_NAME
	seg.z_index = 170

	var t := 0.0
	if SEGMENT_COUNT > 1:
		t = float(index) / float(SEGMENT_COUNT - 1)
	seg.position = Vector2(randf_range(-width * 0.2, width * 0.2), lerpf(-half_h, half_h, t))
	add_child(seg)

	if seg.sprite_frames.has_animation(FX_ANIM_NAME):
		seg.play(FX_ANIM_NAME)
	if not seg.animation_finished.is_connected(_on_segment_finished.bind(seg)):
		seg.animation_finished.connect(_on_segment_finished.bind(seg))

func _on_segment_finished(seg: AnimatedSprite2D) -> void:
	if seg != null and is_instance_valid(seg):
		seg.queue_free()

func _get_or_create_frames() -> SpriteFrames:
	if _cached_frames != null:
		return _cached_frames
	var frames := SpriteFrames.new()
	if not frames.has_animation(FX_ANIM_NAME):
		frames.add_animation(FX_ANIM_NAME)
	frames.set_animation_loop(FX_ANIM_NAME, false)
	frames.set_animation_speed(FX_ANIM_NAME, FX_FPS)
	for idx in range(1, 10):
		var path := "%s/%03d.png" % [FX_FOLDER, idx]
		var tex := load(path) as Texture2D
		if tex != null:
			frames.add_frame(FX_ANIM_NAME, tex)
	_cached_frames = frames
	return _cached_frames

func _deal_damage() -> void:
	if not damage_area:
		return

	var base_damage := FISSURE_DAMAGE
	if config and config.damage > 0.0:
		base_damage = float(config.damage)
	var damage := get_scaled_damage(base_damage)
	
	var targets: Array[Node2D] = []
	for body_any in damage_area.get_overlapping_bodies():
		if body_any is Node2D:
			targets.append(body_any as Node2D)

	if targets.is_empty():
		targets = _collect_fallback_targets()
	
	for body in targets:
		if _damaged_enemies.has(body):
			continue
		
		# Check if enemy
		if not body.is_in_group("enemy") and not body.is_in_group("mobs") and not body.is_in_group("enemies"):
			continue
		
		# Priority 1: Hurtbox
		var hurtbox = body.get_node_or_null("Hurtbox")
		if hurtbox and hurtbox.has_method("apply_hit"):
			var attack_id: int = Time.get_ticks_msec() + get_instance_id()
			hurtbox.apply_hit(damage, self, attack_id)
			_damaged_enemies[body] = true
			continue
		
		# Priority 2: take_damage
		if body.has_method("take_damage"):
			body.take_damage(damage)
			_damaged_enemies[body] = true

func _collect_fallback_targets() -> Array[Node2D]:
	var result: Array[Node2D] = []
	var tree := get_tree()
	if tree == null:
		return result

	var width := STRIP_WIDTH * radius_multiplier
	var height := STRIP_HEIGHT * radius_multiplier
	var half := Vector2(width * 0.5, height * 0.5)

	var candidates: Array = tree.get_nodes_in_group("enemy")
	candidates.append_array(tree.get_nodes_in_group("mobs"))
	candidates.append_array(tree.get_nodes_in_group("enemies"))

	for node in candidates:
		if not (node is Node2D):
			continue
		var enemy := node as Node2D
		if not is_instance_valid(enemy):
			continue
		var local := enemy.global_position - global_position
		if absf(local.x) > half.x or absf(local.y) > half.y:
			continue
		result.append(enemy)

	return result
