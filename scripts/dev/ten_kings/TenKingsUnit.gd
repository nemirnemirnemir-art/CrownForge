## Battle unit Node2D — represents a troop stack, tower, or castle on the arena.
## Uses a simple enum-based state machine for IDLE / ADVANCING / FIGHTING /
## CHASING_CASTLE / DEAD.  Visuals are a Sprite2D (card icon), a drawn HP bar,
## and a Label showing unit count.  No dependencies outside TenKingsCardLibrary.
extends Node2D

const CardLib := preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")
const SoldierActorScene := preload("res://scenes/dev/ten_kings/actors/TenKingsSoldierActor.tscn")
const ArcherActorScene := preload("res://scenes/dev/ten_kings/actors/TenKingsArcherActor.tscn")
const PaladinActorScene := preload("res://scenes/dev/ten_kings/actors/TenKingsPaladinActor.tscn")

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal unit_died(unit: Node2D)
signal attack_performed(attacker, target)

# ---------------------------------------------------------------------------
# State machine
# ---------------------------------------------------------------------------
enum UnitState { IDLE, ADVANCING, FIGHTING, CHASING_CASTLE, DEAD }

# ---------------------------------------------------------------------------
# Data fields
# ---------------------------------------------------------------------------
var card_id: StringName
var level: int
var unit_count: int          ## current alive units
var max_unit_count: int      ## starting units
var hp_per_unit: float       ## HP of each individual unit
var current_hp: float        ## HP of the front unit (takes damage first)
var dmg_per_unit: float      ## damage per unit per hit
var hits_per_second: float
var crit_chance: float
var is_ranged: bool
var is_building: bool
var is_indestructible: bool
var side: int                ## 0 = player, 1 = AI
var smith_dmg_bonus: float   ## cumulative blacksmith bonus
var steel_coat_blocks: int   ## blocks available this battle
var attack_range: float      ## pixels; melee ~40, ranged ~300, buildings ~400

var _state: int = UnitState.IDLE
var _attack_timer: float = 0.0
var _target: Node2D = null   ## current attack target (another TenKingsUnit)
var _chase_target_pos: Vector2 = Vector2.ZERO

# Movement constants
const ADVANCE_SPEED: float = 80.0
const CHASE_SPEED: float = 120.0
const CHASE_CONTACT_DISTANCE: float = 28.0

# HP bar constants
const HP_BAR_WIDTH: float = 40.0
const HP_BAR_HEIGHT: float = 5.0
const HP_BAR_OFFSET_Y: float = -30.0

# Visual children (created in setup)
var _sprite: Sprite2D = null
var _actor: Node2D = null
var _label: Label = null


# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------

func setup(
	p_card_id: StringName,
	p_level: int,
	p_side: int,
	p_extra_units: int,
	p_smith_bonus: float,
	p_steel_coat_stacks: int,
) -> void:
	print("[TenKingsUnit] setup called - card: ", p_card_id, " side: ", p_side)
	card_id = p_card_id
	level = p_level
	side = p_side
	smith_dmg_bonus = p_smith_bonus
	steel_coat_blocks = p_steel_coat_stacks

	# Determine type flags
	is_ranged = CardLib.is_ranged(card_id)
	is_building = CardLib.is_building(card_id)

	var card_def: Dictionary = CardLib.get_card_def(card_id)
	is_indestructible = bool(card_def.get("is_indestructible", false))

	# Load stats from CardLib
	var stats: Dictionary = CardLib.get_stats_for_level(card_id, level)

	if is_building:
		# Buildings have 1 unit; HP handled externally for castle
		unit_count = 1
		max_unit_count = 1
		hp_per_unit = float(stats.get("hp", 0.0))
		current_hp = hp_per_unit
		dmg_per_unit = float(stats.get("dmg", 0.0))
		hits_per_second = float(stats.get("hps", 1.0))
		crit_chance = float(stats.get("cc", 0.0))
	else:
		# Troops
		var base_units: int = int(stats.get("units", 1))
		unit_count = base_units + p_extra_units
		max_unit_count = unit_count
		hp_per_unit = float(stats.get("hp", 1.0))
		current_hp = hp_per_unit
		dmg_per_unit = float(stats.get("dmg", 1.0))
		hits_per_second = float(stats.get("hps", 1.0))
		crit_chance = float(stats.get("cc", 0.0))

	# Apply blacksmith bonus
	dmg_per_unit *= (1.0 + p_smith_bonus)

	# Set attack range based on type
	if is_building:
		attack_range = 400.0
	elif is_ranged:
		attack_range = 300.0
	else:
		attack_range = 40.0

	print("[TenKingsUnit] Creating visuals for ", card_id, " is_building: ", is_building, " unit_count: ", unit_count)
	# Create visuals
	_create_visuals(card_def)
	_create_label()
	_update_label()
	_apply_visual_state()
	queue_redraw()
	print("[TenKingsUnit] Setup complete - visible: ", visible, " position: ", position)


