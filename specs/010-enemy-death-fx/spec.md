# Enemy Death FX v1 — Hybrid LOD + Pooling

## Goal

Implement a unified enemy death pipeline with hybrid LOD (near/far behavior) and pooling, so that:

- each enemy death feels readable and juicy near the player (dissolve / pixel-like effect);

- distant deaths are cheap and do not hurt performance;

- enemy objects and FX objects are reused via pools instead of constant free/instantiate.

## Context

- Engine: Godot 4.3, GDScript.

- There is already a damage/HP system for enemies and a central enemy management/spawn system.

- Current death behavior is simple: enemy disappears or plays a basic animation.

- The game can have dozens of enemies dying in a short time window, so performance matters.

We want to introduce a proper "death FX system" without changing the existing damage pipeline or external API for applying damage.

## In scope

- Define a single death flow for all enemies: HP <= 0 → death pipeline → FX → pooling.

- LOD-based behavior:

  - near player: full dissolve / pixel-like FX;

  - far from player: cheap fade-out or instant removal.

- Object pooling for enemies and (optionally) separate DeathFX nodes.

- Disabling enemy logic immediately on death (AI, movement, collisions, status effects).

## Out of scope

- Changing how damage is calculated (base damage, crit, modifiers).

- Changing spawn system logic (waves, timers).

- New enemy types or new gameplay mechanics.

- Player death FX.

## Requirements

### 1. Unified death pipeline

1. When an enemy's HP reaches 0:

   - Set enemy state to `EnemyState.DYING` (using enum `EnemyState` in `Enemy` class with values `ALIVE`, `DYING`, `DEAD`).

   - Immediately disable:

     - AI / movement controller;

     - attack/hitbox/hurtbox;

     - pathfinding / steering / flocking logic;

     - status effects ticking;

     - sprite animation (stop animation, reset frame to 0).

   - Mark enemy as logically dead (set state flag) so spawn/AI systems can check and skip this enemy:
     - Enemy spawner checks enemy state before counting toward `max_alive` limit
     - AI systems check enemy state before processing (enemy already in DYING state)
     - No explicit "inform" needed - state-based check is sufficient

