Last updated: 27.03.2026

This file is the project-level contract for AI agents working in this repository.

## Required startup context

1. Read `docs/project_description.md` before starting any task.
2. Before editing existing code or adding new code, read `docs/policies/GDSCRIPT_WARNING_PREVENTION.md` and keep its checklist in working memory during implementation.
3. Use `docs/README.md` as the top-level index for the `docs/` folder.
4. Use `docs/WIKI_HOME.md` as the documentation entrypoint.
5. Use `docs/PROJECT_NAVIGATOR.md` for quick file-level orientation.
6. Use `docs/ARCHITECTURE.md` for runtime ownership, orchestrator boundaries, and composition rules.
7. Treat `docs/PROJECT_NAVIGATOR.md`, `docs/ARCHITECTURE.md`, and focused existing docs as the current canonical runtime references.
8. For MainMenu, start flow, CharacterCreation, runtime HUD, and king ability UX, review `docs/PROJECT_NAVIGATOR.md` and `docs/ARCHITECTURE.md` together.
9. Use `docs/wiki_buildings/` as the primary local source for building and upgrade data.

## Agent execution policy

1. Always use relevant superpowers skills for planning, debugging, implementation, review, and verification in this repository.
2. If the intended action is already clear from the user request and the repository context, do not ask unnecessary clarification questions; proceed directly to implementation.
3. Ask follow-up questions only when a real ambiguity would materially risk implementing the wrong behavior.
4. **Do not ask confirmation questions for explicit resources.** If the user directly provides:
   - an exact file path, URL, or resource identifier
   - and the repository confirms it exists
   - and using that resource does not change architecture or violate project policies
   
   Then use it directly without asking "Is this what you want?" For example:
   - **Bad:** User gives `C:\Godot\clickcer\assets\ui\fonts\ThaleahFat.ttf`, repo confirms it exists → AI asks "Use this font?"
   - **Good:** AI uses the font directly without asking for confirmation.

## Deletion semantics

1. When the user says to delete something from the game, treat that as **full removal by default**.
2. Full removal means:
   - gameplay/runtime reachability is removed;
   - related `tscn`, `gd`, `tres`, and other content files are removed or detached as needed;
   - docs, wiki pages, and other project-facing references are also cleaned up.
3. Do **not** keep asking whether deletion should be partial if the user did not explicitly ask for a partial deletion.
4. Only ask for clarification when the user explicitly scopes the deletion to a specific area or says they want a partial removal.

## Language policy

1. Documentation must be written in English.
2. Code and code comments must be written in English.
3. Assistant replies to the user must be written in Russian.

## Canonical resource count

1. The game has exactly **13 runtime resources**.
2. The canonical split is:
   - **11 normal resources**
   - **2 special resources**: `meat` and `oil`
3. `Denarii` is a currency, not a resource.
4. `furniture` is not a game resource and must not be treated as one in code, UI, rewards, or documentation.

## Policy split (canonical)

Detailed rules are split into policy documents:

1. `docs/policies/AGENT_RULES.md`
2. `docs/policies/ENGINEERING_STANDARDS.md`
3. `docs/policies/DOCUMENTATION_POLICY.md`
4. `docs/policies/GDSCRIPT_WARNING_PREVENTION.md`
5. `docs/policies/REPORTING.md`

If any rule conflicts with older documents, these policy files are the source of truth.

## GDScript warning prevention (critical)

1. Yellow editor warnings are not acceptable background noise; prevent them while editing, not after the fact.
2. Before code changes, read `docs/policies/GDSCRIPT_WARNING_PREVENTION.md`.
3. Common forbidden patterns include:
   - shadowing global `class_name` identifiers
   - shadowing base-class properties like `owner`
   - unused parameters/locals/fields/signals left behind after refactors
   - enum assignments from raw integers without proper casts
   - typed ternary expressions with incompatible branches
   - implicit integer division or coercion where a float result is intended
4. If a script keeps accumulating warnings, treat that as a design smell and split responsibilities instead of stacking more local fixes.

## Modularity and orchestration contract (critical)

1. Prefer `.tscn`-first composition over code-built hierarchies whenever the scene can be authored in the editor.
2. Prefer small focused scripts and helper modules over large monolithic controllers.
3. Root or feature-entry scripts must act primarily as orchestrators:
   - wire dependencies
   - coordinate signals/state
   - delegate concrete behavior to child nodes, modules, or resources
