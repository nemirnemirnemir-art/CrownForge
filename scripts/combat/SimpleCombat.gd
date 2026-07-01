extends RefCounted
class_name SimpleCombat

## Distance-based combat system
## No collision detection - pure distance check + timer

signal attack_started(target: Node2D)
signal damage_dealt(target: Node2D, amount: int)

var owner_node: Node2D
var attack_range: float = 50.0
var attack_damage: float = 10.0
var attack_cooldown: float = 1.0
var hit_delay: float = 0.3  # Delay before damage is applied (for animation sync)

var _attack_timer: float = 0.0
var _current_target: Node2D = null
var _hit_pending: bool = false
var _hit_timer: float = 0.0
var _is_attacking: bool = false

func _init(owner_node: Node2D) -> void:
	self.owner_node = owner_node

func setup(range_val: float, damage_val: float, cooldown_val: float, delay_val: float = 0.3) -> void:
	attack_range = range_val
	attack_damage = damage_val
	attack_cooldown = cooldown_val
	hit_delay = delay_val
	# print("[SimpleCombat] %s configured: range=%.0f, damage=%.1f, cooldown=%.1f" % [owner_node.name, range_val, damage_val, cooldown_val])

func is_in_range(target: Node2D) -> bool:
	if not owner_node or not target or not is_instance_valid(target):
		return false
	return owner_node.global_position.distance_to(target.global_position) <= attack_range

func can_attack() -> bool:
	return _attack_timer <= 0.0 and not _is_attacking

func is_attacking() -> bool:
	return _is_attacking

func start_attack(target: Node2D) -> bool:
	if not can_attack() or not is_in_range(target):
		return false
	if not target or not is_instance_valid(target):
		return false
	
	_current_target = target
	_is_attacking = true
	_hit_pending = true
	_hit_timer = hit_delay
	_attack_timer = attack_cooldown
	attack_started.emit(target)
	return true

func update(delta: float) -> void:
	if _attack_timer > 0:
		_attack_timer -= delta
	
	if _hit_pending:
		_hit_timer -= delta
		if _hit_timer <= 0:
			_apply_damage()
			_hit_pending = false
			_is_attacking = false

func cancel_attack() -> void:
	_hit_pending = false
	_is_attacking = false
	_current_target = null

func get_current_target() -> Node2D:
	return _current_target

func _apply_damage() -> void:
	if _current_target == null or not is_instance_valid(_current_target):
		return
	
	# Check if target is dead
	if "is_dead" in _current_target and bool(_current_target.is_dead):
		return
	
	# Apply damage
	var damage_amount := int(round(attack_damage))
	if _current_target.has_method("take_damage"):
		_current_target.take_damage(damage_amount)
		damage_dealt.emit(_current_target, damage_amount)
		# print("[SimpleCombat] %s dealt %d damage to %s" % [owner_node.name, damage_amount, _current_target.name])
