# Validation API Contract: Weapon Documentation System

**Feature**: 006-weapon-docs  
**Date**: 2024-12-28  
**Type**: Documentation Validation API

## Overview

This contract defines the validation methods and APIs used by the weapon documentation system to ensure accuracy, completeness, and consistency. Validation is performed manually during documentation updates using Context7 (for Godot 4.3 API validation) and manual review (for project standards).

## Godot 4.3 API Validation

### Context7 Godot API Query

**Purpose**: Validate that all Godot API references in weapon documentation are compatible with Godot 4.3

**Method**: `mcp_context7_get-library-docs`

**Parameters**:
- `context7CompatibleLibraryID`: `/godotengine/godot` (Godot 4.3)
- `topic`: API category (e.g., "Area2D CollisionShape2D", "Vector2 rotation", "projectile system")
- `tokens`: Maximum tokens (default: 5000)

**Returns**: Godot 4.3 API documentation snippet containing relevant APIs

**Validation Rules**:
- All referenced node types must exist in Godot 4.3
- All referenced methods must exist and have correct signatures
- All referenced constants/enums must exist
- Deprecated methods must be flagged for review

**Example**:
```markdown
Documentation Reference: "Uses Area2D with CollisionShape2D for damage detection"
Validation Query: mcp_context7_get-library-docs("/godotengine/godot", "Area2D CollisionShape2D", 3000)
Validation Result: ✅ Valid - Both Area2D and CollisionShape2D exist in Godot 4.3
```

---

### Node Type Validation

**Purpose**: Validate that weapon documentation references valid Godot 4.3 node types

**Target Node Types**:
- `Area2D` - Used for projectile collision and damage detection
- `CharacterBody2D` - Used for enemy/player physics
- `AnimatedSprite2D` - Used for projectile visuals
- `CollisionShape2D` - Used for collision shapes
- `CollisionPolygon2D` - Used for complex collision shapes
- `StaticBody2D` - Used for static obstacles (Boulder)
- `Node2D` - Base 2D node type

**Validation**: Query Context7 for each node type, confirm existence in Godot 4.3

---

### Method/API Validation

**Purpose**: Validate that weapon documentation references valid Godot 4.3 methods and properties

**Target Methods/Properties**:
- `rotation` - Node2D rotation property
- `angle()` - Vector2 angle method
- `normalized()` - Vector2 normalization
- `global_position` - Node2D position property
- `apply_damage()` - Enemy damage application
- `apply_knockback()` - Enemy knockback application
- `get_tree().create_timer()` - Scene tree timer creation
- `queue_free()` - Node cleanup

**Validation**: Query Context7 for each method/property, confirm existence and signature in Godot 4.3

---

## Project Standards Validation

### Documentation Template Compliance

**Purpose**: Ensure weapon documentation follows standard template structure

**Validation Rules**:
- All required sections must be present
- Section order must match template (or deviations documented)
- Formatting must follow markdown standards
- Code blocks must specify language (GDScript)

**Required Sections Checklist**:
- [ ] Overview
- [ ] Baseline Parameters
- [ ] Tome Interactions
- [ ] Adapter Rules (if applicable)
- [ ] Controller Integration
- [ ] File Structure
- [ ] Dependencies
- [ ] Lifecycle
- [ ] Debug Logging
- [ ] Known Pitfalls

---

### Cross-Reference Validation

**Purpose**: Ensure documentation cross-references are valid and consistent

**Validation Rules**:
- All references to main.md must point to existing sections
- All references to NORMALIZED_WEAPON_SYSTEM.md must point to existing content
- All references to other weapon docs must point to existing files
- File paths must be correct (relative to project root)

**Reference Format**:
- Internal: `[Section Name](./path/to/file.md#anchor)`
- External: `[Document Name](path/to/file.md)`

---

### Terminology Consistency

**Purpose**: Ensure consistent terminology across all weapon documentation

