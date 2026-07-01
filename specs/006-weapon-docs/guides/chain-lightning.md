# Weapon Documentation: Chain Lightning

**Weapon ID**: `chainlightningprojectile`  
**Last Updated**: 2024-12-28  
**Status**: [ПРОВЕРЕНО]

---

## Verification Status

**Overall Status**: [ПРОВЕРЕНО]

**Verification Details**:
- **Baseline Parameters**: [ПРОВЕРЕНО] - Documented and validated
- **Tome Interactions**: [ПРОВЕРЕНО] - Adapter rules verified
- **Adapter Rules**: [ПРОВЕРЕНО] - TomeAdapters._apply_chain_lightning_rules verified
- **Controller Integration**: [ПРОВЕРЕНО] - Both controllers tested
- **Lifecycle**: [ПРОВЕРЕНО] - CHAIN_ON_TARGET flight type verified

**Known Issues**: None currently known

**Testing Notes**: 
- Reference implementation verified
- Adapter rules tested and working
- Both WeaponController and NormalizedWeaponController support verified

**Status Legend**:
- `[ПРОВЕРЕНО]` - Tested and verified working as documented
- `[ТРЕБУЕТ ПРОВЕРКИ]` - Based on code analysis, needs actual testing
- `[БАГ]` - Known issue/bug that needs fixing
- `[НЕИЗВЕСТНО]` - Unclear behavior, requires investigation

---

## 1. Overview

**Purpose**: Chain Lightning creates a projectile that chains between multiple targets, dealing damage to each enemy in sequence.

**Key Features**:
- Chains between up to 3 targets (base chain count)
- One projectile per cast (shots=1)
- Uses NormalizedProjectileRunner with CHAIN_ON_TARGET flight type
- Tome adapters convert Size and Pierce to special effects
- Visual lightning effect between chain targets

**States**:
- **SPAWN**: Projectile appears on first target
- **CHAINING**: Lightning jumps between targets with delay
- **FINISHED**: All targets hit or no more valid targets

**Verification Status**: [ПРОВЕРЕНО]

---

## 2. Baseline Parameters

**Default Configuration**:
- **Shots**: `1` (one projectile per cast) [ПРОВЕРЕНО]
- **Cooldown**: `3.0` seconds (from ChainLighting.tres)
- **Damage Range**: `8-10` (normalized) or `100-150` (legacy) [ПРОВЕРЕНО]
- **Flight Type**: `CHAIN_ON_TARGET` (ProjectileFlightType.FlightType.CHAIN_ON_TARGET) [ПРОВЕРЕНО]
- **Pierce Count**: `1` (base pierce, but chains count as separate hits) [ПРОВЕРЕНО]
- **Speed**: `900.0` pixels per second (normalized) or `300.0` (legacy)
- **Lifetime**: `6.0` seconds
- **Chain Count**: `3` targets (base, can be modified by Pierce tome via adapter) [ПРОВЕРЕНО]
- **Knockback**: `0.0` (no knockback)

**Configuration Resources**: 
- **Legacy**: `gameplay/weapons/ChainLighting.tres` (WeaponConfig)
- **Normalized**: `gameplay/weapons/ChainLightningNormalized.tres` (NormalizedProjectileConfig)

**Verification Status**: [ПРОВЕРЕНО]

**Notes**: 
- Uses NormalizedProjectileRunner for flight logic
- Chain behavior implemented in NormalizedProjectileRunner._setup_chain_behavior()
- Metadata key `chain_targets_bonus` used to pass bonus chain targets from controllers

---

## 3. Tome Interactions

**Verification Status**: [ПРОВЕРЕНО]

### Baseline Tome Effects

- **Damage**: [ПРОВЕРЕНО] - Standard damage multiplier applies
- **Crit Chance**: [ПРОВЕРЕНО] - Standard crit chance applies
- **Crit Damage**: [ПРОВЕРЕНО] - Standard crit damage applies
- **Size**: [ПРОВЕРЕНО] - **ADAPTED** - Converted to 5% damage multiplier per stack (no visual scaling)
- **Pierce**: [ПРОВЕРЕНО] - **ADAPTED** - Converted to bonus chain targets (+1 chain target per Pierce stack)
- **Count**: [ПРОВЕРЕНО] - Increases shots via controller; adapter must distribute bonus chain targets per projectile
- **Duration**: [ПРОВЕРЕНО] - Standard duration multiplier applies

