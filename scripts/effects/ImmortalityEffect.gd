extends SpellEffect

## Immortality spell - persistent allied area that keeps heroes invincible
## while they stay inside, with per-hero overhead icon and floor VFX.

const StatusIconServiceScript := preload("res://scripts/effects/shared/StatusIconService.gd")

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var floor_vfx_template: AnimatedSprite2D = $FloorVfxTemplate

const DEFAULT_DURATION: float = 4.0
const DEFAULT_RADIUS: float = 80.0
const ICON_PATH: String = "res://assets/vfx/spells/Immortality.png"
const ICON_NAME: String = "ImmortalityIcon"
const FLOOR_VFX_NAME: String = "ImmortalityFloorVfx"
const ICON_OFFSET_Y: float = -55.0
const CHECK_INTERVAL: float = 0.2
const HERO_STACK_META: StringName = &"immortality_effect_stack_count"
const HERO_ORIGINAL_STATE_META: StringName = &"immortality_effect_original_invincible"

var _duration_remaining: float = DEFAULT_DURATION
var _check_timer: float = 0.0
var _is_cleaning_up: bool = false
## instance_id -> { "hero_ref": WeakRef, "icon_ref": WeakRef, "floor_vfx_ref": WeakRef }
var _tracked_heroes: Dictionary = {}


func execute_effect() -> void:
	if not detection_area or not detection_shape or not floor_vfx_template:
		push_error("[ImmortalityEffect] Missing required nodes")
		queue_free()
		return

	_duration_remaining = _get_duration()
	_configure_area_radius()
	_configure_detection_area()
	_connect_area_signals()

	await get_tree().process_frame
	_sync_tracked_heroes()
	set_process(true)
	call_deferred("_run_duration_timer")


func _process(delta: float) -> void:
	if _is_cleaning_up:
		return

	_duration_remaining -= delta
	_check_timer += delta

	if _check_timer >= CHECK_INTERVAL:
		_check_timer = 0.0
		_sync_tracked_heroes()


func _exit_tree() -> void:
	_cleanup_tracked_heroes()


func _on_detection_area_body_entered(body: Node) -> void:
	if body is Node2D:
		_track_hero_enter(body as Node2D)


func _on_detection_area_body_exited(body: Node) -> void:
	if body is Node2D:
		_track_hero_exit(body as Node2D)


func _track_hero_enter(hero: Node2D) -> void:
	if _is_cleaning_up or not _is_trackable_hero(hero):
		return

	var hero_id := hero.get_instance_id()
	if _tracked_heroes.has(hero_id):
		return

	_increment_hero_invincibility(hero)

	var icon: Sprite2D = StatusIconServiceScript.add_status_icon(
		hero,
		ICON_PATH,
		ICON_NAME,
		ICON_OFFSET_Y
	)
	var floor_vfx := _spawn_floor_vfx(hero)

	_tracked_heroes[hero_id] = {
		"hero_ref": weakref(hero),
		"icon_ref": weakref(icon) if icon != null else null,
		"floor_vfx_ref": weakref(floor_vfx) if floor_vfx != null else null,
	}


func _track_hero_exit(hero: Node2D) -> void:
	if hero == null:
		return
	_remove_tracked_hero_by_id(hero.get_instance_id())


func _run_duration_timer() -> void:
	await get_tree().create_timer(_duration_remaining).timeout
	_cleanup_and_free()


func _get_duration() -> float:
	if config != null and config.duration > 0.0:
		return config.duration
	return DEFAULT_DURATION


func _configure_area_radius() -> void:
	var radius := DEFAULT_RADIUS
	if config != null and config.target_radius > 0.0:
		radius = config.target_radius

	var shape := CircleShape2D.new()
	shape.radius = radius
	detection_shape.shape = shape


func _configure_detection_area() -> void:
	detection_area.collision_layer = 0
	detection_area.collision_mask = 4
	detection_area.monitoring = true
	detection_area.monitorable = true


func _connect_area_signals() -> void:
	var entered := Callable(self, "_on_detection_area_body_entered")
	if not detection_area.body_entered.is_connected(entered):
		detection_area.body_entered.connect(entered)

	var exited := Callable(self, "_on_detection_area_body_exited")
	if not detection_area.body_exited.is_connected(exited):
		detection_area.body_exited.connect(exited)


func _sync_tracked_heroes() -> void:
	if _is_cleaning_up or detection_area == null:
		return

	var current_heroes := _collect_current_heroes()

	for hero_id_variant in current_heroes.keys():
		var hero_id := int(hero_id_variant)
		if not _tracked_heroes.has(hero_id):
			_track_hero_enter(current_heroes[hero_id])

	var stale_ids: Array[int] = []
	for tracked_id_variant in _tracked_heroes.keys():
		var tracked_id := int(tracked_id_variant)
		var hero := _resolve_node2d_from_weakref(_tracked_heroes[tracked_id].get("hero_ref"))
		if hero == null or not is_instance_valid(hero) or not current_heroes.has(tracked_id):
			stale_ids.append(tracked_id)

	for stale_id in stale_ids:
		_remove_tracked_hero_by_id(stale_id)


