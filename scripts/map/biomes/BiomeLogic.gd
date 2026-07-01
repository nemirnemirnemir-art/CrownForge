extends Node2D

## Biome Logic Script
## Handles persistence of environmental state (chopped trees)

func _ready() -> void:
    # Wait for the scene to settle
    await get_tree().process_frame
    _sync_tree_state()

func _sync_tree_state() -> void:
    if not StageCore:
        return
        
    var stage_idx = StageCore.get_current_stage()
    var biome_name = StageCore.get_biome_name(stage_idx)
    var props_node = get_node_or_null("Props")
    
    if not props_node:
        return
        
    var restored_count = 0
    for child in props_node.get_children():
        if not child is Node2D:
            continue
        if not child.name.begins_with("Tree_"):
            continue
            
        var tree_pos = child.global_position
        
        # Check against global registry
        if StageCore.is_tree_chopped(biome_name, tree_pos):
            _apply_chopped_state(child)
            restored_count += 1
            
    if restored_count > 0:
        print("[BiomeLogic] Restored %d chopped trees in %s" % [restored_count, biome_name])

func _apply_chopped_state(tree_node: Node2D) -> void:
    # 1. Mark as chopped
    tree_node.set_meta("is_chopped", true)
    tree_node.add_to_group("chopped_trees")
    
    # 2. Visuals -> Stump
    var sprite: AnimatedSprite2D = null
    for child in tree_node.get_children():
        if child is AnimatedSprite2D:
            sprite = child
            break
            
    if sprite:
        # Randomize stump if not already playing
        if not sprite.animation.begins_with("stump"):
            if randf() < 0.5:
                sprite.play("stump1")
            else:
                sprite.play("stump2")
    
    # 3. Remove collision
    var collision = tree_node.get_node_or_null("TreeCollision")
    if collision:
        collision.queue_free()
