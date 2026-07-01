extends SpellEffect

## TNT Barrel spell effect - places barrel that explodes after 5 seconds dealing 250 damage

@onready var barrel_sprite: Sprite2D = $BarrelSprite
@onready var explosion_area: Area2D = $ExplosionArea
@onready var explosion_collision: CollisionShape2D = $ExplosionArea/CollisionShape2D
@onready var explosion_anim: AnimatedSprite2D = $ExplosionAnim

var _fuse_timer: float = 5.0
var _explosion_triggered: bool = false
var _fuse_elapsed: float = 0.0
var _barrel_frames: Array[Texture2D] = []

const BARREL_FRAME_SWITCH_INTERVAL: float = 0.35
const BARREL_ANIM_FOLDER: String = "res://assets/vfx/spells_visuals/TNT Barrel"
const EXPLOSION2_FOLDER: String = "res://assets/vfx/Particle FX/Explosion2"
const EXPLOSION2_ANIM: StringName = &"explode2"
const EXPLOSION2_FPS: float = 20.0

static var _cached_explosion2_frames: SpriteFrames = null

func execute_effect() -> void:
	if not barrel_sprite or not explosion_area or not explosion_collision:
		push_error("[TNTBarrelEffect] Missing required nodes")
		queue_free()
		return
	
	# Show barrel, hide explosion initially
	_fuse_timer = config.duration if config != null and config.duration > 0.0 else 5.0
	barrel_sprite.visible = true
	_fuse_elapsed = 0.0
	_barrel_frames = _load_barrel_frames()
	if barrel_sprite and not _barrel_frames.is_empty():
		barrel_sprite.texture = _barrel_frames[0]
	if explosion_anim:
		explosion_anim.visible = false
		explosion_anim.sprite_frames = _get_or_create_explosion2_frames()
		explosion_anim.animation = EXPLOSION2_ANIM
	explosion_collision.disabled = true
	
	# Position explosion area (radius from config or default 80px)
	if config:
		var radius: float = 80.0
		if config.target_radius > 0:
			radius = float(config.target_radius)
		var shape := CircleShape2D.new()
		shape.radius = radius
		explosion_collision.shape = shape

func _process(delta: float) -> void:
	if _explosion_triggered:
		return
	
	_fuse_timer -= delta
	_fuse_elapsed += delta
	_update_barrel_fuse_animation()
	
	if _fuse_timer <= 0.0:
		_trigger_explosion()

func _update_barrel_fuse_animation() -> void:
	if barrel_sprite == null or _barrel_frames.is_empty():
		return
	var frame_count := _barrel_frames.size()
	if frame_count <= 1:
		return
	var idx := int(floor(_fuse_elapsed / BARREL_FRAME_SWITCH_INTERVAL)) % frame_count
	barrel_sprite.texture = _barrel_frames[idx]

func _trigger_explosion() -> void:
	_explosion_triggered = true
	
	# Hide barrel, show explosion
	if barrel_sprite:
		barrel_sprite.visible = false
	
	if explosion_anim:
		explosion_anim.visible = true
		if explosion_anim.sprite_frames and explosion_anim.sprite_frames.has_animation(EXPLOSION2_ANIM):
			explosion_anim.play(EXPLOSION2_ANIM)
		elif explosion_anim.sprite_frames and explosion_anim.sprite_frames.has_animation("default"):
			explosion_anim.play("default")
	
	# Enable collision briefly to deal damage
	explosion_collision.disabled = false
	_deal_explosion_damage()
	
	# Disable collision after damage dealt
	await get_tree().create_timer(0.1).timeout
	explosion_collision.disabled = true
	
	# Wait for animation to finish, then cleanup
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _deal_explosion_damage() -> void:
	if not explosion_area:
		return
	
	var damage_amount: float = 250.0
	if config:
		damage_amount = float(config.damage)
	var hits: Dictionary = {}
	var overlaps: Array = []
	overlaps.append_array(explosion_area.get_overlapping_areas())
	overlaps.append_array(explosion_area.get_overlapping_bodies())

	for obj in overlaps:
		_apply_damage_to_overlap_target(obj, damage_amount, hits)

	if hits.is_empty():
		_apply_fallback_radius_damage(damage_amount, hits)

