extends CharacterBody2D
class_name Mob

## Mob controller (Orchestrator Facade)
## Coordinates components and handles movement/state logic

const MOVE_SPEED: float = 50.0  # Default pixels per second (reduced by 50%)

const MELEE_OVER_RANGED_SPEED_RATIO: float = 1.15
const GIANT_SPEED_MULTIPLIER: float = 0.75
const MobLaneAssaultScript = preload("res://scripts/mob/MobLaneAssault.gd")
const MobRuntimeBridgeScript = preload("res://scripts/mob/modules/MobRuntimeBridge.gd")
const MobStatusEffectsFlowScript = preload("res://scripts/mob/modules/MobStatusEffectsFlow.gd")
const MobDeathFlowScript = preload("res://scripts/mob/modules/MobDeathFlow.gd")
const MobDeathAnimSetupScript = preload("res://scripts/mob/modules/MobDeathAnimSetup.gd")
const MobProjectileFlowScript = preload("res://scripts/mob/modules/MobProjectileFlow.gd")
const MobBootstrapScript = preload("res://scripts/mob/modules/MobBootstrap.gd")
const MobWallTargetingFlowScript = preload("res://scripts/mob/modules/MobWallTargetingFlow.gd")
const MobWatchdogFlowScript = preload("res://scripts/mob/modules/MobWatchdogFlow.gd")
const MobCombatFacadeScript = preload("res://scripts/mob/modules/MobCombatFacade.gd")

## Modules
var stats: MobStats
var movement: MobMovement
var combat: MobCombat
var animations: MobAnimations
var visuals: MobVisuals

## Export for Modules (Forwarded to Stats)
@export var move_speed: float = 50.0
@export var invert_visual_facing: bool = false
@export var attack_range: float = 25.0
@export var aggro_range: float = 200.0
@export var mob_damage: float = 1.0
@export var heal_amount: float = 19.0
@export var projectile_scene: PackedScene

## Internal State (Delegated to Movement)
var behavior_target_type: String = "portal"
var target_position: Vector2:
    get: return movement.target_position if movement else Vector2.ZERO
    set(val): if movement: movement.target_position = val
var center_position: Vector2:
    get: return movement.center_position if movement else Vector2.ZERO
    set(val): if movement: movement.center_position = val
var bridge_position: Vector2:
    get: return movement.bridge_position if movement else Vector2.ZERO
    set(val): if movement: movement.bridge_position = val
var portal_position: Vector2:
    get: return movement.portal_position if movement else Vector2.ZERO
    set(val): if movement: movement.portal_position = val
var move_direction: Vector2:
    get: return movement.move_direction if movement else Vector2.ZERO
    set(val): if movement: movement.move_direction = val

## Stats Proxy Accessors (delegated to MobStats or MobHealth)
var current_health: float:
    get: return health.current_health if health else 0.0

var max_health: float:
    get: return health.max_health if health else 0.0

var is_dead: bool:
    get: return health.is_dead if health else true

var damage_taken_multiplier: float:
    get: return stats.damage_taken_multiplier if stats else 1.0
    set(value):
        if stats:
            stats.damage_taken_multiplier = value

var evasion_chance: float:
    get: return stats.evasion_chance if stats else 0.0
    set(value):
        if stats:
            stats.evasion_chance = value

var is_invincible: bool:
    get: return stats.is_invincible if stats else false
    set(value):
        if stats:
            stats.is_invincible = value

var speed_multiplier: float:
    get: return stats.speed_multiplier if stats else 1.0
    set(value):
        if stats:
            stats.speed_multiplier = value

var attack_speed_multiplier: float:
    get: return stats.attack_speed_multiplier if stats else 1.0
    set(value):
        if stats:
            stats.attack_speed_multiplier = value

var _debug_left: float = 1.0
var _last_hp: float = 0.0
var _total_damage_dealt_last: float = 0.0
var _lane_assault = MobLaneAssaultScript.new()
var _pending_wall_attack_stop_distance_override: float = -1.0
var _runtime_bridge: RefCounted = null
var _status_effects_flow: RefCounted = null
var _death_flow: RefCounted = null
var _death_anim_setup: RefCounted = null
var _projectile_flow: RefCounted = null
var _bootstrap: RefCounted = null
var _wall_targeting_flow: RefCounted = null
var _watchdog_flow: RefCounted = null
var _combat_facade: RefCounted = null

## Component References
@onready var health: MobHealth = $Components/Health
@onready var rewards: MobRewards = $Components/Rewards
@onready var slots: MobSlots = $Components/Slots
@onready var click_handler: MobClickHandler = $Components/ClickHandler

## Standard Node References

