extends SpellEffect

## Banish spell - hides allied units for 30 seconds, awards 6 crystal per unit on return

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

const BANISH_DURATION: float = 30.0
const CRYSTAL_PER_UNIT: int = 6

const FX_ANIM_NAME: StringName = &"default"
const FX_DUST2_FPS: float = 18.0
const FX_BANISH_FPS: float = 12.0

static var _cached_dust2_frames: SpriteFrames = null
static var _cached_lamp_frames: SpriteFrames = null

var _banished_allies: Array[Dictionary] = []

func execute_effect() -> void:
    if not detection_area or not detection_shape:
        push_error("[BanishEffect] Missing required nodes")
        queue_free()
        return
    
    if config:
        var shape := CircleShape2D.new()
        shape.radius = config.target_radius if config.target_radius > 0 else 80.0
        detection_shape.shape = shape
    
    # Target heroes (layers 1, 2, 4 to be safe)
    detection_area.collision_mask = 7
    
    var duration := BANISH_DURATION
    if config != null and config.duration > 0.0:
        duration = config.duration

    await get_tree().process_frame
    await get_tree().physics_frame
    await get_tree().physics_frame
    _banish_allies()
    
    await get_tree().create_timer(duration).timeout
    _return_allies()
    queue_free()

func _banish_allies() -> void:
    if not detection_area:
        return
    
    var bodies: Array[Node2D] = detection_area.get_overlapping_bodies()
    if bodies.is_empty():
        bodies = _collect_heroes_in_radius()
    
    for body in bodies:
        if not body.is_in_group("hero"):
            continue

        var parent_for_fx: Node = get_tree().current_scene
        if get_parent() != null:
            parent_for_fx = get_parent()

        var banish_pos: Vector2 = body.global_position
        var dust_fx := _spawn_fx(parent_for_fx, _get_or_create_dust2_frames(), banish_pos, false)
        var banish_fx := _spawn_fx(parent_for_fx, _get_or_create_lamp_frames(), banish_pos, true)

        var data := {
            "unit_ref": weakref(body),
            "original_visible": body.visible,
            "original_position": body.global_position,
            "original_collision_layer": body.collision_layer if "collision_layer" in body else 0,
            "original_collision_mask": body.collision_mask if "collision_mask" in body else 0,
            "original_process_mode": body.process_mode,
            "original_is_processing": body.is_processing(),
            "original_is_physics_processing": body.is_physics_processing(),
            "fx_ref": weakref(banish_fx) if banish_fx != null else null,
            "dust_fx_ref": weakref(dust_fx) if dust_fx != null else null,
        }
        _banished_allies.append(data)
        
        # Hide unit completely
        body.visible = false
        if "collision_layer" in body:
            body.collision_layer = 0
        if "collision_mask" in body:
            body.collision_mask = 0

        body.process_mode = Node.PROCESS_MODE_DISABLED
        body.set_process(false)
        body.set_physics_process(false)
        
        # Remove from combat
        if body.has_method("release_current_slot"):
            body.release_current_slot()
        
        # print("[BanishEffect] Banished %s for %.1fs" % [body.name, BANISH_DURATION])

func _collect_heroes_in_radius() -> Array[Node2D]:
    var result: Array[Node2D] = []
    var tree := get_tree()
    if tree == null:
        return result

    var radius := 80.0
    if config != null and config.target_radius > 0.0:
        radius = get_scaled_radius(config.target_radius)

    for node in tree.get_nodes_in_group("hero"):
        if not (node is Node2D):
            continue
        var hero := node as Node2D
        if not is_instance_valid(hero):
            continue
        if hero.global_position.distance_to(global_position) > radius:
            continue
        result.append(hero)

    return result

