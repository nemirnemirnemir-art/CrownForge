extends CharacterBody2D

## Single bursting guy - runs forward, explodes on enemy contact

@onready var guy_anim: AnimatedSprite2D = $GuyAnim
@onready var detection_area: Area2D = $DetectionArea
@onready var explosion_area: Area2D = $ExplosionArea
@onready var explosion_shape: CollisionShape2D = $ExplosionArea/CollisionShape2D

const BUN_TEXTURE_PATH: String = "res://assets/vfx/spells_visuals/Bursting Bunch.png"
const EXPLOSION_FOLDER: String = "res://assets/vfx/Particle FX/Explosion2"
const EXPLOSION_FPS: float = 18.0
const EXPLOSION_ANIM: StringName = &"default"

const START_SPEED: float = 15.0
const MAX_SPEED: float = 350.0
const ACCEL: float = 700.0
const ROT_SPEED_FACTOR: float = 0.02
const HARD_DESPAWN_SEC: float = 15.0
const CONTACT_SLOW_MULT: float = 0.25

var _direction: Vector2 = Vector2.RIGHT
var _exploded: bool = false
var _lifetime_timer: float = 0.0

var _speed: float = START_SPEED
var _damage: float = 250.0
var _explosion_radius: float = 80.0
var _explosion_delay: float = 1.0
var _lifetime: float = 5.0
var _pending_explosion: bool = false
var _pending_speed: float = START_SPEED

static var _cached_bun_frames: SpriteFrames = null
static var _cached_explosion_frames: SpriteFrames = null

func setup(direction: Vector2, damage: float, explosion_radius: float, explosion_delay: float, lifetime: float) -> void:
	_direction = direction.normalized()
	_damage = damage
	_explosion_radius = explosion_radius
	_explosion_delay = explosion_delay
	_lifetime = lifetime
	_speed = START_SPEED

	# Setup explosion shape
	if explosion_shape:
		var shape := CircleShape2D.new()
		shape.radius = _explosion_radius
		explosion_shape.shape = shape
		explosion_shape.disabled = true

	# Connect detection signal
	if detection_area and not detection_area.body_entered.is_connected(_on_body_entered):
		detection_area.body_entered.connect(_on_body_entered)

	if guy_anim:
		guy_anim.sprite_frames = _get_or_create_bun_frames()
		if guy_anim.sprite_frames and guy_anim.sprite_frames.has_animation(EXPLOSION_ANIM):
			guy_anim.play(EXPLOSION_ANIM)

func _physics_process(delta: float) -> void:
	_lifetime_timer += delta
	if _lifetime_timer >= HARD_DESPAWN_SEC:
		queue_free()
		return

	if _exploded:
		return
	if _pending_explosion:
		velocity = _direction * _pending_speed
		move_and_slide()
		rotation += _pending_speed * ROT_SPEED_FACTOR * delta
		return

	var prev_pos := global_position
	if _has_enemy_contact():
		_start_pending_explosion()
		return
	
	_speed = minf(MAX_SPEED, _speed + ACCEL * delta)
	velocity = _direction * _speed
	move_and_slide()
	if _check_path_contact(prev_pos, global_position):
		_start_pending_explosion()
		return
	rotation += _speed * ROT_SPEED_FACTOR * delta

func _on_body_entered(body: Node2D) -> void:
	if not _is_enemy(body):
		return
	_start_pending_explosion()

func _start_pending_explosion() -> void:
	if _exploded or _pending_explosion:
		return
	_pending_explosion = true
	_pending_speed = maxf(START_SPEED * 0.5, _speed * CONTACT_SLOW_MULT)
	if detection_area:
		detection_area.set_deferred("monitoring", false)
	await get_tree().create_timer(_explosion_delay).timeout
	if not is_inside_tree():
		return
	_explode()

func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	velocity = Vector2.ZERO
	_spawn_explosion_fx()
	
	# Enable explosion and deal damage
	if explosion_shape:
		explosion_shape.set_deferred("disabled", false)
	
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	_deal_explosion_damage()
	
	# Wait then cleanup
	await get_tree().create_timer(0.2).timeout
	queue_free()