func _apply_damage_to_overlap_target(obj: Variant, damage_amount: float, hits: Dictionary) -> void:
	if obj == null:
		return

	if obj is Hurtbox:
		var hb := obj as Hurtbox
		var owner_node := hb.get_parent()
		if owner_node is Node2D and _is_enemy(owner_node as Node2D):
			var enemy_owner := owner_node as Node2D
			var owner_id := enemy_owner.get_instance_id()
			if hits.has(owner_id):
				return
			hits[owner_id] = true
			hb.apply_hit(damage_amount, self, Time.get_ticks_msec() + get_instance_id() + owner_id)
		return

	if obj is Node2D:
		var body := obj as Node2D
		var enemy := body
		if not _is_enemy(enemy):
			var parent := body.get_parent()
			if parent is Node2D and _is_enemy(parent as Node2D):
				enemy = parent as Node2D
			else:
				return
		var enemy_id := enemy.get_instance_id()
		if hits.has(enemy_id):
			return
		hits[enemy_id] = true
		var hurtbox := enemy.get_node_or_null("Hurtbox")
		if hurtbox and hurtbox.has_method("apply_hit"):
			hurtbox.apply_hit(damage_amount, self, Time.get_ticks_msec() + get_instance_id() + enemy_id)
			return
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage_amount)

func _apply_fallback_radius_damage(damage_amount: float, hits: Dictionary) -> void:
	var shape := explosion_collision.shape as CircleShape2D
	if shape == null:
		return
	var radius_sq := shape.radius * shape.radius
	var tree := get_tree()
	if tree == null:
		return
	var candidates: Array = tree.get_nodes_in_group("enemy")
	candidates.append_array(tree.get_nodes_in_group("mobs"))
	candidates.append_array(tree.get_nodes_in_group("enemies"))
	for node in candidates:
		if not (node is Node2D):
			continue
		var enemy := node as Node2D
		if not is_instance_valid(enemy):
			continue
		var enemy_id := enemy.get_instance_id()
		if hits.has(enemy_id):
			continue
		if enemy.global_position.distance_squared_to(global_position) > radius_sq:
			continue
		hits[enemy_id] = true
		var hurtbox := enemy.get_node_or_null("Hurtbox")
		if hurtbox and hurtbox.has_method("apply_hit"):
			hurtbox.apply_hit(damage_amount, self, Time.get_ticks_msec() + get_instance_id() + enemy_id)
		elif enemy.has_method("take_damage"):
			enemy.take_damage(damage_amount)

func _load_barrel_frames() -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	for idx in range(1, 4):
		var path := "%s/%d.png" % [BARREL_ANIM_FOLDER, idx]
		if not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		if tex != null:
			result.append(tex)
	return result

func _is_enemy(node: Node2D) -> bool:
	return node.is_in_group("enemy") or node.is_in_group("mobs") or node.is_in_group("enemies")

func _get_or_create_explosion2_frames() -> SpriteFrames:
	if _cached_explosion2_frames != null:
		return _cached_explosion2_frames

	var frames := SpriteFrames.new()
	if not frames.has_animation(EXPLOSION2_ANIM):
		frames.add_animation(EXPLOSION2_ANIM)
	frames.set_animation_loop(EXPLOSION2_ANIM, false)
	frames.set_animation_speed(EXPLOSION2_ANIM, EXPLOSION2_FPS)

	for idx in range(2, 12):
		var path := "%s/Explosion_%02d.png" % [EXPLOSION2_FOLDER, idx]
		if not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		if tex != null:
			frames.add_frame(EXPLOSION2_ANIM, tex)

	_cached_explosion2_frames = frames
	return _cached_explosion2_frames
