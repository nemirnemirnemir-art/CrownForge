# Biome Scene API Contract

## Overview
This contract defines the interface for biome scenes used as battle backgrounds.

## Scene Structure Contract

### Required Node Structure
Every biome scene MUST have exactly this structure:
```
Biome_Base (Node2D)
├── Ground (Sprite2D)
├── Props (Node2D)
└── BattleAnchor (Node2D)
```

### Node Naming Contract
- Root node: `Biome_Base` (Node2D)
- Ground node: `Ground` (Sprite2D)
- Props node: `Props` (Node2D)
- Anchor node: `BattleAnchor` (Node2D)

## Ground Node Contract

### Properties
- `centered: bool = true`
- `position: Vector2 = (0, 0)`
- `texture: Texture2D` - MUST be set to a 1920×1080 texture

### Behavior
- Sprite MUST cover entire 16:9 visible area when centered
- Texture MUST be designed for 1920×1080 base resolution

## Props Node Contract

### Properties
- Empty in template
- Accepts any visual child nodes: Sprite2D, AnimatedSprite2D, Particles2D, etc.

### Behavior
- Children render over Ground node
- No restrictions on child node types or properties

## BattleAnchor Node Contract

### Properties
- `position: Vector2` - Default (0, 0) in template, adjusted in biome variants

### Behavior
- GameScene MUST be able to read `BattleAnchor.global_position`
- Position defines visual center of battle area

## Scene Contract

### File Location
- Template: `res://biomes/Biome_Base.tscn`
- Variants: `res://biomes/Biome_{Name}.tscn`

### Dependencies
- NO external dependencies allowed
- NO scripts attached to any node
- NO signals connected
- NO references to other scenes or resources

### Scaling
- Scene MUST scale correctly with viewport changes
- Uses standard Godot stretch settings
