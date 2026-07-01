# Research: Weapon Documentation System

**Feature**: 006-weapon-docs  
**Date**: 2024-12-28  
**Status**: Complete

## Research Tasks

### Task 1: Documentation Integration Strategy

**Question**: How should existing documentation files (DefaultWeaponDocumentation.md, BOULDER_WEAPON_GUIDE.md, PROJECTILE_ORIENTATION_GUIDE.md) be integrated into unified spec structure without breaking existing references?

**Findings**:
- Existing files are in `docs/` directory and may be referenced by developers
- Spec structure (`specs/006-weapon-docs/`) follows established pattern (see specs/001, 002, 004)
- Need to maintain backward compatibility while providing unified navigation

**Decision**: Preserve source files in `docs/` as authoritative references. Create integrated guides in `specs/006-weapon-docs/guides/` that copy/refactor content into unified format. Add cross-references between integrated guides and source files. Create index/navigation in `specs/006-weapon-docs/` for discovery.

**Rationale**: 
- Maintains backward compatibility (existing references continue to work)
- Allows gradual migration without breaking changes
- Preserves history and context of original documentation
- Provides single navigation point through spec structure

**Alternatives considered**:
- Full migration to spec structure only (rejected - breaks existing references, loses context)
- Duplication without integration (rejected - maintenance overhead, confusion)
- Links only without copying (rejected - doesn't provide unified structure)

---

### Task 2: Documentation Template Structure

**Question**: What standard template structure should be used for weapon documentation to ensure completeness and consistency?

**Findings**:
- Existing documentation has different structures:
  - DefaultWeaponDocumentation.md: concise reference format (baseline, tomes, adapters, controllers, debug)
  - BOULDER_WEAPON_GUIDE.md: comprehensive guide format (overview, file structure, architecture, configuration, lifecycle, mechanics, damage, examples, debugging)
  - PROJECTILE_ORIENTATION_GUIDE.md: standards guide format (problem, rules, examples, checklist)
- Need unified structure that accommodates different complexity levels

**Decision**: Standard template with required sections:
1. **Overview**: Weapon description, key features, states (if applicable)
2. **Baseline Parameters**: Default values (shots, cooldown, damage range, flight type)
3. **Tome Interactions**: Which tomes apply, how they're interpreted, special adapter rules
4. **Adapter Rules**: Special transformations for this weapon (if any)
5. **Controller Integration**: WeaponController vs NormalizedWeaponController usage
6. **File Structure**: Scripts, scenes, configs, resources
7. **Dependencies**: Required nodes/scripts/resources
8. **Lifecycle**: Spawn, update, despawn conditions
9. **Debug Logging**: debug_logs flags, expected marker formats
10. **Known Pitfalls**: Common mistakes and resolved cases

**Rationale**: 
- Ensures all critical information is documented
- Allows comparison across weapons
- Covers baseline behavior, tome effects, integration, and debugging
- Flexible enough for simple weapons (Chain Lightning) and complex ones (Boulder)

**Alternatives considered**:
- Minimal template (Overview, Parameters, Tome Interactions only) - rejected: misses critical integration/debug info
- Over-detailed template (includes code examples, detailed architecture) - rejected: too complex for simple weapons, better for separate guides

---

### Task 3: Context7 Validation Integration

**Question**: How should Context7 be integrated for Godot 4.3 API validation of weapon documentation?

**Findings**:
- Context7 is MCP server for external library documentation (appropriate for Godot 4.3 API validation)
- Documentation may reference Godot APIs (Area2D, CollisionShape2D, Vector2, rotation, etc.)
- Need to validate that all API references are compatible with Godot 4.3
- Project constitution specifies when to use Context7 (external API documentation)

**Decision**: Use Context7 for on-demand validation during documentation updates. Validate:
- All Godot node types referenced (Area2D, CharacterBody2D, AnimatedSprite2D, etc.)
- All Godot methods/APIs referenced (rotation, angle(), Vector2, etc.)
- All Godot constants/enums referenced (collision layers, physics properties)
- Deprecated methods check (flag any methods that don't exist in Godot 4.3)

Validation performed manually when:
- Creating new weapon documentation
- Updating existing documentation
- Suspecting API changes

**Rationale**: 
- Manual validation sufficient for documentation accuracy (not high-frequency operation)
- Avoids adding external dependency to automated builds
- Context7 usage aligns with constitution guidelines (external library documentation)
- On-demand validation catches issues without blocking development

**Alternatives considered**:
- Automated validation in CI/CD pipeline (rejected - adds external dependency, may slow builds, manual validation sufficient)
- No validation (rejected - risks outdated/deprecated API references, breaks constitution requirement for Godot 4.3)

---

### Task 4: Navigation and Discovery

**Question**: How should developers discover and navigate weapon documentation?

**Findings**:
- ~20 weapon types in project, only 2 documented in detail
- Documentation scattered across multiple files (docs/, data/config/)
- Need single entry point for discovery
- Need to integrate with main.md and NORMALIZED_WEAPON_SYSTEM.md

**Decision**: Single navigation point through `specs/006-weapon-docs/` structure:
- Index file or README.md listing all weapon documentation
- Cross-references to source files in `docs/` (for backward compatibility)
- Cross-references to `main.md` (weapon system overview)
- Cross-references to `NORMALIZED_WEAPON_SYSTEM.md` (configuration details)
- Template link for new weapon documentation
- Status indicators (documented/pending) for each weapon type

Navigation structure:
- Top-level: `specs/006-weapon-docs/README.md` or index
- Guides: `specs/006-weapon-docs/guides/[weapon-name].md`
- Template: `specs/006-weapon-docs/templates/weapon-doc-template.md`

**Rationale**: 
- Provides central access point while maintaining links to detailed guides
- Status indicators help track documentation completeness
- Template ensures consistency for new documentation
- Cross-references maintain integration with existing documentation

**Alternatives considered**:
- Separate documentation site/website (rejected - overkill for internal documentation, maintenance overhead)
- No navigation/index (rejected - defeats purpose of centralization, hard to discover)

---

### Task 5: Integration with Existing Documentation

**Question**: How should weapon documentation integrate with main.md and NORMALIZED_WEAPON_SYSTEM.md without conflicts?

**Findings**:
- main.md contains weapon system overview (section 5, 10)
- NORMALIZED_WEAPON_SYSTEM.md contains configuration system details
- Weapon documentation should reference but not duplicate these

**Decision**: Integration pattern:
- Weapon documentation references main.md for weapon system overview and general principles
- Weapon documentation references NORMALIZED_WEAPON_SYSTEM.md for configuration parameters and flight types
- Weapon documentation provides weapon-specific details not covered in general docs
- Cross-reference validation ensures no contradictions

**Rationale**: 
- Avoids duplication and maintenance overhead
- Maintains single source of truth for general principles
- Weapon docs focus on weapon-specific details
- Integration ensures consistency

**Alternatives considered**:
- Duplicate general info in each weapon doc (rejected - maintenance nightmare, inconsistency risk)
- No integration (rejected - creates disconnected documentation, confusion)

---

## Summary

All research tasks completed. No unresolved clarifications. Structure validated against existing spec patterns. Integration strategy preserves backward compatibility while providing unified navigation. Template structure balances completeness with flexibility. Context7 validation aligns with constitution guidelines for external API documentation.

