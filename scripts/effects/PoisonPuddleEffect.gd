extends SpellEffect

## Poison Puddle spell effect - creates DoT zone dealing 24 DPS for 9 seconds

const SpellEnemyTrackerScript := preload("res://scripts/effects/shared/SpellEnemyTracker.gd")

@onready var puddle_anim: AnimatedSprite2D = $PuddleAnim
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D

const PUDDLE_DURATION: float = 9.0
const DAMAGE_PER_TICK: float = 24.0
const TICK_INTERVAL: float = 1.0
const CHECK_INTERVAL: float = 0.2
const POISON_BLEND_COLOR: Color = Color(0.45, 1.0, 0.45, 1.0)
const POISON_BLEND_STRENGTH: float = 0.7
const POISON_STACK_META: StringName = &"poison_puddle_stack_count"
const POISON_BASE_MODULATE_META: StringName = &"poison_puddle_base_modulate"

var _duration_remaining: float = PUDDLE_DURATION
var _tick_timer: float = 0.0
var _check_timer: float = 0.0
var _damaged_this_tick: Dictionary = {}  # Track who was damaged to prevent stacking
var _poisoned_enemies: Dictionary = {}
var _is_cleaning_up: bool = false
var _enemy_tracker: RefCounted = SpellEnemyTrackerScript.new()

func execute_effect() -> void:
	if not puddle_anim or not damage_area or not damage_shape:
		push_error("[PoisonPuddleEffect] Missing required nodes")
		queue_free()
		return

	damage_area.monitoring = true
	damage_area.monitorable = true
	
	# Set puddle radius
	if config:
		_duration_remaining = config.duration if config.duration > 0.0 else PUDDLE_DURATION
		var shape := CircleShape2D.new()
		shape.radius = config.target_radius if config.target_radius > 0 else 80.0
		damage_shape.shape = shape
	
	# Play puddle animation
	if puddle_anim.sprite_frames:
		if puddle_anim.sprite_frames.has_animation("puddle"):
			puddle_anim.play("puddle")
		elif puddle_anim.sprite_frames.has_animation("default"):
			puddle_anim.play("default")

	set_process(true)

func _process(delta: float) -> void:
	if _is_cleaning_up:
		return

	_duration_remaining -= delta
	_tick_timer += delta
	_check_timer += delta

	if _check_timer >= CHECK_INTERVAL:
		_check_timer = 0.0
		_update_poisoned_enemies()
	
	# Deal damage every second
	if _tick_timer >= TICK_INTERVAL:
		_tick_timer = 0.0
		_deal_tick_damage()
		_damaged_this_tick.clear()
	
	# Fade out and destroy when duration expires
	if _duration_remaining <= 0.0:
		set_process(false)
		_remove_all_poison_visuals()
		_fade_and_destroy()


func _exit_tree() -> void:
	_remove_all_poison_visuals()

func _deal_tick_damage() -> void:
	if not damage_area:
		return

	var dps := DAMAGE_PER_TICK
	if config and config.damage_per_second > 0.0:
		dps = config.damage_per_second
	var dmg := dps * TICK_INTERVAL
	var attack_id: int = Time.get_ticks_msec()
	
	var overlaps: Array = []
	overlaps.append_array(damage_area.get_overlapping_areas())
	overlaps.append_array(damage_area.get_overlapping_bodies())
	
	for obj in overlaps:
		# Priority 0: Hurtbox area (most reliable for this project)
		if obj is Hurtbox:
			var hb: Hurtbox = obj
			if _damaged_this_tick.has(hb):
				continue
			hb.apply_hit(dmg, self, attack_id)
			_damaged_this_tick[hb] = true
			continue
		
		var body := obj as Node2D
		if body == null:
			continue
		if _damaged_this_tick.has(body):
			continue
		
		# Priority 1: Use Hurtbox child if available
		var hurtbox = body.get_node_or_null("Hurtbox")
		if hurtbox and hurtbox.has_method("apply_hit"):
			hurtbox.apply_hit(dmg, self, attack_id)
			_damaged_this_tick[body] = true
			continue
		
		# Priority 2: Direct take_damage method (fallback)
		if body.has_method("take_damage"):
			body.take_damage(dmg)
			_damaged_this_tick[body] = true
			continue
		
		# Priority 3: Health component (legacy support)
		if body.has_node("Components/Health"):
			var health = body.get_node("Components/Health")
			if health and health.has_method("take_damage"):
				health.take_damage(dmg)
				_damaged_this_tick[body] = true