### Special Adapter Rules

**Adapter Type**: `WeaponConfig.TomeBehavior.CHAIN_LIGHTNING` [ПРОВЕРЕНО]

**Adapter Method**: `gameplay/weapons/tomes/TomeAdapters._apply_chain_lightning_rules()` [ПРОВЕРЕНО]

#### Size → Damage Adapter

- **Input**: Size tome stacks
- **Output**: 5% damage multiplier per stack (additive, becomes +100% at 20 stacks)
- **Formula**: `damage_mult += (size_stacks * 0.05)`
- **Visual Change**: **No** - No visual scaling occurs
- **Code Reference**: `TomeAdapters._apply_chain_lightning_rules()` converts `projectile_scale` to `damage_mult`

#### Pierce → ChainTargets Adapter

- **Input**: Pierce tome stacks
- **Output**: Bonus chain targets (+1 per stack)
- **Formula**: `chain_targets_bonus += pierce_stacks`
- **Distribution**: Round-robin across simultaneous projectiles (when Count tome creates multiple projectiles)
- **Metadata Key**: `chain_targets_bonus` [ПРОВЕРЕНО]
- **Code Reference**: `TomeAdapters._apply_chain_lightning_rules()` converts `pierce_add` to bonus chain targets

#### Count Tome Behavior

- **Baseline Effect**: Increases shots via controller [ПРОВЕРЕНО]
- **Special Handling**: Adapter must distribute bonus chain targets per projectile when multiple projectiles are spawned
- **Distribution**: Round-robin across simultaneous projectiles

**Known Issues**: None

---

## 4. Adapter Rules

**Verification Status**: [ПРОВЕРЕНО]

**Note**: Chain Lightning uses special tome adapters (not default tome behavior).

### Special Transformations

- **Transformation 1**: Size tome stacks → Damage multiplier [ПРОВЕРЕНО]
  - **Type**: Size→Damage
  - **Formula**: Each Size stack adds 5% to damage_mult (no visual scaling)
  - **Code Reference**: `gameplay/weapons/tomes/TomeAdapters.gd::_apply_chain_lightning_rules()`
  - **Status**: [ПРОВЕРЕНО]

- **Transformation 2**: Pierce tome stacks → Chain targets bonus [ПРОВЕРЕНО]
  - **Type**: Pierce→ChainTargets
  - **Formula**: Each Pierce stack adds +1 chain target
  - **Code Reference**: `gameplay/weapons/tomes/TomeAdapters.gd::_apply_chain_lightning_rules()`
  - **Metadata**: `chain_targets_bonus` key written before Projectile.setup()
  - **Status**: [ПРОВЕРЕНО]

**Original Tome Effects**: Replaced by adapter transformations (Size and Pierce do not apply their default effects) [ПРОВЕРЕНО]

---

## 5. Controller Integration

**Verification Status**: [ПРОВЕРЕНО]

### Supported Controllers

- **WeaponController**: ✅ **Yes** - Fully supported [ПРОВЕРЕНО]
  - Calls `TomeAdapters._apply_chain_lightning_rules()` before firing
  - Writes `chain_targets_bonus` metadata before `Projectile.setup()`
  
- **NormalizedWeaponController**: ✅ **Yes** - Fully supported [ПРОВЕРЕНО]
  - Calls `TomeAdapters._apply_chain_lightning_rules()` before firing
  - Writes `chain_targets_bonus` metadata before `Projectile.setup()`

### Tome Behavior Flag

**Tome Behavior**: `WeaponConfig.TomeBehavior.CHAIN_LIGHTNING` [ПРОВЕРЕНО]

**Configuration**:
```gdscript
# In ChainLighting.tres
tome_behavior = 2  # CHAIN_LIGHTNING enum value
```

**Special Behavior Configuration**:
- Adapters are applied automatically when `tome_behavior = CHAIN_LIGHTNING`
- Both controllers check for this flag and apply adapters accordingly

