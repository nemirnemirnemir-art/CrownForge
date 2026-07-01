extends CharacterBody2D
class_name HeroOnField

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")
const ArtifactSummonFlowScript := preload("res://core/artifacts/ArtifactSummonFlow.gd")
const HeroOnFieldRuntimeBridgeScript := preload("res://scripts/hero/modules/HeroOnFieldRuntimeBridge.gd")
const HeroOnFieldStatusEffectsScript := preload("res://scripts/hero/modules/HeroOnFieldStatusEffects.gd")
const HeroOnFieldCombatFacadeScript := preload("res://scripts/hero/modules/HeroOnFieldCombatFacade.gd")
const HeroOnFieldLifecycleScript := preload("res://scripts/hero/modules/HeroOnFieldLifecycle.gd")
const HeroOnFieldBoundsFlowScript := preload("res://scripts/hero/modules/HeroOnFieldBoundsFlow.gd")
const HeroOnFieldBootstrapScript := preload("res://scripts/hero/modules/HeroOnFieldBootstrap.gd")
const FriendlyDamageBlockHelperScript := preload("res://scripts/hero/shared/FriendlyDamageBlockHelper.gd")
const HeroSelectionOutlineScript := preload("res://scripts/hero/shared/HeroSelectionOutline.gd")
const HeroHurtboxUIScript := preload("res://scripts/hero/shared/HeroHurtboxUI.gd")
const HeroAnimationHelperScript := preload("res://scripts/hero/shared/HeroAnimationHelper.gd")

## Hero on the game field - Controller
## Coordinates the state machine and modules (Stats, Combat, Health, Animations)

# Helper Scripts (Components)
# We use class_name references for global classes:
# HeroOnFieldStats, HeroOnFieldDebug, HeroFieldAnimations, HeroOnFieldCombat, HeroOnFieldHealth

## Hero Data
var hero_id: String = ""
var is_debug_spawn: bool = false
var current_target: Node2D = null

var damage_taken_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0
var evasion_chance: float = 0.0
var is_invincible: bool = false
var is_temporary_summon: bool = false
var summon_unit_id: String = ""
var summon_duration: float = 0.0
var _summon_elapsed: float = 0.0
var _summon_max_hp: float = 1.0
var _summon_current_hp: float = 1.0
var _summon_damage: float = 1.0
var _temporary_summon_dead: bool = false

@export_group("Combat Stats")
@export var override_attack_range: float = -1.0
@export var override_projectile_speed: float = -1.0
@export var override_move_speed: float = -1.0
@export var override_projectile_type: String = ""
@export var default_projectile_scene: PackedScene = null

## Modules
var _stats: HeroOnFieldStats
var _animations: HeroFieldAnimations
var _combat_ai: HeroOnFieldCombatAI
var _health: HeroOnFieldHealth
var _debug: HeroOnFieldDebug
var _movement: HeroOnFieldMovement
var _visuals: HeroOnFieldVisuals
var _state_machine: HeroStateMachine
var _runtime_bridge: RefCounted
var _status_effects: RefCounted
var _combat_facade: RefCounted
var _lifecycle: RefCounted
var _bounds_flow: RefCounted
var _bootstrap: RefCounted
var _selection_outline_helper: RefCounted
var _hurtbox_ui_helper: RefCounted
var _animation_helper: RefCounted

## Movement (Delegated to HeroOnFieldMovement)
var move_speed: float:
    get: return _movement.move_speed if _movement else 37.5
    set(val): if _movement: _movement.move_speed = val
var stop_tolerance: float:
    get: return _movement.stop_tolerance if _movement else 10.0
    set(val): if _movement: _movement.stop_tolerance = val
var bridge_position: Vector2:
    get: return _movement.bridge_position if _movement else Vector2.ZERO
    set(val): if _movement: _movement.bridge_position = val
