extends SpellEffect

## Chain Lightning spell - fast chain to up to 5 enemies, 75 damage each

@onready var lightning_line: Line2D = $LightningLine
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

var max_targets_override: int = 0
var line_width_multiplier: float = 1.0
var start_anim_scale_multiplier: float = 1.0
var pre_chain_delay_override: float = -1.0
var origin_position_override: Vector2 = Vector2.INF
var deal_damage_enabled: bool = true

const MAX_TARGETS: int = 5
const DAMAGE_PER_HIT: float = 75.0
const CHAIN_RANGE: float = 150.0  # Max distance to jump to next target
const DISPLAY_TIME_SEC: float = 0.35
const PRE_CHAIN_DELAY_SEC: float = 1.0
const FLASH_FADE_SEC: float = 0.2
const LINE_SEGMENTS_PER_JUMP: int = 4
const LINE_JITTER_PX: float = 10.0
const HOP_DELAY_SEC: float = 0.10

static var _cached_start_frames: SpriteFrames = null

func execute_effect() -> void:
	if not lightning_line or not detection_area:
		push_error("[ChainLightningEffect] Missing required nodes")
		queue_free()
		return
	
	# Play lighting_start animation above target
	var anim := AnimatedSprite2D.new()
	var frames := _get_or_create_start_frames()
	if frames != null and frames.get_frame_count("default") > 0:
		anim.sprite_frames = frames
		anim.position = Vector2(0, -60)
		anim.scale = Vector2.ONE * maxf(0.1, start_anim_scale_multiplier)
		anim.z_index = 200
		add_child(anim)
		anim.animation_finished.connect(_on_temp_anim_finished.bind(anim), CONNECT_ONE_SHOT)
		anim.play("default")
	
	# Screen flash effect
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100
	var flash_rect := ColorRect.new()
	flash_rect.color = Color(1.0, 1.0, 1.0, 1.0)
	var viewport_size = get_viewport().get_visible_rect().size
	flash_rect.custom_minimum_size = viewport_size
	flash_rect.size = viewport_size
	canvas_layer.add_child(flash_rect)
	add_child(canvas_layer)
	
	var tween = create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, FLASH_FADE_SEC)
	tween.tween_callback(canvas_layer.queue_free)
	
	# Setup large detection area to find all potential targets
	detection_area.collision_mask = 2 # Target enemies
	if detection_shape:
		var shape := CircleShape2D.new()
		shape.radius = get_scaled_radius(400.0)
		detection_shape.shape = shape
	
	# Setup lightning line visual
	lightning_line.width = 3.5 * maxf(0.1, line_width_multiplier)
	lightning_line.default_color = Color(0.3, 0.5, 1.0, 1.0)  # Blue lightning
	lightning_line.clear_points()
	
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# 1 second delay before chain lightning
	var pre_chain_delay := PRE_CHAIN_DELAY_SEC if pre_chain_delay_override < 0.0 else pre_chain_delay_override
	if pre_chain_delay > 0.0:
		await get_tree().create_timer(pre_chain_delay).timeout
	
	# Find and chain targets
	await _chain_lightning()
	
	# Brief display then cleanup
	await get_tree().create_timer(DISPLAY_TIME_SEC).timeout
	queue_free()

func _chain_lightning() -> void:
	var enemies := _collect_enemy_candidates()
	if enemies.is_empty():
		return

	var max_targets := max_targets_override if max_targets_override > 0 else MAX_TARGETS
	var chain_range_sq := pow(get_scaled_radius(CHAIN_RANGE), 2.0)
	var start := _find_start_target(enemies)
	if start == null:
		return

	var hit: Array[Node2D] = [start]
	var from_pos := global_position if origin_position_override == Vector2.INF else origin_position_override
	var current: Node2D = start

	_deal_damage_to(start)
	_draw_link(from_pos, start.global_position)
	await get_tree().create_timer(HOP_DELAY_SEC).timeout

	for _i in range(max_targets - 1):
		var next := _find_next_target(current.global_position, enemies, hit, chain_range_sq)
		if next == null:
			break
		hit.append(next)
		_draw_link(current.global_position, next.global_position)
		_deal_damage_to(next)
		current = next
		await get_tree().create_timer(HOP_DELAY_SEC).timeout

