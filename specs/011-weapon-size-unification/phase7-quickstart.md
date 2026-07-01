# Phase 7 Quickstart: Weapon Testing Guide

**Date**: 2025-11-22  
**Feature**: Weapon Size Unification - Phase 7 (Testing)  
**Status**: In Progress

## Overview

Phase 7 is the testing phase for weapon size unification. The goal is to verify that all 20 weapons work correctly with the unified size system and document how tome effects (Size, Count, Pierce) work for each weapon.

## Prerequisites

- ✅ Phases 1-6 completed (unified size system implemented)
- ✅ All weapons have `size_level` field in their configs
- ✅ All weapons use metadata-based base value storage
- ✅ Debug logs available for verification

## Testing Workflow

### Step 1: Enable Debug Logs

For each weapon being tested, enable `debug_logs = true` in the weapon config (`.tres` file):

```gdscript
# Example: ArrowNormalized.tres
debug_logs = true
```

### Step 2: Test Base Level (size_level = 0)

1. Launch the game
2. Equip the weapon
3. Fire the weapon
4. Check logs for:
   - `[Projectile] SIZE DEBUG -> Total size: 100.0% (base 100% + 0.0%)`
   - Visual sprite and collision match in-game
   - No accumulation on multiple spawns (fire 10 times, check size doesn't grow)

**Expected Log Output**:
```
[Projectile] SIZE DEBUG -> Total size: 100.0% (base 100% + 0.0%)
[Projectile] SIZE DEBUG -> AnimatedSprite2D: base_scale_x=0.703 final_scale_x=0.703 (+0.0%)
[Projectile] SIZE DEBUG -> CircleShape2D: base_radius=3.0 final_radius=3.0 (+0.0%)
```

### Step 3: Test Size Upgrades

1. Activate Size tome (press 'Z' to activate all tomes, or manually add Size tome)
2. Fire the weapon
3. Check logs for:
   - `scale_factor` increases by +5% per stack
   - Visual and collision scale proportionally
   - No "jumps" in size

**Expected Log Output (20 Size tomes)**:
```
[Projectile] SIZE DEBUG -> Total size: 200.0% (base 100% + 100.0%)
[Projectile] SIZE DEBUG -> AnimatedSprite2D: base_scale_x=0.703 final_scale_x=1.406 (+100.0%)
[Projectile] SIZE DEBUG -> CircleShape2D: base_radius=3.0 final_radius=6.0 (+100.0%)
```

### Step 4: Test Multiple Spawns (No Accumulation)

1. Fire the weapon 10 times in a row
2. Check logs: all spawns should have the same `scale_factor`
3. Visual inspection: size should not grow between spawns

**Expected Behavior**: All 10 spawns have identical size, no accumulation.

### Step 5: Document Tome Effects

For each weapon, document how tomes affect it:

#### Size Tome
- **Standard**: +5% size per stack (applies to visual and collision)
- **Exceptions**: Document if weapon has special behavior

#### Count Tome
- **Standard**: +1 projectile per stack
- **Exceptions**: Document if weapon has special behavior (e.g., AuraWeapon affects `_max_targets_per_tick`)

#### Pierce Tome
- **Standard**: +1 pierce per stack
- **Exceptions**: Document if weapon has special behavior (e.g., AuraWeapon affects `_tick_interval`)

### Step 6: Update Documentation

1. **weapon-test-list.md**: Update status
   - `[yes]` → `[pass]` if test passed
   - `[clarify]` → `[fixed]` if issue was resolved, or `[fail]` if issue remains

2. **phase7-test-results.md**: Add detailed report
   ```markdown
   ## [Weapon Name
   
   ### Test Date: [DATE]
   ### Status: [PASS/FAIL/FIXED]
   
   ### Base Level Test
   - Visual/Collision Match: [YES/NO]
   - No Accumulation: [YES/NO]
   - Logs: [Snippet of relevant logs]
   
   ### Size Upgrade Test
   - Proportional Scaling: [YES/NO]
   - No Jumps: [YES/NO]
   - Logs: [Snippet of relevant logs]
   
   ### Tome Effects
   - **Size Tome**: [Description]
   - **Count Tome**: [Description]
   - **Pierce Tome**: [Description]
   
   ### Bugs Found
   - [List any bugs found]
   
   ### Fixes Applied
   - [List any fixes applied]
   ```

### Step 7: Fix Critical Bugs

If critical bugs are found (accumulation, visual/collision desync):
1. Fix immediately
2. Re-test the weapon
3. Update documentation
4. Document fix in `docs/BUGS_PATTERNS.md` if it's a new pattern

## Testing Checklist per Weapon

- [ ] Base level (size_level = 0) - visual and collision match
- [ ] Base level - no accumulation on 10 spawns
- [ ] Size upgrade (0 → 1 → 2) - proportional scaling
- [ ] Size upgrade - no jumps in size
- [ ] Size tome effect documented
- [ ] Count tome effect documented
- [ ] Pierce tome effect documented
- [ ] Results documented in `weapon-test-list.md`
- [ ] Detailed report in `phase7-test-results.md`
- [ ] Critical bugs fixed (if any)

## Completion

Phase 7 is complete when:
- ✅ All 20 weapons tested
- ✅ All critical bugs fixed
- ✅ `weapon-test-list.md` updated
- ✅ `phase7-test-results.md` contains all reports
- ✅ `20_weapons_ready_to_go.md` created

## Troubleshooting

### Issue: Size keeps growing on respawn
**Solution**: Check if base values are stored using metadata. Look for `has_meta(&"base_scale")` checks in `_store_base_values()`.

### Issue: Visual and collision don't match
**Solution**: Check if both use the same `scale_factor`. Verify `_apply_size_scale()` applies to both visual and collision nodes.

### Issue: Size tome doesn't work
**Solution**: Check if `size_scale` parameter is passed correctly from `NormalizedWeaponController` to `Projectile.setup()`.

### Issue: Logs not appearing
**Solution**: Ensure `debug_logs = true` is set in weapon config (`.tres` file), not just in script.