4. Do not centralize unrelated behavior into one script just because it is convenient during the current task.
5. When a feature touches UI, scene structure, and logic together, keep visual ownership in `.tscn`, behavior in focused scripts, and cross-system flow in an orchestrator.
6. This rule applies especially to `GameScene`, `MainUI`, artifact/runtime managers, and CharacterCreation flows.
7. When modularity conflicts with "just append quickly," modularity wins.

## Architecture discipline (critical)

### Monolith watchlist

The following files require special discipline — no new feature logic may be appended without first attempting to extract a module:

- `scripts/game/GameScene.gd`
- `scripts/map/MapSlot.gd`
- `scripts/game_scene/GameSceneWaves.gd`
- `core/town_core.gd`
- `core/hero_core.gd`
- `scripts/mob/Mob.gd`
- `scripts/hero/HeroOnField.gd`
- `scripts/hero/types/SmallBones.gd`
- `scripts/game_scene/GameSceneSpells.gd`
- `core/buildings/BuildingRegistry.gd`

Rules for watchlist files:

1. Do not add new feature logic without first attempting to extract a module.
2. Allowed contents: wiring, delegation, wrappers, compatible entry points, exported values, node references, signal connections.
3. New internal logic must go into separate focused files.

### Mandatory extraction policy

1. If a task touches a known monolithic file, find an extraction seam first, then add the new mechanic.
2. Default rule: **extract first, extend second**.
3. If backward compatibility is required, the old public method stays as a thin wrapper while the implementation moves to a separate module.
4. If a file is already overloaded, adding a new mechanic without prior module extraction is forbidden.
5. Small changes that increase responsibility mixing still require a small extraction first.
6. "It's faster" or "it's temporary" do not justify growing a monolith.

### Required module naming patterns

Preferred naming conventions for extracted modules:

- `*Controller` — UI flow / interaction flow
- `*Service` — narrow applied operation or orchestration helper
- `*Runtime` — runtime state / persistence bridge
- `*Flow` — setup / clear / apply / remove lifecycle flows
- `*Presenter` / `*UI` — display and visual state
- `*Tracker` — observation and derived state
- `*Builder` — payload / data / result structure assembly
- `*Query` / `*Bridge` — cross-system lookups and adapters

### AI-first development rules

This project is developed primarily through AI agents, so modularity is not optional best practice — it is a mandatory condition for stable development.

For AI-driven changes, **required:**

1. Always look for the narrowest seam to insert new logic.
2. Extract feature logic into a separate file with one responsibility.
3. Keep only wiring, delegation, wrappers, and state references in root scripts.
4. Do not mix multiple independent mechanic flows in one new file.

For AI-driven changes, **forbidden:**

1. Adding new feature logic to a monolith watchlist file without an extraction attempt.
2. Creating new god-objects "for the future."
3. Putting unrelated behavior into one helper just because they belong to the same scene.
4. Using a root/autoload file as a place for a quick temporary solution.

### AI batching rule

1. If architectural work has started on a subsystem, continue extraction in batches rather than stopping after each small helper file.
2. Normal mode for large architectural tasks: one batch = several related extraction steps + a single regression suite at the end.
3. Stop between steps only if an architectural conflict is found, a shared contract is broken, or an explicit user decision is needed.

### New feature insertion rule

1. Any new gameplay mechanic must first be classified by responsibility: combat/runtime, UI flow, persistence/save-load, state transition/lifecycle, visual presentation, reward/build/result assembly.
2. After classification, the mechanic goes into the matching narrow module, not into the subsystem's general root script.

### Facade preservation rule

1. If a root script is already used by scenes, the inspector, signals, or other systems, its public methods should be preserved as compatibility wrappers when possible.
2. Extraction must not break scene contracts for the sake of architectural "beauty."
3. Delegation first, then optional API cleanup later if truly needed.

### Micro-module quality rule

1. A small module must be small by responsibility, not by file size.
2. Do not create a formal micro-module that internally carries multiple different flows.
3. A good helper answers one question: "what one thing does it do better than the root script?"

### Architecture drift prevention

1. After each major extraction batch, evaluate whether a new helper is itself turning into the next monolith.
2. If a helper quickly grows and mixes multiple mechanic flows, split it too rather than declaring it "the new logic center."
3. Moving a god-object from one file to another and calling it modularity is forbidden.

### Test requirement for refactors

1. Any extraction from a monolith must be accompanied by a regression test.
2. First the test captures current behavior, then the extraction is performed.
3. Modularity work is not considered complete without targeted tests on the extracted behavior.

### Planning requirement for watchlist files