func _deal_damage_to(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return

	var base_damage := DAMAGE_PER_HIT
	if config and config.damage > 0.0:
		base_damage = float(config.damage)
	var damage := get_scaled_damage(base_damage)
	if not deal_damage_enabled:
		return
	
	var hurtbox = enemy.get_node_or_null("Hurtbox")
	if hurtbox and hurtbox.has_method("apply_hit"):
		var attack_id: int = Time.get_ticks_msec() + enemy.get_instance_id()
		hurtbox.apply_hit(damage, self, attack_id)
		return
	
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)

func _draw_jagged_chain(world_points: Array[Vector2]) -> void:
	if lightning_line == null or world_points.size() < 2:
		return

	for idx in range(world_points.size() - 1):
		var from := world_points[idx]
		var to := world_points[idx + 1]
		if idx == 0:
			lightning_line.add_point(to_local(from))

		var direction := to - from
		var normal := Vector2(-direction.y, direction.x).normalized()
		for seg in range(1, LINE_SEGMENTS_PER_JUMP):
			var t := float(seg) / float(LINE_SEGMENTS_PER_JUMP)
			var mid := from.lerp(to, t)
			var jitter := normal * randf_range(-LINE_JITTER_PX, LINE_JITTER_PX)
			lightning_line.add_point(to_local(mid + jitter))

		lightning_line.add_point(to_local(to))

func _draw_link(from_world: Vector2, to_world: Vector2) -> void:
	if lightning_line == null:
		return
	lightning_line.clear_points()
	_draw_jagged_chain([from_world, to_world])

func _collect_enemy_candidates() -> Array[Node2D]:
	var result: Array[Node2D] = []
	var tree := get_tree()
	if tree == null:
		return result

	var dedupe := {}
	for node in tree.get_nodes_in_group("enemy"):
		if node is Node2D and is_instance_valid(node):
			var e := node as Node2D
			if "is_dead" in e and bool(e.is_dead):
				continue
			dedupe[e.get_instance_id()] = e
	for node in tree.get_nodes_in_group("mobs"):
		if node is Node2D and is_instance_valid(node):
			var e := node as Node2D
			if "is_dead" in e and bool(e.is_dead):
				continue
			dedupe[e.get_instance_id()] = e
	for node in tree.get_nodes_in_group("enemies"):
		if node is Node2D and is_instance_valid(node):
			var e := node as Node2D
			if "is_dead" in e and bool(e.is_dead):
				continue
			dedupe[e.get_instance_id()] = e
	for key in dedupe.keys():
		result.append(dedupe[key])

	return result

func _find_start_target(enemies: Array[Node2D]) -> Node2D:
	var best: Node2D = null
	var best_d2 := INF
	for enemy in enemies:
		var d2 := target_position.distance_squared_to(enemy.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = enemy
	return best

func _find_next_target(from_pos: Vector2, enemies: Array[Node2D], already_hit: Array[Node2D], max_d2: float) -> Node2D:
	var best: Node2D = null
	var best_d2 := max_d2
	for enemy in enemies:
		if already_hit.has(enemy):
			continue
		var d2 := from_pos.distance_squared_to(enemy.global_position)
		if d2 <= best_d2:
			best_d2 = d2
			best = enemy
	return best

func _get_or_create_start_frames() -> SpriteFrames:
	if _cached_start_frames != null:
		return _cached_start_frames

	var frames := SpriteFrames.new()
	if not frames.has_animation("default"):
		frames.add_animation("default")
	frames.set_animation_loop("default", false)
	frames.set_animation_speed("default", 12.0)

	for i in range(1, 5):
		var tex_path := "res://assets/vfx/spells_visuals/lighting_start/%d.png" % i
		if not ResourceLoader.exists(tex_path):
			continue
		var tex := load(tex_path) as Texture2D
		if tex != null:
			frames.add_frame("default", tex)

	_cached_start_frames = frames
	return _cached_start_frames

func _on_temp_anim_finished(anim: AnimatedSprite2D) -> void:
	if anim != null and is_instance_valid(anim):
		anim.queue_free()
