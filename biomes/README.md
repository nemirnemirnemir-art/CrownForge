# Biome Scenes

This directory contains biome background scenes for battle environments.

## Files

- **Biome_Base.tscn**: Template scene for creating new biomes
- **Biome_Forest.tscn**: Forest biome example
- **Biome_Desert.tscn**: Desert biome example

## Props Library

Ready-to-use prop scenes for biome decoration:

### Trees (4 variants)
- `props/trees/Tree_01.tscn`
- `props/trees/Tree_02.tscn`
- `props/trees/Tree_03.tscn`
- `props/trees/Tree_04.tscn`

### Bushes (4 variants)
- `props/bushes/Bush_01.tscn`
- `props/bushes/Bush_02.tscn`
- `props/bushes/Bush_03.tscn`
- `props/bushes/Bush_04.tscn`

### Portal (1 variant)
- `props/portal/Portal_01.tscn`

## Structure

Each biome scene has the following structure:
```
Biome_Base (Node2D)
├── Ground (Sprite2D)        # Fullscreen background texture
├── Props (Node2D)           # Container for decorations
└── BattleAnchor (Node2D)    # Center point for battle positioning
```

Each prop scene has this structure:
```
PropName_XX (Node2D)
└── Sprite (AnimatedSprite2D)  # Empty SpriteFrames, add animations manually
```

## Usage

1. Copy Biome_Base.tscn to create new biome variants
2. Update Ground texture with appropriate background (1920×1080 recommended)
3. Position BattleAnchor to the visual center of the battle area
4. Add decorations by instantiating prop scenes as children of Props node
5. Position props visually over the Ground layer

## Y-Sorting

All biome props use Y-sorting for proper layering:

- Props have `y_sort_enabled = true` on root nodes
- Background has `z_index = -10` to stay behind all objects
- Objects sort automatically by Y-coordinate (higher Y = drawn later)

## Integration

GameScene loads biome scenes under `WorldYSort` container and uses BattleAnchor.global_position to center the battle area.
