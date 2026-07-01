# Data Model: Weapon Documentation System

**Feature**: 006-weapon-docs  
**Date**: 2024-12-28

## Overview

This feature is documentation-only and does not introduce new code entities. However, documentation itself has structure that can be modeled for validation and consistency.

## Documentation Entities

### Weapon Documentation Entry

**Purpose**: Complete documentation for a single weapon type

**Structure**:
- `weapon_name: String` - Weapon identifier (e.g., "ChainLightning", "Boulder")
- `baseline_parameters: Dictionary` - Default values:
  - `shots: int` - Projectiles per cast (default: 1)
  - `cooldown: float` - Cooldown between casts (seconds)
  - `damage_min: int` - Minimum damage
  - `damage_max: int` - Maximum damage
  - `flight_type: String` - Flight type enum value
  - `pierce_count: int` - Base pierce count
- `tome_interactions: Array[TomeInteractionSpec]` - List of tome interactions
- `adapter_rules: Array[AdapterRule]` - Special transformations (if any)
- `controller_requirements: Dictionary` - Controller integration:
  - `uses_weapon_controller: bool` - Legacy controller support
  - `uses_normalized_controller: bool` - Normalized controller support
  - `special_behavior: String` - Tome behavior enum (if applicable)
- `file_structure: Array[String]` - Required files (scripts, scenes, configs, resources)
- `dependencies: Array[String]` - Required nodes/scripts/resources
- `lifecycle_states: Array[String]` - State machine states (if applicable)
- `debug_markers: Array[String]` - Expected debug log marker patterns
- `known_pitfalls: Array[String]` - Common mistakes and resolved cases

**Validation Rules**:
- All baseline parameters must have explicit default values (no "varies" or "depends")
- Tome interactions must list all applicable tomes or explicitly state "no special interactions"
- Adapter rules must specify input tomes and output modifications
- Debug markers must follow format: `[WeaponName] ...`

---

### Tome Interaction Specification

**Purpose**: Documented rule describing how a specific tome affects a specific weapon

**Structure**:
- `tome_name: String` - Tome identifier (e.g., "Size", "Pierce", "Count")
- `weapon_name: String` - Weapon identifier
- `baseline_effect: String` - How tome normally affects weapons (reference to base tome behavior)
- `adapted_effect: String` - How tome is adapted for this weapon (if different)
- `conversion_formula: String` - Mathematical formula (if applicable, e.g., "5% per stack")
- `visual_change: bool` - Whether visual scaling occurs (default: true for Size tome)
- `metadata_key: String` - Metadata key used (if applicable, e.g., "chain_targets_bonus")

**Validation Rules**:
- If adapted_effect differs from baseline_effect, must specify adapter rule
- Conversion formulas must be quantifiable (percentages, multipliers, additions)
- Visual change flag must be explicit (true/false, not assumed)

---

### Adapter Rule

**Purpose**: Special transformation applied to tome modifiers for weapons with unique behavior

**Structure**:
- `weapon_name: String` - Weapon identifier
- `input_tomes: Array[String]` - Tomes that are transformed
- `transformation_type: String` - Type of transformation (e.g., "Size→Damage", "Pierce→ChainTargets")
- `transformation_formula: String` - How transformation works (e.g., "Size stacks → 5% damage per stack")
- `adapter_method: String` - Code reference (e.g., "TomeAdapters._apply_chain_lightning_rules")

**Validation Rules**:
- Must reference actual adapter method in code
- Transformation must be mathematically defined
- Must specify what happens to original tome effect (replaced, suppressed, combined)

---

### Documentation Template

**Purpose**: Standardized structure for weapon documentation

**Structure**:
- `required_sections: Array[String]` - Mandatory sections:
  1. Overview
  2. Baseline Parameters
  3. Tome Interactions
  4. Adapter Rules (if applicable)
  5. Controller Integration
  6. File Structure
  7. Dependencies
  8. Lifecycle
  9. Debug Logging
  10. Known Pitfalls
- `optional_sections: Array[String]` - Optional sections:
  - Architecture Details
  - Movement Mechanics
  - Damage System Details
  - Examples
- `format_rules: Dictionary` - Formatting requirements:
  - `markdown_levels: Dictionary` - Section heading levels
  - `code_block_language: String` - Default language (GDScript)
  - `cross_reference_format: String` - Link format

**Validation Rules**:
- All required sections must be present in documentation
- Optional sections may be omitted for simple weapons
- Format must follow markdown standards

---

### Validation Rule

**Purpose**: Check that ensures documentation aligns with Godot 4.3 API and project standards

**Structure**:
- `validation_type: String` - Type of check (e.g., "GodotAPI", "ProjectStandard", "CrossReference")
- `target_content: String` - Content to validate (e.g., "Area2D", "rotation = 0°")
- `expected_result: String` - What validation should find (e.g., "valid Godot 4.3 API", "consistent with main.md")
- `validation_method: String` - How to validate (e.g., "Context7 API check", "manual review")

**Validation Rules**:
- Godot API references must be validated against Godot 4.3 documentation
- Project standard references must match actual project structure
- Cross-references must point to existing documentation

---

## Documentation Status Model

### Weapon Documentation Status

**Purpose**: Track documentation completeness for all weapons

**Structure**:
- `weapon_name: String` - Weapon identifier
- `status: String` - Status enum: "documented", "partial", "pending", "not_applicable"
- `completeness_percentage: int` - Percentage of required sections complete (0-100)
- `last_updated: String` - Date of last update (ISO format)
- `source_files: Array[String]` - Source documentation files
- `integrated_guide: String` - Path to integrated guide (if exists)

**Validation Rules**:
- Status "documented" requires completeness_percentage >= 90%
- Status "partial" requires completeness_percentage >= 50%
- Status "pending" applies to weapons with no documentation

---

## Cross-Reference Model

### Documentation Reference

**Purpose**: Links between documentation files

**Structure**:
- `from_document: String` - Source document path
- `to_document: String` - Target document path
- `reference_type: String` - Type: "integration", "detail", "example", "related"
- `anchor: String` - Specific section anchor (if applicable)

**Validation Rules**:
- All references must point to existing documents
- References should use relative paths within project
- Broken references must be flagged during validation

---

## Notes

- This data model represents documentation structure, not code entities
- Validation ensures consistency and completeness across all weapon documentation
- Status tracking enables progress monitoring (~20 weapons, 2 documented, 18 pending)

