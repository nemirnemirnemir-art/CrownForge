extends Node2D

const HeroSceneRegistryScript = preload("res://scripts/hero/HeroSceneRegistry.gd")
const GOBLIN_BANDIT_SCENE: PackedScene = preload("res://scenes/mobs/GoblinBandit.tscn")

@export var stun_duration: float = 3.0
@export var spawn_jitter: float = 18.0
@export var knockback_force: float = 180.0
@export var knockback_duration: float = 0.25

@onready var _world: Node2D = $World
@onready var _heroes: Node2D = $World/Heroes
@onready var _mobs: Node2D = $World/Mobs
@onready var _camera: Camera2D = $Camera2D
@onready var _debug_panel: Node = get_node_or_null("UI/TestDebugPanel")

func _ready() -> void:
    randomize()
    add_to_group("game_scene")
    if _camera:
        _camera.enabled = true
        _camera.position = MapMarkerService.get_bridge_position() if MapMarkerService else Vector2(400, 300)

    if _debug_panel:
        if _debug_panel.has_signal("spawn_peasant_pressed"):
            _debug_panel.connect("spawn_peasant_pressed", Callable(self, "_spawn_peasant"))
        if _debug_panel.has_signal("spawn_goblin_bandit_pressed"):
            _debug_panel.connect("spawn_goblin_bandit_pressed", Callable(self, "_spawn_goblin_bandit"))
        if _debug_panel.has_signal("clear_scene_pressed"):
            _debug_panel.connect("clear_scene_pressed", Callable(self, "_clear_scene"))

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var k := event as InputEventKey
        if k.pressed and not k.echo and k.keycode == KEY_Z:
            _apply_stun_to_all_units()

func _get_spawn_center() -> Vector2:
    if _camera:
        return _camera.get_screen_center_position()
    return global_position

func _rand_jitter() -> Vector2:
    return Vector2(randf_range(-spawn_jitter, spawn_jitter), randf_range(-spawn_jitter, spawn_jitter))

func _spawn_peasant() -> void:
    if _heroes == null:
        return
    var peasant_scene := HeroSceneRegistryScript.load_scene("peasant")
    if peasant_scene == null:
        push_error("[TestScene] Hero scene not found for unit: peasant")
        return

    var inst := peasant_scene.instantiate() as Node2D
    if inst == null:
        return
    _heroes.add_child(inst)
    inst.global_position = _get_spawn_center() + _rand_jitter()

    var spawn_id := _make_unique_test_hero_id("peasant")
    _ensure_hero_exists(spawn_id, "peasant")
    if inst.has_method("initialize"):
        inst.call("initialize", spawn_id)

    if "bridge_position" in inst and MapMarkerService:
        inst.bridge_position = MapMarkerService.get_bridge_position()

func _spawn_goblin_bandit() -> void:
    if GOBLIN_BANDIT_SCENE == null or _mobs == null:
        return
    var inst := GOBLIN_BANDIT_SCENE.instantiate() as Node2D
    if inst == null:
        return
    _mobs.add_child(inst)
    inst.global_position = _get_spawn_center() + _rand_jitter() + Vector2(60, 0)
    # Align with normal game wiring (so AI/behavior has expected reference points)
    if MapMarkerService:
        if "bridge_position" in inst:
            inst.bridge_position = MapMarkerService.get_bridge_position()
        if "portal_position" in inst:
            inst.portal_position = MapMarkerService.get_portal_position()
        if "center_position" in inst:
            inst.center_position = (MapMarkerService.get_bridge_position() + MapMarkerService.get_portal_position()) * 0.5
        if "behavior_target_type" in inst:
            inst.behavior_target_type = "bridge"

func _apply_stun_to_all_units() -> void:
    var tree := get_tree()
    if tree == null:
        return

    var groups := ["hero", "enemy", "mobs"]
    var seen: Dictionary = {}
    for g in groups:
        for n in tree.get_nodes_in_group(g):
            if n == null or not is_instance_valid(n):
                continue
            if seen.has(n):
                continue
            if not is_ancestor_of(n):
                continue
            seen[n] = true
            if n.has_method("apply_stun"):
                n.call("apply_stun", stun_duration)
            _apply_knockback_to_unit(n)

