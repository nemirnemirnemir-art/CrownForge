extends SpellEffect

## Last Stand spell – persistent area granting invincibility + 110 HP/s heal
## to allied heroes for the duration.  Combines ImmortalityEffect-style
## stack-based invincibility with HealingPoolEffect-style heal ticks.

const StatusIconServiceScript := preload("res://scripts/effects/shared/StatusIconService.gd")

@onready var stand_anim: AnimatedSprite2D = $StandAnim
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

const DEFAULT_DURATION: float = 5.0
const DEFAULT_RADIUS: float = 100.0
const HEAL_PER_TICK: float = 110.0
const TICK_INTERVAL: float = 1.0
const CHECK_INTERVAL: float = 0.2
const ICON_PATH: String = "res://assets/vfx/spells/Last Stand.png"
const ICON_NAME: String = "LastStandIcon"
const ICON_OFFSET_Y: float = -55.0
const HERO_STACK_META: StringName = &"last_stand_effect_stack_count"
const HERO_ORIGINAL_STATE_META: StringName = &"last_stand_effect_original_invincible"
const FADE_OUT_TIME: float = 0.5

var _duration_remaining: float = DEFAULT_DURATION
var _check_timer: float = 0.0
var _tick_timer: float = 0.0
var _is_cleaning_up: bool = false
## instance_id -> { "hero_ref": WeakRef, "icon_ref": WeakRef }
var _tracked_heroes: Dictionary = {}


func execute_effect() -> void:
	if not detection_area or not detection_shape:
		push_error("[LastStandEffect] Missing required nodes")
		queue_free()
		return

	_duration_remaining = _get_duration()
	_configure_area()

	detection_area.monitoring = true
	detection_area.monitorable = true
	detection_area.collision_layer = 0
	detection_area.collision_mask = 4

	_connect_signals()

	# Play animation
	if stand_anim and stand_anim.sprite_frames:
		if stand_anim.sprite_frames.has_animation("last_stand"):
			stand_anim.play("last_stand")
		elif stand_anim.sprite_frames.has_animation("default"):
			stand_anim.play("default")

	await get_tree().process_frame
	_sync_tracked_heroes()
	set_process(true)
	call_deferred("_run_duration_timer")


func _process(delta: float) -> void:
	if _is_cleaning_up:
		return

	_duration_remaining -= delta
	_check_timer += delta
	_tick_timer += delta

	if _check_timer >= CHECK_INTERVAL:
		_check_timer = 0.0
		_sync_tracked_heroes()

	if _tick_timer >= TICK_INTERVAL:
		_tick_timer = 0.0
		_heal_tracked_heroes()


func _exit_tree() -> void:
	_cleanup_all()


func _run_duration_timer() -> void:
	await get_tree().create_timer(_duration_remaining).timeout
	_cleanup_and_free()


func _get_duration() -> float:
	if config != null and config.duration > 0.0:
		return config.duration
	return DEFAULT_DURATION


func _configure_area() -> void:
	var radius := DEFAULT_RADIUS
	if config != null and config.target_radius > 0.0:
		radius = config.target_radius
	var shape := CircleShape2D.new()
	shape.radius = radius
	detection_shape.shape = shape


func _connect_signals() -> void:
	var entered := Callable(self, "_on_body_entered")
	if not detection_area.body_entered.is_connected(entered):
		detection_area.body_entered.connect(entered)
	var exited := Callable(self, "_on_body_exited")
	if not detection_area.body_exited.is_connected(exited):
		detection_area.body_exited.connect(exited)


func _on_body_entered(body: Node) -> void:
	if body is Node2D:
		_track_hero(body as Node2D)


func _on_body_exited(body: Node) -> void:
	if body is Node2D:
		_untrack_hero(body as Node2D)


func _track_hero(hero: Node2D) -> void:
	if _is_cleaning_up or not _is_trackable_hero(hero):
		return
	var hero_id := hero.get_instance_id()
	if _tracked_heroes.has(hero_id):
		return

	_increment_invincibility(hero)

	var icon: Sprite2D = StatusIconServiceScript.add_status_icon(
		hero, ICON_PATH, ICON_NAME, ICON_OFFSET_Y
	)

	_tracked_heroes[hero_id] = {
		"hero_ref": weakref(hero),
		"icon_ref": weakref(icon) if icon != null else null,
	}


func _untrack_hero(hero: Node2D) -> void:
	if hero == null:
		return
	_remove_hero_by_id(hero.get_instance_id())


