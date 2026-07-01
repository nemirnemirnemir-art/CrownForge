# Implementation Tasks: Weapon Documentation System

**Feature**: 006-weapon-docs  
**Branch**: `006-weapon-docs`  
**Created**: 2024-12-28  
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Overview

This feature integrates existing weapon documentation (DefaultWeaponDocumentation.md, BOULDER_WEAPON_GUIDE.md, PROJECTILE_ORIENTATION_GUIDE.md) into unified spec structure with Context7 validation for Godot 4.3. Creates centralized documentation system providing single navigation point for all weapon types.

**Total Tasks**: 47  
**MVP Scope**: Phases 1-4 (Setup, Foundational, User Story 1, User Story 2) - 24 tasks

---

## Dependencies

### User Story Completion Order

1. **User Story 1** (P1) - Find Weapon Documentation → **No dependencies** (MVP)
2. **User Story 2** (P1) - Understand Tome Interactions → **Depends on**: US1 (needs integrated guides structure)
3. **User Story 3** (P2) - Validate Weapon Documentation → **Depends on**: US1, US2 (needs documented weapons to validate)
4. **User Story 4** (P2) - Follow Standard Template → **Depends on**: US1 (needs template created in foundational phase)

### Parallel Execution Opportunities

- **US1 and US2**: Can be partially parallel (US2 tome sections can be written while US1 structure is created)
- **US3 validation tasks**: Can be parallelized by weapon type (each weapon can be validated independently)
- **Polish tasks**: Can be done in parallel with any user story

---

## Phase 1: Setup

**Goal**: Create documentation directory structure and validate existing source files

**Independent Test**: Directory structure exists, source files are accessible and readable

- [x] T001 Create `specs/006-weapon-docs/guides/` directory for integrated weapon guides
- [x] T002 Create `specs/006-weapon-docs/templates/` directory for documentation templates
- [x] T003 Validate existing source file `docs/DefaultWeaponDocumentation.md` is accessible and contains Chain Lightning documentation
- [x] T004 Validate existing source file `docs/BOULDER_WEAPON_GUIDE.md` is accessible and contains Boulder documentation
- [x] T005 Validate existing source file `docs/PROJECTILE_ORIENTATION_GUIDE.md` is accessible and contains orientation standards
- [x] T006 Verify integration points exist: `main.md` (weapon system overview) and `data/config/NORMALIZED_WEAPON_SYSTEM.md` (configuration details)

---

## Phase 2: Foundational

**Goal**: Create documentation template and establish structure standards

**Independent Test**: Template file exists with all required sections, follows data-model.md structure

- [x] T007 [P] Create weapon documentation template with all 10 required sections in `specs/006-weapon-docs/templates/weapon-doc-template.md`
- [x] T008 [P] Add Overview section placeholder to template in `specs/006-weapon-docs/templates/weapon-doc-template.md`
- [x] T009 [P] Add Baseline Parameters section placeholder to template in `specs/006-weapon-docs/templates/weapon-doc-template.md`
- [x] T010 [P] Add Tome Interactions section placeholder to template in `specs/006-weapon-docs/templates/weapon-doc-template.md`
- [x] T011 [P] Add Adapter Rules section placeholder to template in `specs/006-weapon-docs/templates/weapon-doc-template.md`
- [x] T012 [P] Add Controller Integration section placeholder to template in `specs/006-weapon-docs/templates/weapon-doc-template.md`
- [x] T013 [P] Add File Structure section placeholder to template in `specs/006-weapon-docs/templates/weapon-doc-template.md`
- [x] T014 [P] Add Dependencies section placeholder to template in `specs/006-weapon-docs/templates/weapon-doc-template.md`
- [x] T015 [P] Add Lifecycle section placeholder to template in `specs/006-weapon-docs/templates/weapon-doc-template.md`
- [x] T016 [P] Add Debug Logging section placeholder to template in `specs/006-weapon-docs/templates/weapon-doc-template.md`
- [x] T017 [P] Add Known Pitfalls section placeholder to template in `specs/006-weapon-docs/templates/weapon-doc-template.md`

---

## Phase 3: User Story 1 - Find Weapon Documentation (P1)

**Goal**: Integrate existing documentation files into unified structure providing single navigation point

**Independent Test**: Can be fully tested by checking if all weapon types in the project (~20 weapons) have corresponding documentation entries that can be found through a single navigation point. This delivers immediate access to weapon information for any developer.

**Acceptance Criteria**:
- All existing documented weapons (Chain Lightning, Boulder) are integrated into unified structure
- Navigation/index file provides single entry point with verification status indicators
- Projectile orientation guide is integrated
- All integrated guides follow standard template structure with verification status sections

**IMPORTANT**: Since many weapons are not fully tested, documentation will include verification status markers:
- `[ПРОВЕРЕНО]` - Tested and verified
- `[ТРЕБУЕТ ПРОВЕРКИ]` - Based on code analysis, needs testing
- `[БАГ]` - Known issue/bug
- `[НЕИЗВЕСТНО]` - Unclear behavior