func _deal_explosion_damage() -> void:
	var targets: Array[Node2D] = []
	if explosion_area:
		for body_any in explosion_area.get_overlapping_bodies():
			if body_any is Node2D:
				targets.append(body_any as Node2D)

	if targets.is_empty():
		targets = _collect_enemies_in_radius(_explosion_radius)

	for body in targets:
		if not body.is_in_group("enemy") and not body.is_in_group("mobs"):
			continue
		var hurtbox = body.get_node_or_null("Hurtbox")
		if hurtbox and hurtbox.has_method("apply_hit"):
			var attack_id: int = Time.get_ticks_msec() + get_instance_id()
			hurtbox.apply_hit(_damage, self, attack_id)
		elif body.has_method("take_damage"):
			body.take_damage(_damage)

func _has_enemy_contact() -> bool:
	if detection_area == null:
		return false
	for body_any in detection_area.get_overlapping_bodies():
		if body_any is Node2D and _is_enemy(body_any as Node2D):
			return true
	return false

func _is_enemy(body: Node2D) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	return body.is_in_group("enemy") or body.is_in_group("mobs") or body.is_in_group("enemies")

func _collect_enemies_in_radius(radius: float) -> Array[Node2D]:
	var result: Array[Node2D] = []
	var tree := get_tree()
	if tree == null:
		return result

	var candidates: Array = tree.get_nodes_in_group("enemy")
	candidates.append_array(tree.get_nodes_in_group("mobs"))
	candidates.append_array(tree.get_nodes_in_group("enemies"))

	for candidate in candidates:
		if not (candidate is Node2D):
			continue
		var enemy := candidate as Node2D
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(global_position) > radius:
			continue
		result.append(enemy)

	return result

func _check_path_contact(from_pos: Vector2, to_pos: Vector2) -> bool:
	for enemy in _collect_enemies_in_radius(_explosion_radius):
		if not is_instance_valid(enemy):
			continue
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, from_pos, to_pos)
		if enemy.global_position.distance_to(closest) <= 24.0:
			return true
	return false

func _spawn_explosion_fx() -> void:
	var parent_node: Node = get_tree().current_scene
	if get_parent() != null:
		parent_node = get_parent()
	if parent_node == null:
		return
	var frames := _get_or_create_explosion_frames()
	if frames == null:
		return
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = frames
	fx.animation = EXPLOSION_ANIM
	fx.z_index = 180
	parent_node.add_child(fx)
	fx.global_position = global_position
	if fx.sprite_frames.has_animation(EXPLOSION_ANIM):
		fx.play(EXPLOSION_ANIM)
	if not fx.animation_finished.is_connected(_on_fx_finished.bind(fx)):
		fx.animation_finished.connect(_on_fx_finished.bind(fx))

func _on_fx_finished(fx: AnimatedSprite2D) -> void:
	if fx != null and is_instance_valid(fx):
		fx.queue_free()

func _get_or_create_bun_frames() -> SpriteFrames:
	if _cached_bun_frames != null:
		return _cached_bun_frames
	var frames := SpriteFrames.new()
	if not frames.has_animation(EXPLOSION_ANIM):
		frames.add_animation(EXPLOSION_ANIM)
	frames.set_animation_loop(EXPLOSION_ANIM, true)
	frames.set_animation_speed(EXPLOSION_ANIM, 8.0)
	var tex := load(BUN_TEXTURE_PATH) as Texture2D
	if tex != null:
		frames.add_frame(EXPLOSION_ANIM, tex)
	_cached_bun_frames = frames
	return _cached_bun_frames

func _get_or_create_explosion_frames() -> SpriteFrames:
	if _cached_explosion_frames != null:
		return _cached_explosion_frames
	var frames := SpriteFrames.new()
	if not frames.has_animation(EXPLOSION_ANIM):
		frames.add_animation(EXPLOSION_ANIM)
	frames.set_animation_loop(EXPLOSION_ANIM, false)
	frames.set_animation_speed(EXPLOSION_ANIM, EXPLOSION_FPS)
	for idx in range(2, 12):
		var frame_path := "%s/Explosion_%02d.png" % [EXPLOSION_FOLDER, idx]
		var tex := load(frame_path) as Texture2D
		if tex != null:
			frames.add_frame(EXPLOSION_ANIM, tex)
	_cached_explosion_frames = frames
	return _cached_explosion_frames
