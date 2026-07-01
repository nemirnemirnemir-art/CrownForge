# Weapon Documentation: Boulder

**Weapon ID**: `boulder_weapon`  
**Last Updated**: 2024-12-28  
**Status**: [ТРЕБУЕТ ПРОВЕРКИ]

---

## Verification Status

**Overall Status**: [ТРЕБУЕТ ПРОВЕРКИ]

**Verification Details**:
- **Baseline Parameters**: [ТРЕБУЕТ ПРОВЕРКИ] - Based on code analysis, needs testing
- **Tome Interactions**: [ТРЕБУЕТ ПРОВЕРКИ] - Uses default tome behavior (no adapters), needs verification
- **Adapter Rules**: [НЕ ПРИМЕНИМО] - Boulder does not use special tome adapters
- **Controller Integration**: [ТРЕБУЕТ ПРОВЕРКИ] - Both controllers supported, needs verification
- **Lifecycle**: [ТРЕБУЕТ ПРОВЕРКИ] - IDLE/ROLLING states implemented, needs testing

**Known Issues**: 
- Type inference errors in geometry calculations (fixed in code, but needs verification) [БАГ - РЕШЕНО]

**Testing Notes**: 
- Complex weapon with two-state system (IDLE/ROLLING)
- Geometric center/side hit detection logic needs thorough testing
- Speed profile (acceleration → cruise → deceleration) needs verification
- One boulder per owner constraint needs testing

**Status Legend**:
- `[ПРОВЕРЕНО]` - Tested and verified working as documented
- `[ТРЕБУЕТ ПРОВЕРКИ]` - Based on code analysis, needs actual testing
- `[БАГ]` - Known issue/bug that needs fixing
- `[НЕИЗВЕСТНО]` - Unclear behavior, requires investigation

---

## 1. Overview

**Purpose**: Boulder Weapon creates a rolling boulder that travels across the battlefield, dealing damage to enemies in its path.

**Key Features**:
- Two-state system: IDLE (waiting) and ROLLING (active rolling)
- One boulder per owner (new spawn replaces old)
- Geometric center/side hit detection (center = no knockback, side = knockback)
- Speed profile: acceleration → cruise speed → deceleration
- Fixed size (no runtime scaling)
- Hit cooldown between hits on same target

**States**:
- **IDLE** - Waiting before rolling starts [ТРЕБУЕТ ПРОВЕРКИ]
- **ROLLING** - Active rolling with damage [ТРЕБУЕТ ПРОВЕРКИ]

**Verification Status**: [ТРЕБУЕТ ПРОВЕРКИ]

---

## 2. Baseline Parameters

**Default Configuration**:
- **Shots**: `1` (always one boulder, regardless of Count tome) [ТРЕБУЕТ ПРОВЕРКИ]
- **Cooldown**: `1.0` seconds (from BoulderWeapon.tres) [ТРЕБУЕТ ПРОВЕРКИ]
- **Damage Range**: `8-10` (from BoulderWeapon.tres) [ТРЕБУЕТ ПРОВЕРКИ]
- **Flight Type**: `N/A` (uses custom BoulderWeaponProjectile, not standard flight types) [ТРЕБУЕТ ПРОВЕРКИ]
- **Pierce Count**: `6` (not used directly, hit cooldown controls frequency) [ТРЕБУЕТ ПРОВЕРКИ]
- **Speed**: `320.0` pixels per second (not used directly, speed profile used instead) [ТРЕБУЕТ ПРОВЕРКИ]
- **Lifetime**: `9999.0` seconds (lives until removed by logic, not time) [ТРЕБУЕТ ПРОВЕРКИ]
- **Knockback**: `360.0` (base knockback for side hits) [ТРЕБУЕТ ПРОВЕРКИ]