**Validation Rules**:
- "baseline" means default values without tomes
- "adapter" means special tome transformation for weapon
- "controller" refers to WeaponController or NormalizedWeaponController
- "runner" refers to NormalizedProjectileRunner
- Tome names must match actual tome IDs (Damage, Crit Chance, Size, Pierce, etc.)

---

## Integration Validation

### Main.md Integration Check

**Purpose**: Ensure weapon documentation aligns with main.md weapon system description

**Validation Rules**:
- Weapon descriptions must not contradict main.md
- Weapon list in docs must match main.md weapon examples
- Damage formula references must match main.md formula
- Tome system references must align with main.md tome descriptions

**Check Points**:
- Section 5 (Бой и оружие) - Weapon overview
- Section 10 (Weapon System) - Weapon system details
- Section 10 (Tome System) - Tome interactions

---

### NORMALIZED_WEAPON_SYSTEM.md Integration Check

**Purpose**: Ensure weapon documentation aligns with normalized weapon system configuration

**Validation Rules**:
- Flight type references must match ProjectileFlightType enum
- Aim mode references must match ProjectileAimMode enum
- Cast pattern references must match ProjectileCastPattern enum
- Configuration parameter names must match NormalizedProjectileConfig properties

**Check Points**:
- Flight types: DIRECT, BOOMERANG_RETURN_TO_ORIGIN, ORBIT_FIXED, CHAIN_ON_TARGET, etc.
- Aim modes: TARGETED, RANDOM_DIR, MOUSE_DIRECTION, etc.
- Cast patterns: FAN, SEQUENTIAL, WAVES, etc.

---

## Validation Workflow

### When Creating New Weapon Documentation

1. **Fill Template**: Use standard template, fill all required sections
2. **Validate Godot APIs**: Use Context7 to check all Godot API references
3. **Check Cross-References**: Verify all internal references point to existing docs
4. **Validate Integration**: Ensure alignment with main.md and NORMALIZED_WEAPON_SYSTEM.md
5. **Review Terminology**: Ensure consistent terminology usage
6. **Check Format**: Ensure markdown formatting is correct

---

### When Updating Existing Documentation

1. **Identify Changes**: What sections/APIs are being updated?
2. **Validate New APIs**: Use Context7 to check any new Godot API references
3. **Check Cross-References**: Verify updated references are still valid
4. **Validate Integration**: Ensure changes don't break integration with main.md
5. **Review Consistency**: Ensure updated terminology is consistent

---

### Periodic Validation

**Frequency**: Before major releases, or when Godot version changes

**Process**:
1. **Godot API Audit**: Validate all Godot API references against current version
2. **Cross-Reference Audit**: Check all internal references for broken links
3. **Integration Audit**: Review alignment with main.md and NORMALIZED_WEAPON_SYSTEM.md
4. **Completeness Audit**: Check documentation status for all weapons

---

## Error Handling

### Invalid Godot API Reference

**Detection**: Context7 validation fails, method/node type not found in Godot 4.3

**Action**:
1. Flag reference as invalid
2. Check if method was deprecated or renamed
3. Update documentation with correct Godot 4.3 API
4. Document change in Known Pitfalls section

---

### Broken Cross-Reference

**Detection**: Reference points to non-existent document or section

**Action**:
1. Flag reference as broken
2. Find correct document/section
3. Update reference with correct path
4. If target removed, remove reference or note as "legacy"

---

### Integration Conflict

**Detection**: Weapon documentation contradicts main.md or NORMALIZED_WEAPON_SYSTEM.md

**Action**:
1. Flag conflict
2. Determine authoritative source (main.md > NORMALIZED_WEAPON_SYSTEM.md > weapon doc)
3. Update weapon documentation to align with authoritative source
4. If weapon doc is correct, update main.md (with approval)

---

## Notes

- All validation is manual (no automated CI/CD integration)
- Context7 used for external API validation only (Godot 4.3)
- Project standards validated through manual review
- Validation results documented in weapon documentation or separate validation log