var is_returning: bool:
    get: return _movement.is_returning if _movement else false
    set(val): if _movement: _movement.is_returning = val
var patrol_center: Vector2:
    get: return _movement.patrol_center if _movement else Vector2.ZERO
    set(val): if _movement: _movement.patrol_center = val
var patrol_box_size: Vector2:
    get: return _movement.patrol_box_size if _movement else Vector2(150.0, 300.0)
    set(val): if _movement: _movement.patrol_box_size = val
var map_bounds: Rect2:
    get: return _movement.map_bounds if _movement else Rect2()
    set(val): if _movement: _movement.map_bounds = val

var is_stunned: bool = false
var stun_timer: float = 0.0
var _stun_prev_sm_process: bool = true
var _stun_prev_sm_physics: bool = true

## Property Proxies (Compatibility)
var attack_range: float:
    get: return _stats.attack_range if _stats else 25.0
var max_range: float:
    get: return _stats.max_range if _stats else 200.0
var is_melee: bool:
    get: return _stats.is_melee if _stats else true
var attack_cooldown: float:
    get: return _stats.attack_cooldown if _stats else 1.0

var combat: HeroOnFieldCombatAI:
    get: return _combat_ai

# Proxy for health status
# Proxy for health status
var is_dead: bool:
    get:
        if is_temporary_summon:
            return _temporary_summon_dead
        return _health.is_dead() if _health else true # Default to dead if no health component

var projectile_scene: PackedScene:
    get:
        if _projectile_scene_override != null:
            return _projectile_scene_override
        if default_projectile_scene != null:
            return default_projectile_scene
        return _stats.projectile_scene if _stats else null
    set(value):
        _projectile_scene_override = value
        if _stats:
            _stats.projectile_scene = value

var projectile_speed: float:
    get: return _stats.projectile_speed if _stats else 400.0

var projectile_type: String:
    get: return _stats.projectile_type if _stats else "arrow"

var projectile_spin_speed_deg: float:
    get: return _stats.projectile_spin_speed_deg if _stats else 0.0

var _projectile_scene_override: PackedScene = null

# Node references
var animation_sprite: AnimatedSprite2D = null
var health_bar: ProgressBar = null

# Static Cache
static var _cached_generic_death_frames: SpriteFrames = null

func _ready() -> void:
    # 1. Initialize Modules
    _stats = HeroOnFieldStats.new()
    _debug = HeroOnFieldDebug.new(self)
    _movement = HeroOnFieldMovement.new()
    _visuals = HeroOnFieldVisuals.new()
    _runtime_bridge = HeroOnFieldRuntimeBridgeScript.new()
    _status_effects = HeroOnFieldStatusEffectsScript.new()
    _combat_facade = HeroOnFieldCombatFacadeScript.new()
    _lifecycle = HeroOnFieldLifecycleScript.new()
    _bounds_flow = HeroOnFieldBoundsFlowScript.new()
    _bootstrap = HeroOnFieldBootstrapScript.new()
    _selection_outline_helper = HeroSelectionOutlineScript.new()
    _hurtbox_ui_helper = HeroHurtboxUIScript.new()
    _animation_helper = HeroAnimationHelperScript.new()

    _movement.setup(self, _debug)
    _runtime_bridge.setup(self)
    _status_effects.setup(self)
    _bounds_flow.setup(self)
    _combat_facade.setup(self, _combat_ai)
    _lifecycle.setup(self)
    _setup_watchdog()

    # 2. Node Setup
    if _bootstrap:
        _bootstrap.setup_visual_nodes(self)
    if _visuals:
        _visuals.hero = self
        _visuals.hero_id = hero_id
        _visuals.animation_sprite = animation_sprite
    if _selection_outline_helper:
        _selection_outline_helper.setup(self, _get_event_bus())
    if _hurtbox_ui_helper:
        _hurtbox_ui_helper.setup(self, get_node_or_null("Hurtbox") as Area2D, _get_event_bus())
    _setup_selection_outline()
    _connect_selection_signals()
    _setup_hurtbox_ui_events()
    _visuals.ensure_anim_dead(self)
    if _bootstrap:
        _bootstrap.setup_physics(self)
    add_to_group("hero")

    if hero_id != "":
        initialize(hero_id)

    var hero_core := _get_hero_core()
    if hero_core != null and hero_core.has_signal("hero_healed"):
        hero_core.hero_healed.connect(_on_hero_healed)