func _update_poisoned_enemies() -> void:
	if damage_area == null:
		return

	var current_enemies: Dictionary = {}
	var overlaps: Array = []
	overlaps.append_array(damage_area.get_overlapping_areas())
	overlaps.append_array(damage_area.get_overlapping_bodies())

	for obj in overlaps:
		var enemy: Node2D = _enemy_tracker.resolve_enemy_from_collider(obj)
		if enemy == null:
			continue
		current_enemies[enemy.get_instance_id()] = enemy

	for enemy in _collect_fallback_targets():
		current_enemies[enemy.get_instance_id()] = enemy

	for id_variant in current_enemies.keys():
		var id := int(id_variant)
		if not _poisoned_enemies.has(id):
			_apply_poison_visual(current_enemies[id])

	var stale_ids: Array[int] = []
	for id_variant in _poisoned_enemies.keys():
		var id := int(id_variant)
		if not current_enemies.has(id):
			stale_ids.append(id)

	for id in stale_ids:
		_remove_poison_visual(id)


func _collect_fallback_targets() -> Array[Node2D]:
	if get_tree() == null:
		return []
	return _enemy_tracker.collect_tree_enemies_in_radius(get_tree().root, global_position, _get_damage_radius(), true)


func _get_damage_radius() -> float:
	if damage_shape != null and damage_shape.shape is CircleShape2D:
		return (damage_shape.shape as CircleShape2D).radius
	return 80.0


func _apply_poison_visual(enemy: Node2D) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return

	var id := enemy.get_instance_id()
	if _poisoned_enemies.has(id):
		return

	_increment_poison_visual_stack(enemy)
	_poisoned_enemies[id] = {
		"enemy_ref": weakref(enemy),
	}


func _remove_poison_visual(id: int) -> void:
	if not _poisoned_enemies.has(id):
		return

	var data: Dictionary = _poisoned_enemies[id]
	var enemy: Node2D = _resolve_enemy_from_entry(data)
	if enemy != null and is_instance_valid(enemy):
		_decrement_poison_visual_stack(enemy)

	_poisoned_enemies.erase(id)


func _remove_all_poison_visuals() -> void:
	if _poisoned_enemies.is_empty():
		return

	var ids: Array[int] = []
	for id_variant in _poisoned_enemies.keys():
		ids.append(int(id_variant))

	for id in ids:
		_remove_poison_visual(id)


func _increment_poison_visual_stack(enemy: Node2D) -> void:
	var stack_count := int(enemy.get_meta(POISON_STACK_META, 0))
	if stack_count <= 0:
		enemy.set_meta(POISON_BASE_MODULATE_META, enemy.modulate)
	stack_count += 1
	enemy.set_meta(POISON_STACK_META, stack_count)
	enemy.modulate = _get_poisoned_modulate(enemy)


func _decrement_poison_visual_stack(enemy: Node2D) -> void:
	var stack_count := int(enemy.get_meta(POISON_STACK_META, 0))
	if stack_count <= 0:
		return

	stack_count -= 1
	if stack_count > 0:
		enemy.set_meta(POISON_STACK_META, stack_count)
		enemy.modulate = _get_poisoned_modulate(enemy)
		return

	var base_modulate: Variant = enemy.get_meta(POISON_BASE_MODULATE_META, Color.WHITE)
	enemy.remove_meta(POISON_STACK_META)
	enemy.remove_meta(POISON_BASE_MODULATE_META)
	if base_modulate is Color:
		enemy.modulate = base_modulate as Color


func _get_poisoned_modulate(enemy: Node2D) -> Color:
	var base_modulate: Variant = enemy.get_meta(POISON_BASE_MODULATE_META, enemy.modulate)
	if base_modulate is Color:
		return (base_modulate as Color).lerp(POISON_BLEND_COLOR, POISON_BLEND_STRENGTH)
	return enemy.modulate.lerp(POISON_BLEND_COLOR, POISON_BLEND_STRENGTH)


func _resolve_enemy_from_entry(entry: Dictionary) -> Node2D:
	var enemy_ref: Variant = entry.get("enemy_ref")
	if enemy_ref == null or not (enemy_ref is WeakRef):
		return null
	var obj: Object = (enemy_ref as WeakRef).get_ref()
	if obj != null and obj is Node2D:
		return obj as Node2D
	return null

func _fade_and_destroy() -> void:
	if _is_cleaning_up:
		return
	_is_cleaning_up = true

	# Simple fade out
	if puddle_anim:
		var tween := create_tween()
		tween.tween_property(puddle_anim, "modulate:a", 0.0, 0.5)
		await tween.finished
	
	queue_free()