**BoulderWeaponConfig Parameters**:
- **Idle Duration**: `4.0` seconds (wait time before rolling) [ПРОВЕРЕНО]
- **Travel Distance**: `720.0` pixels (distance per roll) [ТРЕБУЕТ ПРОВЕРКИ]
- **Min Speed**: `80.0` px/sec (minimum speed) [ТРЕБУЕТ ПРОВЕРКИ]
- **Max Speed**: `520.0` px/sec (maximum cruise speed) [ТРЕБУЕТ ПРОВЕРКИ]
- **Acceleration Time**: `1.5` seconds (time to reach max speed) [ТРЕБУЕТ ПРОВЕРКИ]
- **Deceleration Time**: `1.1` seconds (time to slow down at end) [ТРЕБУЕТ ПРОВЕРКИ]
- **Hit Cooldown**: `0.25` seconds (cooldown between hits on same target) [ТРЕБУЕТ ПРОВЕРКИ]
- **Side Knockback Multiplier**: `1.0` (multiplier for side hit knockback) [ТРЕБУЕТ ПРОВЕРКИ]
- **Center Band Ratio**: `0.33` (width of center band as fraction of radius) [ТРЕБУЕТ ПРОВЕРКИ]
- **Require Owner Bias**: `true` (prefer direction toward owner) [ТРЕБУЕТ ПРОВЕРКИ]
- **Bias Distance**: `900.0` pixels (distance threshold for owner bias) [ТРЕБУЕТ ПРОВЕРКИ]
- **Min Direction Dot**: `0.0` (minimum dot product for direction selection) [ТРЕБУЕТ ПРОВЕРКИ]

**Configuration Resources**: 
- **Weapon Config**: `gameplay/weapons/BoulderWeapon.tres` (WeaponConfig)
- **Behavior Config**: `gameplay/weapons/BoulderWeaponBehavior.tres` (BoulderWeaponConfig)

**Verification Status**: [ТРЕБУЕТ ПРОВЕРКИ]

**Notes**: 
- Boulder uses custom BoulderWeaponProjectile instead of standard Projectile.gd
- Speed is controlled by speed profile, not simple constant speed
- One boulder per owner (new spawn replaces old)

---

## 3. Tome Interactions

**Verification Status**: [ТРЕБУЕТ ПРОВЕРКИ]

**Note**: Boulder uses **default tome behavior** (no special adapters).

### Baseline Tome Effects

- **Damage**: [ТРЕБУЕТ ПРОВЕРКИ] - Standard damage multiplier applies (`damage_mult`, `damage_add`)
- **Crit Chance**: [ТРЕБУЕТ ПРОВЕРКИ] - Standard crit chance applies (`crit_chance_add`, base 5%)
- **Crit Damage**: [ТРЕБУЕТ ПРОВЕРКИ] - Standard crit damage applies (`crit_damage_mult`, base 1.5x)
- **Size**: [ТРЕБУЕТ ПРОВЕРКИ] - **Default behavior** - Visual scaling (if implemented, not used by Boulder)
- **Pierce**: [ТРЕБУЕТ ПРОВЕРКИ] - **Default behavior** - Not used by Boulder (hit cooldown controls frequency)
- **Count**: [ТРЕБУЕТ ПРОВЕРКИ] - **Not applicable** - Boulder always spawns one instance (Count tome ignored)
- **Duration**: [ТРЕБУЕТ ПРОВЕРКИ] - **Not applicable** - Boulder lifetime not time-based
- **Knockback**: [ТРЕБУЕТ ПРОВЕРКИ] - Standard knockback applies (`knockback_mult`, `knockback_add`) for side hits only
- **Lifesteal**: [ТРЕБУЕТ ПРОВЕРКИ] - Standard lifesteal applies (`lifesteal_chance`)

### Special Cases

**Count Tome**: Ignored - Boulder always spawns one instance regardless of Count tome stacks [ТРЕБУЕТ ПРОВЕРКИ]

**Size Tome**: Not applicable - Boulder has fixed size, visual scaling not used [ТРЕБУЕТ ПРОВЕРКИ]

**Pierce Tome**: Not applicable - Hit cooldown controls frequency, not pierce count [ТРЕБУЕТ ПРОВЕРКИ]

