# Ten Kings 1:1 Crowd Battle Implementation Plan

**Status:** In Progress  
**Created:** 2026-04-05  
**Goal:** Transform the Ten Kings prototype from single-stack visuals into a centered, real 1:1 on-screen crowd battle where actual unit counts are shown and units run/fight wall-vs-wall.

## Context

Current state:
- Battle uses one `TenKingsBattleActor` per stack with a multiplier label
- Arena layout collapses left when `ArenaPanel` is hidden during battle
- Battle-space coordinates are derived from UI slot rects, coupling battle geometry to UI layout

Target state:
- Each soldier in a stack is a visible entity on screen
- Battle is centered in a dedicated arena space independent of UI layout
- Wall-vs-wall melee clash in center, ranged stay behind and shoot
- Performance optimized enough to handle typical stack sizes (target: 100-300+ soldiers total)

## Constraints

- No `NavigationAgent2D` / avoidance (overlaps acceptable for now)
- Animations from Aseprite spritesheets, not authored in Godot
- `MultiMesh` only as renderer optimization if needed, not as giving up walk/attack animations
- Strict 1:1 first; measure real limits before considering hybrid/cap approaches

## Tasks

### Phase 1: Fix Centered Arena Layout

**Task 1.1: Refactor arena visibility without layout collapse**
- [ ] In `TenKingsPrototype.tscn`, replace ArenaPanel hide/show with opacity or `visible` on children only
- [ ] Or: restructure so ArenaPanel doesn't affect HBoxContainer sizing when "hidden"
- [ ] Verify boards stay in position during battle
- [ ] Test: manual visual check that battle stays centered

**Task 1.2: Create TenKingsArenaGeometryService**
- [ ] Create `scripts/dev/ten_kings/TenKingsArenaGeometryService.gd`
- [ ] Define arena rect independent of UI slots
- [ ] Provide methods: `get_player_spawn_zone() -> Rect2`, `get_enemy_spawn_zone() -> Rect2`, `get_center_line() -> float`
- [ ] Inject into TenKingsBattleManager instead of UI-derived origins

**Task 1.3: Decouple TenKingsBattleManager from UI slot rects**
- [ ] Remove `_get_slot_world_origin()` dependency on `slot_ui.get_global_rect()`
- [ ] Use ArenaGeometryService for spawn positions
- [ ] Update `_setup_actors()` to use arena geometry

### Phase 2: Strict 1:1 Soldier Expansion

**Task 2.1: Create TenKingsCrowdBuilder**
- [ ] Create `scripts/dev/ten_kings/TenKingsCrowdBuilder.gd`
- [ ] Method `expand_stack_to_soldiers(unit: TenKingsUnit, spawn_zone: Rect2) -> Array[Dictionary]`
- [ ] Each dictionary: `{unit_type, position, team, source_slot}`
- [ ] Distribute soldiers in formation within spawn zone (grid or staggered)

**Task 2.2: Create soldier entity data structure**
- [ ] Define soldier struct/dictionary: `{id, unit_type, team, position, velocity, state, target_id, hp, attack_cooldown}`
- [ ] States: `idle`, `walking`, `attacking`, `dying`, `dead`

**Task 2.3: Integrate crowd expansion into battle setup**
- [ ] In TenKingsBattleManager, replace single-actor-per-stack with crowd expansion
- [ ] Call TenKingsCrowdBuilder for each stack
- [ ] Collect all soldiers into flat arrays (player_soldiers, enemy_soldiers)

### Phase 3: Centralized Crowd Simulation

**Task 3.1: Create TenKingsCrowdRuntime**
- [ ] Create `scripts/dev/ten_kings/TenKingsCrowdRuntime.gd`
- [ ] Owns all soldier data arrays
- [ ] `_process(delta)` updates all soldiers each frame
- [ ] Movement: melee walk toward nearest enemy, ranged stay at range
- [ ] Attack: when in range, deal damage to target
- [ ] Death: mark dead, skip in future updates

**Task 3.2: Create TenKingsCrowdSpatialGrid**
- [ ] Create `scripts/dev/ten_kings/TenKingsCrowdSpatialGrid.gd`
- [ ] Simple cell-based spatial hash for fast nearest-enemy lookup
- [ ] Methods: `insert(soldier_id, position)`, `remove(soldier_id)`, `get_nearest_enemy(position, team, max_range) -> soldier_id`
- [ ] Update grid each frame as soldiers move

**Task 3.3: Implement targeting and combat**
- [ ] Melee: walk until within attack_range, then attack
- [ ] Ranged: walk until within shoot_range, stop and shoot
- [ ] Random speed variance (0.9-1.1x base speed) to prevent perfect stacking
- [ ] Attack deals damage, target dies when hp <= 0