func _sync_tracked_heroes() -> void:
	if _is_cleaning_up or detection_area == null:
		return

	var current := _collect_current_heroes()

	for id_variant in current.keys():
		var hid := int(id_variant)
		if not _tracked_heroes.has(hid):
			_track_hero(current[hid])

	var stale_ids: Array[int] = []
	for id_variant in _tracked_heroes.keys():
		var hid := int(id_variant)
		var hero := _resolve_node2d(_tracked_heroes[hid].get("hero_ref"))
		if hero == null or not is_instance_valid(hero) or not current.has(hid):
			stale_ids.append(hid)

	for sid in stale_ids:
		_remove_hero_by_id(sid)


func _collect_current_heroes() -> Dictionary:
	var heroes: Dictionary = {}
	for obj in detection_area.get_overlapping_bodies():
		if not (obj is Node2D):
			continue
		var hero := obj as Node2D
		if _is_trackable_hero(hero):
			heroes[hero.get_instance_id()] = hero

	var tree := get_tree()
	if tree == null:
		return heroes

	var radius := _get_detection_radius()
	for hero_node in tree.get_nodes_in_group("hero"):
		if not (hero_node is Node2D):
			continue
		var hero := hero_node as Node2D
		if not _is_trackable_hero(hero):
			continue
		if hero.global_position.distance_to(global_position) > radius:
			continue
		heroes[hero.get_instance_id()] = hero

	return heroes


func _heal_tracked_heroes() -> void:
	for id_variant in _tracked_heroes.keys():
		var entry: Dictionary = _tracked_heroes[id_variant]
		var hero := _resolve_node2d(entry.get("hero_ref"))
		if hero == null or not is_instance_valid(hero):
			continue
		if hero.has_method("heal"):
			hero.heal(int(HEAL_PER_TICK))
		elif "hero_id" in hero:
			var hero_core := _get_autoload("HeroCore")
			if hero_core != null and hero_core.has_method("heal_hero"):
				hero_core.heal_hero(str(hero.hero_id), int(HEAL_PER_TICK))


func _is_trackable_hero(hero: Node2D) -> bool:
	return hero != null \
		and is_instance_valid(hero) \
		and hero.is_in_group("hero") \
		and ("is_invincible" in hero)


func _get_detection_radius() -> float:
	if detection_shape != null and detection_shape.shape is CircleShape2D:
		return (detection_shape.shape as CircleShape2D).radius
	return DEFAULT_RADIUS


func _increment_invincibility(hero: Node2D) -> void:
	var stack_count := int(hero.get_meta(HERO_STACK_META, 0))
	if stack_count <= 0:
		hero.set_meta(HERO_ORIGINAL_STATE_META, bool(hero.get("is_invincible")))
	stack_count += 1
	hero.set_meta(HERO_STACK_META, stack_count)
	hero.set("is_invincible", true)


func _decrement_invincibility(hero: Node2D) -> void:
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


func _remove_hero_by_id(hero_id: int) -> void:
	if not _tracked_heroes.has(hero_id):
		return
	var entry: Dictionary = _tracked_heroes[hero_id]
	var hero := _resolve_node2d(entry.get("hero_ref"))
	if hero != null and is_instance_valid(hero):
		_decrement_invincibility(hero)
		var icon_node := _resolve_node(entry.get("icon_ref"))
		if icon_node != null and is_instance_valid(icon_node):
			icon_node.queue_free()
		StatusIconServiceScript.reflow_status_icons(hero)
	else:
		var icon_node := _resolve_node(entry.get("icon_ref"))
		if icon_node != null and is_instance_valid(icon_node):
			icon_node.queue_free()
	_tracked_heroes.erase(hero_id)


func _cleanup_all() -> void:
	if _tracked_heroes.is_empty():
		return
	var ids: Array[int] = []
	for id_variant in _tracked_heroes.keys():
		ids.append(int(id_variant))
	for hid in ids:
		_remove_hero_by_id(hid)


func _cleanup_and_free() -> void:
	if _is_cleaning_up:
		return
	_is_cleaning_up = true
	set_process(false)
	_cleanup_all()
	_fade_and_destroy()


func _fade_and_destroy() -> void:
	if stand_anim:
		var tween := create_tween()
		tween.tween_property(stand_anim, "modulate:a", 0.0, FADE_OUT_TIME)
		await tween.finished
	queue_free()


func _get_autoload(node_name: String) -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)


func _resolve_node2d(value: Variant) -> Node2D:
	var node := _resolve_node(value)
	if node != null and node is Node2D:
		return node as Node2D
	return null


func _resolve_node(value: Variant) -> Node:
	if value == null:
		return null
	if not (value is WeakRef):
		return null
	var obj: Object = (value as WeakRef).get_ref()
	if obj != null and obj is Node:
		return obj as Node
	return null
