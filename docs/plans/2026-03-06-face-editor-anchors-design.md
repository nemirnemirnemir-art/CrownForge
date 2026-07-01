---
description: Face editor anchors for Character Creation
---

# Goal

Allow moving the embedded face editor layout directly in Godot `2D View` without editing code, and fix the missing embedded head display.

# Chosen approach

Use editor-visible anchor nodes inside `CharacterCreationScratchEditable` and `CharacterCreationScratch`.

## Anchor nodes

- `HeadAnchor`
  - Controls where the embedded `FaceRigTest` character head appears.
- `SettingsAnchor`
  - Controls where the embedded face settings panel appears.

These anchors will be draggable in `2D View` like normal scene nodes.

# Runtime behavior

`FaceRigTest.gd` in `embed_mode` will:

- disable only the embedded `Camera2D`
- keep the face settings UI visible
- read anchor positions from the parent scene when available
- place the embedded settings panel using `SettingsAnchor`

# Head visibility fix

The embedded head should be visible without requiring code edits. The fix should ensure:

- stable embedded placement for the `FaceRigTest` root
- visible face base / head rendering in embed mode
- no dependency on the preview camera

# Validation

- Verify both `CharacterCreationScratchEditable.tscn` and `CharacterCreationScratch.tscn` load correctly
- Run `res://scripts/dev/tests/test_character_creation_class_token_modes.gd`