**Task 3.4: Detect battle end**
- [ ] Battle ends when all soldiers of one team are dead
- [ ] Emit signal with winner team
- [ ] Connect to existing TenKingsBattleManager flow

### Phase 4: Pooled Soldier Renderer

**Task 4.1: Create TenKingsSoldierVisual scene**
- [ ] Create `scenes/dev/ten_kings/TenKingsSoldierVisual.tscn`
- [ ] Minimal: Node2D with AnimatedSprite2D child
- [ ] Script: `set_unit_type()`, `set_state()`, `set_position()`, `set_team()` (flip for enemy)

**Task 4.2: Create TenKingsCrowdRenderer**
- [ ] Create `scripts/dev/ten_kings/TenKingsCrowdRenderer.gd`
- [ ] Maintain pool of TenKingsSoldierVisual instances
- [ ] Each frame: sync pool to living soldiers
- [ ] Reuse visuals for dead soldiers (return to pool)
- [ ] Cap visuals at configurable max (e.g., 200) if needed

**Task 4.3: Animation state sync**
- [ ] Map soldier state to animation: `idle`->`idle`, `walking`->`walk`, `attacking`->`attack`
- [ ] Update AnimatedSprite2D.animation based on soldier state

### Phase 5: Benchmark and Quality Scaling

**Task 5.1: Create benchmark scene**
- [ ] Create `scenes/dev/ten_kings/TenKingsBattleBenchmark.tscn`
- [ ] Script spawns configurable number of soldiers (50, 100, 200, 300, 500)
- [ ] Displays FPS counter
- [ ] Runs battle simulation to completion
- [ ] Logs results

**Task 5.2: Create TenKingsBattleQualityController**
- [ ] Create `scripts/dev/ten_kings/TenKingsBattleQualityController.gd`
- [ ] Monitor FPS during battle
- [ ] If FPS drops below threshold, reduce visual quality:
  - Reduce animation framerate
  - Increase LOD distance
  - Skip some visual updates
- [ ] Configurable thresholds

**Task 5.3: Measure and document limits**
- [ ] Run benchmarks on target hardware
- [ ] Document observed FPS vs soldier count
- [ ] Set recommended defaults

### Phase 6: (Optional) MultiMesh Renderer Backend

Only if Phase 5 shows strict 1:1 cannot meet performance targets.

**Task 6.1: MultiMesh renderer prototype**
- [ ] Create alternative renderer using MultiMeshInstance2D
- [ ] Batch by unit_type + state
- [ ] Use shader or custom_data for frame selection
- [ ] Preserve walk/attack animations from spritesheets

### Phase 7: Integration and Cleanup

**Task 7.1: Wire new systems into TenKingsPrototype**
- [ ] Replace old actor-based battle with crowd-based battle
- [ ] Ensure turn flow still works (place cards -> battle -> resolve siege)
- [ ] Remove or deprecate old TenKingsBattleActor if no longer used

**Task 7.2: Update tests**
- [ ] Add tests for TenKingsCrowdBuilder
- [ ] Add tests for TenKingsCrowdRuntime
- [ ] Update existing battle flow tests

**Task 7.3: Update documentation**
- [ ] Update `docs/dev/TEN_KINGS_PROTOTYPE.md`
- [ ] Document new architecture

## Verification

After each phase:
1. Run Ten Kings test suite: `godot --headless --script scripts/dev/tests/run_ten_kings_tests.gd`
2. Manual visual test: launch prototype, place cards, start battle, verify centered arena and visible soldiers
3. Check FPS in editor during battle

## Files to Create

- `scripts/dev/ten_kings/TenKingsArenaGeometryService.gd`
- `scripts/dev/ten_kings/TenKingsCrowdBuilder.gd`
- `scripts/dev/ten_kings/TenKingsCrowdRuntime.gd`
- `scripts/dev/ten_kings/TenKingsCrowdSpatialGrid.gd`
- `scripts/dev/ten_kings/TenKingsCrowdRenderer.gd`
- `scripts/dev/ten_kings/TenKingsBattleQualityController.gd`
- `scenes/dev/ten_kings/TenKingsSoldierVisual.tscn`
- `scenes/dev/ten_kings/TenKingsBattleBenchmark.tscn`
- `scripts/dev/ten_kings/TenKingsBattleBenchmark.gd`

## Files to Modify

- `scenes/dev/TenKingsPrototype.tscn` - arena layout fix
- `scripts/dev/ten_kings/TenKingsPrototype.gd` - integrate new systems
- `scripts/dev/ten_kings/TenKingsBattleManager.gd` - decouple from UI, integrate crowd
- `docs/dev/TEN_KINGS_PROTOTYPE.md` - update architecture docs
