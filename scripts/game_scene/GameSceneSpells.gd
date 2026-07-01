## Spell system module for GameScene - handles targeting and casting

const BLADEFALL_TARGET_WIDTH_PX: float = 50.0
const BLADEFALL_TARGET_HEIGHT_PX: float = 300.0
const FISSURE_TARGET_WIDTH_PX: float = 64.0
const FISSURE_TARGET_HEIGHT_PX: float = 640.0

static func setup_spell_panel(game_scene: GameScene) -> void:
    # Find SpellPanel in UILayer/MainUI
    var main_ui = game_scene.get_node_or_null("UILayer/MainUI")
    if main_ui:
        var spell_panel = main_ui.get_node_or_null("SpellPanel")
        if spell_panel:
            if spell_panel.has_signal("spell_targeting_started"):
                spell_panel.spell_targeting_started.connect(game_scene._on_spell_targeting_started)
            if spell_panel.has_signal("spell_cast_requested"):
                spell_panel.spell_cast_requested.connect(game_scene._on_spell_cast_requested)
            if spell_panel.has_signal("spell_targeting_cancelled"):
                spell_panel.spell_targeting_cancelled.connect(game_scene._on_spell_targeting_cancelled)
            print("[GameScene] SpellPanel connected")
            game_scene._spell_panel = spell_panel
        else:
            push_warning("[GameScene] SpellPanel not found in MainUI")
    else:
        push_warning("[GameScene] MainUI not found in UILayer")

static func start_targeting(game_scene: GameScene, config: SpellConfig) -> void:
    print("[GameSceneSpells] START_TARGETING requested for: ", config.spell_id if config else "null")
    game_scene._active_spell_config = config
    game_scene._spell_targeting_active = true
    var radius := config.target_radius if config else 100.0
    var radius_mult := 1.0
    var tree := Engine.get_main_loop() as SceneTree
    if tree and tree.root:
        var artifact_core := tree.root.get_node_or_null("ArtifactCore")
        if artifact_core != null and artifact_core.has_method("get_spell_radius_multiplier"):
            radius_mult = float(artifact_core.call("get_spell_radius_multiplier"))
            radius *= radius_mult
    
    print("[GameSceneSpells] Creating targeting circle with radius: ", radius)
    create_targeting_circle(game_scene, radius)
    if config != null and game_scene._targeting_circle:
        var rect_base := _get_rect_target_size(String(config.spell_id))
        if rect_base != Vector2.ZERO:
            if "shape_mode" in game_scene._targeting_circle:
                game_scene._targeting_circle.shape_mode = "rect"
            if "rect_size" in game_scene._targeting_circle:
                game_scene._targeting_circle.rect_size = rect_base * radius_mult

const SpellTargetingCircleScene = preload("res://scenes/ui/spells/SpellTargetingCircle.tscn")

static func create_targeting_circle(game_scene: GameScene, radius: float) -> void:
    if game_scene._targeting_circle:
        print("[GameSceneSpells] Freeing existing targeting circle")
        game_scene._targeting_circle.queue_free()
    
    game_scene._targeting_circle = SpellTargetingCircleScene.instantiate()
    if game_scene._targeting_circle.has_method("set_radius"):
        game_scene._targeting_circle.set_radius(radius)
    elif "radius" in game_scene._targeting_circle:
        game_scene._targeting_circle.radius = radius
    game_scene.add_child(game_scene._targeting_circle)
    game_scene._targeting_circle.z_index = 150
    game_scene._targeting_circle.visible = true
    game_scene._targeting_circle.global_position = game_scene.get_global_mouse_position()
    print("[GameSceneSpells] Targeting circle created and added to scene")

