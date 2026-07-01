# Implementation Tasks: Панель героев (Hero Bar + Hero Card UI)

**Feature**: 013-hero-bar-ui  
**Branch**: `013-hero-bar-ui`  
**Created**: 2025-01-XX  
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Overview

This feature implements UI panels for hero management: bottom hero bar (Hero Bar) with 20 slots and hero card (Hero Card) on the right bottom. Extends HeroCore with XP system, death flags, and squad management (up to 6 heroes).

**Total Tasks**: 42  
**Scope**: All tasks (complete UI implementation)

---

## Dependencies

### Implementation Order

1. **HeroCore Extension** → **No dependencies** (extends existing HeroCore)
2. **Save/Load Integration** → **Depends on**: HeroCore Extension
3. **HeroBar UI** → **Depends on**: HeroCore Extension
4. **HeroCard UI** → **Depends on**: HeroCore Extension
5. **GameScene Integration** → **Depends on**: HeroBar, HeroCard
6. **Assets & Sprites** → **Can be done in parallel** with UI implementation
7. **Testing** → **Depends on**: All previous phases

### Parallel Execution Opportunities

- **Assets & Sprites** can be prepared in parallel with Phase 1-2 (no dependencies)
- **HeroCard** can be created in parallel with HeroBar (different scenes, both depend on HeroCore)

---

## Phase 1: Расширение HeroCore

**Goal**: Add XP, death, and squad management to HeroCore

**Independent Test**: HeroCore methods work correctly, new fields are initialized

- [X] **T001** Add new fields to hero structure in `createHero()`:
  - `xp: int = 0`
  - `xp_to_next: int = 5`
  - `is_dead: bool = false`
  - `is_removed: bool = false`

- [X] **T002** Add `active_hero_ids: Array[String] = []` variable to HeroCore

- [X] **T003** Implement `set_hero_active(hero_id: String, active: bool) -> bool`:
  - Check hero exists and not dead (if active == true)
  - If active == true and 6 heroes already selected — return false
  - Add/remove hero_id from active_hero_ids
  - Return true on success

- [X] **T004** Implement `is_hero_active(hero_id: String) -> bool`

- [X] **T005** Implement `get_active_heroes() -> Array[Dictionary]`

- [X] **T006** Implement `add_xp_to_hero(hero_id: String, xp_amount: int) -> void`:
  - Increase xp
  - Auto-levelup if xp >= xp_to_next
  - Randomly increase hp or damage
  - Update xp and xp_to_next

- [X] **T007** Implement `set_hero_dead(hero_id: String, is_dead: bool) -> void`:
  - Set is_dead flag
  - Auto-remove from active_hero_ids if is_dead == true

- [X] **T008** Implement `remove_hero(hero_id: String) -> void`:
  - Set is_removed = true
  - Remove from active_hero_ids

- [X] **T009** Update `getAllHeroes()` to filter by `is_removed` (optional parameter)

- [ ] **T010** Test Phase 1: Create hero, select 6 heroes, add XP, set death

---

## Phase 2: Интеграция с системой сохранений

**Goal**: Save and load new hero fields and squad state

**Independent Test**: Save/load preserves all new data correctly

- [X] **T011** Update `GameManager.save_game()`:
  - Save `active_hero_ids` from HeroCore
  - Save new hero fields: `xp`, `xp_to_next`, `is_dead`, `is_removed`

- [X] **T012** Update `GameManager.load_game()`:
  - Load `active_hero_ids` to HeroCore
  - Load new hero fields with defaults if missing
  - Filter heroes with `is_removed == true` for display

- [X] **T013** Update `GameManager.prestige()` and `reset_progress()`:
  - Clear `active_hero_ids`
  - Reset or remove all heroes

- [X] **T014** Test Phase 2: Save/load with heroes, squad, XP, death

---

## Phase 3: Создание HeroBar (нижняя панель)

**Goal**: Create bottom hero bar with 20 slots

**Independent Test**: HeroBar displays heroes correctly, handles clicks

- [X] **T015** Create scene `scenes/HeroBar.tscn`:
  - Control root node
  - Anchor to bottom (BOTTOM_WIDE)
  - GridContainer: 2 rows × 10 columns
  - 20 slots (Button or TextureRect) 50×50 each
  - 20 border nodes (ColorRect/Panel) for selection highlight

- [X] **T016** Create script `scripts/HeroBar.gd`:
  - `extends Control`
  - Variables: `@onready var slots: Array[Control] = []`
  - Variables: `@onready var slot_borders: Array[Control] = []`
  - Variables: `current_page: int = 0`, `heroes_per_page: int = 20`

- [X] **T017** Implement `_ready()`:
  - Get references to slots and borders
  - Connect click signals
  - Call `update_display()`

- [X] **T018** Implement `update_display() -> void`:
  - Get heroes from HeroCore (filter is_removed)
  - Sort by ID
  - Calculate current page
  - For each slot: show hero face, skull if dead, border if active

- [X] **T019** Implement `_on_slot_clicked(slot_index: int) -> void`:
  - Get hero for slot
  - If dead: call remove_hero(), update display, return
  - If alive: toggle active state via HeroCore.set_hero_active()
  - Emit signal `hero_selected(hero_id)`

