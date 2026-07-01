# Quick Start: Weapon Documentation System

**Feature**: 006-weapon-docs  
**Date**: 2024-12-28

## Overview

The Weapon Documentation System provides centralized access to all weapon documentation in the project. It integrates existing documentation files (DefaultWeaponDocumentation.md, BOULDER_WEAPON_GUIDE.md, PROJECTILE_ORIENTATION_GUIDE.md) into a unified structure and provides templates for documenting new weapons.

## Getting Started

### 1. Locate the Documentation

**Main Entry Point**: `specs/006-weapon-docs/`

**Integrated Guides**: `specs/006-weapon-docs/guides/`
- `projectile-orientation.md` - Projectile orientation standards
- `chain-lightning.md` - Chain Lightning weapon (reference implementation)
- `boulder.md` - Boulder weapon (comprehensive guide)

**Template**: `specs/006-weapon-docs/templates/weapon-doc-template.md`

**Source Files** (authoritative references):
- `docs/DefaultWeaponDocumentation.md` - Chain Lightning reference
- `docs/BOULDER_WEAPON_GUIDE.md` - Boulder comprehensive guide
- `docs/PROJECTILE_ORIENTATION_GUIDE.md` - Orientation standards

---

### 2. Find Documentation for a Weapon

**Option A: Browse Integrated Guides**
1. Navigate to `specs/006-weapon-docs/guides/`
2. Look for `[weapon-name].md` file
3. If not found, weapon may be undocumented (status: pending)

**Option B: Check Documentation Index**
1. Check `specs/006-weapon-docs/README.md` (if exists) for complete list
2. Review status indicators (documented/partial/pending)

**Option C: Search Source Files**
1. Check `docs/DefaultWeaponDocumentation.md` for Chain Lightning
2. Check `docs/BOULDER_WEAPON_GUIDE.md` for Boulder
3. For other weapons, check if documentation exists elsewhere

---

### 3. Understand Weapon Documentation Structure

Each weapon documentation follows a standard template:

1. **Overview** - What the weapon does, key features
2. **Baseline Parameters** - Default values (shots, cooldown, damage)
3. **Tome Interactions** - How tomes affect this weapon
4. **Adapter Rules** - Special tome transformations (if any)
5. **Controller Integration** - WeaponController vs NormalizedWeaponController
6. **File Structure** - Required files (scripts, scenes, configs)
7. **Dependencies** - Required nodes/scripts/resources
8. **Lifecycle** - Spawn, update, despawn conditions
9. **Debug Logging** - debug_logs flags and expected markers
10. **Known Pitfalls** - Common mistakes and resolved cases

---

### 4. Create New Weapon Documentation

**Step 1: Use Template**
1. Copy `specs/006-weapon-docs/templates/weapon-doc-template.md`
2. Rename to `[weapon-name].md`
3. Place in `specs/006-weapon-docs/guides/`

**Step 2: Fill Required Sections**
1. Start with Overview and Baseline Parameters
2. Document tome interactions (check existing tomes for patterns)
3. Document adapter rules if weapon has special behavior
4. Document controller integration requirements
5. List file structure and dependencies
6. Document lifecycle and debug markers
7. Add known pitfalls as they're discovered

**Step 3: Validate Against Godot 4.3**
1. Use Context7 to validate all Godot API references
2. Check that methods/node types exist in Godot 4.3
3. Flag any deprecated methods

**Step 4: Cross-Reference Integration**
1. Ensure references to main.md align with actual content
2. Ensure references to NORMALIZED_WEAPON_SYSTEM.md align
3. Check that file paths are correct

---

### 5. Example: Finding Chain Lightning Documentation

**Scenario**: Developer needs to understand how Chain Lightning weapon works with tomes.

**Steps**:
1. Navigate to `specs/006-weapon-docs/guides/chain-lightning.md`
2. Read "Tome Interactions" section:
   - Card of Count: increases shots via controller
   - Card of Size: converted to 5% damage multiplier per stack (no visual scaling)
   - Card of Pierce: converted to bonus chain targets