func _collect_current_heroes() -> Dictionary:
	var current_heroes: Dictionary = {}
	var overlaps: Array = []
	overlaps.append_array(detection_area.get_overlapping_bodies())

	for obj in overlaps:
		if not (obj is Node2D):
			continue
		var hero := obj as Node2D
		if not _is_trackable_hero(hero):
			continue
		current_heroes[hero.get_instance_id()] = hero

	var tree := get_tree()
	if tree == null:
		return current_heroes

	var radius := _get_detection_radius()
	for hero_node in tree.get_nodes_in_group("hero"):
		if not (hero_node is Node2D):
			continue
		var hero := hero_node as Node2D
		if not _is_trackable_hero(hero):
			continue
		if hero.global_position.distance_to(global_position) > radius:
			continue
		current_heroes[hero.get_instance_id()] = hero

	return current_heroes


func _get_detection_radius() -> float:
	if detection_shape == null or detection_shape.shape == null:
		return DEFAULT_RADIUS
	if detection_shape.shape is CircleShape2D:
		return (detection_shape.shape as CircleShape2D).radius
	return DEFAULT_RADIUS


func _cleanup_and_free() -> void:
	if _is_cleaning_up:
		return
	_is_cleaning_up = true
	set_process(false)
	_cleanup_tracked_heroes()
	queue_free()


func _cleanup_tracked_heroes() -> void:
	if _tracked_heroes.is_empty():
		return

	var tracked_ids: Array[int] = []
	for tracked_id_variant in _tracked_heroes.keys():
		tracked_ids.append(int(tracked_id_variant))

	for tracked_id in tracked_ids:
		_remove_tracked_hero_by_id(tracked_id)


func _remove_tracked_hero_by_id(hero_id: int) -> void:
	if not _tracked_heroes.has(hero_id):
		return

	var entry: Dictionary = _tracked_heroes[hero_id]
	var hero := _resolve_node2d_from_weakref(entry.get("hero_ref"))
	if hero != null and is_instance_valid(hero):
		_decrement_hero_invincibility(hero)
		var icon_node := _resolve_node_from_weakref(entry.get("icon_ref"))
		if icon_node != null and is_instance_valid(icon_node):
			icon_node.queue_free()
		StatusIconServiceScript.reflow_status_icons(hero)
	else:
		var icon_node := _resolve_node_from_weakref(entry.get("icon_ref"))
		if icon_node != null and is_instance_valid(icon_node):
			icon_node.queue_free()

	var floor_vfx_node := _resolve_node_from_weakref(entry.get("floor_vfx_ref"))
	if floor_vfx_node != null and is_instance_valid(floor_vfx_node):
		floor_vfx_node.queue_free()

	_tracked_heroes.erase(hero_id)


func _is_trackable_hero(hero: Node2D) -> bool:
	return hero != null \
		and is_instance_valid(hero) \
		and hero.is_in_group("hero") \
		and ("is_invincible" in hero)


func _increment_hero_invincibility(hero: Node2D) -> void:
	var stack_count := int(hero.get_meta(HERO_STACK_META, 0))
	if stack_count <= 0:
		hero.set_meta(HERO_ORIGINAL_STATE_META, bool(hero.get("is_invincible")))
	stack_count += 1
	hero.set_meta(HERO_STACK_META, stack_count)
	hero.set("is_invincible", true)


func _decrement_hero_invincibility(hero: Node2D) -> void:
	var stack_count := int(hero.get_meta(HERO_STACK_META, 0))
	if stack_count <= 0:
		return

	stack_count -= 1
	if stack_count > 0:
		hero.set_meta(HERO_STACK_META, stack_count)
		hero.set("is_invincible", true)
		return

	var original_state := bool(hero.get_meta(HERO_ORIGINAL_STATE_META, false))
	hero.remove_meta(HERO_STACK_META)
	hero.remove_meta(HERO_ORIGINAL_STATE_META)
	hero.set("is_invincible", original_state)


func _spawn_floor_vfx(hero: Node2D) -> AnimatedSprite2D:
	if floor_vfx_template == null or floor_vfx_template.sprite_frames == null:
		return null

	var floor_vfx := floor_vfx_template.duplicate() as AnimatedSprite2D
	if floor_vfx == null:
		return null

	floor_vfx.name = FLOOR_VFX_NAME
	floor_vfx.visible = true
	floor_vfx.position = floor_vfx_template.position
	floor_vfx.scale = floor_vfx_template.scale
	floor_vfx.rotation = floor_vfx_template.rotation
	floor_vfx.z_index = floor_vfx_template.z_index
	hero.add_child(floor_vfx)

	if floor_vfx.sprite_frames.has_animation(floor_vfx.animation):
		floor_vfx.play(floor_vfx.animation)
	elif floor_vfx.sprite_frames.has_animation("default"):
		floor_vfx.play("default")

	return floor_vfx


func _resolve_node2d_from_weakref(value: Variant) -> Node2D:
	var node := _resolve_node_from_weakref(value)
	if node != null and node is Node2D:
		return node as Node2D
	return null


func _resolve_node_from_weakref(value: Variant) -> Node:
	if value == null:
		return null
	if not (value is WeakRef):
		return null
	var obj: Object = (value as WeakRef).get_ref()
	if obj != null and obj is Node:
		return obj as Node
	return null