**Duration Tome**: Not applicable - Boulder lifetime not time-based [ТРЕБУЕТ ПРОВЕРКИ]

---

## 4. Adapter Rules

**Verification Status**: [НЕ ПРИМЕНИМО]

**Note**: Boulder does **not** use special tome adapters. It uses default tome behavior.

**Tome Behavior**: `WeaponConfig.TomeBehavior.DEFAULT` (or unspecified)

**Code Reference**: `gameplay/weapons/tomes/TomeAdapters.gd` - Boulder not listed in adapter rules

---

## 5. Controller Integration

**Verification Status**: [ТРЕБУЕТ ПРОВЕРКИ]

### Supported Controllers

- **WeaponController**: ✅ **Yes** - Supported [ТРЕБУЕТ ПРОВЕРКИ]
  - Calls `BoulderWeaponProjectile.setup()` with `WeaponConfig`, `dir`, `from`, `tome_mods`
  - Always spawns one boulder (ignores Count tome)
  
- **NormalizedWeaponController**: ✅ **Yes** - Supported [ТРЕБУЕТ ПРОВЕРКИ]
  - Calls `BoulderWeaponProjectile.setup()` with config, direction, owner, tome_mods
  - Always spawns one boulder (ignores Count tome)

### Tome Behavior Flag

**Tome Behavior**: `WeaponConfig.TomeBehavior.DEFAULT` (or unspecified) [ТРЕБУЕТ ПРОВЕРКИ]

**Configuration**: No special `tome_behavior` flag needed for Boulder

### Integration Requirements

- **Pre-setup Processing**: [ТРЕБУЕТ ПРОВЕРКИ]
  - Controllers pass `TomeMods` directly to `setup()` (no adapter processing)
  - Standard tome modifiers applied in `_initialize_stats()`
  
- **Metadata Keys**: [НЕ ПРИМЕНИМО] - Boulder does not use metadata keys
  
- **One Boulder Per Owner**: [ТРЕБУЕТ ПРОВЕРКИ]
  - Boulder uses static `_active_by_owner` dictionary
  - New spawn replaces old boulder for same owner
  - Implemented in `setup()` method

**Code References**:
- `gameplay/player/WeaponController.gd` - Legacy controller
- `gameplay/player/NormalizedWeaponController.gd` - Normalized controller
- `gameplay/weapons/BoulderWeaponProjectile.gd` - Boulder projectile script

**Known Issues**: None currently known

---

## 6. File Structure

**Verification Status**: [ТРЕБУЕТ ПРОВЕРКИ]

### Required Files

```
gameplay/weapons/
├── BoulderWeapon.tres                  # Weapon config (WeaponConfig)
├── BoulderWeaponBehavior.tres          # Behavior config (BoulderWeaponConfig)
├── BoulderWeaponProjectile.gd          # Boulder projectile script
└── BoulderWeaponProjectile.tscn        # Boulder projectile scene

gameplay/player/
└── PlayerShadow.gd                      # Shadow script (used by Boulder)
```

### File Descriptions

- **`BoulderWeapon.tres`**: Weapon configuration (WeaponConfig) [ТРЕБУЕТ ПРОВЕРКИ]
  - Damage: 8-10
  - Cooldown: 1.0s
  - Uses `BoulderWeaponBehavior.tres` as behavior
  
- **`BoulderWeaponBehavior.tres`**: Boulder-specific behavior configuration (BoulderWeaponConfig) [ТРЕБУЕТ ПРОВЕРКИ]
  - Idle duration, travel distance, speed profile, hit cooldown, geometry settings
  
- **`BoulderWeaponProjectile.tscn`**: Boulder projectile scene [ТРЕБУЕТ ПРОВЕРКИ]
  - Root: Area2D
  - Visual: AnimatedSprite2D (24-frame rolling animation)
  - Collider: StaticBody2D with CircleShape2D (radius ≈ 62.5)
  - DamageArea: Area2D with CircleShape2D (radius ≈ 62.5)
  - Shadow: Node2D with PlayerShadow.gd
  