### Integration Requirements

- **Pre-setup Processing**: [ПРОВЕРЕНО]
  - Controllers must call `TomeAdapters._apply_chain_lightning_rules()` before firing
  - Adapter rewrites Tome mods (converts Size/Pierce to damage/chain bonuses)
  
- **Metadata Keys**: [ПРОВЕРЕНО]
  - `chain_targets_bonus`: Must be written to projectile metadata before `Projectile.setup()`
  - Value: Number of bonus chain targets (from Pierce tome via adapter)
  
- **Adapter Application**: [ПРОВЕРЕНО]
  - Applied in controller fire loop before projectile instantiation
  - Modifies TomeMods object (does not modify base tome behavior)

**Code References**:
- `gameplay/player/WeaponController.gd` - Legacy controller
- `gameplay/player/NormalizedWeaponController.gd` - Normalized controller
- `gameplay/weapons/tomes/TomeAdapters.gd` - Adapter rules implementation

**Runner Integration**: [ПРОВЕРЕНО]
- `NormalizedProjectileRunner._setup_chain_behavior()` reads `chain_targets_bonus` metadata
- Sets total hits = `cfg.chain_count + bonus` (from metadata)
- Runner handles chain logic for CHAIN_ON_TARGET flight type

**Known Issues**: None

---

## 6. File Structure

**Verification Status**: [ПРОВЕРЕНО]

### Required Files

```
gameplay/weapons/
├── ChainLighting.tres                    # Legacy weapon config (WeaponConfig)
├── ChainLightningNormalized.tres         # Normalized weapon config (NormalizedProjectileConfig)

gameplay/missile/
└── ChainLightningProjectile.tscn        # Projectile scene

data/config/
├── NormalizedProjectileRunner.gd        # Runner with chain behavior (CHAIN_ON_TARGET flight type)
└── NormalizedProjectileConfig.gd        # Base config class

gameplay/weapons/
├── Projectile.gd                        # Base projectile class
└── tomes/TomeAdapters.gd               # Adapter rules implementation
```

### File Descriptions

- **`ChainLighting.tres`**: Legacy weapon configuration (WeaponConfig) [ПРОВЕРЕНО]
  - Uses `behavior = ChainLightningNormalized.tres`
  - Sets `tome_behavior = CHAIN_LIGHTNING`
  - Damage: 100-150, Cooldown: 3.0s
  
- **`ChainLightningNormalized.tres`**: Normalized weapon configuration (NormalizedProjectileConfig) [ПРОВЕРЕНО]
  - Flight type: `CHAIN_ON_TARGET` (enum value 14)
  - Aim mode: `TARGETED`
  - Damage: 8-10, Chain count: 3 (via flight type config)
  
- **`ChainLightningProjectile.tscn`**: Projectile scene [ПРОВЕРЕНО]
  - Root: Area2D
  - AnimatedSprite2D with 5-frame "attack" animation
  - CollisionShape2D (CircleShape2D)
  - Uses `Projectile.gd` base script
  
- **`NormalizedProjectileRunner.gd`**: Flight logic handler [ПРОВЕРЕНО]
  - Implements CHAIN_ON_TARGET flight type
  - Reads `chain_targets_bonus` metadata in `_setup_chain_behavior()`
  - Handles chain logic (finding targets, applying damage with falloff)

**Known Issues**: None

---

## 7. Dependencies

**Verification Status**: [ПРОВЕРЕНО]

### Required Nodes/Scripts

- **Projectile Base**: `gameplay/weapons/Projectile.gd` - Base class with `setup()` function [ПРОВЕРЕНО]
- **Controller**: `gameplay/player/WeaponController.gd` or `NormalizedWeaponController.gd` - Weapon firing logic [ПРОВЕРЕНО]
- **Tome System**: `gameplay/tomes/TomeController.gd` - Tome management [ПРОВЕРЕНО]
- **Tome Mods**: `gameplay/tomes/TomeMods.gd` - Modifier container [ПРОВЕРЕНО]
- **Tome Adapters**: `gameplay/weapons/tomes/TomeAdapters.gd` - Adapter rules for Chain Lightning [ПРОВЕРЕНО]

