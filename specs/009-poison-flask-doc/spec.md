# Feature Specification: Poison Flask Weapon Documentation

**Feature Branch**: `009-poison-flask-doc`  
**Created**: 2024-12-28  
**Status**: Draft  
**Input**: User description: "фласка док нужно определить как полностью работает создадим док закрыть все не понима"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Complete Understanding of Poison Flask Mechanics (Priority: P1)

As a developer or game designer working with the Poison Flask weapon, I need complete documentation that explains every aspect of how it works so I can understand its mechanics, configuration, tome interactions, lifecycle, and debugging without ambiguity or missing information.

**Why this priority**: Poison Flask has complex mechanics (arc trajectory, poison cloud, DOT damage) that need clear documentation. Missing or unclear documentation leads to incorrect assumptions, bugs, and wasted development time.

**Independent Test**: Can be fully tested by verifying that the documentation covers all aspects: baseline parameters, trajectory calculation, explosion mechanics, poison cloud creation, DOT application, tome interactions, file structure, lifecycle, and debug logging. Documentation should be complete enough that a developer can implement or modify Poison Flask behavior without consulting code.

**Acceptance Scenarios**:

1. **Given** a developer wants to understand how Poison Flask selects targets, **When** they read the documentation, **Then** they find clear explanation of `_find_nearest_enemy()` logic and fallback behavior when no enemies are present
2. **Given** a developer wants to know how poison DOT works, **When** they read the documentation, **Then** they find complete details about damage calculation, tick interval, duration calculation, and how Pierce tome affects duration
3. **Given** a developer needs to debug Poison Flask behavior, **When** they check the documentation, **Then** they find all expected debug markers and how to enable logging

---

### User Story 2 - Understand Poison Flask Tome Interactions (Priority: P1)

As a game designer or developer, I need to understand how tomes interact with Poison Flask so I can balance gameplay and ensure correct tome effect application.

**Why this priority**: Poison Flask has a special interaction where Pierce tome converts to poison duration bonus. This must be clearly documented to prevent confusion and ensure correct behavior.

**Independent Test**: Can be fully tested by verifying that documentation explicitly explains:
- Which tomes apply to Poison Flask
- How Pierce tome converts to `_poison_duration_bonus` (0.5 seconds per stack)
- How other tomes (Size, Count, Damage, Duration, etc.) affect Poison Flask
- Whether any special adapters are used (currently none - uses DEFAULT behavior)

**Acceptance Scenarios**:

1. **Given** a designer wants to know how Pierce tome affects Poison Flask, **When** they check documentation, **Then** they find formula: `_poison_duration_bonus = pierce_add` (1 полная итерация за стак) and understand it's applied in `setup()`
2. **Given** a developer implements a new tome, **When** they check Poison Flask documentation, **Then** they can determine if/how the new tome should interact with Poison Flask
3. **Given** documentation exists for Poison Flask tome interactions, **When** reviewed against code, **Then** all documented interactions match actual implementation

---

### User Story 3 - Document Poison Flask Lifecycle and States (Priority: P1)

As a developer debugging or modifying Poison Flask, I need complete documentation of its lifecycle (spawn, flight, explosion, cloud, cleanup) and state transitions so I can understand when and why things happen.

**Why this priority**: Poison Flask has multiple distinct phases (flight arc, explosion, cloud creation, DOT application, cleanup) that must be clearly documented. Missing lifecycle documentation leads to bugs when modifying behavior.

**Independent Test**: Can be fully tested by verifying that documentation covers:
- Spawn conditions and setup process
- Flight arc trajectory calculation (`_physics_process()`)
- Explosion trigger and `_explode()` behavior
- Poison cloud creation and `_create_poison_cloud()` logic
- DOT application cycle (`_check_poison_application()`)
- Cleanup conditions and `cleanup_poison_cloud()` timing

**Acceptance Scenarios**:

1. **Given** a developer wants to modify poison cloud duration, **When** they check documentation, **Then** they find where `poison_cloud_duration_sec` is used and how it affects cleanup timing
2. **Given** a developer encounters a bug where poison doesn't apply, **When** they check lifecycle documentation, **Then** they can trace through setup → explosion → cloud → DOT application to find the issue
3. **Given** documentation exists for Poison Flask lifecycle, **When** reviewed, **Then** all state transitions and conditions are clearly explained

---

### Edge Cases