static func update_targeting(game_scene: GameScene) -> void:
    if not game_scene._spell_targeting_active:
        return

    if game_scene._targeting_circle == null or not is_instance_valid(game_scene._targeting_circle):
        var recreate_radius := 100.0
        if game_scene._active_spell_config != null:
            recreate_radius = game_scene._active_spell_config.target_radius
            var tree_recreate := Engine.get_main_loop() as SceneTree
            if tree_recreate and tree_recreate.root:
                var artifact_core_recreate := tree_recreate.root.get_node_or_null("ArtifactCore")
                if artifact_core_recreate != null and artifact_core_recreate.has_method("get_spell_radius_multiplier"):
                    recreate_radius *= float(artifact_core_recreate.call("get_spell_radius_multiplier"))
        create_targeting_circle(game_scene, recreate_radius)
        if game_scene._targeting_circle == null:
            return
    
    game_scene._targeting_circle.global_position = game_scene.get_global_mouse_position()
    game_scene._targeting_circle.visible = true

    
    if game_scene._active_spell_config:
        var target_pos := game_scene._targeting_circle.global_position
        var radius := game_scene._active_spell_config.target_radius
        var tree := Engine.get_main_loop() as SceneTree
        if tree and tree.root:
            var artifact_core := tree.root.get_node_or_null("ArtifactCore")
            if artifact_core != null and artifact_core.has_method("get_spell_radius_multiplier"):
                radius *= float(artifact_core.call("get_spell_radius_multiplier"))
        
        var rect_base := _get_rect_target_size(String(game_scene._active_spell_config.spell_id))
        if rect_base != Vector2.ZERO:
            var radius_mult := 1.0
            if game_scene._active_spell_config.target_radius > 0.0:
                radius_mult = radius / float(game_scene._active_spell_config.target_radius)
            highlight_targets_rect(
                game_scene,
                target_pos,
                rect_base * radius_mult
            )
            if game_scene._targeting_circle.has_method("set_rect_size"):
                game_scene._targeting_circle.set_rect_size(rect_base * radius_mult)
        else:
            # Highlight mobs
            highlight_targets(
                game_scene,
                target_pos,
                radius
            )
        
        # Highlight trees for deforestation spell
        if game_scene._active_spell_config.spell_id == "deforestation":
            highlight_trees(game_scene, target_pos, radius)

static func highlight_targets(game_scene: GameScene, center: Vector2, radius: float) -> void:
    var all_mobs = game_scene.get_tree().get_nodes_in_group("enemies")
    all_mobs.append_array(game_scene.get_tree().get_nodes_in_group("mobs"))
    
    for mob in all_mobs:
        if not is_instance_valid(mob):
            continue
        
        if mob.global_position.distance_to(center) <= radius:
            mob.modulate = Color(1.5, 0.8, 0.8)
        else:
            mob.modulate = Color(1, 1, 1)

static func highlight_targets_rect(game_scene: GameScene, center: Vector2, size: Vector2) -> void:
    var all_mobs = game_scene.get_tree().get_nodes_in_group("enemies")
    all_mobs.append_array(game_scene.get_tree().get_nodes_in_group("mobs"))
    var half := size * 0.5
    for mob in all_mobs:
        if not is_instance_valid(mob):
            continue
        var dx: float = float(mob.global_position.x - center.x)
        var dy: float = float(mob.global_position.y - center.y)
        if absf(dx) <= half.x and absf(dy) <= half.y:
            mob.modulate = Color(1.5, 0.8, 0.8)
        else:
            mob.modulate = Color(1, 1, 1)

static func _get_rect_target_size(spell_id: String) -> Vector2:
    if spell_id == "bladefall":
        return Vector2(BLADEFALL_TARGET_WIDTH_PX, BLADEFALL_TARGET_HEIGHT_PX)
    if spell_id == "fissure":
        return Vector2(FISSURE_TARGET_WIDTH_PX, FISSURE_TARGET_HEIGHT_PX)
    return Vector2.ZERO

