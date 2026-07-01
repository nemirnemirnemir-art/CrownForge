# Engineering Standards

Last updated: 12.02.2026

## Architecture

1. Prefer scene-first composition for gameplay/UI entities.
2. Keep root scripts as thin orchestrators.
3. Move concrete behavior to focused components/resources.
4. Prefer signals/event bus over deep parent traversal.

## Godot 4.3 coding standards

1. Use static typing for variables, parameters, and return values.
2. Use `snake_case` for members/functions and `PascalCase` for class names.
3. Keep indentation style consistent within each `.gd` file.

## Hero scene standards

1. Every hero/unit id must have a dedicated entry scene at `res://scenes/heroes/<unit_id>.tscn`.
2. Scene resolution must go through `res://scripts/hero/HeroSceneRegistry.gd`.
3. Do not hardcode hero-id scene branches in gameplay or debug scripts.
4. Hero entry scenes must be fully local scenes; inherited/instanced wrapper roots are not allowed.
5. Hero entry/base scenes must expose dual animation nodes: `AnimWalk` and `AnimAttack` (`AnimatedSprite2D`).
6. Single-node `AnimationSprite2D`-only setup is not a valid standard for hero entry/base scenes.
7. In Godot editor terms: no yellow inherited nodes in `res://scenes/heroes/*.tscn`.
8. Reuse scripts/components for shared behavior instead of hero scene inheritance.

## Debugging and observability

1. Add diagnostics for new mechanics.
2. Throttle recurring logs to avoid spam.
3. Use explicit debug toggles for heavy logging paths.

## AI-generated test policy

1. Do not add new AI-generated ad-hoc test scripts for ordinary gameplay or artifact changes.
2. This project-level restriction overrides automatic test creation habits, including flows suggested by `superpowers:test-driven-development`.
3. New files under `scripts/dev/tests/` require explicit user request or explicit user approval of a named test file.
4. Prefer direct implementation plus manual in-game verification over expanding the test-script surface.
5. Update existing approved tests only when necessary; do not grow parallel duplicate coverage.

## UI standards

1. Keep tooltip/popup hover logic stable.
2. Avoid timer-driven teardown/rebuild of hovered UI nodes.
3. Prefer refresh on data-change signals.

## Terminology

1. Unit = any combat entity (heroes + enemies).
2. Hero = player-controlled unit.
3. Mob/Enemy = hostile AI-controlled unit.