- What happens when no enemies are present during setup? (Fallback: use aim direction)
- What if the target enemy dies before the flask reaches it? (Flask still travels to last known position)
- How does poison cloud handle overlapping enemies? (Applies poison to all overlapping every 1 second)
- What happens if poison cloud lifetime expires while DOT is still active? (Cloud disappears, but DOT continues on enemies if they have `apply_status_poison`)
- What if Size tome is applied? (Affects cloud area via `_size_scale`, but calculation differs: `1.0 + (size_scale - 1.0) * 0.5`)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Documentation MUST explain Poison Flask baseline parameters (damage, cooldown, speed, arc height, DOT damage, DOT duration, cloud duration)
- **FR-002**: Documentation MUST explain target selection logic (`_find_nearest_enemy()`) and fallback behavior when no enemies are present
- **FR-003**: Documentation MUST explain trajectory calculation (parabolic arc using `sin(t * PI) * arc_height`)
- **FR-004**: Documentation MUST explain explosion trigger condition (`t >= 1.0` in `_physics_process()`)
- **FR-005**: Documentation MUST explain poison cloud creation process and collision setup
- **FR-006**: Documentation MUST explain DOT application logic (`_check_poison_application()`) including tick interval and recursive timing
- **FR-007**: Documentation MUST explain cleanup conditions (cloud lifetime expires via `_schedule_cleanup()`)
- **FR-008**: Documentation MUST document Pierce tome → poison duration bonus conversion (Pierce tome увеличивает длительность яда на 1 итерацию за стак, то есть `pierce_add` добавляет `pierce_add` итераций к базовым 4). Формула: `_poison_duration_bonus = float(pierce_add)` (не 0.5 * pierce_add)
- **FR-009**: Documentation MUST document all tome interactions (Size, Count, Damage, Pierce, Duration, Crit, etc.)
  - **Size tome**: Увеличивает область взрыва (облако яда), которая заражает мобов, а не саму фласку, которая летит. Формула: `_size_scale = 1.0 + (max(0.0, size_scale - 1.0) * 0.5)`
  - **Count tome**: Работает по дефолту на фласку (увеличивает количество фласок)
  - **Pierce tome**: Работает по специальному методу - увеличивает длительность тика яда на мобе на 1 раз (1 полная итерация за стак). Формула: `_poison_duration_bonus = float(pierce_add)` (добавляет `pierce_add` итераций к базовым 4)
- **FR-010**: Documentation MUST document that default poison mechanics: 4 итерации при базовой длительности 4.0 секунды и интервале 1.0 секунда. **Note**: Требуется изменение в `PoisonflaskNormalized.tres`: `poison_dot_duration_sec = 4.0` (сейчас 5.0)
- **FR-011**: Documentation MUST document file structure (PoisonflaskProjectile.gd, PoisonflaskProjectile.tscn, Poisonflask.tres, PoisonflaskNormalized.tres)
- **FR-012**: Documentation MUST document animation states (object, explosion, damagearea)
- **FR-013**: Documentation MUST document collision layer/mask setup and changes during lifecycle
- **FR-014**: Documentation MUST document debug logging markers and how to enable them
- **FR-015**: Documentation MUST explain why `_on_area_hit()` and `_on_body_hit()` are empty (collisions disabled during flight)
- **FR-016**: Documentation MUST follow standard weapon documentation template from `specs/006-weapon-docs/templates/weapon-doc-template.md`

### Non-Functional Requirements

- **NFR-001**: Documentation MUST be complete enough that a developer can understand Poison Flask without reading code
- **NFR-002**: Documentation MUST use verification status markers ([ПРОВЕРЕНО], [ТРЕБУЕТ ПРОВЕРКИ], [БАГ], [НЕИЗВЕСТНО]) for untested sections
- **NFR-003**: Documentation MUST be written in Russian (following project documentation standards)
- **NFR-004**: Documentation MUST include code references (file paths, line numbers where applicable)
- **NFR-005**: Documentation MUST validate all Godot 4.3 API references are correct

## Key Entities

### Poison Flask Projectile

**Class**: `PoisonflaskProjectile` extends `Area2D`  
**Location**: `gameplay/weapons/PoisonflaskProjectile.gd`

**Key Variables**:
- `damage: int` - Initial damage value from WeaponConfig
- `_from: Node` - Owner/source of the projectile
- `_config: NormalizedProjectileConfig` - Behavior configuration
- `_target: Node` - Target enemy (may be null)
- `_start_pos: Vector2` - Spawn position
- `_target_pos: Vector2` - Target position
- `_travel_time: float` - Current travel time
- `_total_travel_time: float` - Total flight time
- `_has_exploded: bool` - Whether explosion has occurred
- `_size_scale: float` - Size scaling for cloud area
- `_poison_duration_bonus: float` - Bonus duration from Pierce tome

