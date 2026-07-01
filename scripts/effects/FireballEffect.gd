extends SpellEffect

@onready var flight_sprite: Sprite2D = $FlightSprite
@onready var impact_anim: AnimatedSprite2D = $ImpactAnim

const FIREBALL_TEXTURE_PATH: String = "res://assets/vfx/effects/fireball.png"
const TRAVEL_DURATION_SEC: float = 3.0
const DEFAULT_DAMAGE: float = 110.0
const DEFAULT_RADIUS: float = 80.0
const SPAWN_MARGIN_PX: float = 120.0
const FALLBACK_SPAWN_OFFSET_PX: float = 520.0
const IMPACT_ANIM_NAME: StringName = &"impact"
const IMPACT_ANIM_SPEED: float = 14.0

static var _cached_impact_frames: SpriteFrames = null
static var _cached_fireball_texture: Texture2D = null

var _impact_radius: float = DEFAULT_RADIUS
var _impact_damage: float = DEFAULT_DAMAGE
var _damaged_targets: Dictionary = {}
var _impact_started: bool = false


func execute_effect() -> void:
	if flight_sprite == null or impact_anim == null:
		push_error("[FireballEffect] Missing required nodes")
		queue_free()
		return

	flight_sprite.texture = _get_or_create_fireball_texture()
	if flight_sprite.texture == null:
		push_warning("[FireballEffect] Fireball texture is missing, using empty flight sprite")
	impact_anim.sprite_frames = _get_or_create_impact_frames()
	impact_anim.visible = false

	var base_radius := DEFAULT_RADIUS
	if config != null and config.target_radius > 0.0:
		base_radius = config.target_radius
	_impact_radius = get_scaled_radius(base_radius)

	var base_damage := DEFAULT_DAMAGE
	if config != null and config.damage > 0.0:
		base_damage = config.damage
	_impact_damage = get_scaled_damage(base_damage)

	global_position = _resolve_spawn_position(target_position)
	flight_sprite.rotation = 0.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", target_position, TRAVEL_DURATION_SEC)

	await tween.finished
	_start_impact()


func _start_impact() -> void:
	if _impact_started:
		return
	_impact_started = true

	global_position = target_position
	flight_sprite.visible = false
	impact_anim.visible = true

	_apply_impact_damage()

	if impact_anim.sprite_frames != null and impact_anim.sprite_frames.has_animation(IMPACT_ANIM_NAME):
		impact_anim.play(IMPACT_ANIM_NAME)
		await impact_anim.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout

	queue_free()


func _resolve_spawn_position(target_pos: Vector2) -> Vector2:
	var viewport := get_viewport()
	if viewport != null:
		var camera := viewport.get_camera_2d()
		if camera != null:
			var zoom_x := maxf(camera.zoom.x, 0.001)
			var zoom_y := maxf(camera.zoom.y, 0.001)
			var half_width := viewport.get_visible_rect().size.x * 0.5 / zoom_x
			var half_height := viewport.get_visible_rect().size.y * 0.5 / zoom_y
			var left_edge := camera.global_position.x - half_width
			var top_edge := camera.global_position.y - half_height

			var spawn_x := minf(left_edge - SPAWN_MARGIN_PX, target_pos.x - 32.0)
			var spawn_y := minf(top_edge - SPAWN_MARGIN_PX, target_pos.y - 32.0)
			return Vector2(spawn_x, spawn_y)

	return Vector2(target_pos.x - FALLBACK_SPAWN_OFFSET_PX, target_pos.y - FALLBACK_SPAWN_OFFSET_PX)


func _apply_impact_damage() -> void:
	_damaged_targets.clear()

	var candidates: Array[Node] = []
	candidates.append_array(get_tree().get_nodes_in_group("enemy"))
	candidates.append_array(get_tree().get_nodes_in_group("enemies"))
	candidates.append_array(get_tree().get_nodes_in_group("mobs"))

	for candidate in candidates:
		if candidate == null or not is_instance_valid(candidate):
			continue
		if _damaged_targets.has(candidate):
			continue
		if not (candidate is Node2D):
			continue

		var enemy := candidate as Node2D
		if enemy.global_position.distance_to(target_position) > _impact_radius:
			continue

		_apply_damage_to_target(enemy)
		_damaged_targets[candidate] = true


func _apply_damage_to_target(target: Node) -> void:
	var hurtbox := target.get_node_or_null("Hurtbox")
	if hurtbox != null and hurtbox.has_method("apply_hit"):
		var attack_id := Time.get_ticks_msec()
		hurtbox.apply_hit(_impact_damage, self, attack_id)
		return

	if target.has_method("apply_hit"):
		var attack_id := Time.get_ticks_msec()
		target.apply_hit(_impact_damage, self, attack_id)
		return

	if target.has_method("take_damage"):
		target.take_damage(_impact_damage)


func _get_or_create_impact_frames() -> SpriteFrames:
	if _cached_impact_frames != null:
		return _cached_impact_frames

	var frames := SpriteFrames.new()
	frames.add_animation(IMPACT_ANIM_NAME)
	frames.set_animation_speed(IMPACT_ANIM_NAME, IMPACT_ANIM_SPEED)
	frames.set_animation_loop(IMPACT_ANIM_NAME, false)

	for frame_idx in range(1, 11):
		var frame_path := "res://assets/vfx/effects/Explosion2/%d.png" % frame_idx
		var texture := load(frame_path) as Texture2D
		if texture != null:
			frames.add_frame(IMPACT_ANIM_NAME, texture)

	_cached_impact_frames = frames
	return _cached_impact_frames


func _get_or_create_fireball_texture() -> Texture2D:
	if _cached_fireball_texture != null:
		return _cached_fireball_texture

	var image := Image.new()
	var fs_path := ProjectSettings.globalize_path(FIREBALL_TEXTURE_PATH)
	if not FileAccess.file_exists(fs_path):
		return null
	if image.load(fs_path) != OK:
		return null

	_cached_fireball_texture = ImageTexture.create_from_image(image)
	return _cached_fireball_texture
