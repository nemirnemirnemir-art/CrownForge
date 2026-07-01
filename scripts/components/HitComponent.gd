extends Area2D
class_name HitComponent

signal hit_landed(amount: float)

@export var damage: float = 1.0
@export var owner_node_path: NodePath

var attack_id: int = 0
var _enabled: bool = false
var _has_hit_in_this_cycle: bool = false

func _ready() -> void:
    monitoring = false
    monitorable = false
    visible = false

    # Auto-config collisions if scene forgot.
    # Rule: hero hitbox hits enemy hurtbox (layer 2); enemy hitbox hits hero hurtbox (layer 1)
    var owner_node := _get_owner_node()
    if owner_node and owner_node is Node:
        var is_hero := (owner_node as Node).is_in_group("hero")
        var is_enemy := (owner_node as Node).is_in_group("enemy")

        if collision_layer == 0:
            if is_hero:
                collision_layer = 4
                print("[HitComponent] Auto collision_layer=4 (hero hitbox)")
            elif is_enemy:
                collision_layer = 2
                print("[HitComponent] Auto collision_layer=2 (enemy hitbox)")

        if collision_mask == 0:
            if is_hero:
                collision_mask = 2
                print("[HitComponent] Auto collision_mask=2 (hit enemy hurtbox)")
            elif is_enemy:
                collision_mask = 1
                print("[HitComponent] Auto collision_mask=1 (hit hero hurtbox)")

    area_entered.connect(_on_area_entered)
    _disable_all_shapes()

func enabled(new_attack_id: int, new_damage: float) -> void:
    attack_id = new_attack_id
    damage = new_damage
    _enabled = true
    _has_hit_in_this_cycle = false
    monitoring = true
    monitorable = true
    _enable_all_shapes()
    visible = true

func disabled() -> void:
    _enabled = false
    monitoring = false
    monitorable = false
    _disable_all_shapes()
    visible = false

func _enable_all_shapes() -> void:
    for c in get_children():
        if c is CollisionShape2D:
            (c as CollisionShape2D).disabled = false

func _disable_all_shapes() -> void:
    for c in get_children():
        if c is CollisionShape2D:
            (c as CollisionShape2D).disabled = true

func _get_owner_node() -> Node:
    if owner_node_path != NodePath(""):
        var n = get_node_or_null(owner_node_path)
        if n:
            return n
    return get_parent()

func _on_area_entered(area: Area2D) -> void:
    if not _enabled or _has_hit_in_this_cycle:
        return
    var owner_node := _get_owner_node()
    if owner_node and area and area.get_parent() == owner_node:
        return
    if area and area.has_method("apply_hit"):
        if area.apply_hit(damage, owner_node, attack_id):
            _has_hit_in_this_cycle = true
            hit_landed.emit(damage)