- [x] T018 [US1] Add verification status section to documentation template in `specs/006-weapon-docs/templates/weapon-doc-template.md`
- [x] T019 [US1] Create integrated guide for projectile orientation from `docs/PROJECTILE_ORIENTATION_GUIDE.md` to `specs/006-weapon-docs/guides/projectile-orientation.md`
- [x] T020 [US1] Create integrated guide for Chain Lightning from `docs/DefaultWeaponDocumentation.md` to `specs/006-weapon-docs/guides/chain-lightning.md` (mark as [ПРОВЕРЕНО] where applicable)
- [x] T021 [US1] Convert Chain Lightning guide to standard template format with all 10 required sections + verification status in `specs/006-weapon-docs/guides/chain-lightning.md`
- [x] T022 [US1] Create integrated guide for Boulder from `docs/BOULDER_WEAPON_GUIDE.md` to `specs/006-weapon-docs/guides/boulder.md` (mark as [ПРОВЕРЕНО] where applicable)
- [x] T023 [US1] Convert Boulder guide to standard template format with all 10 required sections + verification status in `specs/006-weapon-docs/guides/boulder.md`
- [x] T024 [US1] Add cross-references from integrated guides to source files in `specs/006-weapon-docs/guides/chain-lightning.md`
- [x] T025 [US1] Add cross-references from integrated guides to source files in `specs/006-weapon-docs/guides/boulder.md`
- [x] T026 [US1] Create navigation index/README listing all weapon documentation with verification status in `specs/006-weapon-docs/README.md`

---

## Phase 4: User Story 2 - Understand Tome Interactions for Weapons (P1)

**Goal**: Document tome interactions for all integrated weapons with explicit rules and adapter behaviors

**Independent Test**: Can be fully tested by verifying that documentation for each weapon type explicitly lists which tomes apply, how they're interpreted (including special adapter rules), and what the expected behavior is. This delivers clear understanding of weapon-tome relationships.

**Acceptance Criteria**:
- Chain Lightning tome interactions documented with all adapter rules
- Boulder tome interactions documented (baseline or adapted)
- All applicable tomes listed for each weapon
- Adapter rules clearly specify input tomes and output modifications

- [ ] T027 [US2] Document Chain Lightning tome interactions section with Size→Damage adapter rule in `specs/006-weapon-docs/guides/chain-lightning.md` (mark verification status)
- [ ] T028 [US2] Document Chain Lightning tome interactions section with Pierce→ChainTargets adapter rule in `specs/006-weapon-docs/guides/chain-lightning.md` (mark verification status)
- [ ] T029 [US2] Document Chain Lightning tome interactions section with Count adapter behavior in `specs/006-weapon-docs/guides/chain-lightning.md` (mark verification status)
- [ ] T030 [US2] Document Chain Lightning adapter rules section with transformation formulas and adapter method references in `specs/006-weapon-docs/guides/chain-lightning.md` (mark verification status)
- [ ] T031 [US2] Document Boulder tome interactions section with baseline tome effects in `specs/006-weapon-docs/guides/boulder.md` (mark as [ТРЕБУЕТ ПРОВЕРКИ] if not verified)
- [ ] T032 [US2] Verify Boulder uses default tome behavior (no special adapters) and document explicitly in `specs/006-weapon-docs/guides/boulder.md` (mark verification status)
- [ ] T033 [US2] Add cross-references to TomeAdapters.gd code for adapter rules in `specs/006-weapon-docs/guides/chain-lightning.md`
- [ ] T034 [US2] Document any known bugs or unclear tome interactions in Chain Lightning guide with [БАГ] or [НЕИЗВЕСТНО] markers

---

## Phase 5: User Story 3 - Validate Weapon Documentation Against Godot 4.3 Standards (P2)

**Goal**: Validate all Godot API references in weapon documentation against Godot 4.3 specifications using Context7

**Independent Test**: Can be fully tested by running Context7 validation against weapon documentation to verify that all referenced Godot APIs, node types, and methods are valid for Godot 4.3. This delivers confidence that documentation is technically accurate.

**Acceptance Criteria**:
- All Godot node types referenced are validated (Area2D, CharacterBody2D, AnimatedSprite2D, etc.)
- All Godot methods/APIs referenced are validated (rotation, angle(), Vector2, etc.)
- All deprecated methods are flagged for review
- Validation results documented in guides

