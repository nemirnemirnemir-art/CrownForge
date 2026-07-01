# Project Description

This document is the authoritative, incrementally updated source of project-specific requirements. Always read the entire file before starting any task. If critical information is missing, stop and request clarification instead of guessing.

## Current Scope
- Implement ArtifactCore and ArtifactCatalog to manage artifact definitions, ownership, and activation.
- Integrate artifact effects with EventBus signals, building payments, and resource systems.
- Build the UI surface (debug grid, in-game panel, reward menu) for interacting with artifacts.

## Implemented Features
- **Morale System**: Global mechanic tracking morale from King stats, Wine stock, Unit Diversity, and Buildings (Arena, Concert).
    - Bonus: +0.5% Unit Damage per morale point.
    - Bonus: +0.25% Building Productivity per morale point.
    - Visuals: `MoraleTooltip` with dynamic icons and breakdown list.
    - Debug: +100 Morale button in DebugMenu.

## Core Philosophy
- Deliver clean, component-based, strictly typed systems that favor thin orchestrators and reusable scenes.
- Prefer composition over inheritance and keep systems modular through Autoloads where appropriate.

## Operational Directives

### 0. Zero-Tolerance for Hallucination & Data Synthesis
- Never guess technical data (HP, DPS, costs, paths, etc.) if it is not explicitly available.
- When data cannot be verified, clearly mark it as `[Blocked/Unknown]`.
- Accuracy has higher priority than completeness; reporting failure is acceptable, fabricating results is not.

### 1. Scene-First Instantiation
- Do not create visual or logical entities purely via code if they can be authored as `.tscn` scenes.
- Static UI must live directly in the relevant `.tscn` hierarchy so it is easy to tweak in the editor.
- Use `.instantiate()` for dynamic content only and expose visuals via `@export var texture: Texture2D`.
- Provide `@export` hooks for every dependency that designers might want to swap.

### 2. Thin Orchestrators & Components
- Root scripts only coordinate state, signals, and component wiring.
- Push concrete behavior into child nodes or resources to maintain single responsibility.
- Use composition to keep features reusable and avoid god-objects even within Autoloads.

### 3. Strict Coding Standards (Godot 4.3)
- Enforce static typing on variables, parameters, and return values.
- Follow Godot naming conventions (snake_case for members, PascalCase for classes).

### 4. Smart Debugging & Anti-Spam
- Provide debug prints for new mechanics and throttle recurring logs to once per second.
- Exceptions apply only when real-time tracking is explicitly required.

### 5. Architectural Quality Gate
- If the requested solution is a shortcut that harms architecture, warn the user and propose the correct approach.
- Implement the shortcut only if the user explicitly insists after the warning.

### 6. Signals & Communication
- Favor Signal Bus patterns or standard signals to decouple systems; avoid deep `get_parent()` chains.

### 7. Language, Indentation, and Formatting
- Use English for code, comments, and communication.
- Stick to Godot-default tabs for indentation and verify indentation after every edit.

### 8. Path Standardization
- Use forward slashes in paths and prefer the Latin name variant (`Maks`) to avoid encoding issues.

### 9. Mandatory Delivery Reporting
- When touching UI or scenes, summarize changes using the format `SceneName.tscn Created/Instanced into Parent.tscn`.

### 10. Asset Logistics
- Provide code-based placeholders (e.g., `GradientTexture2D`) and expose textures via exports so assets can be swapped in the editor.

### 11. Terminology Standards
- **Unit** = any combat entity (heroes + mobs). Apply shared mechanics to both unless stated otherwise.
- **Hero** = player-controlled units only.
- **Mob/Enemy** = hostile AI-controlled units.

### 12. Hero Scene Resolution Standard
- Each hero/unit id must resolve to its own entry scene file under `res://scenes/heroes/<unit_id>.tscn`.
- Use centralized scene resolution (`res://scripts/hero/HeroSceneRegistry.gd`) instead of scattered id-prefix branches.

### 13. External API Validation Standard
- For documentation claims about external APIs (including Godot 4.3 APIs), validate with Context7 when available.
- If Context7 is unavailable, document that limitation and use explicit local fallback evidence.

## Maintenance Notes
- Update this document whenever requirements, constraints, or architectural decisions change.
- Keep entries concise and specific so they are easy to review before each work session.