func _setup_watchdog() -> void:
    if _bootstrap:
        _bootstrap.setup(self)

func _setup_selection_outline() -> void:
    if _selection_outline_helper:
        _selection_outline_helper.setup_selection_outline()

func _connect_selection_signals() -> void:
    if _selection_outline_helper:
        _selection_outline_helper.connect_selection_signals(Callable(self, "_on_hero_selected_for_ui"))

func _on_hero_selected_for_ui(selected_hero_id: String) -> void:
    if _selection_outline_helper:
        _selection_outline_helper.on_hero_selected_for_ui(selected_hero_id)

func _setup_hurtbox_ui_events() -> void:
    if _hurtbox_ui_helper:
        _hurtbox_ui_helper.setup_hurtbox_ui_events(
            Callable(self, "_on_hurtbox_mouse_enter"),
            Callable(self, "_on_hurtbox_mouse_exit"),
            Callable(self, "_on_hurtbox_input_event")
        )

func _on_hurtbox_mouse_enter() -> void:
    if _hurtbox_ui_helper:
        _hurtbox_ui_helper.on_hurtbox_mouse_enter()

func _on_hurtbox_mouse_exit() -> void:
    if _hurtbox_ui_helper:
        _hurtbox_ui_helper.on_hurtbox_mouse_exit()

func _on_hurtbox_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if _hurtbox_ui_helper:
        _hurtbox_ui_helper.on_hurtbox_input_event(event)

func initialize(id: String) -> void:
    hero_id = id.to_lower()
    if _visuals != null:
        _visuals.hero_id = hero_id

    if patrol_center == Vector2.ZERO:
        patrol_center = global_position

    if _bootstrap:
        _setup_state_machine()

    _animations = HeroFieldAnimations.new()
    _combat_ai = HeroOnFieldCombatAI.new()
    _health = HeroOnFieldHealth.new()
    if _combat_facade:
        _combat_facade.setup(self, _combat_ai)
    if _bootstrap:
        _bootstrap.initialize_runtime(self, _stats, _movement, _visuals, _animations, _combat_ai, _health, _state_machine)

func _setup_visual_nodes() -> void:
    if _bootstrap:
        _bootstrap.setup_visual_nodes(self)

func _setup_physics() -> void:
    if _bootstrap:
        _bootstrap.setup_physics(self)

func _setup_state_machine() -> void:
    if _bootstrap:
        _state_machine = _bootstrap.setup_state_machine(self)

func _physics_process(delta: float) -> void:
    if _lifecycle and _lifecycle.physics_tick(delta, _debug, _health, _state_machine, _visuals, Callable(_combat_ai, "update_attack_timer") if _combat_ai else Callable(), Callable(self, "_check_target_validity"), 6):
        return
    if is_temporary_summon and summon_duration > 0.0 and not is_dead:
        _summon_elapsed += delta
        if _summon_elapsed >= summon_duration:
            die()
            return