- **`BoulderWeaponProjectile.gd`**: Boulder projectile script [ТРЕБУЕТ ПРОВЕРКИ]
  - Implements IDLE/ROLLING state machine
  - Handles speed profile (acceleration → cruise → deceleration)
  - Geometric center/side hit detection
  - One boulder per owner constraint

**Known Issues**: None currently known

---

## 7. Dependencies

**Verification Status**: [ТРЕБУЕТ ПРОВЕРКИ]

### Required Nodes/Scripts

- **Projectile Base**: `gameplay/weapons/BoulderWeaponProjectile.gd` - Custom projectile script (not Projectile.gd) [ТРЕБУЕТ ПРОВЕРКИ]
- **Controller**: `gameplay/player/WeaponController.gd` or `NormalizedWeaponController.gd` - Weapon firing logic [ТРЕБУЕТ ПРОВЕРКИ]
- **Tome System**: `gameplay/tomes/TomeController.gd` - Tome management [ТРЕБУЕТ ПРОВЕРКИ]
- **Tome Mods**: `gameplay/tomes/TomeMods.gd` - Modifier container [ТРЕБУЕТ ПРОВЕРКИ]
- **Shadow**: `gameplay/player/PlayerShadow.gd` - Shadow visualization [ТРЕБУЕТ ПРОВЕРКИ]

### Required Resources

- **Weapon Config**: `gameplay/weapons/BoulderWeapon.tres` - WeaponConfig resource [ТРЕБУЕТ ПРОВЕРКИ]
- **Behavior Config**: `gameplay/weapons/BoulderWeaponBehavior.tres` - BoulderWeaponConfig resource [ТРЕБУЕТ ПРОВЕРКИ]
- **Config Class**: `gameplay/weapons/BoulderWeaponConfig.gd` - BoulderWeaponConfig class definition [ТРЕБУЕТ ПРОВЕРКИ]

### External Dependencies

- **Godot 4.3 Nodes**: Area2D, AnimatedSprite2D, StaticBody2D, CollisionShape2D, CircleShape2D [ТРЕБУЕТ ПРОВЕРКИ]
- **Godot 4.3 APIs**: Vector2 math (dot, normalized, distance), physics_process, global_position [ТРЕБУЕТ ПРОВЕРКИ]

**API Validation**: [ТРЕБУЕТ ПРОВЕРКИ] - All APIs should be valid for Godot 4.3, needs verification

**Known Issues**: 
- Type inference errors in geometry calculations (fixed in code) [БАГ - РЕШЕНО]

---

## 8. Lifecycle

**Verification Status**: [ТРЕБУЕТ ПРОВЕРКИ]

### Spawn Conditions

- **When**: Controller fires weapon (cooldown expired) [ТРЕБУЕТ ПРОВЕРКИ]
- **Where**: At owner position [ТРЕБУЕТ ПРОВЕРКИ]
- **Frequency**: Every `cooldown` seconds (default 1.0s) [ТРЕБУЕТ ПРОВЕРКИ]
- **One Per Owner**: New spawn replaces old boulder for same owner [ТРЕБУЕТ ПРОВЕРКИ]

### State Machine

**State 1: IDLE** [ПРОВЕРЕНО]
- **Duration**: `idle_duration_sec` (default 4.0s)
- **Behavior**: Waits before rolling starts
- **Visual**: Animation stopped
- **Transition**: IDLE → ROLLING when timer expires

**State 2: ROLLING** [ТРЕБУЕТ ПРОВЕРКИ]
- **Duration**: Until travel distance reached
- **Behavior**: Rolls in selected direction, deals damage to enemies
- **Visual**: Animation playing (24-frame rolling animation)
- **Speed Profile**: 
  - Acceleration phase (0 → max speed over `acceleration_time_sec`)
  - Cruise phase (constant max speed)
  - Deceleration phase (max speed → min speed over `deceleration_time_sec`)
- **Transition**: ROLLING → IDLE when travel distance reached

### Update Loop

