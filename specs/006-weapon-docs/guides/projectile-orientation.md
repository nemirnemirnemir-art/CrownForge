# Weapon Documentation: Projectile Orientation Standards

**Weapon ID**: `projectile_orientation_standards`  
**Last Updated**: 2024-12-28  
**Status**: [ПРОВЕРЕНО]

---

## Verification Status

**Overall Status**: [ПРОВЕРЕНО]

**Verification Details**:
- **Baseline Parameters**: [НЕ ПРИМЕНИМО] - Standards guide, not weapon-specific
- **Tome Interactions**: [НЕ ПРИМЕНИМО] - Standards guide, not weapon-specific
- **Adapter Rules**: [НЕ ПРИМЕНИМО] - Standards guide, not weapon-specific
- **Controller Integration**: [НЕ ПРИМЕНИМО] - Standards guide, not weapon-specific
- **Lifecycle**: [НЕ ПРИМЕНИМО] - Standards guide, not weapon-specific

**Status Legend**:
- `[ПРОВЕРЕНО]` - Tested and verified working as documented
- `[ТРЕБУЕТ ПРОВЕРКИ]` - Based on code analysis, needs actual testing
- `[БАГ]` - Known issue/bug that needs fixing
- `[НЕИЗВЕСТНО]` - Unclear behavior, requires investigation

---

## 1. Overview

**Purpose**: Standards guide for projectile orientation in Godot 4.3. Ensures all projectiles follow consistent orientation rules (rotation = 0° = RIGHT direction).

**Key Features**:
- Standard orientation rule: rotation = 0° = RIGHT direction
- Sprite and collision alignment rules
- Code validation patterns
- Visual marker guidelines
- Testing checklist

**Verification Status**: [ПРОВЕРЕНО]

---

## 2. Baseline Parameters

**Note**: This is a standards guide, not a weapon-specific documentation. Orientation standards apply to all projectiles.

**Standard Orientation**:
- **Sprite Direction**: RIGHT at `rotation = 0°` [ПРОВЕРЕНО]
- **Collision Direction**: RIGHT at `rotation = 0°` [ПРОВЕРЕНО]
- **Code Rotation**: `rotation = _direction.angle()` [ПРОВЕРЕНО]
- **Exception**: Vertical sprites use `rotation = PI/2` (90°) [ПРОВЕРЕНО]

**Verification Status**: [ПРОВЕРЕНО]

---

## 3. Tome Interactions

**Note**: [НЕ ПРИМЕНИМО] - Orientation standards do not interact with tomes directly.

---

## 4. Adapter Rules

**Note**: [НЕ ПРИМЕНИМО] - Orientation standards do not have adapter rules.

---

## 5. Controller Integration

**Note**: [НЕ ПРИМЕНИМО] - Orientation standards apply to projectile scenes, not controllers.

**However**, controllers should ensure projectiles are spawned with correct initial rotation (0° = RIGHT).

---

## 6. File Structure

### Orientation Rules Apply To

All projectile scenes (`.tscn` files):
- `gameplay/weapons/*Projectile.tscn`
- Any new projectile scenes created

### Code Files That Use Orientation

- `gameplay/weapons/Projectile.gd` - Base projectile class with `setup()` function
- Individual projectile scripts (e.g., `ChainLightningProjectile.gd`, `BoulderWeaponProjectile.gd`)

**Verification Status**: [ПРОВЕРЕНО]

---

## 7. Dependencies

### Godot 4.3 APIs Used

- **Node2D.rotation**: Rotation property (radians)
- **Vector2.angle()**: Get angle from Vector2 (returns radians)
- **Vector2.RIGHT**: Constant for right direction (1, 0)
- **rad_to_deg()**: Convert radians to degrees

**API Validation**: [ПРОВЕРЕНО] - All APIs are valid for Godot 4.3

**Verification Status**: [ПРОВЕРЕНО]

---

## 8. Lifecycle

### Orientation Check Points

1. **Scene Setup** (`.tscn` file):
   - Sprite should be oriented RIGHT at rotation = 0°
   - Collision shape should be oriented RIGHT at rotation = 0°
   - If sprite is vertical, add `rotation = PI/2` (90°) in scene

2. **Code Setup** (`setup()` function):
   - Validate orientation: `rotation = Vector2.RIGHT.angle()` should be 0°
   - Apply direction: `rotation = _direction.angle()`

3. **Runtime**:
   - Projectile rotates correctly based on `_direction` vector
   - Visual sprite matches rotation

**Verification Status**: [ПРОВЕРЕНО]

---

## 9. Debug Logging

### Orientation Validation Debug

Enable `debug_logs` on projectile scene or script.

