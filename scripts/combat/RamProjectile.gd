extends Area2D

enum Phase { START, FLY, EXPLOSION }

@export var speed: float = 350.0
@export var damage: float = 10.0
@export var lifetime: float = 10.0
@export var start_duration: float = 1.0

var _direction: Vector2 = Vector2.RIGHT
var _fly_timer: float = 0.0
var _start_timer: float = 0.0
var _phase: Phase = Phase.START
var _attack_id: int = 0
var _target_node: Node = null

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
    area_entered.connect(_on_area_entered)
    set_deferred("monitoring", false)
    _play_phase(Phase.START)


func setup(p_direction: Vector2, p_damage: float, p_target = null, p_owner: Node = null) -> void:
    _direction = p_direction.normalized()
    if _direction == Vector2.ZERO:
        _direction = Vector2.RIGHT
    damage = p_damage
    _attack_id += 1
    _target_node = p_target
    rotation = _direction.angle()


func _play_phase(phase: Phase) -> void:
    _phase = phase
    match phase:
        Phase.START:
            _sprite.play("start")
        Phase.FLY:
            set_deferred("monitoring", true)
            rotation = _direction.angle()
            _sprite.play("fly")
        Phase.EXPLOSION:
            set_deferred("monitoring", false)
            _sprite.play("explosion")
            _sprite.animation_finished.connect(_on_explosion_finished, CONNECT_ONE_SHOT)


func _process(delta: float) -> void:
    match _phase:
        Phase.START:
            _start_timer += delta
            if _start_timer >= start_duration:
                _play_phase(Phase.FLY)
        Phase.FLY:
            position += _direction * speed * delta
            _fly_timer += delta
            if _fly_timer >= lifetime:
                _play_phase(Phase.EXPLOSION)


func _on_area_entered(area: Area2D) -> void:
    if _phase != Phase.FLY or _target_node == null:
        return

    var hit_parent := area.get_parent() if area else null
    if area != _target_node and hit_parent != _target_node:
        return

    if area and area.has_method("apply_hit"):
        area.apply_hit(damage, self, _attack_id)
        _play_phase(Phase.EXPLOSION)
        return

    if hit_parent and hit_parent.has_method("apply_hit"):
        hit_parent.apply_hit(damage, self, _attack_id)
        _play_phase(Phase.EXPLOSION)
        return

    if area and area.has_method("take_damage"):
        area.take_damage(damage)
        _play_phase(Phase.EXPLOSION)
        return

    if hit_parent and hit_parent.has_method("take_damage"):
        hit_parent.take_damage(damage)
        _play_phase(Phase.EXPLOSION)


func _on_explosion_finished() -> void:
    queue_free()