**Per-frame Processing** (`_physics_process`) [ТРЕБУЕТ ПРОВЕРКИ]:
- Updates state timer
- Cleans up hit timestamps (removes old entries)
- Processes current state (IDLE or ROLLING)
- Checks for owner validity (despawns if owner invalid)

**Direction Selection** (`_choose_direction`) [ПРОВЕРЕНО]:
- Uses 8 discrete directions (RIGHT, RIGHT_UP, UP, LEFT_UP, LEFT, LEFT_DOWN, DOWN, RIGHT_DOWN)
- If `require_owner_bias = true`: 
  - Calculates vector to owner (`to_hero = hero_pos - boulder_pos`)
  - Filters directions where `dot >= min_direction_dot` (toward owner, positive dot)
  - Selects random direction from filtered set (or all directions if filter empty)
- **Important**: Logic selects directions **toward** hero (positive dot), not away from hero
- Calculates travel distance (toward owner if far, or fixed distance if close)

**Speed Calculation** (`_compute_speed`) [ТРЕБУЕТ ПРОВЕРКИ]:
- Acceleration: `lerp(min_speed, max_speed, accel_t)` where `accel_t = roll_time / acceleration_time`
- Deceleration: If `distance_remaining < decel_distance`, `lerp(min_speed, current_speed, decel_t)`
- Minimum speed: Never below `min_speed * 0.2`