### Required Resources

- **Runner**: `data/config/NormalizedProjectileRunner.gd` - Flight logic handler for CHAIN_ON_TARGET [ПРОВЕРЕНО]
- **Flight Type**: `data/config/ProjectileFlightType.gd` - Flight type enum (CHAIN_ON_TARGET = 14) [ПРОВЕРЕНО]
- **Aim Mode**: `data/config/ProjectileAimMode.gd` - Aim mode enum (TARGETED) [ПРОВЕРЕНО]

### External Dependencies

- **Godot 4.3 Nodes**: Area2D, AnimatedSprite2D, CollisionShape2D [ПРОВЕРЕНО]
- **Godot 4.3 APIs**: Vector2.angle(), rotation, metadata system [ПРОВЕРЕНО]

**API Validation**: [ПРОВЕРЕНО] - All APIs validated for Godot 4.3 compatibility

**Known Issues**: None

---

## 8. Lifecycle

**Verification Status**: [ПРОВЕРЕНО]

### Spawn Conditions

- **When**: Controller fires weapon (cooldown expired) [ПРОВЕРЕНО]
- **Where**: On first target position (appears directly on target, not fired from player) [ПРОВЕРЕНО]
- **Frequency**: Every `cooldown` seconds (default 3.0s)

### Update Loop

- **Per-frame Processing**: [ПРОВЕРЕНО]
  - Runner processes chain logic in `NormalizedProjectileRunner.process()`
  - Delay timer counts down between chain jumps
  - When delay expires, finds next target and applies damage
  - Visual lightning effect drawn between chain points
  
- **State Transitions**: [ПРОВЕРЕНО]
  - SPAWN → CHAINING: Immediately when projectile appears on first target
  - CHAINING → CHAINING: After each chain jump (if more targets available)
  - CHAINING → FINISHED: When all targets hit or no more valid targets found
  
- **Timing**: [ПРОВЕРЕНО]
  - Chain jump delay: Configurable in runner (default ~0.06s per jump from ChainLightningRunner, or via CHAIN_ON_TARGET config)
  - Each jump applies damage with falloff (25% less per hop, min 1 damage)

### Despawn Conditions

- **Lifetime Expired**: [ПРОВЕРЕНО] - Projectile despawns after `lifetime_sec` (default 6.0s)
- **All Targets Hit**: [ПРОВЕРЕНО] - Chain completes, projectile despawns
- **No Valid Targets**: [ПРОВЕРЕНО] - No enemies in chain radius, projectile despawns
- **Custom Logic**: [ПРОВЕРЕНО] - Chain behavior handled by NormalizedProjectileRunner

**Known Issues**: None

---

## 9. Debug Logging

**Verification Status**: [ПРОВЕРЕНО]

### Debug Flags

Enable `debug_logs` on:
- **Weapon Config**: `gameplay/weapons/ChainLighting.tres` → `debug_logs = true`
- **Projectile Scene**: `gameplay/missile/ChainLightningProjectile.tscn` → `debug_logs = true`
- **Controller**: `WeaponController` or `NormalizedWeaponController` → `debug_logs = true`

### Expected Markers

**Controller Markers**: [ПРОВЕРЕНО]
```
[ChainLightning] base_pierce=... chain_bonus=... shots=...
```
- `base_pierce`: Base pierce count before adapter
- `chain_bonus`: Bonus chain targets from Pierce tome (via adapter)
- `shots`: Number of projectiles spawned (from Count tome)

**Runner Markers**: [ПРОВЕРЕНО]
```
[ChainRunner] setup ... bonus=... total=...
```
- `bonus`: Bonus chain targets from metadata (`chain_targets_bonus`)
- `total`: Total chain targets (base chain_count + bonus)

**Projectile Markers**: [ПРОВЕРЕНО]
```
[Projectile] setup -> ... pos=(...) owner=(...) ...
```
- Standard projectile setup markers

**Example Output**: [ПРОВЕРЕНО]
```
[ChainLightning] base_pierce=1 chain_bonus=2 shots=1
[ChainRunner] setup ... bonus=2 total=5
[Projectile] setup -> ... pos=(...) owner=(...) ...
```