**Key Methods**:
- `setup()` - Initialization with WeaponConfig and tome mods
- `_find_nearest_enemy()` - Target selection logic
- `_physics_process()` - Flight arc calculation and explosion trigger
- `_explode()` - Explosion animation and cloud creation trigger
- `_create_poison_cloud()` - Cloud setup and DOT cycle start
- `_check_poison_application()` - Apply poison DOT to overlapping enemies (recursive)
- `cleanup_poison_cloud()` - Cloud cleanup and despawn

### Poison Flask Configuration

**Resource**: `Poisonflask.tres` (WeaponConfig)  
**Behavior Resource**: `PoisonflaskNormalized.tres` (NormalizedProjectileConfig)

**Key Parameters**:
- `min_damage = 100`, `max_damage = 150` - Damage range
- `cooldown = 3.0` - Fire rate
- `speed = 100.0` - (Note: actual speed uses `poison_flask_speed_px_sec` from normalized config)
- `lifetime = 6.0` - Maximum lifetime
- `pierce_count = 1` - Base pierce
- `tome_behavior = 0` - DEFAULT (no special adapters)

**Normalized Config Parameters**:
- `poison_arc_height_px = 150.0` - Arc height for trajectory
- `poison_flask_speed_px_sec = 400.0` - Flight speed
- `poison_dot_damage = 2` - DOT damage per tick
- `poison_dot_duration_sec = 4.0` - Base DOT duration (4 итерации при интервале 1.0 секунда)
- `poison_cloud_duration_sec = 3.0` - Cloud lifetime
- `poison_tick_interval_sec = 1.0` - Time between DOT ticks

**Note**: Базовая длительность яда должна быть 4.0 секунды для 4 итераций (при интервале 1.0 секунда). Pierce tome добавляет дополнительные итерации: `total_iterations = 4 + pierce_add`.

**Changes Required**:
- `PoisonflaskNormalized.tres`: Изменить `poison_dot_duration_sec` с `5.0` на `4.0`
- `PoisonflaskProjectile.gd` (строка 49): Изменить формулу Pierce tome с `_poison_duration_bonus = 0.5 * float(max(0, tome_mods.pierce_add))` на `_poison_duration_bonus = float(max(0, tome_mods.pierce_add))`

## Technical Constraints

- **Godot Version**: 4.3 (all API references must be valid for this version)
- **Documentation Format**: Markdown following template from `specs/006-weapon-docs/templates/weapon-doc-template.md`
- **Language**: Russian (following project standards)
- **Location**: `specs/006-weapon-docs/guides/poison-flask.md` (integrated into existing weapon docs system)

## Success Criteria

- [ ] Complete documentation file created at `specs/006-weapon-docs/guides/poison-flask.md`
- [ ] All baseline parameters documented with verification status
- [ ] All tome interactions documented (especially Pierce → duration bonus)
- [ ] Complete lifecycle documented (spawn → flight → explosion → cloud → DOT → cleanup)
- [ ] File structure documented with all required files
- [ ] Debug logging documented with expected markers
- [ ] All Godot 4.3 API references validated
- [ ] Documentation added to `specs/006-weapon-docs/README.md` navigation
- [ ] All edge cases documented
- [ ] Verification status markers applied appropriately

## Clarifications

### Session 2024-12-28

- Q: Size Scale Calculation - Why is `_size_scale = 1.0 + (max(0.0, size_scale - 1.0) * 0.5)` used instead of direct `size_scale`? → A: Size tome должен увеличивать область взрыва (облако яда), которая заражает мобов, а не саму фласку, которая летит. Формула применяется только к облаку.
- Q: Count tome behavior → A: Count tome работает по дефолту на фласку (увеличивает количество фласок).
- Q: Pierce tome behavior → A: Pierce tome работает по специальному методу - увеличивает длительность тика яда на мобе на 1 раз (1 итерация за стак).
- Q: Default poison mechanics → A: На дефолте фласка при заражении делает 4 итерации (базовая длительность должна быть 4.0 секунды при интервале 1.0 секунда).

## Open Questions / Clarifications Needed

1. **DOT vs Direct Damage**: When does poison cloud apply `apply_status_poison()` vs `apply_damage()`? Is this based on enemy type capabilities?
2. **Cloud Collision Area**: How is the collision area calculated? Is it based on `CollisionShape2D` in the scene scaled by `_size_scale`?
3. **Animation Timing**: What is the duration of "explosion" animation before switching to "damagearea"? Is this tied to cloud creation?
4. **Missing Debug Logs**: Should documentation recommend adding debug logs for `_explode()`, `_create_poison_cloud()`, and `_check_poison_application()` since they currently lack logging?