**Hit Detection** (`_handle_hit`) [ТРЕБУЕТ ПРОВЕРКИ]:
- Checks hit cooldown (same target can't be hit more than once per `hit_cooldown_sec`)
- Calculates geometric center/side detection:
  - `delta = receiver_pos - boulder_pos` (vector from boulder to target)
  - `forward = direction` (boulder movement direction)
  - `right = Vector2(forward.y, -forward.x)` (perpendicular to movement)
  - `lateral = delta.dot(right)` (lateral offset from movement axis)
  - `center_band_half_width = radius * center_band_ratio` (half-width of center band)
  - `is_central_hit = abs(lateral) <= center_band_half_width`
- Applies damage (with crit calculation)
- Applies knockback only for side hits (not center hits)

### Despawn Conditions

- **Travel Distance Reached**: [ТРЕБУЕТ ПРОВЕРКИ] - Boulder completes roll, returns to IDLE state
- **Owner Invalid**: [ТРЕБУЕТ ПРОВЕРКИ] - Owner node invalid or freed, boulder despawns
- **Replaced by New Boulder**: [ТРЕБУЕТ ПРОВЕРКИ] - New spawn for same owner replaces old boulder
- **Custom Logic**: [ТРЕБУЕТ ПРОВЕРКИ] - Boulder manages own lifecycle (not time-based)

**Known Issues**: None currently known

---

## 9. Debug Logging

**Verification Status**: [ТРЕБУЕТ ПРОВЕРКИ]

### Debug Flags

Enable `debug_logs` on:
- **Weapon Config**: `gameplay/weapons/BoulderWeapon.tres` → `debug_logs = true`
- **Behavior Config**: `gameplay/weapons/BoulderWeaponBehavior.tres` → `debug_logs = true`
- **Projectile Scene**: `gameplay/weapons/BoulderWeaponProjectile.tscn` → `debug_logs = true`
- **Projectile Script**: `gameplay/weapons/BoulderWeaponProjectile.gd` - Check for `debug_logs` flag

### Expected Markers

**Spawn/Setup Markers**: [ТРЕБУЕТ ПРОВЕРКИ]
```
[BoulderWeaponProjectile] setup -> owner=... pos=(...) ...
[BoulderWeaponProjectile] replace existing instance for owner 12345
```

**State Transition Markers**: [ТРЕБУЕТ ПРОВЕРКИ]
```
[BoulderWeaponProjectile] start roll dir=(...) distance=... target=(...)
[BoulderWeaponProjectile] finish roll
```

**Hit Markers**: [ТРЕБУЕТ ПРОВЕРКИ]
```
[BoulderWeaponProjectile] hit central damage=... lateral=... band=...
[BoulderWeaponProjectile] hit side damage=... lateral=... band=... kb=...
```

**Error Markers**: [ТРЕБУЕТ ПРОВЕРКИ]
```
[BoulderWeaponProjectile] missing BoulderWeaponConfig
```

### Example Output

```
[BoulderWeaponProjectile] setup -> owner=Player pos=(100, 200) ...
[BoulderWeaponProjectile] start roll dir=(1, 0) distance=720.0 target=(820, 200)
[BoulderWeaponProjectile] hit central damage=12 lateral=3.5 band=20.0
[BoulderWeaponProjectile] hit side damage=12 lateral=42.0 band=20.0 kb=360.0
[BoulderWeaponProjectile] finish roll
```

**Verification Status**: [ТРЕБУЕТ ПРОВЕРКИ] - Debug markers exist in code, but need verification

---

## 10. Known Pitfalls

**Verification Status**: [ТРЕБУЕТ ПРОВЕРКИ]

### Common Mistakes

- **Type inference errors in geometry calculations**: [ПРОВЕРЕНО] [БАГ - РЕШЕНО]
  - **Symptom**: Godot 4.3 compiler warnings: "Cannot infer the type of 'delta' variable"
  - **Cause**: Variables declared with `:=` operator, operands from nodes with ambiguous types
  - **Fix**: Added explicit type annotations (`var delta: Vector2 = ...`, `var lateral: float = ...`, `var is_central_hit: bool = ...`)
  - **Prevention**: Always use explicit types when working with `global_position` or vector math
  - **Code Reference**: `gameplay/weapons/BoulderWeaponProjectile.gd` (lines 754-756)

- **Missing BoulderWeaponConfig**: [ТРЕБУЕТ ПРОВЕРКИ] [БАГ]
  - **Symptom**: Boulder fails to initialize or behaves incorrectly
  - **Cause**: `behavior` resource not set or wrong type
  - **Fix**: Ensure `BoulderWeapon.tres` has `behavior = BoulderWeaponBehavior.tres` set
  - **Prevention**: Validate behavior resource type in `setup()`

- **Center band ratio too large/small**: [ТРЕБУЕТ ПРОВЕРКИ] [БАГ]
  - **Symptom**: All hits treated as center (no knockback) or all hits treated as side (always knockback)
  - **Cause**: `center_band_ratio` set incorrectly (should be ~0.33 for balanced behavior)
  - **Fix**: Adjust `center_band_ratio` in BoulderWeaponBehavior.tres
  - **Prevention**: Test with various enemy sizes and positions

- **One boulder per owner not working / Teleportation bug**: [ПРОВЕРЕНО] [БАГ - РЕШЕНО]
  - **Symptom**: Boulder "teleports" behind hero every cooldown cycle, multiple boulders spawn simultaneously
  - **Cause**: `NormalizedWeaponController` spawned new boulder every cooldown without checking for active boulder. Each spawn called `setup()` which set `global_position = _owner.global_position`, creating teleportation effect
  - **Fix**: Added check in `NormalizedWeaponController._fire_weapon()` to skip spawn if active boulder exists in parent node
  - **Prevention**: Always check for active instances before spawning weapons with "one per owner" constraint
  - **Code Reference**: `gameplay/player/NormalizedWeaponController.gd` (lines 378-390)
  
- **Direction selection bug (away from hero instead of toward)**: [ПРОВЕРЕНО] [БАГ - РЕШЕНО]
  - **Symptom**: Boulder chooses direction away from hero instead of toward hero
  - **Cause**: Inverted logic in `_choose_direction()` used `-dot` instead of `dot >= min_direction_dot`
  - **Fix**: Changed logic to filter directions with `dot >= min_direction_dot` (toward hero) and select random from filtered
  - **Prevention**: Always verify direction selection logic matches documentation (positive dot = toward target)
  - **Code Reference**: `gameplay/weapons/BoulderWeaponProjectile.gd` (lines 363-417)

### Resolved Cases

- **Type inference errors**: [ПРОВЕРЕНО] [БАГ - РЕШЕНО]
  - **Problem**: Geometry calculations used `:=` inference, causing compiler warnings
  - **Solution**: Added explicit type annotations (`Vector2`, `float`, `bool`)
  - **Prevention**: Always use explicit types for vector/math operations

- **Teleportation bug**: [ПРОВЕРЕНО] [БАГ - РЕШЕНО]
  - **Problem**: Boulder spawned every cooldown cycle, teleporting to hero position each time
  - **Solution**: Added check in `NormalizedWeaponController._fire_weapon()` to skip spawn if active boulder exists
  - **Prevention**: Always check for active instances before spawning "one per owner" weapons

- **Direction selection bug**: [ПРОВЕРЕНО] [БАГ - РЕШЕНО]
  - **Problem**: Boulder chose direction away from hero instead of toward hero
  - **Solution**: Fixed `_choose_direction()` to filter directions with `dot >= min_direction_dot` (toward hero)
  - **Prevention**: Verify direction selection logic matches documentation (positive dot = toward target)

### Important Notes

1. **One boulder per owner**: New spawn always kills old boulder. Controller checks for active boulder before spawning new one to prevent teleportation bug [ПРОВЕРЕНО]
2. **Fixed size**: Boulder size is constant, geometry logic depends on fixed radius [ТРЕБУЕТ ПРОВЕРКИ]
3. **Geometric center/side detection**: Based on lateral offset from movement axis, not separate Area2D zones [ТРЕБУЕТ ПРОВЕРКИ]
4. **Large enemies**: Even if collision overlaps center band, if enemy center is outside center band, hit is treated as side [ТРЕБУЕТ ПРОВЕРКИ]
5. **Hit cooldown**: Same target can't be hit more than once per `hit_cooldown_sec` [ТРЕБУЕТ ПРОВЕРКИ]
6. **Animation**: Only plays during ROLLING state [ТРЕБУЕТ ПРОВЕРКИ]
7. **Shadow**: Uses PlayerShadow.gd for visual shadow [ТРЕБУЕТ ПРОВЕРКИ]

---

## Cross-References

### Integration Points

- **Source Documentation**: [`docs/BOULDER_WEAPON_GUIDE.md`](../../../docs/BOULDER_WEAPON_GUIDE.md) - Original Boulder documentation (comprehensive guide)
- **main.md**: [Section 10 - Weapon System](../../../main.md#10-ключевые-игровые-системы-сводка) - Weapon system overview
  - Boulder mentioned as special weapon with custom behavior
- **NORMALIZED_WEAPON_SYSTEM.md**: [`data/config/NORMALIZED_WEAPON_SYSTEM.md`](../../../data/config/NORMALIZED_WEAPON_SYSTEM.md) - Normalized weapon configuration system
  - Boulder does not use NormalizedProjectileConfig (uses custom BoulderWeaponConfig)

### Related Weapons

- **Drone**: [DOCUMENTED] - Also uses custom projectile script, but supports normalized config
- **Aura**: [DOCUMENTED] - Also uses custom behavior, but simpler state machine

---

## Notes

Boulder is a **complex weapon** with a custom state machine and geometric hit detection. It does not use the standard Projectile.gd base class or NormalizedProjectileConfig.

**Key Principle**: Center/side hit detection is geometric (based on lateral offset from movement axis), not collision-based (separate Area2D zones).

**Last Verified**: 2024-12-28  
**Recent Fixes**:
- Fixed teleportation bug (controller now checks for active boulder before spawn)
- Fixed direction selection (now selects toward hero, not away)
- Updated idle duration to 4.0 seconds (was 6.0)

**Next Review**: When state machine changes or geometric hit detection logic is modified

---

**Template Version**: 1.0  
**Based on**: `docs/BOULDER_WEAPON_GUIDE.md` (comprehensive guide)  
**Status System**: Complex weapon, most sections marked as [ТРЕБУЕТ ПРОВЕРКИ] until tested