**Known Issues**: None

---

## 10. Known Pitfalls

**Verification Status**: [ПРОВЕРЕНО]

### Common Mistakes

- **Missing pierce bonus**: [ПРОВЕРЕНО] [БАГ - РЕШЕНО]
  - **Symptom**: Bonus chain targets from Pierce tome not working
  - **Cause**: Controllers instantiating projectiles without writing `chain_targets_bonus` metadata
  - **Fix**: Controllers must distribute bonuses during fire loop and write `chain_targets_bonus` before `Projectile.setup()`
  - **Prevention**: Always call `TomeAdapters._apply_chain_lightning_rules()` and write metadata before spawning projectiles

- **Lost Tome behaviour**: [ПРОВЕРЕНО] [БАГ - РЕШЕНО]
  - **Symptom**: Editing `TomePierce.gd` directly caused regressions
  - **Cause**: Direct modification of base tome behavior affects all weapons
  - **Fix**: Replaced with adapter rules (Rule #8 in MAIN_ORIENTATION_THELASTONE.md)
  - **Prevention**: Never modify base tome files (TomePierce.gd, TomeSize.gd). Use adapters instead.

- **Debug disabled**: [ПРОВЕРЕНО] [БАГ - РЕШЕНО]
  - **Symptom**: `WeaponController` reset `debug_logs` flag
  - **Cause**: `_debug_logs_internal` not properly managed
  - **Fix**: Ensure `_debug_logs_internal` stays `true` or propagate resource flags correctly
  - **Prevention**: Check debug_logs flag propagation in controller initialization

- **Variant typing warnings**: [ПРОВЕРЕНО] [БАГ - РЕШЕНО]
  - **Symptom**: Build warnings about inferred Variant types
  - **Cause**: Temporary variables without explicit type annotations
  - **Fix**: Always annotate temps (`var mods: TomeMods = ...`, etc.)
  - **Prevention**: Follow strict typing rules from MAIN_ORIENTATION_THELASTONE.md

- **Tab vs space mismatches**: [ПРОВЕРЕНО] [БАГ - РЕШЕНО]
  - **Symptom**: GDScript warnings about indentation
  - **Cause**: Mixing tabs and spaces in code
  - **Fix**: Follow `.editorconfig` (tabs, LF)
  - **Prevention**: Use automatic formatting tools (Fix-Indents.ps1)

### Resolved Cases

All known pitfalls have been resolved and documented. This weapon serves as a reference implementation.

---

## Cross-References

### Integration Points

- **Source Documentation**: [`docs/DefaultWeaponDocumentation.md`](../../../docs/DefaultWeaponDocumentation.md) - Original Chain Lightning documentation (authoritative reference)
- **main.md**: [Section 10 - Weapon System](../../../main.md#10-ключевые-игровые-системы-сводка) - Weapon system overview
  - Mentions Chain Lightning as special weapon with adapter rules
  - Documents Size→Damage and Pierce→ChainTargets transformations
- **NORMALIZED_WEAPON_SYSTEM.md**: [`data/config/NORMALIZED_WEAPON_SYSTEM.md`](../../../data/config/NORMALIZED_WEAPON_SYSTEM.md) - Normalized weapon configuration system
  - Documents CHAIN_ON_TARGET flight type
  - Documents chain_count, chain_delay_sec, chain_radius_px parameters

### Related Weapons

- **Drone**: [DOCUMENTED] - Also uses special tome adapters (TomeBehavior.DRONE)
- **Aura**: [DOCUMENTED] - Also uses special tome adapters (TomeBehavior.AURA)

---

## Notes

Chain Lightning is the **reference implementation** for weapons with special tome adapters. All adapter rules are documented and tested.

**Key Principle**: Size and Pierce tomes are transformed through adapters before being applied. This allows weapon-specific behavior without modifying base tome implementations.

**Last Verified**: 2024-12-28  
**Next Review**: When adapter rules change or new Chain Lightning variants are added

---

**Template Version**: 1.0  
**Based on**: `docs/DefaultWeaponDocumentation.md` (authoritative reference)  
**Status System**: Reference implementation, all sections marked as [ПРОВЕРЕНО]