func _create_visuals(card_def: Dictionary) -> void:
	if is_building:
		_create_sprite(card_def)
		return
	_create_actor(card_def)


func _create_sprite(card_def: Dictionary) -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "IconSprite"
	var icon_path: String = String(card_def.get("icon_path", ""))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		_sprite.texture = load(icon_path) as Texture2D
	_sprite.scale = Vector2(0.4, 0.4)
	add_child(_sprite)


func _create_actor(card_def: Dictionary) -> void:
	var actor_scene: PackedScene = _get_actor_scene()
	if actor_scene == null:
		print("[TenKingsUnit] No actor scene for ", card_id, ", falling back to sprite")
		_create_sprite(card_def)
		return
	print("[TenKingsUnit] Creating actor for ", card_id)
	var actor_node: Node = actor_scene.instantiate()
	if actor_node is Node2D:
		_actor = actor_node as Node2D
		_actor.name = "Actor"
		add_child(_actor)
		print("[TenKingsUnit] Actor added: ", _actor.name, " visible: ", _actor.visible)
		if _actor.has_method("setup_for_side"):
			_actor.call("setup_for_side", side)


func _get_actor_scene() -> PackedScene:
	match card_id:
		CardLib.CARD_SOLDIER:
			return SoldierActorScene
		CardLib.CARD_ARCHER:
			return ArcherActorScene
		CardLib.CARD_PALADIN:
			return PaladinActorScene
		_:
			return null


func _create_label() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-20.0, 10.0)
	_label.size = Vector2(40.0, 20.0)
	_label.add_theme_font_size_override("font_size", 12)
	add_child(_label)


# ---------------------------------------------------------------------------
# Combat interface
# ---------------------------------------------------------------------------

func set_target(target_node: Node2D) -> void:
	_target = target_node


func get_target() -> Node2D:
	return _target


func has_live_target() -> bool:
	return _is_target_alive(_target)


func get_state() -> int:
	return _state


func is_advancing() -> bool:
	return _state == UnitState.ADVANCING


func get_total_hp() -> float:
	if unit_count <= 0:
		return 0.0
	return (unit_count - 1) * hp_per_unit + current_hp


func is_alive() -> bool:
	return unit_count > 0 and _state != UnitState.DEAD


func take_damage(amount: float) -> void:
	if is_indestructible:
		return
	if _state == UnitState.DEAD:
		return

	# Steel coat blocks
	if steel_coat_blocks > 0:
		steel_coat_blocks -= 1
		return

	var remaining: float = amount
	while remaining > 0.0 and unit_count > 0:
		current_hp -= remaining
		if current_hp <= 0.0:
			# Front unit dies
			unit_count -= 1
			if unit_count > 0:
				# Carry over excess damage to next unit
				remaining = -current_hp  # positive overflow
				current_hp = hp_per_unit
			else:
				# All units dead
				current_hp = 0.0
				remaining = 0.0
				_transition_to(UnitState.DEAD)
				unit_died.emit(self)
		else:
			remaining = 0.0

	_update_label()
	queue_redraw()


func _get_dps() -> float:
	return dmg_per_unit * unit_count * hits_per_second


# ---------------------------------------------------------------------------
# State transitions
# ---------------------------------------------------------------------------

func start_advancing() -> void:
	print("[TenKingsUnit] start_advancing called for ", card_id, " current state: ", _state)
	if _state == UnitState.DEAD:
		return
	_transition_to(UnitState.ADVANCING)


func start_fighting() -> void:
	if _state == UnitState.DEAD:
		return
	_transition_to(UnitState.FIGHTING)
	_attack_timer = 0.0


