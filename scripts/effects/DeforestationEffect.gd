extends SpellEffect

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")

## Deforestation spell effect - chops trees and changes them to stumps
## Trees give +40 wood each, 50% chance to show stump1 or stump2

@onready var effect_area: Area2D = $EffectArea
@onready var effect_shape: CollisionShape2D = $EffectArea/CollisionShape2D

const WOOD_PER_TREE: int = 40

func execute_effect() -> void:
    if not effect_area or not effect_shape:
        push_error("[DeforestationEffect] Missing EffectArea or CollisionShape2D")
        queue_free()
        return
    
    # Set collision area from config
    if config:
        var shape := CircleShape2D.new()
        shape.radius = config.target_radius if config.target_radius > 0 else 100.0
        effect_shape.shape = shape
    
    # Force Area2D to update its transform and collision detection
    effect_area.force_update_transform()
    
    # DEBUG: Check if trees exist in scene at all
    var all_trees: Array = get_tree().get_nodes_in_group("trees")
    if all_trees.is_empty():
        print("[DeforestationEffect] ⚠️ No trees in 'trees' group, searching by name...")
        all_trees = _find_all_trees_by_name(get_tree().root)
    
    print("[DeforestationEffect] DEBUG: Found %d trees in scene total" % all_trees.size())
    for tree in all_trees:
        if tree is Node2D:
            var tree_node := tree as Node2D
            print("  - %s at %v, has TreeCollision: %s" % [
                tree.name,
                tree_node.global_position,
                tree.has_node("TreeCollision")
            ])
    
    # CRITICAL: Wait for physics to process the new collision shape
    await get_tree().physics_frame
    await get_tree().physics_frame
    await get_tree().physics_frame
    
    _chop_trees_in_area()
    
    # Clean up after a short delay
    await get_tree().create_timer(0.5).timeout
    queue_free()

func _chop_trees_in_area() -> void:
    var spell_pos := global_position
    var radius := config.target_radius if config and config.target_radius > 0 else 100.0
    
    print("[DeforestationEffect] Spell position: %s" % spell_pos)
    print("[DeforestationEffect] Effect radius: %.1f" % radius)
    
    # Find all trees manually (Area2D doesn't work with dynamic shapes reliably)
    var all_trees: Array = get_tree().get_nodes_in_group("trees")
    if all_trees.is_empty():
        all_trees = _find_all_trees_by_name(get_tree().root)
    
    var trees_chopped: int = 0
    
    for tree in all_trees:
        if not is_instance_valid(tree) or not tree is Node2D:
            continue
        
        # DEFINITIVE CHECK: Is it a tree or a stump?
        # 1. Check if metadata exists
        if tree.has_meta("is_chopped"):
            continue
        # 2. Check if collision exists (we remove it when chopping)
        if not tree.has_node("TreeCollision"):
            continue
        # 3. Check group
        if tree.is_in_group("chopped_trees"):
            continue
            
        var tree_node := tree as Node2D
        var dist := tree_node.global_position.distance_to(spell_pos)
        
        if dist <= radius and tree.name.begins_with("Tree_"):
            # MARK IMMEDIATELY to prevent double-processing
            tree.set_meta("is_chopped", true)
            tree.add_to_group("chopped_trees")
            
            print("[DeforestationEffect] Chopping '%s' at %v" % [tree.name, tree_node.global_position])
            _chop_tree(tree)
            trees_chopped += 1

    if trees_chopped == 0:
        print("[DeforestationEffect] ❌ No fresh trees found in spell area")
    else:
        print("[DeforestationEffect] ✅ Processed %d tree(s)" % trees_chopped)

func _chop_tree(tree: Node) -> void:
    if not tree is Node2D:
        return
    
    var tree_node := tree as Node2D
    var tree_pos := tree_node.global_position
    var resource_core := _get_autoload("ResourceCore")
    var king_spell_state := _get_autoload("KingSpellState")
    var stage_core := _get_autoload("StageCore")
    
    # Show resource popup - FORCING 40 for stability
    var popup_scene := load("res://scenes/ui/overlays/ResourcePopup.tscn") as PackedScene
    if popup_scene:
        var popup := popup_scene.instantiate()
        var wood_icon := PathRegistryScript.load_resource_icon("wood", {"wood": "wood_1"})
        
        var game_scene = get_tree().current_scene
        if game_scene:
            # Set data before adding to tree
            # Even if WOOD_PER_TREE is weird, we show 40 Wood
            popup.initialize(wood_icon, 40, tree_pos)
            game_scene.add_child(popup)
    
    # Add wood to player resources
    if resource_core != null and resource_core.has_method("add_resource"):
        resource_core.add_resource("wood", 40)
    if king_spell_state != null and king_spell_state.has_method("register_tree_chopped"):
        king_spell_state.register_tree_chopped(1)
    
    # Change visuals to stump
    for child in tree_node.get_children():
        if child is AnimatedSprite2D:
            var tree_sprite := child as AnimatedSprite2D
            if randf() < 0.5:
                tree_sprite.play("stump1")
            else:
                tree_sprite.play("stump2")
            break
    
    # REMOVE COLLISION IMMEDIATELY
    var collision_node := tree_node.get_node_or_null("TreeCollision")
    if collision_node:
        collision_node.free() # Use free() for instant removal from node structure

    # PERSISTENCE: Save to StageCore so it remains chopped after background reload
    if stage_core != null and stage_core.has_method("mark_tree_chopped"):
        var stage_idx: int = int(stage_core.get_current_stage())
        var biome_name: String = str(stage_core.get_biome_name(stage_idx))
        stage_core.mark_tree_chopped(biome_name, tree_pos)


func _find_all_trees_by_name(node: Node) -> Array:
    var result: Array = []
    
    if node.name.begins_with("Tree_"):
        result.append(node)
    
    for child in node.get_children():
        result.append_array(_find_all_trees_by_name(child))
    
    return result

func _get_autoload(node_name: String) -> Node:
    var tree := get_tree()
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null(node_name)