func _apply_knockback_to_unit(unit: Node) -> void:
    if unit == null or not is_instance_valid(unit):
        return
    var unit2d := unit if unit is Node2D else null
    if unit2d == null:
        return
    var direction: Vector2 = Vector2.RIGHT.rotated(randf() * TAU)
    var source: Vector2 = unit2d.global_position - direction * 10.0
    var kb_node := unit2d.get_node_or_null("KnockbackComponent")
    if kb_node and kb_node.has_method("apply_knockback"):
        kb_node.call("apply_knockback", source, knockback_force, knockback_duration)
        return
    var initial_pos: Vector2 = unit2d.global_position
    var force := knockback_force * randf_range(0.85, 1.15)
    var target: Vector2 = initial_pos + direction * force
    var push_duration: float = maxf(0.2, knockback_duration * 2.0)
    var tween := unit2d.create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(unit2d, "global_position", target, push_duration)

    _apply_tilt(unit2d, direction, push_duration, push_duration * 0.9)
    _start_stun_wobble(unit2d, push_duration * 0.8)

func _clear_scene() -> void:
    if get_tree():
        get_tree().reload_current_scene()

func _ensure_hero_exists(hero_id: String, icon_id: String) -> void:
    if HeroCore == null:
        return
    if HeroCore.query and HeroCore.query.has_hero(hero_id):
        return
    if HeroCore.has_method("create_hero"):
        HeroCore.create_hero(hero_id, hero_id.capitalize(), icon_id, 0.0)

func _make_unique_test_hero_id(base_id: String) -> String:
    var base := base_id.to_lower()
    for attempt in range(0, 50):
        var new_id := "%s_test_%d" % [base, int(Time.get_unix_time_from_system() * 1000) + randi() % 1000]
        if HeroCore == null or not (HeroCore.query and HeroCore.query.has_hero(new_id)):
            return new_id
    return "%s_test_%d" % [base, int(Time.get_unix_time_from_system() * 1000)]

func _apply_tilt(unit2d: Node2D, direction: Vector2, push_duration: float, settle_duration: float) -> void:
    var target_node := unit2d.get_node_or_null("AnimationSprite2D")
    if target_node == null:
        target_node = unit2d
    var tilt_angle := clampf(direction.x, -1.0, 1.0) * deg_to_rad(15.0)
    var squash_scale := Vector2(1.0 + abs(direction.x) * 0.12, 1.0 - 0.1)

    var tilt_tween := target_node.create_tween()
    tilt_tween.set_parallel(true)
    tilt_tween.tween_property(target_node, "rotation", tilt_angle, push_duration * 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tilt_tween.tween_property(target_node, "scale", squash_scale, push_duration * 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tilt_tween.set_parallel(false)
    tilt_tween.tween_property(target_node, "rotation", 0.0, settle_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tilt_tween.tween_property(target_node, "scale", Vector2.ONE, settle_duration * 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _start_stun_wobble(unit2d: Node2D, delay: float) -> void:
    if unit2d == null or not is_instance_valid(unit2d):
        return
    var target_node := unit2d.get_node_or_null("AnimationSprite2D")
    if target_node == null:
        target_node = unit2d
    var tree := get_tree()
    if tree == null:
        return

    var start_callable := func():
        if not is_instance_valid(target_node):
            return
        if target_node.has_meta("_test_wobble_tween"):
            var prev: Tween = target_node.get_meta("_test_wobble_tween") as Tween
            if prev and prev is Tween and prev.is_valid():
                prev.kill()
        var amplitude: float = deg_to_rad(11.0)
        var segment: float = 0.25
        var loops: int = maxi(1, int(ceil(stun_duration / (segment * 2.0))))
        var wobble := target_node.create_tween()
        wobble.set_trans(Tween.TRANS_SINE)
        wobble.set_ease(Tween.EASE_IN_OUT)
        for i in range(loops):
            wobble.tween_property(target_node, "rotation", amplitude, segment)
            wobble.tween_property(target_node, "rotation", -amplitude, segment)
        wobble.tween_property(target_node, "rotation", 0.0, 0.3)
        wobble.finished.connect(func():
            if target_node.has_meta("_test_wobble_tween"):
                target_node.set_meta("_test_wobble_tween", null)
        )
        target_node.set_meta("_test_wobble_tween", wobble)

    if delay <= 0.01:
        start_callable.call()
    else:
        var timer := tree.create_timer(delay)
        timer.timeout.connect(start_callable)