func start_chasing_castle(castle_pos: Vector2) -> void:
	if _state == UnitState.DEAD:
		return
	_chase_target_pos = castle_pos
	_transition_to(UnitState.CHASING_CASTLE)


func _transition_to(new_state: int) -> void:
	print("[TenKingsUnit] ", card_id, " transition: ", _state, " -> ", new_state)
	_state = new_state
	_apply_visual_state()


func _apply_visual_state() -> void:
	if _actor == null:
		return
	match _state:
		UnitState.IDLE:
			_actor.call("play_idle")
		UnitState.ADVANCING, UnitState.CHASING_CASTLE:
			_actor.call("play_walk")
		UnitState.FIGHTING:
			_actor.call("play_attack")
		UnitState.DEAD:
			_actor.call("play_dead")


# ---------------------------------------------------------------------------
# Processing
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	match _state:
		UnitState.IDLE:
			pass
		UnitState.ADVANCING:
			_process_advancing(delta)
		UnitState.FIGHTING:
			_process_fighting(delta)
		UnitState.CHASING_CASTLE:
			_process_chasing(delta)
		UnitState.DEAD:
			pass


func _process_advancing(delta: float) -> void:
	# Buildings don't move — skip straight to fighting if they have a target
	if is_building:
		if _target != null:
			start_fighting()
		return

	if _target == null:
		return

	var dir: Vector2 = (_target.global_position - global_position).normalized()
	var dist: float = global_position.distance_to(_target.global_position)

	if dist <= attack_range:
		start_fighting()
		return

	global_position += dir * ADVANCE_SPEED * delta


func _process_fighting(delta: float) -> void:
	if _target == null:
		return

	# Check if target is still alive
	if not _is_target_alive(_target):
		_target = null
		return

	if hits_per_second <= 0.0:
		return

	_attack_timer += delta
	var attack_interval: float = 1.0 / hits_per_second

	while _attack_timer >= attack_interval:
		_attack_timer -= attack_interval
		_perform_attack()

		# Re-check target after each attack (it may have died)
		if _target == null:
			break
		if not _is_target_alive(_target):
			_target = null
			break


func _process_chasing(delta: float) -> void:
	# Buildings don't move
	if is_building:
		return

	var dir: Vector2 = (_chase_target_pos - global_position).normalized()
	var dist: float = global_position.distance_to(_chase_target_pos)

	if dist <= CHASE_CONTACT_DISTANCE:
		return

	global_position += dir * CHASE_SPEED * delta


func _perform_attack() -> void:
	if _target == null:
		return
	if not _target.has_method("take_damage"):
		return

	var damage: float = dmg_per_unit * unit_count
	# Crit check
	if randf() < crit_chance:
		damage *= 2.0

	attack_performed.emit(self, _target)
	_target.call("take_damage", damage)


func _is_target_alive(target_node: Node2D) -> bool:
	if target_node == null:
		return false
	if not target_node.has_method("is_alive"):
		return false
	return bool(target_node.call("is_alive"))


# ---------------------------------------------------------------------------
# Visual updates
# ---------------------------------------------------------------------------

func _draw() -> void:
	# Don't draw HP bar for indestructible buildings (towers)
	if is_indestructible and card_id != CardLib.CARD_CASTLE:
		return
	if unit_count <= 0:
		return

	var max_total_hp: float = max_unit_count * hp_per_unit
	if max_total_hp <= 0.0:
		return

	var ratio: float = clampf(get_total_hp() / max_total_hp, 0.0, 1.0)
	var bar_x: float = -HP_BAR_WIDTH * 0.5
	var bar_y: float = HP_BAR_OFFSET_Y

	# Background (dark)
	draw_rect(Rect2(bar_x, bar_y, HP_BAR_WIDTH, HP_BAR_HEIGHT), Color(0.2, 0.2, 0.2, 0.8))
	# Foreground (green -> red based on ratio)
	var bar_color: Color = Color(1.0 - ratio, ratio, 0.0, 0.9)
	draw_rect(Rect2(bar_x, bar_y, HP_BAR_WIDTH * ratio, HP_BAR_HEIGHT), bar_color)


func _update_label() -> void:
	if _label == null:
		return
	if is_building and unit_count == 1:
		_label.text = ""
	else:
		_label.text = "x%d" % unit_count
