extends SpellEffect

## Bladecaster spell - summons a scarecrow that has 8 hit charges
## Each hit deals 50 damage back to attacker, ignoring actual damage received

@onready var scarecrow_anim: AnimatedSprite2D = $ScarecrowAnim
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D

const FallingBladeScene = preload("res://scenes/spells/effects/FallingBlade.tscn")
const VISUAL_PATH: String = "res://assets/vfx/spells_visuals/Bladecaster.png"

const MAX_HITS: int = 8
const RETALIATION_DAMAGE: float = 50.0
const ATTACKER_HEAD_OFFSET: Vector2 = Vector2(0.0, -50.0)
const FALL_TIME: float = 0.18

const HP_DOT_RADIUS: float = 5.0
const HP_DOT_SPACING: float = 13.0
const HP_DOT_OFFSET_Y: float = -55.0
const HP_COLOR_ACTIVE: Color = Color(0.9, 0.1, 0.1, 1.0)
const HP_COLOR_SPENT: Color = Color(0.4, 0.4, 0.4, 1.0)

var _hits_remaining: int = MAX_HITS
var _is_dead: bool = false
var _hp_dots: Array[Node2D] = []

func execute_effect() -> void:
	if not scarecrow_anim or not hurtbox:
		push_error("[BladecasterEffect] Missing required nodes")
		queue_free()
		return

	z_index = 100

	# Load visual programmatically
	var tex := load(VISUAL_PATH) as Texture2D
	if tex != null:
		var frames := SpriteFrames.new()
		frames.add_animation(&"idle")
		frames.set_animation_loop(&"idle", true)
		frames.set_animation_speed(&"idle", 1.0)
		frames.add_frame(&"idle", tex)
		scarecrow_anim.sprite_frames = frames
		scarecrow_anim.z_index = 0
		scarecrow_anim.play(&"idle")
	else:
		push_warning("[BladecasterEffect] Could not load visual: " + VISUAL_PATH)

	if not is_in_group("hero"):
		add_to_group("hero")

	# Setup hurtbox collision shape
	if hurtbox_shape:
		var hit_shape := CircleShape2D.new()
		hit_shape.radius = 25.0
		hurtbox_shape.shape = hit_shape

	# Make hurtbox detectable by enemies
	hurtbox.collision_layer = 1
	hurtbox.collision_mask = 2

	# Connect to receive damage
	if hurtbox.has_signal("area_entered") and not hurtbox.area_entered.is_connected(_on_area_entered):
		hurtbox.area_entered.connect(_on_area_entered)

	_build_hp_dots()

func _build_hp_dots() -> void:
	var total_width := float(MAX_HITS - 1) * HP_DOT_SPACING
	for i in range(MAX_HITS):
		var dot := Node2D.new()
		dot.position = Vector2(
			-total_width * 0.5 + float(i) * HP_DOT_SPACING,
			HP_DOT_OFFSET_Y
		)
		dot.z_index = 10
		add_child(dot)
		_hp_dots.append(dot)
		_draw_dot(dot, HP_COLOR_ACTIVE)

func _draw_dot(dot: Node2D, color: Color) -> void:
	for child in dot.get_children():
		child.queue_free()
	var circle := Node2D.new()
	circle.set_script(null)
	dot.add_child(circle)
	# Use a small ColorRect as a circle approximation via a script
	var rect := ColorRect.new()
	rect.color = color
	rect.size = Vector2(HP_DOT_RADIUS * 2.0, HP_DOT_RADIUS * 2.0)
	rect.position = Vector2(-HP_DOT_RADIUS, -HP_DOT_RADIUS)
	dot.add_child(rect)

func _on_area_entered(area: Area2D) -> void:
	if _is_dead:
		return
	var attacker := area.get_parent() as Node2D
	if attacker == null or not is_instance_valid(attacker):
		return
	if not (attacker.is_in_group("enemy") or attacker.is_in_group("mobs") or attacker.is_in_group("enemies")):
		return
	await _register_hit(attacker)

func take_damage(_amount: float, _is_crit: bool = false) -> void:
	if _is_dead:
		return
	var attacker := _find_nearest_attacker()
	await _register_hit(attacker)

func apply_damage(_amount: float, source: Node) -> void:
	if _is_dead:
		return
	var attacker := _resolve_attacker_from_source(source)
	await _register_hit(attacker)

func _resolve_attacker_from_source(source: Node) -> Node2D:
	if source == null or not is_instance_valid(source):
		return _find_nearest_attacker()
	if source is Node2D:
		var n := source as Node2D
		if n.is_in_group("enemy") or n.is_in_group("mobs") or n.is_in_group("enemies"):
			return n
	var p := source.get_parent()
	if p != null and is_instance_valid(p) and p is Node2D:
		var n2 := p as Node2D
		if n2.is_in_group("enemy") or n2.is_in_group("mobs") or n2.is_in_group("enemies"):
			return n2
	return _find_nearest_attacker()

func _find_nearest_attacker() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	var candidates: Array[Node] = []
	candidates.append_array(get_tree().get_nodes_in_group("enemy"))
	candidates.append_array(get_tree().get_nodes_in_group("enemies"))
	candidates.append_array(get_tree().get_nodes_in_group("mobs"))
	for c in candidates:
		if c == null or not is_instance_valid(c):
			continue
		if not (c is Node2D):
			continue
		var n := c as Node2D
		var d := global_position.distance_squared_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n
	return best

func _register_hit(attacker: Node2D) -> void:
	if _is_dead:
		return
	_hits_remaining -= 1

	# Turn the rightmost active dot grey
	var spent_idx := MAX_HITS - 1 - _hits_remaining
	if spent_idx >= 0 and spent_idx < _hp_dots.size():
		_draw_dot(_hp_dots[spent_idx], HP_COLOR_SPENT)

	if attacker != null and is_instance_valid(attacker):
		_spawn_blade_on_attacker(attacker)

	# Flash effect
	if scarecrow_anim:
		scarecrow_anim.modulate = Color(2, 2, 2, 1)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(scarecrow_anim):
			scarecrow_anim.modulate = Color(1, 1, 1, 1)

	if _hits_remaining <= 0:
		_die()

func _spawn_blade_on_attacker(attacker: Node2D) -> void:
	if FallingBladeScene == null:
		return
	var blade := FallingBladeScene.instantiate()
	if blade == null:
		return
	var root: Node
	if get_parent() != null:
		root = get_parent()
	else:
		root = get_tree().current_scene
	if root == null:
		return
	root.add_child(blade)
	blade.global_position = attacker.global_position + ATTACKER_HEAD_OFFSET

	var dmg := RETALIATION_DAMAGE
	if config != null and config.damage > 0.0:
		dmg = get_scaled_damage(config.damage)
	else:
		dmg = get_scaled_damage(RETALIATION_DAMAGE)
	if blade.has_method("setup"):
		blade.call("setup", dmg, FALL_TIME, attacker)

func _die() -> void:
	if _is_dead:
		return
	_is_dead = true

	if hurtbox:
		hurtbox.monitoring = false
		hurtbox.monitorable = false
	if hurtbox_shape:
		hurtbox_shape.set_deferred("disabled", true)

	var base_scale := scale
	var base_pos := position

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", base_scale * 1.2, 0.12)
	tween.parallel().tween_property(self, "position", base_pos + Vector2(0.0, -18.0), 0.12)

	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", base_scale * 0.05, 0.38)
	tween.parallel().tween_property(self, "position", base_pos + Vector2(0.0, 14.0), 0.38)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.38)

	await tween.finished
	queue_free()
