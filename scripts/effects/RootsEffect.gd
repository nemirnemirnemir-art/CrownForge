extends SpellEffect

## Roots spell - spawns roots that push enemies and deal poison
## 60 impact damage + 56 poison damage (4 ticks of 14)

const SpellDamageApplicatorScript := preload("res://scripts/effects/shared/SpellDamageApplicator.gd")

@onready var roots_anim: AnimatedSprite2D = $RootsAnim
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D

const IMPACT_DAMAGE: float = 60.0
const POISON_DAMAGE: float = 14.0
const POISON_TICKS: int = 4
const PUSH_FORCE: float = 100.0
const DEFAULT_RADIUS: float = 60.0
const VISUAL_SPAWN_TIME: float = 0.18
const DEFAULT_ANIMATION: StringName = &"grow"

var _affected_enemies: Dictionary = {}
var _damage_applicator: RefCounted = SpellDamageApplicatorScript.new()


func execute_effect() -> void:
	if not roots_anim or roots_anim.sprite_frames == null or not damage_area or not damage_shape:
		push_error("[RootsEffect] Missing required nodes")
		queue_free()
		return

	_configure_damage_area()
	_play_spawn_visual()
	_deal_damage_and_push(_collect_targets())
	_apply_poison_to_targets()


func _configure_damage_area() -> void:
	var shape := CircleShape2D.new()
	shape.radius = _get_base_radius()
	damage_shape.shape = shape
	damage_area.monitoring = true
	damage_area.monitorable = true


func _play_spawn_visual() -> void:
	roots_anim.visible = true
	roots_anim.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var base_scale := maxf(0.75, _get_base_radius() / DEFAULT_RADIUS)
	roots_anim.scale = Vector2.ONE * (base_scale * 0.7)

	if roots_anim.sprite_frames.has_animation(DEFAULT_ANIMATION):
		roots_anim.play(DEFAULT_ANIMATION)
	elif roots_anim.sprite_frames.has_animation("default"):
		roots_anim.play("default")

	var tween := create_tween()
	tween.parallel().tween_property(roots_anim, "modulate:a", 1.0, VISUAL_SPAWN_TIME)
	tween.parallel().tween_property(roots_anim, "scale", Vector2.ONE * base_scale, VISUAL_SPAWN_TIME)


func _collect_targets() -> Array[Node2D]:
	var result: Array[Node2D] = []
	var dedupe := {}

	for obj in damage_area.get_overlapping_bodies():
		if not (obj is Node2D):
			continue
		var body := obj as Node2D
		if not _is_valid_enemy(body):
			continue
		dedupe[body.get_instance_id()] = body

	var tree := get_tree()
	if tree != null:
		var radius := get_scaled_radius(_get_base_radius())
		var candidates: Array = tree.get_nodes_in_group("enemy")
		candidates.append_array(tree.get_nodes_in_group("mobs"))
		candidates.append_array(tree.get_nodes_in_group("enemies"))

		for node in candidates:
			if not (node is Node2D):
				continue
			var enemy := node as Node2D
			if not _is_valid_enemy(enemy):
				continue
			if enemy.global_position.distance_to(global_position) > radius:
				continue
			dedupe[enemy.get_instance_id()] = enemy

	for enemy_id in dedupe.keys():
		result.append(dedupe[enemy_id])

	return result


func _deal_damage_and_push(targets: Array[Node2D]) -> void:
	for body in targets:
		var attack_id := Time.get_ticks_msec() + body.get_instance_id()
		_damage_applicator.apply_damage(body, get_scaled_damage(IMPACT_DAMAGE), self, attack_id)
		_push_enemy(body)
		_affected_enemies[body.get_instance_id()] = weakref(body)


func _push_enemy(body: Node2D) -> void:
	if not ("velocity" in body):
		return

	var push_direction := (body.global_position - global_position).normalized()
	if push_direction == Vector2.ZERO:
		push_direction = Vector2.RIGHT
	body.velocity += push_direction * PUSH_FORCE

func _apply_poison_to_targets() -> void:
	for i in range(POISON_TICKS):
		await get_tree().create_timer(1.0).timeout

		for enemy_id_variant in _affected_enemies.keys().duplicate():
			var enemy_id := int(enemy_id_variant)
			var enemy := _resolve_enemy(enemy_id)
			if enemy == null:
				_affected_enemies.erase(enemy_id)
				continue

			var attack_id := Time.get_ticks_msec() + i + enemy_id
			_damage_applicator.apply_damage(enemy, POISON_DAMAGE, self, attack_id)

	queue_free()


func _resolve_enemy(enemy_id: int) -> Node2D:
	if not _affected_enemies.has(enemy_id):
		return null

	var enemy_ref: Variant = _affected_enemies[enemy_id]
	if not (enemy_ref is WeakRef):
		return null

	var enemy_obj: Object = (enemy_ref as WeakRef).get_ref()
	if enemy_obj != null and enemy_obj is Node2D and is_instance_valid(enemy_obj):
		return enemy_obj as Node2D
	return null


func _is_valid_enemy(node: Node2D) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if "is_dead" in node and bool(node.is_dead):
		return false
	return node.is_in_group("enemy") or node.is_in_group("mobs") or node.is_in_group("enemies")


func _get_base_radius() -> float:
	if config != null and config.target_radius > 0.0:
		return config.target_radius
	return DEFAULT_RADIUS
