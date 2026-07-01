extends SpellEffect

## Landmine spell effect - triggers when enemy steps on it, explodes after 1 second

const TRIGGER_RADIUS_SCALE: float = 1.0
const VISUAL_SCALE: float = 0.7

@onready var mine_sprite: Sprite2D = $MineSprite
@onready var trigger_area: Area2D = $TriggerArea
@onready var trigger_collision: CollisionShape2D = $TriggerArea/CollisionShape2D
@onready var explosion_area: Area2D = $ExplosionArea
@onready var explosion_collision: CollisionShape2D = $ExplosionArea/CollisionShape2D
@onready var explosion_anim: AnimatedSprite2D = $ExplosionAnim

var _triggered: bool = false
var _explosion_timer: float = 0.0
var _explosion_triggered: bool = false

var _trigger_enemy: Node2D = null

const EXPLOSION_DELAY: float = 1.0  # 1 second delay after trigger

func execute_effect() -> void:
    if not mine_sprite or not trigger_area or not explosion_area:
        push_error("[LandmineEffect] Missing required nodes")
        queue_free()
        return

    trigger_area.monitoring = true
    trigger_area.monitorable = true
    explosion_area.monitoring = true
    explosion_area.monitorable = true

    # Hurtboxes are expected on layer 2, but some enemies may end up on layer 1.
    # Detect both and filter by groups in code.
    trigger_area.collision_mask = 0x7fffffff
    explosion_area.collision_mask = 0x7fffffff
    
    # Show mine, hide explosion initially
    mine_sprite.visible = true
    if explosion_anim:
        explosion_anim.visible = false

    mine_sprite.scale = Vector2.ONE * VISUAL_SCALE

    # Setup trigger area (small collision for stepping on mine)
    trigger_collision.disabled = false
    var trigger_radius: float = 80.0
    if config and config.target_radius > 0.0:
        trigger_radius = float(config.target_radius) * TRIGGER_RADIUS_SCALE
    var trigger_shape := CircleShape2D.new()
    trigger_shape.radius = trigger_radius
    trigger_collision.shape = trigger_shape

    # Setup explosion area (disabled until triggered)
    explosion_collision.disabled = true
    if config:
        var radius: float = 80.0
        if config.target_radius > 0:
            radius = float(config.target_radius)
        var shape := CircleShape2D.new()
        shape.radius = radius
        explosion_collision.shape = shape
    
    # Connect trigger signal
    if not trigger_area.body_entered.is_connected(_on_body_entered_trigger):
        trigger_area.body_entered.connect(_on_body_entered_trigger)
    if trigger_area.has_signal("area_entered") and not trigger_area.area_entered.is_connected(_on_area_entered_trigger):
        trigger_area.area_entered.connect(_on_area_entered_trigger)

    # Wait for physics to register overlaps, then check for enemies already inside
    await get_tree().physics_frame
    _scan_initial_overlaps()


func _on_area_entered_trigger(area: Area2D) -> void:
    _on_body_entered_trigger(area)

func _scan_initial_overlaps() -> void:
    if _triggered:
        return

    # Check bodies already overlapping
    for body in trigger_area.get_overlapping_bodies():
        if _triggered:
            return
        _on_body_entered_trigger(body)

    # Check areas already overlapping
    for area in trigger_area.get_overlapping_areas():
        if _triggered:
            return
        _on_area_entered_trigger(area)

    # Fallback: group-based radius scan
    if _triggered:
        return
    var tree := get_tree()
    if tree == null:
        return
    var trigger_radius: float = 80.0
    if trigger_collision and trigger_collision.shape is CircleShape2D:
        trigger_radius = (trigger_collision.shape as CircleShape2D).radius

    var candidates: Array = []
    candidates.append_array(tree.get_nodes_in_group("enemy"))
    candidates.append_array(tree.get_nodes_in_group("mobs"))
    candidates.append_array(tree.get_nodes_in_group("enemies"))

    for node in candidates:
        if _triggered:
            return
        if not (node is Node2D):
            continue
        var enemy := node as Node2D
        if enemy.global_position.distance_to(global_position) <= trigger_radius:
            _on_body_entered_trigger(enemy)

func _on_body_entered_trigger(body: Node2D) -> void:
    var enemy := _resolve_enemy_from_collider(body)
    if enemy == null:
        return
    
    # Trigger mine (only once)
    if not _triggered:
        _triggered = true
        _trigger_enemy = enemy
        trigger_collision.set_deferred("disabled", true)  # Disable further triggers (avoid flushing queries)
        # print("[LandmineEffect] Triggered by %s, exploding in %.1fs" % [enemy.name, EXPLOSION_DELAY])

func _resolve_enemy_from_collider(collider: Object) -> Node2D:
    if collider == null:
        return null
    var enemy: Node2D = null
    if collider is Hurtbox:
        var p := (collider as Hurtbox).get_parent()
        if p is Node2D:
            enemy = p
    elif collider is Node2D:
        enemy = collider as Node2D
    if enemy == null:
        return null
    if not enemy.is_in_group("enemy") and not enemy.is_in_group("enemies") and not enemy.is_in_group("mobs"):
        return null
    return enemy

