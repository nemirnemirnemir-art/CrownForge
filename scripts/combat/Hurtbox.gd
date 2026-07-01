extends Area2D
class_name Hurtbox

signal damaged(amount: float, source: Node)

@export var health_target_path: NodePath

var _recent_attack_ids: Dictionary = {}

func _ready() -> void:
	monitoring = true
	monitorable = true
	
	# Defer layer setup to ensure parent is fully initialized and in groups
	call_deferred("_setup_collision_layer")
	
	collision_mask = 0

	var has_shape := false
	for child in get_children():
		if child is CollisionShape2D:
			has_shape = true
			break
	if not has_shape:
		push_warning("[Hurtbox] %s: No CollisionShape2D found. Please add it in the .tscn." % (get_parent().name if get_parent() else name))

func _setup_collision_layer() -> void:
	# Set collision layers based on parent type
	# Layer 1 = heroes (detected by mob AggroArea)
	# Layer 2 = enemies (detected by hero projectiles)
	var parent = get_parent()
	if parent:
		if parent.is_in_group("enemy") or parent.name.begins_with("Goblin") or parent.name.begins_with("Orc") or parent.name.begins_with("Skeleton") or parent.name.begins_with("Troll"):
			collision_layer = 2  # Enemies on layer 2
		else:
			collision_layer = 1  # Heroes on layer 1
	elif collision_layer == 0:
		collision_layer = 1
	
	# print("[Hurtbox] %s: collision_layer=%d (in_enemy_group=%s)" % [get_parent().name if get_parent() else "unknown", collision_layer, get_parent().is_in_group("enemy") if get_parent() else false])

func clear_recent_hits() -> void:
	_recent_attack_ids.clear()

func apply_hit(amount: float, source: Node, attack_id: int) -> bool:
	var source_id := 0
	if source and is_instance_valid(source):
		source_id = source.get_instance_id()
	var hit_key := "%s:%s" % [str(source_id), str(attack_id)]
	if _recent_attack_ids.has(hit_key):
		return false
	if _recent_attack_ids.size() > 64:
		_recent_attack_ids.clear()
	_recent_attack_ids[hit_key] = true

	damaged.emit(amount, source)

	var target: Node = null
	if health_target_path != NodePath(""):
		target = get_node_or_null(health_target_path)
	if target == null:
		target = get_parent()

	if target and is_instance_valid(target):
		if target.has_method("apply_damage"):
			target.apply_damage(amount, source)
			return true
		if target.has_method("take_damage"):
			# Many existing scripts use int damage
			target.take_damage(int(round(amount)))
			return true

	return true
