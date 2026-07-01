# New Hero Integration Checklist

Purpose: fast, repeatable checklist for adding a new hero without re-searching the codebase.

Use this when user asks to add a hero with new run/attack animations and face.

## 1) Decide canonical IDs first

- Canonical unit id: `snake_case`, e.g. `assassin`.
- If incoming asset names differ (example: `assasin`), keep aliases in UI mappings.

## 2) Add animation assets

- Put frames in folders:
  - `assets/tinyHeroes/<hero_folder>/run/1.png ... N.png`
  - `assets/tinyHeroes/<hero_folder>/attack/1.png ... N.png`
- Face portrait path:
  - `assets/tinyHeroes/heroes_faces/<face_name>.png`
- If the unit also has a placeholder image under `assets/characters/unit_placeholders/`, treat it as fallback-only. A valid animated scene or real direct animation folder must keep priority over the placeholder.

## 3) Create hero field scene (required)

- Create entry scene: `scenes/heroes/<unit_id>.tscn`
- Entry scene must be fully local/editable (no inherited wrapper root, no editor-yellow inherited nodes).
- Base script: `res://scripts/hero/HeroOnField.gd`
- Required nodes for animation/state machine flow:
  - `AnimWalk` (`AnimatedSprite2D`) with `walk` animation
  - `AnimAttack` (`AnimatedSprite2D`) with `attack` animation
  - Do not use single-node `AnimationSprite2D`-only layout for hero entry/base scenes
  - `HeroStateMachine` + states (`HeroIdleState`, `HeroMovingToCombatState`, `HeroMovingToPortalState`, `HeroReturningHomeState`, `HeroAttackingState`, `HeroSaveFromStackState`)
  - Combat areas: `AggroArea`, `Hurtbox`, `Hitbox`
  - `HealthBar`

## 4) Register scene in centralized registry (required)

- File: `scripts/hero/HeroSceneRegistry.gd`
- Ensure resolver normalizes aliases/clone suffixes to canonical `unit_id`.
- Ensure `res://scenes/heroes/<unit_id>.tscn` exists and resolves via registry.

## 5) Ensure hero template exists in HeroCore (required)

- File: `core/hero/HeroData.gd`
- Update fallback initialization lists:
  - `initialize_base_heroes()`
  - `ensure_default_heroes()`
- Add hero entry so `HeroCore.hire_hero_copy("<unit_id>")` works for buildings.

## 6) Unit config resource (required)

- File: `data/units/<unit_id>.tres`
- Must contain:
  - `unit_id`
  - `display_name`
  - `hp`, `dps`, `unit_classes`, `trait_description`

## 7) Link with producing building (required when hero comes from building)

- Building file example: `data/buildings/levy_barracks/<building>.tres`
- Set `produced_unit_id = "<unit_id>"`.

## 8) Wire face in all UI entry points (required)

1. `scripts/ui/components/HeroPortrait.gd`
   - Add export var for face texture.
   - Add `match` branch in `set_unit_portrait()` including aliases.
2. `scenes/ui/components/HeroPortrait.tscn`
   - Add `ext_resource` to face image.
   - Bind it to new exported property.
3. `scripts/ui/town/BarracksTroopMenu.gd`
   - Update `_FACE_NAME_ALIASES` if filename differs from unit id.
4. `scripts/utils/HeroAssetLoader.gd`
   - Add icon mapping in `MANUAL_ICON_OVERRIDES` (and alias if needed).

## 9) Optional but recommended wiring

- Debug spawn menu:
  - `scripts/ui/DebugSpawnMenu.gd`
  - Add/update icon in `HERO_ICONS` (scene list is built from registry automatically).

## 10) Fast verification checklist

- Scene exists: `scenes/heroes/<unit_id>.tscn`.
- Scene is fully local: no `instance=ExtResource(...)` in `scenes/heroes/<unit_id>.tscn`.
- `HeroSceneRegistry.gd` resolves this `unit_id`.
- `HeroData.gd` contains hero in both fallback lists.
- `data/units/<unit_id>.tres` exists.
- Building `produced_unit_id` points to this unit (if applicable).
- If a placeholder PNG also exists for this unit, confirm runtime still uses authored/directed animation frames instead of four identical placeholder frames.
- Face resolves in both:
  - `HeroPortrait.gd` / `HeroPortrait.tscn`
  - `BarracksTroopMenu.gd`

## 11) Minimal copy-paste TODO for future requests

1. Add assets (`run`, `attack`, `face`).
2. Create `scenes/heroes/<unit_id>.tscn` (entry scene).
3. Register/validate in `scripts/hero/HeroSceneRegistry.gd`.
4. Register in `core/hero/HeroData.gd`.
5. Add/update `data/units/<unit_id>.tres`.
6. Set building `produced_unit_id`.
7. Wire face in `HeroPortrait.gd` + `HeroPortrait.tscn` + `BarracksTroopMenu.gd`.
8. Add icon mapping in `scripts/utils/HeroAssetLoader.gd`.
9. (Optional) Add debug spawn entry.
