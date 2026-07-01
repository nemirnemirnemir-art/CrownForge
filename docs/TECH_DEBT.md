# Tech Debt

Evidence-first list from current code/resources. If a relation is not strictly confirmed, mark it as probable.

---

## 1) `res://core/castle_core.gd` calls missing API

- Category: bug / tight coupling
- Fact: `CastleCore.reset_game()` calls `EconomyCore.set_gold(0)`.
- Issue: `set_gold()` is not present in `res://core/economy_core.gd`.
- Risk: possible runtime error when `reset_game()` is executed.
- Confidence: high
- Suggested fix: replace with existing economy API or add a safe explicit reset method in `EconomyCore`.

---

## 2) Duplicate passive meat production systems

- Category: overgrown / possible duplicate
- Fact: both `HuntingCore` (`res://core/hunting_core.gd`) and `MeatProductionCore` (`res://core/meat_production_core.gd`) add `meat` to `ResourceCore`.
- Issue: both are autoloaded and both use `_process()`, which can create overlap.
- Confidence: medium
- Suggested fix: keep one implementation or make one a thin wrapper around the other.

---

## 3) Tree lookup logic is duplicated

- Category: overgrown
- Fact:
  - `scripts/game_scene/GameSceneSpells.gd` finds trees by group `trees` with fallback `_find_all_trees_by_name()` using `Tree_`.
  - `scripts/TreeCollisionSetup.gd` also finds trees by recursive `Tree_` name search.
- Issue: duplicated lookup contract increases fragility.
- Confidence: medium
- Suggested fix: enforce one tree-discovery contract (group-based or centralized service).

---

## 4) `DamagePopupPool` container lifecycle tied to `current_scene`

- Category: tight coupling
- Fact: `DamagePopupPool._ensure_container()` attaches `DamagePopupContainer` to `get_tree().current_scene`.
- Issue: container recreation is needed when scene lifecycle changes.
- Confidence: medium
- Suggested fix: if instability appears, move popup container to dedicated `CanvasLayer`/UI root.

