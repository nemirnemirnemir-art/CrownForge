extends Node
class_name HeroFieldNavigation

var _hero: Node2D
var _nav_agent: NavigationAgent2D
var _targeting: Node
var _state_machine: Node

var _nav_repath_left: float = 0.0
var _nav_repath_interval: float = 0.2
var _last_move_delta: float = 0.0
var _nav_target_jitter: Vector2 = Vector2.ZERO

func setup(hero: Node2D, nav_agent: NavigationAgent2D, targeting: Node, state_machine: Node) -> void:
    _hero = hero
    _nav_agent = nav_agent
    _targeting = targeting
    _state_machine = state_machine
    if _nav_agent:
        _nav_agent.avoidance_enabled = true
        if not _nav_agent.velocity_computed.is_connected(_on_velocity_computed):
            _nav_agent.velocity_computed.connect(_on_velocity_computed)

func reset_repath() -> void:
    _nav_repath_left = 0.0

func move_to(target_pos: Vector2) -> void:
    if _nav_agent:
        _nav_agent.target_position = target_pos

func update_target(target: Node2D, delta: float) -> void:
    if not _nav_agent or target == null or not is_instance_valid(target):
        return
    _nav_repath_left -= delta
    if _nav_repath_left > 0.0:
        return
    if _nav_target_jitter == Vector2.ZERO:
        var rng = RandomNumberGenerator.new()
        rng.randomize()
        _nav_target_jitter = Vector2(rng.randf_range(-20.0, 20.0), rng.randf_range(-20.0, 20.0))
    _nav_agent.target_position = target.global_position + _nav_target_jitter
    _nav_repath_left = _nav_repath_interval

func process_nav_movement(delta: float) -> void:
    if not _nav_agent:
        return
    
    var map = _nav_agent.get_navigation_map()
    if not map.is_valid():
        return 

    var attacking_block := false
    if _hero and "use_new_combat_ai" in _hero and bool(_hero.use_new_combat_ai):
        if _state_machine and "current_state" in _state_machine and _state_machine.current_state:
            attacking_block = String(_state_machine.current_state.name) == "HeroAttackingState"
    if attacking_block:
        if _nav_agent.avoidance_enabled:
            _nav_agent.set_velocity(Vector2.ZERO)
        _last_move_delta = delta
        return
    if _nav_agent.is_navigation_finished():
        if _nav_agent.avoidance_enabled:
            _nav_agent.set_velocity(Vector2.ZERO)
        return
    _last_move_delta = delta
    var next_path_pos := _nav_agent.get_next_path_position()
    var move_speed := float(_hero.move_speed) if _hero and "move_speed" in _hero else 37.5
    var desired_vel := (next_path_pos - _hero.global_position).normalized() * move_speed
    if _nav_agent.avoidance_enabled:
        _nav_agent.set_velocity(desired_vel)
    else:
        _on_velocity_computed(desired_vel)

func stop() -> void:
    if _nav_agent and _nav_agent.avoidance_enabled:
        _nav_agent.set_velocity(Vector2.ZERO)

func _on_velocity_computed(safe_velocity: Vector2) -> void:
    if not _hero:
        return
    var attacking_block := false
    if "use_new_combat_ai" in _hero and bool(_hero.use_new_combat_ai):
        if _state_machine and "current_state" in _state_machine and _state_machine.current_state:
            attacking_block = String(_state_machine.current_state.name) == "HeroAttackingState"
    if attacking_block:
        return
    _hero.position += safe_velocity * _last_move_delta
    if safe_velocity.x != 0.0:
        _hero.scale.x = abs(_hero.scale.x) * (-1.0 if safe_velocity.x < 0.0 else 1.0)