- [ ] T035 [US3] [P] Validate Area2D and CollisionShape2D references in `specs/006-weapon-docs/guides/chain-lightning.md` using Context7 Godot 4.3 API
- [ ] T036 [US3] [P] Validate CharacterBody2D references in `specs/006-weapon-docs/guides/boulder.md` using Context7 Godot 4.3 API
- [ ] T037 [US3] [P] Validate AnimatedSprite2D references in `specs/006-weapon-docs/guides/boulder.md` using Context7 Godot 4.3 API
- [ ] T038 [US3] [P] Validate Vector2 and rotation API references in `specs/006-weapon-docs/guides/projectile-orientation.md` using Context7 Godot 4.3 API
- [ ] T039 [US3] [P] Validate get_tree().create_timer() and queue_free() method references using Context7 Godot 4.3 API
- [ ] T040 [US3] Validate all Godot API references in Chain Lightning guide are compatible with Godot 4.3 in `specs/006-weapon-docs/guides/chain-lightning.md`
- [ ] T041 [US3] Validate all Godot API references in Boulder guide are compatible with Godot 4.3 in `specs/006-weapon-docs/guides/boulder.md`
- [ ] T042 [US3] Flag any deprecated methods found during validation for review with [БАГ] marker

---

## Phase 6: User Story 4 - Follow Standard Documentation Template (P2)

**Goal**: Ensure all integrated guides follow standard template structure for consistency

**Independent Test**: Can be fully tested by verifying that all existing weapon documentation (Chain Lightning, Boulder) follows the same template structure and that new documentation can use the template. This delivers consistent documentation quality.

**Acceptance Criteria**:
- All integrated guides follow template structure
- Required sections present in all guides
- Formatting consistent across guides
- Template can be used for new weapons

- [ ] T043 [US4] Verify Chain Lightning guide has all 10 required sections + verification status section matching template structure in `specs/006-weapon-docs/guides/chain-lightning.md`
- [ ] T044 [US4] Verify Boulder guide has all 10 required sections + verification status section matching template structure in `specs/006-weapon-docs/guides/boulder.md`
- [ ] T045 [US4] Verify Projectile Orientation guide follows template format (if applicable) in `specs/006-weapon-docs/guides/projectile-orientation.md`
- [ ] T046 [US4] Ensure consistent markdown formatting across all integrated guides
- [ ] T047 [US4] Verify template file includes verification status section for new weapon documentation

---

## Phase 7: Polish & Cross-Cutting Concerns

**Goal**: Integrate with main.md and NORMALIZED_WEAPON_SYSTEM.md, create status tracking, finalize navigation

**Independent Test**: All documentation integrates without conflicts, navigation provides single entry point, cross-references are valid

- [ ] T048 Add cross-references from weapon documentation to `main.md` weapon system overview section
- [ ] T049 Add cross-references from weapon documentation to `data/config/NORMALIZED_WEAPON_SYSTEM.md` configuration details
- [ ] T050 Verify all cross-references in integrated guides point to existing documents
- [ ] T051 Create documentation status tracking (documented/pending/untested) for all ~20 weapon types in `specs/006-weapon-docs/README.md`
- [ ] T052 Update navigation index with verification status indicators ([ПРОВЕРЕНО]/[ТРЕБУЕТ ПРОВЕРКИ]/[БАГ]/[НЕИЗВЕСТНО]) for each weapon type in `specs/006-weapon-docs/README.md`
- [ ] T053 Verify backward compatibility: source files in `docs/` remain accessible and functional

---

## Implementation Strategy

### MVP First Approach

**MVP Scope**: Phases 1-4 (26 tasks) - includes verification status system
- Phase 1: Setup directory structure
- Phase 2: Create documentation template
- Phase 3: Integrate Chain Lightning and Boulder documentation
- Phase 4: Document tome interactions for integrated weapons

**MVP Deliverable**: 
- Centralized navigation point for weapon documentation
- Integrated guides for Chain Lightning and Boulder following standard template
- Documentation template ready for new weapons
- Tome interactions documented for integrated weapons

### Incremental Delivery

1. **Iteration 1** (MVP): Phases 1-4 - Core documentation structure and 2 weapon guides
2. **Iteration 2**: Phase 5 - Godot 4.3 API validation for existing guides
3. **Iteration 3**: Phase 6 - Template consistency verification
4. **Iteration 4**: Phase 7 - Integration with main docs and status tracking

### Parallel Execution Strategy

- **T007-T017** (template creation): All can be done in parallel (different sections)
- **T033-T037** (API validation): Can be parallelized by weapon/file
- **T041-T045** (template verification): Can be done in parallel with validation tasks

---

## Task Summary

**Total Tasks**: 54  
**Setup Tasks**: 6 (Phase 1)  
**Foundational Tasks**: 11 (Phase 2)  
**US1 Tasks**: 9 (Phase 3) - includes verification status section  
**US2 Tasks**: 8 (Phase 4) - includes verification markers  
**US3 Tasks**: 8 (Phase 5)  
**US4 Tasks**: 5 (Phase 6) - includes verification status verification  
**Polish Tasks**: 7 (Phase 7) - includes verification status tracking

**Parallelizable Tasks**: 28 (marked with [P])

**Suggested MVP Scope**: Phases 1-4 (26 tasks) - Core documentation structure with 2 integrated weapon guides and verification status system

---

## Notes

- All file paths use absolute paths from project root
- Context7 validation should be performed on-demand during documentation updates
- Source files in `docs/` remain authoritative references (backward compatibility maintained)
- New weapons can use template from Phase 2 to ensure consistency