func _return_allies() -> void:
    var crystal_total: int = 0
    var town_core := _get_autoload("TownCore")
    var resource_core := _get_autoload("ResourceCore")
    
    for data in _banished_allies:
        _queue_free_node_from_weakref(data.get("fx_ref"))
        _queue_free_node_from_weakref(data.get("dust_fx_ref"))

        var body := _get_node2d_from_weakref(data.get("unit_ref"))
        if body == null:
            continue
        
        # Restore visibility
        body.visible = data.get("original_visible", true)

        var restored_mode: int = data.get("original_process_mode", Node.PROCESS_MODE_INHERIT)
        if restored_mode is int:
            # Валидация и прямой enum casting
            if restored_mode == 0:  # PROCESS_MODE_INHERIT
                restored_mode = Node.PROCESS_MODE_INHERIT
            elif restored_mode == 1:  # PROCESS_MODE_PAUSABLE
                restored_mode = Node.PROCESS_MODE_PAUSABLE
            elif restored_mode == 2:  # PROCESS_MODE_WHEN_PAUSED
                restored_mode = Node.PROCESS_MODE_WHEN_PAUSED
            elif restored_mode == 3:  # PROCESS_MODE_DISABLED
                restored_mode = Node.PROCESS_MODE_DISABLED
            else:
                restored_mode = Node.PROCESS_MODE_INHERIT
        body.process_mode = restored_mode
        body.set_process(bool(data.get("original_is_processing", true)))
        body.set_physics_process(bool(data.get("original_is_physics_processing", true)))
        body.global_position = data.get("original_position", body.global_position)
        
        # Restore collision
        if "collision_layer" in body:
            body.collision_layer = data.get("original_collision_layer", 0)
        if "collision_mask" in body:
            body.collision_mask = data.get("original_collision_mask", 0)
        
        # Award crystal
        crystal_total += CRYSTAL_PER_UNIT
        # print("[BanishEffect] %s returned, awarding %d crystal" % [body.name, CRYSTAL_PER_UNIT])
    
    # Add potions to player resources
    if crystal_total > 0:
        if town_core != null and town_core.has_method("add_potions"):
            town_core.add_potions(crystal_total)
        elif resource_core != null and resource_core.has_method("add_resource"):
            resource_core.add_resource("potion", crystal_total)
        
        # print("[BanishEffect] Total potions awarded: %d" % crystal_total)
    
    _banished_allies.clear()

func _get_or_create_dust2_frames() -> SpriteFrames:
    if _cached_dust2_frames != null:
        return _cached_dust2_frames
    _cached_dust2_frames = _build_fx_frames("res://assets/vfx/Particle FX/Dust2", "Dust", 2, 11, FX_DUST2_FPS, false)
    return _cached_dust2_frames

func _get_or_create_lamp_frames() -> SpriteFrames:
    if _cached_lamp_frames != null:
        return _cached_lamp_frames
    
    var frames := SpriteFrames.new()
    if not frames.has_animation(FX_ANIM_NAME):
        frames.add_animation(FX_ANIM_NAME)
    frames.set_animation_speed(FX_ANIM_NAME, FX_BANISH_FPS)
    frames.set_animation_loop(FX_ANIM_NAME, true)

    for idx in range(1, 5):
        var frame_path := "res://assets/vfx/spells_visuals/lamp/%d.png" % idx
        if ResourceLoader.exists(frame_path):
            var texture := load(frame_path) as Texture2D
            if texture != null:
                frames.add_frame(FX_ANIM_NAME, texture)

    _cached_lamp_frames = frames
    return _cached_lamp_frames

func _build_fx_frames(folder: String, base: String, start_idx: int, end_idx: int, fps: float, loop: bool) -> SpriteFrames:
    var frames := SpriteFrames.new()
    if not frames.has_animation(FX_ANIM_NAME):
        frames.add_animation(FX_ANIM_NAME)
    frames.set_animation_speed(FX_ANIM_NAME, fps)
    frames.set_animation_loop(FX_ANIM_NAME, loop)

    for idx in range(start_idx, end_idx + 1):
        var frame_path := "%s/%s_%02d.png" % [folder, base, idx]
        if ResourceLoader.exists(frame_path):
            var texture := load(frame_path) as Texture2D
            if texture != null:
                frames.add_frame(FX_ANIM_NAME, texture)

    return frames

func _spawn_fx(parent_node: Node, frames: SpriteFrames, world_pos: Vector2, loop: bool) -> AnimatedSprite2D:
    if parent_node == null or frames == null:
        return null

    var anim := AnimatedSprite2D.new()
    anim.sprite_frames = frames
    anim.animation = FX_ANIM_NAME
    parent_node.add_child(anim)
    anim.global_position = world_pos
    anim.z_index = 120
    if frames.has_animation(FX_ANIM_NAME):
        anim.play(FX_ANIM_NAME)

    if not loop:
        if not anim.animation_finished.is_connected(_on_fx_animation_finished.bind(anim)):
            anim.animation_finished.connect(_on_fx_animation_finished.bind(anim))

    return anim

func _on_fx_animation_finished(sprite: AnimatedSprite2D) -> void:
    if sprite != null and is_instance_valid(sprite):
        sprite.queue_free()

func _get_node2d_from_weakref(value: Variant) -> Node2D:
    if value == null:
        return null
    if not (value is WeakRef):
        return null
    var obj: Object = (value as WeakRef).get_ref()
    if obj == null:
        return null
    return obj if obj is Node2D else null

func _queue_free_node_from_weakref(value: Variant) -> void:
    if value == null:
        return
    if not (value is WeakRef):
        return
    var obj: Object = (value as WeakRef).get_ref()
    if obj == null:
        return
    if obj is Node and is_instance_valid(obj):
        (obj as Node).queue_free()

func _get_autoload(node_name: String) -> Node:
    var tree := get_tree()
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null(node_name)