- [X] **T020** Add signal `signal hero_selected(hero_id: String)`

- [X] **T021** Implement `_process()` or connect to HeroCore signals:
  - Periodically call `update_display()`

- [ ] **T022** Test Phase 3: Display heroes, select squad, handle dead heroes

---

## Phase 4: Создание HeroCard (карточка героя)

**Goal**: Create hero card on right bottom with detailed info

**Independent Test**: HeroCard displays hero info correctly, updates on selection

- [X] **T023** Create scene `scenes/HeroCard.tscn`:
  - Control root node
  - Anchor to bottom-right
  - Left: Panel with AnimatedSprite2D (walk animation)
  - Top-right: Label with hero name (blue background)
  - Middle-right: VBoxContainer with stats (red background)
  - Bottom: HBoxContainer with 4 buttons (yellow blocks)

- [X] **T024** Create script `scripts/HeroCard.gd`:
  - `extends Control`
  - Variables: `@onready var hero_name_label: Label`
  - Variables: `@onready var hp_label: Label`, `damage_label`, `level_label`, `xp_label`
  - Variables: `@onready var hero_animation: AnimatedSprite2D`
  - Variables: `@onready var button_1: Button`, `button_2`, `button_3`, `button_4`
  - Variables: `current_hero_id: String = ""`

- [X] **T025** Implement `_ready()`:
  - Get references to UI elements
  - Connect button signals
  - Connect `hero_selected` signal from HeroBar

- [X] **T026** Implement `show_hero(hero_id: String) -> void`:
  - Get hero from HeroCore
  - Skip if not found, is_removed, or is_dead
  - Update all labels with hero data
  - Update animation sprite and play "walk"

- [X] **T027** Implement `update_display() -> void`:
  - Call `show_hero(current_hero_id)` if current_hero_id not empty

- [X] **T028** Implement `_on_hero_selected(hero_id: String) -> void`:
  - Call `show_hero(hero_id)`

- [X] **T029** Implement placeholder button handlers:
  - `_on_button_1_pressed()`: print placeholder message
  - `_on_button_2_pressed()`: print placeholder message
  - `_on_button_3_pressed()`: print placeholder message
  - `_on_button_4_pressed()`: print placeholder message

- [X] **T030** Implement `_process()` or connect to HeroCore signals:
  - Periodically call `update_display()`

- [ ] **T031** Test Phase 4: Display hero card, update on selection, show stats

---

## Phase 5: Интеграция с GameScene

**Goal**: Add HeroBar and HeroCard to main game scene

**Independent Test**: Panels appear correctly, don't overlap other UI

- [X] **T032** Update `scenes/GameScene.tscn`:
  - Add HeroBar as child (bottom)
  - Add HeroCard as child (bottom-right)
  - Ensure no overlap with other UI

- [X] **T033** Update `scripts/GameScene.gd` (if needed):
  - Ensure HeroBar and HeroCard initialize after HeroCore
  - Connect `hero_selected` signal from HeroBar to HeroCard

- [ ] **T034** Test Phase 5: Panels appear, no overlap, signals work

---

## Phase 6: Загрузка спрайтов и иконок

**Goal**: Prepare sprites for hero faces, skull, and walk animation

**Independent Test**: All sprites display correctly

- [ ] **T035** Check/create hero face sprites:
  - Check sprites for iconId: "swordsman", "archer", "warrior_woman"
  - Create placeholder sprites if missing

- [ ] **T036** Create/find skull icon:
  - Create simple skull icon 50×50 (or scale)

- [ ] **T037** Check/create walk animation:
  - Check AnimatedSprite2D with "walk" animation for each iconId
  - Create placeholder animation or use static sprite

- [ ] **T038** Configure resources in HeroBar and HeroCard:
  - Load face sprites by iconId
  - Load skull icon
  - Configure AnimatedSprite2D for walk animation

- [ ] **T039** Test Phase 6: All sprites display, skull shows for dead, animation plays

---

## Phase 7: Финальная проверка и тестирование

**Goal**: Ensure all functions work correctly

**Independent Test**: All test scenarios from spec.md pass

- [ ] **T040** Test hero display:
  - 0 heroes — empty panel
  - 1-20 heroes — all display
  - 25+ heroes — pagination structure works

- [ ] **T041** Test squad selection:
  - Select 6 heroes — red borders appear
  - Try 7th — silent ignore
  - Deselect — border disappears

- [ ] **T042** Test hero card:
  - Click hero — card updates
  - All stats correct
  - Walk animation plays

- [ ] **T043** Test dead heroes:
  - Set is_dead = true — skull appears
  - Try to select dead — nothing happens
  - Click skull — slot clears

- [ ] **T044** Test XP and levelup:
  - Add 5 XP — level increases
  - Check random HP or Damage increase
  - Check XP update in card

- [ ] **T045** Test save/load:
  - Create heroes, select squad, add XP
  - Save, restart
  - Verify all data restored

- [ ] **T046** Test performance:
  - UI updates smoothly
  - Clicks process instantly (< 100ms)

---

## Summary

**Total Tasks**: 46  
**Phases**: 7  
**Estimated Complexity**: Medium

**Critical Path**: Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 7

**Parallel Work**: Phase 6 can be done in parallel with Phase 1-4

---

**Last Updated**: 2025-01-XX

