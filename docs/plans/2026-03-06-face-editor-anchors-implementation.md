# Face Editor Anchors Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Let the user move the embedded face head and settings panel in Godot `2D View` without editing code, and restore visible embedded head rendering.

**Architecture:** `CharacterCreationScratchEditable.tscn` and `CharacterCreationScratch.tscn` will expose editor-visible anchor nodes. `FaceRigTest.gd` will use those anchors in `embed_mode` for panel placement and will raise the embedded rig render order so the head stays visible above the decorative plates while preserving internal face layering.

**Tech Stack:** Godot 4.3, GDScript, `.tscn` scenes

---

### Task 1: Add editor-visible anchors to character creation scenes

**Files:**
- Modify: `scenes/dev/CharacterCreationScratchEditable.tscn`
- Modify: `scenes/dev/CharacterCreationScratch.tscn`

**Step 1: Add a visible head anchor node**
- Replace the generic face rig holder with a named anchor node that is easy to drag in `2D View`.

**Step 2: Add a settings anchor node**
- Add a second draggable anchor used for the embedded face settings panel position.

**Step 3: Keep the embedded face rig under the head anchor**
- Preserve the instance placement and scale while making the hierarchy editor-friendly.

### Task 2: Make embed mode follow scene anchors and fix head rendering

**Files:**
- Modify: `scripts/dev/FaceRigTest.gd`

**Step 1: Resolve anchor lookup in ancestor scenes**
- Add a helper that finds `SettingsAnchor` from the embedded scene instance.

**Step 2: Apply settings panel position from the anchor**
- In `embed_mode`, use the anchor global position when present.

**Step 3: Raise embedded rig render order**
- Ensure the embedded face rig root renders above the decorative plates so the head base is visible.

### Task 3: Validate scene loading

**Files:**
- Test: `scripts/dev/tests/test_character_creation_class_token_modes.gd`

**Step 1: Run the existing headless test**
- Verify scene loading still passes after anchor and render-order changes.

**Step 2: Check for unexpected regressions**
- Review output for scene load errors related to the embedded face rig.