func initialize_as_summon(unit_id: String, duration: float) -> void:
    summon_unit_id = HeroSceneRegistry.resolve_unit_id(unit_id)
    is_temporary_summon = summon_unit_id != ""
    summon_duration = maxf(0.1, duration)
    _summon_elapsed = 0.0
    _temporary_summon_dead = false
    if not is_temporary_summon:
        return
    add_to_group("summon")
    if patrol_center == Vector2.ZERO:
        patrol_center = global_position
    if _bootstrap:
        _setup_state_machine()
    _animations = HeroFieldAnimations.new()
    _combat_ai = HeroOnFieldCombatAI.new()
    _health = HeroOnFieldHealth.new()
    if _combat_facade:
        _combat_facade.setup(self, _combat_ai)
    _visuals.hero_id = summon_unit_id
    _stats.determine_combat_type(summon_unit_id)
    _movement.apply_speed_modifiers(_stats, _stats.is_melee if _stats else true, override_move_speed)
    _animations.setup(self, animation_sprite, summon_unit_id, _state_machine)
    _combat_ai.setup(self, _stats)
    _resolve_temporary_summon_stats(summon_unit_id)
    _animations.start_initial_animation()

func _check_target_validity() -> void:
    if _combat_facade:
        _combat_facade.validate_current_target()

func set_map_bounds(bounds: Rect2) -> void:
    if _bounds_flow:
        _bounds_flow.set_map_bounds(_movement, bounds)

var _bounds_hit_count: int = 0
const BOUNDS_HIT_THRESHOLD: int = 3

func enforce_battlefield_bounds(desired_direction: Vector2 = Vector2.ZERO) -> Vector2:
    return _bounds_flow.enforce_battlefield_bounds(_movement, _state_machine, desired_direction, BOUNDS_HIT_THRESHOLD) if _bounds_flow else desired_direction

func get_map_bounds() -> Rect2:
    return _bounds_flow.get_map_bounds(_movement) if _bounds_flow else Rect2()

# Public Accessors
func get_current_target() -> Node2D:
    return current_target

func set_current_target(target: Node2D) -> void:
    current_target = target

# Actions
func die() -> void:
    if _lifecycle:
        if is_temporary_summon:
            _temporary_summon_dead = true
            _emit_temporary_summon_death_event()
        _lifecycle.die(_state_machine, Callable(self, "queue_free"))

func apply_stun(duration: float) -> void:
    if _status_effects:
        _status_effects.apply_stun(duration, _state_machine, _animations, StunEffect, FloatingText)

func _set_stun_speed_scale(scale_val: float) -> void:
    if _status_effects:
        _status_effects.set_stun_speed_scale(self, scale_val)

func check_attack_range() -> bool:
    return _combat_facade.check_attack_range() if _combat_facade else false

func fire_projectile(target: Node2D) -> void:
    if _combat_facade:
        _combat_facade.fire_projectile(target)

func return_to_bridge():
    if _lifecycle and _movement:
        _lifecycle.return_to_bridge(_movement, _state_machine)

func _on_bridge_reached():
    if _lifecycle:
        _lifecycle.on_bridge_reached(hero_id, _runtime_bridge, Callable(self, "queue_free"))

# Event Handlers
func _on_hit_landed(amount: float) -> void:
    if _combat_facade:
        _combat_facade.on_hit_landed(amount)

func _on_hero_healed(h_id: String, amount: float) -> void:
    if _status_effects:
        _status_effects.on_hero_healed(h_id, hero_id, _health)

func get_current_state_name() -> String:
    return _state_machine.current_state.name if _state_machine and _state_machine.current_state else "None"

func get_base_hero_id() -> String:
    return HeroSpecialBehaviorRules.get_base_unit_id(hero_id)

func is_passive_patroller() -> bool:
    return HeroSpecialBehaviorRules.is_passive_patroller_id(hero_id)

func is_hit_and_run_unit() -> bool:
    return HeroSpecialBehaviorRules.is_hit_and_run_id(hero_id)

func _update_animation(anim_name: String) -> void:
    var anim_walk := get_node_or_null("AnimWalk") as AnimatedSprite2D
    var anim_attack := get_node_or_null("AnimAttack") as AnimatedSprite2D
    if _animations:
        _animations.update_animation(anim_name)
        if _animation_helper == null:
            return
        if anim_name == "death" or anim_name == "dead":
            return
        if anim_name != "attack" and _animations.is_attack_animation_playing():
            return
        if not _animation_helper.needs_dual_sprite_fallback(anim_name, anim_walk, anim_attack):
            return
    if _animation_helper:
        _animation_helper.update_animation(
            anim_name,
            anim_walk,
            anim_attack
        )