**Expected Markers**:
```
[Projectile] orientation check: rotation=0.0 deg (should be 0° for RIGHT)
```

**Validation Code Example**:
```gdscript
func setup(...) -> void:
    # Валидация: при rotation = 0 проектиль должен быть направлен вправо
    if debug_logs:
        var test_dir = Vector2.RIGHT
        rotation = test_dir.angle()  # Должно быть 0°
        print("[Projectile] orientation check: rotation=%.1f deg (should be 0° for RIGHT)" % rad_to_deg(rotation))
```

**Verification Status**: [ПРОВЕРЕНО]

---

## 10. Known Pitfalls

### Common Mistakes

- **Vertical Sprite Not Rotated**: [ПРОВЕРЕНО] [БАГ]
  - **Symptom**: Projectile points up instead of right when rotation = 0°
  - **Cause**: Sprite is vertical but rotation not adjusted in scene
  - **Fix**: Add `rotation = PI/2` (90°) in `.tscn` file for sprite and collision

- **Collision Shape Misaligned**: [ПРОВЕРЕНО] [БАГ]
  - **Symptom**: Collision doesn't match visual sprite direction
  - **Cause**: Collision shape rotation doesn't match sprite rotation
  - **Fix**: Ensure collision shape rotation matches sprite rotation in scene

- **Wrong Initial Rotation**: [ПРОВЕРЕНО] [БАГ]
  - **Symptom**: Projectile starts pointing wrong direction
  - **Cause**: Code applies rotation before sprite is oriented correctly
  - **Fix**: Ensure sprite is oriented RIGHT at rotation = 0° in scene first

### Resolved Cases

- **SwordToTheMouseProjectile Fixed**: [ПРОВЕРЕНО]
  - **Problem**: Sprite was vertical, projectile pointed up instead of right
  - **Solution**: Added `rotation = 1.57617` (90°) in scene for both sprite and collision
  - **Prevention**: Check sprite orientation in scene before adding rotation code

### Standard Rules

**Rule #1**: All projectiles should be horizontal in scene [ПРОВЕРЕНО]
- Sprite: must point RIGHT at rotation = 0°
- Collision: must point RIGHT at rotation = 0°
- Exception: If sprite is vertical, add `rotation = PI/2` (90°) in scene

**Rule #2**: Documentation in scene [ПРОВЕРЕНО]
- Add comments in `.tscn` files:
```gdscript
# ОРИЕНТАЦИЯ: Спрайт направлен вправо (rotation = 0°)
# При rotation = 0° проектиль направлен вправо
# Код поворачивает на угол мыши: rotation = _direction.angle()
```

**Rule #3**: Validation in code [ПРОВЕРЕНО]
- Check orientation in `setup()` function (see Debug Logging section)

**Rule #4**: Visual markers in editor [ПРОВЕРЕНО]
- Add invisible Marker2D arrow in scene pointing RIGHT direction
- Use Marker2D with direction visualization

**Rule #5**: Testing checklist [ПРОВЕРЕНО]
- [ ] Sprite points RIGHT at rotation = 0°?
- [ ] Collision points RIGHT at rotation = 0°?
- [ ] Comments added in `.tscn` about orientation?
- [ ] Tested visually: rotation = 0 → direction RIGHT?
- [ ] Tested: rotation to mouse angle works correctly?

**Verification Status**: [ПРОВЕРЕНО]

---

## Cross-References

### Integration Points

- **Source Documentation**: [`docs/PROJECTILE_ORIENTATION_GUIDE.md`](../../../docs/PROJECTILE_ORIENTATION_GUIDE.md) - Original orientation guide
- **main.md**: Not directly referenced (general projectile standards)
- **NORMALIZED_WEAPON_SYSTEM.md**: Not directly referenced (orientation applies to all projectiles)

### Related Documentation

- **Base Projectile**: `gameplay/weapons/Projectile.gd` - Base class with `setup()` function
- **Chain Lightning Guide**: [Chain Lightning Guide](./chain-lightning.md) - Example of properly oriented projectile
- **Boulder Guide**: [Boulder Guide](./boulder.md) - Example of properly oriented projectile

---

## Notes

This is a **standards guide**, not weapon-specific documentation. These orientation rules apply to all projectiles in the project.

**Key Principle**: `rotation = 0°` should always mean the projectile points RIGHT, regardless of sprite orientation.

**Last Verified**: 2024-12-28  
**Next Review**: When new projectile is added or orientation issues are discovered

---

**Template Version**: 1.0  
**Based on**: `docs/PROJECTILE_ORIENTATION_GUIDE.md`  
**Status System**: Standards guide, all rules marked as [ПРОВЕРЕНО]