@onready var animation_sprite: AnimatedSprite2D = get_node_or_null("AnimationSprite2D")
@onready var anim_walk: AnimatedSprite2D = get_node_or_null("AnimWalk")
@onready var anim_attack: AnimatedSprite2D = get_node_or_null("AnimAttack")
@onready var animation_dead: AnimatedSprite2D = get_node_or_null("AnimationDead")
@onready var health_bar: Control = get_node_or_null("HealthBar")
@onready var health_bar_fill: ColorRect = get_node_or_null("HealthBar/Fill")
@onready var click_area: Area2D = get_node_or_null("ClickArea")
@onready var shadow: CanvasItem = get_node_or_null("Shadow")
var _use_dual_sprites: bool = false

## Internal Component references (Combat/AI)
var _hurtbox: Area2D
var _hitbox: Area2D
var _state_machine: Node
var _aggro_area: Area2D
var _attack_component: Node

func _ready() -> void:
    # 1. Instantiate modules
    stats = MobStats.new()
    movement = MobMovement.new()
    combat = MobCombat.new()
    animations = MobAnimations.new()
    visuals = MobVisuals.new()
    _runtime_bridge = MobRuntimeBridgeScript.new()
    _status_effects_flow = MobStatusEffectsFlowScript.new()
    _death_flow = MobDeathFlowScript.new()
    _death_anim_setup = MobDeathAnimSetupScript.new()
    _projectile_flow = MobProjectileFlowScript.new()
    _bootstrap = MobBootstrapScript.new()
    _wall_targeting_flow = MobWallTargetingFlowScript.new()
    _watchdog_flow = MobWatchdogFlowScript.new()
    _combat_facade = MobCombatFacadeScript.new()
    
    # 2. Setup modules
    if _bootstrap:
        _bootstrap.run(self)

func _behavior_setup() -> void:
    behavior_target_type = "portal"

func set_map_bounds(bounds: Rect2) -> void:
    if movement:
        movement.set_map_bounds(bounds)

func get_effective_move_speed() -> float:
    if stats:
        return stats.get_effective_speed()
    return move_speed

func apply_spawn_speed_variance(multiplier: float) -> void:
    if stats:
        stats.apply_spawn_speed_variance(multiplier)

func get_spawn_speed_variance_percent() -> int:
    if stats:
        return stats.spawn_speed_variance_percent
    return 0

func enforce_battlefield_bounds(desired_direction: Vector2 = Vector2.ZERO) -> Vector2:
    if movement == null or movement.map_bounds.size == Vector2.ZERO:
        return desired_direction
    return movement.enforce_battlefield_bounds(self, desired_direction)

func is_at_left_bounds_edge(tolerance: float = 30.0) -> bool:
    if movement == null or movement.map_bounds.size == Vector2.ZERO:
        return false
    return global_position.x <= movement.map_bounds.position.x + tolerance

func get_map_bounds() -> Rect2:
    if movement:
        return movement.map_bounds
    return Rect2()

func set_assault_lane_y(lane_y: float) -> void:
    if _lane_assault:
        _lane_assault.capture_lane_from_spawn(lane_y)

func get_assault_lane_y() -> float:
    if _lane_assault:
        return _lane_assault.get_lane_y(global_position.y, get_map_bounds())
    return global_position.y

func get_wall_attack_range() -> float:
    return _wall_targeting_flow.get_wall_attack_range() if _wall_targeting_flow else 0.0

func get_wall_attack_stand_off(stop_buffer: float = -1.0) -> float:
    return _wall_targeting_flow.get_wall_attack_stand_off(stop_buffer) if _wall_targeting_flow else 0.0

func get_wall_attack_trigger_distance(stop_buffer: float = -1.0) -> float:
    return _wall_targeting_flow.get_wall_attack_trigger_distance(stop_buffer) if _wall_targeting_flow else 0.0

func set_wall_attack_stop_distance(distance: float) -> void:
    _pending_wall_attack_stop_distance_override = maxf(0.0, distance)
    if _wall_targeting_flow:
        _wall_targeting_flow.set_wall_attack_stop_distance(distance)

func _consume_pending_wall_attack_stop_distance_override() -> float:
    var pending_override := _pending_wall_attack_stop_distance_override
    _pending_wall_attack_stop_distance_override = -1.0
    return pending_override

func get_wall_front_offset_x() -> float:
    return _wall_targeting_flow.get_wall_front_offset_x() if _wall_targeting_flow else 0.0

func get_wall_target_node() -> Node2D:
    return _wall_targeting_flow.get_wall_target_node() if _wall_targeting_flow else null

func get_wall_contact_position() -> Vector2:
    return _wall_targeting_flow.get_wall_contact_position() if _wall_targeting_flow else Vector2.ZERO

func get_wall_approach_position(stop_buffer: float = -1.0) -> Vector2:
    return _wall_targeting_flow.get_wall_approach_position(stop_buffer) if _wall_targeting_flow else Vector2.ZERO

func get_wall_position() -> Vector2:
    return get_wall_approach_position()

func get_distance_to_wall() -> float:
    return _wall_targeting_flow.get_distance_to_wall() if _wall_targeting_flow else 0.0

func set_behavior_target(target_type: String) -> void:
    behavior_target_type = target_type
    if movement:
        movement.behavior_target_type = target_type

