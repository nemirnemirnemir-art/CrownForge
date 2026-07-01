# Biome Scene Template Quickstart

## Creating a New Biome

1. **Duplicate the template**:
   ```bash
   # In Godot editor
   Right-click Biome_Base.tscn → Duplicate
   Rename to Biome_Forest.tscn
   ```

   **Note**: Biome_Forest.tscn and Biome_Desert.tscn already exist as examples

2. **Set ground texture**:
   - Select Ground node
   - Assign appropriate texture (1920×1080)
   - Example: forest_ground.png, desert_sand.png, etc.

3. **Position BattleAnchor**:
   - Select BattleAnchor node
   - Move to visual center of battle area
   - Usually around (0, 0) to (200, 200) depending on biome

4. **Add decorations to Props**:
   - Right-click Props → Add Child Node
   - Add Sprite2D, AnimatedSprite2D, etc.
   - Position visually over Ground
   - Examples: trees, rocks, bushes, particles

## Adding Props to Biomes

After creating biome variants, manually add props from the library:

1. **Open biome scene** (e.g., Biome_Forest.tscn)
2. **Right-click Props node** → Add Child Node
3. **Choose a prop** from the library:
   - Trees: `res://biomes/props/trees/Tree_01.tscn` to `Tree_04.tscn`
   - Bushes: `res://biomes/props/bushes/Bush_01.tscn` to `Bush_04.tscn`
   - Portal: `res://biomes/props/portal/Portal_01.tscn`
4. **Position visually** over the Ground layer
5. **Repeat** for desired decorations

## Y-Sorting System

The game uses a unified Y-sorting system for all ground objects:

- **WorldYSort** (YSort node) contains all sortable objects
- Objects with `y_sort_enabled = true`: heroes, mobs, trees, bushes, portal
- Objects with low `z_index`: background/ground elements
- Objects are sorted by Y-coordinate automatically

## Using in GameScene

```gdscript
# In GameScene.gd
func load_biome(biome_name: String) -> void:
    var biome_scene = load("res://biomes/Biome_" + biome_name + ".tscn")
    var biome_instance = biome_scene.instantiate()
    $WorldYSort/BiomeLayer.add_child(biome_instance)

    # Center battle area
    var anchor_pos = biome_instance.get_node("BattleAnchor").global_position
    # Use anchor_pos to position heroes/mobs
```

## Template Checklist

- [ ] Root is Node2D named "Biome_Base"
- [ ] Ground is Sprite2D, centered, with 1920×1080 texture
- [ ] Props is empty Node2D
- [ ] BattleAnchor is Node2D at (0, 0)
- [ ] No scripts attached
- [ ] No signals connected
- [ ] Scene loads without errors
