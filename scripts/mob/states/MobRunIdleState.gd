extends MobState
class_name MobRunIdleState

## State for Wall Buster - runs for 4s, idles for 1s, repeats, explodes on wall contact

const EXPLOSION_DAMAGE: float = 3.0
const WALL_CONTACT_THRESHOLD: float = 12.0
var _has_exploded: bool = false

func enter() -> void:
    _has_exploded = false
    mob.play_walk()
    # print("[MobRunIdleState] %s running to wall" % mob.name)

func update(_delta: float) -> void:
    if _has_exploded:
        return

func physics_update(delta: float) -> void:
    if _has_exploded:
        return
    _move_forward(delta)
    _check_wall_collision()

func _move_forward(_delta: float) -> void:
    # Move toward wall/castle
    var target_pos := Vector2.ZERO
    if mob and mob.has_method("get_wall_contact_position"):
        target_pos = mob.get_wall_contact_position()
    elif target_pos == Vector2.ZERO:
        var wall = mob.get_tree().get_first_node_in_group("wall")
        if wall and is_instance_valid(wall) and wall is Node2D:
            target_pos = (wall as Node2D).global_position
    if target_pos == Vector2.ZERO:
        target_pos = mob.bridge_position

    var direction := (target_pos - mob.global_position).normalized()
    var move_speed: float = mob.get_effective_move_speed() if mob.has_method("get_effective_move_speed") else float(mob.move_speed)
    mob.velocity = direction * move_speed
    mob.move_and_slide()
    if mob.has_method("enforce_battlefield_bounds"):
        var bounced_direction: Vector2 = mob.enforce_battlefield_bounds(direction)
        if bounced_direction != direction and bounced_direction != Vector2.ZERO:
            mob.velocity = bounced_direction * move_speed

func _check_wall_collision() -> void:
    if _has_exploded: return

    if mob and mob.has_method("get_distance_to_wall") and mob.has_method("get_wall_target_node"):
        var wall_distance: float = float(mob.get_distance_to_wall())
        var wall_target: Node = mob.get_wall_target_node()
        if wall_target and wall_distance <= WALL_CONTACT_THRESHOLD:
            _trigger_explosion(wall_target)
            return

    # Prefer physics collision results
    var count: int = mob.get_slide_collision_count()
    if count > 0:
        for i in range(count):
            var c: KinematicCollision2D = mob.get_slide_collision(i)
            if c:
                var collider: Object = c.get_collider()
                if collider:
                    _trigger_explosion(collider)
                    return

    # Fallback: point query (areas/bodies)
    var wall = _find_nearby_wall()
    if wall:
        _trigger_explosion(wall)

func _find_nearby_wall() -> Node:
    # Look for wall in collision/proximity
    var space_state = mob.get_world_2d().direct_space_state
    var query = PhysicsPointQueryParameters2D.new()
    query.position = mob.global_position
    query.collision_mask = 128  # Wall layer (layer 8)
    query.collide_with_areas = true
    query.collide_with_bodies = true
    
    var result = space_state.intersect_point(query, 1)
    if result.size() > 0:
        return result[0].collider
    return null

func _trigger_explosion(wall: Node) -> void:
    _has_exploded = true
    # print("[MobRunIdleState] %s EXPLODING! Dealing %.1f damage to wall" % [mob.name, EXPLOSION_DAMAGE])
    
    # Stop movement
    mob.velocity = Vector2.ZERO
    
    # Deal damage to wall
    if wall.has_method("take_damage"):
        wall.take_damage(int(EXPLOSION_DAMAGE))

    # Die via standard pipeline so AnimDead plays and cleanup/rewards happen once
    if state_machine and state_machine.has_method("change_state"):
        state_machine.change_state("MobDeathState")
    elif mob and mob.has_method("die"):
        mob.die()

func exit() -> void:
    mob.velocity = Vector2.ZERO
