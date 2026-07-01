# Biome Scene Template Tasks

## Phase 1: Setup & Structure

- [x] Create biomes/ directory
- [x] Create Biome_Base.tscn scene with Node2D root
- [x] Add Ground (Sprite2D) child node
- [x] Add Props (Node2D) child node
- [x] Add BattleAnchor (Node2D) child node

## Phase 2: Ground Node Configuration

- [x] Set Ground.centered = true
- [x] Set Ground.position = (0, 0)
- [x] Create/find placeholder texture (1920x1080)
- [x] Assign texture to Ground node
- [x] Verify Ground covers full screen area

## Phase 3: Props Node Setup

- [x] Verify Props node is empty
- [x] Test adding child nodes (Sprite2D test)
- [x] Verify child nodes render over Ground

## Phase 4: BattleAnchor Node Setup

- [x] Set BattleAnchor.position = (0, 0)
- [x] Test global_position access
- [x] Verify anchor point functionality

## Phase 5: Testing & Validation

- [x] Test scene loading without errors
- [x] Test viewport scaling
- [x] Test scene duplication for biome variants
- [x] Verify no scripts/signals present

## Phase 6: Props Creation

- [x] Create biomes/props/trees/ directory
- [x] Create biomes/props/bushes/ directory
- [x] Create biomes/props/portal/ directory
- [x] Create Tree_01.tscn through Tree_04.tscn
- [x] Create Bush_01.tscn through Bush_04.tscn
- [x] Create Portal_01.tscn
- [x] Verify all prop scenes load without errors
- [x] Ensure correct node structure in all prop scenes

## Phase 7: Y-Sorting Implementation

- [x] Create WorldYSort (YSort) node in GameScene
- [x] Move all ground objects under WorldYSort
- [x] Enable y_sort_enabled for heroes, mobs, and props
- [x] Set proper z_index for background elements
- [x] Update spawn logic to use Y-sorted containers

## Phase 8: Documentation

- [x] Create quickstart guide
- [x] Document biome creation process
- [x] Document props usage
- [x] Update project documentation