func get_current_hp() -> float:
    if is_temporary_summon:
        return _summon_current_hp
    return _runtime_bridge.get_current_hp() if _runtime_bridge else 0.0

func get_max_hp() -> float:
    if is_temporary_summon:
        return maxf(1.0, _summon_max_hp)
    return _runtime_bridge.get_max_hp() if _runtime_bridge else 1.0

func get_attack_damage() -> float:
    if is_temporary_summon:
        return maxf(1.0, _summon_damage)
    return _runtime_bridge.get_attack_damage() if _runtime_bridge else 1.0

func is_attack_animation_playing() -> bool:
    return _animations.is_attack_animation_playing() if _animations else false

func set_attack_animation_playing(v: bool) -> void:
    if _animations:
        _animations.set_attack_animation_playing(v)

func take_damage(amount: int, block_roll_provider: Callable = Callable()) -> void:
    if is_temporary_summon:
        _apply_temporary_summon_damage(amount, block_roll_provider)
        return
    if hero_id == "" or _runtime_bridge == null or _status_effects == null:
        return
    _status_effects.take_damage(amount, damage_taken_multiplier, is_invincible, evasion_chance, _runtime_bridge, null, block_roll_provider)

func apply_damage(amount: float, _source: Node = null) -> void:
    take_damage(int(round(amount)))

func _get_hero_core() -> Node:
    return _runtime_bridge.get_hero_core() if _runtime_bridge else null

func _get_event_bus() -> Node:
    return _runtime_bridge.get_event_bus() if _runtime_bridge else null

func _get_damage_popup_pool() -> Node:
    return _runtime_bridge.get_damage_popup_pool() if _runtime_bridge else null

func _resolve_temporary_summon_stats(unit_id: String) -> void:
    var unit_cfg := PathRegistryScript.load_unit_config(unit_id)
    if unit_cfg != null:
        _summon_max_hp = maxf(1.0, float(unit_cfg.hp))
        _summon_damage = maxf(1.0, float(unit_cfg.dps))
    else:
        _summon_max_hp = 50.0
        _summon_damage = 10.0
    _summon_current_hp = _summon_max_hp

func _apply_temporary_summon_damage(amount: int, block_roll_provider: Callable = Callable()) -> void:
    if is_dead or is_invincible:
        return
    if evasion_chance > 0.0 and randf() < clampf(evasion_chance, 0.0, 1.0):
        if get_parent() and FloatingText:
            FloatingText.spawn_evade(get_parent(), global_position + Vector2(0, -30))
        return
    if FriendlyDamageBlockHelperScript.should_block_damage(self, block_roll_provider):
        if get_parent() and FloatingText:
            FloatingText.spawn_evade(get_parent(), global_position + Vector2(0, -30))
        return
    var final_amount := maxf(1.0, float(amount) * maxf(0.0, damage_taken_multiplier))
    _summon_current_hp = maxf(0.0, _summon_current_hp - final_amount)
    if _hurtbox_ui_helper and health_bar:
        health_bar.visible = true
        health_bar.value = (_summon_current_hp / maxf(1.0, _summon_max_hp)) * 100.0
    if _summon_current_hp <= 0.0:
        die()

func _emit_temporary_summon_death_event() -> void:
    if not is_temporary_summon:
        return
    var event_bus := _get_event_bus()
    if event_bus == null or not event_bus.has_signal("hero_died"):
        return
    var token := ArtifactSummonFlowScript.register_temporary_death(summon_unit_id, global_position, summon_duration)
    if token != "":
        event_bus.hero_died.emit(token)
