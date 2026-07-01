# Weapon Documentation: [Weapon Name]

**Weapon ID**: `[weapon_id]` (e.g., `chain_lightning`, `boulder`)  
**Last Updated**: [DATE]  
**Status**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]

---

## Verification Status

**Overall Status**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]

**Verification Details**:
- **Baseline Parameters**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]
- **Tome Interactions**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]
- **Adapter Rules**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО] / [НЕ ПРИМЕНИМО]
- **Controller Integration**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]
- **Lifecycle**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]

**Known Issues**:
- [List any known bugs or unclear behaviors here, marked with [БАГ] or [НЕИЗВЕСТНО]]

**Testing Notes**:
- [Notes about how this weapon was tested, what was verified, what needs testing]

**Status Legend**:
- `[ПРОВЕРЕНО]` - Tested and verified working as documented
- `[ТРЕБУЕТ ПРОВЕРКИ]` - Based on code analysis, needs actual testing
- `[БАГ]` - Known issue/bug that needs fixing
- `[НЕИЗВЕСТНО]` - Unclear behavior, requires investigation

---

## 1. Overview

**Purpose**: [Brief description of what this weapon does]

**Key Features**:
- [Feature 1]
- [Feature 2]
- [Feature 3]

**States** (if applicable):
- **State 1**: [Description]
- **State 2**: [Description]

**Verification Status**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]

---

## 2. Baseline Parameters

**Default Configuration**:
- **Shots**: `[number]` (projectiles per cast)
- **Cooldown**: `[seconds]` seconds
- **Damage Range**: `[min]` - `[max]` (base damage)
- **Flight Type**: `[DIRECT/BOOMERANG/ORBIT/CHAIN/etc.]`
- **Pierce Count**: `[number]` (base pierce)
- **Speed**: `[px/sec]` pixels per second
- **Lifetime**: `[seconds]` seconds
- **Knockback**: `[power]` (base knockback power)

**Configuration Resource**: `[path/to/WeaponConfig.tres]`

**Verification Status**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]

**Notes**: [Any special notes about baseline parameters]

---

## 3. Tome Interactions

**Verification Status**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]

### Baseline Tome Effects

List how each tome affects this weapon with baseline behavior:

- **Damage**: [How Damage tome affects this weapon] [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ]
- **Crit Chance**: [How Crit Chance tome affects this weapon] [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ]
- **Crit Damage**: [How Crit Damage tome affects this weapon] [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ]
- **Size**: [How Size tome affects this weapon] [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ]
- **Pierce**: [How Pierce tome affects this weapon] [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ]
- **Count**: [How Count tome affects this weapon] [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ]
- **Duration**: [How Duration tome affects this weapon] [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ]
- **Movement Speed**: [How Movement Speed tome affects this weapon] [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ]

### Special Adapter Rules

**[ТРЕБУЕТ ПРОВЕРКИ]**: Does this weapon use special tome adapters?

- **Tome Name** → **Adapted Effect**: [Description] [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ]
  - **Input**: [What tome/modifier is used]
  - **Output**: [How it's transformed]
  - **Formula**: [Mathematical formula if applicable]
  - **Visual Change**: [Yes/No - does visual scaling occur?]
  - **Adapter Method**: `[path/to/TomeAdapters.gd]::[method_name]`

**Known Issues**: [Any bugs or unclear tome interactions marked with [БАГ] or [НЕИЗВЕСТНО]]

---

## 4. Adapter Rules

**Verification Status**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО] / [НЕ ПРИМЕНИМО]

**Note**: [If this weapon has no special adapter rules, explicitly state: "This weapon uses default tome behavior. No special adapters."]

### Special Transformations

- **Transformation 1**: [Input tomes] → [Output modification]
  - **Type**: [Size→Damage, Pierce→ChainTargets, etc.]
  - **Formula**: [Mathematical formula]
  - **Code Reference**: `[path/to/TomeAdapters.gd]::[method_name]`
  - **Status**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]

**Known Issues**: [Any bugs or issues with adapter rules]

---

## 5. Controller Integration

**Verification Status**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]

### Supported Controllers

- **WeaponController**: [Yes/No/Partial] - [Description] [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ]
- **NormalizedWeaponController**: [Yes/No/Partial] - [Description] [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ]

### Tome Behavior Flag

**Tome Behavior**: `WeaponConfig.TomeBehavior.[DEFAULT/AURA/CHAIN_LIGHTNING/DRONE]`

[If applicable] **Special Behavior Configuration**:
```gdscript
# Example configuration
weapon_config.tome_behavior = WeaponConfig.TomeBehavior.CHAIN_LIGHTNING
```

### Integration Requirements

- **Pre-setup Processing**: [Any processing needed before Projectile.setup()]
- **Metadata Keys**: [Any metadata keys that must be set (e.g., `chain_targets_bonus`)]
- **Adapter Application**: [When/how TomeAdapters are applied]

**Code References**:
- `[path/to/WeaponController.gd]`
- `[path/to/NormalizedWeaponController.gd]`
- `[path/to/TomeAdapters.gd]`

**Known Issues**: [Any bugs or issues with controller integration]

---

## 6. File Structure

**Verification Status**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]

### Required Files

