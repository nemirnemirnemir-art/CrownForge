extends RefCounted
class_name AttackTiming

signal hit_window_opened()
signal hit_window_closed()
signal attack_finished()

@export var attack_cooldown: float = 1.0
@export var attack_duration: float = 0.8
@export var hit_start_time: float = 0.2
@export var hit_end_time: float = 0.6

var attack_id: int = 0

var _timer: float = 0.0
var _cooldown_left: float = 0.0
var _attacking: bool = false
var _hit_enabled: bool = false

func can_start_attack() -> bool:
	return _cooldown_left <= 0.0 and not _attacking

func is_attacking() -> bool:
	return _attacking

func start() -> void:
	_attacking = true
	_timer = 0.0
	_hit_enabled = false
	attack_id += 1
	_cooldown_left = attack_cooldown

func cancel() -> void:
	if not _attacking:
		return
	_hit_enabled = false
	_attacking = false

func finish_from_animation() -> void:
	if not _attacking:
		return
	_do_finish()

func begin_hit_window() -> void:
	if not _attacking or _hit_enabled:
		return
	_hit_enabled = true
	hit_window_opened.emit()

func end_hit_window() -> void:
	if not _attacking or not _hit_enabled:
		return
	_hit_enabled = false
	hit_window_closed.emit()

func consume_cooldown() -> void:
	if _attacking:
		return
	if _cooldown_left <= 0.0:
		_cooldown_left = attack_cooldown

func tick_cooldown(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = max(0.0, _cooldown_left - delta)

func tick_attack(delta: float) -> void:
	if not _attacking:
		return
	_timer += delta
	if not _hit_enabled and _timer >= hit_start_time and _timer < hit_end_time:
		_hit_enabled = true
		hit_window_opened.emit()
	if _hit_enabled and _timer >= hit_end_time:
		_hit_enabled = false
		hit_window_closed.emit()
	if _timer >= attack_duration:
		_do_finish()

func _do_finish() -> void:
	_hit_enabled = false
	_attacking = false
	attack_finished.emit()