func get_should_flip_for_direction(direction_x: float) -> bool:
    if movement:
        return movement.get_should_flip_for_direction(direction_x, invert_visual_facing)
    var should_flip: bool = direction_x < 0.0
    if invert_visual_facing:
        should_flip = not should_flip
    return should_flip

func _component_setup() -> void:
    if _bootstrap:
        _bootstrap.setup_components(self)

func _animation_setup() -> void:
    if _bootstrap:
        _bootstrap.setup_animation_sprites(self)

func _signal_setup() -> void:
    if health and not health.died.is_connected(_on_died):
        health.died.connect(_on_died)
    if _attack_component:
        _attack_component.use_animation_hit_window = true
    if _watchdog_flow:
        _watchdog_flow.setup_timer(self, Callable(self, "_on_watchdog_timer_timeout"))

func _spawn_effects_setup() -> void:
    if visuals:
        visuals.play_spawn_effects()

func _spawn_dust() -> void:
    if visuals and visuals.has_method("_spawn_dust"):
        visuals._spawn_dust()

func _register_combat_groups() -> void:
    if not is_in_group("enemy"):
        add_to_group("enemy")
    if not is_in_group("mobs"):
        add_to_group("mobs")
    if not is_in_group("enemies"):
        add_to_group("enemies")

func _on_died() -> void:
    var dead_node := get_node_or_null("AnimDead") as AnimatedSprite2D
    _death_flow.on_died(shadow, anim_walk, anim_attack, animation_sprite, dead_node, animation_dead)
    _death_flow.connect_death_cleanup(self, dead_node, animation_dead, animation_sprite, Callable(self, "_on_death_animation_finished"))

func _on_death_animation_finished() -> void:
    _death_flow.on_death_animation_finished()

func _on_watchdog_timer_timeout() -> void:
    if _watchdog_flow:
        _watchdog_flow.watchdog_tick(self, movement, combat, _state_machine, Callable(self, "end_attack"))

func _process(delta: float) -> void:
    if is_dead: return
    
    _debug_left -= delta
    if _debug_left <= 0.0:
        _debug_left = 2.0
        _debug_combat_tick()

func take_damage(amount: float, is_crit: bool = false) -> void:
    if _status_effects_flow:
        _status_effects_flow.take_damage(amount, is_crit, FloatingText, _runtime_bridge.get_singleton("DamagePopupPool") if _runtime_bridge else null)

func apply_stun(duration: float) -> void:
    if _status_effects_flow:
        _status_effects_flow.apply_stun(duration, StunEffect, FloatingText)

func reserve_slot(hero_id: String) -> bool:
    return slots.reserve_slot(hero_id)

func release_slot(hero_id: String) -> void:
    slots.release_slot(hero_id)

func has_slot(hero_id: String) -> bool:
    return slots.has_slot(hero_id)

func get_available_slots() -> int:
    return slots.get_available_slots()

func start_attack() -> void:
    if _combat_facade:
        _combat_facade.start_attack(combat)

func attack_finished() -> bool:
    return _combat_facade.attack_finished(combat) if _combat_facade else true

func end_attack() -> void:
    if _combat_facade:
        _combat_facade.end_attack(combat)

func play_anim(anim_name: String) -> void:
    if animations: animations._play_anim(anim_name)

func _is_boss_mob() -> bool:
    if stats: return stats.is_boss_mob()
    return false

func _debug_combat_tick() -> void:
    pass

func _get_wall_rect() -> Rect2:
    if _wall_targeting_flow:
        return _wall_targeting_flow._get_wall_rect()
    return Rect2()

func _get_wall_marker_position() -> Vector2:
    if _wall_targeting_flow:
        return _wall_targeting_flow._get_wall_marker_position()
    return Vector2.ZERO

func _get_singleton(name: String) -> Node:
    return _runtime_bridge.get_singleton(name) if _runtime_bridge else null

## Healing support (for Goblin Shaman)
func heal(amount: float) -> void:
    var actual_heal: float = _combat_facade.heal(health, amount) if _combat_facade else 0.0
    if actual_heal > 0:
        pass

## Ranged attack support
func fire_projectile(target_pos: Vector2, target_node: Node2D = null) -> void:
    if _projectile_flow:
        _projectile_flow.fire_projectile(self, target_pos, target_node)

## Animation proxy methods for convenience
func play_walk() -> void:
    if _combat_facade:
        _combat_facade.play_walk(animations)

func play_attack() -> void:
    if _combat_facade:
        _combat_facade.play_attack(animations)

func play_death() -> void:
    if _combat_facade:
        _combat_facade.play_death(animations)

## Death handling - called by MobDeathState
func die() -> void:
    if _death_flow:
        _death_flow.execute_die(self, _aggro_area, _hurtbox, _hitbox, _attack_component, _runtime_bridge)

func _try_spawn_corpse() -> void:
    if _death_flow:
        _death_flow.try_spawn_corpse(self)

func _on_death_cleanup() -> void:
    if is_instance_valid(self):
        queue_free()