```
gameplay/weapons/
├── [WeaponName]Projectile.gd          # Main projectile script
├── [WeaponName]Projectile.tscn        # Projectile scene
├── [WeaponName]Config.gd              # Behavior config class (if applicable)
├── [WeaponName]Behavior.tres          # Behavior config resource (if applicable)
└── [WeaponName]Weapon.tres            # Weapon config resource (WeaponConfig or NormalizedProjectileConfig)
```

### File Descriptions

- **`[WeaponName]Projectile.gd`**: [Description of script responsibilities]
- **`[WeaponName]Projectile.tscn`**: [Description of scene structure]
- **`[WeaponName]Config.gd`**: [Description if custom config class exists]
- **`[WeaponName]Behavior.tres`**: [Description if behavior config exists]
- **`[WeaponName]Weapon.tres`**: [Description of weapon config resource]

**Known Issues**: [Any missing files or structural problems]

---

## 7. Dependencies

**Verification Status**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]

### Required Nodes/Scripts

- **Projectile Base**: `gameplay/weapons/Projectile.gd` - [Description]
- **Controller**: `gameplay/player/WeaponController.gd` or `NormalizedWeaponController.gd` - [Description]
- **Tome System**: `gameplay/tomes/TomeController.gd` - [Description]
- **Tome Mods**: `gameplay/tomes/TomeMods.gd` - [Description]
- **Tome Adapters**: `gameplay/weapons/tomes/TomeAdapters.gd` - [If applicable]

### Required Resources

- **Runner** (if normalized): `data/config/NormalizedProjectileRunner.gd` - [If applicable]
- **Flight Type**: `data/config/ProjectileFlightType.gd` - [If applicable]
- **Aim Mode**: `data/config/ProjectileAimMode.gd` - [If applicable]

### External Dependencies

- **Godot 4.3 Nodes**: [List of Godot node types used, e.g., Area2D, CharacterBody2D, AnimatedSprite2D]
- **Godot 4.3 APIs**: [List of Godot APIs/methods used, e.g., Vector2.angle(), rotation, get_tree().create_timer()]

**API Validation**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] - [Notes about Godot 4.3 API validation]

**Known Issues**: [Any dependency problems or missing requirements]

---

## 8. Lifecycle

**Verification Status**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]

### Spawn Conditions

- **When**: [When this weapon spawns projectiles]
- **Where**: [Position/spawn location]
- **Frequency**: [Cooldown/delay between spawns]

### Update Loop

- **Per-frame Processing**: [What happens each frame]
- **State Transitions**: [State machine transitions if applicable]
- **Timing**: [Any time-based behaviors]

### Despawn Conditions

- **Lifetime Expired**: [When lifetime runs out]
- **Hit Target**: [When it hits a target] [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ]
- **Out of Bounds**: [When it goes off-screen]
- **Custom Logic**: [Any custom despawn conditions]

**Known Issues**: [Any lifecycle bugs or unclear behaviors]

---

## 9. Debug Logging

**Verification Status**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]

### Debug Flags

Enable `debug_logs` on:
- **Weapon Config**: `[WeaponName]Weapon.tres` → `debug_logs = true`
- **Projectile Scene**: `[WeaponName]Projectile.tscn` → `debug_logs = true`
- **Controller**: `WeaponController` or `NormalizedWeaponController` → `debug_logs = true`

### Expected Markers

**Controller Markers**:
```
[WeaponName] base_pierce=... shots=... chain_bonus=... (if applicable)
```

**Projectile Markers**:
```
[Projectile] setup -> ... pos=(...) owner=(...) ...
```

**Runner Markers** (if normalized):
```
[WeaponName]Runner setup ... bonus=... total=...
```

**Custom Markers**: [Any weapon-specific debug markers]

**Example Output**: [Sample of what debug logs should look like]

**Known Issues**: [Any debug logging problems, missing markers, or unclear output]

---

## 10. Known Pitfalls

**Verification Status**: [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]

### Common Mistakes

- **[Issue Name]**: [Description] [ПРОВЕРЕНО] / [ТРЕБУЕТ ПРОВЕРКИ] / [БАГ] / [НЕИЗВЕСТНО]
  - **Symptom**: [What goes wrong]
  - **Cause**: [Why it happens]
  - **Fix**: [How to fix it]

### Resolved Cases

- **[Case Name]**: [Description] [ПРОВЕРЕНО]
  - **Problem**: [What the problem was]
  - **Solution**: [How it was fixed]
  - **Prevention**: [How to avoid it]

### Open Issues

- **[Issue Name]**: [Description] [БАГ] / [НЕИЗВЕСТНО]
  - **Status**: [Current status]
  - **Impact**: [How it affects gameplay]
  - **Workaround**: [Any temporary fixes]

---

## Cross-References

### Integration Points

- **main.md**: [Link to weapon system overview section] - [Description]
- **NORMALIZED_WEAPON_SYSTEM.md**: [Link to configuration details] - [Description]
- **Source Documentation**: `docs/DefaultWeaponDocumentation.md` or `docs/BOULDER_WEAPON_GUIDE.md` - [If applicable]

### Related Weapons

- **[Related Weapon Name]**: [Link] - [Why it's related]

---

## Notes

[Additional notes, context, or special considerations]

**Last Verified**: [DATE] by [PERSON/AUTO]  
**Next Review**: [DATE or "When weapon is updated"]

---

**Template Version**: 1.0  
**Based on**: Chain Lightning and Boulder documentation patterns  
**Status System**: Integrated verification markers for untested weapons