func _process(delta: float) -> void:
    if not _triggered or _explosion_triggered:
        return
    
    _explosion_timer += delta
    
    if _explosion_timer >= EXPLOSION_DELAY:
        _trigger_explosion()

func _trigger_explosion() -> void:
    _explosion_triggered = true
    
    # Hide mine, show explosion
    if mine_sprite:
        mine_sprite.visible = false
    
    if explosion_anim:
        explosion_anim.visible = true
        if explosion_anim.sprite_frames and explosion_anim.sprite_frames.has_animation("explode"):
            explosion_anim.play("explode")
        elif explosion_anim.sprite_frames and explosion_anim.sprite_frames.has_animation("default"):
            explosion_anim.play("default")
    
    # Enable collision briefly to deal damage.
    # Important: enable via deferred and wait one physics frame so overlaps are up-to-date.
    explosion_collision.set_deferred("disabled", false)
    await get_tree().physics_frame
    _deal_explosion_damage()
    
    # Disable collision after damage dealt
    await get_tree().create_timer(0.1).timeout
    explosion_collision.set_deferred("disabled", true)
    
    # Wait for animation to finish, then cleanup
    await get_tree().create_timer(0.5).timeout
    queue_free()

func _deal_explosion_damage() -> void:
    if not explosion_area:
        return
    
    var damage_amount: float = 90.0
    if config:
        damage_amount = float(config.damage)
    var attack_id: int = Time.get_ticks_msec()

    # Always try to damage the triggering enemy first (in case AoE query misses)
    if _trigger_enemy and is_instance_valid(_trigger_enemy):
        var hb0 = _trigger_enemy.get_node_or_null("Hurtbox")
        if hb0 and hb0.has_method("apply_hit"):
            hb0.apply_hit(damage_amount, self, attack_id)
        elif _trigger_enemy.has_method("take_damage"):
            _trigger_enemy.take_damage(damage_amount)

    # Query physics directly (more reliable than get_overlapping_* for one-shot explosions)
    var radius: float = 80.0
    if config and config.target_radius > 0.0:
        radius = float(config.target_radius)
    var shape := CircleShape2D.new()
    shape.radius = radius

    var params := PhysicsShapeQueryParameters2D.new()
    params.shape = shape
    params.transform = Transform2D(0.0, global_position)
    params.collision_mask = 0x7fffffff
    params.collide_with_areas = true
    params.collide_with_bodies = true

    var results: Array = get_world_2d().direct_space_state.intersect_shape(params, 64)
    var seen: Dictionary = {}

    for r in results:
        var collider: Object = r.get("collider")
        if collider == null:
            continue

        # Priority 0: Hurtbox areas
        if collider is Hurtbox:
            var hb: Hurtbox = collider
            var hb_parent := hb.get_parent()
            if hb_parent and hb_parent is Node and not hb_parent.is_in_group("enemy") and not hb_parent.is_in_group("enemies") and not hb_parent.is_in_group("mobs"):
                continue
            if seen.has(hb):
                continue
            seen[hb] = true
            hb.apply_hit(damage_amount, self, attack_id)
            continue

        var body := collider as Node2D
        if body == null:
            continue

        # Optional safety: only damage enemies
        if not body.is_in_group("enemy") and not body.is_in_group("enemies") and not body.is_in_group("mobs"):
            continue

        if seen.has(body):
            continue
        seen[body] = true

        # Priority 1: Use Hurtbox (standard enemy system)
        var hurtbox = body.get_node_or_null("Hurtbox")
        if hurtbox and hurtbox.has_method("apply_hit"):
            hurtbox.apply_hit(damage_amount, self, attack_id)
            continue

        # Priority 2: Direct take_damage
        if body.has_method("take_damage"):
            body.take_damage(damage_amount)
            continue

        # Priority 3: Health component
        if body.has_node("Components/Health"):
            var health = body.get_node("Components/Health")
            if health and health.has_method("take_damage"):
                health.take_damage(damage_amount)

    var nodes: Array = []
    nodes.append_array(get_tree().get_nodes_in_group("enemy"))
    nodes.append_array(get_tree().get_nodes_in_group("enemies"))
    nodes.append_array(get_tree().get_nodes_in_group("mobs"))

    for n in nodes:
        var mob := n as Node2D
        if mob == null:
            continue
        if mob.global_position.distance_to(global_position) > radius:
            continue
        if seen.has(mob):
            continue
        seen[mob] = true

        var hb = mob.get_node_or_null("Hurtbox")
        if hb and hb.has_method("apply_hit"):
            hb.apply_hit(damage_amount, self, attack_id)
            continue
        if mob.has_method("take_damage"):
            mob.take_damage(damage_amount)