3. Read "Adapter Rules" section for transformation details
4. Read "Debug Logging" section for expected markers:
   - `[ChainLightning] base_pierce=… chain_bonus=… shots=…`
   - `[ChainRunner] setup … bonus=… total=…`

**Time**: < 30 seconds to find and access documentation

---

### 6. Example: Creating Documentation for New Weapon

**Scenario**: Developer implements new weapon "FireBall" and needs to document it.

**Steps**:
1. Copy template: `specs/006-weapon-docs/templates/weapon-doc-template.md` → `specs/006-weapon-docs/guides/fireball.md`
2. Fill Overview: "FireBall creates explosive projectile that deals AoE damage on impact"
3. Fill Baseline Parameters:
   - shots: 1
   - cooldown: 2.0
   - damage_min: 8, damage_max: 10
   - flight_type: DIRECT
4. Fill Tome Interactions:
   - Size: increases explosion radius (visual scaling)
   - Count: increases shots (default behavior)
   - Pierce: not applicable (explodes on first hit)
5. Fill Adapter Rules: None (uses default tome behavior)
6. Fill Controller Integration: Uses NormalizedWeaponController
7. Fill File Structure: `FireBallProjectile.gd`, `FireBallProjectile.tscn`, `FireBallWeapon.tres`
8. Validate Godot 4.3 APIs (Area2D, CircleShape2D, etc.)
9. Update documentation index/status

**Time**: ~15-30 minutes for complete documentation

---

### 7. Validate Documentation Against Godot 4.3

**Using Context7** (when documentation references Godot APIs):

1. **Identify API References**: Scan documentation for Godot node types, methods, constants
2. **Query Context7**: Use `mcp_context7_get-library-docs` for Godot 4.3
3. **Validate Existence**: Confirm all referenced APIs exist in Godot 4.3
4. **Check Deprecation**: Flag any deprecated methods
5. **Update Documentation**: Fix invalid references or note compatibility issues

**Example Validation**:
- Documentation: "Uses `Area2D` with `CollisionShape2D`"
- Context7 Check: Query Godot 4.3 docs for `Area2D`, `CollisionShape2D`
- Result: ✅ Valid (both exist in Godot 4.3)

---

## Common Tasks

### Find Baseline Parameters for Weapon

1. Open weapon guide: `specs/006-weapon-docs/guides/[weapon-name].md`
2. Read "Baseline Parameters" section
3. If not found, check source files in `docs/`

### Understand Tome Interactions

1. Open weapon guide
2. Read "Tome Interactions" section
3. For special adaptations, read "Adapter Rules" section
4. Compare with base tome behavior (reference `gameplay/tomes/` scripts)

### Debug Weapon Issues

1. Open weapon guide
2. Read "Debug Logging" section for expected markers
3. Enable `debug_logs` on weapon config, projectile scene, and controller
4. Check console for expected markers
5. Compare actual output with documented markers

### Add New Weapon Documentation

1. Use template from `specs/006-weapon-docs/templates/weapon-doc-template.md`
2. Fill all required sections
3. Validate against Godot 4.3 using Context7
4. Add cross-references to main.md and NORMALIZED_WEAPON_SYSTEM.md
5. Update documentation index/status

---

## Integration Points

- **main.md**: References weapon system overview (section 5, 10)
- **NORMALIZED_WEAPON_SYSTEM.md**: References configuration parameters and flight types
- **docs/BUGS_PATTERNS.md**: References known pitfalls and resolved cases
- **MAIN_ORIENTATION_THELASTONE.md**: References project rules and conventions

---

## Notes

- Source files in `docs/` remain authoritative references
- Integrated guides provide unified navigation and format consistency
- Template ensures all new documentation follows standard structure
- Context7 validation ensures technical accuracy for Godot 4.3 APIs

