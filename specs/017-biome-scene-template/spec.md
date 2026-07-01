# Biome Scene Template (017)
**Feature ID**: 017-biome-scene-template
**Status**: Implemented
**Priority**: Medium
**Estimated Effort**: 2-4 hours

## Clarifications

### Session 2025-11-28
- Q: Extend biome template to include prop library (trees, bushes, portal) → A: Yes, integrated into existing spec as natural extension of biome system

## Overview

Create a reusable biome scene template for battle backgrounds. Each biome is a standalone scene with a fullscreen "ground" texture and a Props node for manual placement of decorations (trees, bushes, rocks, animated sprites, etc.).

**Scope**: Visual only - no gameplay logic, scripts, or signals.

## Requirements

### Engine & Resolution
- **Engine**: Godot 4.3
- **Base Resolution**: 1920×1080 (16:9)
- **Scaling**: Scene must scale correctly with viewport changes (standard Godot stretch settings)

### File Structure
```
biomes/
├── Biome_Base.tscn          # Template scene
├── Biome_Forest.tscn        # Forest biome (copy of template) ✅ Created
├── Biome_Desert.tscn        # Desert biome (copy of template) ✅ Created
├── Biome_Snow.tscn          # Snow biome (copy of template) - TODO
└── props/
    ├── trees/
    │   ├── Tree_01.tscn     # Tree prop variant 1
    │   ├── Tree_02.tscn     # Tree prop variant 2
    │   ├── Tree_03.tscn     # Tree prop variant 3
    │   └── Tree_04.tscn     # Tree prop variant 4
    ├── bushes/
    │   ├── Bush_01.tscn     # Bush prop variant 1
    │   ├── Bush_02.tscn     # Bush prop variant 2
    │   ├── Bush_03.tscn     # Bush prop variant 3
    │   └── Bush_04.tscn     # Bush prop variant 4
    └── portal/
        └── Portal_01.tscn   # Portal prop
```

### Scene Structure
```
Biome_Base (Node2D)
├── Ground (Sprite2D)        # Fullscreen ground texture
├── Props (Node2D)           # Container for decorations
└── BattleAnchor (Node2D)    # Battle center anchor point
```

### Ground Node Details
- **Type**: Sprite2D
- **Properties**:
  - `centered = true`
  - `position = (0, 0)`
- **Texture**: Placeholder 1920×1080 image (solid color or simple pattern)
- **Purpose**: Fullscreen ground covering entire 16:9 visible area

### Props Node Details
- **Type**: Node2D
- **Purpose**: Container for visual decorations
- **Content**: Empty in template, manually populated with:
  - Sprite2D, AnimatedSprite2D, Particles2D, etc.
  - Positioned visually over Ground

### BattleAnchor Node Details
- **Type**: Node2D
- **Purpose**: Reference point for battle system centering
- **Position**: (0, 0) in template, adjusted in biome copies
- **Usage**: GameScene reads `BattleAnchor.global_position` to center battle area

## Constraints

### What NOT to include
- **No Foreground layer**
- **No gameplay logic**: No scripts, signals, mob/hero bindings, timers, UI
- **Only visual elements**: Ground, Props, BattleAnchor

### Scene Autonomy
- Scene must be self-contained visual module
- No external dependencies or references

### Props Scenes Structure

Each prop scene follows this template:

```
PropName_XX (Node2D)
└── Sprite (AnimatedSprite2D)
```

**Requirements for all prop scenes:**
- Root node: Node2D named after the prop (Tree_01, Bush_02, Portal_01)
- `y_sort_enabled = true` for Y-sorting with other ground objects
- Child node: AnimatedSprite2D named "Sprite"
- Empty SpriteFrames resource (animations added manually later)
- Default positions (0, 0)
- Pivot point at bottom-center for correct Y-sorting
- No scripts or signals
- Scenes load without errors in Godot 4.3

**Trees (4 variants):** Tree_01.tscn through Tree_04.tscn in `biomes/props/trees/`
**Bushes (4 variants):** Bush_01.tscn through Bush_04.tscn in `biomes/props/bushes/`
**Portal (1 variant):** Portal_01.tscn in `biomes/props/portal/`

## Integration Notes (For Reference - Not Implemented Here)

### GameScene Integration
- GameScene will have `BiomeLayer: Node2D` node under `WorldYSort: YSort`
- During gameplay: biome instance added as child of BiomeLayer
- GameScene reads `BattleAnchor.global_position` to align battle center
- All ground objects (heroes, mobs, props) use Y-sorting for proper layering

## Success Criteria

1. Template scene loads without errors
2. Scene structure matches specification exactly
3. Ground covers full 1920×1080 area when centered
4. Props node accepts child nodes without issues
5. BattleAnchor position readable via global_position
6. Scene scales properly with viewport changes
7. Template can be duplicated and modified for different biomes
8. All 9 prop scenes (4 trees, 4 bushes, 1 portal) created in correct paths
9. All prop scenes load without errors and have correct structure
10. Prop scenes contain no scripts or signals
11. Y-sorting enabled for all ground objects (heroes, mobs, props)
12. Background elements have proper z_index layering