1. If a task touches a file from the monolith watchlist, a brief plan is required before making changes:
   - what stays in the facade
   - what gets extracted
   - which public methods remain as wrappers
   - which tests confirm that behavior is not broken

### Architecture completion rule

Architectural work is NOT considered complete if:

1. The root script still received a new feature branch instead of delegation.
2. Extraction was done without regression tests.
3. Responsibilities became even more mixed.
4. Modularity was claimed but the implementation effectively remained inside the monolith.

## Orientation and canonical reading order

1. `docs/project_description.md` - current high-level requirements and operating directives.
2. `docs/README.md` - top-level index for the `docs/` folder.
3. `docs/WIKI_HOME.md` - documentation entrypoint.
4. `docs/PROJECT_NAVIGATOR.md` - fastest file lookup map.
5. `docs/ARCHITECTURE.md` - authoritative runtime composition and module boundaries.
6. Relevant focused docs that actually exist for the touched subsystem.
7. For CharacterCreation/start-flow tasks specifically:
   - `docs/PROJECT_NAVIGATOR.md`
   - `docs/ARCHITECTURE.md`
   - `docs/project_description.md`

## Animation asset policy (critical)

1. **Do not build SpriteFrames in code.** Every `AnimatedSprite2D` / `AnimationSprite2D` must reference a SpriteFrames resource defined directly in the scene (or a `.tres` explicitly authored in the project). Runtime generation from filesystem folders is banned.
2. **No runtime asset crawling.** Loading textures/frames from repository folders (e.g. iterating PNG files at startup) to assemble animations is forbidden. All frames must be assigned in the editor.
3. **Node-based requirement.** Animations must be authored as nodes/resources in the scene tree. Any new enemy/boss/hero must expose its animation clips through editor-authored SpriteFrames, never via programmatic imports.

## Temporary asset intake policy (critical)

1. `res://assets/takefromthis/` is a temporary intake/storage folder only. It must not be used as a direct runtime asset source in scenes, scripts, or resources.
2. If an asset from `takefromthis` is needed, move or copy it first into a logical destination folder that matches its system ownership (for example character creation UI assets into `res://assets/Characher_Creation/`, unit art into unit/character folders, etc.).
3. After relocation, update scene/script references to the logical destination path and keep `takefromthis` clean of adopted runtime assets.
4. Reused visuals taken from unrelated feature folders (for example `options/`) should also be copied into the owning feature folder when they become part of a new permanent UI flow.
5. When a task description or provided content contains obvious spelling/syntax mistakes, normalize the text before transcribing it into project-facing labels/data/documentation, while preserving the intended meaning.

## Binary asset relocation workflow (critical)

1. Before planning UI/runtime integration, determine whether required assets are binary files that cannot be relocated with text patch tools.
2. If a task depends on moving/copying binary assets, treat the relocation as a separate prerequisite step and surface it early.
3. When relocation requires a terminal/file command approval, request it once with the smallest possible command and do not block all other implementation on that approval.
4. If the command is rejected, cancelled, or unavailable, do not retry blindly and do not stall on the transfer. Continue with unrelated code work and leave only the asset hookup pending.
5. If a safe in-project fallback visual already exists, prefer using that temporary fallback over repeatedly attempting blocked transfers.
6. Never reference `takefromthis` directly at runtime just because relocation was blocked; unresolved relocation must remain explicit.

## Mandatory documentation update rule

1. If you add a feature, change a mechanic, modify flow/timing, or change architecture, you must update documentation in the same task.
2. When new mechanics or scripts are added to the project, **all relevant documentation branches must be updated**: focused subsystem docs, architecture references, navigator, and wiki entries if applicable.
3. Do not assume documentation will be updated later; treat it as part of the task delivery.

At minimum:

1. Update `docs/PROJECT_NAVIGATOR.md`.
2. Update `docs/ARCHITECTURE.md`.
3. Update the focused existing doc(s) that cover the touched subsystem.

Final response requirement:

1. Explicitly state which documentation files were updated.
2. Use the report format specified in `docs/policies/REPORTING.md` to communicate completion.

## Documentation and project reference rules

