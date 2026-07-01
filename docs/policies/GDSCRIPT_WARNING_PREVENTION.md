# GDScript Warning Prevention

Last updated: 26.03.2026

This document defines the mandatory anti-warning checklist for any AI or human editing GDScript in this repository.

## Mandatory pre-edit rule

1. Before editing existing code or adding new code, read this document or keep its checklist in working memory.
2. Do not treat yellow editor warnings as harmless noise.
3. New code must not introduce fresh editor warnings when the warning can be avoided with a small local fix.

## Main warning classes to prevent

1. Shadowed global identifiers
   - Do not create `const`/`var` names that duplicate `class_name` globals such as `CombatTargetFinder`, `FloatingText`, `HeroCombatTypeResolver`, or other globally registered scripts.
   - Prefer one of these patterns instead:
     - use the global class directly
     - use a suffixed preload alias like `CombatTargetFinderScript`
     - use a domain-specific name like `_target_finder`

2. Shadowing base-class properties
   - Never name local variables `owner` inside Nodes.
   - Use `owner_node`, `parent_node`, `source_node`, `target_node`, etc.

3. Unused parameters and locals
   - If a parameter is intentionally unused, prefix it with `_`.
   - If a local/debug variable is intentionally retained but unused, prefix it with `_`.
   - If a field/signal is truly unused, delete it instead of renaming it.

4. Enum typing
   - When restoring or assigning enum-backed values, cast to the enum type, not just `int`.
   - Example: `Node.ProcessMode(int(saved_value))`

5. Ternary typing
   - Avoid typed ternary expressions when branches come from different static types or Variant-heavy properties.
   - Prefer explicit initialization plus `if` reassignment.

6. Integer division and numeric coercion
   - If a float result is intended, use float literals or explicit casts.
   - Prefer `2.0`, `3.0`, `float(value)`, `Vector2(...) / 2.0`, etc.

## Project architecture rules tied to warnings prevention

1. Prefer scene composition through `.tscn` files over giant all-in-one scripts.
2. Prefer small focused scripts/modules over monoliths.
3. Main runtime scripts should act as orchestrators/coordinators, not as the place where every low-level behavior is implemented.
4. If a script becomes a warning magnet because it owns too many responsibilities, split it into smaller modules instead of piling on patches.
5. Reuse canonical global classes carefully; do not wrap or duplicate them with conflicting names unless there is a clear reason.

## Safe naming conventions

1. For preloaded helper scripts, prefer names ending in `Script` when a global class of the same feature exists.
2. For temporary node refs, prefer `*_node`, `parent_*`, `owner_*`, `source_*`, `target_*`.
3. For intentionally unused placeholders, use `_name`.
4. For cached private fields, use `_field_name`.

## Pre-commit / pre-finish checklist

1. Scan edited files for:
   - shadowed `class_name` identifiers
   - local `owner` variables
   - typed ternaries
   - enum assignments from raw integers
   - unused parameters/locals/signals/fields
2. If you changed architecture, update docs in the same task.
3. If you introduced a new reusable pattern, document it in `AGENTS.md`, `ARCHITECTURE.md`, or the relevant system page.

## Related docs

1. `docs/AGENTS.md`
2. `docs/ARCHITECTURE.md`
3. `docs/PROJECT_NAVIGATOR.md`
4. `docs/WIKI_HOME.md`
5. `docs/HERO_ADDING_CHECKLIST.md`
