# Scene Marker Standard

This document defines marker placement requirements for gameplay scenes and biomes that use `MapMarkerService`.

## Marker contract

Markers must be `MapMarker` nodes (or `Node2D` nodes in the correct marker group) using `res://scripts/map/MapMarker.gd`.

### 1) Spawn markers

- Group: `spawn_markers`
- Purpose: enemy spawn positions
- Count: minimum 1, recommended 3-5
- Properties:
  - `marker_type = SPAWN`
  - `priority` in range 1-5 (1 = highest)
  - optional `marker_id` (`cave`, `forest_edge`, etc.)

### 2) Defense markers

- Group: `defense_markers`
- Purpose: hero defense positions near wall
- Count: 6 (party slots)
- Properties:
  - `marker_type = DEFENSE`
  - `priority` as slot index (0-5)

### 3) Portal marker

- Group: `portal_markers`
- Purpose: portal/home position
- Count: 1
- Properties:
  - `marker_type = PORTAL`

### 4) Bridge marker

- Group: `bridge_markers`
- Purpose: transition/rally position
- Count: 1
- Properties:
  - `marker_type = BRIDGE`

### 5) Wall marker

- Group: `wall_markers`
- Purpose: wall target position
- Count: 1
- Properties:
  - `marker_type = WALL`

## New scene checklist

1. Add `WorldYSort/MapContainer`.
2. Place `spawn_markers` outside immediate defense line.
3. Place `defense_markers` in front of wall.
4. Place `portal_marker`.
5. Place `wall_marker` on defense line.
6. Verify every marker has correct script, group, and `marker_type`.
