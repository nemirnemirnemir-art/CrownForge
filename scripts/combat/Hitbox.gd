extends Area2D
class_name Hitbox

signal hit_landed(amount: float)

@export var damage: float = 1.0
@export var owner_node_path: NodePath

var attack_id: int = 0
var _enabled: bool = false
var _target_node: Node2D = null  # Specific target for single-target attacks

func _ready() -> void:
	monitoring = true
	monitorable = false
	disabled()
	area_entered.connect(_on_area_entered)

func enabled(new_attack_id: int, new_damage: float, target: Node2D = null) -> void:
	attack_id = new_attack_id
	damage = new_damage
	_target_node = target
	_enabled = true
	monitoring = true
	monitorable = true
	visible = false

func disabled() -> void:
	_enabled = false
	monitoring = false
	monitorable = false
	visible = false

func _get_owner_node() -> Node:
	if owner_node_path != NodePath(""):
		var n = get_node_or_null(owner_node_path)
		if n:
			return n
	return get_parent()

func _on_area_entered(area: Area2D) -> void:
	if not _enabled:
		return
	
	# If we have a specific target, only hit that target
	if _target_node != null:
		var area_parent = area.get_parent()
		if area_parent != _target_node:
			return  # Skip this area if it's not our intended target
	
	if area and area.has_method("apply_hit"):
		if area.apply_hit(damage, _get_owner_node(), attack_id):
			hit_landed.emit(damage)