2. Trigger existing death events (call Enemy methods directly, do not duplicate `_on_died()` logic):

   - loot drop logic (call `enemy._drop_experience()` if exists, handle coin drops via enemy's drop system);

   - XP / kill counters (call `ExperienceService.gain()` and `Statistics.add_kill()` via autoload services);

   - any existing on-death events (check for enemy signals or methods, but avoid calling full `_on_died()` to prevent duplication).

3. After death FX finishes (or timeouts), enemy object is:

   - either returned to the enemy pool;

   - or finally freed (if pooling is not available yet).

### 2. LOD behavior (near vs far)

1. LOD must be distance-based:

   - distance is measured from enemy to player position (`player.global_position`).

2. Define a configurable `NEAR_DEATH_RADIUS` (e.g. 400–600 px, exact value configurable in one place).

3. If enemy dies **within** `NEAR_DEATH_RADIUS`:

   - play **full "nice" death FX**: dissolve / pixel-like shader effect on the enemy sprite using `ShaderMaterial` with a uniform (e.g. `dissolve_progress`).

4. If enemy dies **outside** `NEAR_DEATH_RADIUS`:

   - use a **cheap** variant: fast alpha fade-out (0.1–0.2 sec) via Tween on enemy sprite `modulate.a`, then release to pool or `queue_free()`.

5. LOD decision must be made once per death event (no per-frame switching).

### 3. Visual FX behavior

For the "near" case:

1. Enemy sprite uses a **shared** `ShaderMaterial` with dissolve effect (uniform `dissolve_progress` or similar). The material is created once and reused by all enemies to minimize memory allocations and optimize performance during mass death scenarios.

2. FX duration should be short and predictable (e.g. 0.4–0.8 sec).

3. FX must not require per-frame heavy CPU logic:

   - use Tween to drive shader uniform (e.g. `dissolve_progress` from 0.0 to 1.0).

4. During FX:

   - enemy must not interact with collisions or AI;

   - only the visual part (sprite with shader) remains active.

### 4. Pooling

1. Enemy pooling is **optional in v1**:

   - Phase 1: Death FX and LOD can work with existing `queue_free()` approach.

   - Phase 2 (future): Introduce or reuse an enemy pool where enemies are not freed on death, but moved to an inactive pool and reused on spawn.

   - If pooling is implemented, all runtime state (HP, status effects, AI state, timers, shader uniforms) must be reset on reuse.

2. DeathFX pool is **not needed** (FX uses shader on enemy sprite, no separate nodes to pool).

3. Pool implementation details (if implemented) can be hidden behind a simple interface, for example:

   - `EnemyPool.spawn_enemy(type, position) -> enemy_instance`

   - `EnemyPool.release_enemy(enemy_instance)`

4. Death logic should call pool release instead of `queue_free()` if pooling is available, otherwise use `queue_free()`.

### 5. Performance / safety constraints

1. Death FX must scale to dozens of simultaneous deaths without noticeable FPS drops.

2. Avoid:

   - allocating new heavy resources on each death;

   - per-pixel CPU computations;

   - complex per-frame loops over all dying enemies.

3. All configurable constants (near radius, FX durations, fade speed, max active "nice" FX count) must be stored in a single autoload singleton `EnemyDeathConfig` with exported fields for centralized management and easy value changes without restart.

4. **Hard cap on simultaneous "nice" death FX is mandatory**:

   - Maximum active "nice" FX count (e.g. 30) must be enforced by `EnemyDeathController` tracking active FX list.

   - `EnemyDeathConfig` stores the limit constant (`max_active_nice_fx`), but `EnemyDeathController` manages the active FX tracking and enforces the limit before creating new FX.

   - If cap is exceeded, additional deaths use cheap variant (fast fade-out) instead of full dissolve FX.

   - This prevents FPS drops during mass death scenarios.

## Integration notes

- Reuse the existing event/hook where enemy HP reaches 0 (e.g. `EnemyHealth` component).

- Centralize death handling in one module/class (e.g. `EnemyDeathController` or inside `EnemyManager`) instead of duplicating death logic in each enemy script.

- Keep the interface for "apply damage to enemy" unchanged.

## Acceptance criteria

- Killing enemies near the player produces a visible dissolve/pixel-like or similar juicy FX.

- Killing enemies far from the player results in quick, cheap removal (instant or short fade), without visible stutter.

- When stress-testing (waves with many enemies dying per second), FPS remains stable and no GC spikes from constant `queue_free()/instantiate()` are observed.

- No regression in:

  - loot drops;

  - XP/kill counters;

  - enemy spawn limits.

## Clarifications

### Session 2025-01-27

- Q: Death FX implementation approach (shader vs separate node) → A: Shader-эффект dissolve на основном спрайте врага (ShaderMaterial с uniform) для минимального влияния на FPS (1 draw call, простой shader).
- Q: Distance measurement point for LOD (player vs camera) → A: Позиция игрока (`player.global_position`) для простоты и соответствия существующей логике в Enemy.gd.
- Q: Enemy pool requirement in v1 (mandatory vs optional) → A: Пул врагов опционален в v1 (можно начать с `queue_free()`, пул добавить позже). DeathFX pool не нужен (FX на спрайте врага).
- Q: Cheap variant behavior for far enemies (instant vs fade) → A: Быстрый alpha fade-out (0.1–0.2 сек) через Tween на `modulate.a` спрайта врага, затем освобождение.
- Q: Simultaneous "nice" FX cap requirement (mandatory vs optional) → A: Лимит обязателен (например, max 30 активных "nice" FX, остальные → cheap variant) для защиты от просадок FPS при массовых смертях.
- Q: Integration with existing Enemy death methods (direct call vs signals vs services) → A: Вызывать методы Enemy напрямую для loot/XP (например, `enemy._drop_experience()`), но не дублировать `_on_died()` логику. Использовать autoload сервисы (`ExperienceService.gain()`, `Statistics.add_kill()`) напрямую.

### Session 2025-01-18

- Q: Configuration storage location for death FX constants (NEAR_DEATH_RADIUS, FX durations, max active FX count) → A: Autoload singleton `EnemyDeathConfig` с экспортируемыми полями для централизованного управления и легкого изменения значений без перезапуска.
- Q: Enemy state model definition (DYING and other states) → A: Enum `EnemyState` в классе `Enemy` (например, `ALIVE`, `DYING`, `DEAD`) для оптимальной производительности (int под капотом, оптимизированный match) и читаемости кода, соответствует строгой типизации проекта.
- Q: ShaderMaterial sharing strategy for dissolve effect (shared vs per-enemy) → A: Shared ShaderMaterial (один материал создаётся один раз, используется всеми врагами) для минимизации выделений памяти и оптимальной производительности при массовых смертях.
- Q: Enemy animation behavior when transitioning to DYING state → A: Немедленно остановить и сбросить анимацию (`stop()`, `frame = 0`) для соответствия требованию "immediately disable", оптимальной производительности (нет обновления кадров анимации) и предсказуемого визуального эффекта (враг замирает и растворяется).
- Q: Active FX tracking for "nice" FX cap enforcement (controller vs config counter) → A: EnemyDeathController отслеживает список активных FX и проверяет лимит перед созданием нового. Логика управления в контроллере, EnemyDeathConfig только хранит константы (max_active_nice_fx), что упрощает тестирование и поддержку.

