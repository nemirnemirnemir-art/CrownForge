extends RefCounted
class_name HeroOnFieldDebug

var _hero: Node2D
var _debug_left: float = 1.0
var is_stuck_log_enabled: bool = true
var _last_pos: Vector2 = Vector2.ZERO
var _last_hp: float = 0.0
var _last_total_damage: float = 0.0
var _stuck_time: float = 0.0
var _last_stuck_report_ms: int = 0

func _init(hero: Node2D) -> void:
    _hero = hero
    if _hero:
        _last_pos = _hero.global_position
        _last_hp = _get_current_hp()
        _last_total_damage = _get_total_damage_dealt()

func process_debug_tick(delta: float) -> void:
    _debug_left -= delta
    if _debug_left <= 0.0:
        _debug_left = 2.0 # Run every 2s
        _print_combat_state()

func _print_combat_state() -> void:
    if not _hero.visible: return # Don't spam for invisible heroes
    
    # Only print if explicitly requested or relevant to debugging
    # Currently just replicating the old logic which printed periodically
    # But let's check a specialized debug flag from the hero or global config
    
    # For now, just replicate the logic but cleaner
    var _sm_state := "<no_sm>"
    var _sm = _hero.get("state_machine_node") # Or access _state_machine property if exposed
    # Accessing private props via get() might be tricky if not @export or generic property
    # We'll assume public accessors or generic property
    
    var hero = _hero as Object
    if hero.has_method("get_current_state_name"):
        _sm_state = hero.get_current_state_name()
        
    var target = hero.get_current_target() if hero.has_method("get_current_target") else null
    var _t_name := "<none>"
    var _dist := -1.0
    if target and is_instance_valid(target):
        _t_name = target.name
        _dist = _hero.global_position.distance_to(target.global_position)
        
    # Minimal print to avoid console spam unless needed
    # print("[HeroDbg] id=%s state=%s target=%s dist=%.1f" % [_hero.name, _sm_state, _t_name, _dist])

func check_stuck() -> void:
    if not is_stuck_log_enabled or _hero == null or not is_instance_valid(_hero):
        return
    if not _hero.visible:
        _reset_stuck_tracking()
        return

    var state_name: String = "None"
    if _hero.has_method("get_current_state_name"):
        state_name = String(_hero.get_current_state_name())
    var target: Node2D = null
    if _hero.has_method("get_current_target"):
        target = _hero.get_current_target()
    var current_pos: Vector2 = _hero.global_position
    var current_hp: float = _get_current_hp()
    var current_total_damage: float = _get_total_damage_dealt()
    var moved: float = current_pos.distance_to(_last_pos)
    var hp_changed := not is_equal_approx(current_hp, _last_hp)
    var damage_changed := not is_equal_approx(current_total_damage, _last_total_damage)
    var velocity: Vector2 = Vector2.ZERO
    if "velocity" in _hero:
        velocity = _hero.velocity
    var speed: float = velocity.length()
    var target_distance: float = -1.0
    if target and is_instance_valid(target):
        target_distance = current_pos.distance_to(target.global_position)
    var should_watch := state_name == "HeroMovingState" or state_name == "HeroAttackingState" or target != null

    if should_watch and moved < 2.0 and speed < 2.0 and not hp_changed and not damage_changed:
        _stuck_time += 1.0
        if _stuck_time >= 4.0:
            var now := Time.get_ticks_msec()
            if now - _last_stuck_report_ms >= 4000:
                _last_stuck_report_ms = now
                print("[HeroStuck] hero=", _hero.name, " id=", _hero.get("hero_id") if "hero_id" in _hero else "", " state=", state_name, " pos=", current_pos, " vel=", velocity, " speed=", snappedf(speed, 0.1), " target=", target.name if target and is_instance_valid(target) else "<none>", " target_dist=", snappedf(target_distance, 0.1), " atk_range=", float(_hero.get("attack_range")) if "attack_range" in _hero else -1.0, " hp=", snappedf(current_hp, 0.1), " dmg_total=", snappedf(current_total_damage, 0.1), " stuck_for=", _stuck_time)
    else:
        _stuck_time = 0.0

    _last_pos = current_pos
    _last_hp = current_hp
    _last_total_damage = current_total_damage

func _get_current_hp() -> float:
    if _hero and _hero.has_method("get_current_hp"):
        return float(_hero.call("get_current_hp"))
    if _hero and "current_health" in _hero:
        return float(_hero.current_health)
    return 0.0

func _get_total_damage_dealt() -> float:
    if _hero == null:
        return 0.0
    var combat: Variant = _hero.get("combat")
    if combat != null and "total_damage_dealt" in combat:
        return float(combat.total_damage_dealt)
    return 0.0

func _reset_stuck_tracking() -> void:
    _stuck_time = 0.0
    if _hero and is_instance_valid(_hero):
        _last_pos = _hero.global_position
        _last_hp = _get_current_hp()
        _last_total_damage = _get_total_damage_dealt()
