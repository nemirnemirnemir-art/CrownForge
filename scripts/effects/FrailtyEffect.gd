extends SpellEffect

## Frailty - applies damage taken debuff and icon on enemies in area

@onready var frailty_anim: AnimatedSprite2D = $FrailtyAnim
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

const StatusIconServiceScript := preload("res://scripts/effects/shared/StatusIconService.gd")
const FALL_ANIM: StringName = &"fall"
const IMPACT_ANIM: StringName = &"impact"
const FALL_START_OFFSET_Y: float = -520.0
const FALL_TIME: float = 0.35

const DEFAULT_DURATION: float = 7.0
const DEFAULT_RADIUS: float = 80.0
const FRAILTY_DAMAGE_TAKEN_MULTIPLIER: float = 1.30
const ICON_PATH: String = "res://assets/vfx/spells/Frailty.png"
const ICON_OFFSET: Vector2 = Vector2(0.0, -55.0)
const ICON_SIZE: float = 37.5
const FX_SCALE_MULT: float = 1.5

var _affected: Dictionary = {}


func execute_effect() -> void:
	if frailty_anim == null or frailty_anim.sprite_frames == null:
		push_error("[FrailtyEffect] Missing scene-authored FrailtyAnim SpriteFrames")
		queue_free()
		return

	_configure_detection_area()
	await _play_visual_sequence()

	await get_tree().process_frame
	await get_tree().physics_frame
	_apply_debuff_to_targets()

	var duration := DEFAULT_DURATION
	if config != null and config.duration > 0.0:
		duration = config.duration
	await get_tree().create_timer(duration).timeout

	_remove_debuff()
	queue_free()


func _configure_detection_area() -> void:
	if detection_shape != null:
		var shape := CircleShape2D.new()
		shape.radius = _get_base_radius()
		detection_shape.shape = shape

	if detection_area != null:
		detection_area.monitoring = true
		detection_area.monitorable = true


func _play_visual_sequence() -> void:
	frailty_anim.visible = true
	frailty_anim.scale = Vector2.ONE * FX_SCALE_MULT
	frailty_anim.position = Vector2(0.0, FALL_START_OFFSET_Y)
	frailty_anim.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if frailty_anim.sprite_frames.has_animation(FALL_ANIM):
		frailty_anim.play(FALL_ANIM)
	elif frailty_anim.sprite_frames.has_animation(IMPACT_ANIM):
		frailty_anim.play(IMPACT_ANIM)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(frailty_anim, "position", Vector2.ZERO, FALL_TIME)
	await tween.finished

	frailty_anim.position = Vector2.ZERO
	if frailty_anim.sprite_frames.has_animation(IMPACT_ANIM):
		frailty_anim.play(IMPACT_ANIM)
		await frailty_anim.animation_finished
	else:
		await get_tree().create_timer(0.2).timeout

	frailty_anim.visible = false

func _apply_debuff_to_targets() -> void:
	var targets: Array[Node2D] = []
	if detection_area != null:
		for body_any in detection_area.get_overlapping_bodies():
			if body_any is Node2D:
				targets.append(body_any as Node2D)
	if targets.is_empty():
		targets = _collect_enemies_in_radius()

	for enemy in targets:
		if not _is_enemy(enemy):
			continue
		if "is_dead" in enemy and bool(enemy.is_dead):
			continue

		var id := enemy.get_instance_id()
		if _affected.has(id):
			continue
		if not ("damage_taken_multiplier" in enemy):
			continue

		enemy.damage_taken_multiplier = float(enemy.damage_taken_multiplier) * FRAILTY_DAMAGE_TAKEN_MULTIPLIER

		var icon := Sprite2D.new()
		var tex := load(ICON_PATH) as Texture2D
		icon.texture = tex
		icon.name = "FrailtyIcon"
		icon.z_index = 210
		icon.position = ICON_OFFSET
		icon.set_meta("status_icon", true)
		icon.set_meta("status_icon_offset_y", ICON_OFFSET.y)
		if tex != null:
			var size := tex.get_size()
			if size.x > 0.0 and size.y > 0.0:
				icon.scale = Vector2(ICON_SIZE / size.x, ICON_SIZE / size.y)
		enemy.add_child(icon)
		StatusIconServiceScript.reflow_status_icons(enemy)

		_affected[id] = {
			"enemy_ref": weakref(enemy),
			"icon_ref": weakref(icon),
			"applied_mult": FRAILTY_DAMAGE_TAKEN_MULTIPLIER,
		}

func _remove_debuff() -> void:
	for id in _affected.keys():
		var data: Dictionary = _affected[id]
		var enemy_obj := _get_object_from_weakref(data.get("enemy_ref"))
		if enemy_obj != null and is_instance_valid(enemy_obj) and enemy_obj is Node2D:
			var enemy := enemy_obj as Node2D
			if "damage_taken_multiplier" in enemy:
				var applied_mult := float(data.get("applied_mult", 1.0))
				if applied_mult > 0.001:
					enemy.damage_taken_multiplier = maxf(0.01, float(enemy.damage_taken_multiplier) / applied_mult)

		_queue_free_node_from_weakref(data.get("icon_ref"))

		if enemy_obj != null and is_instance_valid(enemy_obj) and enemy_obj is Node2D:
			StatusIconServiceScript.schedule_deferred_reflow(enemy_obj as Node2D)

	_affected.clear()

func _collect_enemies_in_radius() -> Array[Node2D]:
	var result: Array[Node2D] = []
	var tree := get_tree()
	if tree == null:
		return result

	var radius := get_scaled_radius(_get_base_radius())
	var candidates: Array = tree.get_nodes_in_group("enemy")
	candidates.append_array(tree.get_nodes_in_group("mobs"))
	candidates.append_array(tree.get_nodes_in_group("enemies"))

	var dedupe := {}
	for node in candidates:
		if not (node is Node2D):
			continue
		var enemy := node as Node2D
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(global_position) > radius:
			continue
		dedupe[enemy.get_instance_id()] = enemy

	for key in dedupe.keys():
		result.append(dedupe[key])

	return result


func _get_base_radius() -> float:
	if config != null and config.target_radius > 0.0:
		return config.target_radius
	return DEFAULT_RADIUS

func _is_enemy(node: Node2D) -> bool:
	return node.is_in_group("enemy") or node.is_in_group("mobs") or node.is_in_group("enemies")

func _get_object_from_weakref(value: Variant) -> Object:
	if value == null:
		return null
	if not (value is WeakRef):
		return null
	return (value as WeakRef).get_ref() as Object

func _queue_free_node_from_weakref(value: Variant) -> void:
	var obj := _get_object_from_weakref(value)
	if obj != null and is_instance_valid(obj) and obj is Node:
		(obj as Node).queue_free()