static func highlight_trees(game_scene: GameScene, center: Vector2, radius: float) -> void:
    # Find all trees in scene
    var all_trees: Array = game_scene.get_tree().get_nodes_in_group("trees")
    if all_trees.is_empty():
        all_trees = _find_all_trees_by_name(game_scene.get_tree().root)
    
    for tree in all_trees:
        if not is_instance_valid(tree) or not tree is Node2D:
            continue
        
        var tree_node := tree as Node2D
        var dist := tree_node.global_position.distance_to(center)
        
        # Selection Outline logic
        var outline = tree_node.get_node_or_null("SelectionOutline")
        
        # Check if chopped (Meta, Group, Missing Collision, or Global Registry)
        var is_chopped = tree_node.has_meta("is_chopped") or \
                         tree_node.is_in_group("chopped_trees") or \
                         not tree_node.has_node("TreeCollision")
        
        # Extra check: Query persistent storage in StageCore
        var stage_core := _get_singleton("StageCore")
        if not is_chopped and stage_core != null and stage_core.has_method("is_tree_chopped"):
            var stage_idx = stage_core.get_current_stage()
            var biome_name = stage_core.get_biome_name(stage_idx)
            if stage_core.is_tree_chopped(biome_name, tree_node.global_position):
                is_chopped = true

        
        if dist <= radius and tree.name.begins_with("Tree_"):
            if is_chopped:
                if outline: outline.visible = false
                tree_node.modulate = Color(0.5, 0.5, 0.5, 0.7) # Very dim for chopped
                continue
                
            # Create outline if not exists
            if not outline:
                var main_sprite: AnimatedSprite2D = null
                for child in tree_node.get_children():
                    if child is AnimatedSprite2D:
                        main_sprite = child
                        break
                
                if main_sprite:
                    outline = Sprite2D.new()
                    outline.name = "SelectionOutline"
                    if main_sprite.sprite_frames:
                        var anim = main_sprite.animation
                        var frame = main_sprite.frame
                        outline.texture = main_sprite.sprite_frames.get_frame_texture(anim, frame)
                    
                    outline.position = main_sprite.position
                    outline.offset = main_sprite.offset
                    outline.centered = main_sprite.centered
                    outline.flip_h = main_sprite.flip_h
                    
                    outline.modulate = Color(0.3, 0.3, 0.3, 1.0) # Dark gray outline
                    outline.scale = Vector2(1.15, 1.15)
                    outline.show_behind_parent = true
                    tree_node.add_child(outline)
            
            if outline:
                outline.visible = true
            tree_node.modulate = Color(1.3, 1.3, 1.3)
        else:
            if outline:
                outline.visible = false
            tree_node.modulate = Color(1, 1, 1) if not is_chopped else Color(0.6, 0.6, 0.6, 0.8)

static func _find_all_trees_by_name(node: Node) -> Array:
    var result: Array = []
    
    if node.name.begins_with("Tree_"):
        result.append(node)
    
    for child in node.get_children():
        result.append_array(_find_all_trees_by_name(child))
    
    return result