1. **"правила проекта", "проект", and "доки" clarification**: These terms always refer to the agent instruction documents in this repository: `AGENTS.md` and all child policy documents listed in the "Policy split (canonical)" section. When a task description or feedback mentions "project rules," "project docs," or similar, it refers exclusively to these authoritative documents.
2. **Debug keybinding documentation requirement**: All new debug keybinds added to the project MUST be documented in the F10 debug menu with clear descriptions of what they do. This applies to new Q/R/T keys or any future debug input handlers added to `GameSceneDebug.gd` or similar debug modules.
3. **Indentation consistency requirement**: Before marking a task as complete and submitting a final report, verify that all modified files have consistent indentation (either all tabs or all spaces, not mixed). This includes newly created files and existing files that were edited. Document this check in the final report.
4. **Obvious architectural choices**: Do not ask for clarification on obvious architectural decisions. If a suggested approach conflicts with documented architecture standards, technical best practices, or the established patterns in the codebase, and alternative options are clearly wrong/illogical/against standards, proceed with the recommended approach without asking for confirmation.

## Hero scene architecture (strict)

1. Canonical rule: one hero/unit id must resolve to one dedicated entry scene file.
2. Canonical entry path format: `res://scenes/heroes/<unit_id>.tscn`.
3. Canonical resolver: `res://scripts/hero/HeroSceneRegistry.gd`.
4. Do not add new branch-based scene routing (for example `if id.begins_with(...)`) in runtime/debug code.
5. Legacy/alias compatibility must be handled in the registry resolver, not spread across scene-spawn call sites.
6. Hero entry/base scene animation contract: use exactly two animation nodes `AnimWalk` and `AnimAttack` (`AnimatedSprite2D`) for combat animation flow.
7. For hero entry/base scenes, single-node `AnimationSprite2D`-only setup is non-canonical.
8. Hero scenes under `res://scenes/heroes/` must be fully local scenes (no inherited/instanced wrapper roots).
9. Do not keep editor-yellow inherited nodes in hero scenes; all hero nodes must be directly editable in the scene.
10. If common behavior is needed, reuse scripts/components, not scene inheritance for hero entry scenes.

## Context7 validation policy

1. Use Context7 when documenting or validating external APIs (for example Godot 4.3 API signatures and node methods).
2. If Context7 is unavailable in the current environment, explicitly mark it as unavailable and perform a local-source fallback review.
3. Never claim external API compliance without evidence from Context7 or clearly documented fallback evidence.

## Recommended GDScript Patterns

Agents should apply these standard Godot patterns to ensure consistency:

1.  **State Machine**: Use for complex entity logic (e.g., Player, Enemies).
    -   *Implementation*: A `StateMachine` node with `State` children.
    -   *Benefit*: Decouples states, easier to maintain than `enum` + `match`.

2.  **Autoload Singletons**: Use for global managers (GameManager, EventBus).
    -   *Implementation*: `extends Node`, added to Project Settings > Autoload.
    -   *Benefit*: Accessible globally, persistent across scenes.

3.  **Resource-based Data**: Use for static data (Stats, Items, Weapons).
    -   *Implementation*: `class_name MyData extends Resource`.
    -   *Benefit*: Editable in Inspector, reusable, serializable.

4.  **Object Pooling**: Use for frequent spawns (Projectiles, Particles).
    -   *Implementation*: Pre-instantiate nodes, toggle `process_mode` and `visible`.
    -   *Benefit*: Eliminates instantiation/GC lag.

5.  **Component System**: Use for shared behavior (Health, Hitbox).
    -   *Implementation*: specialized `Node` or `Area2D` scripts added as children.
    -   *Benefit*: Composition over inheritance, modularity.

6.  **Scene Management**: Use a central manager for transitions.
    -   *Implementation*: Autoload `SceneManager` with async loading.
    -   *Benefit*: Smooth transitions, loading screens.

7.  **Signal Bus**: Use for decoupled communication.
    -   *Implementation*: Autoload `EventBus` with signals.
    -   *Benefit*: Nodes communicate without knowing about each other.

## Windows `run_command` / terminal spam troubleshooting

If the agent starts spawning an interactive `cmd.exe` / PowerShell banner, times out, or repeats the same command in a loop, treat this as an environment/runner issue (not a project bug).

Checklist:

1. Stop issuing more terminal commands immediately (do not retry blindly).
2. Avoid commands that open interactive shells or keep stdin open.
3. Prefer direct file edits (patches) for code changes; only verify via a single explicit command after edits.
4. When running a command, always run a single non-interactive command (no chained shell sessions).
5. If the terminal shows a banner (e.g. Windows copyright text) for `cmd.exe`, the runner likely launched a shell instead of a one-shot command.

Mitigation:

1. Restart the IDE terminal (or kill the stuck shell process) to clear the interactive session.
2. Re-run verification using a single short command (one invocation) instead of multiple rapid retries.
3. If the problem persists, temporarily disable terminal execution and proceed with file-based changes + manual verification inside Godot.