static func cast_spell(game_scene: GameScene, config: SpellConfig, target_pos: Vector2) -> bool:
    if not config or not config.effect_scene:
        clear_targeting(game_scene)
        return false

    var damage_mult := 1.0
    var radius_mult := 1.0
    var double_chance := 0.0
    var artifact_core: Node = null
    var tree := Engine.get_main_loop() as SceneTree
    if tree and tree.root:
        artifact_core = tree.root.get_node_or_null("ArtifactCore")
        if artifact_core != null:
            if artifact_core.has_method("get_spell_damage_multiplier"):
                damage_mult = float(artifact_core.call("get_spell_damage_multiplier"))
            if artifact_core.has_method("get_spell_radius_multiplier"):
                radius_mult = float(artifact_core.call("get_spell_radius_multiplier"))
            if artifact_core.has_method("get_spell_double_cast_chance"):
                double_chance = float(artifact_core.call("get_spell_double_cast_chance"))
    
    var effect: SpellEffect = config.effect_scene.instantiate()
    if effect == null:
        clear_targeting(game_scene)
        return false
    if effect != null:
        effect.damage_multiplier = damage_mult
        effect.radius_multiplier = radius_mult
    
    # Spawn in WorldYSort so Area2D can detect trees in BiomeLayer
    var world_ysort = game_scene.get_node_or_null("WorldYSort")
    if world_ysort:
        world_ysort.add_child(effect)
    elif game_scene.map_container:
        game_scene.map_container.add_child(effect)
    else:
        game_scene.add_child(effect)
    
    # Connect damage_dealt signal for floating damage numbers
    if effect.has_signal("damage_dealt"):
        effect.damage_dealt.connect(_on_spell_damage_dealt.bind(game_scene))
    
    effect.initialize(config, target_pos)
    if artifact_core != null and artifact_core.has_method("on_spell_cast"):
        artifact_core.call("on_spell_cast", str(config.spell_id))
    if double_chance > 0.0 and randf() < clamp(double_chance, 0.0, 1.0):
        var effect2: SpellEffect = config.effect_scene.instantiate()
        if effect2 != null:
            effect2.damage_multiplier = damage_mult
            effect2.radius_multiplier = radius_mult
            if world_ysort:
                world_ysort.add_child(effect2)
            elif game_scene.map_container:
                game_scene.map_container.add_child(effect2)
            else:
                game_scene.add_child(effect2)
            # Connect damage signal for double cast too
            if effect2.has_signal("damage_dealt"):
                effect2.damage_dealt.connect(_on_spell_damage_dealt.bind(game_scene))
            effect2.initialize(config, target_pos)
            if artifact_core != null and artifact_core.has_method("on_spell_cast"):
                artifact_core.call("on_spell_cast", str(config.spell_id))
    print("[GameScene] Spell cast: %s at %v" % [config.spell_name, target_pos])
    
    clear_targeting(game_scene)
    return true

static func clear_targeting(game_scene: GameScene) -> void:
    print("[GameSceneSpells] CLEAR_TARGETING called")
    game_scene._spell_targeting_active = false
    game_scene._active_spell_config = null
    
    if game_scene._targeting_circle:
        print("[GameSceneSpells] Freeing targeting circle from clear_targeting")
        game_scene._targeting_circle.queue_free()
        game_scene._targeting_circle = null
    
    # Clear mob highlights
    var all_mobs = game_scene.get_tree().get_nodes_in_group("enemies")
    all_mobs.append_array(game_scene.get_tree().get_nodes_in_group("mobs"))
    all_mobs.append_array(game_scene.get_tree().get_nodes_in_group("enemy"))
    for mob in all_mobs:
        if is_instance_valid(mob):
            mob.modulate = Color(1, 1, 1)
    
    # Clear tree highlights
    var all_trees: Array = game_scene.get_tree().get_nodes_in_group("trees")
    if all_trees.is_empty():
        all_trees = _find_all_trees_by_name(game_scene.get_tree().root)
    for tree in all_trees:
        if is_instance_valid(tree) and tree is Node2D:
            var tree_node := tree as Node2D
            tree_node.modulate = Color(1, 1, 1)

            var outline = tree_node.get_node_or_null("SelectionOutline")
            if outline:
                outline.visible = false

## Spell damage popup handler - shows floating damage numbers when spells deal damage
## Signal signature: damage_dealt(position: Vector2, damage: float)
static func _on_spell_damage_dealt(position: Vector2, damage: float, _game_scene: GameScene) -> void:
    if damage <= 0:
        return
    # Use DamagePopupPool autoload to show floating damage number
    var damage_popup_pool := _get_singleton("DamagePopupPool")
    if damage_popup_pool != null and damage_popup_pool.has_method("show_damage"):
        damage_popup_pool.show_damage(position, int(damage), false)


static func _get_singleton(node_name: String) -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null(node_name)
